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

use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Person record from the database
#[derive(Debug, sqlx::FromRow)]
pub struct Person {
    pub id: Uuid,
    pub full_name: String,
    pub date_of_birth: Option<NaiveDate>,
    pub email_address: String,
}

/// Basic user info returned after Google OAuth
#[derive(Debug, Serialize)]
pub struct UserBasicInfo {
    pub person_id: Uuid,
    pub email: String,
    pub display_name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub avatar_url: Option<String>,
}

impl From<Person> for UserBasicInfo {
    fn from(p: Person) -> Self {
        Self {
            person_id: p.id,
            email: p.email_address,
            display_name: p.full_name,
            avatar_url: None,
        }
    }
}

// ==================== Request/Response DTOs ====================

#[derive(Debug, Deserialize)]
pub struct GoogleAuthInitRequest {
    pub redirect_uri: String,
}

#[derive(Debug, Serialize)]
pub struct GoogleAuthInitResponse {
    pub authorization_url: String,
    pub state: String,
}

#[derive(Debug, Deserialize)]
pub struct GoogleCallbackRequest {
    pub code: String,
    pub redirect_uri: String,
}

#[derive(Debug, Serialize)]
pub struct GoogleCallbackResponse {
    pub intermediate_token: String,
    pub expires_in: u64,
    pub user: UserBasicInfo,
}

#[derive(Debug, Serialize)]
pub struct PasskeyChallengeResponse {
    pub challenge: String, // base64url encoded
    pub timeout: u64,
    pub rp_id: String,
    pub user_verification: String,
    pub allowed_credentials: Vec<AllowedCredential>,
}

#[derive(Debug, Serialize)]
pub struct AllowedCredential {
    #[serde(rename = "type")]
    pub cred_type: String,
    pub id: String, // base64url encoded credential ID
    #[serde(skip_serializing_if = "Option::is_none")]
    pub transports: Option<Vec<String>>,
}

#[derive(Debug, Deserialize)]
pub struct PasskeyVerifyRequest {
    pub credential_id: String,      // base64url
    pub authenticator_data: String, // base64url
    pub client_data_json: String,   // base64url
    pub signature: String,          // base64url
    #[serde(default)]
    pub user_handle: Option<String>, // base64url
}

#[derive(Debug, Serialize)]
pub struct AuthTokenResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: String,
    pub expires_in: u64,
}

#[derive(Debug, Deserialize)]
pub struct RefreshTokenRequest {
    pub refresh_token: String,
}

#[derive(Debug, Serialize)]
pub struct ErrorResponse {
    pub code: String,
    pub message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<serde_json::Value>,
}

impl ErrorResponse {
    pub fn new(code: impl Into<String>, message: impl Into<String>) -> Self {
        Self {
            code: code.into(),
            message: message.into(),
            details: None,
        }
    }

    #[allow(dead_code)]
    pub fn with_details(mut self, details: serde_json::Value) -> Self {
        self.details = Some(details);
        self
    }
}

// ==================== KYC Models ====================

#[derive(Debug)]
pub struct FileData {
    pub filename: String,
    pub content_type: String,
    pub data: bytes::Bytes,
}

#[derive(Debug)]
pub struct AccountOpeningBrData {
    pub full_name: String,
    pub mother_name: String,
    pub cpf: String,
    pub email: String,
    pub phone: String,
    pub cnh_pdf: Option<FileData>,
    pub cnh_front: Option<FileData>,
    pub cnh_back: Option<FileData>,
    pub selfie: Option<FileData>,
    pub proof_of_address: Option<FileData>,
}

#[derive(Debug, Serialize)]
pub struct AccountOpeningResponse {
    pub success: bool,
    pub person_id: Uuid,
    pub account_holder_id: Uuid,
    pub polygon_address: String,
    pub message: String,
    pub documents_status: String,
}
