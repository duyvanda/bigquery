CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_mds_performance()
BEGIN 
  TRUNCATE TABLE staging_temp.f_mds_performance_temp;


 INSERT INTO staging_temp.f_mds_performance_temp(

-- Create table `staging_temp.f_mds_performance_temp`
-- partition by (updated_at)
-- as

with data_congno as 
(
  select slsperid,date(updated_at) as updated_at,sum(tiennocongty) as tiennocongty 
  from `spatial-vision-343005.staging.f_daily_capture_notoihan_taixe_hanh`
  where
  --  slsperid ='MR0624' and
EXTRACT(DAYOFWEEK FROM updated_at) <> 1
 and date(updated_at) not in ('2022-04-30','2022-05-01','2022-05-02','2022-05-03')
 and date(updated_at) >='2022-04-01'
 group by 1,2
),

-- data_quangduong as 
-- (
-- select  
--   slsperid,
--   date(checkindate) as checkindate,

--   -- count(numbercico) as sodiem_checkin,
--   sum(distance_value/1000) as distance_km
-- from `spatial-vision-343005.staging.f_mds_distance_matrix`
-- where date(checkindate) >='2022-04-01'
-- --  where slsperid ='MR0624'
--  group by 1,2

-- ),


data_checkin as (
with rawdata as (SELECT distinct a.slsperid,date(a.updatetime) as checkindate,a.checktype,a.numbercico
FROM `spatial-vision-343005.staging.d_checkin` a
JOIN `spatial-vision-343005.staging.d_phanquyen_phanam` b on a.slsperid =b.manv 
and b.chucdanh in ('Level2-SUP','Level3-MGR','Level1-LOG/MDS')
where date(updatetime) >= '2022-04-01'  and checktype in ('IO','OO') )

select slsperid,checkindate,sum(sodiem_checkin) as sodiem_checkin, sum(sodiem_checkout) as sodiem_checkout from (

select a.slsperid,a.checkindate,
Case when a.checktype ='IO' then 1 else 0 end as sodiem_checkin,
Case when a.checktype ='OO' then 1 else 0 end as sodiem_checkout
 from rawdata a
  )a
group by 1,2 

),

data_sales as (
select macongtycn,sodondathang,sum(doanhsochuavat)  as doanhsochuavat
from `spatial-vision-343005.staging.f_sales`
 where ngaychungtu >='2022-01-01' group by 1,2
),

data_tinh as (
with data as (
SELECT distinct a.manvgh,statedescr
FROM `spatial-vision-343005.staging.f_sales` a
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` b on a.macongtycn = b.branchid and a.makhcu = b.custid and b.active ='Active'
where date(a.ngaygiaohang) >='2022-04-01'and a.trangthaigiaohang ='Đã giao hàng'),

result as (
  select 
manvgh,
ARRAY_TO_STRING(ARRAY_AGG(statedescr),',') as tinh
FROM data
GROUP BY manvgh )

select a.*,b.firstname as tencvbh
 from result a LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` b on a.manvgh =b.username 
 order by a.manvgh


),

-- raw_data_leadtime as (
--   SELECT 
--     manvgh,
--     branchid,
--     custid,
--     ordernbr,
--     dvvc,
--     status,
--     post_time,
--     approve_time,
--     invoice_time,
--     booked_time,
--     ready_to_ship_time,
--     date(delivered_time) as delivered_time,
--     leadtime_t0_minute/60 as leadtime_t0_hour,
--     leadtime_t1_minute/60 as leadtime_t1_hour,
--     leadtime_t2_minute/60 as leadtime_t2_hour,
--     leadtime_t3_minute/60 as leadtime_t3_hour,
--     leadtime_t4_minute/60 as leadtime_t4_hour,
--     leadtime_full_minute/60 as leadtime_full_hour,
--     null as tiennocongty,
--     null as count_congno,
--     null as sodiem_checkin,
--     null as sodiem_checkout,
--     null as distance_km
--  FROM `spatial-vision-343005.staging.f_mds_leadtime` 
-- -- and manvgh ='MR0624'
-- ),
-- max_invoice as (
--   select branchid,ordernbr,max(invoice_time)  as max_invoicetime from raw_data_leadtime group by 1,2 ),

data_leadtime as (
 

select
  Case when slsperid_dv is null then crtd_user_dv else slsperid_dv end as slsperid_dv,
  branchid,
  custid,
  ordernbr,
  deliveryunit,
  status_dv,
  ngaytaodon,
  ngayduyetdon,
  ngayphathanhhd,
  ngaytaoso,
  ngaychotso,
  date(ngaygiaohang) as ngaygiaohang,
  t0,
  t1,
  t2,
  t3_1,
  t4,
  full_leadtime,
    null as tiennocongty,
    null as count_congno,
    null as sodiem_checkin,
    null as sodiem_checkout,
    null as distance_km
from `warehouse.f_leadtime_new_detail1` 
where --ngaygiaohang >='2022-04-01' and 
ngaytaodon >='2022-01-01'
and status_iv <>'Hủy hóa đơn' and ordernbr_co <>'Hủy HĐ'

),

result as (
  SELECT 
  slsperid,
  null as branchid,
  null as custid,
  null as ordernbr,
  null as dvvc,
  null as status,
  null as post_time,
  null as approve_time,
  null as invoice_time,
  null as crt_booked_time,
  null as booked_time,
  date(updated_at) as updated_at,
  null as leadtime_t0_hour,
  null as leadtime_t1_hour,
  null as leadtime_t2_hour,
  null as leadtime_t3_hour,
  null as leadtime_t4_hour,
  null as leadtime_full_hour,
  tiennocongty,
  IF(tiennocongty>=20000000,1,0) as count_congno,
  null as sodiem_checkin,
  null as sodiem_checkout,
  null as distance_km
 FROM data_congno


--  UNION ALL

--   select  
--   slsperid,
--   null as branchid,
--   null as custid,
--   null as ordernbr,
--   null as dvvc,
--   null as status,
--   null as post_time,
--   null as approve_time,
--   null as invoice_time,
--   null as crt_book_time,
--   null as booked_time,
--   checkindate,
--   null as leadtime_t0_hour,
--   null as leadtime_t1_hour,
--   null as leadtime_t2_hour,
--   null as leadtime_t3_hour,
--   null as leadtime_t4_hour,
--   null as leadtime_full_hour,
--   null as tiennocongty,
--   null as count_congno,
--   null as sodiem_checkin,
--   null as sodiem_checkout,
--   distance_km
-- from data_quangduong

UNION ALL

  select  
  slsperid,
  null as branchid,
  null as custid,
  null as ordernbr,
  null as dvvc,
  null as status,
  null as post_time,
  null as approve_time,
  null as invoice_time,
  null as booked_time,
  null as ready_to_ship_time,
  checkindate,
  null as leadtime_t0_hour,
  null as leadtime_t1_hour,
  null as leadtime_t2_hour,
  null as leadtime_t3_hour,
  null as leadtime_t4_hour,
  null as leadtime_full_hour,
  null as tiennocongty,
  null as count_congno,
  sodiem_checkin,
  sodiem_checkout,
  null as distance_km
from data_checkin

UNION ALL


    SELECT 
    *
    from
    data_leadtime
)

-- phanquyen as 
-- (
--   with max_phanquyen as (
--   select manv,max(inserted_at) as max_inserted_at from `spatial-vision-343005.staging.d_phanquyen_phanam`
-- group by 1 )

-- select distinct a.*
-- from `spatial-vision-343005.staging.d_phanquyen_phanam` a
-- JOIN max_phanquyen b on a.manv=b.manv and a.inserted_at =b.max_inserted_at
-- where a.trangthaihoatdong ='Còn hoạt động'
-- )

select * from (
select a.* 
   ,e.tinh
  ,d.doanhsochuavat
-- ,b.custname,b.statedescr,b.channel,b.shoptype
  ,c.tencvbh,c.tenquanlytt,c.tenquanlykhuvuc,
  -- f.email as sup_email,

  -- Case when a.slsperid ='MR2168' then 'MR2568' else a.slsperid end as  manv
  'MR2568' as manv
  
from result a
-- LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` b on b.branchid = a.branchid and a.custid = b.custid
LEFT JOIN `spatial-vision-343005.staging.d_users` c on c.manv = a.slsperid
LEFT JOIN data_sales d on d.macongtycn = a.branchid and d.sodondathang =a.ordernbr
LEFT JOIN data_tinh e on e.manvgh = a.slsperid
-- LEFT JOIN phanquyen f on c.supid = f.manv
 ) a

--where a.manv = @manv
  );

Create or replace table `warehouse.f_mds_performance`

copy `staging_temp.f_mds_performance_temp`;

End;