import os
import glob
import sys
import re
from google.cloud import bigquery

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
ACTIVE_JOB_FILE = r'd:\bigquery\sp_handle\call_active_job.md'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

print("==========================================")
print("KIỂM TRA ACTIVE SPS THEO ĐIỀU KIỆN KÉP CHUẨN XÁC")
print("Rule: Active SP = (Nằm trong call_active_job.md) AND (Có thực thi JOBS trong 180 ngày)")
print("==========================================\n")

# 1. Đọc 107 SPs từ call_active_job.md
with open(ACTIVE_JOB_FILE, 'r', encoding='utf-8') as f:
    text = f.read()

called_sps = set()
for line in text.split('\n'):
    for c in line.split(';'):
        if 'CALL' in c.upper():
            parts = c.split('.')
            if len(parts) >= 2:
                clean_name = re.sub(r'[^a-zA-Z0-9_]', '', parts[-1]).lower()
                if clean_name:
                    called_sps.add(clean_name)

print(f"1. Số SPs được liệt kê trong call_active_job.md: {len(called_sps)}")

# 2. Đọc JOBS (180d) có lệnh CALL
region = 'region-asia-southeast1'
query_jobs = f"""
SELECT 
    LOWER(REGEXP_EXTRACT(query, r'(?i)CALL\s+`?(?:[\w\-]+\.)?(?:[\w\-]+\.)?([\w]+)`?')) AS clean_sp,
    MAX(creation_time) AS last_used_time,
    COUNT(1) AS total_calls
FROM `{region}`.INFORMATION_SCHEMA.JOBS
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
  AND (LOWER(query) LIKE '%call%' OR statement_type = 'CALL')
GROUP BY clean_sp
HAVING clean_sp IS NOT NULL
"""

jobs_executed_sps = {}
for row in client.query(query_jobs).result():
    if row.clean_sp:
        jobs_executed_sps[row.clean_sp.lower()] = {
            'last_used': row.last_used_time,
            'total_calls': row.total_calls
        }

print(f"2. Số SPs có lịch sử thực thi thực tế trong 180 ngày qua (JOBS): {len(jobs_executed_sps)}")

# 3. ĐIỀU KIỆN KÉP: Vừa có trong call_active_job.md VỪA có thực thi trong 180d
truly_active_sps = set()
sps_in_md_but_no_jobs = set()

for sp in called_sps:
    if sp in jobs_executed_sps:
        truly_active_sps.add(sp)
    else:
        sps_in_md_but_no_jobs.add(sp)

print(f"\n================= KẾT QUẢ ĐIỀU KIỆN KÉP ACTIVE SPS =================")
print(f"-> Số Active SPs THỰC SỰ (Vừa trong MD + Vừa chạy 180d): {len(truly_active_sps)}")
print(f"-> Số SPs có trong MD nhưng KHÔNG CHẠY TRONG 180D (Inactive): {len(sps_in_md_but_no_jobs)}")
print("=====================================================================")

if sps_in_md_but_no_jobs:
    print("\nDanh sách SPs nằm trong call_active_job.md nhưng KHÔNG CHẠY TRONG 180D:")
    for idx, s in enumerate(sorted(list(sps_in_md_but_no_jobs)), 1):
        print(f"  {idx}. {s}")
