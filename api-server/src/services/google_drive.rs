// Copyright (c) 2026 Matera Systems, Inc. All rights reserved.
//
// This source code is the proprietary property of Matera Systems, Inc.
// and is protected by copyright law and international treaties.
//
// This software is NOT open source. Use, reproduction, or distribution
// of this code is strictly governed by the Matera Source License (MSL) v1.0.
//
// A copy of the MSL v1.0 should have been provided with this file.
// If not, please contact: licensing@matera.com

use anyhow::{Context, Result};
use bytes::Bytes;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::Mutex;

const DRIVE_API_BASE: &str = "https://www.googleapis.com/drive/v3";
const DRIVE_UPLOAD_API_BASE: &str = "https://www.googleapis.com/upload/drive/v3";
const TOKEN_FILE: &str = "secrets/google-drive-token.json";

fn get_oauth_client_id() -> String {
    std::env::var("GOOGLE_DRIVE_CLIENT_ID")
        .or_else(|_| std::env::var("GOOGLE_CLIENT_ID"))
        .expect("GOOGLE_DRIVE_CLIENT_ID or GOOGLE_CLIENT_ID must be set")
}

fn get_oauth_client_secret() -> String {
    std::env::var("GOOGLE_DRIVE_CLIENT_SECRET")
        .or_else(|_| std::env::var("GOOGLE_CLIENT_SECRET"))
        .expect("GOOGLE_DRIVE_CLIENT_SECRET or GOOGLE_CLIENT_SECRET must be set")
}

#[derive(Serialize, Deserialize, Clone)]
pub struct StoredToken {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_at: i64,
}

pub struct DriveClient {
    client: reqwest::Client,
    root_folder_id: String,
    cached_token: Arc<Mutex<Option<StoredToken>>>,
}

#[derive(Serialize)]
struct FileMetadata {
    name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    parents: Option<Vec<String>>,
    #[serde(rename = "mimeType", skip_serializing_if = "Option::is_none")]
    mime_type: Option<String>,
}

#[derive(Deserialize, Debug)]
struct FileListResponse {
    files: Option<Vec<DriveFile>>,
}

#[derive(Deserialize, Debug)]
struct DriveFile {
    id: Option<String>,
    #[allow(dead_code)]
    name: Option<String>,
}

#[derive(Deserialize)]
struct TokenResponse {
    access_token: String,
    refresh_token: Option<String>,
    expires_in: u64,
}

impl DriveClient {
    /// Initialize Google Drive client with OAuth tokens.
    ///
    /// Reads tokens from secrets/google-drive-token.json
    /// Run `cargo run --bin drive_config` first to set up OAuth.
    pub async fn new(root_folder_id: String) -> Result<Self> {
        // Load token from file
        let token_data = std::fs::read_to_string(TOKEN_FILE)
            .context("Failed to read token file. Run 'cargo run --bin drive_config' first to authorize Google Drive access.")?;

        let stored_token: StoredToken = serde_json::from_str(&token_data)
            .context("Failed to parse token file")?;

        let client = reqwest::Client::new();

        Ok(Self {
            client,
            root_folder_id,
            cached_token: Arc::new(Mutex::new(Some(stored_token))),
        })
    }

    /// Get access token for API requests (with auto-refresh)
    async fn get_token(&self) -> Result<String> {
        let mut cache = self.cached_token.lock().await;

        if let Some(ref stored) = *cache {
            // Check if token is expired (with 5 minute buffer)
            let now = chrono::Utc::now().timestamp();
            if now < stored.expires_at - 300 {
                return Ok(stored.access_token.clone());
            }

            // Token expired, refresh it
            tracing::info!("Access token expired, refreshing...");
            let new_token = self.refresh_token(&stored.refresh_token).await?;

            // Update cache
            *cache = Some(new_token.clone());

            // Save to file
            let token_json = serde_json::to_string_pretty(&new_token)?;
            std::fs::write(TOKEN_FILE, &token_json)?;

            return Ok(new_token.access_token);
        }

        anyhow::bail!("No token available. Run 'cargo run --bin drive_config' to authorize.")
    }

    /// Refresh the access token using the refresh token
    async fn refresh_token(&self, refresh_token: &str) -> Result<StoredToken> {
        let client_id = get_oauth_client_id();
        let client_secret = get_oauth_client_secret();

        let params = [
            ("client_id", client_id.as_str()),
            ("client_secret", client_secret.as_str()),
            ("refresh_token", refresh_token),
            ("grant_type", "refresh_token"),
        ];

        let response = self
            .client
            .post("https://oauth2.googleapis.com/token")
            .form(&params)
            .send()
            .await
            .context("Failed to refresh token")?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            anyhow::bail!("Token refresh failed: {}", error_text);
        }

