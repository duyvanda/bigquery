CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_o_donhang_ecom()
BEGIN 
  TRUNCATE TABLE staging_temp.f_o_donhang_ecom_temp;

 INSERT INTO staging_temp.f_o_donhang_ecom_temp(

-- Create or replace table staging_temp.f_o_donhang_ecom_temp
-- partition by date(ngaychungtu)
-- as

with 
data_pda as (
select ordernbr,custid,crtd_user from `spatial-vision-343005.staging.sync_dms_pda_so` 
WHERE crtd_user ='TMDT_001' and crtd_datetime >='2022-06-01'
  
),
khdms as 
(
  select distinct custid as makhdms from data_pda
),
data_crs as (
with  mapping as
(
select a.custid, slsperid, a.crtd_datetime,row_number() over (partition by a.custid order by a.crtd_datetime desc) as loc
from `staging.sync_dms_srm` a
-- inner join `staging.d_master_khachhang`  b on
-- a.custid = b.custid
-- and b.active = 'Active'
-- inner join khdms c on a.custid = c.makhdms
LEFT JOIN `staging.d_users` d on d.manv = a.slsperid
where routetype in ('B','C','D') and delroutedet is false and slsperid is not null
and d.position in ('S','SS','AM','RM','NS')

--order by a.crtd_datetime asc
)
select  custid, slsperid, crtd_datetime from mapping  where loc =1

),

tuyen_md as (
  with mapping as (
select a.custid, slsperid, a.crtd_datetime,row_number() over (partition by a.custid order by a.crtd_datetime desc) as loc
from `staging.sync_dms_srm` a
-- inner join `staging.d_master_khachhang`  b on
-- a.custid = b.custid
-- and b.active = 'Active'
-- inner join khdms c on a.custid = c.makhdms
where routetype in ('F') and delroutedet is false and slsperid is not null
--order by a.crtd_datetime asc
)
select  custid, slsperid, crtd_datetime from mapping  where loc =1
),


tuyen_mds as (
  with mapping as (
select a.custid, slsperid, a.crtd_datetime,row_number() over (partition by a.custid order by a.crtd_datetime desc) as loc
from `staging.sync_dms_srm` a
-- inner join `staging.d_master_khachhang`  b on
-- a.custid = b.custid
-- and b.active = 'Active'
-- inner join khdms c on a.custid = c.makhdms
where routetype in ('A') and delroutedet is false and slsperid is not null
--order by a.crtd_datetime asc
)
select  custid, slsperid, crtd_datetime from mapping  where loc =1
),


data as (
select a.*except(tenquanlytt,tenquanlykhuvuc,tenquanlyvung,donvigiaohang,manv,phuongxa),
ifnull(a1.crtd_user,a.manv) as manv,
-- Case when mrpn= 'MR' and sp_loaitru = 'N' and is_phanam_momoi = 'N' then
 Case when a.manv <> 'TMDT_001' 
 and a.tenquanlyvung <> 'Lương Trịnh Thắng'
 then a.manv else b.slsperid end as macrs,

 Case when a.manv <> 'TMDT_001' and a.tenquanlyvung = 'Lương Trịnh Thắng' then a.manv
 when b.slsperid is null then ifnull(c.slsperid,c1.slsperid)
 else null end as slsperid_md 
-- else null end as macrs,
from staging.f_sales a 
LEFT JOIN data_pda a1 on a.sodondathang =a1.ordernbr
LEFT JOIN data_crs b on a.makhdms =b.custid
LEFT JOIN tuyen_md c on a.makhdms =c.custid
LEFT JOIN tuyen_mds c1 on a.makhdms =c1.custid
where ngaychungtu >='2024-01-01'  and ifnull(a1.crtd_user,a.manv) = 'TMDT_001' ),



result as (
select a.*except(macrs),
a.macrs as macrs,
b.tencvbh as tencvbh_crs,
b.tenquanlytt ,
b.tenquanlykhuvuc,
b.tenquanlyvung,
b.supid as ma_crm,
b.asm as ma_scrm,
left(b.rsmid,6) as ma_ncxm,
b1.tencvbh as tencvbh_md,
c.kh_total,
c.kh_don,
c.kh_nt,

from data a 
-- LEFT JOIN `view_report.d_phanquyen_trading_gmail` b2 on b2.manv =a.macrs
LEFT JOIN `staging.d_users` b on a.macrs =b.manv
LEFT JOIN `staging.d_users` b1 on a.slsperid_md =b1.manv
LEFT JOIN `staging.d_calendar_ecom` c on date(c.thang) = date_trunc(date(a.ngaychungtu),month)

)

select * from result --where sodondathang ='DH5-1122-01310'

  );
Create or replace table `warehouse.f_o_donhang_ecom`

copy `staging_temp.f_o_donhang_ecom_temp`;

End;