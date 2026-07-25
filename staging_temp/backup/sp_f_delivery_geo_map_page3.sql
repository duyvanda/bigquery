CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_delivery_geo_map_page3()
BEGIN 
TRUNCATE TABLE staging_temp.f_delivery_geo_map_page3_temp;
INSERT INTO staging_temp.f_delivery_geo_map_page3_temp(

-- Create table `staging_temp.f_delivery_geo_map_page3_temp`
-- partition by ngaychungtu
-- as

with leadtime as 
(
  SELECT makhdms,
  date(ngaychungtu) as ngaychungtu,
  ma_dh,
  round(avg(full_leadtime),2)  as full_leadtime 
  FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2`  
  where ngaychungtu >='2023-04-01' and don_tinh_gh = 1 and trangthaigiaohang = 'Đã giao hàng'
  group by 1,2,3
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
from `staging.f_sales` 
where ngaychungtu >='2024-01-01' and makenhkh <>'OTH_LAB'
group by 1,2,3,4,5,6,7
)
,

mapping as 
(
select 'Việt Nam' as country, 
a.*,
c.base_lat,
c.base_lgn,
d.lat as lat_custid,
d.lng as lng_custid, --,
b.full_leadtime,
c.chinhanh,
e.tencvbh as ten_nvgh,
d.districtdescr,
d.wardname
from sales a 
LEFT JOIN leadtime b on a.makhdms =b.makhdms and a.ngaychungtu =b.ngaychungtu and a.sodondathang = b.ma_dh
LEFT JOIN `staging.d_tinh` c on c.tinh =a.tentinhkh
LEFT JOIN `staging.d_master_khachhang` d on d.custid =a.makhdms
LEFT JOIN `staging.d_users` e on e.manv =a.manvghreal
--where a.tentinhkh in ('Hậu Giang','Sóc Trăng','Ninh Bình')
)
,

result as 
(
  select *,
  concat(lat_custid,',',lng_custid) as geo_custid,
  round(ST_DISTANCE(ST_GEOGPOINT(base_lgn, base_lat), ST_GEOGPOINT(lng_custid, lat_custid))/1000,2) as distance_in_km
  from mapping
)

select * 
from result --where distance_in_km < @distance
where full_leadtime is not null

  );

Create or replace table `warehouse.f_delivery_geo_map_page3`

copy `staging_temp.f_delivery_geo_map_page3_temp`;

End;