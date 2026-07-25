CREATE VIEW `spatial-vision-343005.warehouse.api_thong_tin_tuyen_mcp`
AS SELECT
    thu,
    kenh,
    manv AS ma_crs,
    tinh,
    supid AS ma_crm,
    thang,
    kenhphu AS kenh_phu,
    tencvbh AS ten_crs,
    tu_ngay,
    den_ngay,
    ARRAY_TO_STRING([so_nha_ten_duong, phuong_xa, quanhuyen, tinh], ', ') AS dia_chi,
    ma_tuyenbh AS ma_tuyen_ban_hang,
    tansuat_bh AS tuan_suat_ban_hang,
    tenquanlytt AS ten_crm,
    ma_khachhang AS ma_kh_dms,
    tenkhachhang AS ten_kh,
    tuan_tham_kh
FROM `spatial-vision-343005.warehouse.f_thongtin_tuyen_mcp_tp_pcl`
WHERE EXTRACT(MONTH FROM thang) = EXTRACT(MONTH FROM CURRENT_DATE('+07:00'))
    AND EXTRACT(YEAR FROM thang) = EXTRACT(YEAR FROM CURRENT_DATE('+07:00'));;