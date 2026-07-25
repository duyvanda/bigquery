CREATE VIEW `spatial-vision-343005.warehouse.view_ty_le_lhq_bo`
AS WITH

kh_thang as
(
SELECT
a.thang,
sum(kh_total) as kh_total
FROM
`spatial-vision-343005.staging.d_calendar` a
where makenhkh NOT IN ('OTH_LAB')
and date(thang)>= '2025-04-01'
group by all
)

, sales_thang
as
(
SELECT
a.thang,
sum(dschuvat_banhang) as ds_tong,

-- sum(
-- case
-- when trangthaigiaohang = 'Đã giao hàng'  and DATE(DATE_TRUNC(ngaygiaohang_fix, MONTH)) = date(a.thang) then  dschuvat_banhang
-- else 0 END)
-- as ds_giao_hang_trong_thang
FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2`  a
WHERE 
date(ngaychungtu)>= '2025-04-01'
group by all
)

, giao_thang
as
(
SELECT
DATE_TRUNC(ngaygiaohang_fix, MONTH) as thang,
sum(
case
when trangthaigiaohang = 'Đã giao hàng'  then  dschuvat_banhang else 0 END)
as ds_giao_hang_trong_thang
FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2`  a
WHERE 
date(ngaychungtu)>= '2025-04-01'
and DATE(DATE_TRUNC(ngaygiaohang_fix, MONTH)) >= '2025-04-01'
group by all
)

,ty_le_bo AS (
  SELECT 
  77188253000 AS kh_total,
  CAST ('2025-03-01' AS TIMESTAMP ) AS thang, 
  80755409443 AS ds_tong,
  80755409443 as ds_giao_hang_trong_thang,
  104.6 AS ty_le_dsth_dskh_sales,
  104.6 AS  ty_le_ds_giao_tren_kh
  UNION ALL
  SELECT
  68331220480 AS kh_total,
  '2025-02-01' AS thang, 
  68489356075 AS ds_tong,
  68489356075 as ds_giao_hang_trong_thang,
  100.2 AS ty_le_dsth_dskh_sales,
  100.2 AS y_le_ds_giao_tren_kh,
  UNION ALL
  SELECT 
  66641094680 AS kh_total,
  '2025-01-01' AS thang, 
  65070711908 AS ds_tong,
  65070711908 AS ds_giao_hang_trong_thang,
  97.6 AS ty_le_dsth_dskh_sales,
  97.6 AS y_le_ds_giao_tren_kh,
)
select 
kh.kh_total,
s.thang,
s.ds_tong,
gh.ds_giao_hang_trong_thang,
ROUND(SAFE_DIVIDE(ds_tong, kh_total), 3)*100 AS ty_le_dsth_dskh_sales,
ROUND(SAFE_DIVIDE(ds_giao_hang_trong_thang, kh_total), 3)*100 AS ty_le_ds_giao_tren_kh
FROM kh_thang kh
LEFT JOIN sales_thang s on kh.thang = s.thang
LEFT JOIN giao_thang gh on gh.thang = kh.thang

UNION ALL
SELECT * FROM ty_le_bo;