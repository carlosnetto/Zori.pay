use axum::{
    http::StatusCode,
    response::{Html, IntoResponse, Redirect},
};

/// Serve the test login page
pub async fn index() -> impl IntoResponse {
    Html(include_str!("../../test-login.html"))
}

/// Handle Google OAuth callback - redirect to index with params
pub async fn oauth_callback() -> impl IntoResponse {
    // The callback query params are preserved in the redirect
    Redirect::to("/")
}

/// Health check endpoint
pub async fn health() -> impl IntoResponse {
    (StatusCode::OK, "OK")
}
