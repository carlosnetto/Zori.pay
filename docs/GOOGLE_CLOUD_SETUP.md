# Google Cloud Setup Guide

> Complete step-by-step guide for setting up Google Cloud services for Zori.pay.
> This is a manual process that must be done through the Google Cloud Console.

## Table of Contents

1. [Overview](#overview)
2. [Create Google Cloud Project](#1-create-google-cloud-project)
3. [Enable Required APIs](#2-enable-required-apis)
4. [Configure OAuth Consent Screen](#3-configure-oauth-consent-screen)
5. [Create OAuth Credentials](#4-create-oauth-credentials)
6. [Set Up Google Drive Folder](#5-set-up-google-drive-folder)
7. [Update Codebase Configuration](#6-update-codebase-configuration)
8. [Authorize Drive Access](#7-authorize-drive-access)
9. [Testing](#8-testing)
10. [Troubleshooting](#troubleshooting)
11. [Maintenance](#maintenance)

---

## Overview

Zori.pay requires two separate OAuth 2.0 clients:

| Client | Purpose | Used By |
|--------|---------|---------|
| **User Login OAuth** | Google Sign-In for users | Frontend + API auth endpoints |
| **Drive Access OAuth** | Upload KYC documents to Google Drive | API server (`google_drive.rs`) |

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     GOOGLE CLOUD PROJECT                         │
│                                                                   │
│  ┌─────────────────────┐      ┌─────────────────────┐           │
│  │ OAuth Client A      │      │ OAuth Client B      │           │
│  │ "User Login"        │      │ "Drive Access"      │           │
│  │                     │      │                     │           │
│  │ Scopes:             │      │ Scopes:             │           │
│  │ - email             │      │ - drive.file        │           │
│  │ - profile           │      │                     │           │
│  │ - openid            │      │                     │           │
│  └─────────────────────┘      └─────────────────────┘           │
│                                        │                         │
│                                        ▼                         │
│                               ┌─────────────────────┐           │
│                               │ Google Drive        │           │
│                               │                     │           │
│                               │ DOC_DB/             │           │
│                               │   └── {CPF}/        │           │
│                               │       ├── cnh.jpg   │           │
│                               │       └── selfie.jpg│           │
│                               └─────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click the project dropdown at the top
3. Click **"New Project"**
4. Enter project details:
   - **Project name**: `Zori Pay` (or your preferred name)
   - **Organization**: Leave as default or select your organization
5. Click **"Create"**
6. Wait for project creation (takes a few seconds)
7. Select the new project from the dropdown

**Save these values** (found in project settings):
- Project ID: `_______________`
- Project Number: `_______________`

---

## 2. Enable Required APIs

Navigate to **APIs & Services > Library**

Search for and **enable** each of these APIs:

| API | Purpose |
|-----|---------|
| **Google Drive API** | Upload/manage KYC documents |
| **Google Identity Services API** | User authentication (optional but recommended) |

To enable an API:
1. Click on the API name
2. Click **"Enable"**
3. Wait for activation

---

## 3. Configure OAuth Consent Screen

Navigate to **APIs & Services > OAuth consent screen**

### Step 3.1: Choose User Type

Select **"External"** and click **"Create"**

> **Note**: "Internal" is only for Google Workspace organizations. External allows any Google account to sign in.

### Step 3.2: App Information

Fill in the following:

| Field | Value |
|-------|-------|
| App name | `Zori Pay` |
| User support email | Your email |
| App logo | (optional) Upload your logo |

### Step 3.3: App Domain (Optional for testing)

| Field | Value |
|-------|-------|
| Application home page | `https://zoripay.xyz` |
| Privacy policy | (optional) |
| Terms of service | (optional) |

### Step 3.4: Authorized Domains

Add:
```
zoripay.xyz
```

### Step 3.5: Developer Contact Information

Enter your email address.

Click **"Save and Continue"**

### Step 3.6: Scopes

Click **"Add or Remove Scopes"**

Add these scopes:

| Scope | Description |
|-------|-------------|
| `email` | View email address |
| `profile` | View basic profile info |
| `openid` | OpenID Connect |
| `https://www.googleapis.com/auth/drive.file` | Access Drive files created by app |

Click **"Update"** then **"Save and Continue"**

### Step 3.7: Test Users

While in testing mode, only added test users can sign in.

Click **"Add Users"** and add:
- Your email address
- Any other test accounts

Click **"Save and Continue"**

### Step 3.8: Summary

Review and click **"Back to Dashboard"**

---

## 4. Create OAuth Credentials

Navigate to **APIs & Services > Credentials**

### 4.1: Create User Login OAuth Client

Click **"Create Credentials" > "OAuth client ID"**

| Field | Value |
|-------|-------|
| Application type | **Web application** |
| Name | `Zori User Login` |

**Authorized JavaScript origins**:
```
http://localhost:8080
https://zoripay.xyz
```

**Authorized redirect URIs**:
```
http://localhost:8080/auth/callback
https://zoripay.xyz/auth/callback
```

Click **"Create"**

**Save these values:**
- Client ID: `_______________`
- Client Secret: `_______________`

### 4.2: Create Drive Access OAuth Client

Click **"Create Credentials" > "OAuth client ID"** again

| Field | Value |
|-------|-------|
| Application type | **Web application** |
| Name | `Zori Drive Access` |

**Authorized redirect URIs**:
```
http://localhost:8085/callback
```

Click **"Create"**

**Save these values:**
- Client ID: `_______________`
- Client Secret: `_______________`

---

## 5. Set Up Google Drive Folder

1. Go to [Google Drive](https://drive.google.com/)
2. Create a new folder named `DOC_DB` (or similar)
3. Open the folder
4. Copy the folder ID from the URL:
   ```
   https://drive.google.com/drive/folders/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                          This is the folder ID
   ```

**Save this value:**
- Drive Root Folder ID: `_______________`

---

## 6. Update Codebase Configuration

### 6.1: User Login Credentials

Create/update `.credentials/google_client_id`:
```
YOUR_USER_LOGIN_CLIENT_ID.apps.googleusercontent.com
```

Create/update `.credentials/google_client_secret`:
```
YOUR_USER_LOGIN_CLIENT_SECRET
```

### 6.2: API Server Environment

Update `api-server/.env`:
```bash
# Google OAuth (User Login)
GOOGLE_CLIENT_ID=YOUR_USER_LOGIN_CLIENT_ID.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=YOUR_USER_LOGIN_CLIENT_SECRET

# Google Drive
GOOGLE_DRIVE_ROOT_FOLDER_ID=YOUR_DRIVE_FOLDER_ID
```

### 6.3: Drive Config Tool

Check `api-server/src/bin/drive_config.rs` and update the client ID if hardcoded:
```rust
const CLIENT_ID: &str = "YOUR_DRIVE_ACCESS_CLIENT_ID.apps.googleusercontent.com";
const CLIENT_SECRET: &str = "YOUR_DRIVE_ACCESS_CLIENT_SECRET";
```

---

## 7. Authorize Drive Access

The Drive OAuth requires a one-time authorization to get refresh tokens.

### Run the Drive Configuration Tool

```bash
cd api-server
cargo run --bin drive_config
```

### What Happens

1. Terminal shows: `Open this URL in your browser: https://accounts.google.com/o/oauth2/...`
2. Browser opens Google consent screen
3. Sign in with your Google account (must have access to the Drive folder)
4. Grant permission: "See, edit, create, and delete only the specific Google Drive files you use with this app"
5. Browser redirects to `localhost:8085/callback`
6. Terminal shows: `Authorization successful! Token saved.`

### Token Storage

Tokens are saved to: `api-server/secrets/google-drive-token.json`

```json
{
  "access_token": "ya29.xxx...",
  "refresh_token": "1//xxx...",
  "token_type": "Bearer",
  "expires_at": 1234567890
}
```

> **Important**: The `refresh_token` is only provided on the first authorization. If you need a new refresh token, you must revoke access and re-authorize.

---

## 8. Testing

### Test User Login

1. Start the frontend: `cd web && npm run dev`
2. Open `http://localhost:8080`
3. Click "Sign in with Google"
4. Should redirect to Google consent
5. After approval, should redirect back to app

### Test Drive Upload

1. Start the API server: `cd api-server && cargo run`
2. Use the KYC endpoint to upload a test document
3. Check Google Drive for the uploaded file

---

## Troubleshooting

### Error: `disabled_client`

**Cause**: OAuth client was disabled in Google Cloud Console

**Fix**:
1. Go to APIs & Services > Credentials
2. Find the disabled client
3. Re-enable it, or create a new one

### Error: `redirect_uri_mismatch`

**Cause**: The redirect URI doesn't match any configured URIs

**Fix**:
1. Copy the exact URI from the error message
2. Add it to the OAuth client's authorized redirect URIs
3. Wait 5 minutes for propagation
4. Try again

### Error: `access_denied`

**Cause**: User denied consent, or app is not verified, or user is not a test user

**Fix**:
1. Check OAuth consent screen settings
2. Add user to test users list (while in testing mode)
3. For production, submit app for verification

### Error: `invalid_grant` (Drive)

**Cause**: Refresh token expired or was revoked

**Fix**:
1. Delete `api-server/secrets/google-drive-token.json`
2. Run `cargo run --bin drive_config` again
3. Re-authorize

### Error: `Token has been expired or revoked`

**Cause**: Access token expired and refresh failed

**Fix**:
1. Check that refresh token exists in token file
2. Delete token file and re-authorize
3. Check that OAuth client still exists in Google Console

### Drive uploads fail but no error

**Cause**: User doesn't have access to the Drive folder

**Fix**:
1. Share the Drive folder with the Google account used for authorization
2. Re-authorize with an account that owns the folder

---

## Maintenance

### Refresh Token Expiration

Refresh tokens can expire if:
- Not used for 6 months
- User revokes access
- OAuth client is deleted/recreated
- Password changed (for some account types)

**To renew**: Delete token file and re-run `drive_config`

### Publishing the App

While in "Testing" mode:
- Only test users can sign in
- Refresh tokens expire after 7 days

To remove these restrictions:
1. Go to OAuth consent screen
2. Click "Publish App"
3. For sensitive scopes (like Drive), submit for verification

### Rotating Credentials

If you need to rotate OAuth client secrets:

1. Create a new client (don't delete old one yet)
2. Update all configuration files
3. Deploy and test
4. Delete old client
5. Re-authorize Drive access

### Checking Token Status

To verify Drive token is working:
```bash
cd api-server
# Add a test endpoint or use curl with the token
```

---

## Checklist

Use this checklist when setting up a new environment:

- [ ] Created Google Cloud project
- [ ] Enabled Google Drive API
- [ ] Configured OAuth consent screen (External)
- [ ] Added required scopes (email, profile, openid, drive.file)
- [ ] Added test users
- [ ] Created User Login OAuth client
- [ ] Created Drive Access OAuth client
- [ ] Created Drive folder for documents
- [ ] Updated `.credentials/google_client_id`
- [ ] Updated `.credentials/google_client_secret`
- [ ] Updated `api-server/.env` with all Google config
- [ ] Updated `drive_config.rs` with Drive OAuth credentials (if hardcoded)
- [ ] Ran `drive_config` and authorized Drive access
- [ ] Tested user login flow
- [ ] Tested document upload

---

## Reference: All Configuration Locations

| File | Contains |
|------|----------|
| `.credentials/google_client_id` | User Login OAuth Client ID |
| `.credentials/google_client_secret` | User Login OAuth Client Secret |
| `api-server/.env` | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_DRIVE_ROOT_FOLDER_ID` |
| `api-server/src/bin/drive_config.rs` | Drive OAuth Client ID & Secret (may be hardcoded) |
| `api-server/secrets/google-drive-token.json` | Drive access/refresh tokens (auto-generated) |

---

*Last updated: 2026-02-04*
