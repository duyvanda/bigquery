CREATE VIEW `spatial-vision-343005.warehouse.view_f_raw_data_sales_yoy_oth`
AS SELECT * FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` WHERE TIMESTAMP_TRUNC(ngaychungtu, DAY) >= TIMESTAMP("2023-01-01") -- 2023-01-01
and
(
case when makhdms in ('014916', '014937','014938', '019455') then true
when makenhkh in ('OTH_LAB', 'ECE', 'DLPP', 'EXP') then true
else false end);