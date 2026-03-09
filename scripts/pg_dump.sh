#!/bin/bash

# PostgreSQL database dump script
# Uses pg_dump inside the Docker container

# Configuration
CONTAINER="global_banking_db"
DB_NAME="banking_system"
DB_USER="admin"

# Output directory with timestamp
TIMESTAMP=$(date +%Y%m%d%H%M)
OUTPUT_DIR="./${TIMESTAMP}-pg_backup"
OUTPUT_FILE="${OUTPUT_DIR}/${DB_NAME}.sql"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "🗄️  Dumping PostgreSQL database: $DB_NAME"
echo "📂 Output: $OUTPUT_FILE"

# Run pg_dump inside the container
docker exec "$CONTAINER" pg_dump -U "$DB_USER" -d "$DB_NAME" --no-owner --no-acl > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    echo "✅ Dump complete! Size: $SIZE"
else
    echo "❌ Dump failed!"
    exit 1
fi
