CREATE VIEW `spatial-vision-343005.warehouse.f_phan_tich_ecom_hieusuat_ds`
AS with sales as (
select   
if(b.makhdms is not null,'Ngoài MCP','Trong MCP') as check_kh_ngoai_mcp_2025,
date(ngaychungtu) as ngaychungtu,
a.makhdms,
a.sodondathang,
sum(doanhsochuavat) as doanhsochuavat
from `warehouse.f_sales_crs` a 
LEFT JOIN `staging.d_manual_kh_ngoai_mcp_phantich_ecom` b on a.makhdms =b.makhdms
where ngaychungtu >='2024-07-01' and makenh_moi in ('TP')
and is_ecom ='Ecom'
group by all
having doanhsochuavat > 0
),

array_ds as (
select 
check_kh_ngoai_mcp_2025,
date(date_trunc(ngaychungtu,month)) as thang,
count(distinct date(ngaychungtu)) as so_ngay_dat,
array_agg(doanhsochuavat) as ds,
from  sales
group by all
),

cal_quantile as (
select 
check_kh_ngoai_mcp_2025,
thang,
-- so_ngay_dat,
min(ds) as min_ds,
max(ds) as max_ds,
round(avg(ds),2) as mean_ds,
approx_quantiles(ds,4)[offset(1)] as first_quantiles,
approx_quantiles(ds,4)[offset(2)] as second_quantiles,
approx_quantiles(ds,4)[offset(3)] as third_quantiles,
from array_ds,unnest(ds) as ds
group by all 
order by 1,2
)

select a.*,
third_quantiles + 1.5 * (third_quantiles - first_quantiles) as max_rau,
first_quantiles - 1.5 * (third_quantiles - first_quantiles) as min_rau,
 from cal_quantile a

-- select * from array_ds
;