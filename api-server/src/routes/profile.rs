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

// =============================================================================
// BUG FIXES & LESSONS LEARNED (2026-02-04)
// =============================================================================
//
// 1. PHONE_TYPE / EMAIL_TYPE CHANGED FROM OPTION TO REQUIRED
//    Problem: After v007_contact_types_not_null.xml migration made phone_type
//    and email_type columns NOT NULL with defaults, the sqlx::query! macro
//    started returning String instead of Option<String>.
//    Fix: Wrap the values in Some() when mapping to PhoneInfo/EmailInfo structs
//    since the API response types still use Option<String> for backwards
//    compatibility with the frontend.
//    Lesson: When database schema changes column nullability, check all Rust
//    code that reads from those columns - sqlx compile-time checks will catch
//    this, but runtime queries using query_as::<_, T> may silently fail.
//
// 2. DATABASE TYPE MISMATCHES (i16 vs i32)
//    Problem: In reference_data.rs, Currency.decimals was defined as i16, but
//    the database column is INT4 (PostgreSQL integer = i32).
//    Error: "ColumnDecode: mismatched types; Rust type `i16` (as SQL type
//    `INT2`) is not compatible with SQL type `INT4`"
//    Fix: Changed decimals field from i16 to i32.
//    Lesson: Always verify PostgreSQL column types match Rust types:
//      - SMALLINT = i16
//      - INTEGER/INT4 = i32
//      - BIGINT = i64
//      - VARCHAR/TEXT = String
//      - BOOLEAN = bool
//      - UUID = Uuid
//      - TIMESTAMP = chrono::DateTime or NaiveDateTime
//
// 3. NULLABLE COLUMNS IN QUERY RESULTS
//    Problem: When using sqlx::query_as::<_, T>, if a database column is
//    nullable but the Rust struct field is not Option<T>, the query fails
//    at runtime with a type mismatch error.
//    Fix: Use COALESCE in SQL to provide default values, or make the Rust
//    field Option<T>.
//    Example: SELECT COALESCE(name, code) as name FROM table
//
// 4. LIQUIBASE ATTRIBUTE NAMES
//    Problem: Used wrong attribute names in addForeignKeyConstraint:
//      - Wrong: baseSchemaName, referencedSchemaName
//      - Right: baseTableSchemaName, referencedTableSchemaName
//    Lesson: Check existing migrations for correct Liquibase XML syntax,
//    as attribute names vary between Liquibase versions.
//
// IMPORTANT PATTERNS TO REMEMBER:
// - When a migration changes column nullability, ALL queries reading that
//   column need to be updated to match the new type.
// - Use cargo check frequently during development to catch type mismatches.
// - PostgreSQL INT/INTEGER is 4 bytes (i32), not 2 bytes (i16).
// - Frontend API types may differ from database types for compatibility.
// =============================================================================

use axum::{
    extract::State,
    http::{header::AUTHORIZATION, HeaderMap},
    response::IntoResponse,
    Json,
};
use serde::Serialize;
use std::sync::Arc;

use crate::{
    auth::jwt::TokenType,
    error::ApiError,
    AppState,
};

#[derive(Debug, Serialize)]
pub struct ProfileResponse {
    pub personal: Option<PersonalInfo>,
    pub contact: Option<ContactInfo>,
    pub blockchain: Option<BlockchainInfo>,
    pub accounts: Option<AccountsInfo>,
    pub documents: Option<DocumentsInfo>,
}

