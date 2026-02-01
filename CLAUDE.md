# Claude Context - Zori.pay

> Read this file first when resuming work on this project.

## Project Overview

**Zori.pay** is a multi-country banking platform with blockchain integration.

- **Owner**: Carlos Augusto Leite Netto
- **Database**: PostgreSQL with Liquibase migrations
- **Status**: Database schema complete, ready for GitHub publication

## Architecture

### Database Schemas

| Schema | Purpose |
|--------|---------|
| `registration_schema` | Identity (people, contacts, addresses, documents) |
| `accounts_schema` | Financial (accounts, currencies, blockchain wallets) |
| `audit_schema` | Compliance and audit trails |

### Key Design Decisions

1. **HD Wallets**: BIP-44 compliant with AES-256-GCM encrypted master seeds
2. **Normalized Contacts**: Phones/emails stored once, linked N:M to people
3. **Login Exclusivity**: Partial unique indexes ensure one person per login credential
4. **Country-Specific**: Separate tables for BR/US documents and bank details
5. **Privacy Rotation**: Blockchain addresses can be deactivated (is_active flag)

## File Structure

```
Zori.pay/
├── docker-compose.yml          # PostgreSQL + Liquibase
├── README.md                   # Project overview
├── CLAUDE.md                   # This file (context for Claude)
├── docs/
│   └── DATABASE_SCHEMA.md      # Comprehensive schema documentation
└── migrations/
    ├── changelog-master.xml    # Master changelog
    ├── v001_schemas.xml        # Infrastructure (1 changeset)
    ├── v002_registration.xml   # Identity (14 changesets)
    ├── v003_accounts.xml       # Financial (11 changesets)
    ├── v004_audit.xml          # Audit (3 changesets)
    ├── v005_blockchain_wallets.xml  # HD wallets (4 changesets)
    ├── v006_seed_reference_data.xml # Reference data (9 changesets)
    ├── v007_seed_test_data.xml      # Test data (7 changesets)
    └── old/                    # Archived old migration files
```

**Total: 49 changesets across 7 migration files**

## Test Data

Carlos Netto is seeded as test data:
- Person ID: `550e8400-e29b-41d4-a716-446655440000`
- Account Holder ID: `f47ac10b-58cc-4372-a567-0e02b2c3d479`
- Polygon wallet with address: `0x732D57fE3478984E59fF48d224653097ec0C730f`
- Accounts: BRL1 and SOL on Polygon

## Commands

```bash
# Start database
docker-compose up -d

# Reset database (destroys all data)
docker-compose down -v && docker-compose up -d

# Check migration status
docker-compose logs liquibase
```

## Supported Blockchains (32+)

L1: Bitcoin, Ethereum, Solana, Polygon, Avalanche, Algorand, Stellar, Tron, NEAR, Hedera, Celo, Sui, Aptos, BNB Chain, Fantom, Polkadot, Cosmos, Cardano, XRP, TON

L2: Arbitrum, Optimism, Base, zkSync, Linea, Moonbeam, Mantle, Scroll, Blast

Private: Rayls (Parfin), Arc (Circle), Noble (Cosmos)

## Currencies

- **Stablecoins**: USDC, USDT, DAI, EURC, PYUSD, BRL1, BRLA, BRLV, BRLD
- **Native Crypto**: BTC, ETH, SOL, POL, BNB, AVAX
- **Fiat**: 40+ currencies with proper decimal precision (0-3 decimals per ISO 4217)

## Recent Work (Last Session)

1. Created complete database schema with Liquibase migrations
2. Reorganized 18 migration files into 7 clean files
3. Added comprehensive XML comments to all migration files
4. Created README.md and docs/DATABASE_SCHEMA.md
5. All migrations tested successfully (49 changesets)

## Next Steps (Suggested)

- [ ] Delete `migrations/old/` directory before GitHub push
- [ ] Initialize git and push to GitHub
- [ ] Create application layer (API)
- [ ] Implement wallet encryption/decryption service
- [ ] Add more currencies and blockchain contract addresses

---

*Last updated: 2026-02-01*
