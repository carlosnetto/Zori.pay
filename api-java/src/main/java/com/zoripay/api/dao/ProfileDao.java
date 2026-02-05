package com.zoripay.api.dao;

import com.zoripay.api.model.response.ProfileResponse;
import com.zoripay.api.model.response.ProfileResponse.*;
import org.jdbi.v3.core.Jdbi;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public class ProfileDao {

    private final Jdbi jdbi;

    public ProfileDao(Jdbi jdbi) {
        this.jdbi = jdbi;
    }

    public ProfileResponse getProfile(UUID personId) {
        return jdbi.withHandle(handle -> {
            // 1. Personal info
            var personal = handle.createQuery("""
                    SELECT full_name, date_of_birth, birth_city, birth_country
                    FROM registration_schema.people WHERE id = :id
                    """)
                    .bind("id", personId)
                    .map((rs, ctx) -> new PersonalInfo(
                            rs.getString("full_name"),
                            rs.getDate("date_of_birth") != null
                                    ? rs.getDate("date_of_birth").toLocalDate().toString() : null,
                            rs.getString("birth_city"),
                            rs.getString("birth_country")
                    ))
                    .findFirst()
                    .orElse(null);

            // 2. Phones
            List<PhoneInfo> phones = handle.createQuery("""
                    SELECT ph.phone_number, pp.phone_type, pp.is_primary_for_login
                    FROM registration_schema.person_phones pp
                    JOIN registration_schema.phones ph ON ph.id = pp.phone_id
                    WHERE pp.person_id = :id
                    ORDER BY pp.is_primary_for_login DESC
                    """)
                    .bind("id", personId)
                    .map((rs, ctx) -> new PhoneInfo(
                            rs.getString("phone_number"),
                            rs.getString("phone_type"),
                            rs.getBoolean("is_primary_for_login")
                    ))
                    .list();

            // 3. Emails
            List<EmailInfo> emails = handle.createQuery("""
                    SELECT e.email_address, pe.email_type, pe.is_primary_for_login
                    FROM registration_schema.person_emails pe
                    JOIN registration_schema.emails e ON e.id = pe.email_id
                    WHERE pe.person_id = :id
                    ORDER BY pe.is_primary_for_login DESC
                    """)
                    .bind("id", personId)
                    .map((rs, ctx) -> new EmailInfo(
                            rs.getString("email_address"),
                            rs.getString("email_type"),
                            rs.getBoolean("is_primary_for_login")
                    ))
                    .list();

            var contact = (phones.isEmpty() && emails.isEmpty()) ? null
                    : new ContactInfo(phones, emails);

            // 4. Polygon address
            var polygonAddress = handle.createQuery("""
                    SELECT aba.public_address
                    FROM accounts_schema.account_blockchain ab
                    JOIN accounts_schema.account_blockchain_addresses aba
                        ON ab.id = aba.account_blockchain_id
                    JOIN accounts_schema.account_holders ah
                        ON ab.account_holder_id = ah.id
                    WHERE ah.main_person_id = :id
                      AND ab.blockchain_code = 'POLYGON'
                      AND aba.is_active = true AND aba.is_primary = true
                    LIMIT 1
                    """)
                    .bind("id", personId)
                    .mapTo(String.class)
                    .findFirst()
                    .orElse(null);

            var blockchain = new BlockchainInfo(polygonAddress);

            // 5. Brazilian documents
            var brazilDocs = handle.createQuery("""
                    SELECT cpf, rg_number, rg_issuer
                    FROM registration_schema.person_documents_br
                    WHERE person_id = :id LIMIT 1
                    """)
                    .bind("id", personId)
                    .map((rs, ctx) -> new BrazilDocuments(
                            rs.getString("cpf"),
                            rs.getString("rg_number"),
                            rs.getString("rg_issuer")
                    ))
                    .findFirst()
                    .orElse(null);

            // 6. USA documents
            var usaDocs = handle.createQuery("""
                    SELECT ssn_last4, drivers_license_number, drivers_license_state
                    FROM registration_schema.person_documents_us
                    WHERE person_id = :id LIMIT 1
                    """)
                    .bind("id", personId)
                    .map((rs, ctx) -> new UsaDocuments(
                            rs.getString("ssn_last4"),
                            rs.getString("drivers_license_number"),
                            rs.getString("drivers_license_state")
                    ))
                    .findFirst()
                    .orElse(null);

            var documents = (brazilDocs == null && usaDocs == null) ? null
                    : new DocumentsInfo(brazilDocs, usaDocs);

            // 7. Account holder
            Optional<UUID> accountHolderId = handle.createQuery("""
                    SELECT id FROM accounts_schema.account_holders
                    WHERE main_person_id = :id LIMIT 1
                    """)
                    .bind("id", personId)
                    .mapTo(UUID.class)
                    .findFirst();

            AccountsInfo accounts = null;
            if (accountHolderId.isPresent()) {
                UUID ahId = accountHolderId.get();

                var brazilBank = handle.createQuery("""
                        SELECT adb.bank_code, adb.branch_number, adb.account_number
                        FROM accounts_schema.accounts a
                        JOIN accounts_schema.account_details_br adb ON adb.account_id = a.id
                        WHERE a.account_holder_id = :id LIMIT 1
                        """)
                        .bind("id", ahId)
                        .map((rs, ctx) -> new BrazilBankAccount(
                                rs.getString("bank_code"),
                                rs.getString("branch_number"),
                                rs.getString("account_number")
                        ))
                        .findFirst()
                        .orElse(null);

                var usaBank = handle.createQuery("""
                        SELECT adu.routing_number, adu.account_number
                        FROM accounts_schema.accounts a
                        JOIN accounts_schema.account_details_us adu ON adu.account_id = a.id
                        WHERE a.account_holder_id = :id LIMIT 1
                        """)
                        .bind("id", ahId)
                        .map((rs, ctx) -> new UsaBankAccount(
                                rs.getString("routing_number"),
                                rs.getString("account_number")
                        ))
                        .findFirst()
                        .orElse(null);

                if (brazilBank != null || usaBank != null) {
                    accounts = new AccountsInfo(brazilBank, usaBank);
                }
            }

            return new ProfileResponse(personal, contact, blockchain, accounts, documents);
        });
    }
}
