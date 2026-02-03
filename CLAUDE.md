# Claude Context - Zori.pay

> **Read this file first when resuming work on this project.**

## Project Overview

**Zori.pay** is a multi-country banking platform with blockchain integration, enabling users to manage cryptocurrency wallets, send/receive tokens, and comply with KYC regulations.

- **Owner**: Carlos Augusto Leite Netto (carlos.netto@gmail.com)
- **Current Status**: MVP functional with web frontend, API backend, and database
- **Production URL**: https://fb975528.zori-pay.pages.dev (Cloudflare Pages)
- **API Access**: Via Cloudflare Tunnel to local API server

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        CLOUDFLARE INFRASTRUCTURE                         │
│                                                                          │
│  ┌──────────────────────┐         ┌────────────────────────────────┐   │
│  │ Cloudflare Pages     │         │ Cloudflare Tunnel              │   │
│  │ (React Frontend)     │         │ (API Proxy)                    │   │
│  │                      │────────▶│                                │   │
│  │ zoripay.xyz          │         │ Routes /v1/* to localhost:3001 │   │
│  └──────────────────────┘         └─────────────┬──────────────────┘   │
└─────────────────────────────────────────────────┼──────────────────────┘
                                                  │
                                                  ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          LOCAL DEVELOPMENT                               │
│                                                                          │
│  ┌──────────────────────┐         ┌────────────────────────────────┐   │
│  │ Rust API Server      │         │ PostgreSQL                     │   │
│  │ (Axum)               │◀───────▶│ (Docker)                       │   │
│  │ localhost:3001       │         │ localhost:5432                 │   │
│  └──────────────────────┘         └────────────────────────────────┘   │
│           │                                                             │
│           │                       ┌────────────────────────────────┐   │
│           └──────────────────────▶│ Google Drive                   │   │
│                                   │ (KYC Document Storage)         │   │
│                                   └────────────────────────────────┘   │
│                                                                          │
│           │                       ┌────────────────────────────────┐   │
│           └──────────────────────▶│ Polygon Network                │   │
│                                   │ (via Alchemy RPC)              │   │
│                                   └────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

```
Zori.pay/
├── api-server/                    # Rust backend (Axum framework)
│   ├── src/
│   │   ├── main.rs               # Server entry point, routes
│   │   ├── config.rs             # Environment configuration
│   │   ├── db.rs                 # Database operations
│   │   ├── error.rs              # Error handling types
│   │   ├── models.rs             # Data models
│   │   ├── auth/                 # Authentication modules
│   │   │   ├── google.rs         # Google OAuth client
│   │   │   ├── passkey.rs        # WebAuthn/Passkey verification
│   │   │   └── jwt.rs            # JWT token management
│   │   ├── crypto/               # Cryptographic operations
│   │   │   ├── wallet.rs         # HD wallet derivation, encryption
│   │   │   └── erc20.rs          # ERC20 token interface (abigen)
│   │   ├── routes/               # API endpoints
│   │   │   ├── auth.rs           # /v1/auth/* endpoints
│   │   │   ├── balance.rs        # /v1/balance endpoint
│   │   │   ├── receive.rs        # /v1/receive endpoint
│   │   │   ├── send.rs           # /v1/send endpoints
│   │   │   ├── transactions.rs   # /v1/transactions endpoint
│   │   │   └── kyc.rs            # /v1/kyc/* endpoints
│   │   ├── services/
│   │   │   └── google_drive.rs   # Google Drive API client
│   │   └── bin/
│   │       └── drive_config.rs   # OAuth setup tool for Drive
│   ├── secrets/                   # Credentials (gitignored)
│   │   ├── google-drive-token.json
│   │   └── README.md
│   ├── Cargo.toml
│   └── .env                       # Environment variables
│
├── web/                           # React frontend (Vite + TypeScript)
│   ├── src/
│   │   ├── App.tsx               # Main application component
│   │   ├── components/
│   │   │   ├── Dashboard.tsx     # Main wallet view
│   │   │   ├── SendModal.tsx     # Send crypto modal
│   │   │   ├── ReceiveModal.tsx  # Receive/QR code modal
│   │   │   ├── Onboarding.tsx    # KYC onboarding flow
│   │   │   ├── LoginModal.tsx    # Google OAuth login
│   │   │   ├── PasskeyVerify.tsx # Passkey verification
│   │   │   └── Navbar.tsx        # Navigation bar
│   │   ├── services/
│   │   │   ├── auth.ts           # Authentication service
│   │   │   ├── balance.ts        # Balance fetching
│   │   │   ├── send.ts           # Send transactions
│   │   │   ├── receive.ts        # Receive address
│   │   │   └── transactions.ts   # Transaction history
│   │   └── translations.ts       # i18n translations (6 languages)
│   ├── public/images/            # Currency logos (PNG/SVG)
│   ├── .env.development
│   ├── .env.production
│   └── package.json
│
├── migrations/                    # Liquibase database migrations
│   ├── changelog-master.xml
│   ├── v001_schemas.xml          # Database schemas
│   ├── v002_registration.xml     # Identity tables
│   ├── v003_accounts.xml         # Financial tables
│   ├── v004_audit.xml            # Audit trail
│   ├── v005_blockchain_wallets.xml
│   ├── v006_seed_reference_data.xml
│   └── old/                      # Archived migrations (v007 test data)
│
├── openapi/                       # API documentation (OpenAPI 3.1.0)
│   ├── README.md                 # API index
│   ├── auth.yaml                 # Authentication API
│   ├── balance.yaml              # Balance API
│   ├── receive.yaml              # Receive API
│   ├── send.yaml                 # Send API
│   ├── transactions.yaml         # Transactions API
│   └── kyc.yaml                  # KYC API
│
├── docs/
│   ├── DATABASE_SCHEMA.md        # Database tables and relationships
│   ├── REACT_INTEGRATION.md      # Vite proxy and frontend setup
│   ├── WEB_LOGIN_INTEGRATION.md  # Authentication flow
│   ├── TESTING.md                # Testing guide
│   └── UPDATE_GOOGLE_CALLBACK.md # Google OAuth configuration
│
├── .credentials/                  # Google Cloud config (gitignored)
│   ├── google_client_id
│   ├── google_client_secret
│   └── README.md
│
├── docker-compose.yml            # PostgreSQL + Liquibase
├── CLAUDE.md                     # This file (Claude context)
└── README.md                     # Project overview
```

---

## Docker & Database Quick Reference

### Docker Container
```bash
# Container name: global_banking_db
# Run psql:
docker exec -i global_banking_db psql -U admin -d banking_system -c "SELECT ..."
```

### Connection Details
| Setting | Value |
|---------|-------|
| Container | `global_banking_db` |
| User | `admin` |
| Password | `mysecretpassword` |
| Database | `banking_system` |
| Port | `5432` |

### Key Table Columns (for queries)

```sql
-- registration_schema.people
id, full_name, date_of_birth, mother_name, birth_city, birth_country

-- registration_schema.emails
id, email_address

-- registration_schema.person_emails
person_id, email_id

-- accounts_schema.account_holders
id, main_person_id, created_at

-- accounts_schema.account_blockchain
id, account_holder_id, blockchain_code, encrypted_master_seed, encryption_iv, encryption_auth_tag, encryption_key_id

-- accounts_schema.account_blockchain_addresses
id, account_blockchain_id, public_address, derivation_path, address_index, is_active, is_primary
```

### Common Query: Find wallet owner
```sql
SELECT p.full_name, e.email_address, addr.public_address, w.blockchain_code
FROM accounts_schema.account_blockchain_addresses addr
JOIN accounts_schema.account_blockchain w ON w.id = addr.account_blockchain_id
JOIN accounts_schema.account_holders ah ON ah.id = w.account_holder_id
JOIN registration_schema.people p ON p.id = ah.main_person_id
LEFT JOIN registration_schema.person_emails pe ON pe.person_id = p.id
LEFT JOIN registration_schema.emails e ON e.id = pe.email_id
WHERE LOWER(addr.public_address) = LOWER('0x...')
```

---

## Database Schemas

| Schema | Purpose |
|--------|---------|
| `registration_schema` | Identity (people, contacts, addresses, documents) |
| `accounts_schema` | Financial (accounts, currencies, blockchain wallets) |
| `audit_schema` | Compliance and audit trails |

### Key Tables

- `people` - User identity records (`full_name`, not first/last)
- `person_documents_br` - Brazilian KYC documents (CPF, etc.)
- `account_holders` - Links people to financial accounts (`main_person_id`)
- `accounts` - Currency accounts (BRL1, USDC, USDT, etc.)
- `account_blockchain` - HD wallet seeds (encrypted)
- `account_blockchain_addresses` - Derived wallet addresses

See `docs/DATABASE_SCHEMA.md` for complete documentation.

---

## Google Drive Integration

### Purpose
KYC documents (ID photos, selfies, proof of address) are uploaded to Google Drive for compliance storage.

### Architecture
```
┌──────────────────────────────────────────────────────────────────┐
│                     GOOGLE CLOUD PROJECT                          │
│  Project ID: asdj238sjasd                                        │
│  Project Number: 707398925642                                    │
│                                                                   │
│  ┌────────────────────────┐    ┌────────────────────────────┐   │
│  │ OAuth 2.0 Client       │    │ Google Drive               │   │
│  │ (User Consent Flow)    │    │                            │   │
│  │                        │    │ Root Folder:               │   │
│  │ Client ID:             │    │ 1ERvzZMc92XBv_k3SBxm...   │   │
│  │ 964555560579-m91k...   │    │                            │   │
│  │                        │    │ DOC_DB/                    │   │
│  │ Used for:              │    │   └── {CPF}/               │   │
│  │ - Drive authorization  │    │       ├── cnh_front.jpg    │   │
│  │ - Token refresh        │    │       ├── cnh_back.jpg     │   │
│  └────────────────────────┘    │       ├── selfie.jpg       │   │
│                                 │       └── proof.pdf        │   │
│                                 └────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

### OAuth Clients

There are two OAuth clients in the Google Cloud project:

1. **User Login OAuth** (for Google Sign-In):
   - Client ID: `964555560579-5bfmpqrmtub763b1d7vqufl3dh1p4t16.apps.googleusercontent.com`
   - Used by: API auth endpoints

2. **Drive Access OAuth** (for document upload):
   - Client ID: `964555560579-m91kc16dq8ppsna1uv9gnu1d3q66tkue.apps.googleusercontent.com`
   - Used by: `drive_config.rs` and `google_drive.rs`

### Authorized Redirect URIs

Configure these in [Google Cloud Console](https://console.cloud.google.com/apis/credentials):

```
http://localhost:3000/auth/callback     # React dev
http://localhost:8080/auth/callback     # API test page
http://localhost:8085/callback          # Drive config tool
https://zoripay.xyz/auth/callback       # Production
```

### First-Time Setup

1. **Run the Drive configuration tool**:
   ```bash
   cd api-server
   cargo run --bin drive_config
   ```

2. **Browser opens for Google OAuth consent**:
   - Log in with an account that has access to the Drive folder
   - Grant "See, edit, create, and delete only the specific Google Drive files you use with this app" permission

3. **Token saved**:
   - Tokens stored in `api-server/secrets/google-drive-token.json`
   - Auto-refreshed by `DriveClient` when expired

### File Organization in Drive

```
Drive Root (1ERvzZMc92XBv_k3SBxmHLsCJnZUnqON_)
└── DOC_DB/                           # Created automatically
    └── {CPF}/                        # e.g., 07289048881/
        ├── cnh_front.jpg             # Driver's license front
        ├── cnh_back.jpg              # Driver's license back
        ├── selfie.jpg                # User photo
        └── proof_of_address.pdf      # Address proof
```

### Environment Variables

```bash
# api-server/.env
GOOGLE_DRIVE_SERVICE_ACCOUNT_KEY=./secrets/google-drive-service-account.json  # Legacy, not used
GOOGLE_DRIVE_ROOT_FOLDER_ID=1ERvzZMc92XBv_k3SBxmHLsCJnZUnqON_
```

### How It Works

1. **KYC endpoint** (`/v1/kyc/open-account-br`) receives multipart form with documents
2. **DriveClient** ensures folder structure exists: `DOC_DB/{CPF}/`
3. **Files uploaded** with proper naming and MIME types
4. **Tokens auto-refresh** when expired (stored refresh token)

---

## Blockchain Integration

### Supported Network
Currently **Polygon Mainnet only** (Chain ID: 137)

### Supported Currencies

| Code | Name | Type | Decimals | Contract Address |
|------|------|------|----------|-----------------|
| POL | Polygon | Native | 18 | - |
| USDC | USD Coin | ERC20 | 6 | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` |
| USDT | Tether | ERC20 | 6 | `0xc2132D05D31c914a87C6611C10748AEb04B58e8F` |
| BRL1 | Zori Real | ERC20 | 18 | (to be deployed) |

### HD Wallet Architecture

- **Standard**: BIP-44 compliant
- **Derivation Path**: `m/44'/60'/0'/0/0` (Ethereum/Polygon)
- **Encryption**: AES-256-GCM for master seeds
- **Storage**: `account_blockchain.encrypted_master_seed`

### RPC Provider

- **Alchemy Polygon RPC**: `https://polygon-mainnet.g.alchemy.com/v2/{API_KEY}`
- Used for: balance queries, transaction sending, gas estimation
- Transaction history via Alchemy Asset Transfers API

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/v1/auth/google` | Initiate Google OAuth |
| POST | `/v1/auth/google/callback` | Exchange code for token |
| POST | `/v1/auth/passkey/challenge` | Request passkey challenge |
| POST | `/v1/auth/passkey/verify` | Verify passkey, get JWT |
| POST | `/v1/auth/refresh` | Refresh access token |
| POST | `/v1/auth/logout` | Invalidate session |
| GET | `/v1/balance` | Get all token balances |
| GET | `/v1/receive` | Get deposit address |
| POST | `/v1/send` | Send cryptocurrency |
| POST | `/v1/send/estimate` | Estimate gas fees |
| GET | `/v1/transactions` | Get transaction history |
| POST | `/v1/kyc/open-account-br` | Open Brazilian account |

See `openapi/` directory for full OpenAPI 3.1.0 specifications.

---

## Development Commands

### Start Database
```bash
docker-compose up -d
```

### Start API Server
```bash
cd api-server
cargo run
```
Server runs on `http://localhost:3001`

### Start Web Frontend
```bash
cd web
npm run dev
```
Frontend runs on `http://localhost:3000`

### Start Cloudflare Tunnel
```bash
cloudflared tunnel run zori-api
```
Required for production frontend to access local API.

### Deploy to Cloudflare Pages
```bash
cd web
npm run build
npx wrangler pages deploy dist --project-name=zori-pay
```

### Reset Database
```bash
docker-compose down -v
docker-compose up -d
```

### Configure Google Drive (first time only)
```bash
cd api-server
cargo run --bin drive_config
```

---

## Test Data

Carlos Netto is seeded for testing:

| Field | Value |
|-------|-------|
| Person ID | `550e8400-e29b-41d4-a716-446655440000` |
| Account Holder ID | `f47ac10b-58cc-4372-a567-0e02b2c3d479` |
| Email | `carlos.netto@gmail.com` |
| CPF | `072.890.488-81` |
| Polygon Address | `0x732D57fE3478984E59fF48d224653097ec0C730f` |
| Accounts | BRL1, SOL, USDC, USDT |

---

## Key Technical Decisions

1. **OAuth + Passkey Auth**: Two-factor authentication using Google OAuth followed by WebAuthn passkey verification
2. **HD Wallets**: Single encrypted seed per user, addresses derived deterministically
3. **Polygon-First**: Starting with Polygon for low gas fees and fast transactions
4. **Server-Side Signing**: Private keys never leave the server; transactions signed server-side
5. **Alchemy API**: Used for transaction history (asset transfers API with "erc20" and "external" categories)
6. **Google Drive for KYC**: Simple, reliable document storage with folder organization by CPF
7. **Cloudflare Pages + Tunnel**: Static frontend hosting with tunnel to local API

---

## Recent Work Summary

1. **Database Schema**: Complete Liquibase migrations (49+ changesets)
2. **Authentication**: Google OAuth + Passkey flow working
3. **KYC Onboarding**: Brazilian account opening with document upload to Google Drive
4. **Wallet Operations**: Balance, send (POL + ERC20), receive, transaction history
5. **Web Frontend**: React app with Dashboard, Send/Receive modals, QR codes
6. **OpenAPI Docs**: Complete API documentation for all endpoints
7. **Cloudflare Deployment**: Frontend deployed, tunnel configured

---

## Known Issues / TODO

- [ ] Passkey registration UI (currently only verification works)
- [ ] BRL1 token contract deployment
- [ ] Additional blockchain support (Ethereum, Solana, etc.)
- [ ] Token refresh auto-handling in frontend
- [ ] Rate limiting on API endpoints
- [ ] Production-grade error handling
- [ ] Delete `migrations/old/` directory

---

*Last updated: 2026-02-03*
