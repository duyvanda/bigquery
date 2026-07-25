import os
import glob
import sys
from google.cloud import bigquery

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
term = 'chuanhoa_phaply_dmtt'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

print(f"==========================================")
print(f"TÌM KIẾM CHI TIẾT CHUỖI: '{term}'")
print(f"==========================================\n")

# 1. Kiểm tra BigQuery Object Metadata
print("1. KIỂM TRA TRÊN BIGQUERY (OBJECT NAME):")
query_check = f"""
SELECT table_catalog, table_schema, table_name, table_type 
FROM `spatial-vision-343005.region-asia-southeast1.INFORMATION_SCHEMA.TABLES`
WHERE LOWER(table_name) LIKE '%{term.lower()}%'
"""
try:
    rows = list(client.query(query_check).result())
    if rows:
        print(" -> Tìm thấy Object tên tương tự trên BigQuery:")
        for r in rows:
            print(f"    - Dataset: {r.table_schema} | Object: {r.table_name} ({r.table_type})")
    else:
        print(" -> Không có Table/View nào tên này trên BigQuery.")
except Exception as e:
    print(f" -> Lỗi query BigQuery TABLES: {e}")

# 2. Kiểm tra trong tất cả VIEW .sql files
print("\n2. TÌM KIẾM TRONG NỘI DUNG TẤT CẢ FILE VIEW (.sql):")
view_files = glob.glob(r'd:\bigquery\warehouse_view\*.sql') + glob.glob(r'd:\bigquery\warehouse\*.sql')
view_refs = set()

for vf in view_files:
    v_name = os.path.basename(vf)
    with open(vf, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read().lower()
    if term.lower() in content:
        view_refs.add((v_name, vf))

if view_refs:
    print(f" -> Tìm thấy '{term}' được sử dụng trong {len(view_refs)} View:")
    for v_name, vf in sorted(list(view_refs)):
        print(f"    - {v_name}")
        # In ra dòng cụ thể có chứa từ khóa này
        with open(vf, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
            for l_idx, line in enumerate(lines, 1):
                if term.lower() in line.lower():
                    print(f"      └─ Dòng {l_idx}: {line.strip()[:150]}")
else:
    print(f" -> Không tìm thấy '{term}' trong bất kỳ file VIEW nào.")

# 3. Kiểm tra trong tất cả Stored Procedure .sql files
print("\n3. TÌM KIẾM TRONG NỘI DUNG TẤT CẢ FILE STORED PROCEDURE (.sql):")
sp_files = glob.glob(r'd:\bigquery\staging_temp\*.sql') + glob.glob(r'd:\bigquery\sp_handle\*.sql')
sp_refs = set()

for sf in sp_files:
    s_name = os.path.basename(sf)
    with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read().lower()
    if term.lower() in content:
        sp_refs.add((s_name, sf))

if sp_refs:
    print(f" -> Tìm thấy '{term}' được sử dụng trong {len(sp_refs)} Stored Procedure:")
    for s_name, sf in sorted(list(sp_refs)):
        print(f"    - {s_name}")
        with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
            for l_idx, line in enumerate(lines, 1):
                if term.lower() in line.lower():
                    print(f"      └─ Dòng {l_idx}: {line.strip()[:150]}")
else:
    print(f" -> Không tìm thấy '{term}' trong bất kỳ file Stored Procedure nào.")
