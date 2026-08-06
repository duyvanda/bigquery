-- ==========================================================================
-- Routine Name : sp_f_sales_performance_sales_mtd
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2025-11-06 15:16:35.450000+00:00
-- Last Altered : 2025-11-06 15:16:35.450000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_sales_performance_sales_mtd()
BEGIN
TRUNCATE TABLE staging_temp.f_sales_performance_sales_mtd_temp;
INSERT INTO staging_temp.f_sales_performance_sales_mtd_temp(

with

sl_kh_pp_mcp as

(
with data_tuyen as (
SELECT a.custid,a.slsperid,a.crtd_datetime,b.channel,
Case when routetype in ('B','D') then 1 else 2 end as routetype,
FROM `spatial-vision-343005.staging.sync_dms_srm` a
LEFT JOIN `staging.d_master_khachhang` b on a.custid =b.custid
where delroutedet is false  --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
and b.active ='Active'

),
loc_data_mcp as (

select * from (
select *,row_number() over (partition by custid order by routetype asc,crtd_datetime desc) as loc  from data_tuyen
)
where loc =1
)

select slsperid,channel,custid
from loc_data_mcp
),
data_pp_kh as (
select manv,makhdms,masanpham,ngaychungtu,tensanphamviettat,thang,
sum(doanhsochuavat) as ds
  from `warehouse.f_raw_data_sales_yoy`  a
  where ngaychungtu >='2023-01-01'

group by 1,2,3,4,5,6
)
,
sp as (select distinct masanpham,tensanphamviettat from `warehouse.f_raw_data_sales_yoy` where masanpham is not null and thang >='2023-01-01'

) ,
mapping_pp_kh as (
select
a.slsperid as manv,
a.custid as makhdms_mcp,
ifnull(date(ngaychungtu),(select * from `staging.d_current_table`)) as ngaychungtu ,
ifnull(date(thang),(select * from `staging.d_current_table`)) as thang,
a.channel,
ifnull(sp.masanpham,b.masanpham) as masanpham,
ifnull( sp.tensanphamviettat,b.tensanphamviettat) as tensanphamviettat,
b.makhdms
,e.custname
,d.tencvbh
,d.supid as crm
,d.asm as scrm
,Left(d.rsmid,6) as ncxm
,d.tenquanlytt
,d.tenquanlykhuvuc
,Case when d.tenquanlytt ='Lê Thị Hương Sa' then'Lê Thị Hương Sa' else  d.tenquanlyvung end as tenquanlyvung

 from sl_kh_pp_mcp a
LEFT JOIN sp on 1=1
LEFT JOIN data_pp_kh b on a.slsperid =b.manv and a.custid =b.makhdms and b.masanpham =sp.masanpham
LEFT JOIN `staging.d_users` d on a.slsperid =d.manv
LEFT JOIN `staging.d_master_khachhang` e on e.custid = a.custid
)

select * from mapping_pp_kh
  );
Create or replace table `warehouse.f_sales_performance_sales_mtd`

copy `staging_temp.f_sales_performance_sales_mtd_temp`;

End;
