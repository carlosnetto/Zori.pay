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
use ethers::{
    prelude::*,
    types::{Address, U256},
};
use serde::Serialize;
use std::sync::Arc;

use crate::{
    auth::jwt::TokenType,
    error::ApiError,
};

#[derive(Debug, Serialize)]
pub struct BalanceResponse {
    pub address: String,
    pub blockchain: String,
    pub balances: Vec<CurrencyBalance>,
}

#[derive(Debug, Serialize)]
pub struct CurrencyBalance {
    pub currency_code: String,
    pub balance: String,
    pub decimals: u8,
    pub formatted_balance: String,
}

// ERC20 ABI for balanceOf function
abigen!(
    IERC20,
    r#"[
        function balanceOf(address account) external view returns (uint256)
        function decimals() external view returns (uint8)
    ]"#,
);

use crate::AppState;

/// Get blockchain balances for the authenticated user
pub async fn get_balances(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, ApiError> {
    // Extract and validate access token
    let claims = extract_and_validate_token(&state, &headers, TokenType::Access)?;

    let db = &state.db;
    // Get user's Polygon address from database
    let address_row = sqlx::query!(
        r#"
        SELECT aba.public_address, ab.blockchain_code
        FROM accounts_schema.account_blockchain ab
        JOIN accounts_schema.account_blockchain_addresses aba ON ab.id = aba.account_blockchain_id
        JOIN accounts_schema.account_holders ah ON ab.account_holder_id = ah.id
        WHERE ah.main_person_id = $1
          AND ab.blockchain_code = 'POLYGON'
          AND aba.is_active = true
          AND aba.is_primary = true
        LIMIT 1
        "#,
        claims.sub
    )
    .fetch_optional(db.pool())
    .await?;

    let address_row = address_row.ok_or_else(|| {
        ApiError::Validation("No Polygon address found for user".to_string())
    })?;

    let address_str = address_row.public_address;
    let address: Address = address_str.parse().map_err(|e| {
        ApiError::Internal(anyhow::anyhow!("Invalid address format: {}", e))
    })?;

    // Get currency contracts from database
    let contracts = sqlx::query!(
        r#"
        SELECT
            c.code,
            c.decimals,
            cbc.contract_address,
            COALESCE(cbc.network_decimals, c.decimals) as blockchain_decimals
        FROM accounts_schema.currencies c
        JOIN accounts_schema.currency_blockchain_configs cbc ON c.id = cbc.currency_id
        WHERE cbc.blockchain_code = 'POLYGON'
          AND c.code IN ('USDC', 'USDT', 'POL', 'BRL1')
        ORDER BY c.code
        "#
    )
    .fetch_all(db.pool())
    .await?;

    // Connect to Polygon RPC
    let rpc_url = std::env::var("POLYGON_RPC_URL")
        .unwrap_or_else(|_| "https://polygon-rpc.com".to_string());

    let provider = Provider::<Http>::try_from(rpc_url)
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to connect to Polygon: {}", e)))?;
    let provider = Arc::new(provider);

    let mut balances = Vec::new();

    // Query balances for each currency
    for contract in contracts {
        let code = contract.code;
        let decimals = contract.blockchain_decimals.unwrap_or(contract.decimals) as u8;

        let balance = if code == "POL" {
            // Native token - get balance directly
            provider
                .get_balance(address, None)
                .await
                .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to get POL balance: {}", e)))?
        } else if let Some(contract_addr_str) = contract.contract_address {
            // ERC20 token - query contract
            let contract_address: Address = contract_addr_str.parse().map_err(|e| {
                ApiError::Internal(anyhow::anyhow!("Invalid contract address: {}", e))
            })?;

            let erc20 = IERC20::new(contract_address, provider.clone());
            erc20
                .balance_of(address)
                .call()
                .await
                .map_err(|e| {
                    ApiError::Internal(anyhow::anyhow!("Failed to get {} balance: {:?}", code, e))
                })?
        } else {
            // No contract address, skip
            tracing::warn!("No contract address for {}, skipping", code);
            continue;
        };

        // Format balance with decimals
        let formatted = format_balance(balance, decimals);

        balances.push(CurrencyBalance {
            currency_code: code,
            balance: balance.to_string(),
            decimals,
            formatted_balance: formatted,
        });
    }

    Ok(Json(BalanceResponse {
        address: address_str,
        blockchain: "POLYGON".to_string(),
        balances,
    }))
}

/// Format balance with proper decimals
fn format_balance(balance: U256, decimals: u8) -> String {
    if balance.is_zero() {
        return "0.00".to_string();
    }

    let divisor = U256::from(10u128.pow(decimals as u32));
    let whole = balance / divisor;
    let remainder = balance % divisor;

    // Format with 2 decimal places
    let decimals_u128: u128 = remainder.as_u128();
    let display_decimals = 2;
    let decimal_divisor = 10u128.pow((decimals - display_decimals).max(0) as u32);
    let decimal_part = if decimals >= display_decimals {
        decimals_u128 / decimal_divisor
    } else {
        decimals_u128 * 10u128.pow((display_decimals - decimals) as u32)
    };

    format!("{}.{:02}", whole, decimal_part)
}

/// Helper to extract Bearer token from Authorization header and validate it
fn extract_and_validate_token(
    state: &AppState,
    headers: &HeaderMap,
    expected_type: TokenType,
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
        .validate_token(token, expected_type)
        .map_err(|e| {
            tracing::error!("Token validation failed: {:?}", e);
            ApiError::InvalidToken
        })?;

    Ok(claims)
}
