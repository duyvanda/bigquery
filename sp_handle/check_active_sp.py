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
ACTIVE_JOB_FILE = r'd:\bigquery\sp_handle\call_active_job.md'
STAGING_TEMP_DIR = r'd:\bigquery\staging_temp'
EXCEL_OUTPUT_PATH = r'd:\bigquery\danh_sach_store_het_dung.xlsx'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH

def check_active_stores():
    """
    Rule Active SP = (Nằm trong call_active_job.md) AND (Có thực thi JOBS thực tế trong 180d).
    Các Store không thỏa mãn đồng thời cả 2 điều kiện sẽ được xếp vào danh sách STORE HẾT DÙNG.
    """
    client = bigquery.Client(project=PROJECT_ID)
    
    print("==========================================")
    print("PHÂN TÍCH STORED PROCEDURES (ACTIVE = CHẠY TRONG JOB + CÓ QUERY 180D)")
    print("==========================================\n")

    # 1. Đọc danh sách CALL từ call_active_job.md
    if not os.path.exists(ACTIVE_JOB_FILE):
        print(f"[!] Không tìm thấy file {ACTIVE_JOB_FILE}")
        return
        
    with open(ACTIVE_JOB_FILE, 'r', encoding='utf-8') as f:
        active_job_text = f.read()

    called_sps = set()
    for line in active_job_text.split('\n'):
        for c in line.split(';'):
            if 'CALL' in c.upper():
                parts = c.split('.')
                if len(parts) >= 2:
                    clean_name = re.sub(r'[^a-zA-Z0-9_]', '', parts[-1]).lower()
                    if clean_name:
                        called_sps.add(clean_name)
    
    print(f"1. THÔNG TIN ACTIVE JOB (call_active_job.md)")
    print(f"   - Tổng số Stored Procedures được kê khai: {len(called_sps)}")

    # 2. Truy vấn Lần cuối chạy (Last Used - 180d) từ BigQuery JOBS
    print("\n2. Đang đọc lịch sử thực thi (Last Used - 180 ngày) từ BigQuery JOBS...")
    sp_last_used = {}
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
    try:
        for row in client.query(query_jobs).result():
            if row.clean_sp:
                sp_last_used[row.clean_sp.lower()] = {
                    'last_used': row.last_used_time,
                    'total_calls': row.total_calls
                }
        print(f"   -> Đã ghi nhận {len(sp_last_used)} SPs có lịch sử thực thi thực tế trong 180d.")
    except Exception as e:
        print(f"   [!] Lỗi truy vấn JOBS: {e}")

    # 3. Lấy metadata (Created & Last Altered) từ INFORMATION_SCHEMA.ROUTINES
    print("\n3. Đang lấy Metadata (Created & Last Altered) từ INFORMATION_SCHEMA...")
    datasets = ['staging_temp', 'staging', 'warehouse']
    routine_meta = {}

    for ds in datasets:
        q_meta = f"""
        SELECT 
            routine_name,
            created,
            last_altered
        FROM `{PROJECT_ID}.{ds}.INFORMATION_SCHEMA.ROUTINES`
        """
        try:
            rows = list(client.query(q_meta).result())
            for r in rows:
                key = r.routine_name.lower()
                created_str = r.created.strftime('%Y-%m-%d %H:%M:%S') if r.created else ''
                altered_str = r.last_altered.strftime('%Y-%m-%d %H:%M:%S') if r.last_altered else ''
                routine_meta[key] = {
                    'created': created_str,
                    'last_altered': altered_str
                }
        except Exception as e:
            pass

    # 4. Quét các file .sql và phân loại Active vs Backup
    active_sql_files = glob.glob(os.path.join(STAGING_TEMP_DIR, 'active', '*.sql'))
    backup_sql_files = glob.glob(os.path.join(STAGING_TEMP_DIR, 'backup', '*.sql'))
    all_sql_files = active_sql_files + backup_sql_files

    print(f"\n4. Đối chiếu tổng số {len(all_sql_files)} file SQL SPs ({len(active_sql_files)} active, {len(backup_sql_files)} backup)...")

    unused_list = []
    active_list = []

    for sf in sorted(all_sql_files):
        filename = os.path.basename(sf)
        sp_name = os.path.splitext(filename)[0].lower()
        
        in_md = sp_name in called_sps
        job_data = sp_last_used.get(sp_name)
        has_jobs = job_data is not None
        
        # RULE KÉP: Active = (Nằm trong MD) AND (Có thực thi 180d)
        is_active = in_md and has_jobs
        
        file_size_kb = round(os.path.getsize(sf) / 1024, 2)
        meta = routine_meta.get(sp_name, {'created': 'N/A', 'last_altered': 'N/A'})
        
        last_used_str = job_data['last_used'].strftime('%Y-%m-%d %H:%M:%S') if has_jobs else 'Không gọi trong 180d'
        call_count = job_data['total_calls'] if has_jobs else 0
        
        item_data = {
            'Tên Stored Procedure': sp_name,
            'Tên File SQL': filename,
            'Nằm trong call_active_job.md': 'Có' if in_md else 'Không',
            'Lần cuối chạy (JOBS 180d)': last_used_str,
            'Số lượt chạy (180d)': call_count,
            'Ngày tạo (Created)': meta['created'],
            'Cập nhật lần cuối (Last Altered)': meta['last_altered'],
            'Kích thước File (KB)': file_size_kb,
            'Thư mục chứa': 'active/' if is_active else 'backup/'
        }
        
        if is_active:
            item_data['Trạng thái'] = 'Active (Đang chạy định kỳ)'
            active_list.append(item_data)
        else:
            if in_md and not has_jobs:
                item_data['Trạng thái'] = 'Hết dùng (Có trong MD nhưng 180d không chạy)'
            else:
                item_data['Trạng thái'] = 'Hết dùng (Không có trong Active Job)'
            unused_list.append(item_data)

    df_unused = pd.DataFrame(unused_list)
    df_unused.insert(0, 'STT', range(1, len(df_unused) + 1))

    print(f"\n================ TỔNG HỢP STORED PROCEDURES ================")
    print(f"Tổng số Stored Procedures local: {len(all_sql_files)}")
    print(f"  - Active SPs (Thỏa mãn ĐIỀU KIỆN KÉP): {len(active_list)}")
    print(f"  - Unused SPs (Hết dùng / Ngưng chạy): {len(df_unused)}")
    print("=============================================================\n")

    # 5. Ghi ra Excel
    out_file = EXCEL_OUTPUT_PATH
    try:
        if os.path.exists(out_file):
            os.remove(out_file)
    except Exception:
        out_file = r'd:\bigquery\danh_sach_store_het_dung_moi.xlsx'

    with pd.ExcelWriter(out_file, engine='openpyxl') as writer:
        df_unused.to_excel(writer, index=False, sheet_name='Store Hết Dùng')
        
        workbook = writer.book
        worksheet = writer.sheets['Store Hết Dùng']
        
        header_fill = PatternFill(start_color='1F4E79', end_color='1F4E79', fill_type='solid')
        header_font = Font(name='Segoe UI', size=11, bold=True, color='FFFFFF')
        header_align = Alignment(horizontal='center', vertical='center', wrap_text=True)
        
        thin_border = Border(
            left=Side(style='thin', color='D9D9D9'),
            right=Side(style='thin', color='D9D9D9'),
            top=Side(style='thin', color='D9D9D9'),
            bottom=Side(style='thin', color='D9D9D9')
        )
        
        for col_num, col_name in enumerate(df_unused.columns, 1):
            cell = worksheet.cell(row=1, column=col_num)
            cell.fill = header_fill
            cell.font = header_font
            cell.alignment = header_align
            
        worksheet.row_dimensions[1].height = 28
        
        data_font = Font(name='Segoe UI', size=10)
        center_align = Alignment(horizontal='center', vertical='center')
        left_align = Alignment(horizontal='left', vertical='center')
        right_align = Alignment(horizontal='right', vertical='center')
        zebra_fill = PatternFill(start_color='F9FAFB', end_color='F9FAFB', fill_type='solid')
        
        for row_num in range(2, len(df_unused) + 2):
            worksheet.row_dimensions[row_num].height = 20
            use_zebra = (row_num % 2 == 1)
            
            for col_num in range(1, len(df_unused.columns) + 1):
                cell = worksheet.cell(row=row_num, column=col_num)
                cell.font = data_font
                cell.border = thin_border
                if use_zebra:
                    cell.fill = zebra_fill
                    
                if col_num in [1, 3, 4, 5, 6, 7, 9, 10]:
                    cell.alignment = center_align
                elif col_num == 8:
                    cell.alignment = right_align
                    cell.number_format = '#,##0.00'
                elif col_num == 10:
                    cell.alignment = center_align
                    cell.font = Font(name='Segoe UI', size=10, color='C00000', italic=True)
                else:
                    cell.alignment = left_align
                    
        for col in worksheet.columns:
            max_len = max(len(str(cell.value or '')) for cell in col)
            col_letter = get_column_letter(col[0].column)
            worksheet.column_dimensions[col_letter].width = max(max_len + 4, 12)

    print(f"==========================================")
    print(f"[+] Đã xuất báo cáo Excel Store Hết Dùng tại: {out_file}")
    print(f"==========================================")

if __name__ == '__main__':
    check_active_stores()
