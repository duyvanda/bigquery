CREATE PROCEDURE `spatial-vision-343005`.staging_temp.crs_viengtham(manv STRING, ondate STRING, base_location_lgn STRING, base_location_lat STRING)
BEGIN

SELECT
a.custid,
b.custname,
b.lat, b.lng,
base_location_lgn,
base_location_lat,
round(ST_DISTANCE(ST_GEOGPOINT( cast (base_location_lgn as FLOAT64), cast (base_location_lat as FLOAT64) ), ST_GEOGPOINT(lng, lat))/1000,2) as distance_in_km,
row_number()over(order by round(ST_DISTANCE(ST_GEOGPOINT( cast (base_location_lgn as FLOAT64), cast (base_location_lat as FLOAT64) ), ST_GEOGPOINT(lng, lat))/1000,2) asc)  as stt

  FROM `spatial-vision-343005.staging.sync_dms_salesroutedet` a
  left join `spatial-vision-343005.staging.d_master_khachhang` b on a.custid = b.custid
  WHERE DATE(a.visitdate) = DATE(ondate) 
  and a.slsperid = manv
  and b.lat is not null
;
End;