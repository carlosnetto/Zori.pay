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

//! Wallet Import Tool
//!
//! Check if a blockchain address exists and import a mnemonic or private key.
//!
//! Usage:
//!   cargo run --bin import_wallet -- <public_address>
//!
//! Example:
//!   cargo run --bin import_wallet -- 0x732D57fE3478984E59fF48d224653097ec0C730f
//!
//! Supports importing:
//!   - 12-word BIP-39 mnemonic phrase
//!   - Raw private key (64 hex chars, with or without 0x prefix)

use aes_gcm::{
    aead::{Aead, KeyInit, OsRng},
    Aes256Gcm, Nonce,
};
use anyhow::{Context, Result};
use bip39::{Language, Mnemonic};
use rand::RngCore;
use secp256k1::{PublicKey, Secp256k1, SecretKey};
use sqlx::postgres::PgPoolOptions;
use sqlx::Row;
use std::io::{self, Write};
use tiny_hderive::bip32::ExtendedPrivKey;

#[derive(Debug)]
struct AddressInfo {
    address_id: uuid::Uuid,
    wallet_id: uuid::Uuid,
    public_address: String,
    derivation_path: String,
    blockchain_code: String,
    has_encrypted_seed: bool,
}

#[derive(Debug)]
struct EncryptedData {
    ciphertext: Vec<u8>,
    iv: [u8; 12],
    auth_tag: [u8; 16],
}

/// Type of key being imported
enum ImportType {
    Mnemonic(Mnemonic),
    PrivateKey([u8; 32]),
}

#[tokio::main]
async fn main() -> Result<()> {
    dotenvy::dotenv().ok();

    // Parse command-line arguments
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 2 {
        eprintln!("Usage: {} <public_address>", args[0]);
        eprintln!();
        eprintln!("Example:");
        eprintln!("  cargo run --bin import_wallet -- 0x732D57fE3478984E59fF48d224653097ec0C730f");
        std::process::exit(1);
    }

    let public_address = &args[1];

    println!("🔍 Wallet Import Tool");
    println!("=====================\n");
    println!("Checking address: {}\n", public_address);

    // Connect to database
    let database_url = std::env::var("DATABASE_URL")
        .context("DATABASE_URL must be set in environment or .env file")?;

    let pool = PgPoolOptions::new()
        .max_connections(1)
        .connect(&database_url)
        .await
        .context("Failed to connect to database")?;

    println!("✅ Connected to database\n");

    // Query for the address
    // Check for NULL or placeholder value in encrypted_master_seed
    // A real encrypted key has encryption_key_id != 'PLACEHOLDER_TO_BE_UPDATED'
    let result = sqlx::query(
        r#"
        SELECT
            addr.id AS address_id,
            addr.public_address,
            addr.derivation_path,
            wallet.id AS wallet_id,
            wallet.blockchain_code,
            wallet.encrypted_master_seed IS NOT NULL
                AND wallet.encryption_key_id != 'PLACEHOLDER_TO_BE_UPDATED'
                AS has_encrypted_seed
        FROM accounts_schema.account_blockchain_addresses addr
        INNER JOIN accounts_schema.account_blockchain wallet
            ON wallet.id = addr.account_blockchain_id
        WHERE LOWER(addr.public_address) = LOWER($1)
        "#,
    )
    .bind(public_address)
    .fetch_optional(&pool)
    .await
    .context("Database query failed")?;

    match result {
        Some(row) => {
            let info = AddressInfo {
                address_id: row.get("address_id"),
                wallet_id: row.get("wallet_id"),
                public_address: row.get("public_address"),
                derivation_path: row.get("derivation_path"),
                blockchain_code: row.get("blockchain_code"),
                has_encrypted_seed: row.get("has_encrypted_seed"),
            };

            println!("📋 Address found in database:");
            println!("   Address ID:      {}", info.address_id);
            println!("   Wallet ID:       {}", info.wallet_id);
            println!("   Public Address:  {}", info.public_address);
            println!("   Derivation Path: {}", info.derivation_path);
            println!("   Blockchain:      {}", info.blockchain_code);
            println!();

            if info.has_encrypted_seed {
                println!("🔐 Status: Wallet HAS an encrypted master seed");
                println!("   Cannot import - private key already exists.");
            } else {
                println!("📭 Status: Wallet has NO encrypted master seed");
                println!("   Ready for private key import.\n");

                // Prompt for mnemonic or private key and import
                import_wallet(&pool, &info).await?;
            }
        }
        None => {
            println!("❌ Address not found in database");
            println!(
                "   The address '{}' does not exist in account_blockchain_addresses.",
                public_address
            );
        }
    }

    println!();
    Ok(())
}

