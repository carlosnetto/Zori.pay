package com.zoripay.api.dao;

import org.jdbi.v3.core.Jdbi;

import java.util.UUID;

public class KycDao {

    private final Jdbi jdbi;

    public KycDao(Jdbi jdbi) {
        this.jdbi = jdbi;
    }

    public boolean cpfExists(String cpf) {
        return jdbi.withHandle(handle ->
                handle.createQuery("""
                        SELECT EXISTS(
                            SELECT 1 FROM registration_schema.person_documents_br
                            WHERE cpf = :cpf
                        )
                        """)
                        .bind("cpf", cpf)
                        .mapTo(Boolean.class)
                        .one()
        );
    }

    public record AccountCreationResult(UUID personId, UUID accountHolderId,
                                         String polygonAddress) {}

    /**
     * Create a complete account within a single database transaction.
     * Mirrors the Rust create_account_with_wallet function.
     */
    public AccountCreationResult createAccountWithWallet(
            String fullName, String motherName, String cpf, String email, String phone,
            byte[] encryptedSeed, byte[] iv, byte[] authTag, String keyId,
            String polygonAddress) {

        return jdbi.inTransaction(handle -> {
            // 1. Insert or get email
            UUID emailId = handle.createQuery("""
                    SELECT id FROM registration_schema.emails
                    WHERE LOWER(email_address) = LOWER(:email)
                    """)
                    .bind("email", email)
                    .mapTo(UUID.class)
                    .findFirst()
                    .orElseGet(() -> {
                        UUID newId = UUID.randomUUID();
                        handle.createUpdate("""
                                INSERT INTO registration_schema.emails (id, email_address)
                                VALUES (:id, :email)
                                """)
                                .bind("id", newId)
                                .bind("email", email)
                                .execute();
                        return newId;
                    });

            // 2. Insert or get phone
            UUID phoneId = handle.createQuery("""
                    SELECT id FROM registration_schema.phones
                    WHERE phone_number = :phone
                    """)
                    .bind("phone", phone)
                    .mapTo(UUID.class)
                    .findFirst()
                    .orElseGet(() -> {
                        UUID newId = UUID.randomUUID();
                        handle.createUpdate("""
                                INSERT INTO registration_schema.phones (id, phone_number)
                                VALUES (:id, :phone)
                                """)
                                .bind("id", newId)
                                .bind("phone", phone)
                                .execute();
                        return newId;
                    });

            // 3. Insert person
            UUID personId = UUID.randomUUID();
            handle.createUpdate("""
                    INSERT INTO registration_schema.people (id, full_name, mother_name)
                    VALUES (:id, :fullName, :motherName)
                    """)
                    .bind("id", personId)
                    .bind("fullName", fullName)
                    .bind("motherName", motherName)
                    .execute();

            // 4. Link email to person
            handle.createUpdate("""
                    INSERT INTO registration_schema.person_emails
                        (person_id, email_id, is_primary_for_login, email_type)
                    VALUES (:personId, :emailId, true, 'personal')
                    """)
                    .bind("personId", personId)
                    .bind("emailId", emailId)
                    .execute();

            // 5. Link phone to person
            handle.createUpdate("""
                    INSERT INTO registration_schema.person_phones
                        (person_id, phone_id, is_primary_for_login, phone_type)
                    VALUES (:personId, :phoneId, true, 'mobile')
                    """)
                    .bind("personId", personId)
                    .bind("phoneId", phoneId)
                    .execute();

            // 6. Insert CPF document
            handle.createUpdate("""
                    INSERT INTO registration_schema.person_documents_br (person_id, cpf)
                    VALUES (:personId, :cpf)
                    """)
                    .bind("personId", personId)
                    .bind("cpf", cpf)
                    .execute();

            // 7. Create account holder
            UUID holderId = UUID.randomUUID();
            handle.createUpdate("""
                    INSERT INTO accounts_schema.account_holders (id, main_person_id)
                    VALUES (:id, :personId)
                    """)
                    .bind("id", holderId)
                    .bind("personId", personId)
                    .execute();

            // 8. Store encrypted wallet
            UUID walletId = UUID.randomUUID();
            handle.createUpdate("""
                    INSERT INTO accounts_schema.account_blockchain
                        (id, account_holder_id, blockchain_code,
                         encrypted_master_seed, encryption_iv, encryption_auth_tag, encryption_key_id)
                    VALUES (:id, :holderId, 'POLYGON', :seed, :iv, :authTag, :keyId)
                    """)
                    .bind("id", walletId)
                    .bind("holderId", holderId)
                    .bind("seed", encryptedSeed)
                    .bind("iv", iv)
                    .bind("authTag", authTag)
                    .bind("keyId", keyId)
                    .execute();

            // 9. Store address
            UUID addressId = UUID.randomUUID();
            handle.createUpdate("""
                    INSERT INTO accounts_schema.account_blockchain_addresses
                        (id, account_blockchain_id, public_address, derivation_path,
                         address_index, is_primary, is_active)
                    VALUES (:id, :walletId, :address, 'm/44''/60''/0''/0/0', 0, true, true)
                    """)
                    .bind("id", addressId)
                    .bind("walletId", walletId)
                    .bind("address", polygonAddress)
                    .execute();

            // 10. Create currency accounts
            for (String currency : new String[]{"BRL1", "SOL", "USDC", "USDT"}) {
                UUID accountId = UUID.randomUUID();
                handle.createUpdate("""
                        INSERT INTO accounts_schema.accounts
                            (id, account_holder_id, country_code, currency_code, account_type)
                        VALUES (:id, :holderId, 'BR', :currency, 'crypto')
                        """)
                        .bind("id", accountId)
                        .bind("holderId", holderId)
                        .bind("currency", currency)
                        .execute();
            }

            return new AccountCreationResult(personId, holderId, polygonAddress);
        });
    }
}
