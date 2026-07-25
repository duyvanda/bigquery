CREATE VIEW `spatial-vision-343005.warehouse.view_toa_do_mds`
AS SELECT
stt,
sanrale,
hoten,
phong,
diabanlamviec,
cum,
diachi,
ghichu,
lat,
lng,
ST_GEOGPOINT(lng, lat) as geo_point
FROM `spatial-vision-343005.staging.d_manual_toa_do_hub_ve_tinh_mds`
;