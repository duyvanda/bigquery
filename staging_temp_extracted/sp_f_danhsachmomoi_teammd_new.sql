-- ==========================================================================
-- Routine Name : sp_f_danhsachmomoi_teammd_new
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2023-10-12 08:57:07.961000+00:00
-- Last Altered : 2023-10-12 08:57:07.961000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danhsachmomoi_teammd_new()
BEGIN
  TRUNCATE TABLE staging_temp.f_danhsachmomoi_teammd_new_temp;

 INSERT INTO staging_temp.f_danhsachmomoi_teammd_new_temp(

-- Create or replace table staging_temp.f_danhsachmomoi_teammd_new_temp
-- as
with data_crs as
(
  with data_tuyen as
  (
    SELECT
      thang,
      custid,
      slsperid,
      crtd_datetime,
      Case when routetype in ('B','D') then 1 else 2 end as routetype,
    FROM `spatial-vision-343005.staging.sync_dms_srm_bytime`
    where delroutedet is false
  )
  select *
  from (
         select   *,
         row_number() over (partition by custid,thang order by routetype asc,crtd_datetime desc) as loc
         from data_tuyen
       )
  where loc =1
)
,
dso_khachhang as
(
  select
    a.thang,
    a.makhdms,
    sum(a.doanhsocovat) as doanhsocovat
  from `spatial-vision-343005.staging.f_sales` a
  LEFT JOIN data_crs b on a.makhdms = b.custid and a.thang = b.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users_bytime`  c on (case when a.manv = 'TMDT_001' then b.slsperid else a.manv end) = c.manv and a.thang = c.thang
  WHERE
      c.tenquanlytt = 'Nguyễn Văn Tiến'
      and ngaychungtu >= '2023-04-01'
  group by 1,2
)
,
dso_ecom_khachhang as
(
  select
    DISTINCT
    DATETIME_TRUNC(TIMESTAMP (a.ngaychungtu), MONTH) as thang,
    a.makhdms,
    sum(doanhsocovat) as doanhsocovat
  FROM `spatial-vision-343005.staging.f_sales` a
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_pda_so` b on a.sodondathang = b.ordernbr and a.makhdms = b.custid
  WHERE a.ngaychungtu >= '2023-04-01'
    and (b.slsperid = 'TMDT_001' OR crtd_user = 'TMDT_001')
    and b.status = 'C'
  group by 1,2
)
,
doanhso_thang4 as
(
  SELECT
    DATETIME_TRUNC(timestamp (a.ngaychungtu), MONTH) as thang,
    a.inserted_at,
    a.sodondathang,
    a.makhdms,
    a.tenkhachhang,
    a.ngaychungtu,
    a.manv,
    b.slsperid,
    c.tencvbh,
    c.supid_bh,
    c.tenquanlytt_bh,
    case when a.manv = 'TMDT_001' then b.slsperid else a.manv end as macrs,
    sum(doanhsocovat) as doanhsocovat
  FROM `spatial-vision-343005.staging.f_sales` a
  LEFT JOIN data_crs b on a.makhdms = b.custid and a.thang = b.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users_bytime`  c on (case when a.manv = 'TMDT_001' then b.slsperid else a.manv end) = c.manv and a.thang = c.thang
  WHERE
      c.tenquanlytt = 'Nguyễn Văn Tiến'
      and ngaychungtu >= '2023-04-01'
  GROUP BY 1,2,3,4,5,6,7,8,9,10,11
)
,
doanhso_thang4_don250 as
(
  with loc_don250 as
  (
    SELECT *,
      row_number() over(partition by makhdms,thang order by ngaychungtu asc) as loc,
    FROM doanhso_thang4
    WHERE doanhsocovat >= 250000
  )
  select *
  from loc_don250
  where loc = 1
)
,
kh_ecom_codon as
(
  SELECT
  DISTINCT
  DATETIME_TRUNC(TIMESTAMP (a.ngaychungtu), MONTH) as thang,
  a.makhdms
  FROM `spatial-vision-343005.staging.f_sales` a
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_pda_so` b on a.sodondathang = b.ordernbr and a.makhdms = b.custid
  WHERE
  a.ngaychungtu >= '2023-04-01'
  and (b.slsperid = 'TMDT_001' OR crtd_user = 'TMDT_001')
  and b.status = 'C'
  and a.makhdms in ( select distinct customer_code from `spatial-vision-343005.staging.f_crawl_activate_ecom`)
)
,
danhsach_kh_momoi as
(
  select a.*
  from doanhso_thang4_don250 a
  left join `spatial-vision-343005.staging.f_kh_has_sales` b on a. makhdms = b.makhdms and a.thang = b.thang
  where b.makhdms is null
)
,
result as
(
  select
    a.inserted_at,
    a.thang,
    a.makhdms ,
    a.tenkhachhang,
    a.macrs,
    a.tencvbh,
    a.supid_bh,
    a.tenquanlytt_bh,
    b.makhdms as kh_ecom,
    c.channel,
    c.shoptype,
    case when DATETIME_TRUNC(DATETIME (c.crtd_datetime), MONTH) >= DATETIME_TRUNC(DATETIME (a.ngaychungtu), MONTH) then a.makhdms else null end as kh_new,
    case when DATETIME_TRUNC(DATETIME (c.crtd_datetime), MONTH) < DATETIME_TRUNC(DATETIME (a.ngaychungtu), MONTH) then a.makhdms else null end as kh_repeated,
    d.created_at as ngay_active,
    case when d.created_at is not null and b.makhdms  is not null then a.makhdms else null end as kh_active,
    e.doanhsocovat,
    f.doanhsocovat as ds_ecom

  from danhsach_kh_momoi a
  left join kh_ecom_codon b on a.makhdms = b.makhdms and a.thang = b.thang
  left join `staging.d_master_khachhang` c on a.makhdms = c.custid
  left join `spatial-vision-343005.staging.f_crawl_activate_ecom` d on a.makhdms = d.customer_code
  left join dso_khachhang e on a.makhdms = e.makhdms and a.thang = e.thang
  left join dso_ecom_khachhang f on a.makhdms = f.makhdms and a.thang = f.thang
  -- group by 1,2,3,4,5,6,7
)
select *
from result
-- where makhdms = 'N07020423'
 );
Create or replace table `warehouse.f_danhsachmomoi_teammd_new`

copy `staging_temp.f_danhsachmomoi_teammd_new_temp`;

End;
