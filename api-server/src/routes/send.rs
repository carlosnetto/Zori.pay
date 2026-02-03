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
    types::{Address, TransactionRequest, U256},
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

use crate::{
    auth::jwt::TokenType,
    crypto::{encryption, wallet},
    error::ApiError,
    AppState,
};

#[derive(Debug, Deserialize)]
pub struct EstimateRequest {
    #[allow(dead_code)]
    pub to_address: String,
    #[allow(dead_code)]
    pub amount: String,
    pub currency_code: String,
}

#[derive(Debug, Serialize)]
pub struct EstimateResponse {
    pub estimated_gas: String,
    pub gas_price: String,
    pub estimated_fee: String,
    pub estimated_fee_formatted: String,
    pub max_amount: String,
    pub max_amount_formatted: String,
}

#[derive(Debug, Deserialize)]
pub struct SendRequest {
    pub to_address: String,
    pub amount: String,
    pub currency_code: String,
}

#[derive(Debug, Serialize)]
pub struct SendResponse {
    pub success: bool,
    pub transaction_hash: String,
    pub message: String,
}

// ERC20 ABI for transfer and balanceOf functions
abigen!(
    IERC20,
    r#"[
        function transfer(address to, uint256 amount) external returns (bool)
        function balanceOf(address account) external view returns (uint256)
        function decimals() external view returns (uint8)
    ]"#,
);