        let token_response: TokenResponse = response.json().await?;
        let expires_at = chrono::Utc::now().timestamp() + token_response.expires_in as i64;

        Ok(StoredToken {
            access_token: token_response.access_token,
            refresh_token: token_response
                .refresh_token
                .unwrap_or_else(|| refresh_token.to_string()),
            expires_at,
        })
    }

    /// Ensure the CPF folder exists: DOC_DB/{CPF}/
    ///
    /// Creates the folder structure if it doesn't exist.
    /// Returns the folder ID of the CPF folder.
    pub async fn ensure_cpf_folder(&self, cpf: &str) -> Result<String> {
        // First, ensure DOC_DB folder exists under root
        let doc_db_folder_id = self.ensure_folder("DOC_DB", &self.root_folder_id).await?;

        // Then, ensure CPF folder exists under DOC_DB
        let cpf_folder_id = self.ensure_folder(cpf, &doc_db_folder_id).await?;

        Ok(cpf_folder_id)
    }

    /// Ensure a folder exists within a parent folder.
    /// Creates it if it doesn't exist, returns existing folder ID if found.
    async fn ensure_folder(&self, folder_name: &str, parent_id: &str) -> Result<String> {
        // Search for existing folder
        let query = format!(
            "name = '{}' and '{}' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
            folder_name, parent_id
        );

        let token = self.get_token().await?;

        let response: FileListResponse = self
            .client
            .get(format!("{}/files", DRIVE_API_BASE))
            .bearer_auth(&token)
            .query(&[
                ("q", query.as_str()),
                ("fields", "files(id,name)"),
            ])
            .send()
            .await
            .context("Failed to search for folder")?
            .json()
            .await
            .context("Failed to parse search response")?;

        // If folder exists, return its ID
        if let Some(files) = response.files {
            if !files.is_empty() {
                if let Some(id) = &files[0].id {
                    tracing::info!("Found existing folder: {} ({})", folder_name, id);
                    return Ok(id.clone());
                }
            }
        }

        // Folder doesn't exist, create it
        tracing::info!("Creating folder: {} in parent {}", folder_name, parent_id);

        let metadata = FileMetadata {
            name: folder_name.to_string(),
            parents: Some(vec![parent_id.to_string()]),
            mime_type: Some("application/vnd.google-apps.folder".to_string()),
        };

        let created: DriveFile = self
            .client
            .post(format!("{}/files", DRIVE_API_BASE))
            .bearer_auth(&token)
            .query(&[("fields", "id,name")])
            .json(&metadata)
            .send()
            .await
            .context("Failed to create folder")?
            .json()
            .await
            .context("Failed to parse create response")?;

        let folder_id = created.id.context("Created folder has no ID")?;
        tracing::info!("Created folder: {} ({})", folder_name, folder_id);

        Ok(folder_id)
    }

    /// Upload a file to a specific folder.
    ///
    /// Returns the file ID in Google Drive.
    pub async fn upload_file(
        &self,
        data: Bytes,
        filename: &str,
        mime_type: &str,
        folder_id: &str,
    ) -> Result<String> {
        tracing::info!(
            "Uploading file: {} ({} bytes) to folder {}",
            filename,
            data.len(),
            folder_id
        );

        let token = self.get_token().await?;

        // Create file metadata
        let metadata = FileMetadata {
            name: filename.to_string(),
            parents: Some(vec![folder_id.to_string()]),
            mime_type: None,
        };

        // Upload using multipart
        let metadata_json = serde_json::to_string(&metadata)?;

        let part1 = reqwest::multipart::Part::text(metadata_json)
            .mime_str("application/json; charset=UTF-8")?;

        let part2 = reqwest::multipart::Part::bytes(data.to_vec())
            .mime_str(mime_type)?;

        let form = reqwest::multipart::Form::new()
            .part("metadata", part1)
            .part("file", part2);

        let response = self
            .client
            .post(format!("{}/files", DRIVE_UPLOAD_API_BASE))
            .bearer_auth(&token)
            .query(&[
                ("uploadType", "multipart"),
                ("fields", "id,name"),
            ])
            .multipart(form)
            .send()
            .await
            .context("Failed to upload file")?;

        let status = response.status();
        let response_text = response.text().await.context("Failed to read response")?;

        if !status.is_success() {
            tracing::error!("Upload failed (status {}): {}", status, response_text);
            anyhow::bail!("Upload failed: {}", response_text);
        }

        let uploaded: DriveFile = serde_json::from_str(&response_text)
            .context("Failed to parse upload response")?;

        let file_id = uploaded.id.context("Uploaded file has no ID")?;
        tracing::info!("Successfully uploaded file: {} (ID: {})", filename, file_id);

        Ok(file_id)
    }
}
