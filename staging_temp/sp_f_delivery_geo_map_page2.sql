CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_delivery_geo_map_page2()
BEGIN 
  TRUNCATE TABLE staging_temp.f_delivery_geo_map_page2_temp;

 INSERT INTO staging_temp.f_delivery_geo_map_page2_temp(

-- CREATE OR REPLACE table `staging_temp.f_delivery_geo_map_page2_temp`
-- partition by ngaychungtu
-- as

with leadtime as 
(
  SELECT 
  sodondathang,
  makhdms,
  date(ngaychungtu) as ngaychungtu,
  date(ngaygiaohang_fix) as ngaygiaohang,
  avg(full_leadtime_1) as full_leadtime 
  FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2`  
  where ngaychungtu >='2023-01-01'--and don_tinh_gh = 1 --and trangthaigiaohang = 'Đã giao hàng'
  group by 1,2,3,4
)
,

sales as 
(
  select 
    sodondathang,
    date(ngaychungtu) as ngaychungtu,
    manvghreal,
    makhdms,
    tenkhachhang,
    tentinhkh,
    makenhkh,
    sum(doanhsochuavat) as ds,
    count(distinct sodondathang) as sl_dh 
  from  `spatial-vision-343005.staging.f_sales`
  where makenhkh not in ('NB', 'OTH_LAB') AND manv NOT IN ( 'MA001', 'MA002', 'QUYNHPTA') and LEFT(masanpham,1) != 'V' and ngaychungtu >= '2023-01-01'
  group by 1,2,3,4,5,6,7
)
,

cum as
(
  select 
    distinct statedescr, 
    case when districtdescr in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' 
         when districtdescr = 'Huyện Đảo Cồn Cỏ' then 'Huyện Cồn Cỏ' else districtdescr end districtdescr,
    wardname,
    cluster,
    cluster_state,
    hubcum,
    hubtinh,
    hubcon,
  from `spatial-vision-343005.staging.d_leadtimekpi`
)
,

cum2 as
(
  select 
    distinct statedescr,
    case when districtdescr in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' 
         when districtdescr = 'Huyện Đảo Cồn Cỏ' then 'Huyện Cồn Cỏ' else districtdescr end districtdescr,   
    cluster,       
    cluster_state,
    hubcum,
    hubtinh,
    hubcon,
  from `spatial-vision-343005.staging.d_leadtimekpi`
  where  districtdescr != 'Huyện Bình Chánh'
)
,

mapping as 
(
  select 'Vietnam' as country, 
    a.*,
    c.base_lat,
    c.base_lgn,
    c.tinhviethoa,
    d.lat as lat_custid,
    d.lng as lng_custid ,
    b.full_leadtime,
    b.ngaygiaohang,
    c.chinhanh,
    e.tencvbh as ten_nvgh,
    case when d.districtdescr in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' else d.districtdescr end districtdescr,
    d.wardname
  from sales a 
  LEFT JOIN leadtime b on a.makhdms =b.makhdms and a.ngaychungtu = b.ngaychungtu and a.sodondathang = b.sodondathang
  LEFT JOIN `staging.d_tinh` c on c.tinh =a.tentinhkh
  LEFT JOIN `staging.d_master_khachhang` d on d.custid = a.makhdms
  LEFT JOIN `staging.d_users` e on e.manv =a.manvghreal
-- --where a.tentinhkh in ('Hậu Giang','Sóc Trăng','Ninh Bình')
)
,

result as 
(
  select a.*,
    case when b.cluster is null then c.cluster else b.cluster end as cluster,
    case when b.cluster_state is null then c.cluster_state else b.cluster_state end as cluster_state  ,
    case when b.hubcum is null then c.hubcum else b.hubcum end as hubcum  ,
    case when b.hubtinh is null then c.hubtinh else b.hubtinh end as hubtinh  ,
    case when b.hubcon is null then c.hubcon else b.hubcon end as hubcon  ,

    concat(a.lat_custid,',',a.lng_custid) as geo_custid,
    round(ST_DISTANCE(ST_GEOGPOINT(a.base_lgn, a.base_lat), 
                      ST_GEOGPOINT(a.lng_custid, a.lat_custid))/1000,2) as distance_in_km
  from mapping a
  left join cum b on concat(a.tentinhkh,a.districtdescr,a.wardname) = concat(b.statedescr,b.districtdescr,b.wardname)
  left join cum2 c on concat(a.tentinhkh,a.districtdescr) = concat(c.statedescr,c.districtdescr)
)

select
  a.*except(hubcum), 
-- case when a.cluster in ('7','8') then '0611, 0711, 0811' 
-- when a.cluster in ('25','27') then '2511, 2611, 2711'
-- else a.hubcum end hubcum,
-- case when a.cluster in ('7','8') then 'Quận 10, HCM' 
-- when a.cluster in ('25','27') then 'Quận Cầu Giấy, HA NOI'        
-- else concat(districtdescr,', ',tinhviethoa) end as TinhQuan  
hubcum as hubcum,
'' as TinhQuan
from result a
-- where cluster ='26' and hubcum is not null



  );

Create or replace table `warehouse.f_delivery_geo_map_page2`

copy `staging_temp.f_delivery_geo_map_page2_temp`;

End;