-- ==========================================================================
-- Routine Name : sp_f_sales_performance_thongtin_phaply
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-07-27 07:33:49.730000+00:00
-- Last Altered : 2026-07-27 07:33:49.730000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_sales_performance_thongtin_phaply()
BEGIN
-- TRUNCATE TABLE staging_temp.f_sales_performance_thongtin_phaply_temp;
-- INSERT INTO staging_temp.f_sales_performance_thongtin_phaply_temp(
Create or replace table `spatial-vision-343005.staging_temp.f_sales_performance_thongtin_phaply_temp`
as
(
with data_mcp as (
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
result2 as (
  select
    a.*,
    k.custname,
    k.statedescr,
    k.territorydescr,
    k.channel,
    k.shoptype,
    Case
      when k.classid = 'PC1' then 'KA'
      when k.classid = 'PC2' then 'KB'
      when k.classid = 'PC3' then 'KC'
      else k.classid
    end as classid,
    k.taxregnbr,
    k.phone,
    k.attn,
    date(k.legaldate) as thoihanhieulucgdpgpp,
    Case
      when k.legaldate is null then null
      when date(k.legaldate) < (
        select
          *
        from
          `staging.d_current_table`
      ) then 'Y'
      when date(k.legaldate) >= (
        select
          *
        from
          `staging.d_current_table`
      ) then 'N'
      else null
    end as is_hetthoihanhieuluc,
    Case
      when date_add(
        (
          select
            *
          from
            `staging.d_current_table`
        ),
        interval 30 day
      ) >= date(k.legaldate)
      and date(k.legaldate) > (
        select
          *
        from
          `staging.d_current_table`
      ) then 'Y'
      when k.legaldate is null then null
      else 'N'
    end as is_saphetthoihanhieuluc,
  from
    data_mcp a
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` k on k.custid = a.custid
  where
    k.active = 'Active'
),
result3 as (
  select
    *,
    Case
      when taxregnbr is not null
      and is_hetthoihanhieuluc = 'N' then 'Đầy đủ'
      when is_hetthoihanhieuluc = 'N'
      and taxregnbr is null then 'Thiếu Mã Số Thuế'
      when is_hetthoihanhieuluc = 'Y'
      and taxregnbr is not null then 'GPP hết hạn'
      when (
        is_hetthoihanhieuluc = 'Y'
        or is_hetthoihanhieuluc is null
      )
      and taxregnbr is null then 'Thiếu HSPL' -- when taxregnbr is null and thoihanhieulucgdpgpp is null then 'Thiếu HSPL'
      when thoihanhieulucgdpgpp is null
      and taxregnbr is not null then 'Thiếu GPP'
      else null
    end as is_hspl,
    Case
      when phone is not null
      and attn is not null then 'Đầy đủ'
      when phone is null
      and attn is null then 'Thiếu TTKH'
      when phone is null
      and attn is not null then 'Thiếu SDT'
      when phone is not null
      and attn is null then 'Thiếu họ & tên NLH'
      else null
    end as is_ttkh
  from
    result2
),
result4 as (
  select
    *,
    Case
      when (
        is_hspl like 'Thiếu%'
        or is_hspl = 'GPP hết hạn'
      )
      and is_ttkh like 'Thiếu%' then concat('HSPL', ' & ', 'TTKH')
      when is_hspl = 'GPP hết hạn' then 'HSPL'
      when is_hspl like 'Thiếu%' then 'HSPL'
      when is_ttkh like 'Thiếu%' then 'TTKH'
      when is_hspl like 'Đầy đủ%'
      and is_ttkh like 'Đầy đủ%' then 'Đầy đủ'
      else null
    end as is_bosung_crs
  from
    result3
)
select
  a.*,
  a.slsperid as ma_crs,
  b.tencvbh as mds,
  Case
    when b.tenquanlyvung = 'Lương Trịnh Thắng' then b.supid_bh
    else b.supid
  end as ma_crm,
  Case
    when b.tenquanlyvung = 'Lương Trịnh Thắng' then b.tenquanlytt_bh
    else b.tenquanlytt
  end as tenquanlytt,
  b.asm as ma_scrm,
  tenquanlykhuvuc,
  b.rsmid as ma_ncxm,
  tenquanlyvung
from
  result4 a -- LEFT JOIN  `view_report.d_phanquyen_trading_gmail` b on b.manv = a.slsperid
  LEFT JOIN `staging.d_users` b on b.manv = a.slsperid

	  );
Create or replace table `warehouse.f_sales_performance_thongtin_phaply`

copy `staging_temp.f_sales_performance_thongtin_phaply_temp`;

End;
