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

use anyhow::{Context, Result};
use bip39::{Language, Mnemonic};
use secp256k1::{PublicKey, Secp256k1, SecretKey};
use tiny_hderive::bip32::ExtendedPrivKey;

pub struct GeneratedWallet {
    #[allow(dead_code)]
    pub mnemonic: String,
    pub seed: [u8; 64],
    pub polygon_address: String,
}

/// Generate a new BIP-39 wallet with a 12-word mnemonic and derive the first Polygon address.
///
/// Returns:
/// - 12-word mnemonic phrase
/// - 512-bit seed
/// - Polygon address (m/44'/60'/0'/0/0)
pub fn generate_wallet() -> Result<GeneratedWallet> {
    // Generate 128-bit entropy for 12-word mnemonic
    let mut entropy = [0u8; 16];
    use rand::RngCore;
    rand::thread_rng().fill_bytes(&mut entropy);

    // Generate 12-word mnemonic
    let mnemonic = Mnemonic::from_entropy_in(Language::English, &entropy)
        .context("Failed to generate mnemonic")?;

    // Convert to seed (no passphrase)
    let seed_bytes = mnemonic.to_seed("");
    let mut seed = [0u8; 64];
    seed.copy_from_slice(&seed_bytes);

    // Derive Polygon address from seed
    let polygon_address = derive_polygon_address(&seed, 0)?;

    Ok(GeneratedWallet {
        mnemonic: mnemonic.to_string(),
        seed,
        polygon_address,
    })
}

/// Derive a Polygon (EVM) address from a BIP-39 seed using BIP-44 derivation path.
///
/// Derivation path: m/44'/60'/0'/0/{index}
/// - 44': BIP-44
/// - 60': Ethereum coin type
/// - 0': Account 0
/// - 0: External chain
/// - index: Address index
pub fn derive_polygon_address(seed: &[u8; 64], index: u32) -> Result<String> {
    // Create full derivation path including the index
    let full_path = format!("m/44'/60'/0'/0/{}", index);

    // Derive extended private key from seed using full path
    let ext_key = ExtendedPrivKey::derive(seed, full_path.as_str())
        .map_err(|e| anyhow::anyhow!("Failed to derive HD key: {:?}", e))?;

    // Get the 32-byte private key
    let private_key_bytes = ext_key.secret();

    // Create secp256k1 keypair
    let secp = Secp256k1::new();
    let secret_key = SecretKey::from_slice(&private_key_bytes[..])
        .context("Invalid private key")?;
    let public_key = PublicKey::from_secret_key(&secp, &secret_key);

    // Get uncompressed public key (65 bytes: 0x04 + 64 bytes)
    let public_key_bytes = public_key.serialize_uncompressed();

    // Ethereum address = last 20 bytes of keccak256(public_key[1..65])
    let hash = keccak256(&public_key_bytes[1..]);
    let address_bytes = &hash[12..]; // Last 20 bytes

    // Format as 0x... hex string
    let address = format!("0x{}", hex::encode(address_bytes));

    Ok(address)
}

/// Derive the private key from a BIP-39 seed using BIP-44 derivation path.
///
/// Derivation path: m/44'/60'/0'/0/{index}
pub fn derive_private_key(seed: &[u8; 64], index: u32) -> Result<[u8; 32]> {
    let full_path = format!("m/44'/60'/0'/0/{}", index);

    let ext_key = ExtendedPrivKey::derive(seed, full_path.as_str())
        .map_err(|e| anyhow::anyhow!("Failed to derive HD key: {:?}", e))?;

    let private_key_bytes = ext_key.secret();
    let mut key = [0u8; 32];
    key.copy_from_slice(&private_key_bytes[..]);

    Ok(key)
}

/// Keccak-256 hash function (Ethereum uses this instead of SHA3)
fn keccak256(data: &[u8]) -> [u8; 32] {
    use tiny_keccak::{Hasher, Keccak};
    let mut hasher = Keccak::v256();
    let mut output = [0u8; 32];
    hasher.update(data);
    hasher.finalize(&mut output);
    output
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_wallet() {
        let wallet = generate_wallet().unwrap();

        // Check mnemonic has 12 words
        assert_eq!(wallet.mnemonic.split_whitespace().count(), 12);

        // Check seed is 64 bytes
        assert_eq!(wallet.seed.len(), 64);

        // Check address format
        assert!(wallet.polygon_address.starts_with("0x"));
        assert_eq!(wallet.polygon_address.len(), 42); // 0x + 40 hex chars
    }

    #[test]
    fn test_derive_polygon_address() {
        // Test with a known seed
        let seed = [0u8; 64];
        let address = derive_polygon_address(&seed, 0).unwrap();

        // Should be a valid Ethereum address format
        assert!(address.starts_with("0x"));
        assert_eq!(address.len(), 42);
    }

    #[test]
    fn test_multiple_addresses_from_same_seed() {
        let seed = [1u8; 64];

        let addr0 = derive_polygon_address(&seed, 0).unwrap();
        let addr1 = derive_polygon_address(&seed, 1).unwrap();

        // Addresses should be different
        assert_ne!(addr0, addr1);

        // But deriving the same index should give the same address
        let addr0_again = derive_polygon_address(&seed, 0).unwrap();
        assert_eq!(addr0, addr0_again);
    }
}
