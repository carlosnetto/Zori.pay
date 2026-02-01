# Zori.pay Database Schema

Comprehensive documentation of the Zori.pay database architecture.

## Table of Contents

1. [Schema Overview](#schema-overview)
2. [Entity Relationships](#entity-relationships)
3. [Identity Domain](#identity-domain)
4. [Financial Domain](#financial-domain)
5. [Blockchain Domain](#blockchain-domain)
6. [Currency System](#currency-system)
7. [Audit Domain](#audit-domain)

---

## Schema Overview

The database is organized into three PostgreSQL schemas:

| Schema | Purpose |
|--------|---------|
| `registration_schema` | Identity management: people, contacts, addresses, documents |
| `accounts_schema` | Financial: accounts, currencies, blockchains, wallets |
| `audit_schema` | Compliance: history tracking, audit trails |

---

## Entity Relationships

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           REGISTRATION_SCHEMA                                │
│  ┌──────────┐    N:M     ┌──────────┐     N:M    ┌───────────┐             │
│  │  phones  │◄──────────►│  people  │◄──────────►│  emails   │             │
│  └──────────┘            └────┬─────┘            └───────────┘             │
│       │                       │                        │                    │
│       │                       │ N:M                    │                    │
│       │                       ▼                        │                    │
│       │               ┌───────────────┐                │                    │
│       │               │   addresses   │                │                    │
│       │               └───────┬───────┘                │                    │
│       │                       │                        │                    │
│       │          ┌────────────┼────────────┐           │                    │
│       │          ▼            ▼            ▼           │                    │
│       │   ┌──────────┐ ┌──────────┐ ┌──────────┐       │                    │
│       │   │ docs_br  │ │ docs_us  │ │ docs_etc │       │                    │
│       │   └──────────┘ └──────────┘ └──────────┘       │                    │
└───────┼────────────────────────────────────────────────┼────────────────────┘
        │                       │                        │
        │                       │ 1:1                    │
        │                       ▼                        │
┌───────┼───────────────────────────────────────────────┼─────────────────────┐
│       │              ACCOUNTS_SCHEMA                   │                    │
│       │       ┌───────────────────┐                    │                    │
│       │       │  account_holders  │◄──────────────┐    │                    │
│       │       └─────────┬─────────┘               │    │                    │
│       │                 │                         │    │                    │
│       │    ┌────────────┼────────────┐            │    │                    │
│       │    │            │            │            │    │                    │
│       │    ▼            ▼            ▼            │    │                    │
│       │ ┌──────┐  ┌──────────┐  ┌────────────┐    │    │                    │
│       │ │accts │  │privileges│  │ blockchain │    │    │                    │
│       │ └──┬───┘  └──────────┘  │  wallets   │    │    │                    │
│       │    │                    └─────┬──────┘    │    │                    │
│       │    │                          │           │    │                    │
│       │ ┌──┴───────┐          ┌───────┴────────┐  │    │                    │
│       │ │details_br│          │   addresses    │  │    │                    │
│       │ │details_us│          │(public + path) │  │    │                    │
│       │ └──────────┘          └────────────────┘  │    │                    │
│       │                                           │    │                    │
│       │ ┌───────────┐    ┌────────────────────┐   │    │                    │
│       │ │currencies │───►│currency_blockchain │   │    │                    │
│       │ └───────────┘    │     _configs       │   │    │                    │
│       │                  └────────────────────┘   │    │                    │
└───────┼───────────────────────────────────────────┼────┼────────────────────┘
        │                                           │    │
        ▼                                           ▼    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AUDIT_SCHEMA                                    │
│                      ┌─────────────────────┐                                │
│                      │   people_history    │                                │
│                      └─────────────────────┘                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Identity Domain

### Person (`registration_schema.people`)

The central identity entity. A person is a natural individual.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key (auto-generated) |
| `full_name` | VARCHAR(255) | Complete legal name |
| `date_of_birth` | DATE | Birth date |
| `mother_name` | VARCHAR(255) | Mother's name (required for Brazil) |
| `birth_city` | VARCHAR(100) | City of birth |
| `birth_country` | CHAR(2) | Country code (ISO 3166-1 alpha-2) |

### Contact Information

#### Phone Numbers

Phones are **normalized**: stored once, referenced by many people.

**`phones`** - Phone registry
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `phone_number` | VARCHAR(20) | ITU E.164 format (unique) |

**`person_phones`** - Links people to phones (N:M)
| Column | Type | Description |
|--------|------|-------------|
| `person_id` | UUID | FK to people |
| `phone_id` | UUID | FK to phones |
| `phone_type` | VARCHAR(20) | Type: mobile, work, voip, etc. |
| `is_primary_for_login` | BOOLEAN | Login credential flag |

**Login Rule**: A phone marked as `is_primary_for_login = true` can only belong to **ONE person**. This is enforced by a partial unique index:

```sql
CREATE UNIQUE INDEX idx_unique_login_phone
ON registration_schema.person_phones (phone_id)
WHERE is_primary_for_login = true;
```

#### Email Addresses

Same pattern as phones - normalized and referenced.

**`emails`** - Email registry
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `email_address` | VARCHAR(255) | Unique email |

**`person_emails`** - Links people to emails (N:M)
| Column | Type | Description |
|--------|------|-------------|
| `person_id` | UUID | FK to people |
| `email_id` | UUID | FK to emails |
| `email_type` | VARCHAR(20) | Type: personal, work, other |
| `is_primary_for_login` | BOOLEAN | Login credential flag |

**Login Rule**: Same as phones - only one person per login email.

### Addresses

Addresses follow a **N:M relationship** with people through a junction table.

**`addresses`** - Physical address records
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `line1` | VARCHAR(255) | Street address |
| `line2` | VARCHAR(255) | Complement (apt, suite, etc.) |
| `city` | VARCHAR(100) | City name |
| `state_code` | VARCHAR(10) | State/province code |
| `country_code` | CHAR(2) | Country code (ISO 3166-1) |
| `postal_code` | VARCHAR(20) | ZIP/CEP/postal code |

**Postal Code Validation**: A trigger validates format per country:
- Brazil: `99999-999`
- USA: `99999` or `99999-9999`

**`person_addresses`** - Links people to addresses (N:M)
| Column | Type | Description |
|--------|------|-------------|
| `person_id` | UUID | FK to people |
| `address_id` | UUID | FK to addresses |
| `address_type` | VARCHAR(20) | home, work, mailing, other |
| `is_fiscal_address` | BOOLEAN | Tax/legal address flag |

**Address Types** (domain table):
- `home` - Home address
- `work` - Work address
- `mailing` - Mailing address
- `other` - Other address

### Documents (KYC)

Country-specific document tables for Know Your Customer compliance.

#### Brazil (`person_documents_br`)

| Column | Type | Description |
|--------|------|-------------|
| `person_id` | UUID | PK, FK to people |
| `cpf` | CHAR(11) | Tax ID (unique, mandatory) |
| `rg_number` | VARCHAR(20) | National ID number |
| `rg_issuer` | VARCHAR(20) | Issuing authority |
| `rg_issued_at` | DATE | Issue date |
| `address_id` | UUID | FK to addresses |
| `profession` | VARCHAR(100) | Current profession |
| `employer_name` | VARCHAR(200) | Employer name |
| `monthly_income_brl` | DECIMAL(15,2) | Monthly income in BRL |
| `is_pep` | BOOLEAN | Politically Exposed Person flag |
| `pep_details` | TEXT | PEP relationship details |

#### USA (`person_documents_us`)

| Column | Type | Description |
|--------|------|-------------|
| `person_id` | UUID | PK, FK to people |
| `ssn_last4` | CHAR(4) | Last 4 digits of SSN |
| `ssn_hash` | VARCHAR(128) | Full SSN hash for verification |
| `drivers_license_number` | VARCHAR(30) | Driver's license number |
| `drivers_license_state` | CHAR(2) | Issuing state |
| `drivers_license_issued_at` | DATE | Issue date |
| `drivers_license_expiry` | DATE | Expiration date |
| `state_id_number` | VARCHAR(30) | State ID (alternative) |
| `state_id_state` | CHAR(2) | State ID issuing state |
| `state_id_expiry` | DATE | State ID expiration |
| `occupation` | VARCHAR(100) | Current occupation |
| `employer_name` | VARCHAR(200) | Employer name |

#### Other Countries (`person_documents_etc`)

Generic document table for international users.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `person_id` | UUID | FK to people |
| `country_code` | CHAR(2) | Document country |
| `passport_number` | VARCHAR(30) | Passport number |
| `passport_country_issuer` | CHAR(2) | Passport issuing country |
| `passport_issued_at` | DATE | Passport issue date |
| `passport_expiry_date` | DATE | Passport expiration |
| `passport_full_name` | VARCHAR(255) | Name as in passport |
| `passport_nationality` | VARCHAR(100) | Nationality |
| `national_id_number` | VARCHAR(50) | National ID number |
| `national_id_type` | VARCHAR(50) | Type of national ID |
| `national_id_expiry` | DATE | National ID expiration |

**Constraint**: One document set per person per country (unique index on `person_id + country_code`).

---

## Financial Domain

### Account Holder

An **account holder** is the owning entity for financial accounts. It links to a main person (the primary holder).

**`account_holders`**
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `main_person_id` | UUID | FK to people (primary holder) |
| `created_at` | TIMESTAMP | Creation date |

### Relationship: Person vs Account Holder

```
┌─────────────┐         ┌──────────────────┐         ┌──────────────┐
│   Person    │ 1:1     │  Account Holder  │  1:N    │   Accounts   │
│  (identity) │────────►│   (ownership)    │────────►│  (financial) │
└─────────────┘         └──────────────────┘         └──────────────┘
                                 │
                                 │ N:M (additional members)
                                 ▼
                        ┌────────────────────┐
                        │ account_holder_    │
                        │     members        │
                        └────────────────────┘
```

### Account Holder Members

Additional people linked to an account holder (joint accounts, operators).

**`holder_relationship_types`** (domain table):
- `joint_account` - Joint account holder with equal rights
- `operator` - Account operator (limited access)

**`account_holder_members`**
| Column | Type | Description |
|--------|------|-------------|
| `account_holder_id` | UUID | FK to account_holders |
| `person_id` | UUID | FK to people |
| `relationship_type` | VARCHAR(30) | FK to relationship types |
| `added_at` | TIMESTAMP | When member was added |

### Privileges

Access permissions linking people to account holders.

**`privileges`**
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `person_id` | UUID | FK to people |
| `account_holder_id` | UUID | FK to account_holders |
| `privilege_type` | VARCHAR(50) | Type of access granted |
| `granted_at` | TIMESTAMP | When privilege was granted |

### Accounts

General account table supporting multiple account types per holder.

**`accounts`**
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `account_holder_id` | UUID | FK to account_holders |
| `country_code` | CHAR(2) | Account jurisdiction |
| `currency_code` | VARCHAR(20) | Account currency |
| `account_type` | VARCHAR(20) | fiat, crypto, stablecoin, etc. |
| `status` | VARCHAR(20) | active, suspended, closed |
| `created_at` | TIMESTAMP | Creation date |

**Unique Constraint**: One account per (holder, country, currency, type).

### Country-Specific Bank Details

#### Brazil (`account_details_br`)

| Column | Type | Description |
|--------|------|-------------|
| `account_id` | UUID | PK, FK to accounts |
| `ispb` | CHAR(8) | 8-digit ISPB code (Sistema de Pagamentos Brasileiro) |
| `bank_code` | CHAR(3) | 3-digit COMPE bank code |
| `branch_number` | VARCHAR(10) | Agency/branch number |
| `account_number` | VARCHAR(20) | Account + check digit |

#### USA (`account_details_us`)

| Column | Type | Description |
|--------|------|-------------|
| `account_id` | UUID | PK, FK to accounts |
| `routing_number` | CHAR(9) | 9-digit ABA routing transit number |
| `account_number` | VARCHAR(20) | Bank account number |

---

## Blockchain Domain

### HD Wallet Architecture

Zori.pay uses **Hierarchical Deterministic (HD) Wallets** following BIP-44 standard.

```
┌─────────────────────────────────────────────────────────────────────┐
│                        HD WALLET STRUCTURE                          │
│                                                                     │
│   Master Seed (BIP-39 mnemonic → 512-bit seed)                     │
│        │                                                            │
│        │  Encrypted with AES-256-GCM                               │
│        │  ├── encryption_iv (12 bytes)                             │
│        │  ├── encryption_auth_tag (16 bytes)                       │
│        │  └── encryption_key_id (HSM/KMS reference)                │
│        │                                                            │
│        ▼                                                            │
│   Derivation Path: m / purpose' / coin_type' / account' / change / index
│                    │      │           │           │         │      │
│                    │      │           │           │         │      └─ Address Index
│                    │      │           │           │         └─ 0=external, 1=internal
│                    │      │           │           └─ Account number
│                    │      │           └─ Coin type (60=ETH, 0=BTC, etc.)
│                    │      └─ 44 for BIP-44
│                    └─ Master
│                                                                     │
│   Example Paths:                                                    │
│   • m/44'/60'/0'/0/0  → First Ethereum/Polygon address             │
│   • m/44'/60'/0'/0/1  → Second Ethereum/Polygon address            │
│   • m/44'/0'/0'/0/0   → First Bitcoin address                      │
│   • m/44'/501'/0'/0/0 → First Solana address                       │
└─────────────────────────────────────────────────────────────────────┘
```

### Wallet Structure

**`account_blockchain`** - One HD wallet per holder per blockchain

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `account_holder_id` | UUID | FK to account_holders |
| `blockchain_code` | VARCHAR(20) | FK to blockchain_networks |
| `encrypted_master_seed` | BYTEA | AES-256-GCM encrypted BIP-39 seed |
| `encryption_iv` | BYTEA | 12-byte nonce (unique per encryption) |
| `encryption_auth_tag` | BYTEA | 16-byte GCM authentication tag |
| `encryption_key_id` | VARCHAR(100) | HSM/KMS key reference |
| `key_derivation_standard` | VARCHAR(20) | BIP44, BIP49, BIP84, BIP86 |
| `created_at` | TIMESTAMP | Creation date |

**Unique Constraint**: One wallet per (holder, blockchain).

### Derived Addresses

**`account_blockchain_addresses`** - Addresses derived from HD wallet

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `account_blockchain_id` | UUID | FK to wallet |
| `public_address` | VARCHAR(255) | Public blockchain address |
| `derivation_path` | VARCHAR(100) | BIP-44 path (e.g., m/44'/60'/0'/0/0) |
| `address_index` | INTEGER | Index in derivation sequence |
| `label` | VARCHAR(100) | User-friendly label |
| `is_active` | BOOLEAN | Can receive funds (privacy rotation) |
| `is_primary` | BOOLEAN | Default receiving address |
| `created_at` | TIMESTAMP | Creation date |
| `deactivated_at` | TIMESTAMP | Auto-set when deactivated |

**Constraints**:
- One primary address per wallet (partial unique index on `is_primary = true`)
- Unique derivation path per wallet
- Unique public address per wallet

**Privacy Rotation**: Addresses can be deactivated (`is_active = false`) for privacy. A trigger automatically sets `deactivated_at` when an address is deactivated.

### Key Derivation Standards

**`key_derivation_standards`**

| Code | Name | Description |
|------|------|-------------|
| `BIP44` | BIP-44 | Multi-Account Hierarchy for Deterministic Wallets |
| `BIP49` | BIP-49 | P2WPKH-nested-in-P2SH (SegWit compatible) |
| `BIP84` | BIP-84 | P2WPKH (Native SegWit) |
| `BIP86` | BIP-86 | P2TR (Taproot) |
| `SLIP44` | SLIP-44 | Registered coin types for BIP-44 |
| `CUSTOM` | Custom | Non-standard derivation |

### Blockchain Networks

**`blockchain_networks`** - 32+ supported networks

**Layer 1 Networks:**
| Code | Name |
|------|------|
| `BITCOIN` | Bitcoin |
| `ETHEREUM` | Ethereum |
| `SOLANA` | Solana |
| `POLYGON` | Polygon |
| `AVALANCHE` | Avalanche C-Chain |
| `ALGORAND` | Algorand |
| `STELLAR` | Stellar |
| `TRON` | Tron |
| `NEAR` | NEAR Protocol |
| `HEDERA` | Hedera |
| `CELO` | Celo |
| `SUI` | Sui |
| `APTOS` | Aptos |
| `BNB` | BNB Chain |
| `FANTOM` | Fantom |
| `POLKADOT` | Polkadot |
| `COSMOS` | Cosmos Hub |
| `CARDANO` | Cardano |
| `XRP` | XRP Ledger |
| `TON` | TON (The Open Network) |

**Layer 2 / Rollups:**
| Code | Name |
|------|------|
| `ARBITRUM` | Arbitrum One |
| `OPTIMISM` | OP Mainnet |
| `BASE` | Base |
| `ZKSYNC` | zkSync Era |
| `LINEA` | Linea |
| `MOONBEAM` | Moonbeam |
| `MANTLE` | Mantle |
| `SCROLL` | Scroll |
| `BLAST` | Blast |

**Private / Enterprise:**
| Code | Name |
|------|------|
| `RAYLS` | Rayls (Parfin) |
| `ARC` | Arc (Circle) |
| `NOBLE` | Noble (Cosmos) |

---

## Currency System

### Asset Types

**`asset_types`**
| Code | Description |
|------|-------------|
| `fiat` | Government-issued currency |
| `crypto` | Native blockchain cryptocurrency |
| `stablecoin` | Pegged digital currency |
| `points` | Loyalty/reward points |
| `other` | Other asset types |

### Currencies

**`currencies`**
| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `code` | VARCHAR(20) | Currency code (unique) |
| `name` | VARCHAR(100) | Full name |
| `decimals` | INTEGER | Decimal precision (NULL if varies) |
| `asset_type_code` | VARCHAR(20) | FK to asset_types |

### Decimal Precision

Different currencies have different decimal precision:

| Category | Examples | Decimals |
|----------|----------|----------|
| **0 decimals** | JPY, KRW, VND, CLP | 0 |
| **2 decimals** | USD, EUR, BRL, GBP | 2 |
| **3 decimals** | BHD, KWD, OMR | 3 |
| **6 decimals** | USDC, USDT, EURC | 6 |
| **8 decimals** | BTC, BRL1 | 8 |
| **9 decimals** | SOL | 9 |
| **18 decimals** | ETH, POL, DAI | 18 |

### Currency-Blockchain Mapping

**`currency_blockchain_configs`** - Maps currencies to blockchains with contract addresses

| Column | Type | Description |
|--------|------|-------------|
| `currency_id` | UUID | FK to currencies |
| `blockchain_code` | VARCHAR(20) | FK to blockchain_networks |
| `network_decimals` | INTEGER | Override decimals for this chain |
| `contract_address` | VARCHAR(255) | Token contract (NULL for native) |

**Examples:**

| Currency | Blockchain | Contract | Decimals |
|----------|------------|----------|----------|
| USDC | Ethereum | 0xA0b86991c... | 6 |
| USDC | Polygon | 0x3c499c542... | 6 |
| USDC | Solana | EPjFWdd5Au... | 6 |
| ETH | Ethereum | NULL (native) | 18 |
| POL | Polygon | NULL (native) | 18 |
| PYUSD | Ethereum | 0x6c3ea9036... | 6 |
| PYUSD | Solana | 2b1kV6DkPA... | 6 |
| BRL1 | Polygon | (contract) | 8 |

### Variable Decimals

Some tokens have different decimals on different chains. The `network_decimals` field overrides the base currency `decimals` when they differ.

**Example: PYUSD**
- Base `decimals`: NULL (varies)
- Ethereum: 6 decimals
- Solana: 6 decimals

---

## Audit Domain

### People History

**`audit_schema.people_history`** - Complete change history for people records

| Column | Type | Description |
|--------|------|-------------|
| `history_id` | UUID | Primary key |
| `person_id` | UUID | Reference to person |
| `full_name` | VARCHAR(255) | Name at time of change |
| `date_of_birth` | DATE | DOB at time of change |
| `mother_name` | VARCHAR(255) | Mother's name at time |
| `birth_city` | VARCHAR(100) | Birth city at time |
| `birth_country` | CHAR(2) | Birth country at time |
| `operation` | CHAR(1) | I=Insert, U=Update, D=Delete |
| `changed_at` | TIMESTAMP | When change occurred |
| `changed_by` | VARCHAR(100) | Who made the change |

### Audit Trigger

Every INSERT, UPDATE, or DELETE on `people` automatically creates a history record:

```sql
CREATE TRIGGER trg_people_audit
    AFTER INSERT OR UPDATE OR DELETE ON registration_schema.people
    FOR EACH ROW
    EXECUTE FUNCTION audit_schema.fn_people_audit();
```

### Timeline View

**`audit_schema.v_people_timeline`** - Convenient view of person changes

```sql
SELECT * FROM audit_schema.v_people_timeline
WHERE person_id = 'uuid-here'
ORDER BY changed_at DESC;
```

---

## Summary Diagrams

### Contact Relationships

```
                    ┌─────────────┐
                    │   Person    │
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
    ┌──────────┐     ┌──────────┐     ┌──────────┐
    │ Phones   │     │ Emails   │     │Addresses │
    │  (N:M)   │     │  (N:M)   │     │  (N:M)   │
    └──────────┘     └──────────┘     └──────────┘
         │                │                │
         │                │                │
    ┌────┴────┐      ┌────┴────┐      ┌────┴────┐
    │ * Many  │      │ * Many  │      │ * Many  │
    │ * 1 for │      │ * 1 for │      │ * 1 is  │
    │   login │      │   login │      │  fiscal │
    └─────────┘      └─────────┘      └─────────┘
```

### Account Ownership

```
    Person ──1:1──► Account Holder ──1:N──► Accounts
                          │
                          │ N:M
                          ▼
                    Additional Members
                    (joint/operators)
```

### Blockchain Wallet

```
    Account Holder ──1:N──► HD Wallet (per blockchain)
                                 │
                                 │ 1:N
                                 ▼
                           Derived Addresses
                           ├── is_active (privacy)
                           └── is_primary (default)
```

---

## Design Principles

1. **Normalization**: Phones and emails are stored once, referenced many times
2. **Partial Unique Indexes**: Enforce "one login per contact" without blocking multiple people from sharing contacts
3. **Country-Specific Tables**: KYC requirements and bank details vary by country
4. **HD Wallet Security**: Master seeds encrypted at rest, keys in HSM/KMS
5. **Audit Trail**: All identity changes tracked with full history
6. **Flexible Currencies**: Support for variable decimal precision per blockchain
