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
MAX_BYTES = 10 * 1024 * 1024 # 10 MB limit

os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = CREDENTIALS_PATH
client = bigquery.Client(project=PROJECT_ID)

# 96 TRULY UNUSED TABLES
TRULY_UNUSED_96 = [
    'd_bq_daily_rawdata_debt', 'd_cum_tinh_quan_huyen', 'd_dang_ky_nghi_phep_co_ly_do_pkh_by_user',
    'd_danh_muc_vat_tu_ge', 'd_danh_sach_gui_mail_hang_tra_lai', 'd_danh_sach_qua_tang_tracking_chi_phi_hcp',
    'd_data_hoa_don_claim_chi_phi_kt', 'd_delivery_eom_overload', 'd_display_criteria_remark_temp',
    'd_dm_nvl_bbi_copy', 'd_dm_tai_san', 'd_ds_100kh_ambassador', 'd_ebystaregis_2023',
    'd_eleven_list_conversations_temp', 'd_form_ghi_nhan_ngay_xuat_hoa_don_kim_do', 'd_form_ktttthbb_phan_hoi',
    'd_form_phan_hoi_kim_do', 'd_full_lt_tinh_quan_huyen', 'd_ge_data_order_temp', 'd_giaitrinh_thbb_mds',
    'd_google_sheets_contracts_bv', 'd_hang_kich_nhap_truoc', 'd_hcp_listing', 'd_hr_dsns_bytime_copy',
    'd_kt_replaced_invoice', 'd_kt_thuhoi_dccn_old', 'd_lab_cdkt', 'd_lab_kqkd', 'd_leadtimekpi_bytime',
    'd_manual_bhsx_syt_2024', 'd_manual_bienban_nghiemthu_hcp_2023', 'd_manual_clc_thu_hoi_hop_dong_temp',
    'd_manual_d_kehoachsanxuat_thang_temp', 'd_manual_d_quycachdonghop', 'd_manual_danh_gia_kpi_mt_bytime',
    'd_manual_danhsach_kh_pcl_datra_momoi', 'd_manual_danhsach_theodoi_ntpp', 'd_manual_data_nvc',
    'd_manual_ds_kh_stiker_ladoi', 'd_manual_gs_ctkm_csbh', 'd_manual_gs_diem_phu_san_pham_khvip',
    'd_manual_gs_dskh_tham_gia_poster_binh_on_gia_2025', 'd_manual_gs_dskh_vip_tp_da_duyet_2025_temp',
    'd_manual_gs_ho_tro_thao_tac_su_co', 'd_manual_gs_thong_tin_san_pham', 'd_manual_kt_bb_thu_hoi_no',
    'd_manual_slpp_online_t7_2024', 'd_manual_slpp_online_t7_2024_detail', 'd_manual_so_chuyen_noi_bo_mds',
    'd_manual_th_kh_thu_hoi_team_thau', 'd_manual_theo_doi_doanh_so_kh_vip_tp74cpa',
    'd_manual_toa_do_crs_mcp_thap', 'd_manual_tong_hop_quy_dinh_cs_mai_phuong_no_split',
    'd_master_custhis', 'd_mds_upload_hinh_anh_bbgh_updated', 'd_nguyen_lieu_lam_thuoc',
    'd_onetricks_tft', 'd_rawdata_mb_trans_by_users_ref_1773713572741', 'd_sync_dms_cust_his_temp',
    'd_sync_rptrunning', 'd_taxrate', 'd_thong_tin_cai_dat_bi_qt_gim_duy_crm',
    'd_thong_tin_cai_dat_bi_qt_gim_duy_hcp', 'd_tinh_copy', 'd_tinh_thuong_ban_hang_rc',
    'd_xuatnhapton1208_copy', 'danh_sach_target_mds', 'f_check_congnodaily',
    'f_chitiet_gia_mt_tai_cuahang_temp', 'f_ge_chi_phi_temp', 'f_ge_lich_su_mua_2022',
    'f_ge_lich_su_mua_2023', 'f_nhap_mua_ge', 'f_orddisc_temp', 'f_pxkkvcnb_temp',
    'f_sales_t32025_t42025', 'f_sales_updated', 'file', 'hr_nguoi_phu_thuoc', 'invt_max_lo',
    'ocr_delivery_record_nvc_by_users', 'odoo_danh_sach_giai_doan', 'odoo_qc_kiem_nghiem',
    'odoo_sx_lenh_san_xuat', 'odoo_translation', 'odoo_xu_ly_lich_su_phe_duyet', 'pda_7_day',
    'planning_collect_hcp_gm_by_users', 'sync_dms_lt_t6t7', 'sync_dms_oc_cp',
    'sync_dms_pda_sod_7_day', 'sync_dms_salesroutedet_3dayago', 'sync_dms_sod1_updated',
    'tong_ket_tich_luy_Q12025_CLC2', 'tong_ket_tich_luy_Q12025_CLC3', 'tong_ket_tich_luy_Q12025_NTPP'
]

