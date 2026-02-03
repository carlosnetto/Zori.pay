use axum::{
    extract::State,
    http::HeaderMap,
    response::Json,
};
use bytes::Bytes;
use std::sync::Arc;

use crate::config::Config;
use crate::crypto::{encryption, wallet};
use crate::db::Database;
use crate::error::{ApiError, ApiResult};
use crate::models::{AccountOpeningBrData, AccountOpeningResponse, FileData};
use crate::services::google_drive::DriveClient;
use crate::AppState;

/// POST /v1/kyc/open-account-br
///
/// Brazilian account opening with KYC data and document uploads.
pub async fn open_account_br(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    body: Bytes,
) -> ApiResult<Json<AccountOpeningResponse>> {
    // Extract boundary from Content-Type header
    let boundary = headers
        .get("content-type")
        .and_then(|ct| ct.to_str().ok())
        .and_then(|ct| {
            multer::parse_boundary(ct).ok()
        })
        .ok_or_else(|| ApiError::InvalidRequest("Missing or invalid Content-Type".into()))?;

    // Create multipart parser from bytes
    let stream = futures_util::stream::once(async move { Result::<_, std::io::Error>::Ok(body) });
    let mut multipart = multer::Multipart::new(stream, boundary);
    // 1. Parse multipart form data
    let data = parse_multipart(&mut multipart, &state.config).await?;

    // 2. Validate inputs
    let validated = validate_kyc_data(data)?;

    // 3. Check CPF uniqueness
    if state.db.cpf_exists(&validated.cpf).await? {
        return Err(ApiError::CpfAlreadyExists);
    }

    // 4. Execute database transaction
    let (person_id, holder_id, address) = create_account_with_wallet(
        &state.db,
        &validated,
        &state.config.master_encryption_key,
        &state.config.encryption_key_id,
    )
    .await?;

    // 5. Spawn async background task for Drive upload
    let drive = state.drive_client.clone();
    let cpf = validated.cpf.clone();
    let files = extract_files_for_upload(validated);

    tokio::spawn(async move {
        match upload_to_drive(drive, files, cpf).await {
            Ok(_) => tracing::info!("Documents uploaded successfully"),
            Err(e) => tracing::error!("Failed to upload documents: {:?}", e),
        }
    });

    // 6. Return immediate success
    Ok(Json(AccountOpeningResponse {
        success: true,
        person_id,
        account_holder_id: holder_id,
        polygon_address: address,
        message: "Account created successfully".to_string(),
        documents_status: "processing".to_string(),
    }))
}

/// Parse multipart form data.
async fn parse_multipart(
    multipart: &mut multer::Multipart<'_>,
    config: &Config,
) -> ApiResult<AccountOpeningBrData> {
    let mut full_name = None;
    let mut mother_name = None;
    let mut cpf = None;
    let mut email = None;
    let mut phone = None;
    let mut cnh_pdf = None;
    let mut cnh_front = None;
    let mut cnh_back = None;
    let mut selfie = None;
    let mut proof_of_address = None;
    let mut total_size = 0;

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| ApiError::InvalidRequest(format!("Multipart error: {}", e)))?
    {
        let name = field
            .name()
            .ok_or_else(|| ApiError::InvalidRequest("Field missing name".into()))?
            .to_string();

        let filename = field.file_name().map(|s| s.to_string());
        let content_type = field.content_type().map(|m| m.to_string());

        match name.as_str() {
            "full_name" => {
                full_name = Some(
                    field
                        .text()
                        .await
                        .map_err(|e| ApiError::InvalidRequest(format!("Error reading field: {}", e)))?,
                );
            }
            "mother_name" => {
                mother_name = Some(
                    field
                        .text()
                        .await
                        .map_err(|e| ApiError::InvalidRequest(format!("Error reading field: {}", e)))?,
                );
            }
            "cpf" => {
                cpf = Some(
                    field
                        .text()
                        .await
                        .map_err(|e| ApiError::InvalidRequest(format!("Error reading field: {}", e)))?,
                );
            }
            "email" => {
                email = Some(
                    field
                        .text()
                        .await
                        .map_err(|e| ApiError::InvalidRequest(format!("Error reading field: {}", e)))?,
                );
            }
            "phone" => {
                phone = Some(
                    field
                        .text()
                        .await
                        .map_err(|e| ApiError::InvalidRequest(format!("Error reading field: {}", e)))?,
                );
            }
            "cnh_pdf" | "cnh_front" | "cnh_back" | "selfie" | "proof_of_address" => {
                let bytes = field
                    .bytes()
                    .await
                    .map_err(|e| ApiError::InvalidRequest(format!("Error reading file: {}", e)))?;

                // Check file size
                if bytes.len() > config.max_file_size_bytes {
                    return Err(ApiError::FileTooLarge(format!(
                        "{} exceeds max size of {} MB",
                        name,
                        config.max_file_size_bytes / 1024 / 1024
                    )));
                }

                total_size += bytes.len();

                let file_data = FileData {
                    filename: filename.unwrap_or_else(|| format!("{}.bin", name)),
                    content_type: content_type.unwrap_or_else(|| "application/octet-stream".into()),
                    data: bytes,
                };

                match name.as_str() {
                    "cnh_pdf" => cnh_pdf = Some(file_data),
                    "cnh_front" => cnh_front = Some(file_data),
                    "cnh_back" => cnh_back = Some(file_data),
                    "selfie" => selfie = Some(file_data),
                    "proof_of_address" => proof_of_address = Some(file_data),
                    _ => {}
                }
            }
            _ => {
                // Ignore unknown fields
            }
        }
    }

    // Check total size
    if total_size > config.max_total_upload_bytes {
        return Err(ApiError::FileTooLarge(format!(
            "Total upload size {} MB exceeds max of {} MB",
            total_size / 1024 / 1024,
            config.max_total_upload_bytes / 1024 / 1024
        )));
    }

    // Validate required fields
    let full_name = full_name.ok_or_else(|| ApiError::MissingFile("full_name".into()))?;
    let mother_name = mother_name.ok_or_else(|| ApiError::MissingFile("mother_name".into()))?;
    let cpf = cpf.ok_or_else(|| ApiError::MissingFile("cpf".into()))?;
    let email = email.ok_or_else(|| ApiError::MissingFile("email".into()))?;
    let phone = phone.ok_or_else(|| ApiError::MissingFile("phone".into()))?;
    let selfie = selfie.ok_or_else(|| ApiError::MissingFile("selfie".into()))?;
    let proof_of_address =
        proof_of_address.ok_or_else(|| ApiError::MissingFile("proof_of_address".into()))?;

    Ok(AccountOpeningBrData {
        full_name,
        mother_name,
        cpf,
        email,
        phone,
        cnh_pdf,
        cnh_front,
        cnh_back,
        selfie: Some(selfie),
        proof_of_address: Some(proof_of_address),
    })
}

