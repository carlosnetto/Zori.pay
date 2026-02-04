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

use axum::{extract::State, response::Json};
use serde::Serialize;
use std::sync::Arc;

use crate::error::ApiResult;
use crate::AppState;

#[derive(Serialize)]
pub struct DriveTestResponse {
    pub success: bool,
    pub message: String,
    pub details: DriveTestDetails,
}

#[derive(Serialize)]
pub struct DriveTestDetails {
    pub config_loaded: bool,
    pub auth_successful: bool,
    pub folder_created: bool,
    pub file_uploaded: bool,
    pub test_folder_id: Option<String>,
    pub test_file_id: Option<String>,
    pub errors: Vec<String>,
}

/// GET /v1/test/drive
///
/// Tests the Google Drive integration:
/// 1. Loads service account credentials
/// 2. Authenticates with Google
/// 3. Creates a test folder
/// 4. Uploads a test file
/// 5. Reports results
pub async fn test_drive_integration(
    State(state): State<Arc<AppState>>,
) -> ApiResult<Json<DriveTestResponse>> {
    let mut details = DriveTestDetails {
        config_loaded: false,
        auth_successful: false,
        folder_created: false,
        file_uploaded: false,
        test_folder_id: None,
        test_file_id: None,
        errors: Vec::new(),
    };

    tracing::info!("Starting Google Drive integration test...");

    // Test 1: Configuration loaded
    details.config_loaded = !state.config.google_drive_root_folder_id.is_empty();

    if !details.config_loaded {
        details.errors.push("Configuration missing in .env file".to_string());
        return Ok(Json(DriveTestResponse {
            success: false,
            message: "Google Drive not configured. Check .env file.".to_string(),
            details,
        }));
    }

    tracing::info!("✓ Configuration loaded");

    // Test 2: Create test folder
    let test_cpf = "00000000000";
    match state.drive_client.ensure_cpf_folder(test_cpf).await {
        Ok(folder_id) => {
            details.folder_created = true;
            details.test_folder_id = Some(folder_id.clone());
            tracing::info!("✓ Test folder created: {}", folder_id);
        }
        Err(e) => {
            let error_msg = format!("Failed to create folder: {}", e);
            details.errors.push(error_msg.clone());
            tracing::error!("✗ {}", error_msg);
            return Ok(Json(DriveTestResponse {
                success: false,
                message: "Failed to create folder. Check service account permissions.".to_string(),
                details,
            }));
        }
    }

    // Test 3: Upload test file
    let test_content = b"This is a test file from Zori.pay API server.
Generated at: 2026-02-02
Purpose: Testing Google Drive integration

If you see this file, the integration is working correctly!";

    let test_filename = format!("test_{}.txt", chrono::Utc::now().format("%Y%m%d_%H%M%S"));

    match state
        .drive_client
        .upload_file(
            bytes::Bytes::from(&test_content[..]),
            &test_filename,
            "text/plain",
            details.test_folder_id.as_ref().unwrap(),
        )
        .await
    {
        Ok(file_id) => {
            details.file_uploaded = true;
            details.test_file_id = Some(file_id.clone());
            details.auth_successful = true; // If we got this far, auth worked
            tracing::info!("✓ Test file uploaded: {}", file_id);
        }
        Err(e) => {
            let error_msg = format!("Failed to upload file: {}", e);
            details.errors.push(error_msg.clone());
            tracing::error!("✗ {}", error_msg);
            return Ok(Json(DriveTestResponse {
                success: false,
                message: "Failed to upload file. Check service account permissions.".to_string(),
                details,
            }));
        }
    }

    // All tests passed!
    tracing::info!("✓ All Google Drive tests passed!");

    Ok(Json(DriveTestResponse {
        success: true,
        message: format!(
            "Google Drive integration working! Check folder: PROD/DOC_DB/{}/",
            test_cpf
        ),
        details,
    }))
}
