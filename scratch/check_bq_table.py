import sys
sys.path.append(r"D:\ipython_file\.venv")
from utils.df_handle import get_bq_df

try:
    df = get_bq_df("SELECT * FROM `spatial-vision-343005.staging.d_gia_von_vttd` LIMIT 10")
    print("Fetched successfully!")
    print(df)
except Exception as e:
    print("Failed to query table:", e)
