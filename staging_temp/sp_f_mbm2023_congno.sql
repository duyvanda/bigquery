CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_mbm2023_congno()
BEGIN 
  TRUNCATE TABLE staging_temp.f_mbm2023_congno_temp;

 INSERT INTO staging_temp.f_mbm2023_congno_temp(

-- CREATE OR REPLACE table staging_temp.f_mbm2023_congno_temp
-- as

with congno as 
(
  SELECT CustId, inserted_at ,sum(so_du_dh) as so_du_dh,   FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` 
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
  case when (a.channel = 'OTC' AND a.shoptype = 'PK') THEN 'PCL' ELSE a.channel end as channel, 
  a.shoptype,
  a.statedescr, 
  a.districtdescr, 
  a.wardname,
  a.terms,
  a.paymentsform,
  b.phanloaiub,
  c.so_du_dh,
  c.inserted_at,
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
  left join congno c on a.custid = c.custid
  LEFT JOIN `staging.d_tinh` d on a.statedescr = d.tinh
  left join cum e on concat (a.statedescr,a.districtdescr,a.wardname) = concat(e.statedescr,e.districtdescr,e.wardname)


  where a.channel not in ('OTH_LAB','NB') or a.channel is null and a.custid not like 'DS%'
)

select * from ketqua


  );
Create or replace table `warehouse.f_mbm2023_congno`

copy `staging_temp.f_mbm2023_congno_temp`;

End;