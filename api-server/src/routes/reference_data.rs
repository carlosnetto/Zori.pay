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
    http::{header, HeaderMap, StatusCode},
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use sha2::{Sha256, Digest};
use sqlx::FromRow;
use std::sync::Arc;

use crate::{error::ApiError, AppState};

#[derive(Debug, Serialize)]
pub struct ReferenceDataResponse {
    pub countries: Vec<Country>,
    pub states: Vec<StateEntry>,
    pub phone_types: Vec<PhoneType>,
    pub email_types: Vec<EmailType>,
    pub currencies: Vec<Currency>,
    pub blockchain_networks: Vec<BlockchainNetwork>,
    pub address_types: Vec<AddressType>,
    pub asset_types: Vec<AssetType>,
}

#[derive(Debug, Serialize, FromRow)]
pub struct Country {
    pub iso_code: String,
    pub name: String,
}

#[derive(Debug, Serialize, FromRow)]
pub struct StateEntry {
    pub country_code: String,
    pub state_code: String,
    pub name: String,
}

#[derive(Debug, Serialize, FromRow)]
pub struct PhoneType {
    pub code: String,
    pub description: String,
}

#[derive(Debug, Serialize, FromRow)]
pub struct EmailType {
    pub code: String,
    pub description: String,
}

#[derive(Debug, Serialize, FromRow)]
pub struct Currency {
    pub code: String,
    pub name: String,
    pub asset_type_code: String,
    pub decimals: i32,
}

#[derive(Debug, Serialize, FromRow)]
pub struct BlockchainNetwork {
    pub code: String,
    pub name: String,
}

#[derive(Debug, Serialize, FromRow)]
pub struct AddressType {
    pub code: String,
    pub description: String,
}

#[derive(Debug, Serialize, FromRow)]
pub struct AssetType {
    pub code: String,
    pub description: String,
}

/// GET /v1/reference-data
/// Returns all reference data needed for frontend dropdowns.
/// No authentication required - this is public, static data.
/// Supports ETag caching via If-None-Match header.
pub async fn get_reference_data(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<Response, ApiError> {
    let db = state.db.pool();

    // Execute all queries in parallel using tokio::join!
    // Use COALESCE to handle nullable columns and provide default values
    let (
        countries_result,
        states_result,
        phone_types_result,
        email_types_result,
        currencies_result,
        blockchain_networks_result,
        address_types_result,
        asset_types_result,
    ) = tokio::join!(
        sqlx::query_as::<_, Country>(
            r#"SELECT iso_code, name FROM registration_schema.countries ORDER BY name"#
        )
        .fetch_all(db),
        sqlx::query_as::<_, StateEntry>(
            r#"SELECT country_code, state_code, name FROM registration_schema.states ORDER BY country_code, name"#
        )
        .fetch_all(db),
        sqlx::query_as::<_, PhoneType>(
            r#"SELECT code, description FROM registration_schema.phone_types ORDER BY code"#
        )
        .fetch_all(db),
        sqlx::query_as::<_, EmailType>(
            r#"SELECT code, description FROM registration_schema.email_types ORDER BY code"#
        )
        .fetch_all(db),
        sqlx::query_as::<_, Currency>(
            r#"SELECT code, COALESCE(name, code) as name, COALESCE(asset_type_code, 'other') as asset_type_code, decimals FROM accounts_schema.currencies ORDER BY code"#
        )
        .fetch_all(db),
        sqlx::query_as::<_, BlockchainNetwork>(
            r#"SELECT code, COALESCE(name, code) as name FROM accounts_schema.blockchain_networks ORDER BY name"#
        )
        .fetch_all(db),
        sqlx::query_as::<_, AddressType>(
            r#"SELECT code, COALESCE(description, code) as description FROM registration_schema.address_types ORDER BY code"#
        )
        .fetch_all(db),
        sqlx::query_as::<_, AssetType>(
            r#"SELECT code, code as description FROM accounts_schema.asset_types ORDER BY code"#
        )
        .fetch_all(db),
    );

    // Unwrap all results
    let countries = countries_result?;
    let states = states_result?;
    let phone_types = phone_types_result?;
    let email_types = email_types_result?;
    let currencies = currencies_result?;
    let blockchain_networks = blockchain_networks_result?;
    let address_types = address_types_result?;
    let asset_types = asset_types_result?;

    let response_data = ReferenceDataResponse {
        countries,
        states,
        phone_types,
        email_types,
        currencies,
        blockchain_networks,
        address_types,
        asset_types,
    };

    // Generate ETag based on response content
    let json_data = serde_json::to_string(&response_data)
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Serialization error: {}", e)))?;

    let mut hasher = Sha256::new();
    hasher.update(json_data.as_bytes());
    let hash = hasher.finalize();
    let etag = format!("\"{}\"", hex::encode(&hash[..8])); // Use first 8 bytes for shorter ETag

    // Check If-None-Match header for caching
    if let Some(if_none_match) = headers.get(header::IF_NONE_MATCH) {
        if let Ok(client_etag) = if_none_match.to_str() {
            if client_etag == etag || client_etag == format!("W/{}", etag) {
                return Ok((
                    StatusCode::NOT_MODIFIED,
                    [(header::ETAG, etag)],
                ).into_response());
            }
        }
    }

    // Return full response with ETag
    Ok((
        StatusCode::OK,
        [
            (header::ETAG, etag),
            (header::CACHE_CONTROL, "public, max-age=3600".to_string()), // Cache for 1 hour
        ],
        Json(response_data),
    ).into_response())
}
