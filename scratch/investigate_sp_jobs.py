import os
import sys
from google.cloud import bigquery

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
sp_name = 'sp_f_baocao_phanbothau'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

print(f"==========================================")
print(f"TRA CỨU TOÀN BỘ LỊCH SỬ THỰC THI BẢNG JOBS CHO: {sp_name}")
print(f"==========================================\n")

region = 'region-asia-southeast1'
query_jobs = f"""
SELECT 
    job_id,
    creation_time,
    user_email,
    query,
    statement_type
FROM `{region}`.INFORMATION_SCHEMA.JOBS
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
  AND LOWER(query) LIKE '%{sp_name.lower()}%'
ORDER BY creation_time DESC
LIMIT 20
"""

try:
    rows = list(client.query(query_jobs).result())
    print(f"-> Tìm thấy {len(rows)} lượt JOBS có chứa từ khóa '{sp_name}' trong 180 ngày qua:\n")
    for idx, r in enumerate(rows, 1):
        print(f"  {idx}. Ngày: {r.creation_time} | User: {r.user_email} | Type: {r.statement_type}")
        print(f"     Query snippet: {r.query[:150]}...\n")
except Exception as e:
    print(f"[!] Lỗi truy vấn JOBS: {e}")

# Truy vấn thử bảng ROUTINES xem thời gian last_altered
query_routine = f"""
SELECT 
    routine_name,
    routine_type,
    created,
    last_altered
FROM `spatial-vision-343005.staging_temp.INFORMATION_SCHEMA.ROUTINES`
WHERE LOWER(routine_name) LIKE '%{sp_name.lower()}%'
"""
try:
    r_rows = list(client.query(query_routine).result())
    if r_rows:
        print(f"-> Thông tin Metadata Routine trên BigQuery:")
        for r in r_rows:
            print(f"   Name: {r.routine_name} | Created: {r.created} | Last Altered: {r.last_altered}")
    else:
        print(f"-> Routine '{sp_name}' không tìm thấy trong staging_temp.INFORMATION_SCHEMA.ROUTINES")
except Exception as e:
    print(f"[!] Lỗi truy vấn ROUTINES: {e}")
