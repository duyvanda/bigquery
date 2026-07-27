"""
fetch_jobs_cache.py
-------------------
Query INFORMATION_SCHEMA.JOBS 1 lần duy nhất (~89GB scan),
lưu kết quả ra 2 CSV local để SP & View scripts dùng offline.

Chạy script này mỗi khi cần refresh data (ví dụ: đầu tháng).
Output:
  d:\bigquery\cache\sp_jobs_cache.csv   -> staging_temp SP usage
  d:\bigquery\cache\view_jobs_cache.csv -> warehouse View usage
"""

import os
import sys
import pandas as pd
from google.cloud import bigquery

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
CACHE_DIR = r'd:\bigquery\cache'
SP_CACHE_PATH = os.path.join(CACHE_DIR, 'sp_jobs_cache.csv')
VIEW_CACHE_PATH = os.path.join(CACHE_DIR, 'view_jobs_cache.csv')

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
os.makedirs(CACHE_DIR, exist_ok=True)


def fetch_and_cache():
    client = bigquery.Client(project=PROJECT_ID)

    print("=" * 55)
    print("FETCH JOBS CACHE - Quét INFORMATION_SCHEMA.JOBS 1 lần")
    print("=" * 55)
    print("Đang query BigQuery (CTE gộp SP + View)...")
    print("⚠  Lưu ý: Query này scan ~89GB, chỉ chạy khi cần refresh.\n")

    # 1 CTE duy nhất, scan JOBS 1 lần, extract cả SP lẫn View
    sql = """
    WITH jobs AS (
        SELECT query, creation_time, user_email
        FROM `region-asia-southeast1`.INFORMATION_SCHEMA.JOBS
        WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
    ),
    sp_refs AS (
        SELECT
            'SP'       AS type,
            sp_name    AS name,
            MAX(creation_time)                        AS last_used_time,
            STRING_AGG(DISTINCT user_email, ', ')     AS users
        FROM jobs,
        UNNEST(REGEXP_EXTRACT_ALL(
            LOWER(query),
            r'staging_temp[.`]+([a-z0-9_]+)'
        )) AS sp_name
        GROUP BY type, name
    ),
    view_refs AS (
        SELECT
            'VIEW'     AS type,
            view_name  AS name,
            MAX(creation_time)                        AS last_used_time,
            STRING_AGG(DISTINCT user_email, ', ')     AS users
        FROM jobs,
        UNNEST(REGEXP_EXTRACT_ALL(
            LOWER(query),
            r'warehouse[.`]+([a-z0-9_]+)'
        )) AS view_name
        GROUP BY type, name
    )
    SELECT * FROM sp_refs
    UNION ALL
    SELECT * FROM view_refs
    ORDER BY type, name
    """

    rows = list(client.query(sql).result())
    df = pd.DataFrame([dict(r) for r in rows])
    df['last_used_time'] = pd.to_datetime(df['last_used_time'], utc=True)

    # Tách ra 2 CSV
    df_sp   = df[df['type'] == 'SP'][['name', 'last_used_time', 'users']].reset_index(drop=True)
    df_view = df[df['type'] == 'VIEW'][['name', 'last_used_time', 'users']].reset_index(drop=True)

    df_sp.to_csv(SP_CACHE_PATH, index=False, encoding='utf-8-sig')
    df_view.to_csv(VIEW_CACHE_PATH, index=False, encoding='utf-8-sig')

    print(f"✅ SP cache  : {len(df_sp):>4} records → {SP_CACHE_PATH}")
    print(f"✅ View cache: {len(df_view):>4} records → {VIEW_CACHE_PATH}")
    print("\nDone. Các script SP & View có thể đọc từ cache offline.")


if __name__ == '__main__':
    fetch_and_cache()
