import os
import glob
import re
import sys
import pandas as pd
import pyarrow as pa
import pyarrow.csv as pv
from google.cloud import bigquery

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
DATASET_ID = 'staging'
STAGING_CSV_DIR = r'd:\bigquery\staging'
MAX_BYTES = 10 * 1024 * 1024 # 10 MB limit

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

def backup_and_drop():
    print("==========================================")
    print("SAO LƯU PYARROW CSV (TABLES < 10MB) & DROP 98 STAGING TABLES")
    print("==========================================\n")

    os.makedirs(STAGING_CSV_DIR, exist_ok=True)

    # 1. Lấy danh sách tables trong dataset 'staging'
    print(f"1. Đang lấy danh sách tables trong dataset '{DATASET_ID}'...")
    tables_list = list(client.list_tables(DATASET_ID))
    table_names = [t.table_id for t in tables_list]

    # 2. Đọc lịch sử JOBS (180d)
    print("2. Đang đọc lịch sử Query (180d) từ BigQuery...")
    query_jobs = f"""
    SELECT 
        REGEXP_EXTRACT(query, r'(?i)(?:{DATASET_ID}|`{DATASET_ID}`)\.(`?[\w]+`?)') AS raw_tbl
    FROM `region-asia-southeast1`.INFORMATION_SCHEMA.JOBS
    WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
      AND (LOWER(query) LIKE '%{DATASET_ID}%' OR LOWER(query) LIKE '%table%')
    GROUP BY raw_tbl
    HAVING raw_tbl IS NOT NULL
    """
    table_job_usage = set()
    try:
        for row in client.query(query_jobs).result():
            clean_tbl = str(row.raw_tbl).replace('`', '').strip()
            table_job_usage.add(clean_tbl)
    except Exception as e:
        print(f"Lỗi truy vấn JOBS: {e}")

    # 3. Quét tham chiếu Code SP / Views
    sp_files = glob.glob(r'd:\bigquery\staging_temp\*.sql')
    view_files = glob.glob(r'd:\bigquery\warehouse\*.sql')
    referenced_in_code = set()

    for sf in sp_files:
        with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read().lower()
        for tn in table_names:
            tn_lower = tn.lower()
            if f"staging.{tn_lower}" in content or f"`staging`.`{tn_lower}`" in content or f"`{tn_lower}`" in content:
                referenced_in_code.add(tn)

    for vf in view_files:
        with open(vf, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read().lower()
        for tn in table_names:
            tn_lower = tn.lower()
            if f"staging.{tn_lower}" in content or f"`staging`.`{tn_lower}`" in content:
                referenced_in_code.add(tn)

    # 4. Lọc danh sách 98 tables không dùng (Unused)
    unused_tables = []
    for tn in table_names:
        is_job_used = tn in table_job_usage
        is_code_used = tn in referenced_in_code
        if not (is_job_used or is_code_used):
            unused_tables.append(tn)

    print(f"-> Xác định được {len(unused_tables)} tables hết dùng cần xử lý.\n")

    # 5. BƯỚC 1: SAO LƯU CSV BẰNG PYARROW (CHỈ LẤY TABLES < 10MB)
    print("================ BƯỚC 1: SAO LƯU CSV (CHỈ TABLES < 10MB) ================")
    backed_up_count = 0
    skipped_count = 0

    for idx, t_name in enumerate(unused_tables, 1):
        try:
            t_obj = client.get_table(f"{PROJECT_ID}.{DATASET_ID}.{t_name}")
            t_bytes = t_obj.num_bytes or 0
            size_mb = round(t_bytes / (1024 * 1024), 2)
            
            # Bỏ qua nếu kích thước >= 10 MB
            if t_bytes >= MAX_BYTES:
                print(f"[SKIP >= 10MB {idx}/{len(unused_tables)}] {t_name} ({size_mb} MB) -> Bỏ qua không tải CSV.")
                skipped_count += 1
                continue
                
            csv_filename = f"{t_name}.csv"
            csv_path = os.path.join(STAGING_CSV_DIR, csv_filename)
            
            sql_select = f"SELECT * FROM `{PROJECT_ID}.{DATASET_ID}.{t_name}`"
            query_job = client.query(sql_select)
            arrow_table = query_job.to_arrow()
            
            pv.write_csv(arrow_table, csv_path)
            
            size_kb = round(os.path.getsize(csv_path) / 1024, 2)
            print(f"[BACKUP <10MB {idx}/{len(unused_tables)}] {t_name} -> {csv_filename} ({arrow_table.num_rows} rows, {size_kb} KB)")
            backed_up_count += 1
            
        except Exception as e:
            print(f"[SKIP ERROR {idx}/{len(unused_tables)}] {t_name}: {e}")
            skipped_count += 1

    print(f"\n-> Hoàn tất kiểm tra và sao lưu: {backed_up_count} tables được tạo CSV (<10MB), {skipped_count} tables bỏ qua/lỗi.\n")

    # 6. BƯỚC 2: DROP 98 TABLES TRÊN BIGQUERY PRODUCTION
    print("================ BƯỚC 2: DROP 98 TABLES ON BIGQUERY PRODUCTION ================")
    dropped_count = 0
    failed_count = 0

    for idx, t_name in enumerate(unused_tables, 1):
        drop_sql = f"DROP TABLE IF EXISTS `{PROJECT_ID}.{DATASET_ID}.{t_name}`;"
        try:
            client.query(drop_sql).result()
            dropped_count += 1
            print(f"[DROPPED {idx}/{len(unused_tables)}] {DATASET_ID}.{t_name}")
        except Exception as e:
            failed_count += 1
            print(f"[DROP FAILED] {t_name}: {e}")

    print(f"\n==========================================")
    print(f"HOÀN THÀNH XOÁ 98 TABLES ON BIGQUERY PRODUCTION!")
    print(f"- Số file CSV được tạo (<10MB): {backed_up_count}")
    print(f"- Số tables DROP thành công: {dropped_count}")
    print(f"- Số tables DROP thất bại: {failed_count}")
    print(f"==========================================")

if __name__ == '__main__':
    backup_and_drop()
