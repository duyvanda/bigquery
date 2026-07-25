import os
import sys
from google.cloud import bigquery

# Thiet lap stdout encoding cho Windows console
if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

# Cau hinh duong dan file chung thuc va project ID
CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
OUTPUT_DIR = r'd:\bigquery\staging_temp'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH

def export_all_stored_procedures():
    """
    Tự động kết nối BigQuery, duyệt qua tất cả datasets trong project,
    lấy ra DDL của toàn bộ Stored Procedure / Function / Routine
    và lưu thành các file .sql độc lập trong thư mục staging_temp.
    """
    client = bigquery.Client(project=PROJECT_ID)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    datasets = [d.dataset_id for d in client.list_datasets()]
    print(f"Tim thấy {len(datasets)} datasets trong project '{PROJECT_ID}': {datasets}\n")
    
    total_exported = 0
    saved_filenames = set()
    
    for ds in datasets:
        query = f"""
        SELECT 
            routine_catalog,
            routine_schema,
            routine_name,
            routine_type,
            routine_definition,
            ddl
        FROM `{PROJECT_ID}.{ds}.INFORMATION_SCHEMA.ROUTINES`
        """
        try:
            query_job = client.query(query)
            rows = list(query_job.result())
            
            if not rows:
                print(f"[-] Dataset '{ds}': Khong co routine nao.")
                continue
                
            print(f"[+] Dataset '{ds}': Lay ra {len(rows)} routines...")
            
            for row in rows:
                r_name = row.routine_name
                sql_content = row.ddl if row.ddl else row.routine_definition
                
                if not sql_content:
                    print(f"  └─ Warning: Routine '{ds}.{r_name}' khong co noi dung DDL.")
                    continue
                
                # Xuly ten file de tranh trung lap giua cac dataset
                file_name = f"{r_name}.sql"
                if file_name in saved_filenames:
                    file_name = f"{ds}_{r_name}.sql"
                
                saved_filenames.add(file_name)
                file_path = os.path.join(OUTPUT_DIR, file_name)
                
                # Ghi noi dung DDL ra file .sql voi ma hoa UTF-8
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(sql_content)
                
                total_exported += 1
                
        except Exception as e:
            print(f"[!] Loi khi truy van dataset '{ds}': {e}")
            
    print(f"\n==========================================")
    print(f"Da xuat thanh cong {total_exported} file .sql vao thu muc: {OUTPUT_DIR}")
    print(f"==========================================")

if __name__ == '__main__':
    export_all_stored_procedures()
