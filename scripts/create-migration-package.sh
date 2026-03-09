#!/bin/bash
# Creates a ZIP package with all secrets for migrating to a new machine
#
# Usage: ./scripts/create-migration-package.sh
#
# WARNING: This ZIP contains sensitive credentials.
# Transfer securely and delete after use.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PACKAGE_NAME="zori-secrets-${TIMESTAMP}.zip"
TEMP_DIR=$(mktemp -d)

echo "🔐 Creating Zori.pay Migration Package"
echo "======================================="
echo ""

# Create directory structure in temp
mkdir -p "$TEMP_DIR/api-server/secrets"

# Copy files
echo "📁 Collecting files..."

# API server .env
if [ -f "$PROJECT_ROOT/api-server/.env" ]; then
    cp "$PROJECT_ROOT/api-server/.env" "$TEMP_DIR/api-server/"
    echo "   ✓ api-server/.env"
else
    echo "   ✗ api-server/.env (not found)"
fi

# API server secrets
if [ -d "$PROJECT_ROOT/api-server/secrets" ]; then
    cp -r "$PROJECT_ROOT/api-server/secrets/"* "$TEMP_DIR/api-server/secrets/" 2>/dev/null || true
    echo "   ✓ api-server/secrets/"
else
    echo "   ✗ api-server/secrets/ (not found)"
fi

# Cloudflare Tunnel config
if [ -d "$HOME/.cloudflared" ] && ls "$HOME/.cloudflared/"* &>/dev/null; then
    mkdir -p "$TEMP_DIR/.cloudflared"
    cp "$HOME/.cloudflared/"*.json "$TEMP_DIR/.cloudflared/" 2>/dev/null || true
    cp "$HOME/.cloudflared/"*.pem "$TEMP_DIR/.cloudflared/" 2>/dev/null || true
    cp "$HOME/.cloudflared/"*.yml "$TEMP_DIR/.cloudflared/" 2>/dev/null || true
    echo "   ✓ .cloudflared/ (tunnel config, credentials, cert)"
else
    echo "   ⊘ .cloudflared/ (not found, skipping)"
fi

# Root credentials
if [ -d "$PROJECT_ROOT/.credentials" ] && ls "$PROJECT_ROOT/.credentials/"* &>/dev/null; then
    mkdir -p "$TEMP_DIR/.credentials"
    cp -r "$PROJECT_ROOT/.credentials/"* "$TEMP_DIR/.credentials/"
    echo "   ✓ .credentials/"
else
    echo "   ⊘ .credentials/ (empty or not found, skipping)"
fi

# Create README for the package
cat > "$TEMP_DIR/README.txt" << 'EOF'
ZORI.PAY MIGRATION PACKAGE
==========================

This package contains sensitive credentials for Zori.pay.

TO RESTORE ON NEW MACHINE:
1. Clone the Zori.pay repository
2. Unzip this package
3. Copy files to their locations:
   - api-server/.env -> <project>/api-server/.env
   - api-server/secrets/* -> <project>/api-server/secrets/
   - .credentials/* -> <project>/.credentials/
   - .cloudflared/* -> ~/.cloudflared/

NOTE ON CLOUDFLARE TUNNEL:
- If .cloudflared/ was included, the tunnel config is ready to use.
  You may need to update the credentials-file path in config.yml
  to match the new machine's username.
- If .cloudflared/ was NOT included, see docs/CLOUDFLARE_TUNNEL_SETUP.md
- Google Drive token may need refresh: cargo run --bin drive_config

SECURITY:
- Delete this ZIP after extraction
- Never commit these files to git
- Never share via unencrypted channels

EOF

# Create the ZIP
echo ""
echo "📦 Creating ZIP package..."
cd "$TEMP_DIR"
zip -r "$PROJECT_ROOT/$PACKAGE_NAME" .
cd "$PROJECT_ROOT"

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Migration package created: $PACKAGE_NAME"
echo ""
echo "⚠️  SECURITY REMINDERS:"
echo "   - Transfer this file securely (AirDrop, encrypted USB, etc.)"
echo "   - Delete after extracting on the new machine"
echo "   - Never commit to git or share via email/Slack"
echo ""
echo "📖 On the new machine:"
echo "   - Update credentials-file path in ~/.cloudflared/config.yml if username differs"
echo "   - docs/GOOGLE_CLOUD_SETUP.md (if tokens expired)"
echo ""
