import os
import glob
import re
import sys
import pandas as pd
import pyarrow as pa
import pyarrow.csv as pv
from google.cloud import bigquery

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

CREDENTIALS_PATH = 'D:/bigquery1508.json'
PROJECT_ID = 'spatial-vision-343005'
DATASET_ID = 'staging'
STAGING_CSV_DIR = r'd:\bigquery\staging_table'

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

TARGET_22_TABLES = [
    'd_bi_collect_item_result',
    'd_dskh_mua_hang_sp_online',
    'd_dskh_mua_hang_sp_online_temp',
    'd_kpi_tan_tam',
    'd_manual_chuongtrinh_dulich_2023',
    'd_manual_danhsach_so_xe_loghub',
    'd_manual_duyet_cxm_tracking_chi_phi',
    'd_manual_gs_clc1clc2',
    'd_manual_gs_clc1clc2_quy032023',
    'd_manual_gs_clc3',
    'd_manual_gs_clc3_quy032023',
    'd_manual_gs_ntpp_quy032023',
    'd_manual_theo_doi_cpa74',
    'd_manual_toa_do_nt_long_chau_hn',
    'd_odoo_mua_hang_hoa_dich_vu',
    'd_report_name',
    'f_accumulatedresult_d',
    'f_check_table_dup_tonkho',
    'f_crawl_logqrcode',
    'f_crawl_order_ecom',
    'f_vipplus_c2_2023',
    'khc_theo_user'
]

def backup_and_drop_22():
    print("==========================================")
    print("SAO LƯU PYARROW CSV VÀ DROP 22 TABLES STAGING VỪA PHÁT HIỆN")
    print("==========================================\n")

    os.makedirs(STAGING_CSV_DIR, exist_ok=True)

    # BƯỚC 1: SAO LƯU CSV BẰNG PYARROW
    print("================ BƯỚC 1: SAO LƯU CSV BẰNG PYARROW ================")
    backed_up_tables = []
    
    for idx, t_name in enumerate(TARGET_22_TABLES, 1):
        csv_filename = f"{t_name}.csv"
        csv_path = os.path.join(STAGING_CSV_DIR, csv_filename)
        
        sql_select = f"SELECT * FROM `{PROJECT_ID}.{DATASET_ID}.{t_name}`"
        try:
            query_job = client.query(sql_select)
            arrow_table = query_job.to_arrow()
            
            pv.write_csv(arrow_table, csv_path)
            
            size_kb = round(os.path.getsize(csv_path) / 1024, 2)
            print(f"[BACKUP {idx}/{len(TARGET_22_TABLES)}] {t_name} -> {csv_filename} ({arrow_table.num_rows} rows, {size_kb} KB)")
            backed_up_tables.append(t_name)
        except Exception as e:
            print(f"[BACKUP ERROR] {t_name}: {e}")

    print(f"\n-> Hoàn tất sao lưu PyArrow: {len(backed_up_tables)}/{len(TARGET_22_TABLES)} tables được tạo CSV tại {STAGING_CSV_DIR}.\n")

    # BƯỚC 2: DROP TABLES ON BIGQUERY PRODUCTION
    print("================ BƯỚC 2: DROP TABLES ON BIGQUERY PRODUCTION ================")
    dropped_count = 0
    failed_count = 0

    for idx, t_name in enumerate(backed_up_tables, 1):
        drop_sql = f"DROP TABLE IF EXISTS `{PROJECT_ID}.{DATASET_ID}.{t_name}`;"
        try:
            client.query(drop_sql).result()
            dropped_count += 1
            print(f"[DROPPED {idx}/{len(backed_up_tables)}] {DATASET_ID}.{t_name}")
        except Exception as e:
            failed_count += 1
            print(f"[DROP FAILED] {t_name}: {e}")

    print(f"\n==========================================")
    print(f"HOÀN THÀNH DỌN DẸP 22 TABLES TRÊN STAGING!")
    print(f"- Số file CSV sao lưu thành công (PyArrow): {len(backed_up_tables)}")
    print(f"- Số tables DROP thành công: {dropped_count}")
    print(f"- Số tables DROP thất bại: {failed_count}")
    print(f"==========================================")

if __name__ == '__main__':
    backup_and_drop_22()
