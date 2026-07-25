CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_tuyen_ban()
BEGIN 
 
 TRUNCATE TABLE staging_temp.f_tuyen_ban_temp;

 INSERT INTO `staging_temp.f_tuyen_ban_temp`

(  
-- Create or replace table `staging_temp.f_tuyen_ban_temp`
-- as

with cum as
(
  select distinct statedescr,districtdescr,wardname,cluster_state
  from `spatial-vision-343005.staging.d_leadtimekpi`
)
,

cum1 as
(
  select distinct statedescr,districtdescr,cluster_state
  from `spatial-vision-343005.staging.d_leadtimekpi`
)

SELECT 
  'Vietnam' as country, 
  a.branchid,
  a.slsperid,
  a.custid,
  a.visitdate,
  b.custname,
  b.statedescr as tentinhkh,
  b.districtdescr as tenquanhuyen,
  f.tencvbh,
  concat(b.statedescr,', ', b.districtdescr) as TinhQuan,
  
  --START duy add new 11-12-2023
  case when c.cluster_state is null then d.cluster_state else c.cluster_state end as cluster_state
  --END

FROM `spatial-vision-343005.staging.sync_dms_salesroutedet`  a
left join `spatial-vision-343005.staging.d_master_khachhang` b on a.custid = b.custid
left join `spatial-vision-343005.staging.d_users` f on a.slsperid = f.manv
--START duy add new 11-12-2023
left join cum c on concat (c.statedescr,c.districtdescr,c.wardname) = concat(b.statedescr,b.districtdescr,b.wardname)
left join cum1 d on 
    concat (d.statedescr,d.districtdescr) = concat(c.statedescr,c.districtdescr) 
    and concat(c.statedescr,c.districtdescr) <>'Thành phố Hồ Chí MinhHuyện Bình Chánh'
--END

where a.visitdate >= '2023-07-01'
--a.slsperid = ('MR2676') and
-- custid = 'TN73O708' and salesrouteid = 'NDH_01' order by visitdate ASC 


);

Create or replace table `warehouse.f_tuyen_ban`

copy `staging_temp.f_tuyen_ban_temp`;

END;