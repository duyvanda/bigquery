CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_phantich_khachhangzalo()
BEGIN 
  TRUNCATE TABLE staging_temp.f_phantich_khachhangzalo_temp;

 INSERT INTO staging_temp.f_phantich_khachhangzalo_temp(
-- Create table staging_temp.f_phantich_khachhangzalo_temp
-- partition by ngaytao
-- as
with bang1a as
(
select 
  distinct date (thoidiemtao) as ngaytao,
  makhdms as makhOA,
  'OA' as source,
  row_number() over (partition by makhdms order by thoidiemtao asc ) as loc
from `spatial-vision-343005.staging.d_caresoft_customer`
where 
  makhdms is not null
)
,
bang1 as
(
  select * from bang1a
  where loc = 1
)
,

bang2a as 
  (select 
  distinct date(created_at) as ngayactive,
  customer_code as makhEO,
  'EO' as source,
  row_number() over (partition by customer_code order by created_at asc) as loc
from
`spatial-vision-343005.staging.f_crawl_activate_ecom`
)
,
bang2 as (select * from bang2a where loc = 1)
,

bang3a as
(
  select 
  distinct date (crtd_datetime) as ngaytaodonDMS,
  custid as makhDMS,
  'DMS' as source,
  row_number() over (partition by custid order by crtd_datetime asc ) as loc
  from `spatial-vision-343005.staging.sync_dms_pda_so`
  where crtd_user ='TMDT_001'
)
,
bang3 as 
( select * from bang3a where loc = 1)

  select
  a.ngaytao,
  a.makhOA,
  a.source as source0A,
  b.ngayactive,
  b.makhEO,
  b.source as sourceEO,
  c.ngaytaodonDMS,
  c.makhDMS,
  c.source as sourceDMS,
  d.custname,
  d.channel,
  d.shoptype,
  d.statedescr,
  d.districtdescr,
  d.wardname
  from bang1 a
  left join bang2 b on a.makhOA =  b.makhEO
  left join bang3 c on a.makhOA = c.makhDMS
  left join `staging.d_master_khachhang` d on a.makhOA = d.custid

    );
Create or replace table `warehouse.f_phantich_khachhangzalo`

copy `staging_temp.f_phantich_khachhangzalo_temp`;

End;