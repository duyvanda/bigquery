import sys
import os
import pandas as pd

# Add python virtualenv packages path and project path to sys.path
sys.path.append(r"D:\ipython_file\.venv")
sys.path.append(r"D:\ipython_file\.venv\utils")

from utils.df_handle import bq_values_insert

csv_path = r"d:\bigquery\staging_table\csv\d_gia_von_vttd.csv"
table_name = "d_gia_von_vttd"

print(f"Reading CSV from {csv_path}...")
df = pd.read_csv(csv_path)

print("DataFrame Info:")
print(f"Shape: {df.shape}")
print(df.info())

print(f"Inserting into BigQuery table 'staging.{table_name}' using option 3 (WRITE_TRUNCATE)...")
try:
    bq_values_insert(df, table_name, 3)
    print("Insertion completed successfully!")
except Exception as e:
    print("Error during insertion:")
    import traceback
    traceback.print_exc()
    sys.exit(1)
