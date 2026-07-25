CREATE VIEW `spatial-vision-343005.warehouse.view_f_delivery_geomap_doanhso`
AS with cum1 as 
(
  select 
    distinct
    statedescr,
    districtdescr,
    wardname, 
    cluster,
    cluster_state,
  from `spatial-vision-343005.staging.d_leadtimekpi`
  group by 1,2,3,4,5
)
,
cum2 as 
(
  select 
    distinct
    statedescr,
    districtdescr,
    cluster,
    cluster_state,
  from `spatial-vision-343005.staging.d_leadtimekpi`
  where districtdescr != 'Huyện Bình Chánh'
  group by 1,2,3,4
)
,

doanhso as
(
  select 
     
    a.ngaychungtu,
    a.sodondathang,
    b.custid as makhdms,
    b.statedescr as tentinhkh,
    ifnull(b.districtdescr,tenquanhuyen) as districtdescr,
    ifnull(b.wardname,phuongxa) as wardname,
    a.manv,
    case when (a.manvghreal not like 'GH%' and donvigiaohang not in ('Nhà vận chuyển','NVC') ) then a.manvghreal else null end as manvghreal,
    a.tencvbh,
    -- e.role_luong_mds_phanloai,
    case when ifnull(b.districtdescr,a.tenquanhuyen) in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' 
         else ifnull(b.districtdescr,a.tenquanhuyen) end as tenquanhuyen,
    case when b.channel in ('INS','CLC','PCL') THEN 'HCP'
         when b.channel in ('TP','DLPP','OTC') THEN 'TP'
         when b.channel in ('MT') THEN 'MT' 
         ELSE b.channel end as kenh,
    b.shoptype,
    b.shortterritorydescr,
    case when c.cluster is null then d.cluster else c.cluster end as cluster,      
    case when c.cluster_state is null then d.cluster_state else c.cluster_state end as cluster_state, 
    a.makhdms as makhdms_sales,
  sum(doanhsochuavat) as doanhsochuavat,
  from `spatial-vision-343005.staging.d_master_khachhang` b 
  left join  `spatial-vision-343005.staging.f_sales` a  on a.makhdms = b.custid 
                                                       and ngaychungtu >= '2023-01-01' 
                                                       AND a.manv NOT IN ( 'MA001', 'MA002', 'QUYNHPTA') 
                                                       and LEFT(masanpham,1) != 'V' 
  left join cum1 c on concat (b.statedescr,(case when ifnull(b.districtdescr,a.tenquanhuyen) in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' 
                                                 else ifnull(b.districtdescr,a.tenquanhuyen) end
                                           ),ifnull(b.wardname,phuongxa)
                             )
                    = concat (c.statedescr,c.districtdescr,c.wardname)
  left join cum2 d on concat (b.statedescr,(case when ifnull(b.districtdescr,a.tenquanhuyen) in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' 
                                                 else ifnull(b.districtdescr,a.tenquanhuyen) end
                                           )
                              )
                    = concat (d.statedescr,d.districtdescr)
  where      
        b.channel not in ('NB', 'OTH_LAB') 
        and b.active ='Active'
        and  market != '08'
  group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
)
select *
from doanhso;