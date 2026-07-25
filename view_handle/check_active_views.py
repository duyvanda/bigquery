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
DATASET_ID = 'warehouse'
EXCEL_REPORT_PATH = r'd:\bigquery\danh_sach_view_usage.xlsx'
ACTIVE_JOB_FILE = r'd:\bigquery\sp_handle\call_active_job.md'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

# RULE CHECK ACTIVES FOR VIEWS:
# Active = (Có query trong 180d từ JOBS / Looker / BI) OR (Nằm trong 107 Active SPs) OR (Nằm trong Views khác)
# Unused = (Không query 180d) AND (Không nằm trong Active SPs) AND (Không nằm trong Active Views)

def get_active_sp_names():
    active_sps = set()
    if not os.path.exists(ACTIVE_JOB_FILE):
        return active_sps
    with open(ACTIVE_JOB_FILE, 'r', encoding='utf-8') as f:
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
    return active_sps

def analyze_warehouse_views():
    print("==========================================")
    print("PHÂN TÍCH USAGE WAREHOUSE VIEWS (CHUẨN RULE 3 TIÊU CHÍ)")
    print("==========================================\n")

    active_sp_set = get_active_sp_names()
    print(f"1. Đã tải {len(active_sp_set)} Active Stored Procedures từ call_active_job.md.")

    # 1. Lấy danh sách tất cả VIEWs trong dataset warehouse từ local SQL files
    view_files = glob.glob(r'd:\bigquery\warehouse_view\*.sql')
    view_names = sorted(list(set(os.path.splitext(os.path.basename(f))[0].strip() for f in view_files)))
    print(f"2. Tổng số VIEWs trong dataset warehouse: {len(view_names)}")

    # 2. Truy vấn JOBS (180 ngày) từ BigQuery
    print("\n3. Đang đọc lịch sử Query (180d) từ BigQuery JOBS (bao gồm Looker / BI tools)...")
    query_jobs = """
    SELECT 
        REGEXP_EXTRACT(query, r'(?i)(?:warehouse|`warehouse`)\.(`?[\w]+`?)') AS raw_view,
        MAX(creation_time) AS last_queried_time,
        COUNT(1) AS total_queries,
        STRING_AGG(DISTINCT user_email, ', ') AS user_emails
    FROM `region-asia-southeast1`.INFORMATION_SCHEMA.JOBS
    WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
      AND (LOWER(query) LIKE '%warehouse%' OR LOWER(query) LIKE '%view%')
    GROUP BY raw_view
    HAVING raw_view IS NOT NULL
    """
    
    view_job_usage = {}
    try:
        query_job = client.query(query_jobs)
        for row in query_job.result():
            clean_v = str(row.raw_view).replace('`', '').strip()
            view_job_usage[clean_v] = {
                'last_queried': row.last_queried_time,
                'total_queries': row.total_queries,
                'user_emails': row.user_emails or ''
            }
        print(f"-> Ghi nhận {len(view_job_usage)} VIEWs có lịch sử truy vấn trong 180 ngày.")
    except Exception as e:
        print(f"[!] Lỗi truy vấn JOBS: {e}")

    # 3. Quét tham chiếu trong Active SPs & Nested Views
    print("\n4. Đang quét tham chiếu View trong Active SPs (107 SPs) & Nested Views...")
    sp_files = glob.glob(r'd:\bigquery\staging_temp\*.sql')
    
    referenced_in_code = {}

    for sf in sp_files:
        sp_base = os.path.splitext(os.path.basename(sf))[0].lower()
        if sp_base not in active_sp_set:
            continue
            
        sp_name = os.path.basename(sf)
        with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read().lower()
        for vn in view_names:
            vn_lower = vn.lower()
            if f"warehouse.{vn_lower}" in content or f"`warehouse`.`{vn_lower}`" in content or f"`{vn_lower}`" in content:
                referenced_in_code.setdefault(vn, set()).add(f"Active SP: {sp_name}")

    for vf in view_files:
        v_name = os.path.splitext(os.path.basename(vf))[0]
        with open(vf, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read().lower()
        for vn in view_names:
            if vn == v_name:
                continue
            vn_lower = vn.lower()
            if f"warehouse.{vn_lower}" in content or f"`warehouse`.`{vn_lower}`" in content:
                referenced_in_code.setdefault(vn, set()).add(f"Active View: {v_name}")

    print(f"-> {len(referenced_in_code)} VIEWs được tham chiếu trực tiếp trong Code SP/View.")

    # 4. Lập bảng kết quả
    results = []
    for idx, vn in enumerate(view_names, 1):
        job_info = view_job_usage.get(vn)
        has_job_query = job_info is not None
        last_queried_str = job_info['last_queried'].strftime('%Y-%m-%d %H:%M:%S') if has_job_query else 'Không query trong 180d'
        users_str = job_info['user_emails'] if has_job_query else 'Không có'
        
        code_refs = referenced_in_code.get(vn, set())
        has_code_ref = len(code_refs) > 0
        code_ref_str = ", ".join(sorted(list(code_refs))) if has_code_ref else 'Không có'
        
        is_active = has_job_query or has_code_ref
        
        sources = []
        if has_job_query:
            sources.append("Query history / Looker 180d")
        if has_code_ref:
            sp_count = sum(1 for r in code_refs if r.startswith("Active SP"))
            view_count = sum(1 for r in code_refs if r.startswith("Active View"))
            if sp_count > 0:
                sources.append(f"Active SP ({sp_count})")
            if view_count > 0:
                sources.append(f"Active View ({view_count})")
                
        source_str = " + ".join(sources) if sources else "Hoàn toàn không sử dụng"
        status = 'Active (Đang sử dụng)' if is_active else 'Lâu chưa query / Unused'
        
        results.append({
            'STT': idx,
            'Tên VIEW': vn,
            'Dataset': DATASET_ID,
            'Trạng thái': status,
            'Nguồn ghi nhận Usage': source_str,
            'Lần cuối Query (JOBS 180d)': last_queried_str,
            'Tài khoản/Looker query': users_str,
            'Tham chiếu trong Code (Active SP/View)': 'Có' if has_code_ref else 'Không',
            'Chi tiết Code tham chiếu': code_ref_str
        })

    df = pd.DataFrame(results)
    active_count = len(df[df['Trạng thái'].str.startswith('Active')])
    unused_count = len(df) - active_count
    
    print("\n================ KẾT QUẢ TỔNG HỢP WAREHOUSE VIEWS ================")
    print(f"Tổng số VIEWs trong 'warehouse': {len(df)}")
    print(f"  - VIEWs ĐANG SỬ DỤNG (Active): {active_count}")
    print(f"  - VIEWs LÂU CHƯA QUERY / UNUSED: {unused_count}")
    print("==================================================================")

    # 5. Xuất Excel
    with pd.ExcelWriter(EXCEL_REPORT_PATH, engine='openpyxl') as writer:
        df.to_excel(writer, index=False, sheet_name='Warehouse Views Usage')

    print(f"\n[+] Đã xuất báo cáo Excel View Usage tại: {EXCEL_REPORT_PATH}")

if __name__ == '__main__':
    analyze_warehouse_views()
