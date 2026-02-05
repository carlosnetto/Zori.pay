package com.zoripay.api.dao;

import com.zoripay.api.model.Person;
import org.jdbi.v3.core.Jdbi;

import java.util.Optional;
import java.util.UUID;

public class PersonDao {

    private final Jdbi jdbi;

    public PersonDao(Jdbi jdbi) {
        this.jdbi = jdbi;
    }

    public Optional<Person> findPersonByLoginEmail(String email) {
        return jdbi.withHandle(handle ->
                handle.createQuery("""
                        SELECT p.id, p.full_name, p.date_of_birth, e.email_address
                        FROM registration_schema.people p
                        INNER JOIN registration_schema.person_emails pe ON pe.person_id = p.id
                        INNER JOIN registration_schema.emails e ON e.id = pe.email_id
                        WHERE LOWER(e.email_address) = LOWER(:email)
                          AND pe.is_primary_for_login = true
                        """)
                        .bind("email", email)
                        .map((rs, ctx) -> new Person(
                                rs.getObject("id", UUID.class),
                                rs.getString("full_name"),
                                rs.getDate("date_of_birth") != null
                                        ? rs.getDate("date_of_birth").toLocalDate() : null,
                                rs.getString("email_address")
                        ))
                        .findFirst()
        );
    }
}
