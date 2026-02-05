package com.zoripay.api.dao;

import com.zoripay.api.model.response.ReferenceDataResponse;
import com.zoripay.api.model.response.ReferenceDataResponse.*;
import org.jdbi.v3.core.Jdbi;

import java.util.List;
import java.util.concurrent.StructuredTaskScope;

public class ReferenceDataDao {

    private final Jdbi jdbi;

    public ReferenceDataDao(Jdbi jdbi) {
        this.jdbi = jdbi;
    }

    /**
     * Fetch all reference data using Structured Concurrency (8 parallel queries).
     * Mirrors Rust's tokio::join! for the 8 concurrent queries.
     * Uses Java 25 StructuredTaskScope with Joiner.allSuccessfulOrThrow().
     */
    @SuppressWarnings("preview")
    public ReferenceDataResponse getAll() throws Exception {
        try (var scope = StructuredTaskScope.open(
                StructuredTaskScope.Joiner.<Object>allSuccessfulOrThrow())) {
            var countries = scope.fork(() -> queryCountries());
            var states = scope.fork(() -> queryStates());
            var phoneTypes = scope.fork(() -> queryPhoneTypes());
            var emailTypes = scope.fork(() -> queryEmailTypes());
            var currencies = scope.fork(() -> queryCurrencies());
            var blockchainNetworks = scope.fork(() -> queryBlockchainNetworks());
            var addressTypes = scope.fork(() -> queryAddressTypes());
            var assetTypes = scope.fork(() -> queryAssetTypes());

            scope.join();

            return new ReferenceDataResponse(
                    (List<Country>) countries.get(),
                    (List<StateEntry>) states.get(),
                    (List<PhoneType>) phoneTypes.get(),
                    (List<EmailType>) emailTypes.get(),
                    (List<Currency>) currencies.get(),
                    (List<BlockchainNetwork>) blockchainNetworks.get(),
                    (List<AddressType>) addressTypes.get(),
                    (List<AssetType>) assetTypes.get()
            );
        }
    }

    private List<Country> queryCountries() {
        return jdbi.withHandle(h -> h.createQuery(
                "SELECT iso_code, name FROM registration_schema.countries ORDER BY name")
                .map((rs, ctx) -> new Country(rs.getString("iso_code"), rs.getString("name")))
                .list());
    }

    private List<StateEntry> queryStates() {
        return jdbi.withHandle(h -> h.createQuery(
                "SELECT country_code, state_code, name FROM registration_schema.states ORDER BY country_code, name")
                .map((rs, ctx) -> new StateEntry(
                        rs.getString("country_code"), rs.getString("state_code"),
                        rs.getString("name")))
                .list());
    }

    private List<PhoneType> queryPhoneTypes() {
        return jdbi.withHandle(h -> h.createQuery(
                "SELECT code, description FROM registration_schema.phone_types ORDER BY code")
                .map((rs, ctx) -> new PhoneType(rs.getString("code"),
                        rs.getString("description")))
                .list());
    }

    private List<EmailType> queryEmailTypes() {
        return jdbi.withHandle(h -> h.createQuery(
                "SELECT code, description FROM registration_schema.email_types ORDER BY code")
                .map((rs, ctx) -> new EmailType(rs.getString("code"),
                        rs.getString("description")))
                .list());
    }

    private List<Currency> queryCurrencies() {
        return jdbi.withHandle(h -> h.createQuery("""
                SELECT code, COALESCE(name, code) as name,
                       COALESCE(asset_type_code, 'other') as asset_type_code, decimals
                FROM accounts_schema.currencies ORDER BY code
                """)
                .map((rs, ctx) -> new Currency(
                        rs.getString("code"), rs.getString("name"),
                        rs.getString("asset_type_code"), rs.getInt("decimals")))
                .list());
    }

    private List<BlockchainNetwork> queryBlockchainNetworks() {
        return jdbi.withHandle(h -> h.createQuery(
                "SELECT code, COALESCE(name, code) as name FROM accounts_schema.blockchain_networks ORDER BY name")
                .map((rs, ctx) -> new BlockchainNetwork(rs.getString("code"),
                        rs.getString("name")))
                .list());
    }

    private List<AddressType> queryAddressTypes() {
        return jdbi.withHandle(h -> h.createQuery(
                "SELECT code, COALESCE(description, code) as description FROM registration_schema.address_types ORDER BY code")
                .map((rs, ctx) -> new AddressType(rs.getString("code"),
                        rs.getString("description")))
                .list());
    }

    private List<AssetType> queryAssetTypes() {
        return jdbi.withHandle(h -> h.createQuery(
                "SELECT code, code as description FROM accounts_schema.asset_types ORDER BY code")
                .map((rs, ctx) -> new AssetType(rs.getString("code"),
                        rs.getString("description")))
                .list());
    }
}
