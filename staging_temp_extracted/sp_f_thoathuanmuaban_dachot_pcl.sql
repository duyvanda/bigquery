-- ==========================================================================
-- Routine Name : sp_f_thoathuanmuaban_dachot_pcl
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2024-08-26 09:08:00.221000+00:00
-- Last Altered : 2024-08-26 09:08:00.221000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_thoathuanmuaban_dachot_pcl()
BEGIN
  TRUNCATE TABLE staging_temp.f_thoathuanmuaban_dachot_pcl_temp;

 INSERT INTO staging_temp.f_thoathuanmuaban_dachot_pcl_temp(

-- Create table staging_temp.f_thoathuanmuaban_dachot_pcl_temp
-- as
with -- Update từ ngày 1/4
tuyen_dms_moinhat as (
  with data_tuyen as (
    SELECT
      custid,
      slsperid,
      crtd_datetime,
      Case
        when routetype in ('B', 'D') then 1
        else 2
      end as routetype,
    FROM
      `spatial-vision-343005.staging.sync_dms_srm`
    where
      delroutedet is false --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
  )
  select
    *
  from
    (
      select
        *,
        row_number() over (
          partition by custid
          order by
            routetype asc,
            crtd_datetime desc
        ) as loc
      from
        data_tuyen
    )
  where
    loc = 1
),
---Tuyến bán hàng theo hợp đồng
tuyen_cvbh_hd as (
  with data_crs_theohopdong as (
    select
      *,
      row_number() over(
        partition by custid
        order by
          crtd_date desc
      ) as loc
    from
      `spatial-vision-343005.staging.d_get_contract_det`
  )
  select
    *
  from
    data_crs_theohopdong
  where
    loc = 1
),
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
    accumulateid in ( '202401-TL-QD974-PMC-CTD')
  group by
    1,
    2,
    3,
    4,
    5
),
-- tichluy_dachot_result
-- select *,Case when quy = 1 then date(nam,3,31)
--     when quy = 2 then date(nam,6,30)
--     when quy = 3 then date(nam,9,30)
--     when quy = 4 then date(nam,12,31)
-- else null end as month
-- from tichluy_dachot
-- where quy < extract(quarter from (select * from `staging.d_current_table`)
-- ),
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
    accumulateid in ( '202401-TL-QD974-PMC-CTD')
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

    -- LEFT JOIN tuyen_dms_moinhat c on c.custid = a.custid
    -- LEFT JOIN tuyen_cvbh_hd d on d.custid = a.custid
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
Create or replace table `warehouse.f_thoathuanmuaban_dachot_pcl`

copy `staging_temp.f_thoathuanmuaban_dachot_pcl_temp`;

End;