async fn import_wallet(pool: &sqlx::PgPool, info: &AddressInfo) -> Result<()> {
    // Get encryption key from environment
    let key_hex = std::env::var("MASTER_ENCRYPTION_KEY")
        .context("MASTER_ENCRYPTION_KEY must be set in environment or .env file")?;
    let encryption_key =
        hex::decode(&key_hex).context("MASTER_ENCRYPTION_KEY must be valid hex")?;
    if encryption_key.len() != 32 {
        anyhow::bail!("MASTER_ENCRYPTION_KEY must be 32 bytes (64 hex chars)");
    }

    let encryption_key_id =
        std::env::var("ENCRYPTION_KEY_ID").unwrap_or_else(|_| "env-v1".into());

    // Prompt for input
    println!("Enter your 12-word mnemonic phrase OR private key (hex):");
    print!("> ");
    io::stdout().flush()?;

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    let input = input.trim();

    // Detect input type
    let import_type = detect_input_type(input)?;

    // Process based on type
    let data_to_encrypt: Vec<u8> = match &import_type {
        ImportType::Mnemonic(mnemonic) => {
            println!("\n✅ Valid 12-word mnemonic detected\n");

            // Convert mnemonic to seed
            let seed_bytes = mnemonic.to_seed("");
            let mut seed = [0u8; 64];
            seed.copy_from_slice(&seed_bytes);

            // Extract address index from derivation path
            let index = parse_address_index(&info.derivation_path)?;

            // Derive address from seed to verify
            let derived_address = derive_address_from_seed(&seed, index)?;

            println!("🔍 Verifying derived address...");
            println!("   Expected: {}", info.public_address);
            println!("   Derived:  {}", derived_address);

            if derived_address.to_lowercase() != info.public_address.to_lowercase() {
                anyhow::bail!(
                    "Address mismatch! The mnemonic does not generate the expected address.\n\
                     This mnemonic belongs to a different wallet."
                );
            }

            println!("\n✅ Address verification successful!\n");
            seed.to_vec()
        }
        ImportType::PrivateKey(private_key) => {
            println!("\n✅ Valid private key detected (64 hex chars)\n");

            // Derive address from private key to verify
            let derived_address = derive_address_from_private_key(private_key)?;

            println!("🔍 Verifying derived address...");
            println!("   Expected: {}", info.public_address);
            println!("   Derived:  {}", derived_address);

            if derived_address.to_lowercase() != info.public_address.to_lowercase() {
                anyhow::bail!(
                    "Address mismatch! The private key does not generate the expected address.\n\
                     This private key belongs to a different wallet."
                );
            }

            println!("\n✅ Address verification successful!\n");

            // Store just the 32-byte private key (not padded)
            private_key.to_vec()
        }
    };

    // Encrypt the data
    println!("🔐 Encrypting...");
    let encrypted = encrypt_data(&data_to_encrypt, &encryption_key)?;

    // Update the database
    println!("💾 Saving to database...");

    sqlx::query(
        r#"
        UPDATE accounts_schema.account_blockchain
        SET
            encrypted_master_seed = $1,
            encryption_iv = $2,
            encryption_auth_tag = $3,
            encryption_key_id = $4
        WHERE id = $5
        "#,
    )
    .bind(&encrypted.ciphertext)
    .bind(&encrypted.iv[..])
    .bind(&encrypted.auth_tag[..])
    .bind(&encryption_key_id)
    .bind(info.wallet_id)
    .execute(pool)
    .await
    .context("Failed to update database")?;

    let key_type = match import_type {
        ImportType::Mnemonic(_) => "master seed (64 bytes from mnemonic)",
        ImportType::PrivateKey(_) => "private key (32 bytes)",
    };

    println!("\n🎉 Wallet imported successfully!");
    println!("   Stored: encrypted {}", key_type);

    Ok(())
}

