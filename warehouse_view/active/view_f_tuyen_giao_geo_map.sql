CREATE VIEW `spatial-vision-343005.warehouse.view_f_tuyen_giao_geo_map`
AS with 
cum as
(
  select distinct statedescr,districtdescr,wardname,cluster_state
  from `spatial-vision-343005.staging.d_leadtimekpi`
)
,

cum1 as
(
  select distinct statedescr,districtdescr,cluster_state
  from `spatial-vision-343005.staging.d_leadtimekpi`
),
thongtindonhang as
(
  select distinct
    macongtycn,
    sodondathang,
    makhdms,
    tenkhachhang,
    tentinhkh,
    tenquanhuyen,
    manvghreal,
    tennvghreal,
    phuongxa,
  from `spatial-vision-343005.staging.f_sales`  
  where ngaychungtu >= '2023-07-01' --and manvghreal = 'MR2524'
)

SELECT 
  'Vietnam' as country, 
  a.slsperid,
  a.delivery_date,
  b.macongtycn,
  b.makhdms,
  b.tenkhachhang,
  b.tentinhkh,
  b.tenquanhuyen,
  b.tennvghreal,
  concat(tenquanhuyen,', ',tentinhkh) as TinhQuan,
  case when c.cluster_state is null then d.cluster_state else c.cluster_state end as cluster_state
FROM `spatial-vision-343005.staging.sync_dms_dv` a
left join thongtindonhang b on a.branchid = b.macongtycn and a.ordernbr = b.sodondathang
left join cum c on concat (c.statedescr,c.districtdescr,c.wardname) = concat(b.tentinhkh,b.tenquanhuyen,b.phuongxa)
left join cum1 d on 
    concat (d.statedescr,d.districtdescr) = concat(c.statedescr,c.districtdescr) 
    and concat(c.statedescr,c.districtdescr) <>'Thành phố Hồ Chí MinhHuyện Bình Chánh'
where a.delivery_date >= '2023-07-01' and makhdms is not null;