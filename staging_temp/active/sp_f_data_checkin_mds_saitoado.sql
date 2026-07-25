CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_data_checkin_mds_saitoado()
BEGIN

DECLARE partition_date DATE DEFAULT '2024-01-01';

TRUNCATE TABLE staging_temp.f_data_checkin_mds_saitoado_temp;
INSERT INTO staging_temp.f_data_checkin_mds_saitoado_temp
 (
-- Create or replace table staging_temp.f_data_checkin_mds_saitoado_temp
-- partition by date(visitdate)
-- as

with order_checkin as 
(
  with order_checkin as 
  (
    SELECT 
      branchid,
  	  slsperid,
    	deordernbr,
      de_updatetime,
      numbercico,
      inserted_at
    FROM `spatial-vision-343005.staging.sync_dms_decheckin` 
  )
  ,

  max_order_checkin as
  (
    select 
      branchid,
      slsperid,
      deordernbr,
      max(de_updatetime) as max_de_updatetime 
    from `spatial-vision-343005.staging.sync_dms_decheckin`  
    group by 1,2,3
  )
    select distinct a.* 
    from order_checkin a
    JOIN max_order_checkin b on a.branchid = b.branchid and a.slsperid = b.slsperid and a.deordernbr = b.deordernbr and a.de_updatetime = b.max_de_updatetime
)
,

data_checkin_i as 
(
  select 
    slsperid,
    custid,
    branchid,
    lat,lng,
    typ,
    checktype,
    updatetime,
    numbercico
  from `spatial-vision-343005.staging.d_checkin`
  where date(updatetime) > partition_date and checktype = 'IO'
  QUALIFY row_number() over (partition by slsperid,custid,numbercico,branchid order by updatetime desc) = 1
)
,

data_checkin_o as 
(
  select 
    slsperid,
    custid,
    branchid,
    lat,lng,
    typ,
    checktype,
    updatetime,
    numbercico
  from `spatial-vision-343005.staging.d_checkin`
  where date(updatetime) > partition_date and checktype = 'OO'
  QUALIFY row_number() over (partition by slsperid,custid,numbercico,branchid order by updatetime desc) = 1
)
-- ,

-- sales_checkin as 
-- (
-- 	select
--   from `spatial-vision-343005.staging.sync_dms_sacheckin`
-- )
,

checkin_note as 
(
  select 
  custid,
  visitdate,
  noteid,
  slsperid,
  branchid,
  note,
  descr,
  salesid,
  distance,
  checkintype,
  replace(imagefilename, 'dms.phanam.com.vn','dms.meraplion.com') as imagefilename,
  inserted_at
from `spatial-vision-343005.staging.sync_dms_oc`
where date(visitdate) >= partition_date
)
,

data_update_toado as 
(
  WITH data_update_toado AS 
  (
    SELECT
      custid,
      MAX(visitdate) AS max_visitdate
    FROM `spatial-vision-343005.staging.sync_dms_customerlocationhis`
    group by 1
  )
  ,

  result as 
  (
    SELECT
      a.custid,
      a.visitdate,
      a.lupd_user,
      a.oldlat,
      a.oldlng,
      a.updatelat,
      a.updatelng,
      a.lupd_datetime
    from `spatial-vision-343005.staging.sync_dms_customerlocationhis` a
    JOIN data_update_toado b on a.custid = b.custid and a.visitdate = b.max_visitdate
  )
    select * from result
)
/*
CL = Close
IO= In outlet
PS= Program Sales
SO= Sales ord vào step ghi nhận đơn hàng
PA= Thanh toán công nợ
OO= Out outlet
DP= trưng bày
SA= Có đơn hàng
FC= Feedback customer
PO = POSM/Gimmick
SK= Stock keeping
*/

SELECT
b.*,
Case when b.branchid ='MR0001' then 'DH0'
    when b.branchid ='MR0010' then 'DH1'
    when b.branchid ='MR0012' then 'DH2'
    when b.branchid ='MR0013' then 'DH3'
    when b.branchid ='MR0014' then 'DH4'
    when b.branchid ='MR0015' then 'DH5'
    when b.branchid ='MR0016' then 'DH6'
    when b.branchid ='HCM001' then 'DL0'
    when b.branchid ='HNI010' then 'DL1'
    when b.branchid ='NAN012' then 'DL2'
    when b.branchid ='DNG013' then 'DL3'
    when b.branchid ='KHA014' then 'DL4'
    when b.branchid ='DNI015' then 'DL5'
    when b.branchid ='CTO016' then 'DL6'
    when b.branchid ='HYN017' then 'DL7'
    else null end as mapping_donhang,

a.typ as checkin,
Case when a.updatetime is null then b.visitdate else 
a.updatetime  end as time_checkin,
a.lat,a.lng,
c.typ as checkout, 
c.updatetime  as time_checkout,
Case when b.checkintype ='Bán Hàng' then f.saordernbr
      when b.checkintype ='Giao Hàng' then e.deordernbr
      else null end as ordernbr,
e.deordernbr,
f.saordernbr,
f.ordamt,
h.tencvbh as mds,
h.tenquanlytt,
h.tenquanlykhuvuc,
h.tenquanlyvung,
k.custname,
k.statedescr,
k.address,
k.territorydescr,
k.lat as lat_dms,
k.lng as lng_dms,
k.channel,
k.shoptype,
g.role,
Case when  (b.descr ='Sai tọa độ khách hàng'or note like '%toa d_%' or note like '%toa đ_%' or note like '%tọa đ_%' or note like '%tọa d_%') then 'Y'
      else 'N' end as sai_toa_do_kh,
Case when b.imagefilename is null then 'Không có hình ảnh' else 'Có hình ảnh' end as check_hinhanh,
Case when b.distance >=0 and b.distance < 100 then 'Nhỏ hơn 100m' 
      when b.distance >=100 and b.distance <500 then 'Từ 100m - 500m'
      else 'Lớn hơn 500m' end as check_khoangcach,
l.visitdate as update_toado_visitdate,
m.tencvbh as nv_update_toadokh,
l.oldlat,
l.oldlng,
l.updatelat,
l.updatelng,
l.lupd_datetime as updatetime_toadokh,
Case when l.custid is not null then 'Y'
      else 'N' end as check_update_toa_dokh

FROM checkin_note b
LEFT JOIN data_checkin_i a on a.slsperid =b.slsperid and a.custid =b.custid and b.salesid =a.numbercico and a.checktype ='IO' and b.branchid = a.branchid
LEFT JOIN data_checkin_o c on c.slsperid =b.slsperid and c.custid =b.custid and b.salesid =c.numbercico and c.checktype ='OO' and c.branchid = a.branchid
LEFT JOIN order_checkin e on e.slsperid = b.slsperid and e.branchid = b.branchid and e.numbercico = b.salesid and b.checkintype ='Giao Hàng'
LEFT JOIN `spatial-vision-343005.staging.sync_dms_sacheckin` f on f.numbercico = b.salesid and f.slsperid = b.slsperid and f.branchid = b.branchid and b.checkintype ='Bán Hàng'
LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` g on g.username = b.slsperid  
LEFT JOIN `spatial-vision-343005.staging.d_users` h on h.manv = b.slsperid
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` k on k.custid = b.custid 
LEFT JOIN data_update_toado l on l.custid = b.custid
LEFT JOIN `staging.d_users` m on m.manv = l.lupd_user

);

Create or replace table `warehouse.f_data_checkin_mds_saitoado`

copy `staging_temp.f_data_checkin_mds_saitoado_temp`;


End;