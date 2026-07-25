CREATE VIEW `spatial-vision-343005.warehouse.f_phan_tich_ecom_ds`
AS with sales_order_ecom as (
  
  with sales_order as (
select   
a.makhdms,
a.sodondathang,
a.ngaychungtu,
if(b.makhdms is not null,'Ngoài MCP','Trong MCP') as check_kh_ngoai_mcp_2025,
date(date_trunc(ngaychungtu,month)) as thang,
sum(doanhsochuavat) as doanhsochuavat
from `warehouse.f_sales_crs` a 
LEFT JOIN `staging.d_manual_kh_ngoai_mcp_phantich_ecom` b on a.makhdms =b.makhdms
-- LEFT JOIN tuyen_bh_cn c on a.makhdms =c.custid and a.thang =c.thang
where ngaychungtu >='2024-07-01' and makenh_moi in ('TP')
and is_ecom ='Ecom'
group by all
-- having doanhsochuavat >0

)
,
don_km as (
select a.*,
count(distinct makhdms) over (partition by check_kh_ngoai_mcp_2025) as sl_kh_all,
Case 
when doanhsochuavat >=250000 then row_number() over (partition by makhdms,thang,doanhsochuavat >=250000 order by ngaychungtu )
else 0 end as stt_don
 from sales_order a 
 order by makhdms,thang
),

group_all as (
select 
thang,
check_kh_ngoai_mcp_2025,
sl_kh_all,
count(distinct sodondathang) as sl_dh,
sum(Case when stt_don = 1 then 1 else 0 end) as sl_dh_km,
sum(Case when stt_don =2 then 1 else 0 end) as sl_dh_km_v2,
count(distinct makhdms) as sl_kh,
 from don_km
 group by all
  order by thang,check_kh_ngoai_mcp_2025
)
select a.*,
round(safe_divide(sl_dh_km,sl_dh)*100,2) as ty_le_dh_km,
round(safe_divide(sl_kh,sl_dh)*100,2) as ty_le_kh_km
from group_all a

)
,

sales as (
select   
-- a.makhdms ,
-- date(extract(year from ngaychungtu),extract(quarter from ngaychungtu)*3,1) as quy,
if(b.makhdms is not null,'Ngoài MCP','Trong MCP') as check_kh_ngoai_mcp_2025,
-- if(c.custid is not null,'Tuyến MCP CN','Tuyến MCP Khác CN') as check_tuyen_bh_cn,
date(date_trunc(ngaychungtu,month)) as thang,
count(distinct a.makhdms) as sl_kh,
count(distinct sodondathang) as sl_dh,
count(distinct masanpham) as sl_sp,
round(sum(doanhsochuavat) / count(distinct sodondathang),2) as ds_tb_1dh,
round(sum(doanhsochuavat) / count(distinct a.makhdms),2) as ds_tb_1kh,
sum(Case when extract(year from ngaychungtu) = 2024 then doanhsochuavat else 0 end) as doanhsochuavat_2024,
sum(Case when extract(year from ngaychungtu) = 2025 then doanhsochuavat else 0 end) as doanhsochuavat_2025,
-- sum(Case when b.makhdms is not null then doanhsochuavat  else 0 end) as doanhsochuavat_ngoaimcp,
-- sum(Case when b.makhdms is  null then doanhsochuavat  else 0 end) as doanhsochuavat_trongmcp,

-- sum(Case when extract(year from ngaychungtu) = 2024 and b.makhdms is null then doanhsochuavat  else 0 end) as doanhsochuavat_trongmcp_2024,
-- sum(Case when extract(year from ngaychungtu) = 2025 and b.makhdms is null then doanhsochuavat  else 0 end) as doanhsochuavat_trongmcp_2025,
sum(doanhsochuavat) as doanhsochuavat
from `warehouse.f_sales_crs` a 
LEFT JOIN `staging.d_manual_kh_ngoai_mcp_phantich_ecom` b on a.makhdms =b.makhdms
-- LEFT JOIN tuyen_bh_cn c on a.makhdms =c.custid and a.thang =c.thang
where ngaychungtu >='2024-07-01' and makenh_moi in ('TP')
and is_ecom ='Ecom'
group by all
-- having doanhsochuavat >0
order by thang
)
,
acc_ds as (
select *,
sum(doanhsochuavat) over (partition by thang) as acc_ds_thang,
sum(doanhsochuavat) over (partition by 1) as acc_ds_all,
lag(doanhsochuavat) over (partition by check_kh_ngoai_mcp_2025 order by thang) as pre_doanhsochuavat,
 from sales
 order by thang 
)

select a.*,
lag(acc_ds_thang) over (partition by a.check_kh_ngoai_mcp_2025 order by a.thang) as pre_acc_ds_thang,
round(safe_divide(a.doanhsochuavat,acc_ds_thang)*100,2) as ty_le_ds_trong_ngoai,
round(safe_divide((a.doanhsochuavat - pre_doanhsochuavat),pre_doanhsochuavat)*100,2) as ty_le_tangtruong_trong_ngoai_pre,
b.sl_dh_km,
b.sl_dh_km_v2,
b.ty_le_dh_km,
b.ty_le_kh_km,
b.sl_kh_all,
c.doanhsochuavat as ds_pre_year,
c.sl_kh as kh_pre_year
from acc_ds a
LEFT JOIN sales_order_ecom b on a.thang =b.thang and a.check_kh_ngoai_mcp_2025=b.check_kh_ngoai_mcp_2025
LEFT JOIN sales c on a.thang = c.thang + interval 1 year and a.check_kh_ngoai_mcp_2025=c.check_kh_ngoai_mcp_2025
order by thang;