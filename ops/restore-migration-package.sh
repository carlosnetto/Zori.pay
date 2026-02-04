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

# Root credentials
if [ -d "$TEMP_DIR/.credentials" ]; then
    mkdir -p "$PROJECT_ROOT/.credentials"
    cp -r "$TEMP_DIR/.credentials/"* "$PROJECT_ROOT/.credentials/"
    echo "   ✓ .credentials/"
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✅ Migration package restored!"
echo ""
echo "📋 NEXT STEPS:"
echo "   1. Set up Cloudflare Tunnel (see docs/CLOUDFLARE_TUNNEL_SETUP.md)"
echo "      - Create new tunnel: cloudflared tunnel create zori-api"
echo "      - Create ~/.cloudflared/config.yml"
echo "      - Delete old DNS record in Cloudflare Dashboard"
echo "      - Route DNS: cloudflared tunnel route dns zori-api api.zoripay.xyz"
echo ""
echo "   2. Start services:"
echo "      - Database: docker-compose up -d"
echo "      - API: cd api-server && cargo run"
echo "      - Tunnel: cloudflared tunnel run zori-api"
echo "      - Frontend: cd web && npm run dev"
echo ""
echo "   3. Test Google Drive (if token expired):"
echo "      cd api-server && cargo run --bin drive_config"
echo ""
echo "⚠️  Delete the ZIP file now for security:"
echo "   rm $ZIP_FILE"
echo ""
