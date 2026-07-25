CREATE VIEW `spatial-vision-343005.warehouse.view_f_delivery_geo_map`
AS with toado as
(
  with b1 as
  (
    select 
    custid,
    ST_GEOGPOINT(lng,lat) as geometry,
    row_number() over (partition by custid order by updatetime desc) as loc
    FROM `spatial-vision-343005.staging.d_checkin` 
    WHERE checktype = 'IO'
  )
  select * from b1 where loc = 1
)
,

toado_base as
(
  select 
    manv, 
    tencvbh,
    case when manv in ('MR1307','MR1979') then 'Khánh Hòa'
        when manv in ('MR2081') then 'Nghệ An' 
        when manv in ('MR2000','MR2168','MR2201','MR2924') then 'Thành phố Hà Nội'
        when manv in ('MR2514','MR1153') then 'Thành phố Đà Nẵng'
        when manv in ('MR0366','MR0907','MR0456','MR2554','MR0246','MR0025') then 'Thành phố Hồ Chí Minh'
        when manv in ('MR2001','MR2592','MR1664') then 'Đồng Nai'
        when manv in ('MR0831','MR0965','MR1753') then 'Thành phố Cần Thơ'
        else null end as chinhanh,
    base_lat,
    base_lgn,
    ST_GEOGPOINT(base_lgn,base_lat) as geometry_base

  from `staging.d_users` a
  left join `spatial-vision-343005.staging.d_tinh` b on 
          (case when manv in ('MR1307','MR1979') then 'Khánh Hòa'
            when manv in ('MR2081') then 'Nghệ An' 
            when manv in ('MR2000','MR2168','MR2201','MR2924') then 'Thành phố Hà Nội'
            when manv in ('MR2514','MR1153') then 'Thành phố Đà Nẵng'
            when manv in ('MR0366','MR0907','MR0456','MR2554','MR0246','MR0025') then 'Thành phố Hồ Chí Minh'
            when manv in ('MR2001','MR2592','MR1664') then 'Đồng Nai'
            when manv in ('MR0831','MR0965','MR1753') then 'Thành phố Cần Thơ'
            else null end) = b.tinh

  where role_luong_mds = 'LOG' and ST_GEOGPOINT(base_lgn,base_lat) is not null
)
,

geodata as
( 
  select 
  a.slsperid, 
  e.tencvbh,
  e.role_luong_mds,
  a.ordernbr, 
  a.delivery_date, 
  date(a.delivery_date) delivery, 
  b.custid, 
  c.statedescr,
  c.districtdescr,
  c.wardname,

  case when (ST_GEOGPOINT(c.lng, c.lat)) is null then d.geometry else (ST_GEOGPOINT(c.lng, c.lat)) end as geometry,

  lag ( case when (ST_GEOGPOINT(c.lng, c.lat)) is null then d.geometry else (ST_GEOGPOINT(c.lng, c.lat)) end) OVER (PARTITION BY a.slsperid, date(a.delivery_date) ORDER BY delivery_date ASC) AS preceding_delivery,
  
  round (st_distance(ST_GEOGPOINT(c.lng, c.lat) , lag ( case when (ST_GEOGPOINT(c.lng, c.lat)) is null then d.geometry else (ST_GEOGPOINT(c.lng, c.lat)) end) OVER (PARTITION BY a.slsperid, date(a.delivery_date) ORDER BY delivery_date ASC))/1000,2) as distance_in_km

  from staging.sync_dms_dv a
  LEFT join staging.sync_dms_so b on a.ordernbr = b.origordernbr
  LEFT JOIN staging.d_master_khachhang c on b.custid = c.custid
  LEFT JOIN toado d on b.custid = d.custid
  LEFT JOIN `staging.d_users` e on a.slsperid = e.manv
  where IFNULL(date(a.delivery_date), "1900-01-01") >= '2023-04-01' and a.status = 'C'
  -- and a.slsperid in ('MR2921') --and date(a.delivery_date) = '2023-04-28'
)
,

linestring_data as
(
  SELECT 
  a.slsperid, 
  a.tencvbh,
  a.role_luong_mds,
  a.delivery, 
  sum(a.distance_in_km) distance_in_km,
  count(distinct a.custid) as sl_kh,
  count (distinct a.ordernbr) as sl_dh,

  ST_MAKELINE(ARRAY_AGG(a.geometry ORDER BY a.delivery_date asc)) AS roadgeo,

  FROM geodata a
  LEFT JOIN toado_base b on a.slsperid = b.manv
  GROUP BY 1,2,3,4
)

select a.* ,

round(ST_LENGTH(a.roadgeo)/1000,2) as length_kh,
round(st_distance(b.geometry_base,safe.st_startpoint(a.roadgeo))/1000,2) as length_dau,
round(st_distance(safe.st_endpoint(a.roadgeo),b.geometry_base)/1000,2) as length_cuoi,

case when a.role_luong_mds = 'LOG' and (round(ST_LENGTH(a.roadgeo)/1000,2)) = 0 then ((round (st_distance(geometry_base, roadgeo)/1000,2))*2)  else (round(ST_LENGTH(a.roadgeo)/1000,2))  end as length_1kh,

from linestring_data a
left join toado_base b on a.slsperid = b.manv;