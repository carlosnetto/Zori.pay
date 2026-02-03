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
    extract::{Query, State},
    http::{header::AUTHORIZATION, HeaderMap},
    response::IntoResponse,
    Json,
};
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::sync::Arc;

use crate::{
    auth::jwt::TokenType,
    error::ApiError,
};

#[derive(Debug, Deserialize)]
pub struct TransactionsQuery {
    /// Optional currency code filter (e.g., "BRL1", "USDC", "POL")
    pub currency_code: Option<String>,
    /// Optional limit on number of transactions to return (default: 50, max: 100)
    pub limit: Option<usize>,
}

#[derive(Debug, Serialize)]
pub struct TransactionsResponse {
    pub address: String,
    pub blockchain: String,
    pub currency_code: Option<String>,
    pub transactions: Vec<Transaction>,
}

#[derive(Debug, Serialize)]
pub struct Transaction {
    pub hash: String,
    pub block_number: u64,
    pub timestamp: u64,
    pub from: String,
    pub to: String,
    pub value: String,
    pub formatted_value: String,
    pub currency_code: String,
    pub decimals: u8,
    pub status: String,
}

// Alchemy API response structures
#[derive(Debug, Deserialize)]
struct AlchemyResponse {
    result: AlchemyResult,
}

#[derive(Debug, Deserialize)]
struct AlchemyResult {
    transfers: Vec<AlchemyTransfer>,
}

#[derive(Debug, Deserialize)]
struct AlchemyBlockResponse {
    result: AlchemyBlock,
}

