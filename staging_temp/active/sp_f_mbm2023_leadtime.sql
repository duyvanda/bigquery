CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_mbm2023_leadtime()
BEGIN

TRUNCATE TABLE staging_temp.f_mbm2023_leadtime_temp;
INSERT INTO staging_temp.f_mbm2023_leadtime_temp(

-- Create table staging_temp.f_mbm2023_leadtime_temp
-- partition by date(ngaychungtu)
-- as

with doanhso1 as
(
  select 
  makhdms,
  ngaychungtu,
  sodondathang,
  case when manv in ('QUYNHPTA','MA001','MA002') then 0 else doanhsochuavat end as doanhsochuavat,
  from `spatial-vision-343005.staging.f_sales`
)
,
doanhso as
(
  select 
  makhdms,
  ngaychungtu,
  sodondathang,
  sum (doanhsochuavat) as dschuavat
  from doanhso1
  group by 1,2,3
)
,

leadtime as
(
  select 
  custid,
  ordernbr,
  ngayphathanhhd,
  avg (full_leadtime) as full_leadtime,
  from `spatial-vision-343005.warehouse.f_leadtime_new_detail1`
  group by 1,2,3
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
a.terms,
a.paymentsform,
a.statedescr, 
a.districtdescr, 
a.wardname,
a.crtd_datetime,
a.taxregnbr,
b.phanloaiub,
c.ngaychungtu,
c.sodondathang,
c.dschuavat,
-- d.ngayphathanhhd,
d.full_leadtime,
e.chinhanh as chinhanh_dialy,
f.cluster_state,
 case 
  WHEN a.channel in ('INS','CLC','PCL') THEN 'HCP'
  when (a.shoptype = 'PK') then 'HCP'
  WHEN (a.shoptype in ('PMC','SI23','CTD','SI','NT')) THEN 'TP'
  when (a.channel = 'DLPP') THEN 'TP'
  WHEN a.shoptype in ('NTC','CCD','CVS','CHUOI') THEN 'MT'
  ELSE a.channel end as kenh,

from `staging.d_master_khachhang` a
left join `spatial-vision-343005.staging.d_tinh` b on a.statecode = b.stateid
left join doanhso c on a.custid = c.makhdms
left join leadtime d on c.makhdms = d.custid  and c.ngaychungtu = d.ngayphathanhhd and c.sodondathang = d.ordernbr
left join `spatial-vision-343005.staging.d_tinh` e on a.statedescr = e.tinh 
left join cum f on concat (a.statedescr,a.districtdescr,a.wardname) = concat(f.statedescr,f.districtdescr,f.wardname)

where a.channel not in ('OTH_LAB','NB') and a.custid not like 'DS%'
)
select * from ketqua 
  );
Create or replace table `warehouse.f_mbm2023_leadtime`

copy `staging_temp.f_mbm2023_leadtime_temp`;

End;