def backup_and_drop_96():
    print("==========================================")
    print("SAO LƯU PYARROW CSV (<10MB) & DROP 96 TABLES UNUSED TRÊN STAGING")
    print("==========================================\n")

    os.makedirs(STAGING_CSV_DIR, exist_ok=True)

    # 1. BƯỚC 1: SAO LƯU CSV BẰNG PYARROW CHỈ CHO TABLES < 10MB
    print("================ BƯỚC 1: SAO LƯU CSV (TABLES < 10MB) ================")
    backed_up_count = 0
    skipped_count = 0

    for idx, t_name in enumerate(TRULY_UNUSED_96, 1):
        try:
            t_obj = client.get_table(f"{PROJECT_ID}.{DATASET_ID}.{t_name}")
            t_bytes = t_obj.num_bytes or 0
            size_mb = round(t_bytes / (1024 * 1024), 2)
            
            if t_bytes >= MAX_BYTES:
                print(f"[SKIP >= 10MB {idx}/{len(TRULY_UNUSED_96)}] {t_name} ({size_mb} MB) -> Bỏ qua CSV.")
                skipped_count += 1
                continue
                
            csv_filename = f"{t_name}.csv"
            csv_path = os.path.join(STAGING_CSV_DIR, csv_filename)
            
            # Nếu file CSV đã được tạo sẵn trước đó -> Bỏ qua không tải lại
            if os.path.exists(csv_path) and os.path.getsize(csv_path) > 0:
                size_kb = round(os.path.getsize(csv_path) / 1024, 2)
                print(f"[CSV EXISTS {idx}/{len(TRULY_UNUSED_96)}] {t_name} -> {csv_filename} ({size_kb} KB)")
                backed_up_count += 1
                continue

            sql_select = f"SELECT * FROM `{PROJECT_ID}.{DATASET_ID}.{t_name}`"
            query_job = client.query(sql_select)
            arrow_table = query_job.to_arrow()
            
            pv.write_csv(arrow_table, csv_path)
            size_kb = round(os.path.getsize(csv_path) / 1024, 2)
            print(f"[BACKUP <10MB {idx}/{len(TRULY_UNUSED_96)}] {t_name} -> {csv_filename} ({size_kb} KB)")
            backed_up_count += 1
            
        except Exception as e:
            print(f"[SKIP / NOT FOUND {idx}/{len(TRULY_UNUSED_96)}] {t_name}: {e}")
            skipped_count += 1

    print(f"\n-> Hoàn tất sao lưu PyArrow: {backed_up_count} tables có CSV, {skipped_count} tables bỏ qua/không tìm thấy.\n")

    # 2. BƯỚC 2: DROP ALL 96 TABLES ON BIGQUERY PRODUCTION
    print("================ BƯỚC 2: DROP 96 TABLES ON BIGQUERY PRODUCTION ================")
    dropped_count = 0
    failed_count = 0

    for idx, t_name in enumerate(TRULY_UNUSED_96, 1):
        drop_sql = f"DROP TABLE IF EXISTS `{PROJECT_ID}.{DATASET_ID}.{t_name}`;"
        try:
            client.query(drop_sql).result()
            dropped_count += 1
            print(f"[DROPPED {idx}/{len(TRULY_UNUSED_96)}] {DATASET_ID}.{t_name}")
        except Exception as e:
            failed_count += 1
            print(f"[DROP FAILED] {t_name}: {e}")

    print(f"\n==========================================")
    print(f"HOÀN THÀNH XÓA 96 TABLES TRÊN STAGING!")
    print(f"- Số file CSV được lưu (<10MB): {backed_up_count}")
    print(f"- Số tables DROP thành công: {dropped_count}")
    print(f"- Số tables DROP thất bại: {failed_count}")
    print(f"==========================================")

if __name__ == '__main__':
    backup_and_drop_96()
