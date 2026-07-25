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
DATASET_ID = 'staging'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

# 1. Đọc 107 Active SPs
active_job_file = r'd:\bigquery\sp_handle\call_active_job.md'
active_sps = set()
with open(active_job_file, 'r', encoding='utf-8') as f:
    text = f.read()

for line in text.split('\n'):
    for c in line.split(';'):
        c = c.strip()
        if 'CALL' in c.upper():
            parts = c.split('.')
            if len(parts) >= 2:
                sp_name = parts[-1].replace('`', '').replace('()', '').strip().lower()
                if sp_name:
                    active_sps.add(sp_name)

# 2. Lấy danh sách Base Tables
all_items = list(client.list_tables(DATASET_ID))
base_tables = [item for item in all_items if item.table_type == 'TABLE']
table_names = [t.table_id for t in base_tables]

# 3. Lịch sử JOBS (180d) - BỎ QUA các câu SELECT * FROM staging.<table_name> do script backup tự chạy!
query_jobs = f"""
SELECT 
    REGEXP_EXTRACT(query, r'(?i)(?:{DATASET_ID}|`{DATASET_ID}`)\.(`?[\w]+`?)') AS raw_tbl,
    MAX(creation_time) AS last_queried_time,
    COUNT(1) AS total_queries,
    STRING_AGG(DISTINCT user_email, ', ') AS user_emails
FROM `region-asia-southeast1`.INFORMATION_SCHEMA.JOBS
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
  AND (LOWER(query) LIKE '%{DATASET_ID}%' OR LOWER(query) LIKE '%table%')
  -- Bỏ qua các câu SELECT * sao lưu dữ liệu thô từ service account
  AND NOT (LOWER(query) LIKE 'select * from%' AND user_email = 'bigquery@spatial-vision-343005.iam.gserviceaccount.com')
GROUP BY raw_tbl
HAVING raw_tbl IS NOT NULL
"""

table_job_usage = {}
for row in client.query(query_jobs).result():
    clean_tbl = str(row.raw_tbl).replace('`', '').strip()
    table_job_usage[clean_tbl] = {
        'last_queried': row.last_queried_time,
        'total_queries': row.total_queries,
        'user_emails': row.user_emails or ''
    }

# 4. Quét tham chiếu Code (107 Active SPs + 212 Active Views)
sp_files = glob.glob(r'd:\bigquery\staging_temp\*.sql')
view_files = glob.glob(r'd:\bigquery\warehouse_view\*.sql')

referenced_in_code = {}

for sf in sp_files:
    sp_base = os.path.splitext(os.path.basename(sf))[0].lower()
    if sp_base not in active_sps:
        continue
    sp_name = os.path.basename(sf)
    with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read().lower()
    for tn in table_names:
        tn_lower = tn.lower()
        if f"staging.{tn_lower}" in content or f"`staging`.`{tn_lower}`" in content or f"`{tn_lower}`" in content:
            referenced_in_code.setdefault(tn, set()).add(f"Active SP: {sp_name}")

for vf in view_files:
    v_name = os.path.basename(vf)
    with open(vf, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read().lower()
    for tn in table_names:
        tn_lower = tn.lower()
        if f"staging.{tn_lower}" in content or f"`staging`.`{tn_lower}`" in content:
            referenced_in_code.setdefault(tn, set()).add(f"Active View: {v_name}")

# 5. Đánh giá trạng thái thực sự
truly_unused_tables = []
for tn in table_names:
    has_job = tn in table_job_usage
    has_code = tn in referenced_in_code
    if not (has_job or has_code):
        truly_unused_tables.append(tn)

print(f"==========================================")
print(f"KẾT QUẢ KHI LỌC BỎ CÂU HỎI BACKUP SAO LƯU:")
print(f"Tổng số Base Tables trong staging: {len(base_tables)}")
print(f"Số tables THỰC SỰ LÂU CHƯA QUERY / UNUSED: {len(truly_unused_tables)}")
print(f"==========================================\n")

for idx, t in enumerate(truly_unused_tables, 1):
    print(f"  {idx}. {t}")
