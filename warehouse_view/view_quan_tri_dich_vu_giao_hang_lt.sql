CREATE VIEW `spatial-vision-343005.warehouse.view_quan_tri_dich_vu_giao_hang_lt`
AS SELECT
sodondathang,
ngaychungtu,
tenkhachhang,
tentinhkh,
makenhkh,
makenhphu,
masanpham,
tensanphamviettat,
tennhavanchuyen,
inserted_at,
dschuvat_banhang as doanhsochuavat,
donvigiaohang_fix,
ma_nvgh_tinhluong,
ngaychotso,
ngaygiaohang_fix,
status_dv,
full_leadtime,
ngaytaodon,
ngayduyetdon,
'null' as nguoi_duyetdon,
ten_nvgh_tinhluong,
role_giaohang_tinhluong,
masup_gh,
tensup_gh,
tenmgr_gh,
ten_donghang_tinhluong,
'null' as chinhanh_dialy,
don_tinh_gh,
madon_tinh_gh,
full_leadtime_1,
chotso_leadtime_1 as chotso_leadtime_1,
full_leadtime_duyetdon_1 as full_leadtime_duyetdon_1,
cluster_state

FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2`;