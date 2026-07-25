CREATE VIEW `spatial-vision-343005.warehouse.view_qr_scan_quan_ly_tai_san_by_users`
AS SELECT
    a.id,
    a.ma_qlts_con,
    a.img_0,
    a.img_1,
    a.img_2,
    a.img_3,
    a.img_4,
    a.inserted_at,
    a.elt_at,
    a.p_manv,
    a.p_version
FROM
    staging.qr_scan_quan_ly_tai_san_by_users AS a;