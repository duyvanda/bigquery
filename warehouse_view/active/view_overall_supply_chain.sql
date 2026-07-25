CREATE VIEW `spatial-vision-343005.warehouse.view_overall_supply_chain`
AS WITH kpi_total AS (
SELECT 
DATE(thang) AS thang,
sum(kh_total) as kpi_total,
sum(if(makenhkh = 'OTH_LAB',0,kh_total)) as target_ml
FROM `spatial-vision-343005.staging.d_calendar`
where thang >= '2025-01-01'
group by all
)
,sale as (
SELECT 
DATE(thang) AS thang,
SUM(doanhsochuavat) as doanhsochuavat
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a 
LEFT JOIN `warehouse.dim_excluded_makhdms` b ON b.makhdms = a.makhdms
where thang >= '2025-01-01'
AND b.makhdms IS NULL
group by all
)
,ton_kho_ as (
SELECT 
  date_trunc(date(created_date), MONTH) as thang,
  date(created_date) as created_date,
  extract(DAY FROM created_date) as ngay,
  extract(MONTH FROM created_date) as thang_number,
  ifnull(gia_gom_vat, giaban)*toncuoi as ton_kho
  FROM `spatial-vision-343005.staging.f_sc_daily_raw_invt` a
LEFT JOIN `staging.d_gia_von_vttd`  d on d.ma_sp = a.invtid
LEFT JOIN `staging.d_dms_master_invtid`  i on i.invtid = a.invtid
where date(created_date) >= '2025-01-01' 
and a.invtid not like 'V%' 
and a.invtid not like 'D%' 
and a.invtid !='E0111088'
group by all
QUALIFY DENSE_RANK() OVER (PARTITION BY thang_number ORDER BY ngay DESC) = 1
)

,ton_kho as (
SELECT
thang,
created_date,
SUM(ton_kho) as ton_kho
FROM ton_kho_
GROUP BY ALL
)

,forecast AS (
SELECT 
date_trunc(DATE(month), MONTH) as month,
revised_date,
SUM(fcvalues*giahopwvat) as fcvalues
FROM `spatial-vision-343005.warehouse.f_baocao_tonkho_hangngay_page_forecastdetail`
WHERE date(month) >= '2025-01-01'
GROUP BY ALL
QUALIFY ROW_NUMBER() OVER (PARTITION BY month ORDER BY revised_date DESC) = 1
)
, result as (
SELECT
d.month as thang,
a.kpi_total,
a.target_ml,
b.doanhsochuavat,
c.ton_kho,
d.fcvalues as fc_thang_hien_tai,
LAG(d.fcvalues,1) OVER (ORDER BY d.month DESC) AS fc_thang_sau
FROM forecast d
LEFT JOIN sale b ON b.thang = d.month
LEFT JOIN ton_kho c ON c.thang = d.month
LEFT JOIN kpi_total a ON d.month = a.thang
ORDER BY d.month DESC
)
SELECT
*
FROM result
WHERE doanhsochuavat is not null




;