# Web Login Integration

## Overview

The React web application uses Google OAuth + Passkey authentication flow.

## Authentication Flow

```
1. User clicks "Sign in with Google"
   ↓
2. Redirected to Google OAuth consent screen
   ↓
3. User approves Google login
   ↓
4. Redirected back to web app with code
   ↓
5. App exchanges code for intermediate token
   ↓
6. Passkey verification modal appears
   ↓
7. User approves passkey (biometric/security key)
   ↓
8. App receives access & refresh tokens
   ↓
9. User is logged in → Dashboard view
```

## Components

### Auth Service (`web/src/services/auth.ts`)
- Google OAuth initiation
- OAuth callback handling
- Passkey challenge/verification
- Token management (access, refresh, intermediate)
- User session management
- Logout functionality

### Login Modal (`web/src/components/LoginModal.tsx`)
- Google OAuth button
- Loading and error states
- Redirects to Google for authentication

### Passkey Verification (`web/src/components/PasskeyVerify.tsx`)
- WebAuthn passkey verification
- Auto-initiates after Google OAuth
- Error handling and retry functionality

### Dashboard (`web/src/components/Dashboard.tsx`)
- Balance display with refresh
- Send/Receive modals
- Transaction history

### Onboarding (`web/src/components/Onboarding.tsx`)
- KYC form for new users
- Document upload (CNH, selfie, proof of address)
- Account creation

## Testing

### Prerequisites
1. API server running on `http://localhost:3001`
2. Database running (PostgreSQL via Docker)
3. Google OAuth configured

### Start Services

```bash
# Terminal 1: Start database
docker-compose up -d

# Terminal 2: Start API server
cd api-server
cargo run

# Terminal 3: Start web app
cd web
npm run dev
```

### Test Flow

1. Open `http://localhost:3000`
2. Click "Sign In / Sign Up"
3. Click "Continue with Google"
4. Login with your registered email
5. Complete passkey verification
6. View Dashboard with balance and transactions

## Environment Variables

### Development (`web/.env.development`)

```bash
VITE_API_URL=http://localhost:3001/v1
VITE_OAUTH_REDIRECT_URI=http://localhost:3000/auth/callback
```

### Production (`web/.env.production`)

```bash
VITE_API_URL=https://zoripay.xyz/v1
VITE_OAUTH_REDIRECT_URI=https://zoripay.xyz/auth/callback
```

## File Structure

```
web/src/
├── App.tsx                    # Main app with auth flow
├── services/
│   ├── auth.ts               # Authentication service
│   ├── balance.ts            # Balance API
│   ├── send.ts               # Send transactions
│   ├── receive.ts            # Receive address
│   └── transactions.ts       # Transaction history
├── components/
│   ├── LoginModal.tsx        # Google OAuth login
│   ├── PasskeyVerify.tsx     # Passkey verification
│   ├── Dashboard.tsx         # Main wallet view
│   ├── SendModal.tsx         # Send crypto
│   ├── ReceiveModal.tsx      # Receive/QR code
│   ├── Onboarding.tsx        # KYC flow
│   └── Navbar.tsx            # Navigation
└── translations.ts           # i18n (6 languages)
```

## Current Status

### Working
- ✅ Google OAuth login
- ✅ OAuth callback handling
- ✅ Passkey verification
- ✅ Session persistence (localStorage)
- ✅ Logout
- ✅ Dashboard with balances
- ✅ Send transactions (POL + ERC20)
- ✅ Receive with QR code
- ✅ Transaction history
- ✅ KYC onboarding (Brazilian accounts)
- ✅ Cloudflare Pages deployment

### Not Yet Implemented
- ❌ Passkey registration UI (new devices)
- ❌ Token auto-refresh on 401
- ❌ My Account page

## Troubleshooting

### "No intermediate token available"
- OAuth callback didn't complete
- Check API server logs
- Verify redirect_uri matches exactly

### Passkey verification fails
- No passkey registered for user
- User needs to complete onboarding first

### Not redirected after Google login
- Check Google Console callback URL
- Must include: `http://localhost:3000/auth/callback`

### Balance not showing
- Check API server is running on port 3001
- Check browser console for errors
- Verify JWT token in localStorage

---

**Last updated**: 2026-02-03
