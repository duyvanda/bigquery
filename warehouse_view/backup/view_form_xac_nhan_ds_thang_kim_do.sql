CREATE VIEW `spatial-vision-343005.warehouse.view_form_xac_nhan_ds_thang_kim_do`
AS SELECT
ngaychungtu,
manv,
tencvbh,
tentinhkh,
doanhsochuavat,
'' as ghichu
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` 
WHERE
date(ngaychungtu)>= '2025-04-01'
and macongtycn = 'DL0001';