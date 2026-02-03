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

//! Wallet Management Tool
//!
//! Manage blockchain wallets: import existing keys or generate new ones.
//!
//! Usage:
//!   cargo run --bin wallet -- --import12w <public_address>
//!   cargo run --bin wallet -- --importpk <public_address>
//!   cargo run --bin wallet -- --new <public_address>
//!
//! Options:
//!   --import12w <address>  Import a 12-word BIP-39 mnemonic for an existing address
//!   --importpk <address>   Import a raw private key (64 hex chars) for an existing address
//!   --new <address>        Generate a new wallet and update the existing address record
//!
//! Examples:
//!   cargo run --bin wallet -- --import12w 0x732D57fE3478984E59fF48d224653097ec0C730f
//!   cargo run --bin wallet -- --importpk 0x732D57fE3478984E59fF48d224653097ec0C730f
//!   cargo run --bin wallet -- --new 0x732D57fE3478984E59fF48d224653097ec0C730f

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

#[derive(Debug, Clone, Copy, PartialEq)]
enum Command {
    Import12Words,
    ImportPrivateKey,
    NewWallet,
}

#[derive(Debug)]
struct AddressInfo {
    address_id: uuid::Uuid,
    wallet_id: uuid::Uuid,
    public_address: String,
    derivation_path: String,
    blockchain_code: String,
    has_encrypted_seed: bool,
    owner_name: String,
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

fn print_usage(program: &str) {
    eprintln!("Wallet Management Tool");
    eprintln!();
    eprintln!("Usage:");
    eprintln!("  {} --import12w <public_address>", program);
    eprintln!("  {} --importpk <public_address>", program);
    eprintln!("  {} --new <public_address>", program);
    eprintln!();
    eprintln!("Options:");
    eprintln!("  --import12w <address>  Import a 12-word BIP-39 mnemonic for an existing address");
    eprintln!("  --importpk <address>   Import a raw private key (64 hex chars) for an existing address");
    eprintln!("  --new <address>        Generate a new wallet and update the existing address record");
    eprintln!();
    eprintln!("Examples:");
    eprintln!("  cargo run --bin wallet -- --import12w 0x732D57fE3478984E59fF48d224653097ec0C730f");
    eprintln!("  cargo run --bin wallet -- --importpk 0x732D57fE3478984E59fF48d224653097ec0C730f");
    eprintln!("  cargo run --bin wallet -- --new 0x732D57fE3478984E59fF48d224653097ec0C730f");
}

fn parse_args() -> Result<(Command, String)> {
    let args: Vec<String> = std::env::args().collect();

    if args.len() != 3 {
        print_usage(&args[0]);
        std::process::exit(1);
    }

    let command = match args[1].as_str() {
        "--import12w" => Command::Import12Words,
        "--importpk" => Command::ImportPrivateKey,
        "--new" => Command::NewWallet,
        other => {
            eprintln!("Error: Unknown option '{}'", other);
            eprintln!();
            print_usage(&args[0]);
            std::process::exit(1);
        }
    };

    let address = args[2].clone();
    Ok((command, address))
}

#[tokio::main]
async fn main() -> Result<()> {
    dotenvy::dotenv().ok();

    let (command, public_address) = parse_args()?;

    println!("Wallet Management Tool");
    println!("======================\n");

    // Connect to database
    let database_url = std::env::var("DATABASE_URL")
        .context("DATABASE_URL must be set in environment or .env file")?;

    let pool = PgPoolOptions::new()
        .max_connections(1)
        .connect(&database_url)
        .await
        .context("Failed to connect to database")?;

    println!("Connected to database\n");

    // Query for the address and owner
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
                AS has_encrypted_seed,
            p.full_name AS owner_name
        FROM accounts_schema.account_blockchain_addresses addr
        INNER JOIN accounts_schema.account_blockchain wallet
            ON wallet.id = addr.account_blockchain_id
        INNER JOIN accounts_schema.account_holders ah
            ON ah.id = wallet.account_holder_id
        INNER JOIN registration_schema.people p
            ON p.id = ah.main_person_id
        WHERE LOWER(addr.public_address) = LOWER($1)
        "#,
    )
    .bind(&public_address)
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
                owner_name: row.get("owner_name"),
            };

            println!("Address found in database:");
            println!("   Owner:           {}", info.owner_name);
            println!("   Address ID:      {}", info.address_id);
            println!("   Wallet ID:       {}", info.wallet_id);
            println!("   Public Address:  {}", info.public_address);
            println!("   Derivation Path: {}", info.derivation_path);
            println!("   Blockchain:      {}", info.blockchain_code);
            println!();

            // Confirm operation with owner name
            let operation_desc = match command {
                Command::Import12Words => "IMPORT a 12-word mnemonic",
                Command::ImportPrivateKey => "IMPORT a private key",
                Command::NewWallet => "GENERATE a new wallet",
            };

            println!("You are about to {} for:", operation_desc);
            println!("   Owner: {}", info.owner_name);
            println!("   Address: {}", info.public_address);
            println!();
            print!("Type 'yes' to confirm: ");
            io::stdout().flush()?;

            let mut confirm_input = String::new();
            io::stdin().read_line(&mut confirm_input)?;
            if confirm_input.trim().to_lowercase() != "yes" {
                println!("\nAborted.");
                return Ok(());
            }
            println!();

            match command {
                Command::Import12Words | Command::ImportPrivateKey => {
                    if info.has_encrypted_seed {
                        println!("Status: Wallet HAS an encrypted master seed");
                        println!("   Cannot import - private key already exists.");
                        println!("   Use --new to generate a fresh wallet instead.");
                    } else {
                        println!("Status: Wallet has NO encrypted master seed");
                        println!("   Ready for private key import.\n");
                        import_wallet(&pool, &info, command).await?;
                    }
                }
                Command::NewWallet => {
                    if info.has_encrypted_seed {
                        println!("Status: Wallet HAS an encrypted master seed");
                        println!();
                        print!("WARNING: This will REPLACE the existing wallet with a new one!\n");
                        print!("         The old private key will be lost forever.\n");
                        print!("         Type 'yes' to confirm replacement: ");
                        io::stdout().flush()?;

                        let mut input = String::new();
                        io::stdin().read_line(&mut input)?;
                        if input.trim().to_lowercase() != "yes" {
                            println!("\nAborted.");
                            return Ok(());
                        }
                        println!();
                    }
                    generate_new_wallet(&pool, &info).await?;
                }
            }
        }
        None => {
            println!("Address not found in database");
            println!(
                "   The address '{}' does not exist in account_blockchain_addresses.",
                public_address
            );
        }
    }

    println!();
    Ok(())
}

