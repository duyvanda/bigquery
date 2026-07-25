CREATE VIEW `spatial-vision-343005.warehouse.view_f_form_data_log_by_users`
AS SELECT
a.manv,
a.role,
a.sl_kien_thuc_nhan,
a.sl_tui_thuc_nhan,
a.sl_thung_thuc_nhan,
a.selected_ghi_chu_chenh_lech,
a.lat,
a.lgn,
a.cn_sdh,
a.cn,
a.ma_ct,
a.sl_kien_hang,
a.sl_don_hang,
a.sl_so_xuat_hang,
a.img_0,
a.img_1,
a.img_2,
a.img_3,
a.img_4,
a.sl_hinh,
a.inserted_at,
a.p_manv,
a.p_version,
b.tencvbh,
b.supid,
b.tenquanlytt,
ST_GEOGPOINT(lgn, lat) as geo_point
FROM `spatial-vision-343005.staging.f_form_data_log_by_users` a
left join  `spatial-vision-343005.staging.d_users` b on UPPER(a.manv) = UPPER(b.manv)
;