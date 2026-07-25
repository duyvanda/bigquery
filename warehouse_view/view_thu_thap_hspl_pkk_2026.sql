CREATE VIEW `spatial-vision-343005.warehouse.view_thu_thap_hspl_pkk_2026`
AS SELECT 
a.*,
IFNULL(b.ket_qua_kiem_tra, 'Chưa kiểm tra') as ket_qua_kiem_tra,
b.ghi_chu as ghi_chu_kiem_tra
FROM `spatial-vision-343005.staging.view_bi_theo_doi_tien_do_tang_qua_by_users` a
LEFT JOIN `spatial-vision-343005.warehouse.ket_qua_thu_thap_hspl_pkk_2026` b ON a.ma_khach_hang = b.ma_kh
Where ma_chuong_trinh = "thu_thap_hspl_pkk_2026";