/// Detect if input is a mnemonic (12 words) or a private key (64 hex chars)
fn detect_input_type(input: &str) -> Result<ImportType> {
    // Check if it looks like a private key (hex string)
    let hex_input = input.strip_prefix("0x").unwrap_or(input);

    if hex_input.len() == 64 && hex_input.chars().all(|c| c.is_ascii_hexdigit()) {
        // It's a private key
        let bytes = hex::decode(hex_input).context("Invalid hex in private key")?;
        let mut private_key = [0u8; 32];
        private_key.copy_from_slice(&bytes);

        // Validate it's a valid secp256k1 private key
        SecretKey::from_slice(&private_key).context("Invalid private key (not on secp256k1 curve)")?;

        return Ok(ImportType::PrivateKey(private_key));
    }

    // Try to parse as mnemonic
    let word_count = input.split_whitespace().count();
    if word_count != 12 {
        anyhow::bail!(
            "Invalid input. Expected:\n\
             - 12-word mnemonic phrase, OR\n\
             - Private key (64 hex characters, optionally with 0x prefix)\n\n\
             Got {} words / {} characters.",
            word_count,
            input.len()
        );
    }

    let mnemonic = Mnemonic::parse_in_normalized(Language::English, input)
        .context("Invalid mnemonic phrase. Please enter 12 valid BIP-39 words.")?;

    Ok(ImportType::Mnemonic(mnemonic))
}

/// Parse the address index from a BIP-44 derivation path.
/// e.g., "m/44'/60'/0'/0/0" -> 0
fn parse_address_index(path: &str) -> Result<u32> {
    let parts: Vec<&str> = path.split('/').collect();
    if parts.len() < 6 {
        anyhow::bail!("Invalid derivation path: {}", path);
    }
    let index_str = parts[5];
    index_str
        .parse()
        .context(format!("Invalid address index in path: {}", path))
}

/// Derive a Polygon (EVM) address from a BIP-39 seed using BIP-44 derivation path.
fn derive_address_from_seed(seed: &[u8; 64], index: u32) -> Result<String> {
    let full_path = format!("m/44'/60'/0'/0/{}", index);

    let ext_key = ExtendedPrivKey::derive(seed, full_path.as_str())
        .map_err(|e| anyhow::anyhow!("Failed to derive HD key: {:?}", e))?;

    let private_key_bytes = ext_key.secret();
    let mut private_key = [0u8; 32];
    private_key.copy_from_slice(&private_key_bytes[..]);

    derive_address_from_private_key(&private_key)
}

/// Derive a Polygon (EVM) address from a raw private key.
fn derive_address_from_private_key(private_key: &[u8; 32]) -> Result<String> {
    let secp = Secp256k1::new();
    let secret_key = SecretKey::from_slice(private_key).context("Invalid private key")?;
    let public_key = PublicKey::from_secret_key(&secp, &secret_key);

    let public_key_bytes = public_key.serialize_uncompressed();

    let hash = keccak256(&public_key_bytes[1..]);
    let address_bytes = &hash[12..];

    let address = format!("0x{}", hex::encode(address_bytes));
    Ok(address)
}

/// Keccak-256 hash function
fn keccak256(data: &[u8]) -> [u8; 32] {
    use tiny_keccak::{Hasher, Keccak};
    let mut hasher = Keccak::v256();
    let mut output = [0u8; 32];
    hasher.update(data);
    hasher.finalize(&mut output);
    output
}

/// Encrypt data using AES-256-GCM.
fn encrypt_data(data: &[u8], key: &[u8]) -> Result<EncryptedData> {
    if key.len() != 32 {
        anyhow::bail!("Encryption key must be 32 bytes");
    }

    // Generate random 12-byte IV
    let mut iv = [0u8; 12];
    OsRng.fill_bytes(&mut iv);

    // Create cipher
    let cipher = Aes256Gcm::new_from_slice(key).context("Failed to create cipher")?;

    let nonce = Nonce::from_slice(&iv);

    // Encrypt (this includes the auth tag in the output)
    let ciphertext_with_tag = cipher
        .encrypt(nonce, data)
        .map_err(|e| anyhow::anyhow!("Encryption failed: {}", e))?;

    // AES-GCM appends the 16-byte tag to the ciphertext
    let tag_start = ciphertext_with_tag.len() - 16;
    let ciphertext = ciphertext_with_tag[..tag_start].to_vec();
    let mut auth_tag = [0u8; 16];
    auth_tag.copy_from_slice(&ciphertext_with_tag[tag_start..]);

    Ok(EncryptedData {
        ciphertext,
        iv,
        auth_tag,
    })
}
