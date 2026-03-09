#!/bin/bash
# Restores secrets from a migration package ZIP
#
# Usage: ./scripts/restore-migration-package.sh <path-to-zip>
#
# Run this from the project root directory

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-migration-zip>"
    echo "Example: $0 ~/Downloads/zori-secrets-20260204_120000.zip"
    exit 1
fi

ZIP_FILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEMP_DIR=$(mktemp -d)

echo "🔐 Restoring Zori.pay Migration Package"
echo "========================================"
echo ""

if [ ! -f "$ZIP_FILE" ]; then
    echo "❌ File not found: $ZIP_FILE"
    exit 1
fi

# Extract to temp
echo "📦 Extracting package..."
unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

# Restore files
echo "📁 Restoring files..."

# API server .env
if [ -f "$TEMP_DIR/api-server/.env" ]; then
    mkdir -p "$PROJECT_ROOT/api-server"
    cp "$TEMP_DIR/api-server/.env" "$PROJECT_ROOT/api-server/"
    echo "   ✓ api-server/.env"
fi

# API server secrets
if [ -d "$TEMP_DIR/api-server/secrets" ]; then
    mkdir -p "$PROJECT_ROOT/api-server/secrets"
    cp -r "$TEMP_DIR/api-server/secrets/"* "$PROJECT_ROOT/api-server/secrets/"
    echo "   ✓ api-server/secrets/"
fi

# Cloudflare Tunnel config
if [ -d "$TEMP_DIR/.cloudflared" ] && ls "$TEMP_DIR/.cloudflared/"* &>/dev/null; then
    mkdir -p "$HOME/.cloudflared"
    cp -r "$TEMP_DIR/.cloudflared/"* "$HOME/.cloudflared/"
    echo "   ✓ .cloudflared/ -> ~/.cloudflared/"
    # Update credentials-file path if username differs
    if [ -f "$HOME/.cloudflared/config.yml" ]; then
        OLD_PATH=$(grep 'credentials-file' "$HOME/.cloudflared/config.yml" | awk '{print $2}')
        if [ -n "$OLD_PATH" ] && [ ! -f "$OLD_PATH" ]; then
            CRED_FILE=$(ls "$HOME/.cloudflared/"*.json 2>/dev/null | grep -v cert | head -1)
            if [ -n "$CRED_FILE" ]; then
                sed -i.bak "s|credentials-file:.*|credentials-file: $CRED_FILE|" "$HOME/.cloudflared/config.yml"
                rm -f "$HOME/.cloudflared/config.yml.bak"
                echo "   ✓ Updated credentials-file path in config.yml"
            fi
        fi
    fi
else
    echo "   ⊘ .cloudflared/ (not in package, skipping)"
fi

# Root credentials
if [ -d "$TEMP_DIR/.credentials" ] && ls "$TEMP_DIR/.credentials/"* &>/dev/null; then
    mkdir -p "$PROJECT_ROOT/.credentials"
    cp -r "$TEMP_DIR/.credentials/"* "$PROJECT_ROOT/.credentials/"
    echo "   ✓ .credentials/"
else
    echo "   ⊘ .credentials/ (not in package, skipping)"
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Migration package restored!"
echo ""
echo "📋 NEXT STEPS:"
echo "   1. Start services:"
echo "      - Database: docker-compose up -d"
echo "      - API: cd api-server && cargo run"
echo "      - Tunnel: cloudflared tunnel run zori-api"
echo "      - Frontend: cd web && npm run dev"
echo ""
echo "   2. Test Google Drive (if token expired):"
echo "      cd api-server && cargo run --bin drive_config"
echo ""
echo "   3. If tunnel doesn't work, see docs/CLOUDFLARE_TUNNEL_SETUP.md"
echo ""
echo "⚠️  Delete the ZIP file now for security:"
echo "   rm $ZIP_FILE"
echo ""
