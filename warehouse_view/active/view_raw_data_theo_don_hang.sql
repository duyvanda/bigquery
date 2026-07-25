CREATE VIEW `spatial-vision-343005.warehouse.view_raw_data_theo_don_hang`
AS select 
a.* ,
e.dangdangky,
e.dactinhsxkd
from `warehouse.f_raw_data_sales_yoy` a
LEFT JOIN `spatial-vision-343005.warehouse.dim_excluded_makhdms` excl ON a.makhdms = excl.makhdms
LEFT JOIN `staging.d_nhom_sp_trading` e ON e.masanpham = a.masanpham
WHERE excl.makhdms IS NULL
;