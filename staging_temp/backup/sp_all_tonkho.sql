CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_all_tonkho()
BEGIN 

---Data tồn
-- CALL `spatial-vision-343005.staging_temp.sp_f_tonkhotonghop_daily`();

---CRM | Báo cáo tồn kho hằng ngày (SC và PBH)
-- Call  `spatial-vision-343005.staging_temp.sp_f_baocao_tonkho_hangngay_page_sanluong`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_baocao_tonkho_hangngay_page_tonkhotonghop`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_baocao_tonkho_hangngay_page_forecastdetail`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_baocao_tonkho_hangngay_page_tonkhotonghop2`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_canhbao_sales_fc`();


----SCN | Báo cáo tồn kho phục vụ sản xuất
-- Call  `spatial-vision-343005.staging_temp.sp_f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t1`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t2`();
-- Call  `spatial-vision-343005.staging_temp.sp_f_baocao_tonkho_phucvu_sanxuat_page_capture_t1`();
-- CALL `spatial-vision-343005.staging_temp.sp_f_baocao_tonkho_hangngay_page_forecastdetail`();

---SCN | Tồn kho âm theo lô, date
-- Call  `spatial-vision-343005.staging_temp.sp_f_tonkho_am_lodate`();

---SCN | Hàng tồn kho (CN) có date dưới 15 tháng
-- Call  `spatial-vision-343005.staging_temp.sp_f_hangtonkho_co_date_duoi15thang`();

---SCN | Rawdata Tồn kho daily
-- CALL `spatial-vision-343005.staging_temp.sp_f_rawdata_tonkho_daily`();

End;