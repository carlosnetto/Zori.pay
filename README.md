# Zori.pay

Multi-country banking platform with blockchain integration.

## Overview

Zori.pay is a financial platform that bridges traditional banking with blockchain technology, supporting multiple countries and regulatory frameworks.

## Architecture

### Database Schemas

| Schema | Purpose |
|--------|---------|
| `registration_schema` | Identity management (people, contacts, addresses, documents) |
| `accounts_schema` | Financial operations (accounts, currencies, blockchain wallets) |
| `audit_schema` | Compliance and audit trails |

### Key Features

- **Multi-country Support**: Country-specific document types and banking details (Brazil ISPB/CPF, US routing numbers/SSN)
- **HD Wallet Integration**: BIP-44 compliant hierarchical deterministic wallets with AES-256-GCM encrypted master seeds
- **Multi-blockchain**: Support for 32+ blockchain networks including Bitcoin, Ethereum, Polygon, Solana, Rayls, Arc, and more
- **Stablecoin Support**: BRL1, USDC, USDT, and native cryptocurrencies
- **Audit Trail**: Complete history tracking with timeline views

## Database Migrations

Uses [Liquibase](https://www.liquibase.org/) for database version control.

### Migration Files

| File | Description | Changesets |
|------|-------------|------------|
| `v001_schemas.xml` | Database infrastructure (schemas, extensions) | 1 |
| `v002_registration.xml` | Identity tables (people, contacts, addresses, documents) | 14 |
| `v003_accounts.xml` | Financial structure (holders, accounts, currencies) | 11 |
| `v004_audit.xml` | Audit trail (history tables, triggers, views) | 3 |
| `v005_blockchain_wallets.xml` | HD wallet support (seeds, addresses, derivation) | 4 |
| `v006_seed_reference_data.xml` | Reference data (countries, states, blockchains, currencies) | 9 |
| `v007_seed_test_data.xml` | Test data (development only) | 7 |

**Total: 49 changesets**

### Running Migrations

```bash
# Start PostgreSQL
docker-compose up -d

# Migrations run automatically via Liquibase container
# Check logs
docker-compose logs liquibase
```

### Verifying Migrations

```sql
-- Check changeset count by file
SELECT
    filename,
    COUNT(*) as changesets
FROM databasechangelog
GROUP BY filename
ORDER BY MIN(orderexecuted);
```

## Supported Blockchains

| Network | Type | Native Currency |
|---------|------|-----------------|
| Bitcoin | Layer 1 | BTC |
| Ethereum | Layer 1 | ETH |
| Polygon | Layer 2 | MATIC |
| Solana | Layer 1 | SOL |
| Rayls (Parfin) | Private | - |
| Arc (Circle) | Private | - |
| Base | Layer 2 | ETH |
| Arbitrum | Layer 2 | ETH |
| Optimism | Layer 2 | ETH |
| Avalanche | Layer 1 | AVAX |
| And 22 more... | | |

## Supported Currencies

### Stablecoins
- **BRL1**: Brazilian Real stablecoin (Polygon, Ethereum, Solana)
- **USDC**: USD Coin (multiple chains)
- **USDT**: Tether (multiple chains)

### Native Cryptocurrencies
- BTC, ETH, MATIC, SOL, AVAX, and more

### Fiat
- BRL (Brazilian Real)
- USD (US Dollar)

## HD Wallet Architecture

Zori.pay uses Hierarchical Deterministic (HD) wallets following BIP-44 standard:

```
Master Seed (encrypted with AES-256-GCM)
    └── Derivation Path: m/44'/coin_type'/account'/change/address_index
            └── Multiple addresses per wallet
                    └── is_active: Privacy rotation support
                    └── is_primary: Default receiving address
```

### Security Features

- Master seeds encrypted at rest with AES-256-GCM
- Separate encryption IV and auth tag per wallet
- Key rotation support via encryption_key_id
- Address deactivation with automatic timestamp tracking

## Project Structure

```
Zori.pay/
├── docker-compose.yml      # PostgreSQL + Liquibase setup
├── migrations/
│   ├── changelog-master.xml    # Master changelog
│   ├── v001_schemas.xml        # Infrastructure
│   ├── v002_registration.xml   # Identity
│   ├── v003_accounts.xml       # Financial
│   ├── v004_audit.xml          # Audit
│   ├── v005_blockchain_wallets.xml  # Blockchain
│   ├── v006_seed_reference_data.xml # Reference data
│   └── v007_seed_test_data.xml      # Test data
└── README.md
```

## Development

### Prerequisites

- Docker and Docker Compose
- PostgreSQL 15+ (via Docker)

### Quick Start

```bash
# Clone repository
git clone https://github.com/your-org/Zori.pay.git
cd Zori.pay

# Start services
docker-compose up -d

# Verify
docker-compose ps
```

### Reset Database

```bash
# Remove all data and restart
docker-compose down -v
docker-compose up -d
```

## License

Proprietary - All rights reserved.

## Author

Carlos Augusto Leite Netto
