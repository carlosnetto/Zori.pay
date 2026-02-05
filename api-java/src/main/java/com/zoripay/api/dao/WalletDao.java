package com.zoripay.api.dao;

import org.jdbi.v3.core.Jdbi;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

public class WalletDao {

    private final Jdbi jdbi;

    public WalletDao(Jdbi jdbi) {
        this.jdbi = jdbi;
    }

    public record WalletAddress(String publicAddress, String blockchainCode) {}

    public Optional<WalletAddress> getPrimaryPolygonAddress(UUID personId) {
        return jdbi.withHandle(handle ->
                handle.createQuery("""
                        SELECT aba.public_address, ab.blockchain_code
                        FROM accounts_schema.account_blockchain ab
                        JOIN accounts_schema.account_blockchain_addresses aba
                            ON ab.id = aba.account_blockchain_id
                        JOIN accounts_schema.account_holders ah
                            ON ab.account_holder_id = ah.id
                        WHERE ah.main_person_id = :personId
                          AND ab.blockchain_code = 'POLYGON'
                          AND aba.is_active = true
                          AND aba.is_primary = true
                        LIMIT 1
                        """)
                        .bind("personId", personId)
                        .map((rs, ctx) -> new WalletAddress(
                                rs.getString("public_address"),
                                rs.getString("blockchain_code")
                        ))
                        .findFirst()
        );
    }

    public record WalletData(byte[] encryptedMasterSeed, byte[] encryptionIv,
                              byte[] encryptionAuthTag, String publicAddress) {}

    public Optional<WalletData> getWalletData(UUID personId) {
        return jdbi.withHandle(handle ->
                handle.createQuery("""
                        SELECT ab.encrypted_master_seed, ab.encryption_iv,
                               ab.encryption_auth_tag, aba.public_address
                        FROM accounts_schema.account_blockchain ab
                        JOIN accounts_schema.account_blockchain_addresses aba
                            ON ab.id = aba.account_blockchain_id
                        JOIN accounts_schema.account_holders ah
                            ON ab.account_holder_id = ah.id
                        WHERE ah.main_person_id = :personId
                          AND ab.blockchain_code = 'POLYGON'
                          AND aba.is_active = true
                          AND aba.is_primary = true
                        LIMIT 1
                        """)
                        .bind("personId", personId)
                        .map((rs, ctx) -> new WalletData(
                                rs.getBytes("encrypted_master_seed"),
                                rs.getBytes("encryption_iv"),
                                rs.getBytes("encryption_auth_tag"),
                                rs.getString("public_address")
                        ))
                        .findFirst()
        );
    }

    public record CurrencyContract(String code, int decimals, String contractAddress,
                                    int blockchainDecimals) {}

    public java.util.List<CurrencyContract> getPolygonCurrencies() {
        return jdbi.withHandle(handle ->
                handle.createQuery("""
                        SELECT c.code, c.decimals, cbc.contract_address,
                               COALESCE(cbc.network_decimals, c.decimals) as blockchain_decimals
                        FROM accounts_schema.currencies c
                        JOIN accounts_schema.currency_blockchain_configs cbc
                            ON c.id = cbc.currency_id
                        WHERE cbc.blockchain_code = 'POLYGON'
                          AND c.code IN ('USDC', 'USDT', 'POL', 'BRL1')
                        ORDER BY c.code
                        """)
                        .map((rs, ctx) -> new CurrencyContract(
                                rs.getString("code"),
                                rs.getInt("decimals"),
                                rs.getString("contract_address"),
                                rs.getInt("blockchain_decimals")
                        ))
                        .list()
        );
    }

    public record ContractInfo(String contractAddress, int decimals) {}

    public Optional<ContractInfo> getContractInfo(String currencyCode) {
        return jdbi.withHandle(handle ->
                handle.createQuery("""
                        SELECT cbc.contract_address,
                               COALESCE(cbc.network_decimals, c.decimals) as decimals
                        FROM accounts_schema.currencies c
                        JOIN accounts_schema.currency_blockchain_configs cbc
                            ON c.id = cbc.currency_id
                        WHERE c.code = :code AND cbc.blockchain_code = 'POLYGON'
                        """)
                        .bind("code", currencyCode)
                        .map((rs, ctx) -> new ContractInfo(
                                rs.getString("contract_address"),
                                rs.getInt("decimals")
                        ))
                        .findFirst()
        );
    }

    /**
     * Get currency-contract mapping for transaction resolution.
     * Returns map of lowercase contract_address -> (code, decimals).
     */
    public Map<String, CurrencyContract> getPolygonCurrencyMap() {
        var currencies = getPolygonCurrencies();
        var map = new java.util.HashMap<String, CurrencyContract>();
        for (var c : currencies) {
            if (c.contractAddress() != null) {
                map.put(c.contractAddress().toLowerCase(), c);
            }
        }
        return map;
    }
}
