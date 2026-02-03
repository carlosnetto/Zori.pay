//! Google Drive OAuth Configuration Tool
//!
//! Run this once to authorize Google Drive access:
//!   cargo run --bin drive_config
//!
//! This will:
//! 1. Open your browser to Google OAuth
//! 2. Wait for you to authorize
//! 3. Save tokens to secrets/google-drive-token.json

use anyhow::{Context, Result};
use axum::{extract::Query, response::Html, routing::get, Router};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::mpsc;

const REDIRECT_URI: &str = "http://localhost:8085/callback";

fn get_oauth_client_id() -> String {
    std::env::var("GOOGLE_DRIVE_CLIENT_ID")
        .or_else(|_| std::env::var("GOOGLE_CLIENT_ID"))
        .expect("GOOGLE_DRIVE_CLIENT_ID or GOOGLE_CLIENT_ID must be set")
}

fn get_oauth_client_secret() -> String {
    std::env::var("GOOGLE_DRIVE_CLIENT_SECRET")
        .or_else(|_| std::env::var("GOOGLE_CLIENT_SECRET"))
        .expect("GOOGLE_DRIVE_CLIENT_SECRET or GOOGLE_CLIENT_SECRET must be set")
}
const TOKEN_FILE: &str = "secrets/google-drive-token.json";

#[derive(Deserialize)]
struct CallbackParams {
    code: Option<String>,
    error: Option<String>,
}

#[derive(Serialize, Deserialize)]
struct TokenResponse {
    access_token: String,
    refresh_token: Option<String>,
    expires_in: u64,
    token_type: String,
    scope: Option<String>,
}

#[derive(Serialize, Deserialize)]
pub struct StoredToken {
    pub access_token: String,
    pub refresh_token: String,
    pub expires_at: i64,
}

#[tokio::main]
async fn main() -> Result<()> {
    println!("🔧 Google Drive Configuration Tool");
    println!("===================================\n");

    // Check if token already exists
    if std::path::Path::new(TOKEN_FILE).exists() {
        println!("⚠️  Token file already exists: {}", TOKEN_FILE);
        println!("   Delete it first if you want to re-authorize.\n");

        // Try to refresh the existing token
        println!("Attempting to refresh existing token...");
        match refresh_existing_token().await {
            Ok(_) => {
                println!("✅ Token refreshed successfully!");
                return Ok(());
            }
            Err(e) => {
                println!("❌ Failed to refresh token: {}", e);
                println!("   Delete {} and run again to re-authorize.\n", TOKEN_FILE);
                return Err(e);
            }
        }
    }

    // Create channel to receive auth code
    let (tx, mut rx) = mpsc::channel::<String>(1);
    let tx = Arc::new(tx);

    // Get OAuth credentials from environment
    let client_id = get_oauth_client_id();
    let client_secret = get_oauth_client_secret();

    // Build the OAuth URL
    let auth_url = format!(
        "https://accounts.google.com/o/oauth2/v2/auth?\
        client_id={}&\
        redirect_uri={}&\
        response_type=code&\
        scope=https://www.googleapis.com/auth/drive.file&\
        access_type=offline&\
        prompt=consent",
        client_id,
        urlencoding::encode(REDIRECT_URI)
    );

    // Start callback server
    let tx_clone = tx.clone();
    let server = tokio::spawn(async move {
        let app = Router::new().route(
            "/callback",
            get(move |Query(params): Query<CallbackParams>| {
                let tx = tx_clone.clone();
                async move {
                    if let Some(code) = params.code {
                        let _ = tx.send(code).await;
                        Html("<html><body><h1>✅ Authorization successful!</h1><p>You can close this window and return to the terminal.</p></body></html>".to_string())
                    } else {
                        let error = params.error.unwrap_or_else(|| "Unknown error".to_string());
                        Html(format!("<html><body><h1>❌ Authorization failed</h1><p>{}</p></body></html>", error))
                    }
                }
            }),
        );

        let listener = tokio::net::TcpListener::bind("127.0.0.1:8085")
            .await
            .expect("Failed to bind to port 8085");

        axum::serve(listener, app).await.expect("Server error");
    });

    println!("1️⃣  Opening browser for Google authorization...\n");
    println!("   If browser doesn't open, visit this URL:\n");
    println!("   {}\n", auth_url);

    // Open browser
    if let Err(e) = webbrowser::open(&auth_url) {
        println!("   (Could not open browser automatically: {})", e);
    }

    println!("2️⃣  Waiting for authorization...\n");

    // Wait for the code
    let code = rx.recv().await.context("Failed to receive auth code")?;

    println!("3️⃣  Exchanging code for tokens...\n");

    // Exchange code for tokens
    let client = reqwest::Client::new();
    let params = [
        ("client_id", client_id.as_str()),
        ("client_secret", client_secret.as_str()),
        ("code", code.as_str()),
        ("grant_type", "authorization_code"),
        ("redirect_uri", REDIRECT_URI),
    ];

    let response = client
        .post("https://oauth2.googleapis.com/token")
        .form(&params)
        .send()
        .await
        .context("Failed to exchange code")?;

    if !response.status().is_success() {
        let error_text = response.text().await?;
        anyhow::bail!("Token exchange failed: {}", error_text);
    }

    let token_response: TokenResponse = response.json().await?;

    let refresh_token = token_response
        .refresh_token
        .context("No refresh token received. Try deleting the token file and re-authorizing.")?;

    // Calculate expiration time
    let expires_at = chrono::Utc::now().timestamp() + token_response.expires_in as i64;

    // Save tokens
    let stored_token = StoredToken {
        access_token: token_response.access_token,
        refresh_token,
        expires_at,
    };

    // Ensure secrets directory exists
    std::fs::create_dir_all("secrets").ok();

    let token_json = serde_json::to_string_pretty(&stored_token)?;
    std::fs::write(TOKEN_FILE, &token_json).context("Failed to write token file")?;

    println!("✅ Authorization successful!");
    println!("   Token saved to: {}\n", TOKEN_FILE);

    // Stop the server
    server.abort();

    println!("🎉 Google Drive is now configured!");
    println!("   You can now restart the API server.\n");

    Ok(())
}

async fn refresh_existing_token() -> Result<()> {
    let token_data = std::fs::read_to_string(TOKEN_FILE)?;
    let stored: StoredToken = serde_json::from_str(&token_data)?;

    let client_id = get_oauth_client_id();
    let client_secret = get_oauth_client_secret();

    let client = reqwest::Client::new();
    let params = [
        ("client_id", client_id.as_str()),
        ("client_secret", client_secret.as_str()),
        ("refresh_token", stored.refresh_token.as_str()),
        ("grant_type", "refresh_token"),
    ];

    let response = client
        .post("https://oauth2.googleapis.com/token")
        .form(&params)
        .send()
        .await?;

    if !response.status().is_success() {
        let error_text = response.text().await?;
        anyhow::bail!("Token refresh failed: {}", error_text);
    }

    let token_response: TokenResponse = response.json().await?;
    let expires_at = chrono::Utc::now().timestamp() + token_response.expires_in as i64;

    let new_stored = StoredToken {
        access_token: token_response.access_token,
        refresh_token: token_response.refresh_token.unwrap_or(stored.refresh_token),
        expires_at,
    };

    let token_json = serde_json::to_string_pretty(&new_stored)?;
    std::fs::write(TOKEN_FILE, &token_json)?;

    Ok(())
}
