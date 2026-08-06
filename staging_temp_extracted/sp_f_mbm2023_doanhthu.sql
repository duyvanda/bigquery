-- ==========================================================================
-- Routine Name : sp_f_mbm2023_doanhthu
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2023-07-17 03:16:00.468000+00:00
-- Last Altered : 2023-07-17 03:16:00.468000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_mbm2023_doanhthu()
BEGIN
  TRUNCATE TABLE staging_temp.f_mbm2023_doanhthu_temp;

 INSERT INTO staging_temp.f_mbm2023_doanhthu_temp(
-- Create table staging_temp.f_mbm2023_doanhthu_temp
-- partition by orderdate
-- as
with doanhthu as
(
  select
    custid,
    orderdate,
    sum(sotien_da_thanhtoan) as sotien_da_thanhtoan
  from `staging_temp.d_rawdata_debt_detail`
  group by 1,2
)
,
cum as
(
  select distinct statedescr,districtdescr,wardname,cluster_state
  from `spatial-vision-343005.staging.d_leadtimekpi`
)
,
ketqua as
(
  select
  a.branchid,
  a.branchname,
  a.custid,
  a.custname,
  a.active,
  a.channel,
  a.shoptype,
  a.statedescr,
  a.districtdescr,
  a.wardname,
  a.terms,
  a.paymentsform,
  b.phanloaiub,
  c.orderdate,
  c.sotien_da_thanhtoan,
  d.chinhanh as chinhanh_dialy,
  e.cluster_state,
  case
    WHEN a.channel in ('INS','CLC','PCL') THEN 'HCP'
    when (a.shoptype = 'PK') then 'HCP'
    WHEN (a.shoptype in ('PMC','SI23','CTD','SI','NT')) THEN 'TP'
    when (a.channel = 'DLPP') THEN 'TP'
    WHEN a.shoptype in ('NTC','CCD','CVS','CHUOI') THEN 'MT'
    ELSE a.channel end as kenh,
  from `staging.d_master_khachhang` a
  left join `spatial-vision-343005.staging.d_tinh` b on a.statecode = b.stateid
  left join doanhthu c on a.custid = c.custid
  left join `spatial-vision-343005.staging.d_tinh` d on a.statedescr = d.tinh
  left join cum e on concat (a.statedescr,a.districtdescr,a.wardname) = concat(e.statedescr,e.districtdescr,e.wardname)

  where a.channel not in ('OTH_LAB','NB') or a.channel is null and a.custid not like 'DS%'
)

select * from ketqua
  );
Create or replace table `warehouse.f_mbm2023_doanhthu`

copy `staging_temp.f_mbm2023_doanhthu_temp`;

End;
