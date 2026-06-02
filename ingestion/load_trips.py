import requests
import tempfile
import os
import pandas as pd
import snowflake.connector
from snowflake.connector.pandas_tools import write_pandas
from pathlib import Path
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend

# --- Config ---
SNOWFLAKE_ACCOUNT = "yg09383.us-east-2.aws"
SNOWFLAKE_USER = "dbt_user"
SNOWFLAKE_PRIVATE_KEY_PATH = str(Path.home() / ".ssh" / "snowflake_dbt_key.p8")
SNOWFLAKE_ROLE = "dbt_role"
SNOWFLAKE_WAREHOUSE = "dbt_wh"
SNOWFLAKE_DATABASE = "nyc_taxi"
SNOWFLAKE_SCHEMA = "raw"

MONTHS = [
    (2024, 1), (2024, 2), (2024, 3), (2024, 4),
    (2024, 5), (2024, 6), (2024, 7), (2024, 8),
    (2024, 9), (2024, 10), (2024, 11), (2024, 12),
    (2023, 1), (2023, 2), (2023, 3), (2023, 4),
    (2023, 5), (2023, 6),
]

BASE_URL = "https://d37ci6vzurychx.cloudfront.net/trip-data"


def get_private_key():
    with open(SNOWFLAKE_PRIVATE_KEY_PATH, "rb") as f:
        private_key = serialization.load_pem_private_key(
            f.read(),
            password=None,
            backend=default_backend()
        )
    return private_key.private_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )


def get_connection():
    return snowflake.connector.connect(
        account=SNOWFLAKE_ACCOUNT,
        user=SNOWFLAKE_USER,
        private_key=get_private_key(),
        role=SNOWFLAKE_ROLE,
        warehouse=SNOWFLAKE_WAREHOUSE,
        database=SNOWFLAKE_DATABASE,
        schema=SNOWFLAKE_SCHEMA,
    )


def download_file(year: int, month: int, dest_path: str):
    url = f"{BASE_URL}/yellow_tripdata_{year}-{month:02d}.parquet"
    print(f"  Downloading {url}...")
    response = requests.get(url, stream=True)
    response.raise_for_status()
    with open(dest_path, "wb") as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
    size_mb = os.path.getsize(dest_path) / 1024 / 1024
    print(f"  Downloaded {size_mb:.1f} MB")


def load_month(conn, year: int, month: int):
    filename = f"yellow_tripdata_{year}-{month:02d}.parquet"

    with tempfile.TemporaryDirectory() as tmpdir:
        local_path = os.path.join(tmpdir, filename)
        download_file(year, month, local_path)

        print(f"  Reading parquet...")
        df = pd.read_parquet(local_path)

        # Normalize column names to uppercase for Snowflake
        df.columns = [c.upper() for c in df.columns]

        # Convert timestamps to strings to avoid type issues
        for col in df.select_dtypes(include=["datetime64"]):
            df[col] = df[col].astype(str)

        print(f"  Loaded {len(df):,} rows into dataframe")
        print(f"  Writing to Snowflake...")

        success, nchunks, nrows, _ = write_pandas(
            conn,
            df,
            table_name="TRIPS",
            database="NYC_TAXI",
            schema="RAW",
            auto_create_table=True,
            overwrite=False,
        )

        print(f"  Written {nrows:,} rows in {nchunks} chunks")


def main():
    print("Connecting to Snowflake...")
    conn = get_connection()
    print("Connected.\n")

    for year, month in MONTHS:
        print(f"Processing {year}-{month:02d}...")
        try:
            load_month(conn, year, month)
            print(f"  Done.\n")
        except Exception as e:
            print(f"  ERROR: {e}\n")

    conn.close()
    print("All done.")


if __name__ == "__main__":
    main()