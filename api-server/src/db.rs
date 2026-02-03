use anyhow::Result;
use sqlx::postgres::{PgPool, PgPoolOptions};
use sqlx::{Row, Transaction, Postgres};
use uuid::Uuid;

use crate::models::Person;

#[derive(Clone)]
pub struct Database {
    pool: PgPool,
}

impl Database {
    pub async fn connect(database_url: &str) -> Result<Self> {
        let pool = PgPoolOptions::new()
            .max_connections(10)
            .connect(database_url)
            .await?;

        Ok(Self { pool })
    }

    /// Get a reference to the database connection pool
    pub fn pool(&self) -> &PgPool {
        &self.pool
    }

    /// Find a person by their login email.
    /// Returns Some(Person) only if:
    /// 1. The email exists in the emails table
    /// 2. The email is linked to a person via person_emails
    /// 3. The link has is_primary_for_login = true
    ///
    /// Emails not marked for login will return None.
    pub async fn find_person_by_login_email(&self, email: &str) -> Result<Option<Person>> {
        let row = sqlx::query(
            r#"
            SELECT
                p.id,
                p.full_name,
                p.date_of_birth,
                e.email_address
            FROM registration_schema.people p
            INNER JOIN registration_schema.person_emails pe ON pe.person_id = p.id
            INNER JOIN registration_schema.emails e ON e.id = pe.email_id
            WHERE LOWER(e.email_address) = LOWER($1)
              AND pe.is_primary_for_login = true
            "#,
        )
        .bind(email)
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|r| Person {
            id: r.get("id"),
            full_name: r.get("full_name"),
            date_of_birth: r.get("date_of_birth"),
            email_address: r.get("email_address"),
        }))
    }

    /// Get passkey credentials for a person.
    /// Returns the credential IDs registered for WebAuthn authentication.
    pub async fn get_passkey_credentials(&self, person_id: Uuid) -> Result<Vec<PasskeyCredential>> {
        let rows = sqlx::query(
            r#"
            SELECT
                id,
                credential_id,
                public_key,
                counter,
                transports
            FROM registration_schema.passkey_credentials
            WHERE person_id = $1
              AND is_active = true
            "#,
        )
        .bind(person_id)
        .fetch_all(&self.pool)
        .await?;

        let credentials = rows
            .into_iter()
            .map(|r| PasskeyCredential {
                id: r.get("id"),
                credential_id: r.get("credential_id"),
                public_key: r.get("public_key"),
                counter: r.get("counter"),
                transports: r.get("transports"),
            })
            .collect();

        Ok(credentials)
    }

    /// Update the signature counter for a passkey credential after successful authentication.
    pub async fn update_passkey_counter(&self, credential_id: &[u8], counter: u32) -> Result<()> {
        sqlx::query(
            r#"
            UPDATE registration_schema.passkey_credentials
            SET counter = $2, last_used_at = NOW()
            WHERE credential_id = $1
            "#,
        )
        .bind(credential_id)
        .bind(counter as i32)
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    // ==================== KYC Database Operations ====================

    /// Check if a CPF already exists in the database.
    pub async fn cpf_exists(&self, cpf: &str) -> Result<bool> {
        let exists: bool = sqlx::query_scalar(
            r#"
            SELECT EXISTS(
                SELECT 1 FROM registration_schema.person_documents_br
                WHERE cpf = $1
            )
            "#,
        )
        .bind(cpf)
        .fetch_one(&self.pool)
        .await?;

        Ok(exists)
    }

    /// Insert a person and return the person_id.
    pub async fn insert_person(
        tx: &mut Transaction<'_, Postgres>,
        full_name: &str,
        mother_name: &str,
    ) -> Result<Uuid> {
        let person_id = Uuid::new_v4();

        sqlx::query(
            r#"
            INSERT INTO registration_schema.people (id, full_name, mother_name)
            VALUES ($1, $2, $3)
            "#,
        )
        .bind(person_id)
        .bind(full_name)
        .bind(mother_name)
        .execute(&mut **tx)
        .await?;

        Ok(person_id)
    }

    /// Insert or get email_id for an email address.
    pub async fn insert_email(
        tx: &mut Transaction<'_, Postgres>,
        email: &str,
    ) -> Result<Uuid> {
        // Check if email already exists
        let existing: Option<Uuid> = sqlx::query_scalar(
            r#"
            SELECT id FROM registration_schema.emails
            WHERE LOWER(email_address) = LOWER($1)
            "#,
        )
        .bind(email)
        .fetch_optional(&mut **tx)
        .await?;

        if let Some(id) = existing {
            return Ok(id);
        }

        // Insert new email
        let email_id = Uuid::new_v4();
        sqlx::query(
            r#"
            INSERT INTO registration_schema.emails (id, email_address)
            VALUES ($1, $2)
            "#,
        )
        .bind(email_id)
        .bind(email)
        .execute(&mut **tx)
        .await?;

        Ok(email_id)
    }

    /// Link email to person.
    pub async fn insert_person_email(
        tx: &mut Transaction<'_, Postgres>,
        person_id: Uuid,
        email_id: Uuid,
        is_primary_for_login: bool,
    ) -> Result<()> {
        sqlx::query(
            r#"
            INSERT INTO registration_schema.person_emails (person_id, email_id, is_primary_for_login)
            VALUES ($1, $2, $3)
            "#,
        )
        .bind(person_id)
        .bind(email_id)
        .bind(is_primary_for_login)
        .execute(&mut **tx)
        .await?;

        Ok(())
    }

    /// Insert or get phone_id for a phone number.
    pub async fn insert_phone(
        tx: &mut Transaction<'_, Postgres>,
        phone: &str,
    ) -> Result<Uuid> {
        // Check if phone already exists
        let existing: Option<Uuid> = sqlx::query_scalar(
            r#"
            SELECT id FROM registration_schema.phones
            WHERE phone_number = $1
            "#,
        )
        .bind(phone)
        .fetch_optional(&mut **tx)
        .await?;

        if let Some(id) = existing {
            return Ok(id);
        }

        // Insert new phone
        let phone_id = Uuid::new_v4();
        sqlx::query(
            r#"
            INSERT INTO registration_schema.phones (id, phone_number)
            VALUES ($1, $2)
            "#,
        )
        .bind(phone_id)
        .bind(phone)
        .execute(&mut **tx)
        .await?;

        Ok(phone_id)
    }

    /// Link phone to person.
    pub async fn insert_person_phone(
        tx: &mut Transaction<'_, Postgres>,
        person_id: Uuid,
        phone_id: Uuid,
        is_primary_for_login: bool,
    ) -> Result<()> {
        sqlx::query(
            r#"
            INSERT INTO registration_schema.person_phones (person_id, phone_id, is_primary_for_login)
            VALUES ($1, $2, $3)
            "#,
        )
        .bind(person_id)
        .bind(phone_id)
        .bind(is_primary_for_login)
        .execute(&mut **tx)
        .await?;

        Ok(())
    }

    /// Insert Brazilian CPF document.
    pub async fn insert_person_documents_br(
        tx: &mut Transaction<'_, Postgres>,
        person_id: Uuid,
        cpf: &str,
    ) -> Result<Uuid> {
        sqlx::query(
            r#"
            INSERT INTO registration_schema.person_documents_br (person_id, cpf)
            VALUES ($1, $2)
            "#,
        )
        .bind(person_id)
        .bind(cpf)
        .execute(&mut **tx)
        .await?;

        Ok(person_id)
    }

    /// Create account holder.
    pub async fn insert_account_holder(
        tx: &mut Transaction<'_, Postgres>,
        person_id: Uuid,
        _country_code: &str,
    ) -> Result<Uuid> {
        let holder_id = Uuid::new_v4();

        sqlx::query(
            r#"
            INSERT INTO accounts_schema.account_holders (id, main_person_id)
            VALUES ($1, $2)
            "#,
        )
        .bind(holder_id)
        .bind(person_id)
        .execute(&mut **tx)
        .await?;

        Ok(holder_id)
    }

    /// Create blockchain wallet with encrypted seed.
    pub async fn insert_account_blockchain(
        tx: &mut Transaction<'_, Postgres>,
        holder_id: Uuid,
        blockchain_code: &str,
        encrypted_seed: &[u8],
        iv: &[u8],
        auth_tag: &[u8],
        key_id: &str,
    ) -> Result<Uuid> {
        let wallet_id = Uuid::new_v4();

        sqlx::query(
            r#"
            INSERT INTO accounts_schema.account_blockchain (
                id, account_holder_id, blockchain_code,
                encrypted_master_seed, encryption_iv, encryption_auth_tag, encryption_key_id
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            "#,
        )
        .bind(wallet_id)
        .bind(holder_id)
        .bind(blockchain_code)
        .bind(encrypted_seed)
        .bind(iv)
        .bind(auth_tag)
        .bind(key_id)
        .execute(&mut **tx)
        .await?;

        Ok(wallet_id)
    }

    /// Insert derived blockchain address.
    pub async fn insert_blockchain_address(
        tx: &mut Transaction<'_, Postgres>,
        wallet_id: Uuid,
        address: &str,
        derivation_path: &str,
        is_primary: bool,
    ) -> Result<Uuid> {
        let address_id = Uuid::new_v4();

        sqlx::query(
            r#"
            INSERT INTO accounts_schema.account_blockchain_addresses (
                id, account_blockchain_id, public_address, derivation_path, address_index, is_primary, is_active
            )
            VALUES ($1, $2, $3, $4, 0, $5, true)
            "#,
        )
        .bind(address_id)
        .bind(wallet_id)
        .bind(address)
        .bind(derivation_path)
        .bind(is_primary)
        .execute(&mut **tx)
        .await?;

        Ok(address_id)
    }

    /// Insert a currency account for an account holder.
    pub async fn insert_account(
        tx: &mut Transaction<'_, Postgres>,
        holder_id: Uuid,
        country_code: &str,
        currency_code: &str,
        account_type: &str,
    ) -> Result<Uuid> {
        let account_id = Uuid::new_v4();

        sqlx::query(
            r#"
            INSERT INTO accounts_schema.accounts (
                id, account_holder_id, country_code, currency_code, account_type
            )
            VALUES ($1, $2, $3, $4, $5)
            "#,
        )
        .bind(account_id)
        .bind(holder_id)
        .bind(country_code)
        .bind(currency_code)
        .bind(account_type)
        .execute(&mut **tx)
        .await?;

        Ok(account_id)
    }
}

#[derive(Debug)]
pub struct PasskeyCredential {
    pub id: Uuid,
    pub credential_id: Vec<u8>,
    pub public_key: Vec<u8>,
    pub counter: i32,
    pub transports: Option<Vec<String>>,
}
