use axum::{
    extract::State,
    http::{header::AUTHORIZATION, HeaderMap},
    routing::post,
    Json, Router,
};
use std::sync::Arc;

use crate::auth::jwt::TokenType;
use crate::error::{ApiError, ApiResult};
use crate::models::{
    AuthTokenResponse, GoogleAuthInitRequest, GoogleAuthInitResponse, GoogleCallbackRequest,
    GoogleCallbackResponse, PasskeyVerifyRequest, RefreshTokenRequest, UserBasicInfo,
};
use crate::AppState;

pub fn router() -> Router<Arc<AppState>> {
    Router::new()
        .route("/google", post(initiate_google_auth))
        .route("/google/callback", post(handle_google_callback))
        .route("/passkey/challenge", post(request_passkey_challenge))
        .route("/passkey/verify", post(verify_passkey))
        .route("/dev/bypass-passkey", post(bypass_passkey_verification))
        .route("/refresh", post(refresh_token))
        .route("/logout", post(logout))
}

/// POST /v1/auth/google
/// Initiate Google OAuth flow - returns authorization URL
async fn initiate_google_auth(
    State(state): State<Arc<AppState>>,
    Json(request): Json<GoogleAuthInitRequest>,
) -> ApiResult<Json<GoogleAuthInitResponse>> {
    let (authorization_url, csrf_state) = state
        .google_oauth
        .get_authorization_url(&request.redirect_uri)
        .map_err(|e| ApiError::Internal(e))?;

    Ok(Json(GoogleAuthInitResponse {
        authorization_url,
        state: csrf_state,
    }))
}

/// POST /v1/auth/google/callback
/// Exchange Google authorization code for intermediate token.
/// Only emails marked with is_primary_for_login=true are accepted.
async fn handle_google_callback(
    State(state): State<Arc<AppState>>,
    Json(request): Json<GoogleCallbackRequest>,
) -> ApiResult<Json<GoogleCallbackResponse>> {
    // Exchange code with Google and get user info
    let google_user = state
        .google_oauth
        .exchange_code(&request.code, &request.redirect_uri)
        .await
        .map_err(|_| ApiError::InvalidAuthCode)?;

    tracing::info!("Google OAuth success for email: {}", google_user.email);

    // Look up person by login email
    // This query only returns a result if:
    // 1. The email exists
    // 2. It's linked to a person
    // 3. is_primary_for_login = true
    let person = state
        .db
        .find_person_by_login_email(&google_user.email)
        .await?
        .ok_or_else(|| {
            tracing::warn!(
                "Login attempt with unauthorized email: {}",
                google_user.email
            );
            ApiError::UserNotFound
        })?;

    tracing::info!("Found person {} for email {}", person.id, google_user.email);

    // Create intermediate token (short-lived, only valid for passkey verification)
    let intermediate_token = state
        .jwt
        .create_intermediate_token(
            person.id,
            &person.email_address,
            state.config.intermediate_token_expiry_secs,
        )
        .map_err(|e| ApiError::Internal(e))?;

    Ok(Json(GoogleCallbackResponse {
        intermediate_token,
        expires_in: state.config.intermediate_token_expiry_secs,
        user: UserBasicInfo {
            person_id: person.id,
            email: person.email_address,
            display_name: person.full_name,
            avatar_url: google_user.picture,
        },
    }))
}

