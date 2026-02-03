use anyhow::{Context, Result};
use oauth2::{
    basic::BasicClient, AuthUrl, AuthorizationCode, ClientId, ClientSecret, CsrfToken,
    RedirectUrl, Scope, TokenResponse, TokenUrl,
};
use serde::Deserialize;

const GOOGLE_AUTH_URL: &str = "https://accounts.google.com/o/oauth2/v2/auth";
const GOOGLE_TOKEN_URL: &str = "https://oauth2.googleapis.com/token";
const GOOGLE_USERINFO_URL: &str = "https://www.googleapis.com/oauth2/v3/userinfo";

pub struct GoogleOAuth {
    client_id: String,
    client_secret: String,
}

#[derive(Debug, Deserialize)]
pub struct GoogleUserInfo {
    pub email: String,
    pub email_verified: bool,
    pub name: Option<String>,
    pub picture: Option<String>,
    pub sub: String, // Google's unique user ID
}

impl GoogleOAuth {
    pub fn new(client_id: &str, client_secret: &str) -> Self {
        Self {
            client_id: client_id.to_string(),
            client_secret: client_secret.to_string(),
        }
    }

    /// Generate the Google OAuth authorization URL.
    /// Returns (authorization_url, csrf_state)
    pub fn get_authorization_url(&self, redirect_uri: &str) -> Result<(String, String)> {
        let client = self.build_client(redirect_uri)?;

        let (auth_url, csrf_token) = client
            .authorize_url(CsrfToken::new_random)
            .add_scope(Scope::new("email".to_string()))
            .add_scope(Scope::new("profile".to_string()))
            .add_scope(Scope::new("openid".to_string()))
            .url();

        Ok((auth_url.to_string(), csrf_token.secret().clone()))
    }

    /// Exchange authorization code for access token and fetch user info.
    pub async fn exchange_code(
        &self,
        code: &str,
        redirect_uri: &str,
    ) -> Result<GoogleUserInfo> {
        let client = self.build_client(redirect_uri)?;

        // Exchange code for token
        let token_result = client
            .exchange_code(AuthorizationCode::new(code.to_string()))
            .request_async(oauth2::reqwest::async_http_client)
            .await
            .context("Failed to exchange authorization code")?;

        let access_token = token_result.access_token().secret();

        // Fetch user info
        let user_info = self.fetch_user_info(access_token).await?;

        // Verify email is verified by Google
        if !user_info.email_verified {
            anyhow::bail!("Email not verified by Google");
        }

        Ok(user_info)
    }

    fn build_client(&self, redirect_uri: &str) -> Result<BasicClient> {
        let client = BasicClient::new(
            ClientId::new(self.client_id.clone()),
            Some(ClientSecret::new(self.client_secret.clone())),
            AuthUrl::new(GOOGLE_AUTH_URL.to_string())?,
            Some(TokenUrl::new(GOOGLE_TOKEN_URL.to_string())?),
        )
        .set_redirect_uri(RedirectUrl::new(redirect_uri.to_string())?);

        Ok(client)
    }

    async fn fetch_user_info(&self, access_token: &str) -> Result<GoogleUserInfo> {
        let client = reqwest::Client::new();

        let response = client
            .get(GOOGLE_USERINFO_URL)
            .bearer_auth(access_token)
            .send()
            .await
            .context("Failed to fetch user info from Google")?;

        if !response.status().is_success() {
            let status = response.status();
            let body = response.text().await.unwrap_or_default();
            anyhow::bail!("Google userinfo request failed: {} - {}", status, body);
        }

        let user_info: GoogleUserInfo = response
            .json()
            .await
            .context("Failed to parse Google user info")?;

        Ok(user_info)
    }
}
