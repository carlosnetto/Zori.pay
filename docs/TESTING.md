# Testing Zori.pay

## Quick Start

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
npm run dev
```

Frontend runs on `http://localhost:3000`

## Test User

Only one test user is seeded in the database:

| Field | Value |
|-------|-------|
| Email | `carlos.netto@gmail.com` |
| CPF | `072.890.488-81` |
| Polygon Address | `0x732D57fE3478984E59fF48d224653097ec0C730f` |

Other emails will return `USER_NOT_FOUND`.

## Testing Authentication

### Option 1: Web App (Recommended)

1. Open `http://localhost:3000`
2. Click "Sign In / Sign Up"
3. Click "Continue with Google"
4. Login with `carlos.netto@gmail.com`
5. After Google auth → Passkey verification modal appears
6. Complete passkey → Dashboard with balance

### Option 2: API with cURL

**Step 1: Get Google OAuth URL**
```bash
curl -X POST http://localhost:3001/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"redirect_uri": "http://localhost:3000/auth/callback"}'
```

**Step 2: Visit the `authorization_url` in browser**

**Step 3: Exchange the code (from redirect URL)**
```bash
curl -X POST http://localhost:3001/v1/auth/google/callback \
  -H "Content-Type: application/json" \
  -d '{
    "code": "YOUR_AUTH_CODE_FROM_URL",
    "redirect_uri": "http://localhost:3000/auth/callback"
  }'
```

## Testing Wallet Operations

### Get Balance
```bash
curl -X GET http://localhost:3001/v1/balance \
  -H "Authorization: Bearer <access_token>"
```

### Get Receive Address
```bash
curl -X GET http://localhost:3001/v1/receive \
  -H "Authorization: Bearer <access_token>"
```

### Estimate Transaction
```bash
curl -X POST http://localhost:3001/v1/send/estimate \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "to_address": "0xF766EDB5E3bEbC44098E2C6D06675e7Ba50C28c9",
    "amount": "0",
    "currency_code": "POL"
  }'
```

### Send Transaction
```bash
curl -X POST http://localhost:3001/v1/send \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "to_address": "0xF766EDB5E3bEbC44098E2C6D06675e7Ba50C28c9",
    "amount": "0.01",
    "currency_code": "POL"
  }'
```

### Get Transactions
```bash
curl -X GET "http://localhost:3001/v1/transactions?limit=10" \
  -H "Authorization: Bearer <access_token>"
```

## Testing KYC Onboarding

```bash
curl -X POST http://localhost:3001/v1/kyc/open-account-br \
  -F "full_name=Test User" \
  -F "mother_name=Test Mother" \
  -F "cpf=12345678901" \
  -F "email=test@example.com" \
  -F "phone=+5511999999999" \
  -F "selfie=@/path/to/selfie.jpg" \
  -F "proof_of_address=@/path/to/proof.pdf" \
  -F "cnh_front=@/path/to/cnh_front.jpg" \
  -F "cnh_back=@/path/to/cnh_back.jpg"
```

## Expected Results

### Successful Login
```json
{
  "intermediate_token": "eyJhbGc...",
  "expires_in": 300,
  "user": {
    "person_id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "carlos.netto@gmail.com",
    "display_name": "CARLOS AUGUSTO LEITE NETTO"
  }
}
```

### Failed Login (other emails)
```json
{
  "code": "USER_NOT_FOUND",
  "message": "No account found for this email"
}
```

### Balance Response
```json
{
  "address": "0x732D57fE3478984E59fF48d224653097ec0C730f",
  "blockchain": "POLYGON",
  "balances": [
    {"currency_code": "POL", "balance": "1000000000000000000", "decimals": 18, "formatted_balance": "1.00"},
    {"currency_code": "USDC", "balance": "10000000", "decimals": 6, "formatted_balance": "10.00"}
  ]
}
```

## Server Commands

**Stop server**:
```bash
pkill -f zori-api
```

**Restart server**:
```bash
cd api-server
cargo run
```

**View detailed logs**:
```bash
RUST_LOG=debug cargo run
```

## Troubleshooting

### Server won't start

```bash
# Check if port 3001 is in use
lsof -i :3001

# Kill existing process
pkill -f zori-api

# Check database is running
docker ps | grep postgres

# Verify .env file
cat api-server/.env
```

### Google OAuth errors

1. Check callback URL in [Google Console](https://console.cloud.google.com/apis/credentials)
2. Ensure `http://localhost:3000/auth/callback` is listed
3. Verify credentials in `.env` match

### Database connection errors

```bash
# Ensure PostgreSQL is running
docker-compose up -d

# Check logs
docker-compose logs postgres

# Reset database
docker-compose down -v
docker-compose up -d
```

### Passkey verification fails

The test passkey in the database is a placeholder. For real passkey verification:

1. Passkey registration endpoint needs to be implemented
2. User must register their device/biometric first
3. Current placeholder only works for testing flow

## Environment Variables

Key variables in `api-server/.env`:

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret |
| `POLYGON_RPC_URL` | Alchemy RPC endpoint |
| `MASTER_ENCRYPTION_KEY` | Wallet encryption key |
| `JWT_SECRET` | JWT signing secret |