/// POST /v1/send
///
/// Send cryptocurrency to a destination address.
pub async fn send_transaction(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(request): Json<SendRequest>,
) -> Result<impl IntoResponse, ApiError> {
    // 1. Validate and authenticate
    let claims = extract_and_validate_token(&state, &headers)?;

    // 2. Validate destination address
    let to_address: Address = request
        .to_address
        .parse()
        .map_err(|_| ApiError::Validation("Invalid destination address".to_string()))?;

    // 3. Get user's wallet data from database
    let wallet_data = sqlx::query!(
        r#"
        SELECT
            ab.encrypted_master_seed,
            ab.encryption_iv,
            ab.encryption_auth_tag,
            aba.public_address
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
    .fetch_optional(state.db.pool())
    .await?
    .ok_or_else(|| ApiError::Validation("No wallet found for user".to_string()))?;

    // 4. Decrypt the seed
    let encrypted = encryption::EncryptedSeed {
        ciphertext: wallet_data.encrypted_master_seed,
        iv: wallet_data
            .encryption_iv
            .try_into()
            .map_err(|_| ApiError::Internal(anyhow::anyhow!("Invalid IV length")))?,
        auth_tag: wallet_data
            .encryption_auth_tag
            .try_into()
            .map_err(|_| ApiError::Internal(anyhow::anyhow!("Invalid auth tag length")))?,
    };

    let seed = encryption::decrypt_seed(&encrypted, &state.config.master_encryption_key)
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to decrypt seed: {}", e)))?;

    // 5. Derive private key
    let private_key = wallet::derive_private_key(&seed, 0)
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to derive key: {}", e)))?;

    // 6. Connect to Polygon RPC
    let rpc_url = std::env::var("POLYGON_RPC_URL")
        .unwrap_or_else(|_| "https://polygon-rpc.com".to_string());

    let provider = Provider::<Http>::try_from(&rpc_url)
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to connect to Polygon: {}", e)))?;

    let chain_id = provider
        .get_chainid()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to get chain ID: {}", e)))?;

    // Create wallet from private key
    let wallet = LocalWallet::from_bytes(&private_key)
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to create wallet: {}", e)))?
        .with_chain_id(chain_id.as_u64());

    let client = SignerMiddleware::new(provider.clone(), wallet);

    // 7. Check POL balance for gas fees
    let from_address: Address = wallet_data.public_address.parse()
        .map_err(|_| ApiError::Internal(anyhow::anyhow!("Invalid wallet address")))?;

    let pol_balance = provider
        .get_balance(from_address, None)
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to get POL balance: {}", e)))?;

    // Minimum POL needed for gas (approximately 0.01 POL)
    let min_gas = U256::from(10_000_000_000_000_000u64); // 0.01 POL
    if pol_balance < min_gas {
        return Err(ApiError::Validation(
            "Insufficient POL for gas fees. You need at least 0.01 POL to pay for transaction fees.".to_string()
        ));
    }

    // 8. Build and send transaction
    let tx_hash = if request.currency_code == "POL" {
        // Native token transfer
        let amount = parse_amount(&request.amount, 18)?;

        // Check we have enough POL (amount + gas)
        if pol_balance < amount + min_gas {
            return Err(ApiError::Validation(
                "Insufficient POL balance (need to keep some for gas fees)".to_string()
            ));
        }

        let tx = TransactionRequest::new()
            .to(to_address)
            .value(amount);

        let pending_tx = client
            .send_transaction(tx, None)
            .await
            .map_err(|e| {
                let err_str = format!("{}", e);
                if err_str.contains("gas required exceeds allowance") || err_str.contains("insufficient funds") {
                    ApiError::Validation("Insufficient POL for gas fees".to_string())
                } else {
                    ApiError::Internal(anyhow::anyhow!("Failed to send transaction: {}", e))
                }
            })?;

        format!("{:?}", pending_tx.tx_hash())
    } else {
        // ERC20 token transfer
        let contract_info = sqlx::query!(
            r#"
            SELECT
                cbc.contract_address,
                COALESCE(cbc.network_decimals, c.decimals) as decimals
            FROM accounts_schema.currencies c
            JOIN accounts_schema.currency_blockchain_configs cbc ON c.id = cbc.currency_id
            WHERE c.code = $1 AND cbc.blockchain_code = 'POLYGON'
            "#,
            request.currency_code
        )
        .fetch_optional(state.db.pool())
        .await?
        .ok_or_else(|| {
            ApiError::Validation(format!("Currency {} not supported", request.currency_code))
        })?;

        let contract_address: Address = contract_info
            .contract_address
            .ok_or_else(|| {
                ApiError::Validation(format!(
                    "No contract address for {}",
                    request.currency_code
                ))
            })?
            .parse()
            .map_err(|_| ApiError::Internal(anyhow::anyhow!("Invalid contract address")))?;

        let decimals = contract_info.decimals.unwrap_or(18) as u8;
        let amount = parse_amount(&request.amount, decimals)?;

        let contract = IERC20::new(contract_address, Arc::new(client));

        let tx = contract.transfer(to_address, amount);
        let pending_tx = tx
            .send()
            .await
            .map_err(|e| {
                let err_str = format!("{:?}", e);
                if err_str.contains("gas required exceeds allowance") || err_str.contains("insufficient funds") {
                    ApiError::Validation("Insufficient POL for gas fees. You need POL to pay for transaction fees.".to_string())
                } else if err_str.contains("transfer amount exceeds balance") {
                    ApiError::Validation(format!("Insufficient {} balance", request.currency_code))
                } else {
                    ApiError::Internal(anyhow::anyhow!("Failed to send ERC20 transfer: {}", e))
                }
            })?;

        format!("{:?}", pending_tx.tx_hash())
    };

    tracing::info!(
        "Transaction sent: {} {} to {} - hash: {}",
        request.amount,
        request.currency_code,
        request.to_address,
        tx_hash
    );

    Ok(Json(SendResponse {
        success: true,
        transaction_hash: tx_hash,
        message: format!(
            "Successfully sent {} {} to {}",
            request.amount, request.currency_code, request.to_address
        ),
    }))
}

/// POST /v1/send/estimate
///
/// Estimate transaction cost and calculate max sendable amount.
pub async fn estimate_transaction(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(request): Json<EstimateRequest>,
) -> Result<impl IntoResponse, ApiError> {
    let claims = extract_and_validate_token(&state, &headers)?;

    // Get user's wallet address
    let wallet_data = sqlx::query!(
        r#"
        SELECT aba.public_address
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
    .fetch_optional(state.db.pool())
    .await?
    .ok_or_else(|| ApiError::Validation("No wallet found".to_string()))?;

    let from_address: Address = wallet_data.public_address.parse()
        .map_err(|_| ApiError::Internal(anyhow::anyhow!("Invalid wallet address")))?;

    // Connect to Polygon
    let rpc_url = std::env::var("POLYGON_RPC_URL")
        .unwrap_or_else(|_| "https://polygon-rpc.com".to_string());

    let provider = Provider::<Http>::try_from(&rpc_url)
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to connect: {}", e)))?;

    // Get current gas price
    let gas_price = provider
        .get_gas_price()
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to get gas price: {}", e)))?;

    // Get POL balance
    let pol_balance = provider
        .get_balance(from_address, None)
        .await
        .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to get balance: {}", e)))?;

    // Estimate gas based on transaction type
    let estimated_gas = if request.currency_code == "POL" {
        // Native transfer: 21000 gas
        U256::from(21000)
    } else {
        // ERC20 transfer: approximately 65000 gas (can vary)
        U256::from(65000)
    };

    // Calculate fee (gas * gas_price)
    let estimated_fee = estimated_gas * gas_price;

    // Add 20% buffer for safety
    let estimated_fee_with_buffer = estimated_fee * U256::from(120) / U256::from(100);

    // Calculate max sendable amount
    let (max_amount, max_amount_formatted) = if request.currency_code == "POL" {
        // For POL: balance - fee
        let max = if pol_balance > estimated_fee_with_buffer {
            pol_balance - estimated_fee_with_buffer
        } else {
            U256::zero()
        };
        (max, format_u256(max, 18))
    } else {
        // For ERC20: get token balance
        let contract_info = sqlx::query!(
            r#"
            SELECT cbc.contract_address, COALESCE(cbc.network_decimals, c.decimals) as decimals
            FROM accounts_schema.currencies c
            JOIN accounts_schema.currency_blockchain_configs cbc ON c.id = cbc.currency_id
            WHERE c.code = $1 AND cbc.blockchain_code = 'POLYGON'
            "#,
            request.currency_code
        )
        .fetch_optional(state.db.pool())
        .await?
        .ok_or_else(|| ApiError::Validation("Currency not supported".to_string()))?;

        let contract_address: Address = contract_info
            .contract_address
            .ok_or_else(|| ApiError::Validation("No contract address".to_string()))?
            .parse()
            .map_err(|_| ApiError::Internal(anyhow::anyhow!("Invalid contract")))?;

        let decimals = contract_info.decimals.unwrap_or(18) as u8;

        let provider_arc = Arc::new(provider);
        let contract = IERC20::new(contract_address, provider_arc);
        let token_balance: U256 = contract
            .balance_of(from_address)
            .call()
            .await
            .map_err(|e| ApiError::Internal(anyhow::anyhow!("Failed to get token balance: {}", e)))?;

        (token_balance, format_u256(token_balance, decimals))
    };

    Ok(Json(EstimateResponse {
        estimated_gas: estimated_gas.to_string(),
        gas_price: gas_price.to_string(),
        estimated_fee: estimated_fee_with_buffer.to_string(),
        estimated_fee_formatted: format_u256(estimated_fee_with_buffer, 18),
        max_amount: max_amount.to_string(),
        max_amount_formatted,
    }))
}

/// Format U256 value with decimals (capped at 8 for display)
fn format_u256(value: U256, decimals: u8) -> String {
    if value.is_zero() {
        return "0".to_string();
    }

    let divisor = U256::from(10u128.pow(decimals as u32));
    let whole = value / divisor;
    let remainder = value % divisor;

    if remainder.is_zero() {
        return whole.to_string();
    }

    // Get fractional part with proper padding
    let remainder_str = format!("{:0>width$}", remainder, width = decimals as usize);

    // Cap display decimals at min(currency_decimals, 8)
    let display_decimals = (decimals as usize).min(8);
    let truncated = &remainder_str[..display_decimals];
    let trimmed = truncated.trim_end_matches('0');

    if trimmed.is_empty() {
        whole.to_string()
    } else {
        format!("{}.{}", whole, trimmed)
    }
}

/// Parse amount string to U256 with given decimals
fn parse_amount(amount: &str, decimals: u8) -> Result<U256, ApiError> {
    let parts: Vec<&str> = amount.split('.').collect();

    let whole = parts[0]
        .parse::<u128>()
        .map_err(|_| ApiError::Validation("Invalid amount".to_string()))?;

    let fraction = if parts.len() > 1 {
        let frac_str = parts[1];
        let frac_len = frac_str.len().min(decimals as usize);
        let frac_padded = format!("{:0<width$}", &frac_str[..frac_len], width = decimals as usize);
        frac_padded
            .parse::<u128>()
            .map_err(|_| ApiError::Validation("Invalid amount".to_string()))?
    } else {
        0
    };

    let multiplier = 10u128.pow(decimals as u32);
    let total = whole
        .checked_mul(multiplier)
        .and_then(|w| w.checked_add(fraction))
        .ok_or_else(|| ApiError::Validation("Amount overflow".to_string()))?;

    Ok(U256::from(total))
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