#[derive(Debug, Deserialize)]
struct AlchemyBlock {
    timestamp: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
#[allow(dead_code)]
struct AlchemyTransfer {
    block_num: String,
    hash: String,
    from: String,
    to: String,
    value: Option<f64>,
    asset: Option<String>,
    category: String,
    raw_contract: AlchemyRawContract,
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct AlchemyRawContract {
    value: String,
    address: Option<String>,
    decimal: Option<String>,
}

use crate::AppState;

/// GET /v1/transactions
/// Get recent blockchain transactions for the authenticated user via Alchemy API
pub async fn get_transactions(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Query(query): Query<TransactionsQuery>,
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

    let user_address = address_row.public_address.to_lowercase();

    // Get RPC URL
    let rpc_url = std::env::var("POLYGON_RPC_URL")
        .unwrap_or_else(|_| "https://polygon-rpc.com".to_string());

    let limit = query.limit.unwrap_or(50).min(100);
    let max_count = format!("0x{:x}", limit);

    // Fetch transactions from Alchemy
    let mut all_transactions = Vec::new();

    // Get ERC20 transfers (sent from user)
    let sent_transfers = fetch_alchemy_transfers(
        &rpc_url,
        &user_address,
        None,
        &max_count,
        true, // from address
    ).await?;

    // Get ERC20 transfers (received by user)
    let received_transfers = fetch_alchemy_transfers(
        &rpc_url,
        &user_address,
        None,
        &max_count,
        false, // to address
    ).await?;

    // Combine and deduplicate
    let mut all_transfers = sent_transfers;
    all_transfers.extend(received_transfers);

    // Get currency contract addresses from database
    let currencies = sqlx::query!(
        r#"
        SELECT
            c.code,
            c.decimals,
            cbc.contract_address,
            COALESCE(cbc.network_decimals, c.decimals) as blockchain_decimals
        FROM accounts_schema.currencies c
        JOIN accounts_schema.currency_blockchain_configs cbc ON c.id = cbc.currency_id
        WHERE cbc.blockchain_code = 'POLYGON'
          AND c.code IN ('USDC', 'USDT', 'BRL1', 'POL')
        "#
    )
    .fetch_all(db.pool())
    .await?;

    // Create map of contract_address -> (currency_code, decimals)
    let mut contract_map: std::collections::HashMap<String, (String, u8)> = std::collections::HashMap::new();
    for currency in currencies {
        if let Some(addr) = currency.contract_address {
            let decimals = currency.blockchain_decimals.unwrap_or(currency.decimals) as u8;
            contract_map.insert(addr.to_lowercase(), (currency.code, decimals));
        }
    }

    // Process transfers and collect unique block numbers
    let mut seen_hashes = std::collections::HashSet::new();
    let mut block_numbers = std::collections::HashSet::new();

    for transfer in all_transfers.iter() {
        // Parse block number
        let block_str = transfer.block_num.trim_start_matches("0x");
        if let Ok(block_number) = u64::from_str_radix(block_str, 16) {
            block_numbers.insert(block_number);
        }
    }

    // Fetch timestamps for all unique blocks
    let block_timestamps = fetch_block_timestamps(&rpc_url, &block_numbers).await?;

    // Process transfers
    for transfer in all_transfers {
        // Deduplicate by hash
        if !seen_hashes.insert(transfer.hash.clone()) {
            continue;
        }

        // Get currency info from contract address or category
        let contract_addr = transfer.raw_contract.address
            .as_ref()
            .map(|a| a.to_lowercase())
            .unwrap_or_default();

        // Determine currency code and decimals
        let (currency_code, decimals) = if transfer.category == "external" {
            // Native token transfer (POL on Polygon)
            ("POL".to_string(), 18u8)
        } else if let Some((code, dec)) = contract_map.get(&contract_addr) {
            (code.clone(), *dec)
        } else {
            // Unknown token, skip
            continue;
        };

        // Apply currency filter if specified
        if let Some(ref filter) = query.currency_code {
            if filter != &currency_code {
                continue;
            }
        }

        // Parse value
        let value_str = transfer.raw_contract.value.trim_start_matches("0x");
        let value = u128::from_str_radix(value_str, 16).unwrap_or(0);
        let formatted_value = format_token_value(value, decimals);

        // Parse block number
        let block_str = transfer.block_num.trim_start_matches("0x");
        let block_number = u64::from_str_radix(block_str, 16).unwrap_or(0);

        // Get timestamp from block_timestamps map
        let timestamp = block_timestamps.get(&block_number).copied().unwrap_or(0);

        all_transactions.push(Transaction {
            hash: transfer.hash,
            block_number,
            timestamp,
            from: transfer.from,
            to: transfer.to,
            value: value.to_string(),
            formatted_value,
            currency_code,
            decimals,
            status: "confirmed".to_string(),
        });
    }

    // Sort by block number descending (most recent first)
    all_transactions.sort_by(|a, b| b.block_number.cmp(&a.block_number));

    // Apply limit
    all_transactions.truncate(limit);

    Ok(Json(TransactionsResponse {
        address: user_address,
        blockchain: "POLYGON".to_string(),
        currency_code: query.currency_code,
        transactions: all_transactions,
    }))
}

/// Fetch block timestamps for given block numbers
async fn fetch_block_timestamps(
    rpc_url: &str,
    block_numbers: &std::collections::HashSet<u64>,
) -> Result<std::collections::HashMap<u64, u64>, ApiError> {
    let client = reqwest::Client::new();
    let mut timestamps = std::collections::HashMap::new();

    // Fetch blocks in batches (Alchemy supports batch requests)
    for block_num in block_numbers {
        let block_hex = format!("0x{:x}", block_num);

        let payload = json!({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "eth_getBlockByNumber",
            "params": [block_hex, false]
        });

        let response = client
            .post(rpc_url)
            .header("Content-Type", "application/json")
            .json(&payload)
            .send()
            .await
            .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to fetch block: {}", e)))?;

        let data: AlchemyBlockResponse = response
            .json()
            .await
            .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to parse block response: {}", e)))?;

        // Parse timestamp from hex
        let timestamp_str = data.result.timestamp.trim_start_matches("0x");
        if let Ok(timestamp) = u64::from_str_radix(timestamp_str, 16) {
            timestamps.insert(*block_num, timestamp);
        }
    }

    Ok(timestamps)
}

/// Fetch transfers from Alchemy API
async fn fetch_alchemy_transfers(
    rpc_url: &str,
    address: &str,
    _block_range: Option<String>,
    max_count: &str,
    from_address: bool,
) -> Result<Vec<AlchemyTransfer>, ApiError> {
    let client = reqwest::Client::new();

    let address_param = if from_address {
        json!("fromAddress")
    } else {
        json!("toAddress")
    };

    let payload = json!({
        "jsonrpc": "2.0",
        "id": 1,
        "method": "alchemy_getAssetTransfers",
        "params": [{
            "fromBlock": "0x0",
            "toBlock": "latest",
            address_param.as_str().unwrap(): address,
            "category": ["erc20", "external"],
            "maxCount": max_count,
            "order": "desc"
        }]
    });

    let response = client
        .post(rpc_url)
        .header("Content-Type", "application/json")
        .json(&payload)
        .send()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to fetch transfers: {}", e)))?;

    let data: AlchemyResponse = response
        .json()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to parse Alchemy response: {}", e)))?;

    Ok(data.result.transfers)
}

/// Format token value with proper decimals
fn format_token_value(value: u128, decimals: u8) -> String {
    if value == 0 {
        return "0.00".to_string();
    }

    let divisor = 10u128.pow(decimals as u32);
    let whole = value / divisor;
    let remainder = value % divisor;

    // Format with 2 decimal places
    let display_decimals = 2;
    let decimal_divisor = 10u128.pow((decimals.saturating_sub(display_decimals)) as u32);
    let decimal_part = if decimals >= display_decimals {
        remainder / decimal_divisor
    } else {
        remainder * 10u128.pow((display_decimals - decimals) as u32)
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
