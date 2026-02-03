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

use aes_gcm::{
    aead::{Aead, KeyInit, OsRng},
    Aes256Gcm, Nonce,
};
use anyhow::{Context, Result};
use rand::RngCore;

#[derive(Debug)]
pub struct EncryptedSeed {
    pub ciphertext: Vec<u8>,
    pub iv: [u8; 12],
    pub auth_tag: [u8; 16],
}

/// Encrypt a 64-byte seed using AES-256-GCM.
///
/// Returns:
/// - Ciphertext (encrypted seed)
/// - IV/Nonce (12 bytes) - must be unique for each encryption
/// - Authentication tag (16 bytes) - ensures integrity
pub fn encrypt_seed(seed: &[u8; 64], key: &[u8]) -> Result<EncryptedSeed> {
    if key.len() != 32 {
        anyhow::bail!("Encryption key must be 32 bytes");
    }

    // Generate random 12-byte IV
    let mut iv = [0u8; 12];
    OsRng.fill_bytes(&mut iv);

    // Create cipher
    let cipher = Aes256Gcm::new_from_slice(key)
        .context("Failed to create cipher")?;

    let nonce = Nonce::from_slice(&iv);

    // Encrypt (this includes the auth tag in the output)
    let ciphertext_with_tag = cipher
        .encrypt(nonce, seed.as_ref())
        .map_err(|e| anyhow::anyhow!("Encryption failed: {}", e))?;

    // AES-GCM appends the 16-byte tag to the ciphertext
    let tag_start = ciphertext_with_tag.len() - 16;
    let ciphertext = ciphertext_with_tag[..tag_start].to_vec();
    let mut auth_tag = [0u8; 16];
    auth_tag.copy_from_slice(&ciphertext_with_tag[tag_start..]);

    Ok(EncryptedSeed {
        ciphertext,
        iv,
        auth_tag,
    })
}

/// Decrypt an encrypted seed using AES-256-GCM.
///
/// Verifies the authentication tag to ensure integrity.
pub fn decrypt_seed(encrypted: &EncryptedSeed, key: &[u8]) -> Result<[u8; 64]> {
    if key.len() != 32 {
        anyhow::bail!("Decryption key must be 32 bytes");
    }

    // Create cipher
    let cipher = Aes256Gcm::new_from_slice(key)
        .context("Failed to create cipher")?;

    let nonce = Nonce::from_slice(&encrypted.iv);

    // Reconstruct ciphertext with tag
    let mut ciphertext_with_tag = encrypted.ciphertext.clone();
    ciphertext_with_tag.extend_from_slice(&encrypted.auth_tag);

    // Decrypt (automatically verifies auth tag)
    let plaintext = cipher
        .decrypt(nonce, ciphertext_with_tag.as_ref())
        .map_err(|e| anyhow::anyhow!("Decryption failed: {}", e))?;

    if plaintext.len() != 64 {
        anyhow::bail!("Decrypted seed has invalid length");
    }

    let mut seed = [0u8; 64];
    seed.copy_from_slice(&plaintext);

    Ok(seed)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encrypt_decrypt_roundtrip() {
        let key = [42u8; 32];
        let seed = [7u8; 64];

        let encrypted = encrypt_seed(&seed, &key).unwrap();

        // Check IV is not all zeros
        assert_ne!(encrypted.iv, [0u8; 12]);

        // Decrypt and verify
        let decrypted = decrypt_seed(&encrypted, &key).unwrap();
        assert_eq!(seed, decrypted);
    }

    #[test]
    fn test_wrong_key_fails() {
        let key1 = [1u8; 32];
        let key2 = [2u8; 32];
        let seed = [7u8; 64];

        let encrypted = encrypt_seed(&seed, &key1).unwrap();

        // Decrypting with wrong key should fail
        assert!(decrypt_seed(&encrypted, &key2).is_err());
    }

    #[test]
    fn test_tampered_ciphertext_fails() {
        let key = [1u8; 32];
        let seed = [7u8; 64];

        let mut encrypted = encrypt_seed(&seed, &key).unwrap();

        // Tamper with ciphertext
        encrypted.ciphertext[0] ^= 1;

        // Decryption should fail due to auth tag mismatch
        assert!(decrypt_seed(&encrypted, &key).is_err());
    }

    #[test]
    fn test_different_iv_each_time() {
        let key = [1u8; 32];
        let seed = [7u8; 64];

        let enc1 = encrypt_seed(&seed, &key).unwrap();
        let enc2 = encrypt_seed(&seed, &key).unwrap();

        // IVs should be different
        assert_ne!(enc1.iv, enc2.iv);

        // Both should decrypt correctly
        let dec1 = decrypt_seed(&enc1, &key).unwrap();
        let dec2 = decrypt_seed(&enc2, &key).unwrap();
        assert_eq!(dec1, seed);
        assert_eq!(dec2, seed);
    }
}
