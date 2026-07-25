import os
import glob
import sys
from google.cloud import bigquery

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
tbl_name = 'd_manual_ds_kh_stiker_ladoi'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

print(f"==========================================")
print(f"KIỂM TRA CHÍNH XÁC BẢNG: {tbl_name}")
print(f"==========================================\n")

# 1. Đọc danh sách Active SPs từ call_active_job.md
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

print(f"1. KIỂM TRA TRONG 107 ACTIVE SPs ({len(active_sps)} SPs):")
sp_files = glob.glob(r'd:\bigquery\staging_temp\*.sql')
sp_refs = []
for sf in sp_files:
    sp_base = os.path.splitext(os.path.basename(sf))[0].lower()
    if sp_base not in active_sps:
        continue
    with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read().lower()
    if tbl_name.lower() in content:
        sp_refs.append((os.path.basename(sf), sf))

if sp_refs:
    print(f" -> Tìm thấy trong Active SPs:")
    for name, path in sp_refs:
        print(f"    - {name}")
else:
    print(f" -> KHÔNG có trong bất kỳ Active SP nào.")

# 2. Kiểm tra trong 212 Active Views
print(f"\n2. KIỂM TRA TRONG 212 ACTIVE VIEWs:")
view_files = glob.glob(r'd:\bigquery\warehouse_view\*.sql')
view_refs = []
for vf in view_files:
    with open(vf, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read().lower()
    if tbl_name.lower() in content:
        view_refs.append((os.path.basename(vf), vf))

if view_refs:
    print(f" -> Tìm thấy trong Active Views:")
    for name, path in view_refs:
        print(f"    - {name}")
else:
    print(f" -> KHÔNG có trong bất kỳ Active View nào.")

# 3. Kiểm tra trong JOBS (180d)
print(f"\n3. KIỂM TRA LỊCH SỬ QUERY JOBS (180 NGÀY):")
query = f"""
SELECT 
    job_id,
    creation_time,
    user_email,
    query
FROM `region-asia-southeast1`.INFORMATION_SCHEMA.JOBS
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
  AND LOWER(query) LIKE '%{tbl_name.lower()}%'
ORDER BY creation_time DESC
LIMIT 10
"""

try:
    rows = list(client.query(query).result())
    print(f" -> Tìm thấy {len(rows)} lượt query trong 180 ngày qua:")
    for r in rows:
        print(f"    - Ngày: {r.creation_time} | User: {r.user_email}")
        print(f"      Snippet: {r.query[:120]}...\n")
except Exception as e:
    print(f" -> Lỗi query JOBS: {e}")
