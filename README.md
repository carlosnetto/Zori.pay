# Zori.pay

Multi-country banking platform with blockchain integration.

## Overview

Zori.pay is a financial platform that bridges traditional banking with blockchain technology. Users can:

- **Send & Receive** cryptocurrency (POL, USDC, USDT)
- **Manage Wallets** with HD wallet security (BIP-44)
- **Complete KYC** with document upload and verification
- **View Transactions** with real-time blockchain data

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Rust (for API server)
- Node.js 18+ (for web frontend)

### 1. Start Database

```bash
docker-compose up -d
```

### 2. Start API Server

```bash
cd api-server
cargo run
```

Server runs on `http://localhost:3001`

### 3. Start Web Frontend

```bash
cd web
npm install
npm run dev
```

Frontend runs on `http://localhost:3000`

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ React Frontend  │────▶│ Rust API Server │────▶│ PostgreSQL      │
│ (Vite + TS)     │     │ (Axum)          │     │ (Docker)        │
└─────────────────┘     └────────┬────────┘     └─────────────────┘
                                 │
                    ┌────────────┼────────────┐
                    ▼            ▼            ▼
              ┌──────────┐ ┌──────────┐ ┌──────────┐
              │ Polygon  │ │ Google   │ │ Alchemy  │
              │ Network  │ │ Drive    │ │ RPC      │
              └──────────┘ └──────────┘ └──────────┘
```

### Technology Stack

| Component | Technology |
|-----------|------------|
| Frontend | React + TypeScript + Vite + Tailwind CSS |
| Backend | Rust + Axum + SQLx |
| Database | PostgreSQL + Liquibase |
| Blockchain | Polygon (ethers-rs) |
| Auth | Google OAuth + WebAuthn Passkeys |
| Hosting | Cloudflare Pages + Tunnel |

## Project Structure

```
Zori.pay/
├── api-server/           # Rust backend
│   ├── src/
│   │   ├── auth/        # Google OAuth, Passkey, JWT
│   │   ├── crypto/      # HD wallets, ERC20
│   │   ├── routes/      # API endpoints
│   │   └── services/    # Google Drive
│   └── secrets/         # Credentials (gitignored)
├── web/                  # React frontend
│   ├── src/
│   │   ├── components/  # UI components
│   │   └── services/    # API clients
│   └── public/          # Static assets
├── migrations/           # Liquibase SQL migrations
├── openapi/              # API documentation
└── docs/                 # Additional documentation
```

## API Documentation

Full OpenAPI 3.1.0 specifications in `openapi/` directory:

| API | Description |
|-----|-------------|
| [auth.yaml](openapi/auth.yaml) | Google OAuth + Passkey authentication |
| [balance.yaml](openapi/balance.yaml) | Wallet balance retrieval |
| [receive.yaml](openapi/receive.yaml) | Deposit address |
| [send.yaml](openapi/send.yaml) | Send transactions + fee estimation |
| [transactions.yaml](openapi/transactions.yaml) | Transaction history |
| [kyc.yaml](openapi/kyc.yaml) | Brazilian account opening |
| [profile.yaml](openapi/profile.yaml) | User profile retrieval |
| [reference-data.yaml](openapi/reference-data.yaml) | Static reference data (countries, currencies, etc.) |

## Database

PostgreSQL with three schemas:

| Schema | Purpose |
|--------|---------|
| `registration_schema` | Identity (people, contacts, documents) |
| `accounts_schema` | Financial (accounts, wallets, currencies) |
| `audit_schema` | Compliance (history, audit trails) |

## Documentation

| Document | Description |
|----------|-------------|
| [docs/DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) | Database tables and relationships |
| [docs/REACT_INTEGRATION.md](docs/REACT_INTEGRATION.md) | Vite proxy and frontend setup |
| [docs/WEB_LOGIN_INTEGRATION.md](docs/WEB_LOGIN_INTEGRATION.md) | Authentication flow |
| [docs/TESTING.md](docs/TESTING.md) | Testing guide |
| [docs/UPDATE_GOOGLE_CALLBACK.md](docs/UPDATE_GOOGLE_CALLBACK.md) | Google OAuth configuration |

### Migrations

Uses Liquibase with 42 changesets across 6 migration files (v001-v006).

```bash
# Reset database
docker-compose down -v && docker-compose up -d

# Check migration status
docker-compose logs liquibase
```

## Supported Assets

### Blockchain
- **Polygon** (Mainnet) - Primary network

### Currencies

| Code | Name | Type | Decimals |
|------|------|------|----------|
| POL | Polygon | Native | 18 |
| USDC | USD Coin | ERC20 | 6 |
| USDT | Tether | ERC20 | 6 |
| BRL1 | Zori Real | ERC20 | 18 |

## Development

### Environment Variables

API Server (`.env`):
```bash
DATABASE_URL=postgres://admin:password@localhost:5432/banking_system
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret
POLYGON_RPC_URL=https://polygon-mainnet.g.alchemy.com/v2/your-key
MASTER_ENCRYPTION_KEY=your-32-byte-hex-key
```

Web Frontend (`.env.development`):
```bash
VITE_API_URL=http://localhost:3001/v1
```

### Google Drive Setup

KYC documents are stored in Google Drive. First-time setup:

```bash
cd api-server
cargo run --bin drive_config
```

See [CLAUDE.md](CLAUDE.md) for detailed Google Cloud configuration.

### Deployment

```bash
# Build and deploy frontend
cd web
npm run build
npx wrangler pages deploy dist --project-name=zori-pay

# Start API tunnel (for production frontend)
cloudflared tunnel run zori-api
```

## Security

- **HD Wallets**: BIP-44 compliant with AES-256-GCM encryption
- **Authentication**: Two-factor (Google OAuth + Passkey)
- **Server-Side Signing**: Private keys never leave the server
- **Audit Trail**: Complete history tracking

## License

Proprietary - All rights reserved.

## Author

Carlos Augusto Leite Netto
carlos.netto@gmail.com
