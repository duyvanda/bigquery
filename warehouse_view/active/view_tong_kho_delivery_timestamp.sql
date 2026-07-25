CREATE VIEW `spatial-vision-343005.warehouse.view_tong_kho_delivery_timestamp`
AS SELECT
ma_dh,
tentinhkh,
min(ngaychungtu) as ngaychungtu,
min(ngaytaodon) as ngaytaodon,
min(ngayduyetdon) as ngayduyetdon,
min(ngay_xac_nhan_hang) as ngay_xac_nhan_hang,
min(ngaygiaohang_fix) as ngaygiaohang

FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2` WHERE TIMESTAMP_TRUNC(ngaychungtu, DAY) >= TIMESTAMP("2025-01-01") 
and donvigiaohang_fix NOT IN ('Nhà vận chuyển', 'NVC')
group by all;