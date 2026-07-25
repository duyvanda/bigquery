import os
import glob
import re
import sys
import pandas as pd
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
from google.cloud import bigquery

# Thiet lap UTF-8 output cho Windows Console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
ACTIVE_JOB_FILE = r'd:\bigquery\call_active_job.md'
STAGING_TEMP_DIR = r'd:\bigquery\staging_temp'
EXCEL_OUTPUT_PATH = r'd:\bigquery\danh_sach_store_het_dung.xlsx'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH

def check_active_stores():
    """
    Kiểm tra danh sách các Store HẾT DÙNG (Không có trong call_active_job.md)
    và xuất báo cáo Excel (danh_sach_store_het_dung.xlsx) kèm thời gian 
    Created, Last Altered và Last Used (180d).
    """
    client = bigquery.Client(project=PROJECT_ID)
    
    # 1. Đọc danh sách CALL từ call_active_job.md
    if not os.path.exists(ACTIVE_JOB_FILE):
        print(f"[!] Không tìm thấy file {ACTIVE_JOB_FILE}")
        return
        
    with open(ACTIVE_JOB_FILE, 'r', encoding='utf-8') as f:
        active_job_text = f.read()

    raw_calls = re.findall(r'CALL\s+`?([^`()\s;]+)`?', active_job_text, re.IGNORECASE)
    called_routine_names = set(call_str.split('.')[-1].strip() for call_str in raw_calls if call_str.split('.')[-1].strip())
    
    print(f"==========================================")
    print(f"1. THÔNG TIN ACTIVE JOB ({os.path.basename(ACTIVE_JOB_FILE)})")
    print(f"   - Tổng số câu lệnh CALL tìm thấy: {len(raw_calls)}")
    print(f"   - Số Routine độc lập được gọi: {len(called_routine_names)}")
    print(f"==========================================\n")

    # 2. Truy vấn Lần cuối chạy (Last Used - 180d) từ BigQuery JOBS (Server-side Group By)
    print("2. Đang đọc lịch sử thực thi (Last Used - 180 ngày) từ BigQuery JOBS...")
    sp_last_used = {}
    query_jobs = """
    SELECT 
        REGEXP_EXTRACT(query, r'(?i)CALL\s+`?(?:[\w\-]+\.)?(?:[\w\-]+\.)?([\w]+)`?') AS clean_sp,
        MAX(creation_time) AS last_used_time
    FROM `region-asia-southeast1`.INFORMATION_SCHEMA.JOBS
    WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 180 DAY)
      AND (LOWER(query) LIKE '%call%' OR statement_type = 'CALL')
    GROUP BY clean_sp
    HAVING clean_sp IS NOT NULL
    """
    try:
        for row in client.query(query_jobs).result():
            sp_last_used[row.clean_sp] = row.last_used_time
        print(f"   -> Đã ghi nhận thời gian Last Used cho {len(sp_last_used)} procedure/function.")
    except Exception as e:
        print(f"   [!] Lỗi truy vấn JOBS: {e}")

    # 3. Lấy metadata (Created & Last Altered) từ INFORMATION_SCHEMA.ROUTINES
    print("\n3. Đang lấy Metadata (Created & Last Altered) từ INFORMATION_SCHEMA...")
    datasets = ['staging_temp', 'staging', 'warehouse', 'f']
    routine_meta = {}

    for ds in datasets:
        q_meta = f"""
        SELECT 
            routine_name,
            routine_type,
            created,
            last_altered
        FROM `{PROJECT_ID}.{ds}.INFORMATION_SCHEMA.ROUTINES`
        """
        try:
            rows = list(client.query(q_meta).result())
            for r in rows:
                key = (ds, r.routine_name)
                created_str = r.created.strftime('%Y-%m-%d %H:%M:%S') if r.created else ''
                altered_str = r.last_altered.strftime('%Y-%m-%d %H:%M:%S') if r.last_altered else ''
                routine_meta[key] = {
                    'created': created_str,
                    'last_altered': altered_str
                }
        except Exception as e:
            print(f"   [!] Lỗi đọc dataset '{ds}': {e}")

    # 4. Quét các file .sql và lọc danh sách STORE HẾT DÙNG
    sql_files = glob.glob(os.path.join(STAGING_TEMP_DIR, '*.sql'))
    print(f"\n4. Đang đối chiếu với {len(sql_files)} file .sql trong thư mục '{STAGING_TEMP_DIR}'...")

    unused_list = []

    for sf in sorted(sql_files):
        filename = os.path.basename(sf)
        r_name = filename[:-4]
        
        ds_name = 'staging_temp'
        clean_sp_name = r_name
        
        for prefix in ['warehouse_', 'staging_', 'f_']:
            if r_name.startswith(prefix):
                ds_name = prefix[:-1]
                clean_sp_name = r_name[len(prefix):]
                break
                
        is_active = (r_name in called_routine_names) or (clean_sp_name in called_routine_names)
        
        # Chỉ lấy các Store HẾT DÙNG (Không có trong Active Job)
        if not is_active:
            file_size_kb = round(os.path.getsize(sf) / 1024, 2)
            meta = routine_meta.get((ds_name, clean_sp_name), {'created': 'N/A', 'last_altered': 'N/A'})
            
            dt_used = sp_last_used.get(clean_sp_name) or sp_last_used.get(r_name)
            last_used_str = dt_used.strftime('%Y-%m-%d %H:%M:%S') if dt_used else 'Không chạy trong 180 ngày qua'
            
            unused_list.append({
                'STT': len(unused_list) + 1,
                'Tên Procedure / Routine': clean_sp_name,
                'Dataset': ds_name,
                'Tên File SQL': filename,
                'Ngày tạo (Created)': meta['created'],
                'Cập nhật lần cuối (Last Altered)': meta['last_altered'],
                'Lần cuối chạy (Last Used - 180d)': last_used_str,
                'Kích thước File (KB)': file_size_kb,
                'Trạng thái': 'Hết dùng / Không gọi trong Active Job'
            })

    df = pd.DataFrame(unused_list)
    
    print(f"\n================ SUMMARY RESULTS ================")
    print(f"Tổng số Store Hết Dùng: {len(df)}")
    print(f"=================================================\n")

    # 5. Ghi ra Excel với định dạng giao diện chuyên nghiệp
    out_file = EXCEL_OUTPUT_PATH
    try:
        if os.path.exists(out_file):
            os.remove(out_file)
    except Exception:
        out_file = r'd:\bigquery\danh_sach_store_het_dung_moi.xlsx'

    with pd.ExcelWriter(out_file, engine='openpyxl') as writer:
        df.to_excel(writer, index=False, sheet_name='Store Hết Dùng')
        
        workbook = writer.book
        worksheet = writer.sheets['Store Hết Dùng']
        
        # Header style (Navy Blue #1F4E79, font trắng, chữ đậm)
        header_fill = PatternFill(start_color='1F4E79', end_color='1F4E79', fill_type='solid')
        header_font = Font(name='Segoe UI', size=11, bold=True, color='FFFFFF')
        header_align = Alignment(horizontal='center', vertical='center', wrap_text=True)
        
        thin_border = Border(
            left=Side(style='thin', color='D9D9D9'),
            right=Side(style='thin', color='D9D9D9'),
            top=Side(style='thin', color='D9D9D9'),
            bottom=Side(style='thin', color='D9D9D9')
        )
        
        for col_num, col_name in enumerate(df.columns, 1):
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
        
        for row_num in range(2, len(df) + 2):
            worksheet.row_dimensions[row_num].height = 20
            use_zebra = (row_num % 2 == 1)
            
            for col_num in range(1, len(df.columns) + 1):
                cell = worksheet.cell(row=row_num, column=col_num)
                cell.font = data_font
                cell.border = thin_border
                if use_zebra:
                    cell.fill = zebra_fill
                    
                if col_num in [1, 3, 5, 6, 7]:
                    cell.alignment = center_align
                elif col_num == 8:
                    cell.alignment = right_align
                elif col_num == 9:
                    cell.alignment = center_align
                    cell.font = Font(name='Segoe UI', size=10, color='C00000', italic=True)
                else:
                    cell.alignment = left_align
                    
        for col in worksheet.columns:
            max_len = max(len(str(cell.value or '')) for cell in col)
            col_letter = get_column_letter(col[0].column)
            worksheet.column_dimensions[col_letter].width = max(max_len + 4, 12)

    print(f"==========================================")
    print(f"[+] Đã xuất báo cáo Excel thành công tại: {out_file}")
    print(f"==========================================")

if __name__ == '__main__':
    check_active_stores()