/// POST /v1/auth/passkey/challenge
/// Request a WebAuthn authentication challenge.
/// Requires a valid intermediate token (from Google OAuth).
async fn request_passkey_challenge(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> ApiResult<Json<crate::models::PasskeyChallengeResponse>> {
    // Extract and validate intermediate token
    let claims = extract_and_validate_token(&state, &headers, TokenType::Intermediate)?;

    // Get passkey credentials for this person
    let credentials = state.db.get_passkey_credentials(claims.sub).await?;

    if credentials.is_empty() {
        return Err(ApiError::NoPasskeysRegistered);
    }

    // Generate challenge
    let challenge = state
        .webauthn
        .generate_challenge(claims.sub, &credentials)
        .map_err(|e| ApiError::Internal(e))?;

    Ok(Json(challenge))
}

/// POST /v1/auth/passkey/verify
/// Verify passkey signature and complete login.
/// Returns access and refresh tokens.
async fn verify_passkey(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    Json(request): Json<PasskeyVerifyRequest>,
) -> ApiResult<Json<AuthTokenResponse>> {
    // Extract and validate intermediate token
    let claims = extract_and_validate_token(&state, &headers, TokenType::Intermediate)?;

    // Verify the passkey response
    let (credential_id, counter) = state
        .webauthn
        .verify_response(claims.sub, &request)
        .map_err(|e| {
            tracing::warn!("Passkey verification failed: {:?}", e);
            ApiError::InvalidPasskeySignature
        })?;

    // Update the credential counter (replay attack protection)
    state
        .db
        .update_passkey_counter(&credential_id, counter)
        .await?;

    tracing::info!("Passkey verified for person {}", claims.sub);

    // Create final tokens
    let access_token = state
        .jwt
        .create_access_token(
            claims.sub,
            &claims.email,
            state.config.jwt_access_token_expiry_secs,
        )
        .map_err(|e| ApiError::Internal(e))?;

    let refresh_token = state
        .jwt
        .create_refresh_token(
            claims.sub,
            &claims.email,
            state.config.jwt_refresh_token_expiry_secs,
        )
        .map_err(|e| ApiError::Internal(e))?;

    Ok(Json(AuthTokenResponse {
        access_token,
        refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: state.config.jwt_access_token_expiry_secs,
    }))
}

/// POST /v1/auth/dev/bypass-passkey
/// DEVELOPMENT ONLY: Bypass passkey verification and create tokens directly from intermediate token.
/// This should be removed or disabled in production.
async fn bypass_passkey_verification(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> ApiResult<Json<AuthTokenResponse>> {
    tracing::warn!("DEVELOPMENT MODE: Bypassing passkey verification");

    // Extract and validate intermediate token
    let claims = extract_and_validate_token(&state, &headers, TokenType::Intermediate)?;

    // Create final tokens directly without passkey verification
    let access_token = state
        .jwt
        .create_access_token(
            claims.sub,
            &claims.email,
            state.config.jwt_access_token_expiry_secs,
        )
        .map_err(|e| ApiError::Internal(e))?;

    let refresh_token = state
        .jwt
        .create_refresh_token(
            claims.sub,
            &claims.email,
            state.config.jwt_refresh_token_expiry_secs,
        )
        .map_err(|e| ApiError::Internal(e))?;

    tracing::info!("Dev bypass: Created tokens for person {}", claims.sub);

    Ok(Json(AuthTokenResponse {
        access_token,
        refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: state.config.jwt_access_token_expiry_secs,
    }))
}

/// POST /v1/auth/refresh
/// Exchange a valid refresh token for a new access token.
async fn refresh_token(
    State(state): State<Arc<AppState>>,
    Json(request): Json<RefreshTokenRequest>,
) -> ApiResult<Json<AuthTokenResponse>> {
    // Validate refresh token
    let claims = state
        .jwt
        .validate_refresh_token(&request.refresh_token)
        .map_err(|_| ApiError::InvalidToken)?;

    // Create new tokens
    let access_token = state
        .jwt
        .create_access_token(
            claims.sub,
            &claims.email,
            state.config.jwt_access_token_expiry_secs,
        )
        .map_err(|e| ApiError::Internal(e))?;

    let refresh_token = state
        .jwt
        .create_refresh_token(
            claims.sub,
            &claims.email,
            state.config.jwt_refresh_token_expiry_secs,
        )
        .map_err(|e| ApiError::Internal(e))?;

    Ok(Json(AuthTokenResponse {
        access_token,
        refresh_token,
        token_type: "Bearer".to_string(),
        expires_in: state.config.jwt_access_token_expiry_secs,
    }))
}

/// POST /v1/auth/logout
/// Invalidate the current session.
async fn logout(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
) -> ApiResult<()> {
    // Validate access token (just to ensure it's a valid request)
    let _claims = extract_and_validate_token(&state, &headers, TokenType::Access)?;

    // In a production system, you would:
    // 1. Add the token's JTI to a blacklist (Redis)
    // 2. Invalidate the refresh token family
    // For now, we just acknowledge the logout

    tracing::info!("User logged out");

    Ok(())
}

/// Helper to extract Bearer token from Authorization header and validate it.
fn extract_and_validate_token(
    state: &AppState,
    headers: &HeaderMap,
    expected_type: TokenType,
) -> ApiResult<crate::auth::jwt::Claims> {
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
        .map_err(|_| ApiError::InvalidToken)?;

    Ok(claims)
}
