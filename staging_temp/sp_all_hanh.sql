CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_all_hanh()
BEGIN 

--Mapping MDS
-- CALL `spatial-vision-343005.staging_temp.sp_f_baocao_daily_performance_mds_new_v2`();
-- CALL `spatial-vision-343005.staging_temp.sp_f_overview_mds_hanh1`();
-- -- CALL `spatial-vision-343005.staging_temp.sp_f_baocao_quantridichvugiaohang_v2`();
-- CALL `spatial-vision-343005.staging_temp.sp_f_doanhso_tinhluonghieuqua_mds`();

-- ----MDS | Quản trị dịch vụ giao hàng
-- Call  `spatial-vision-343005.staging_temp.sp_f_baocao_quantridichvugiaohang_v2`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_data_checkin_mds`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_quantridichvugiaohang_page_leadtime`();

---MDS | Thông tin tọa độ ghi nhận (giao, bán)
-- Call  `spatial-vision-343005.staging_temp.sp_f_data_checkin_mds_saitoado`();

---MDS | Danh sách khách hàng kết nối Zalo OA
-- Call  `spatial-vision-343005.staging_temp.sp_f_danhsach_khachhangzalo`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_phantich_khachhangzalo`();

---MDS | Số liệu vận hành giao hàng bằng ô tô
-- Call  `spatial-vision-343005.staging_temp.sp_f_solieu_vanhanh_giaohang_bang_oto`();
---MDS | MDS Performance
-- Call  `spatial-vision-343005.staging_temp.sp_f_mds_performance`();

---MDS | Bán theo tuyến
-- Call  `spatial-vision-343005.staging_temp.sp_f_ban_theotuyen`();

---MDS | 3PL Leadtime
-- Call  `spatial-vision-343005.staging_temp.sp_f_3pl_donhang`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_3pl_delivery`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_d_vnpost_postedorders`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_d_crawl_logpharma`();

---MDS | Hà Nam - Ninh Bình - Nam Định
-- Call  `spatial-vision-343005.staging_temp.sp_f_hanam_ninhbinh_ct_tichluy`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_hub`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_hub_2`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_hub_3`();
-- CALL `spatial-vision-343005.staging_temp.sp_f_khmomoi_duanhub`();

---MDS | Delivery Geo Map
-- Call  `spatial-vision-343005.staging_temp.sp_f_delivery_geo_map`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_delivery_geo_map_page2`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_delivery_geo_map_page3`();

--- CRM | MD | Báo cáo mở mới KH
-- CALL `spatial-vision-343005.staging_temp.sp_f_danhsachmomoi_teammd_new`();

-- CRM | HCP | Báo cáo mở mới PCL 2023
-- CALL `spatial-vision-343005.staging_temp.sp_f_danhsachmomoi_kenhhcp`(); 

END;