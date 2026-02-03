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

use axum::{
    extract::State,
    http::{header::AUTHORIZATION, HeaderMap},
    response::IntoResponse,
    Json,
};
use serde::Serialize;
use std::sync::Arc;

use crate::{auth::jwt::TokenType, error::ApiError, AppState};

#[derive(Debug, Serialize)]
pub struct ReceiveAddressResponse {
    pub blockchain: String,
    pub address: String,
}

/// GET /v1/receive
///
/// Returns the user's primary blockchain address for receiving funds.
pub async fn get_receive_address(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, ApiError> {
    // Extract and validate access token
    let claims = extract_and_validate_token(&state, &headers)?;

    // Get user's primary Polygon address from database
    let address_row = sqlx::query!(
        r#"
        SELECT aba.public_address, ab.blockchain_code
        FROM accounts_schema.account_blockchain ab
        JOIN accounts_schema.account_blockchain_addresses aba ON ab.id = aba.account_blockchain_id
        JOIN accounts_schema.account_holders ah ON ab.account_holder_id = ah.id
        WHERE ah.main_person_id = $1
          AND aba.is_active = true
          AND aba.is_primary = true
        LIMIT 1
        "#,
        claims.sub
    )
    .fetch_optional(state.db.pool())
    .await?;

    let address_row = address_row.ok_or_else(|| {
        ApiError::Validation("No blockchain address found for user".to_string())
    })?;

    Ok(Json(ReceiveAddressResponse {
        blockchain: address_row.blockchain_code,
        address: address_row.public_address,
    }))
}

/// Helper to extract Bearer token from Authorization header and validate it
fn extract_and_validate_token(
    state: &AppState,
    headers: &HeaderMap,
) -> Result<crate::auth::jwt::Claims, ApiError> {
    let auth_header = headers
        .get(AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .ok_or(ApiError::InvalidToken)?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or(ApiError::InvalidToken)?;

    let claims = state
        .jwt
        .validate_token(token, TokenType::Access)
        .map_err(|e| {
            tracing::error!("Token validation failed: {:?}", e);
            ApiError::InvalidToken
        })?;

    Ok(claims)
}
