# Zori.pay API Documentation

OpenAPI 3.1.0 specifications for all Zori.pay APIs.

## API Files

| File | Description | Endpoints |
|------|-------------|-----------|
| [auth.yaml](auth.yaml) | Authentication (Google OAuth + Passkey) | 6 |
| [balance.yaml](balance.yaml) | Wallet balance retrieval | 1 |
| [receive.yaml](receive.yaml) | Receive address for deposits | 1 |
| [send.yaml](send.yaml) | Send transactions and fee estimation | 2 |
| [transactions.yaml](transactions.yaml) | Transaction history | 1 |
| [kyc.yaml](kyc.yaml) | KYC and account opening | 1 |

## All Endpoints

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/v1/auth/google` | Initiate Google OAuth |
| POST | `/v1/auth/google/callback` | Exchange code for intermediate token |
| POST | `/v1/auth/passkey/challenge` | Request passkey challenge |
| POST | `/v1/auth/passkey/verify` | Verify passkey, get access token |
| POST | `/v1/auth/refresh` | Refresh access token |
| POST | `/v1/auth/logout` | Invalidate session |

### Wallet Operations

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/v1/balance` | Get all token balances |
| GET | `/v1/receive` | Get deposit address |
| POST | `/v1/send` | Send cryptocurrency |
| POST | `/v1/send/estimate` | Estimate gas fees |
| GET | `/v1/transactions` | Get transaction history |

### Account Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/v1/kyc/open-account-br` | Open Brazilian account (KYC) |

## Base URLs

| Environment | URL |
|-------------|-----|
| Development | `http://localhost:3001/v1` |
| Production | `https://zoripay.xyz/v1` (via Cloudflare Tunnel) |

**Note**: The production URL routes through Cloudflare Tunnel to the local API server.

## Authentication Flow

```
1. POST /v1/auth/google
   → Returns Google OAuth URL

2. User authenticates with Google
   → Redirected back with authorization code

3. POST /v1/auth/google/callback
   → Returns intermediate_token + user info

4. POST /v1/auth/passkey/challenge
   → Returns WebAuthn challenge

5. User signs challenge with passkey

6. POST /v1/auth/passkey/verify
   → Returns access_token + refresh_token
```

## Using Access Tokens

Include the Bearer token in the `Authorization` header:

```
Authorization: Bearer <access_token>
```

### Token Expiry

| Token Type | Expiry |
|------------|--------|
| Access Token | 1 hour |
| Refresh Token | 7 days |
| Intermediate Token | 5 minutes |

## Supported Currencies

| Code | Name | Type | Decimals | Contract |
|------|------|------|----------|----------|
| POL | Polygon | Native | 18 | - |
| USDC | USD Coin | ERC20 | 6 | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` |
| USDT | Tether | ERC20 | 6 | `0xc2132D05D31c914a87C6611C10748AEb04B58e8F` |
| BRL1 | Zori Real | ERC20 | 18 | (pending deployment) |

## Blockchain

Currently supports **Polygon Mainnet** only.

| Property | Value |
|----------|-------|
| Chain ID | 137 |
| Block Explorer | https://polygonscan.com |
| RPC | Alchemy Polygon Mainnet |

## Error Responses

All endpoints return errors in this format:

```json
{
  "error": "Error message description"
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| `200` | Success |
| `400` | Validation error (invalid input) |
| `401` | Unauthorized (missing or invalid token) |
| `404` | Resource not found |
| `409` | Conflict (duplicate resource, e.g., CPF already registered) |
| `413` | Payload too large (file upload > 10MB) |
| `500` | Internal server error |

### Common Error Examples

```json
// 400 - Invalid address
{"error": "Invalid destination address"}

// 400 - Insufficient balance
{"error": "Insufficient USDC balance"}

// 400 - Insufficient gas
{"error": "Insufficient POL for gas fees. You need at least 0.01 POL to pay for transaction fees."}

// 401 - Invalid token
{"error": "Invalid token"}

// 409 - Duplicate
{"error": "CPF already exists"}
```

## Request Examples

### Get Balances

```bash
curl -X GET "http://localhost:3001/v1/balance" \
  -H "Authorization: Bearer <access_token>"
```

### Send Transaction

```bash
curl -X POST "http://localhost:3001/v1/send" \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "to_address": "0xF766EDB5E3bEbC44098E2C6D06675e7Ba50C28c9",
    "amount": "10.5",
    "currency_code": "USDC"
  }'
```

### Estimate Transaction

```bash
curl -X POST "http://localhost:3001/v1/send/estimate" \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "to_address": "0xF766EDB5E3bEbC44098E2C6D06675e7Ba50C28c9",
    "amount": "0",
    "currency_code": "POL"
  }'
```

## Rate Limits

Rate limits are not currently enforced but may be added in the future.

## Contact

- **Author**: Carlos Augusto Leite Netto
- **Email**: carlos.netto@gmail.com
