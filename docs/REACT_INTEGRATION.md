# React Integration Guide

## Architecture

### Development

```
┌─────────────────────────────────────────────────────────────┐
│  Browser (http://localhost:8080)                            │
│                                                             │
│  React App                                                  │
│  ├── Pages & Components                                     │
│  └── API calls to /v1/*                                     │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Vite Dev Server (localhost:8080)                           │
│                                                             │
│  ├── Serves React app on /                                  │
│  ├── Hot module replacement                                 │
│  └── PROXIES /v1/* requests to localhost:3001  ◀── KEY!    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Rust API Server (localhost:3001)                           │
│                                                             │
│  ├── /v1/auth/*         Authentication                      │
│  ├── /v1/balance        Wallet balances                     │
│  ├── /v1/send           Send transactions                   │
│  ├── /v1/receive        Receive address                     │
│  ├── /v1/transactions   Transaction history                 │
│  └── /v1/kyc/*          KYC onboarding                      │
└─────────────────────────────────────────────────────────────┘
```

### Production (Cloudflare)

```
┌─────────────────────────────────────────────────────────────┐
│  Cloudflare Pages (https://zoripay.xyz)                     │
│                                                             │
│  ├── Serves static React build                              │
│  └── Routes /v1/* through Cloudflare Tunnel                 │
└────────────────────────┬────────────────────────────────────┘
                         │ Cloudflare Tunnel
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  Your Laptop                                                │
│                                                             │
│  Rust API Server (localhost:3001)                           │
└─────────────────────────────────────────────────────────────┘
```

## Vite Proxy Configuration

The key to development is Vite's proxy feature in `vite.config.ts`:

```typescript
export default defineConfig({
  server: {
    port: 8080,
    proxy: {
      '/v1': {
        target: 'http://localhost:3001',
        changeOrigin: true,
      }
    }
  }
});
```

This means:
- React app runs on `http://localhost:8080`
- API calls to `/v1/*` are proxied to `http://localhost:3001`
- No CORS issues in development
- Same-origin cookies work

## Quick Start

### 1. Start API Server

```bash
cd api-server
cargo run
# Runs on http://localhost:3001
```

### 2. Start Web Dev Server

```bash
cd web
npm run dev
# Runs on http://localhost:8080
# Proxies /v1/* to localhost:3001
```

### 3. Open Browser

```
http://localhost:8080
```

## API Calls in React

Services use relative paths (no hardcoded URLs):

```typescript
// web/src/services/balance.ts
const response = await axios.get('/v1/balance', {
  headers: { Authorization: `Bearer ${token}` }
});
```

In development, Vite proxies `/v1/balance` → `http://localhost:3001/v1/balance`

In production, the request goes to `https://zoripay.xyz/v1/balance` → Cloudflare Tunnel → localhost:3001

## Google OAuth Callback

The OAuth callback URL is `http://localhost:8080/auth/callback` (development).

**Important**: This is NOT proxied to the API. It's handled by React Router:

```typescript
// App.tsx handles ?code= parameter
useEffect(() => {
  const code = searchParams.get('code');
  if (code) {
    handleOAuthCallback(code);
  }
}, []);
```

## Production Deployment

### 1. Build React App

```bash
cd web
npm run build
# Creates dist/ folder
```

### 2. Deploy to Cloudflare Pages

```bash
npx wrangler pages deploy dist --project-name=zori-pay
```

### 3. Start Cloudflare Tunnel

```bash
cloudflared tunnel run zori-api
```

This routes `https://zoripay.xyz/v1/*` to your local API server.

### 4. Start API Server

```bash
cd api-server
cargo run
```

## Environment Files

### Development (`web/.env.development`)

```bash
# Not needed - Vite proxy handles API routing
```

### Production (`web/.env.production`)

```bash
VITE_API_URL=https://zoripay.xyz/v1
```

## Google Cloud Console

Add these redirect URIs:

```
http://localhost:8080/auth/callback    # Development (Vite)
https://zoripay.xyz/auth/callback      # Production
```

## Troubleshooting

### API calls fail in development

1. Check API server is running on port 3001
2. Check Vite proxy config in `vite.config.ts`
3. Check browser Network tab for actual request URL

### OAuth callback not working

1. Verify redirect URI in Google Console matches exactly
2. Check React Router handles `/auth/callback` route
3. Check browser console for errors

### CORS errors

In development: Should not happen (Vite proxy)
In production: Check Cloudflare Tunnel is running

---

**Last updated**: 2026-02-03
