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
DATASET_ID = 'warehouse'
WAREHOUSE_CSV_DIR = r'd:\bigquery\warehouse_table'
MAX_BYTES = 10 * 1024 * 1024 # 10 MB limit

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

def backup_and_drop():
    print("==========================================")
    print("SAO LƯU PYARROW CSV (< 10MB) & DROP 10 UNUSED WAREHOUSE BASE TABLES")
    print("==========================================\n")

    os.makedirs(WAREHOUSE_CSV_DIR, exist_ok=True)

    # 1. Đọc báo cáo usage từ Excel hoặc phân tích trực tiếp
    excel_path = r'd:\bigquery\danh_sach_table_warehouse_usage.xlsx'
    if os.path.exists(excel_path):
        df = pd.read_excel(excel_path)
        unused_df = df[df['Trạng thái'].str.contains('Unused')]
        unused_tables = unused_df['Tên Base Table'].tolist()
    else:
        print("[!] Không tìm thấy file Excel báo cáo usage. Kết thúc.")
        return

    print(f"-> Xác định được {len(unused_tables)} Base Tables hết dùng trong dataset '{DATASET_ID}'.\n")

    # 2. BƯỚC 1: SAO LƯU CSV BẰNG PYARROW (CHỈ TABLES < 10MB)
    print("================ BƯỚC 1: SAO LƯU CSV (CHỈ TABLES < 10MB) ================")
    backed_up_count = 0
    skipped_count = 0

    for idx, t_name in enumerate(unused_tables, 1):
        try:
            t_obj = client.get_table(f"{PROJECT_ID}.{DATASET_ID}.{t_name}")
            t_bytes = t_obj.num_bytes or 0
            size_mb = round(t_bytes / (1024 * 1024), 2)
            
            if t_bytes >= MAX_BYTES:
                print(f"[SKIP >= 10MB {idx}/{len(unused_tables)}] {t_name} ({size_mb} MB) -> Bỏ qua không tải CSV.")
                skipped_count += 1
                continue
                
            csv_filename = f"{t_name}.csv"
            csv_path = os.path.join(WAREHOUSE_CSV_DIR, csv_filename)
            
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

    print(f"\n-> Hoàn tất sao lưu PyArrow: {backed_up_count} tables được tạo CSV (<10MB), {skipped_count} tables bỏ qua/lỗi.\n")

    # 3. BƯỚC 2: DROP UNUSED BASE TABLES TRÊN BIGQUERY PRODUCTION
    print("================ BƯỚC 2: DROP BASE TABLES ON BIGQUERY PRODUCTION ================")
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
    print(f"HOÀN THÀNH XOÁ BASE TABLES TRÊN BIGQUERY WAREHOUSE!")
    print(f"- Số file CSV được tạo (<10MB): {backed_up_count}")
    print(f"- Số tables DROP thành công: {dropped_count}")
    print(f"- Số tables DROP thất bại: {failed_count}")
    print(f"==========================================")

if __name__ == '__main__':
    backup_and_drop()
