import os
import sys
from google.cloud import bigquery

# Thiet lap UTF-8 output cho Windows Console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
DATASET_ID = 'warehouse'
OUTPUT_DIR = r'd:\bigquery\warehouse'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH

def export_all_warehouse_views():
    """
    Tự động kết nối BigQuery, lấy tất cả các VIEW trong dataset 'warehouse'
    và xuất mỗi VIEW thành 1 file .sql riêng biệt trong thư mục d:\bigquery\warehouse.
    """
    client = bigquery.Client(project=PROJECT_ID)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    print(f"Đang kết nối BigQuery để lấy danh sách VIEW trong dataset '{DATASET_ID}'...")
    
    query = f"""
    SELECT 
        table_name,
        table_type,
        ddl
    FROM `{PROJECT_ID}.{DATASET_ID}.INFORMATION_SCHEMA.TABLES`
    WHERE table_type = 'VIEW'
    """
    
    try:
        query_job = client.query(query)
        rows = list(query_job.result())
        print(f"[+] Tìm thấy tổng cộng {len(rows)} VIEWs trong dataset '{DATASET_ID}'.\n")
        
        exported_count = 0
        
        for row in rows:
            v_name = row.table_name
            ddl_content = row.ddl
            
            if not ddl_content:
                print(f"  └─ Warning: View '{v_name}' không có nội dung DDL.")
                continue
                
            file_name = f"{v_name}.sql"
            file_path = os.path.join(OUTPUT_DIR, file_name)
            
            # Ghi nội dung DDL của VIEW với mã hóa UTF-8
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(ddl_content)
                
            exported_count += 1
            
        print(f"==========================================")
        print(f"Đã xuất thành công {exported_count} file .sql cho VIEWs vào: {OUTPUT_DIR}")
        print(f"==========================================")
        
    except Exception as e:
        print(f"[!] Lỗi khi truy vấn VIEWs từ dataset '{DATASET_ID}': {e}")

if __name__ == '__main__':
    export_all_warehouse_views()
