use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use thiserror::Error;

use crate::models::ErrorResponse;

#[derive(Debug, Error)]
#[allow(dead_code)]
pub enum ApiError {
    #[error("User not found")]
    UserNotFound,

    #[error("Email not authorized for login")]
    EmailNotAuthorizedForLogin,

    #[error("Invalid or expired authorization code")]
    InvalidAuthCode,

    #[error("Invalid or expired token")]
    InvalidToken,

    #[error("Invalid passkey signature")]
    InvalidPasskeySignature,

    #[error("Passkey challenge expired")]
    PasskeyChallengeExpired,

    #[error("No passkeys registered")]
    NoPasskeysRegistered,

    #[error("Validation error: {0}")]
    Validation(String),

    #[error("CPF already registered")]
    CpfAlreadyExists,

    #[error("Invalid CPF: {0}")]
    InvalidCpf(String),

    #[error("Invalid email format")]
    InvalidEmail,

    #[error("Invalid phone format")]
    InvalidPhone,

    #[error("Missing required file: {0}")]
    MissingFile(String),

    #[error("File too large: {0}")]
    FileTooLarge(String),

    #[error("Invalid request: {0}")]
    InvalidRequest(String),

    #[error("Wallet generation failed")]
    WalletGenerationError,

    #[error("Encryption error")]
    EncryptionError,

    #[error("Google Drive error: {0}")]
    DriveError(String),

    #[error("Internal server error")]
    Internal(#[from] anyhow::Error),

    #[error("Database error")]
    Database(#[from] sqlx::Error),
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, error_response) = match &self {
            ApiError::UserNotFound => (
                StatusCode::NOT_FOUND,
                ErrorResponse::new("USER_NOT_FOUND", "No account found for this email"),
            ),
            ApiError::EmailNotAuthorizedForLogin => (
                StatusCode::FORBIDDEN,
                ErrorResponse::new(
                    "EMAIL_NOT_AUTHORIZED",
                    "This email is not authorized for login",
                ),
            ),
            ApiError::InvalidAuthCode => (
                StatusCode::UNAUTHORIZED,
                ErrorResponse::new("INVALID_AUTH_CODE", "Invalid or expired authorization code"),
            ),
            ApiError::InvalidToken => (
                StatusCode::UNAUTHORIZED,
                ErrorResponse::new("INVALID_TOKEN", "Invalid or expired token"),
            ),
            ApiError::InvalidPasskeySignature => (
                StatusCode::UNAUTHORIZED,
                ErrorResponse::new("INVALID_PASSKEY", "Invalid passkey signature"),
            ),
            ApiError::PasskeyChallengeExpired => (
                StatusCode::UNAUTHORIZED,
                ErrorResponse::new("CHALLENGE_EXPIRED", "Passkey challenge has expired"),
            ),
            ApiError::NoPasskeysRegistered => (
                StatusCode::FORBIDDEN,
                ErrorResponse::new("NO_PASSKEYS", "No passkeys registered for this account"),
            ),
            ApiError::Validation(msg) => (
                StatusCode::BAD_REQUEST,
                ErrorResponse::new("VALIDATION_ERROR", msg.clone()),
            ),
            ApiError::CpfAlreadyExists => (
                StatusCode::CONFLICT,
                ErrorResponse::new("CPF_ALREADY_EXISTS", "CPF is already registered"),
            ),
            ApiError::InvalidCpf(msg) => (
                StatusCode::BAD_REQUEST,
                ErrorResponse::new("INVALID_CPF", msg.clone()),
            ),
            ApiError::InvalidEmail => (
                StatusCode::BAD_REQUEST,
                ErrorResponse::new("INVALID_EMAIL", "Invalid email format"),
            ),
            ApiError::InvalidPhone => (
                StatusCode::BAD_REQUEST,
                ErrorResponse::new("INVALID_PHONE", "Invalid phone format"),
            ),
            ApiError::MissingFile(msg) => (
                StatusCode::BAD_REQUEST,
                ErrorResponse::new("MISSING_FILE", msg.clone()),
            ),
            ApiError::FileTooLarge(msg) => (
                StatusCode::PAYLOAD_TOO_LARGE,
                ErrorResponse::new("FILE_TOO_LARGE", msg.clone()),
            ),
            ApiError::InvalidRequest(msg) => (
                StatusCode::BAD_REQUEST,
                ErrorResponse::new("INVALID_REQUEST", msg.clone()),
            ),
            ApiError::WalletGenerationError => (
                StatusCode::INTERNAL_SERVER_ERROR,
                ErrorResponse::new("WALLET_ERROR", "Failed to generate wallet"),
            ),
            ApiError::EncryptionError => (
                StatusCode::INTERNAL_SERVER_ERROR,
                ErrorResponse::new("ENCRYPTION_ERROR", "Failed to encrypt data"),
            ),
            ApiError::DriveError(msg) => {
                tracing::error!("Google Drive error: {}", msg);
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    ErrorResponse::new("DRIVE_ERROR", "Failed to upload documents"),
                )
            }
            ApiError::Internal(e) => {
                tracing::error!("Internal error: {:?}", e);
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    ErrorResponse::new("INTERNAL_ERROR", "An internal error occurred"),
                )
            }
            ApiError::Database(e) => {
                tracing::error!("Database error: {:?}", e);
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    ErrorResponse::new("DATABASE_ERROR", "A database error occurred"),
                )
            }
        };

        (status, Json(error_response)).into_response()
    }
}

pub type ApiResult<T> = Result<T, ApiError>;
