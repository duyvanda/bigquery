import os
import glob
import sys
from google.cloud import bigquery

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
view_name = 'view_sp_f_nhacdon_pcl'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

print(f"==========================================")
print(f"KIỂM TRA CHÍNH XÁC USAGE VÀ TRẠNG THÁI CỦA VIEW: {view_name}")
print(f"==========================================\n")

# 1. Kiểm tra tồn tại trên BigQuery
print("1. KIỂM TRA TRÊN BIGQUERY PRODUCTION:")
try:
    v_obj = client.get_table(f"{PROJECT_ID}.warehouse.{view_name}")
    print(f" -> VIEW tồn tại trên BigQuery! Created: {v_obj.created} | Modified: {v_obj.modified}")
except Exception as e:
    print(f" -> KHÔNG tìm thấy VIEW trên BigQuery: {e}")

# 2. Lịch sử query (180d)
print("\n2. LỊCH SỬ QUERY TRONG 180 NGÀY (JOBS):")
query_jobs = f"""
SELECT 
    job_id,
    creation_time,
    user_email,
    query
FROM `region-asia-southeast1`.INFORMATION_SCHEMA.JOBS
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
  AND LOWER(query) LIKE '%{view_name.lower()}%'
ORDER BY creation_time DESC
LIMIT 10
"""
try:
    rows = list(client.query(query_jobs).result())
    print(f" -> Tìm thấy {len(rows)} lượt query trong 180 ngày qua:")
    for r in rows:
        print(f"    - Ngày: {r.creation_time} | User: {r.user_email}")
        print(f"      Snippet: {r.query[:120]}...\n")
except Exception as e:
    print(f" -> Lỗi query JOBS: {e}")

# 3. Quét xem VIEW này có được gọi bởi Active SP hay View nào khác không
print("\n3. THAM CHIẾU NỘI DUNG TRONG ACTIVE SPs & VIEWS KHÁC:")
sp_files = glob.glob(r'd:\bigquery\staging_temp\*.sql')
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
                sp_n = parts[-1].replace('`', '').replace('()', '').strip().lower()
                if sp_n:
                    active_sps.add(sp_n)

sp_refs = []
for sf in sp_files:
    sp_base = os.path.splitext(os.path.basename(sf))[0].lower()
    if sp_base not in active_sps:
        continue
    with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read().lower()
    if view_name.lower() in content:
        sp_refs.append(os.path.basename(sf))

if sp_refs:
    print(f" -> Tìm thấy được gọi trong Active SPs:")
    for s in sp_refs:
        print(f"    - {s}")
else:
    print(f" -> KHÔNG được gọi bởi bất kỳ Active SP nào.")
