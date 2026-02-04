# Google OAuth Callback URLs

> For complete Google Cloud setup instructions, see [GOOGLE_CLOUD_SETUP.md](GOOGLE_CLOUD_SETUP.md)

## Authorized Redirect URIs

These URLs must be configured in [Google Cloud Console](https://console.cloud.google.com/apis/credentials):

### User Login OAuth Client
```
http://localhost:8080/auth/callback      # React dev (Vite on port 8080)
https://zoripay.xyz/auth/callback        # Production
```

### Drive Access OAuth Client
```
http://localhost:8085/callback           # Drive config tool
```

## How to Add/Update

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Click on your OAuth 2.0 Client ID
3. Under "Authorized redirect URIs", add the new URL
4. Click "Save"
5. Wait 5 minutes for propagation

## Authentication Flow

```
1. User clicks "Sign in with Google" on React app (localhost:8080)
   ↓
2. React calls API to get Google auth URL
   - API generates URL with redirect_uri = http://localhost:8080/auth/callback
   ↓
3. Browser redirects to Google OAuth consent screen
   ↓
4. User approves on Google
   ↓
5. Google redirects to: http://localhost:8080/auth/callback?code=xxx&state=yyy
   ↓
6. React app receives callback (App.tsx handles it)
   - Calls API to exchange code for intermediate token
   - Shows passkey verification modal
   ↓
7. User completes passkey verification
   ↓
8. React app receives access/refresh tokens
   ↓
9. User is logged in → Dashboard view
```

## Common Errors

### "redirect_uri_mismatch"

The redirect URI in the request doesn't match any authorized URIs.

**Fix**:
1. Copy the exact URI from the error message
2. Add it to Google Cloud Console
3. Wait a few minutes for propagation
4. Try again

### "disabled_client"

The OAuth client was disabled.

**Fix**: See [GOOGLE_CLOUD_SETUP.md#troubleshooting](GOOGLE_CLOUD_SETUP.md#troubleshooting)

### "access_denied"

User denied consent or app is not verified.

**Fix**:
1. Check OAuth consent screen configuration
2. For testing, add test users in consent screen settings
3. For production, submit for verification

## Environment Variables

### Web Frontend (.env.development)

```bash
VITE_API_URL=http://localhost:3001/v1
VITE_OAUTH_REDIRECT_URI=http://localhost:8080/auth/callback
```

### Web Frontend (.env.production)

```bash
VITE_API_URL=https://zoripay.xyz/v1
VITE_OAUTH_REDIRECT_URI=https://zoripay.xyz/auth/callback
```

### API Server (.env)

```bash
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
```

## Adding New Environments

When deploying to a new domain (e.g., staging):

1. Add the new callback URL to Google Console
2. Create new environment file for frontend
3. Update Cloudflare Tunnel config if needed
4. Deploy and test

---

*Last updated: 2026-02-04*
