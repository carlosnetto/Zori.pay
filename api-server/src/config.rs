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

#[derive(Clone)]
pub struct Config {
    // Server
    pub host: String,
    pub port: u16,

    // Database
    pub database_url: String,

    // Google OAuth
    pub google_client_id: String,
    pub google_client_secret: String,

    // WebAuthn
    pub rp_id: String,
    pub rp_origin: String,

    // JWT
    pub jwt_secret: String,
    pub jwt_access_token_expiry_secs: u64,
    pub jwt_refresh_token_expiry_secs: u64,
    pub intermediate_token_expiry_secs: u64,

    // Wallet encryption
    pub master_encryption_key: Vec<u8>,
    pub encryption_key_id: String,

    // Google Drive
    pub google_drive_service_account_key: String,
    pub google_drive_root_folder_id: String,

    // File upload limits
    pub max_file_size_bytes: usize,
    pub max_total_upload_bytes: usize,
}

impl Config {
    pub fn from_env() -> Result<Self> {
        // Parse hex-encoded encryption key
        let key_hex = std::env::var("MASTER_ENCRYPTION_KEY")
            .context("MASTER_ENCRYPTION_KEY must be set")?;
        let master_encryption_key = hex::decode(&key_hex)
            .context("MASTER_ENCRYPTION_KEY must be valid hex")?;
        if master_encryption_key.len() != 32 {
            anyhow::bail!("MASTER_ENCRYPTION_KEY must be 32 bytes (64 hex chars)");
        }

        Ok(Self {
            host: std::env::var("HOST").unwrap_or_else(|_| "127.0.0.1".into()),
            port: std::env::var("PORT")
                .unwrap_or_else(|_| "8080".into())
                .parse()
                .context("Invalid PORT")?,

            database_url: std::env::var("DATABASE_URL")
                .context("DATABASE_URL must be set")?,

            google_client_id: std::env::var("GOOGLE_CLIENT_ID")
                .context("GOOGLE_CLIENT_ID must be set")?,
            google_client_secret: std::env::var("GOOGLE_CLIENT_SECRET")
                .context("GOOGLE_CLIENT_SECRET must be set")?,

            rp_id: std::env::var("RP_ID").unwrap_or_else(|_| "zori.pay".into()),
            rp_origin: std::env::var("RP_ORIGIN")
                .unwrap_or_else(|_| "https://zori.pay".into()),

            jwt_secret: std::env::var("JWT_SECRET")
                .context("JWT_SECRET must be set")?,
            jwt_access_token_expiry_secs: std::env::var("JWT_ACCESS_EXPIRY")
                .unwrap_or_else(|_| "3600".into())
                .parse()
                .unwrap_or(3600),
            jwt_refresh_token_expiry_secs: std::env::var("JWT_REFRESH_EXPIRY")
                .unwrap_or_else(|_| "604800".into())
                .parse()
                .unwrap_or(604800), // 7 days
            intermediate_token_expiry_secs: std::env::var("INTERMEDIATE_TOKEN_EXPIRY")
                .unwrap_or_else(|_| "300".into())
                .parse()
                .unwrap_or(300), // 5 minutes

            master_encryption_key,
            encryption_key_id: std::env::var("ENCRYPTION_KEY_ID")
                .unwrap_or_else(|_| "env-v1".into()),

            google_drive_service_account_key: std::env::var("GOOGLE_DRIVE_SERVICE_ACCOUNT_KEY")
                .context("GOOGLE_DRIVE_SERVICE_ACCOUNT_KEY must be set")?,
            google_drive_root_folder_id: std::env::var("GOOGLE_DRIVE_ROOT_FOLDER_ID")
                .context("GOOGLE_DRIVE_ROOT_FOLDER_ID must be set")?,

            max_file_size_bytes: std::env::var("MAX_FILE_SIZE_MB")
                .unwrap_or_else(|_| "10".into())
                .parse::<usize>()
                .unwrap_or(10) * 1024 * 1024,
            max_total_upload_bytes: std::env::var("MAX_TOTAL_UPLOAD_SIZE_MB")
                .unwrap_or_else(|_| "50".into())
                .parse::<usize>()
                .unwrap_or(50) * 1024 * 1024,
        })
    }
}
