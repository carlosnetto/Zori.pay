import os
import uuid
import pandas as pd
from sqlalchemy import create_engine, inspect
from datetime import datetime

# ================= CONFIGURATION =================
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "banking_system"
DB_USER = "admin"
DB_PASS = "mysecretpassword"

# Schemas to export (your database uses these instead of 'public')
SCHEMAS = ["registration_schema", "accounts_schema", "audit_schema"]

# Output directory for the backup
BACKUP_DIR = f"./{datetime.now().strftime('%Y%m%d%H%M')}-parquet_backup"
# =================================================

def export_database():
    # 1. Create the connection string
    # We use postgresql+psycopg2 for the driver
    db_url = f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    
    try:
        engine = create_engine(db_url)
        connection = engine.connect()
        print(f"✅ Connected to database: {DB_NAME}")
    except Exception as e:
        print(f"❌ Failed to connect: {e}")
        return

    # 2. Create backup folder
    if not os.path.exists(BACKUP_DIR):
        os.makedirs(BACKUP_DIR)
        print(f"📂 Created backup directory: {BACKUP_DIR}")

    # 3. Inspect the database to get all table names from all schemas
    inspector = inspect(engine)

    total_tables = 0
    for schema in SCHEMAS:
        tables = inspector.get_table_names(schema=schema)
        total_tables += len(tables)

    print(f"🔍 Found {total_tables} tables across {len(SCHEMAS)} schemas to export.")

    # 4. Loop through schemas and tables, then export
    for schema in SCHEMAS:
        tables = inspector.get_table_names(schema=schema)
        print(f"\n📁 Schema: {schema} ({len(tables)} tables)")

        for table in tables:
            try:
                print(f"   ➡ Exporting {schema}.{table}...", end=" ")

                # Read SQL table into Pandas DataFrame
                df = pd.read_sql_table(table, engine, schema=schema)

                # Convert UUID columns to strings (Parquet doesn't support UUID natively)
                for col in df.columns:
                    if df[col].dtype == 'object' and not df[col].dropna().empty:
                        first_val = df[col].dropna().iloc[0]
                        if isinstance(first_val, uuid.UUID):
                            df[col] = df[col].apply(lambda x: str(x) if x is not None else None)

                # Define output file path (prefix with schema name to avoid conflicts)
                output_file = os.path.join(BACKUP_DIR, f"{schema}.{table}.parquet")

                # Write to Parquet (using pyarrow engine and snappy compression)
                df.to_parquet(output_file, engine='pyarrow', compression='snappy')

                print(f"Done! ({len(df)} rows)")

            except Exception as e:
                print(f"\n❌ Error exporting {schema}.{table}: {e}")

    print("\n✨ All exports finished.")
    connection.close()

if __name__ == "__main__":
    export_database()
