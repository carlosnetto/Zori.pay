# Cloudflare Tunnel Setup Guide

> Step-by-step guide for setting up Cloudflare Tunnel to expose the local API server to the internet.

## Table of Contents

1. [Overview](#overview)
2. [Initial Setup (New Machine)](#initial-setup-new-machine)
3. [Migrating to a New Machine](#migrating-to-a-new-machine)
4. [Running the Tunnel](#running-the-tunnel)
5. [Troubleshooting](#troubleshooting)
6. [Common Errors](#common-errors)

---

## Overview

Cloudflare Tunnel (formerly Argo Tunnel) creates a secure connection between your local machine and Cloudflare's network, allowing the production frontend (`zoripay.xyz`) to access the local API server (`localhost:3001`).

```
┌─────────────────────┐      ┌─────────────────────┐      ┌─────────────────────┐
│  Production         │      │  Cloudflare         │      │  Local Machine      │
│  Frontend           │─────▶│  Network            │─────▶│                     │
│  zoripay.xyz        │      │                     │      │  API Server         │
│                     │      │  api.zoripay.xyz    │◀─────│  localhost:3001     │
│                     │      │  (DNS CNAME)        │      │                     │
│                     │      │                     │      │  cloudflared        │
└─────────────────────┘      └─────────────────────┘      └─────────────────────┘
```

### Key Files

| File | Purpose |
|------|---------|
| `~/.cloudflared/config.yml` | Tunnel configuration (hostname, service mapping) |
| `~/.cloudflared/<tunnel-id>.json` | Tunnel credentials (auto-generated) |
| `~/.cloudflared/cert.pem` | Cloudflare account certificate |

---

## Initial Setup (New Machine)

### 1. Install cloudflared

```bash
# macOS
brew install cloudflared

# Or download from https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/
```

### 2. Login to Cloudflare

```bash
cloudflared tunnel login
```

This opens a browser to authenticate with your Cloudflare account. After approval, a certificate is saved to `~/.cloudflared/cert.pem`.

### 3. Create a Tunnel

```bash
cloudflared tunnel create zori-api
```

This creates:
- A tunnel with a unique ID
- A credentials file: `~/.cloudflared/<tunnel-id>.json`

**Save the tunnel ID** - you'll need it for the config file.

### 4. Create Configuration File

```bash
cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: <YOUR-TUNNEL-ID>
credentials-file: /Users/<YOUR-USERNAME>/.cloudflared/<YOUR-TUNNEL-ID>.json

ingress:
  - hostname: api.zoripay.xyz
    service: http://localhost:3001
  - service: http_status:404
EOF
```

Replace:
- `<YOUR-TUNNEL-ID>` with the tunnel ID from step 3
- `<YOUR-USERNAME>` with your macOS username (`whoami`)

### 5. Route DNS

```bash
cloudflared tunnel route dns zori-api api.zoripay.xyz
```

This creates a CNAME record in Cloudflare DNS pointing `api.zoripay.xyz` to your tunnel.

### 6. Run the Tunnel

```bash
cloudflared tunnel run zori-api
```

---

## Migrating to a New Machine

When setting up on a new computer, you need to create a **new tunnel** and **update DNS**.

### 1. Install and Login

```bash
brew install cloudflared
cloudflared tunnel login
```

### 2. Create New Tunnel

```bash
cloudflared tunnel create zori-api
```

Note the new tunnel ID.

### 3. Create config.yml

```bash
# Check your username
whoami

# Create config (replace values)
cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: <NEW-TUNNEL-ID>
credentials-file: /Users/<USERNAME>/.cloudflared/<NEW-TUNNEL-ID>.json

ingress:
  - hostname: api.zoripay.xyz
    service: http://localhost:3001
  - service: http_status:404
EOF
```

### 4. Update DNS (CRITICAL STEP)

The old DNS record points to the old tunnel. You must delete it first:

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Select domain: `zoripay.xyz`
3. Navigate to **DNS** → **Records**
4. Find the `api` CNAME record
5. **Delete it**
6. Run the DNS route command:

```bash
cloudflared tunnel route dns zori-api api.zoripay.xyz
```

> **WARNING**: If you skip deleting the old DNS record, you'll get error 1003:
> `Failed to create record api.zoripay.xyz with err An A, AAAA, or CNAME record with that host already exists.`

### 5. Run the Tunnel

```bash
cloudflared tunnel run zori-api
```

### 6. Verify

```bash
curl https://api.zoripay.xyz/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"redirect_uri":"https://zoripay.xyz/auth/callback"}'
```

---

## Running the Tunnel

### Foreground (for debugging)

```bash
cloudflared tunnel run zori-api
```

### Background

```bash
nohup cloudflared tunnel run zori-api > /tmp/cloudflared.log 2>&1 &
```

### As a Service (recommended for production)

```bash
# Install as service
sudo cloudflared service install

# Start service
sudo launchctl start com.cloudflare.cloudflared

# Check status
sudo launchctl list | grep cloudflared
```

### Using the Start Script

There's a convenience script in the repo:

```bash
./start-tunnel.sh
```

---

## Troubleshooting

### Check Tunnel Status

```bash
# List all tunnels
cloudflared tunnel list

# Get detailed info
cloudflared tunnel info zori-api
```

### Test Connectivity

```bash
# 1. Is API server running?
curl http://localhost:3001/v1/balance
# Expected: 401 Unauthorized (means server is running)

# 2. Is tunnel reaching the server?
curl https://api.zoripay.xyz/v1/balance
# Expected: 401 Unauthorized (means tunnel is working)

# 3. Test with verbose output
curl -v https://api.zoripay.xyz/v1/auth/google \
  -H "Content-Type: application/json" \
  -H "Origin: https://zoripay.xyz" \
  -d '{"redirect_uri":"https://zoripay.xyz/auth/callback"}'
```

### View Tunnel Logs

```bash
# Run with debug logging
cloudflared tunnel --loglevel debug run zori-api
```

---

## Common Errors

### Error 530 / Error Code 1033

**Symptom**: Browser shows "Error 530" or API returns error code 1033

**Cause**: Cloudflare can't reach the tunnel - tunnel is not running

**Fix**:
```bash
cloudflared tunnel run zori-api
```

### Error 1003: DNS Record Already Exists

**Symptom**:
```
Failed to add route: code: 1003, reason: Failed to create record api.zoripay.xyz
with err An A, AAAA, or CNAME record with that host already exists.
```

**Cause**: Old DNS record points to a different tunnel

**Fix**:
1. Go to Cloudflare Dashboard → DNS → Records
2. Delete the existing `api` CNAME record
3. Re-run: `cloudflared tunnel route dns zori-api api.zoripay.xyz`

### CORS Errors in Browser

**Symptom**:
```
Access to XMLHttpRequest at 'https://api.zoripay.xyz/v1/auth/google' from origin
'https://zoripay.xyz' has been blocked by CORS policy
```

**Cause**: Usually means the request isn't reaching the API server at all (tunnel not running)

**Fix**:
1. Verify tunnel is running: `cloudflared tunnel list`
2. Check for connections in the output
3. Start tunnel if needed: `cloudflared tunnel run zori-api`

### Config File Not Found

**Symptom**:
```
Cannot determine default configuration path
```

**Fix**: Create `~/.cloudflared/config.yml` with proper content (see above)

### Credentials File Not Found

**Symptom**:
```
Cannot load tunnel credentials
```

**Fix**: Verify the credentials file exists:
```bash
ls -la ~/.cloudflared/*.json
```

If missing, create a new tunnel: `cloudflared tunnel create zori-api`

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `cloudflared tunnel login` | Authenticate with Cloudflare |
| `cloudflared tunnel create <name>` | Create new tunnel |
| `cloudflared tunnel list` | List all tunnels |
| `cloudflared tunnel info <name>` | Get tunnel details |
| `cloudflared tunnel route dns <name> <hostname>` | Create DNS record |
| `cloudflared tunnel run <name>` | Start the tunnel |
| `cloudflared tunnel delete <name>` | Delete a tunnel |

---

## Checklist for New Machine Setup

- [ ] Install cloudflared (`brew install cloudflared`)
- [ ] Login to Cloudflare (`cloudflared tunnel login`)
- [ ] Create tunnel (`cloudflared tunnel create zori-api`)
- [ ] Note the tunnel ID
- [ ] Create `~/.cloudflared/config.yml` with correct tunnel ID and username
- [ ] **Delete old DNS record** in Cloudflare Dashboard
- [ ] Route DNS (`cloudflared tunnel route dns zori-api api.zoripay.xyz`)
- [ ] Start tunnel (`cloudflared tunnel run zori-api`)
- [ ] Verify with curl or browser

---

*Last updated: 2026-02-04*