async fn import_wallet(pool: &sqlx::PgPool, info: &AddressInfo, command: Command) -> Result<()> {
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

    // Prompt for input based on command
    let prompt = match command {
        Command::Import12Words => "Enter your 12-word mnemonic phrase:",
        Command::ImportPrivateKey => "Enter your private key (64 hex chars, with or without 0x):",
        Command::NewWallet => unreachable!(),
    };
    println!("{}", prompt);
    print!("> ");
    io::stdout().flush()?;

    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    let input = input.trim();

    // Parse input based on command
    let import_type = match command {
        Command::Import12Words => parse_mnemonic(input)?,
        Command::ImportPrivateKey => parse_private_key(input)?,
        Command::NewWallet => unreachable!(),
    };

    // Process based on type
    let data_to_encrypt: Vec<u8> = match &import_type {
        ImportType::Mnemonic(mnemonic) => {
            println!("\nValid 12-word mnemonic detected\n");

            // Convert mnemonic to seed
            let seed_bytes = mnemonic.to_seed("");
            let mut seed = [0u8; 64];
            seed.copy_from_slice(&seed_bytes);

            // Extract address index from derivation path
            let index = parse_address_index(&info.derivation_path)?;

            // Derive address from seed to verify
            let derived_address = derive_address_from_seed(&seed, index)?;

            println!("Verifying derived address...");
            println!("   Expected: {}", info.public_address);
            println!("   Derived:  {}", derived_address);

            if derived_address.to_lowercase() != info.public_address.to_lowercase() {
                anyhow::bail!(
                    "Address mismatch! The mnemonic does not generate the expected address.\n\
                     This mnemonic belongs to a different wallet."
                );
            }

            println!("\nAddress verification successful!\n");
            seed.to_vec()
        }
        ImportType::PrivateKey(private_key) => {
            println!("\nValid private key detected (64 hex chars)\n");

            // Derive address from private key to verify
            let derived_address = derive_address_from_private_key(private_key)?;

            println!("Verifying derived address...");
            println!("   Expected: {}", info.public_address);
            println!("   Derived:  {}", derived_address);

            if derived_address.to_lowercase() != info.public_address.to_lowercase() {
                anyhow::bail!(
                    "Address mismatch! The private key does not generate the expected address.\n\
                     This private key belongs to a different wallet."
                );
            }

            println!("\nAddress verification successful!\n");

            // Store just the 32-byte private key (not padded)
            private_key.to_vec()
        }
    };

    // Encrypt the data
    println!("Encrypting...");
    let encrypted = encrypt_data(&data_to_encrypt, &encryption_key)?;

    // Update the database
    println!("Saving to database...");

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

    println!("\nWallet imported successfully!");
    println!("   Stored: encrypted {}", key_type);

    Ok(())
}

