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
print("KIỂM TRA ACTIVE SPS MULTI-STATEMENT SCRIPT SAFE")
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

# 2. Quét JOBS (180d) có chứa lệnh CALL
region = 'region-asia-southeast1'
query_jobs = f"""
SELECT 
    query,
    creation_time
FROM `{region}`.INFORMATION_SCHEMA.JOBS
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
  AND (LOWER(query) LIKE '%call%' OR statement_type IN ('CALL', 'SCRIPT'))
"""

executed_sps_jobs = {}
job_rows = list(client.query(query_jobs).result())
print(f"2. Đã tải {len(job_rows)} query JOBS có chứa lệnh CALL/SCRIPT.")

for row in job_rows:
    q_lower = str(row.query).lower()
    c_time = row.creation_time
    # Tìm tất cả các tên SP được CALL trong query string
    for sp in called_sps:
        if f'call' in q_lower and sp in q_lower:
            if sp not in executed_sps_jobs or c_time > executed_sps_jobs[sp]:
                executed_sps_jobs[sp] = c_time

print(f"\n================= KẾT QUẢ QUÉT MULTI-STATEMENT SCRIPT =================")
print(f"-> Số Active SPs trong call_active_job.md CÓ CHẠY THỰC TẾ 180D: {len(executed_sps_jobs)} / {len(called_sps)}")

inactive_in_md = called_sps - set(executed_sps_jobs.keys())
print(f"-> Số SPs trong call_active_job.md KHÔNG CHẠY TRONG 180D: {len(inactive_in_md)}")
if inactive_in_md:
    print("   - Các SP không chạy 180d:", sorted(list(inactive_in_md)))
print("=======================================================================")
