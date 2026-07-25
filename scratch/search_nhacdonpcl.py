import os
import glob
import sys
from google.cloud import bigquery

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
terms = ['d_nhacdonpcl', 'nhacdonpcl', 'nhacdon_pcl']

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

print(f"==========================================")
print(f"TÌM KIẾM CHI TIẾT TỪ KHÓA: {terms}")
print(f"==========================================\n")

# 1. Kiểm tra BigQuery Object Metadata
print("1. KIỂM TRA TRÊN BIGQUERY (OBJECT NAME):")
for term in terms:
    query_check = f"""
    SELECT table_catalog, table_schema, table_name, table_type 
    FROM `spatial-vision-343005.region-asia-southeast1.INFORMATION_SCHEMA.TABLES`
    WHERE LOWER(table_name) LIKE '%{term.lower()}%'
    """
    try:
        rows = list(client.query(query_check).result())
        if rows:
            print(f" -> Tìm thấy Object cho từ khóa '{term}':")
            for r in rows:
                print(f"    - Dataset: {r.table_schema} | Object: {r.table_name} ({r.table_type})")
    except Exception as e:
        print(f" -> Lỗi query BigQuery TABLES: {e}")

# 2. Kiểm tra trong tất cả VIEW .sql files
print("\n2. TÌM KIẾM TRONG NỘI DUNG TẤT CẢ FILE VIEW (.sql):")
view_files = glob.glob(r'd:\bigquery\warehouse_view\*.sql') + glob.glob(r'd:\bigquery\warehouse\*.sql')

for term in terms:
    view_refs = set()
    for vf in view_files:
        v_name = os.path.basename(vf)
        with open(vf, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read().lower()
        if term.lower() in content:
            view_refs.add((v_name, vf))

    if view_refs:
        print(f" -> Từ khóa '{term}' xuất hiện trong {len(view_refs)} View:")
        for v_name, vf in sorted(list(view_refs)):
            print(f"    - {v_name}")
            with open(vf, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
                for l_idx, line in enumerate(lines, 1):
                    if term.lower() in line.lower():
                        print(f"      └─ Dòng {l_idx}: {line.strip()[:150]}")

# 3. Kiểm tra trong tất cả Stored Procedure .sql files
print("\n3. TÌM KIẾM TRONG NỘI DUNG TẤT CẢ FILE STORED PROCEDURE (.sql):")
sp_files = glob.glob(r'd:\bigquery\staging_temp\*.sql') + glob.glob(r'd:\bigquery\sp_handle\*.sql')

for term in terms:
    sp_refs = set()
    for sf in sp_files:
        s_name = os.path.basename(sf)
        with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read().lower()
        if term.lower() in content:
            sp_refs.add((s_name, sf))

    if sp_refs:
        print(f" -> Từ khóa '{term}' xuất hiện trong {len(sp_refs)} Stored Procedure:")
        for s_name, sf in sorted(list(sp_refs)):
            print(f"    - {s_name}")
            with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
                lines = f.readlines()
                for l_idx, line in enumerate(lines, 1):
                    if term.lower() in line.lower():
                        print(f"      └─ Dòng {l_idx}: {line.strip()[:150]}")
