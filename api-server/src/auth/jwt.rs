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

use anyhow::Result;
use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TokenType {
    /// Intermediate token - only valid for passkey verification
    Intermediate,
    /// Full access token - grants API access
    Access,
    /// Refresh token - used to obtain new access tokens
    Refresh,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    /// Subject (person_id)
    pub sub: Uuid,
    /// Email address
    pub email: String,
    /// Token type
    pub token_type: TokenType,
    /// Issued at (Unix timestamp)
    pub iat: i64,
    /// Expiration (Unix timestamp)
    pub exp: i64,
    /// JWT ID (unique identifier for this token)
    pub jti: Uuid,
}

pub struct JwtManager {
    encoding_key: EncodingKey,
    decoding_key: DecodingKey,
}

impl JwtManager {
    pub fn new(secret: &str) -> Self {
        Self {
            encoding_key: EncodingKey::from_secret(secret.as_bytes()),
            decoding_key: DecodingKey::from_secret(secret.as_bytes()),
        }
    }

    /// Create an intermediate token (valid only for passkey verification)
    pub fn create_intermediate_token(
        &self,
        person_id: Uuid,
        email: &str,
        expiry_secs: u64,
    ) -> Result<String> {
        self.create_token(person_id, email, TokenType::Intermediate, expiry_secs)
    }

    /// Create a full access token
    pub fn create_access_token(
        &self,
        person_id: Uuid,
        email: &str,
        expiry_secs: u64,
    ) -> Result<String> {
        self.create_token(person_id, email, TokenType::Access, expiry_secs)
    }

    /// Create a refresh token
    pub fn create_refresh_token(
        &self,
        person_id: Uuid,
        email: &str,
        expiry_secs: u64,
    ) -> Result<String> {
        self.create_token(person_id, email, TokenType::Refresh, expiry_secs)
    }

    fn create_token(
        &self,
        person_id: Uuid,
        email: &str,
        token_type: TokenType,
        expiry_secs: u64,
    ) -> Result<String> {
        let now = Utc::now();
        let exp = now + Duration::seconds(expiry_secs as i64);

        let claims = Claims {
            sub: person_id,
            email: email.to_string(),
            token_type,
            iat: now.timestamp(),
            exp: exp.timestamp(),
            jti: Uuid::new_v4(),
        };

        let token = encode(&Header::default(), &claims, &self.encoding_key)?;
        Ok(token)
    }

    /// Validate and decode a token, checking that it matches the expected type
    pub fn validate_token(&self, token: &str, expected_type: TokenType) -> Result<Claims> {
        let mut validation = Validation::default();
        validation.validate_exp = true;

        let token_data = decode::<Claims>(token, &self.decoding_key, &validation)?;

        if token_data.claims.token_type != expected_type {
            anyhow::bail!(
                "Invalid token type: expected {:?}, got {:?}",
                expected_type,
                token_data.claims.token_type
            );
        }

        Ok(token_data.claims)
    }

    /// Validate an intermediate token (used before passkey verification)
    pub fn validate_intermediate_token(&self, token: &str) -> Result<Claims> {
        self.validate_token(token, TokenType::Intermediate)
    }

    /// Validate an access token (used for API requests)
    pub fn validate_access_token(&self, token: &str) -> Result<Claims> {
        self.validate_token(token, TokenType::Access)
    }

    /// Validate a refresh token
    pub fn validate_refresh_token(&self, token: &str) -> Result<Claims> {
        self.validate_token(token, TokenType::Refresh)
    }
}