#[derive(Debug, Serialize)]
pub struct PersonalInfo {
    pub full_name: String,
    pub date_of_birth: Option<String>,
    pub birth_city: Option<String>,
    pub birth_country: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ContactInfo {
    pub phones: Vec<PhoneInfo>,
    pub emails: Vec<EmailInfo>,
}

#[derive(Debug, Serialize)]
pub struct PhoneInfo {
    pub phone_number: String,
    pub phone_type: Option<String>,
    pub is_primary_for_login: bool,
}

#[derive(Debug, Serialize)]
pub struct EmailInfo {
    pub email_address: String,
    pub email_type: Option<String>,
    pub is_primary_for_login: bool,
}

#[derive(Debug, Serialize)]
pub struct BlockchainInfo {
    pub polygon_address: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct AccountsInfo {
    pub brazil: Option<BrazilBankAccount>,
    pub usa: Option<UsaBankAccount>,
}

#[derive(Debug, Serialize)]
pub struct BrazilBankAccount {
    pub bank_code: Option<String>,
    pub branch_number: Option<String>,
    pub account_number: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct UsaBankAccount {
    pub routing_number: String,
    pub account_number: String,
}

#[derive(Debug, Serialize)]
pub struct DocumentsInfo {
    pub brazil: Option<BrazilDocuments>,
    pub usa: Option<UsaDocuments>,
}

#[derive(Debug, Serialize)]
pub struct BrazilDocuments {
    pub cpf: String,
    pub rg_number: Option<String>,
    pub rg_issuer: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct UsaDocuments {
    pub ssn_last4: Option<String>,
    pub drivers_license_number: Option<String>,
    pub drivers_license_state: Option<String>,
}

/// Get user profile for the authenticated user
pub async fn get_profile(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, ApiError> {
    // Extract and validate access token
    let claims = extract_and_validate_token(&state, &headers, TokenType::Access)?;
    let person_id = claims.sub;

    let db = &state.db;

    // 1. Personal info
    let personal_row = sqlx::query!(
        r#"
        SELECT full_name, date_of_birth, birth_city, birth_country
        FROM registration_schema.people
        WHERE id = $1
        "#,
        person_id
    )
    .fetch_optional(db.pool())
    .await?;

    let personal = personal_row.map(|row| PersonalInfo {
        full_name: row.full_name,
        date_of_birth: row.date_of_birth.map(|d| d.to_string()),
        birth_city: row.birth_city,
        birth_country: row.birth_country,
    });

    // 2. Phones
    let phone_rows = sqlx::query!(
        r#"
        SELECT ph.phone_number, pp.phone_type, pp.is_primary_for_login
        FROM registration_schema.person_phones pp
        JOIN registration_schema.phones ph ON ph.id = pp.phone_id
        WHERE pp.person_id = $1
        ORDER BY pp.is_primary_for_login DESC
        "#,
        person_id
    )
    .fetch_all(db.pool())
    .await?;

    let phones: Vec<PhoneInfo> = phone_rows
        .into_iter()
        .map(|row| PhoneInfo {
            phone_number: row.phone_number,
            phone_type: Some(row.phone_type),
            is_primary_for_login: row.is_primary_for_login.unwrap_or(false),
        })
        .collect();

    // 3. Emails
    let email_rows = sqlx::query!(
        r#"
        SELECT e.email_address, pe.email_type, pe.is_primary_for_login
        FROM registration_schema.person_emails pe
        JOIN registration_schema.emails e ON e.id = pe.email_id
        WHERE pe.person_id = $1
        ORDER BY pe.is_primary_for_login DESC
        "#,
        person_id
    )
    .fetch_all(db.pool())
    .await?;

    let emails: Vec<EmailInfo> = email_rows
        .into_iter()
        .map(|row| EmailInfo {
            email_address: row.email_address,
            email_type: Some(row.email_type),
            is_primary_for_login: row.is_primary_for_login.unwrap_or(false),
        })
        .collect();

    let contact = if phones.is_empty() && emails.is_empty() {
        None
    } else {
        Some(ContactInfo { phones, emails })
    };

    // 4. Polygon address
    let address_row = sqlx::query!(
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
        person_id
    )
    .fetch_optional(db.pool())
    .await?;

    let blockchain = Some(BlockchainInfo {
        polygon_address: address_row.map(|r| r.public_address),
    });

    // 5. Brazilian documents
    let br_docs_row = sqlx::query!(
        r#"
        SELECT cpf, rg_number, rg_issuer
        FROM registration_schema.person_documents_br
        WHERE person_id = $1
        LIMIT 1
        "#,
        person_id
    )
    .fetch_optional(db.pool())
    .await?;

    let brazil_docs = br_docs_row.map(|row| BrazilDocuments {
        cpf: row.cpf,
        rg_number: row.rg_number,
        rg_issuer: row.rg_issuer,
    });

    // 6. USA documents
    let us_docs_row = sqlx::query!(
        r#"
        SELECT ssn_last4, drivers_license_number, drivers_license_state
        FROM registration_schema.person_documents_us
        WHERE person_id = $1
        LIMIT 1
        "#,
        person_id
    )
    .fetch_optional(db.pool())
    .await?;

    let usa_docs = us_docs_row.map(|row| UsaDocuments {
        ssn_last4: row.ssn_last4,
        drivers_license_number: row.drivers_license_number,
        drivers_license_state: row.drivers_license_state,
    });

    let documents = if brazil_docs.is_none() && usa_docs.is_none() {
        None
    } else {
        Some(DocumentsInfo {
            brazil: brazil_docs,
            usa: usa_docs,
        })
    };

    // 7. Get account holder ID first
    let account_holder_row = sqlx::query!(
        r#"
        SELECT id FROM accounts_schema.account_holders
        WHERE main_person_id = $1
        LIMIT 1
        "#,
        person_id
    )
    .fetch_optional(db.pool())
    .await?;

    let accounts = if let Some(ah) = account_holder_row {
        // 8. Brazilian bank account
        let br_bank_row = sqlx::query!(
            r#"
            SELECT adb.bank_code, adb.branch_number, adb.account_number
            FROM accounts_schema.accounts a
            JOIN accounts_schema.account_details_br adb ON adb.account_id = a.id
            WHERE a.account_holder_id = $1
            LIMIT 1
            "#,
            ah.id
        )
        .fetch_optional(db.pool())
        .await?;

        let brazil_bank = br_bank_row.map(|row| BrazilBankAccount {
            bank_code: row.bank_code,
            branch_number: row.branch_number,
            account_number: row.account_number,
        });

        // 9. USA bank account
        let us_bank_row = sqlx::query!(
            r#"
            SELECT adu.routing_number, adu.account_number
            FROM accounts_schema.accounts a
            JOIN accounts_schema.account_details_us adu ON adu.account_id = a.id
            WHERE a.account_holder_id = $1
            LIMIT 1
            "#,
            ah.id
        )
        .fetch_optional(db.pool())
        .await?;

        let usa_bank = us_bank_row.map(|row| UsaBankAccount {
            routing_number: row.routing_number,
            account_number: row.account_number,
        });

        if brazil_bank.is_none() && usa_bank.is_none() {
            None
        } else {
            Some(AccountsInfo {
                brazil: brazil_bank,
                usa: usa_bank,
            })
        }
    } else {
        None
    };

    Ok(Json(ProfileResponse {
        personal,
        contact,
        blockchain,
        accounts,
        documents,
    }))
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
