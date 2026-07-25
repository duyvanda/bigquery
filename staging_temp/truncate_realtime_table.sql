CREATE PROCEDURE `spatial-vision-343005`.staging_temp.truncate_realtime_table()
BEGIN 

TRUNCATE TABLE staging.f_distprogram;
TRUNCATE TABLE warehouse.f_ton_phan_bo_hang_hoa;

TRUNCATE TABLE `spatial-vision-343005.staging.f_sc_daily_invt_realtime`;
-- TRUNCATE TABLE `spatial-vision-343005.warehouse.f_baocao_tonkho_hangngay_realtime`;

TRUNCATE TABLE `warehouse.f_sales_crs_pending_v3_realtime`;
TRUNCATE TABLE `staging.sync_dms_so_don_treo`;
TRUNCATE TABLE `staging.sync_dms_pda_so_don_treo`;
TRUNCATE TABLE `staging.sync_dms_pda_sod_don_treo`;
TRUNCATE TABLE `staging.sync_dms_sod_don_treo`;

TRUNCATE TABLE `staging.get_crm_contract_v2_theo_user`;
TRUNCATE TABLE `warehouse.f_tonghopdata_hcp_pcl`;

-- TRUNCATE TABLE `staging.d_khao_sat_kh_truyen_thong_tp_q42023_theo_user`;
-- TRUNCATE TABLE `warehouse.f_khaosatkh_truyenthongmerrap_tp`;

-- TRUNCATE TABLE `staging.d_khao_sat_kh_truyen_thong_hcp_q42023_theo_user`;
-- TRUNCATE TABLE `warehouse.f_khaosatkh_truyenthongmerrap_hcp`;

TRUNCATE TABLE `staging.d_voucher_ctr_dulich`;
TRUNCATE TABLE `warehouse.f_voucher_dulich`;

TRUNCATE TABLE `staging.get_crm_contract_v2_theo_user`;
TRUNCATE TABLE `warehouse.f_tonghopdata_hcp_pcl`;

TRUNCATE TABLE `staging.get_crm_bv_contract_v2_theo_user`;
TRUNCATE TABLE `warehouse.f_tonghopdata_hcp_bv`;

TRUNCATE TABLE `staging.d_xnt_xtv_by_user`;
TRUNCATE TABLE `warehouse.f_mds_xnt_xuan_thinh_vuong`;

TRUNCATE TABLE `staging.d_ppc_bi_collectdiscitem_by_user`;
TRUNCATE TABLE `warehouse.f_rawdata_nhap_bb_thuhoi`;

TRUNCATE TABLE `warehouse.f_data_tracking_chi_phi_hco_by_users_realtime`;

TRUNCATE TABLE `staging.insert_data_vpp_by_users`;

TRUNCATE TABLE `staging.f_data_tracking_chi_phi_hco_by_users`;
TRUNCATE TABLE `warehouse.f_data_tracking_chi_phi_hco_by_users_realtime`;

TRUNCATE TABLE `staging.f_planning_collect_hcp_by_users`;

TRUNCATE TABLE `staging.f_answer_cmsp_by_users`;
TRUNCATE TABLE `staging.f_answer_cmsp_det_by_users`;

TRUNCATE TABLE `staging.f_sc_daily_raw_invt_by_users`;

TRUNCATE TABLE `staging.d_rawdata_mb_trans_by_users`;
-- TRUNCATE TABLE `staging.f_gm_answer_question_by_users`;

-- TRUNCATE TABLE `staging.f_form_seminar_by_users`;
TRUNCATE TABLE `staging.f_form_conference_by_users`;
-- TRUNCATE TABLE `staging.f_gm_flip_image_by_users`;

TRUNCATE TABLE `staging.f_data_tao_hcp_bv_by_users`;

TRUNCATE TABLE `staging.d_ge_data_order_by_users`;
--TRUNCATE TABLE `warehouse.view_d_ge_data_order`;

TRUNCATE TABLE `staging.f_form_data_log_by_users`;

TRUNCATE TABLE `staging.f_data_mds_tra_thuong_cmm_2025_by_users`;

End;