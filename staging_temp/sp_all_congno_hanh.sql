CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_all_congno_hanh()
BEGIN 


---ACG | MDS | Công 
-- Call  `spatial-vision-343005.staging_temp.sp_f_congno_rawdata_mds`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_congno_rawdata_cs_tm`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_daily_capture_notoihan_taixe_hanh`();

---ACG | MDS | Cảnh báo rủi ro công nợ
-- Call  `spatial-vision-343005.staging_temp.sp_f_canhbaoruiro_congno_mds`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_canhbaorruiro_congno_mds_k_goidau`();

---ACG | Raw data chi tiết công nợ bán hàng
-- Call  `spatial-vision-343005.staging_temp.sp_f_hanh_doisoatcongno`();

---ACG | MT | View Công Nợ - Kênh MT
-- Call  `spatial-vision-343005.staging_temp.sp_f_congno_rawdata_mt`();

End;