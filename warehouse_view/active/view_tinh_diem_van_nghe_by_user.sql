CREATE VIEW `spatial-vision-343005.warehouse.view_tinh_diem_van_nghe_by_user`
AS SELECT
manv,
bod,
tiet_muc,
diem_chon,
diem_chon_int,
'' as p_manv,
'' as version,
inserted_at,
b.hovatenfullname
FROM `spatial-vision-343005.staging.view_tinh_diem_van_nghe_chi_tiet_by_users` a
left join `spatial-vision-343005.staging.d_hr_dsns` b on a.manv = b.msnvcsmmoi;