async fn generate_new_wallet(pool: &sqlx::PgPool, info: &AddressInfo) -> Result<()> {
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

    println!("Generating new wallet...\n");

    // Generate 128-bit entropy for 12-word mnemonic
    let mut entropy = [0u8; 16];
    rand::thread_rng().fill_bytes(&mut entropy);

    // Generate 12-word mnemonic
    let mnemonic = Mnemonic::from_entropy_in(Language::English, &entropy)
        .context("Failed to generate mnemonic")?;

    // Convert to seed (no passphrase)
    let seed_bytes = mnemonic.to_seed("");
    let mut seed = [0u8; 64];
    seed.copy_from_slice(&seed_bytes);

    // Extract address index from derivation path (usually 0)
    let index = parse_address_index(&info.derivation_path)?;

    // Derive address from seed
    let new_address = derive_address_from_seed(&seed, index)?;

    println!("============================================================");
    println!("                   NEW WALLET GENERATED");
    println!("============================================================");
    println!();
    println!("MNEMONIC PHRASE (WRITE THIS DOWN AND KEEP IT SAFE!):");
    println!();
    println!("   {}", mnemonic);
    println!();
    println!("============================================================");
    println!();
    println!("New address:     {}", new_address);
    println!("Old address:     {}", info.public_address);
    println!("Derivation path: {}", info.derivation_path);
    println!();

    // Encrypt the seed
    println!("Encrypting seed...");
    let encrypted = encrypt_data(&seed, &encryption_key)?;

    // Update the database - both the wallet and the address
    println!("Updating database...");

    // Start a transaction
    let mut tx = pool.begin().await.context("Failed to start transaction")?;

    // Update the encrypted seed
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
    .execute(&mut *tx)
    .await
    .context("Failed to update account_blockchain")?;

    // Update the public address
    sqlx::query(
        r#"
        UPDATE accounts_schema.account_blockchain_addresses
        SET public_address = $1
        WHERE id = $2
        "#,
    )
    .bind(&new_address)
    .bind(info.address_id)
    .execute(&mut *tx)
    .await
    .context("Failed to update account_blockchain_addresses")?;

    tx.commit().await.context("Failed to commit transaction")?;

    println!("\nNew wallet created successfully!");
    println!("   Address updated from: {}", info.public_address);
    println!("   Address updated to:   {}", new_address);
    println!();
    println!("IMPORTANT: Make sure you have written down your mnemonic phrase!");
    println!("           It is the ONLY way to recover your wallet.");

    Ok(())
}

/// Parse input as a 12-word mnemonic
fn parse_mnemonic(input: &str) -> Result<ImportType> {
    let word_count = input.split_whitespace().count();
    if word_count != 12 {
        anyhow::bail!(
            "Invalid mnemonic. Expected 12 words, got {} words.",
            word_count
        );
    }

    let mnemonic = Mnemonic::parse_in_normalized(Language::English, input)
        .context("Invalid mnemonic phrase. Please enter 12 valid BIP-39 words.")?;

    Ok(ImportType::Mnemonic(mnemonic))
}

/// Parse input as a private key (64 hex chars)
fn parse_private_key(input: &str) -> Result<ImportType> {
    let hex_input = input.strip_prefix("0x").unwrap_or(input);

    if hex_input.len() != 64 {
        anyhow::bail!(
            "Invalid private key length. Expected 64 hex characters, got {}.",
            hex_input.len()
        );
    }

    if !hex_input.chars().all(|c| c.is_ascii_hexdigit()) {
        anyhow::bail!("Invalid private key. Contains non-hexadecimal characters.");
    }

    let bytes = hex::decode(hex_input).context("Invalid hex in private key")?;
    let mut private_key = [0u8; 32];
    private_key.copy_from_slice(&bytes);

    // Validate it's a valid secp256k1 private key
    SecretKey::from_slice(&private_key)
        .context("Invalid private key (not on secp256k1 curve)")?;

    Ok(ImportType::PrivateKey(private_key))
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