/// Validate KYC data and normalize inputs.
fn validate_kyc_data(mut data: AccountOpeningBrData) -> ApiResult<AccountOpeningBrData> {
    // Validate and normalize CPF
    data.cpf = validate_cpf(&data.cpf)?;

    // Validate email format (basic check)
    if !data.email.contains('@') || !data.email.contains('.') {
        return Err(ApiError::InvalidEmail);
    }

    // Validate phone (basic E.164 format check)
    if !data.phone.starts_with('+') || data.phone.len() < 10 {
        return Err(ApiError::InvalidPhone);
    }

    // Check either PDF or (Front + Back)
    if data.cnh_pdf.is_none() && (data.cnh_front.is_none() || data.cnh_back.is_none()) {
        return Err(ApiError::InvalidRequest(
            "Must provide either CNH PDF or both front and back images".into(),
        ));
    }

    Ok(data)
}

/// Validate CPF and return normalized version (digits only).
fn validate_cpf(cpf: &str) -> ApiResult<String> {
    // Remove formatting
    let digits: String = cpf.chars().filter(|c| c.is_numeric()).collect();

    // Must be 11 digits
    if digits.len() != 11 {
        return Err(ApiError::InvalidCpf("Must be 11 digits".into()));
    }

    // Check for all same digit
    if digits.chars().all(|c| c == digits.chars().next().unwrap()) {
        return Err(ApiError::InvalidCpf("Invalid CPF".into()));
    }

    // Validate check digits
    if !validate_cpf_checksum(&digits) {
        return Err(ApiError::InvalidCpf("Invalid checksum".into()));
    }

    Ok(digits)
}

/// Validate CPF checksum algorithm.
fn validate_cpf_checksum(cpf: &str) -> bool {
    let digits: Vec<u32> = cpf.chars().filter_map(|c| c.to_digit(10)).collect();

    if digits.len() != 11 {
        return false;
    }

    // Calculate first check digit
    let mut sum = 0;
    for i in 0..9 {
        sum += digits[i] * (10 - i as u32);
    }
    let remainder = sum % 11;
    let check1 = if remainder < 2 { 0 } else { 11 - remainder };

    if check1 != digits[9] {
        return false;
    }

    // Calculate second check digit
    sum = 0;
    for i in 0..10 {
        sum += digits[i] * (11 - i as u32);
    }
    let remainder = sum % 11;
    let check2 = if remainder < 2 { 0 } else { 11 - remainder };

    check2 == digits[10]
}

