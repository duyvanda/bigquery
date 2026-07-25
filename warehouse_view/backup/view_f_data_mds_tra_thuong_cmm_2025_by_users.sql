CREATE VIEW `spatial-vision-343005.warehouse.view_f_data_mds_tra_thuong_cmm_2025_by_users`
AS SELECT 
a.ten_sup,
a.ma_nv,
a.ten_nv,
a.ma_oa,
a.ma_kh_dms,
a.ten_kh,
a.trang_thai_tra_thuong,
a.ma_qua,
a.ten_qua,
a.sl,
a.inserted_at,
a.img_0,
a.img_1,
a.img_2,
a.sl_hinh,
a.p_manv,
a.p_version,
b.channel,
b.territorydescr,
b.statedescr
FROM `spatial-vision-343005.staging.f_data_mds_tra_thuong_cmm_2025_by_users` a
LEFT JOIN spatial-vision-343005.staging.d_master_khachhang b ON a.ma_kh_dms = b.custid;