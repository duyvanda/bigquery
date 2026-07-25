import os
import glob
import re
import sys
import pandas as pd
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
from google.cloud import bigquery

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
DATASET_ID = 'staging_temp'
ACTIVE_JOB_FILE = r'd:\bigquery\sp_handle\call_active_job.md'
EXCEL_REPORT_PATH = r'd:\bigquery\danh_sach_sp_usage.xlsx'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

# RULE CHECK ACTIVES FOR STORED PROCEDURES:
# Active = (Nằm trong 107 Active SPs của call_active_job.md) OR (Có query trong 180d)
# Unused = (Không nằm trong call_active_job.md) AND (Không query trong 180d)

def analyze_sp_usage():
    print("==========================================")
    print("PHÂN TÍCH USAGE STORED PROCEDURES (CHUẨN RULE 3 TIÊU CHÍ)")
    print("==========================================\n")

    # 1. Đọc danh sách CALL active SPs từ call_active_job.md
    print("1. Đọc danh sách Active Jobs từ call_active_job.md...")
    active_sps_file = {}
    with open(ACTIVE_JOB_FILE, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.split('\n')
    for line_num, line in enumerate(lines, 1):
        calls = line.split(';')
        for c in calls:
            c = c.strip()
            if 'CALL' in c.upper():
                parts = c.split('.')
                if len(parts) >= 2:
                    sp_name = parts[-1].replace('`', '').replace('()', '').strip().lower()
                    if sp_name:
                        active_sps_file[sp_name] = f"call_active_job.md (Line {line_num})"

    print(f"-> Ghi nhận {len(active_sps_file)} Stored Procedures Active trong call_active_job.md.")

    # 2. Truy vấn JOBS lịch sử 180 ngày từ BigQuery
    print("\n2. Đang đọc lịch sử Query (180d) từ BigQuery JOBS...")
    query_jobs = """
    SELECT 
        REGEXP_EXTRACT(query, r'(?i)(?:staging_temp|`staging_temp`)\.(`?[\w]+`?)') AS raw_sp,
        MAX(creation_time) AS last_queried_time,
        COUNT(1) AS total_queries,
        STRING_AGG(DISTINCT user_email, ', ') AS user_emails
    FROM `region-asia-southeast1`.INFORMATION_SCHEMA.JOBS
    WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
      AND (LOWER(query) LIKE '%call%' OR LOWER(query) LIKE '%staging_temp%')
    GROUP BY raw_sp
    HAVING raw_sp IS NOT NULL
    """
    
    sp_job_usage = {}
    try:
        query_job = client.query(query_jobs)
        for row in query_job.result():
            clean_sp = str(row.raw_sp).replace('`', '').replace('()', '').strip().lower()
            sp_job_usage[clean_sp] = {
                'last_queried': row.last_queried_time,
                'total_queries': row.total_queries,
                'user_emails': row.user_emails or ''
            }
        print(f"-> Ghi nhận {len(sp_job_usage)} SPs có lịch sử gọi trong 180 ngày.")
    except Exception as e:
        print(f"[!] Lỗi truy vấn JOBS: {e}")

    # 3. Quét tất cả file .sql local trong staging_temp
    print("\n3. Đang quét danh sách file SQL SPs local trong d:\\bigquery\\staging_temp...")
    sp_files = glob.glob(r'd:\bigquery\staging_temp\*.sql')
    
    sp_results = []
    for idx, sf in enumerate(sp_files, 1):
        sp_name = os.path.splitext(os.path.basename(sf))[0].lower()
        
        in_active_file = sp_name in active_sps_file
        active_source_info = active_sps_file.get(sp_name, '')
        
        job_info = sp_job_usage.get(sp_name)
        has_job_query = job_info is not None
        last_queried_str = job_info['last_queried'].strftime('%Y-%m-%d %H:%M:%S') if has_job_query else 'Không gọi trong 180d'
        users_str = job_info['user_emails'] if has_job_query else 'Không có'
        
        is_active = in_active_file or has_job_query
        
        sources = []
        if in_active_file:
            sources.append(active_source_info)
        if has_job_query:
            sources.append("Query history 180d")
            
        source_str = " + ".join(sources) if sources else "Hoàn toàn không sử dụng"
        status = 'Active (Đang sử dụng)' if is_active else 'Lâu chưa query / Unused'
        
        sp_results.append({
            'STT': idx,
            'Tên Stored Procedure': sp_name,
            'Dataset': DATASET_ID,
            'Trạng thái': status,
            'Nguồn ghi nhận Usage': source_str,
            'Lần cuối Query (JOBS 180d)': last_queried_str,
            'Tài khoản thực thi': users_str,
            'File SQL Local': os.path.basename(sf)
        })

    df = pd.DataFrame(sp_results)
    active_count = len(df[df['Trạng thái'].str.startswith('Active')])
    unused_count = len(df) - active_count
    
    print("\n================ KẾT QUẢ TỔNG HỢP STORED PROCEDURES ================")
    print(f"Tổng số SP SQL files local: {len(df)}")
    print(f"  - Stored Procedures ĐANG SỬ DỤNG (Active): {active_count}")
    print(f"  - Stored Procedures LÂU CHƯA QUERY / UNUSED: {unused_count}")
    print("====================================================================")

    # 4. Xuất Excel
    with pd.ExcelWriter(EXCEL_REPORT_PATH, engine='openpyxl') as writer:
        df.to_excel(writer, index=False, sheet_name='Stored Procedures Usage')

    print(f"\n[+] Đã xuất báo cáo Excel SP Usage tại: {EXCEL_REPORT_PATH}")

if __name__ == '__main__':
    analyze_sp_usage()