/// Create account with wallet in a database transaction.
async fn create_account_with_wallet(
    db: &Database,
    data: &AccountOpeningBrData,
    encryption_key: &[u8],
    key_id: &str,
) -> ApiResult<(uuid::Uuid, uuid::Uuid, String)> {
    let mut tx = db.pool().begin().await?;

    // 1. Create identity
    let email_id = Database::insert_email(&mut tx, &data.email).await?;
    let phone_id = Database::insert_phone(&mut tx, &data.phone).await?;
    let person_id = Database::insert_person(&mut tx, &data.full_name, &data.mother_name).await?;

    // 2. Link contacts
    Database::insert_person_email(&mut tx, person_id, email_id, true).await?;
    Database::insert_person_phone(&mut tx, person_id, phone_id, true).await?;

    // 3. Store CPF
    Database::insert_person_documents_br(&mut tx, person_id, &data.cpf).await?;

    // 4. Create account holder
    let holder_id = Database::insert_account_holder(&mut tx, person_id, "BR").await?;

    // 5. Generate and encrypt wallet
    let wallet_data = wallet::generate_wallet().map_err(|_| ApiError::WalletGenerationError)?;

    let encrypted =
        encryption::encrypt_seed(&wallet_data.seed, encryption_key).map_err(|e| {
            tracing::error!("Encryption error: {:?}", e);
            ApiError::EncryptionError
        })?;

    // 6. Store wallet
    let wallet_id = Database::insert_account_blockchain(
        &mut tx,
        holder_id,
        "POLYGON",
        &encrypted.ciphertext,
        &encrypted.iv,
        &encrypted.auth_tag,
        key_id,
    )
    .await?;

    // 7. Store address
    Database::insert_blockchain_address(
        &mut tx,
        wallet_id,
        &wallet_data.polygon_address,
        "m/44'/60'/0'/0/0",
        true,
    )
    .await?;

    // 8. Create currency accounts (BRL1, SOL, USDC, USDT)
    for currency in &["BRL1", "SOL", "USDC", "USDT"] {
        Database::insert_account(&mut tx, holder_id, "BR", currency, "crypto").await?;
    }

    tx.commit().await?;

    Ok((person_id, holder_id, wallet_data.polygon_address))
}

/// Extract files for upload.
fn extract_files_for_upload(data: AccountOpeningBrData) -> Vec<(String, String, Bytes)> {
    let mut files = Vec::new();
    let timestamp = chrono::Utc::now().format("%Y%m%d_%H%M%S");

    if let Some(pdf) = data.cnh_pdf {
        files.push((
            format!("cnh_{}.{}", timestamp, get_extension(&pdf.filename)),
            pdf.content_type,
            pdf.data,
        ));
    } else {
        if let Some(front) = data.cnh_front {
            files.push((
                format!("cnh_front_{}.{}", timestamp, get_extension(&front.filename)),
                front.content_type,
                front.data,
            ));
        }
        if let Some(back) = data.cnh_back {
            files.push((
                format!("cnh_back_{}.{}", timestamp, get_extension(&back.filename)),
                back.content_type,
                back.data,
            ));
        }
    }

    if let Some(selfie) = data.selfie {
        files.push((
            format!("selfie_{}.{}", timestamp, get_extension(&selfie.filename)),
            selfie.content_type,
            selfie.data,
        ));
    }

    if let Some(proof) = data.proof_of_address {
        files.push((
            format!(
                "proof_of_address_{}.{}",
                timestamp,
                get_extension(&proof.filename)
            ),
            proof.content_type,
            proof.data,
        ));
    }

    files
}

/// Get file extension from filename.
fn get_extension(filename: &str) -> &str {
    filename.split('.').last().unwrap_or("bin")
}

/// Upload files to Google Drive asynchronously.
async fn upload_to_drive(
    drive: Arc<DriveClient>,
    files: Vec<(String, String, Bytes)>,
    cpf: String,
) -> anyhow::Result<()> {
    // Ensure CPF folder exists
    let folder_id = drive.ensure_cpf_folder(&cpf).await?;

    // Upload all files
    for (filename, mime_type, data) in files {
        drive
            .upload_file(data, &filename, &mime_type, &folder_id)
            .await?;
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_cpf_valid() {
        // Valid CPF with formatting
        assert!(validate_cpf("123.456.789-09").is_ok());

        // Valid CPF without formatting
        assert!(validate_cpf("12345678909").is_ok());
    }

    #[test]
    fn test_validate_cpf_invalid() {
        // All same digits
        assert!(validate_cpf("111.111.111-11").is_err());

        // Wrong length
        assert!(validate_cpf("123.456.789").is_err());

        // Invalid checksum
        assert!(validate_cpf("123.456.789-00").is_err());
    }

    #[test]
    fn test_validate_cpf_checksum() {
        // Known valid CPF
        assert!(validate_cpf_checksum("12345678909"));

        // Invalid CPF
        assert!(!validate_cpf_checksum("12345678900"));
    }
}
