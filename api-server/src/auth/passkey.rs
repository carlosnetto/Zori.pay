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
use std::collections::HashMap;
use std::sync::RwLock;
use url::Url;
use uuid::Uuid;
use webauthn_rs::prelude::*;

use crate::db::PasskeyCredential;
use crate::models::{AllowedCredential, PasskeyChallengeResponse, PasskeyVerifyRequest};

pub struct PasskeyAuth {
    webauthn: Webauthn,
    rp_id: String,
    // In-memory storage for authentication challenges (should be Redis in production)
    auth_challenges: RwLock<HashMap<Uuid, PasskeyAuthentication>>,
    // Store passkeys for lookup during verification
    passkeys_cache: RwLock<HashMap<Uuid, Vec<Passkey>>>,
}

impl PasskeyAuth {
    pub fn new(rp_id: &str, rp_origin: &str) -> Result<Self> {
        let rp_origin = Url::parse(rp_origin)?;

        let builder = WebauthnBuilder::new(rp_id, &rp_origin)?
            .rp_name("Zori.pay");

        let webauthn = builder.build()?;

        Ok(Self {
            webauthn,
            rp_id: rp_id.to_string(),
            auth_challenges: RwLock::new(HashMap::new()),
            passkeys_cache: RwLock::new(HashMap::new()),
        })
    }

    /// Generate a passkey authentication challenge for the given credentials.
    pub fn generate_challenge(
        &self,
        person_id: Uuid,
        credentials: &[PasskeyCredential],
    ) -> Result<PasskeyChallengeResponse> {
        // Convert stored credentials to webauthn format
        let passkeys: Vec<Passkey> = credentials
            .iter()
            .filter_map(|c| self.credential_to_passkey(c).ok())
            .collect();

        if passkeys.is_empty() {
            anyhow::bail!("No valid credentials found");
        }

        // Start authentication
        let (rcr, auth_state) = self
            .webauthn
            .start_passkey_authentication(&passkeys)?;

        // Store the challenge state and passkeys for later verification
        {
            let mut challenges = self.auth_challenges.write().unwrap();
            challenges.insert(person_id, auth_state);
        }
        {
            let mut cache = self.passkeys_cache.write().unwrap();
            cache.insert(person_id, passkeys);
        }

        // Build response
        let allowed_creds: Vec<AllowedCredential> = credentials
            .iter()
            .map(|c| AllowedCredential {
                cred_type: "public-key".to_string(),
                id: base64_url_encode(&c.credential_id),
                transports: c.transports.clone(),
            })
            .collect();

        Ok(PasskeyChallengeResponse {
            challenge: base64_url_encode(rcr.public_key.challenge.as_ref()),
            timeout: 60000,
            rp_id: self.rp_id.clone(),
            user_verification: "required".to_string(),
            allowed_credentials: allowed_creds,
        })
    }

    /// Verify the passkey response from the client.
    /// Returns the credential ID that was used (to update the counter).
    pub fn verify_response(
        &self,
        person_id: Uuid,
        request: &PasskeyVerifyRequest,
    ) -> Result<(Vec<u8>, u32)> {
        // Retrieve the challenge state
        let auth_state = {
            let mut challenges = self.auth_challenges.write().unwrap();
            challenges
                .remove(&person_id)
                .ok_or_else(|| anyhow::anyhow!("No pending authentication challenge"))?
        };

        // Parse the client response as JSON (this is the format browsers send)
        let credential_id = base64_url_decode(&request.credential_id)?;

        // The client sends the PublicKeyCredential as a JSON object
        // We reconstruct it here using serde
        let auth_response: PublicKeyCredential = serde_json::from_value(serde_json::json!({
            "id": request.credential_id,
            "rawId": request.credential_id,
            "response": {
                "authenticatorData": request.authenticator_data,
                "clientDataJSON": request.client_data_json,
                "signature": request.signature,
                "userHandle": request.user_handle
            },
            "type": "public-key"
        }))?;

        // Verify the response
        let auth_result = self
            .webauthn
            .finish_passkey_authentication(&auth_response, &auth_state)?;

        // Clean up cache
        {
            let mut cache = self.passkeys_cache.write().unwrap();
            cache.remove(&person_id);
        }

        // Return the credential ID and new counter
        Ok((credential_id, auth_result.counter()))
    }

    /// Convert a stored credential to webauthn Passkey format
    fn credential_to_passkey(&self, cred: &PasskeyCredential) -> Result<Passkey> {
        // Deserialize the stored passkey (we store the full serialized Passkey)
        let passkey: Passkey = serde_json::from_slice(&cred.public_key)?;
        Ok(passkey)
    }
}

fn base64_url_encode(data: &[u8]) -> String {
    use base64::engine::general_purpose::URL_SAFE_NO_PAD;
    use base64::Engine;
    URL_SAFE_NO_PAD.encode(data)
}

fn base64_url_decode(data: &str) -> Result<Vec<u8>> {
    use base64::engine::general_purpose::URL_SAFE_NO_PAD;
    use base64::Engine;
    Ok(URL_SAFE_NO_PAD.decode(data)?)
}
