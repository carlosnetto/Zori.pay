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

mod auth;
mod config;
mod crypto;
mod db;
mod error;
mod models;
mod routes;
mod services;

use axum::{extract::DefaultBodyLimit, routing::{get, post}, Router};
use std::sync::Arc;
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::config::Config;
use crate::db::Database;
use crate::services::google_drive::DriveClient;

pub struct AppState {
    pub db: Database,
    pub config: Config,
    pub google_oauth: auth::google::GoogleOAuth,
    pub webauthn: auth::passkey::PasskeyAuth,
    pub jwt: auth::jwt::JwtManager,
    pub drive_client: Arc<DriveClient>,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            std::env::var("RUST_LOG").unwrap_or_else(|_| "info,tower_http=debug".into()),
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration
    dotenvy::dotenv().ok();
    let config = Config::from_env()?;

    // Connect to database
    let db = Database::connect(&config.database_url).await?;
    tracing::info!("Connected to database");

    // Initialize auth components
    let google_oauth = auth::google::GoogleOAuth::new(
        &config.google_client_id,
        &config.google_client_secret,
    );

    let webauthn = auth::passkey::PasskeyAuth::new(&config.rp_id, &config.rp_origin)?;

    let jwt = auth::jwt::JwtManager::new(&config.jwt_secret);

    // Initialize Google Drive client (uses OAuth tokens from secrets/google-drive-token.json)
    let drive_client = Arc::new(
        DriveClient::new(config.google_drive_root_folder_id.clone()).await?,
    );
    tracing::info!("Connected to Google Drive");

    // Build application state
    let state = Arc::new(AppState {
        db,
        config: config.clone(),
        google_oauth,
        webauthn,
        jwt,
        drive_client,
    });

    // Build router
    let app = Router::new()
        // Web routes (no state needed)
        .route("/", get(routes::web::index))
        .route("/auth/callback", get(routes::web::oauth_callback))
        .route("/health", get(routes::web::health))
        // API routes
        .nest("/v1/auth", routes::auth::router())
        .route("/v1/balance", get(routes::balance::get_balances))
        .route("/v1/receive", get(routes::receive::get_receive_address))
        .route("/v1/send", post(routes::send::send_transaction))
        .route("/v1/send/estimate", post(routes::send::estimate_transaction))
        .route("/v1/transactions", get(routes::transactions::get_transactions))
        .route("/v1/profile", get(routes::profile::get_profile))
        .route("/v1/reference-data", get(routes::reference_data::get_reference_data))
        .route("/v1/kyc/open-account-br", post(routes::kyc::open_account_br)
            .layer(DefaultBodyLimit::max(50 * 1024 * 1024))) // 50MB limit for file uploads
        // Test routes
        .route("/v1/test/drive", get(routes::test_drive::test_drive_integration))
        .layer(TraceLayer::new_for_http())
        .layer(
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods(Any)
                .allow_headers(Any),
        )
        .with_state(state);

    // Start server
    let addr = format!("{}:{}", config.host, config.port);
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    tracing::info!("Server listening on {}", addr);

    axum::serve(listener, app).await?;

    Ok(())
}
