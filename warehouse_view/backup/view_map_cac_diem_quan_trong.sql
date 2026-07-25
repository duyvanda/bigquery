CREATE VIEW `spatial-vision-343005.warehouse.view_map_cac_diem_quan_trong`
AS SELECT
cast (cum as STRING) as id,
diabanlamviec as name,
diabanlamviec as tinh,
'hublocation' as location_type,
ST_GEOGPOINT(lng, lat) as geo_point
FROM `spatial-vision-343005.staging.d_manual_toa_do_hub_ve_tinh_mds`
UNION ALL
SELECT
a.makhdms, 
tenkhachhang,
b.statedescr,
'sales' as location_type,
ST_GEOGPOINT(lng, lat) as geo_point
FROM `spatial-vision-343005.staging.f_sales` a
left join `staging.d_master_khachhang` b on a.makhdms = b.custid
WHERE DATE(ngaychungtu)>= '2024-01-01'
UNION ALL
SELECT
tennhathuoc,
diachi,
tinh,
'LongChau' as location_type,
ST_GEOGPOINT(lng, lat) as geo_point
FROM
`staging.d_manual_toa_do_nt_long_chau_hcm`;