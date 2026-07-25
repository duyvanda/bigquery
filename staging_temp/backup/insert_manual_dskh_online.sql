CREATE PROCEDURE `spatial-vision-343005`.staging_temp.insert_manual_dskh_online()
BEGIN
truncate table staging.d_dskh_mua_hang_sp_online;
INSERT INTO staging.d_dskh_mua_hang_sp_online
SELECT
cast (stt as int) as stt,
ncrm as n_crm,
crmacrm as crm_acrm,
ma_crs as crs,
-- crs,
ma_hco_tren_dms,
ten_hco,
phan_loai_hco,
dia_chi,
tinh_thanh,
phan_hang_hco,
ke_hoach_ban_online_so_luong as ke_hoach_ban_online,
-- ngay_vieng_tham,
id_user,
access_key,
active,
deleted_at,
created_at,
created_name,
created_code
FROM `spatial-vision-343005.staging.d_dskh_mua_hang_sp_online_temp`;
END;