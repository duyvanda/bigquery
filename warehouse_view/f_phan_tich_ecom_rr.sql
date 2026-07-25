CREATE VIEW `spatial-vision-343005.warehouse.f_phan_tich_ecom_rr`
AS with union_all as (

with retension_month as (
select   makhdms ,date_trunc(ngaychungtu,month) as thang,sum(doanhsochuavat) as ds  from `warehouse.f_sales_crs` where ngaychungtu >='2024-07-01' and makenh_moi in ('TP')
and makhdms not in (select makhdms from `staging.d_manual_kh_ngoai_mcp_phantich_ecom`)
-- and ngaychungtu < '2025-03-01'  
and is_ecom ='Ecom'
group by all
-- having ds >0
),

first_month as (
select   makhdms  ,min(date_trunc(ngaychungtu,month)) as thang ,sum(doanhsochuavat) as ds from `warehouse.f_sales_crs` where ngaychungtu >='2024-07-01' and makenh_moi in ('TP')
and makhdms not in (select makhdms from `staging.d_manual_kh_ngoai_mcp_phantich_ecom`)
-- and ngaychungtu < '2025-03-01'  
and is_ecom ='Ecom'
group by all
-- having ds >0
),

month_values as (
select  thang as thang1,count(makhdms) as sl_customer from first_month
group by 1
),
mapping as (

select a.*,b.thang as retension_month,b.makhdms as retension_makhdms 
from first_month a 
LEFT JOIN retension_month b on a.makhdms = b.makhdms
order by 1,2,3
),
retension_user as (
select thang,retension_month,count(makhdms) as retension_user from mapping group by 1,2
order by 1,2
)

select *,round(retension_user/sl_customer,2) as retension_rate ,
date_diff(date(retension_month), date(thang1),month) as thang_num,
'Trong MCP' as datatype,
from month_values a 
LEFT JOIN retension_user b on a.thang1 =b.thang
-- where retension_month ='2025-02-01'


UNION ALL 

select * from (

with retension_month as (
select   makhdms ,date_trunc(ngaychungtu,month) as thang,sum(doanhsochuavat) as ds  from `warehouse.f_sales_crs` where ngaychungtu >='2024-07-01' and makenh_moi in ('TP')
and makhdms  in (select makhdms from `staging.d_manual_kh_ngoai_mcp_phantich_ecom`)
-- and ngaychungtu < '2025-03-01'  
and is_ecom ='Ecom'
group by all
-- having ds >0
),

first_month as (
select   makhdms  ,min(date_trunc(ngaychungtu,month)) as thang ,sum(doanhsochuavat) as ds from `warehouse.f_sales_crs` where ngaychungtu >='2024-07-01' and makenh_moi in ('TP')
and makhdms  in (select makhdms from `staging.d_manual_kh_ngoai_mcp_phantich_ecom`)
-- and ngaychungtu < '2025-03-01'  
and is_ecom ='Ecom'
group by all
-- having ds >0
),

month_values as (
select  thang as thang1,count(makhdms) as sl_customer from first_month
group by 1
),
mapping as (

select a.*,b.thang as retension_month,b.makhdms as retension_makhdms 
from first_month a 
LEFT JOIN retension_month b on a.makhdms = b.makhdms
order by 1,2,3
),
retension_user as (
select thang,retension_month,count(makhdms) as retension_user from mapping group by 1,2
order by 1,2
)

select *,round(retension_user/sl_customer,2) as retension_rate ,
date_diff(date(retension_month), date(thang1),month) as thang_num,
'Ngoài MCP' as datatype,

from month_values a 
LEFT JOIN retension_user b on a.thang1 =b.thang
-- where retension_month ='2025-02-01'
order by 1,4
)

UNION ALL 

select * from (
  
with retension_month as (
select   makhdms ,date_trunc(ngaychungtu,month) as thang,sum(doanhsochuavat) as ds from `warehouse.f_sales_crs` where ngaychungtu >='2024-07-01' and makenh_moi in ('TP')
-- and makhdms  in (select makhdms from `staging.d_manual_kh_ngoai_mcp_phantich_ecom`)
-- and ngaychungtu < '2025-03-01'  
and is_ecom ='Ecom'
group by all
-- having ds > 0
),

first_month as (
select   makhdms  ,min(date_trunc(ngaychungtu,month)) as thang,sum(doanhsochuavat) as ds from `warehouse.f_sales_crs` where ngaychungtu >='2024-07-01' and makenh_moi in ('TP')
-- and makhdms  in (select makhdms from `staging.d_manual_kh_ngoai_mcp_phantich_ecom`)
-- and ngaychungtu < '2025-03-01'  
and is_ecom ='Ecom'
group by 1
-- having ds > 0
),

month_values as (
select  thang as thang1,count(makhdms) as sl_customer from first_month
group by 1
),
mapping as (

select a.*,b.thang as retension_month,b.makhdms as retension_makhdms 
from first_month a 
LEFT JOIN retension_month b on a.makhdms = b.makhdms
order by 1,2,3
),
retension_user as (
select thang,retension_month,count(makhdms) as retension_user from mapping group by 1,2
order by 1,2
)

select *,round(retension_user/sl_customer,2) as retension_rate ,
date_diff(date(retension_month), date(thang1),month) as thang_num,
'ALL' as datatype,

from month_values a 
LEFT JOIN retension_user b on a.thang1 =b.thang
-- where retension_month ='2025-02-01'
order by 1,4
)
)
select * from union_all 
-- where datatype='Trong MCP'
order by 1,4,8;