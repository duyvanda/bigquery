CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_all()
BEGIN 

--- Sales 
-- CALL `spatial-vision-343005.staging_temp.sp_sales`();

-- CALL `spatial-vision-343005.staging_temp.sp_sales_hanh`();

-- CALL `spatial-vision-343005.staging_temp.sp_sales_lhq_bytime`();

-- CALL `spatial-vision-343005.staging_temp.sp_f_raw_data_sales_yoy`();

---CRM | Sales Performance
-- Call  `spatial-vision-343005.staging_temp.sp_f_donhang_ecom`();
-- Call `spatial-vision-343005.staging_temp.sp_f_sales_crs_pending_v3`();

-- Call  `spatial-vision-343005.staging_temp.sp_f_accumulated_progress`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_chuongtrinh_dulich_2023`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_chuongtrinh_dulich_pcl_2023`();
-- CALL `spatial-vision-343005.staging_temp.sp_f_chuongtrinh_tichluy_clc123`();
-- CALL `spatial-vision-343005.staging_temp.sp_f_chuongtrinh_tichluy_ntpp`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_chuongtrinh_quatang_hethu_pcl`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_chuongtrinh_quatang_hethu_tp`();

-- Call  `spatial-vision-343005.staging_temp.sp_f_kh_thamgia_trungbay_decal2023`();

-- Call  `spatial-vision-343005.staging_temp.sp_f_sales_performance_thongtin_phaply`();
-- Call `spatial-vision-343005.staging_temp.sp_f_thoathuan_muaban`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_thoathuanmuaban_dachot`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_tongquan_hcp`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_trungbay_ebysta`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_viengtham_hcp`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_viplus_trading`();
-- CALL `spatial-vision-343005.staging_temp.sp_data_checkin_pbh`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_data_checkin_pbh_v2`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_sales_performance_sales_mtd`();


---GD | Theo dõi đơn hàng Ecommerce
-- Call  `spatial-vision-343005.staging_temp.sp_f_d_donhang_ecom`();

---PO | Theo dõi đơn hàng Ecommerce
-- CALL `spatial-vision-343005.staging_temp.sp_f_o_donhang_ecom`();

----CRM | Tra cứu doanh số, sản lượng của khách hàng
-- Call  `spatial-vision-343005.staging_temp.sp_f_sales_client_performance`();

---CRM | Doanh số, sản lượng theo khách hàng
-- Call  `spatial-vision-343005.staging_temp.sp_f_doanhso_sanluong_theokhachhang`();

---CRM | Sales Report - Mobile
-- CALL `spatial-vision-343005.staging_temp.sp_f_sales_report_mobile`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_sales_report_mobile_daily`();

---CRM | Báo cáo LHQ - ALL
-- Call  `spatial-vision-343005.staging_temp.sp_f_luonghieuqua_crs`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_luonghieuqua_crm`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_luonghieuqua_ncrm`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_luonghieuqua_chitam`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_luonghieuqua_data_am`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_luonghieuqua_hongthuy`();

-- Call  `spatial-vision-343005.staging_temp.sp_f_baocao_lhq_md_new`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_luonghieuqua_mds`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_luonghieuqua_all`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_thuongquy_mds`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_tinhthuong_danhgia_quy_crs`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_tinhthuong_danhgia_quy_crm`();

-- Call  `spatial-vision-343005.staging_temp.sp_f_tinhthuong_danhgia_quy_all`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_tinhthuong_danhgia_quy_all_portal`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_luonghieuqua_all_portal`();

---CRM | Đơn hàng theo giờ
-- Call  `spatial-vision-343005.staging_temp.sp_f_donhang_theogio`();

END;