package com.zoripay.api.model.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record ProfileResponse(
        PersonalInfo personal,
        ContactInfo contact,
        BlockchainInfo blockchain,
        AccountsInfo accounts,
        DocumentsInfo documents
) {
    public record PersonalInfo(
            @JsonProperty("full_name") String fullName,
            @JsonProperty("date_of_birth") String dateOfBirth,
            @JsonProperty("birth_city") String birthCity,
            @JsonProperty("birth_country") String birthCountry
    ) {}

    public record ContactInfo(
            List<PhoneInfo> phones,
            List<EmailInfo> emails
    ) {}

    public record PhoneInfo(
            @JsonProperty("phone_number") String phoneNumber,
            @JsonProperty("phone_type") String phoneType,
            @JsonProperty("is_primary_for_login") boolean isPrimaryForLogin
    ) {}

    public record EmailInfo(
            @JsonProperty("email_address") String emailAddress,
            @JsonProperty("email_type") String emailType,
            @JsonProperty("is_primary_for_login") boolean isPrimaryForLogin
    ) {}

    public record BlockchainInfo(
            @JsonProperty("polygon_address") String polygonAddress
    ) {}

    public record AccountsInfo(
            BrazilBankAccount brazil,
            UsaBankAccount usa
    ) {}

    public record BrazilBankAccount(
            @JsonProperty("bank_code") String bankCode,
            @JsonProperty("branch_number") String branchNumber,
            @JsonProperty("account_number") String accountNumber
    ) {}

    public record UsaBankAccount(
            @JsonProperty("routing_number") String routingNumber,
            @JsonProperty("account_number") String accountNumber
    ) {}

    public record DocumentsInfo(
            BrazilDocuments brazil,
            UsaDocuments usa
    ) {}

    public record BrazilDocuments(
            String cpf,
            @JsonProperty("rg_number") String rgNumber,
            @JsonProperty("rg_issuer") String rgIssuer
    ) {}

    public record UsaDocuments(
            @JsonProperty("ssn_last4") String ssnLast4,
            @JsonProperty("drivers_license_number") String driversLicenseNumber,
            @JsonProperty("drivers_license_state") String driversLicenseState
    ) {}
}
