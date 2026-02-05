package com.zoripay.api.dao;

import com.zoripay.api.model.PasskeyCredential;
import org.jdbi.v3.core.Jdbi;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;

public class PasskeyDao {

    private final Jdbi jdbi;

    public PasskeyDao(Jdbi jdbi) {
        this.jdbi = jdbi;
    }

    public List<PasskeyCredential> getPasskeyCredentials(UUID personId) {
        return jdbi.withHandle(handle ->
                handle.createQuery("""
                        SELECT id, credential_id, public_key, counter, transports
                        FROM registration_schema.passkey_credentials
                        WHERE person_id = :personId
                          AND is_active = true
                        """)
                        .bind("personId", personId)
                        .map((rs, ctx) -> {
                            String[] transports = null;
                            var pgArray = rs.getArray("transports");
                            if (pgArray != null) {
                                transports = (String[]) pgArray.getArray();
                            }
                            return new PasskeyCredential(
                                    rs.getObject("id", UUID.class),
                                    rs.getBytes("credential_id"),
                                    rs.getBytes("public_key"),
                                    rs.getInt("counter"),
                                    transports != null ? Arrays.asList(transports) : List.of()
                            );
                        })
                        .list()
        );
    }

    public void updatePasskeyCounter(byte[] credentialId, int counter) {
        jdbi.useHandle(handle ->
                handle.createUpdate("""
                        UPDATE registration_schema.passkey_credentials
                        SET counter = :counter, last_used_at = NOW()
                        WHERE credential_id = :credentialId
                        """)
                        .bind("counter", counter)
                        .bind("credentialId", credentialId)
                        .execute()
        );
    }
}
