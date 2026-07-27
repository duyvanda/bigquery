import sys
import os
import pandas as pd

# Add python virtualenv packages path and project path to sys.path
sys.path.append(r"D:\ipython_file\.venv")
sys.path.append(r"D:\ipython_file\.venv\utils")

from utils.df_handle import bq_values_insert, get_bq_df

tables_to_insert = [
    {
        "csv_path": r"d:\bigquery\staging_table\csv\d_form_ktttthbb_phan_hoi.csv",
        "table_name": "d_form_ktttthbb_phan_hoi"
    },
    {
        "csv_path": r"d:\bigquery\staging_table\csv\d_crs_location.csv",
        "table_name": "d_crs_location"
    }
]

for table_info in tables_to_insert:
    csv_path = table_info["csv_path"]
    table_name = table_info["table_name"]
    
    print("=" * 60)
    print(f"Processing CSV: {csv_path}")
    print("=" * 60)
    
    if not os.path.exists(csv_path):
        print(f"Error: File {csv_path} does not exist!")
        continue
        
    try:
        df = pd.read_csv(csv_path)
        print("DataFrame Info:")
        print(f"Shape: {df.shape}")
        print(df.dtypes)
        
        print(f"Inserting into BigQuery table 'staging.{table_name}' using option 3...")
        bq_values_insert(df, table_name, 3)
        print(f"Successfully inserted staging.{table_name}!")
        
        # Verify by querying BigQuery
        print("Verifying in BigQuery...")
        verify_df = get_bq_df(f"SELECT COUNT(*) as total_rows FROM `spatial-vision-343005.staging.{table_name}`")
        print(f"Total rows in BigQuery for {table_name}: {verify_df['total_rows'].values[0]}")
    except Exception as e:
        print(f"Error processing {table_name}:")
        import traceback
        traceback.print_exc()

print("\nAll tasks processed.")
