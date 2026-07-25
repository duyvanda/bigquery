CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_thoathuanmuaban_dachot()
BEGIN 
  TRUNCATE TABLE staging_temp.f_thoathuanmuaban_dachot_temp;

 INSERT INTO staging_temp.f_thoathuanmuaban_dachot_temp(

-- Create table staging_temp.f_thoathuanmuaban_dachot_temp
-- as

with 

tichluy_dachot as (
  select
    branchid,
    accumulateid,
    custid,
    extract(
      quarter
      from
        closedate
    ) as quy,
    extract(
      year
      from
        closedate
    ) as nam,
    sum(accumulatedvalue) giatri_tl,
    sum(reward * cast(pass as int)) + sum(prepay * cast(pass as int)) as tienthuong_dat_tichluy,
    sum(prepay) tra_truoc,
    sum(reward * cast(pass as int)) thuong_tichluy,
    sum(rewardback * cast(pass as int)) dieuchinh_tichluy
  from
    `staging.f_accumulatedresult`
  where
    accumulateid = '202301-TL-QD01-NT-QT-PKN-PKQ'
  group by
    1,
    2,
    3,
    4,
    5
),

tichluy_datra as (
  select
    branchid,
    accumulateid,
    custid,
    extract(
      quarter
      from
        cast(todate as date)
    ) as quy,
    extract(
      year
      from
        cast(todate as date)
    ) as nam,
    sum(amt) thuong_tichluy1,
    sum(paidamt) da_tra,
  from
    `staging.f_paidso_acculate`
  where
    accumulateid = '202301-TL-QD01-NT-QT-PKN-PKQ'
  group by
    1,
    2,
    3,
    4,
    5
),
result as (
  select
    a.*,
    ifnull(b.da_tra, 0) as da_tra -- ,ifnull(b.thuong_tichluy1,0) as thuong_tichluy1
,
Case
      when a.quy = 1 then date(a.nam, 3, 31)
      when a.quy = 2 then date(a.nam, 6, 30)
      when a.quy = 3 then date(a.nam, 9, 30)
      when a.quy = 4 then date(a.nam, 12, 31)
      else null
    end as month,
    l.col.ma_nvbh as ma_crs -- from tichluy_dachot
    -- where
  from
    tichluy_dachot a
    LEFT JOIN tichluy_datra b on a.branchid = b.branchid
    and a.accumulateid = b.accumulateid
    and a.custid = b.custid
    and a.quy = b.quy
    and a.nam = b.nam
    LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a.custid 

),
result1 as (
  select
    a.*
  except
(ma_crs, custid),
    a.custid as makhdms,
    d.custname as tenkhachhang,
    d.statedescr as filter_tinh,
    d.channel,
    a.ma_crs as crtd_user -- ,t3.tencvbh tencvbh1
,
Case
      when t5.tenquanlyvung = 'Lương Trịnh Thắng' then t5.supid_bh
      else t5.supid
    end as ma_crm,
    t5.asm as ma_scrm,
    LEFT(t5.rsmid, 6) as ma_ncxm,
    t5.tencvbh tencvbh,
Case
      when t5.tenquanlyvung = 'Lương Trịnh Thắng' then t5.tenquanlytt_bh
      else t5.tenquanlytt
    end as tenquanlytt,
    t5.tenquanlykhuvuc as tenquanlykhuvuc,
    t5.tenquanlyvung as tenquanlyvung
  from
    result a
    LEFT JOIN `staging.d_users` b on b.manv = a.ma_crs 
    left join `spatial-vision-343005.staging.d_users` t5 on a.ma_crs = t5.manv
    LEFT JOIN `staging.d_master_khachhang` d on d.custid = a.custid
)
select
  *
from
  result1
  );
Create or replace table `warehouse.f_thoathuanmuaban_dachot`

copy `staging_temp.f_thoathuanmuaban_dachot_temp`;

End;