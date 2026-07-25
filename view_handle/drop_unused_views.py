import os
import glob
import re
import sys
import pandas as pd
from google.cloud import bigquery

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
DATASET_ID = 'warehouse'
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH

client = bigquery.Client(project=PROJECT_ID)

def drop_unused_views():
    print("==========================================")
    print("XÁC ĐỊNH VÀ XÓA 76 UNUSED VIEWS TRÊN BIGQUERY PRODUCTION")
    print("==========================================\n")

    # 1. Lấy danh sách 288 views trong d:\bigquery\warehouse
    view_files = glob.glob(r'd:\bigquery\warehouse\*.sql')
    view_names = sorted(list(set(os.path.splitext(os.path.basename(f))[0].strip() for f in view_files)))
    print(f"1. Tổng số VIEWs trong dataset warehouse: {len(view_names)}")

    # 2. Quét tham chiếu trong SPs và VIEWs
    sp_files = glob.glob(r'd:\bigquery\staging_temp\*.sql')
    referenced_in_code = set()

    for sf in sp_files:
        with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read().lower()
        for vn in view_names:
            vn_lower = vn.lower()
            if f"warehouse.{vn_lower}" in content or f"`warehouse`.`{vn_lower}`" in content or f"`{vn_lower}`" in content:
                referenced_in_code.add(vn)

    for vf in view_files:
        v_name = os.path.splitext(os.path.basename(vf))[0]
        with open(vf, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read().lower()
        for vn in view_names:
            if vn == v_name:
                continue
            vn_lower = vn.lower()
            if f"warehouse.{vn_lower}" in content or f"`warehouse`.`{vn_lower}`" in content:
                referenced_in_code.add(vn)

    # 3. Server-side Group By từ BigQuery JOBS (180 ngày)
    print("2. Truy vấn JOBS (180 ngày) từ BigQuery...")
    query_jobs = """
    SELECT 
        REGEXP_EXTRACT(query, r'(?i)(?:warehouse|`warehouse`)\.(`?[\w]+`?)') AS raw_view
    FROM `region-asia-southeast1`.INFORMATION_SCHEMA.JOBS
    WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
      AND (LOWER(query) LIKE '%warehouse%' OR LOWER(query) LIKE '%view%')
    GROUP BY raw_view
    HAVING raw_view IS NOT NULL
    """
    
    view_job_usage = set()
    try:
        query_job = client.query(query_jobs)
        for row in query_job.result():
            clean_v = str(row.raw_view).replace('`', '').strip()
            view_job_usage.add(clean_v)
    except Exception as e:
        print(f"Lỗi truy vấn JOBS: {e}")

    # 4. Lọc các VIEWs không dùng (Unused)
    unused_views = []
    for vn in view_names:
        is_code_ref = vn in referenced_in_code
        is_job_ref = vn in view_job_usage
        
        if not (is_code_ref or is_job_ref):
            unused_views.append(vn)

    print(f"\n-> Tìm thấy {len(unused_views)} VIEWs hoàn toàn không được sử dụng.")

    # 5. Thực thi DROP VIEW IF EXISTS
    dropped_count = 0
    failed_count = 0

    for idx, v_name in enumerate(unused_views, 1):
        drop_sql = f"DROP VIEW IF EXISTS `{PROJECT_ID}.{DATASET_ID}.{v_name}`;"
        try:
            client.query(drop_sql).result()
            dropped_count += 1
            print(f"[DROPPED {idx}/{len(unused_views)}] {DATASET_ID}.{v_name}")
        except Exception as e:
            failed_count += 1
            print(f"[FAILED] Lỗi drop {v_name}: {e}")

    print(f"\n==========================================")
    print(f"HOÀN THÀNH XOÁ VIEWS ON BIGQUERY PRODUCTION!")
    print(f"- Số VIEWs DROP thành công: {dropped_count}")
    print(f"- Số VIEWs DROP thất bại: {failed_count}")
    print(f"==========================================")

if __name__ == '__main__':
    drop_unused_views()
