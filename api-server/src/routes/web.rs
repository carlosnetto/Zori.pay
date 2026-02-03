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
    http::StatusCode,
    response::{Html, IntoResponse, Redirect},
};

/// API root - redirect to health check
pub async fn index() -> impl IntoResponse {
    Html("<h1>Zori.pay API Server</h1><p>Use the <a href=\"https://zoripay.xyz\">web frontend</a> to access Zori.</p>")
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
