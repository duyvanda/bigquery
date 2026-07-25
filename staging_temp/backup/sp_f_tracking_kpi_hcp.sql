CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_tracking_kpi_hcp()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_tracking_kpi_hcp_temp`;


 INSERT INTO `staging_temp.f_tracking_kpi_hcp_temp`

(  
-- Create or replace table staging_temp.f_tracking_kpi_hcp_temp as

  with sales as (
  
  select
  makhdms,
  IFNULL(b.pubcustid, 'NONE') as pubcustid,
  a.makenh_moi as channel,
  a.crm as ma_crm,
  date(date_trunc(a.ngaychungtu,month)) as thang,
  sum(a.doanhsochuavat) as doanhsochuavat,
  0 as kh_total
  from `warehouse.f_sales_crs` a
  LEFT JOIN `staging.d_master_khachhang` b on a.makhdms = b.custid
  where ngaychungtu >= '2024-01-01' and a.makenh_moi in ('INS','CLC','PCL')
  group by all
  )

,kh_kenh_trong_tam as
(
select
 a.mahcochung as pubcustid,
 a.kenh as channel,
 a.ma_crm,
 date(a.thang) as thang,
 0 as doanhsochuavat,
 sum(target) as ke_hoach
from `staging.d_kpi_tan_tam` a
group by 1,2,3,4,5
)
,
kh_kenh_trong_tam1 as 
(
select 
b.custid,
a.pubcustid,
a.channel,
a.ma_crm,
a.thang,
a.doanhsochuavat,
Case when b.custid is not null then a.ke_hoach / count(b.custid) over (partition by a.pubcustid,a.thang,a.channel)
else a.ke_hoach end as ke_hoach
from kh_kenh_trong_tam a 
LEFT JOIN `staging.d_master_khachhang` b on a.pubcustid=b.pubcustid and a.channel =b.channel

)
, kh_calendar as
(
SELECT b.supid, makenhkh, date(thang) as thang, sum(kh_total) as kh_total FROM `spatial-vision-343005.staging.d_calendar` a 
LEFT JOIN staging.d_users b on a.manv = b.manv
where makenhkh in ('INS','CLC','PCL') and date(thang)>= '2024-01-01'
group by 1,2,3

)

, kh_tt as
(
select
 a.ma_crm,
 a.kenh,
 date(a.thang) as thang,
 sum(target) as kh_tt
from `staging.d_kpi_tan_tam` a 
where thang >= '2024-01-01'
group by all

)

, kh_con_lai as
(
select 
cast(null as string) as makhdms,
'NONE' as pubcustid,
makenhkh as channel,
supid as ma_crm,
date(a.thang) as thang,
0 as doanhsochuavat,
kh_total - ifnull(kh_tt,0) as ke_hoach 
from kh_calendar a left join kh_tt b on a.supid = b.ma_crm and a.makenhkh = b.kenh and a.thang = b.thang

)

, union_all as
(
select * from sales

UNION ALL

select * from kh_kenh_trong_tam1

UNION ALL

select * from kh_con_lai

)

, result as

(

select makhdms,pubcustid, channel, ma_crm, thang, sum(doanhsochuavat) as doanhsochuavat, sum(kh_total) as kh_total from union_all 
group by all 

)
,
result1 as (
select *, 
case
when pubcustid != 'NONE' and abs(kh_total) > 0 then 'Trọng tâm'
else 'Còn lại' end as datatype
from result
)
,

result2 as (
select 
a.makhdms,
a.pubcustid,
b.pubcustname,
b.custname,
a.channel,
b.shoptype,
b.statedescr,
b.shortterritorydescr,
b.hcoid,
b.hcotypeid,
b.branchid,
b.branchname,
a.ma_crm,
c.tencvbh as tenquanlytt,
a.thang,
a.datatype,
a.doanhsochuavat,
a.kh_total,
timestamp(current_datetime("+7")) as inserted_at 
from result1 a 
LEFT JOIN `staging.d_master_khachhang` b on a.makhdms =b.custid
LEFT JOIN `staging.d_users` c on a.ma_crm = c.manv
)

select *  from result2  

);

Create or replace table `warehouse.f_tracking_kpi_hcp`

copy `staging_temp.f_tracking_kpi_hcp_temp`;


END;