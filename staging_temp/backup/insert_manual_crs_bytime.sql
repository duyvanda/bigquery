CREATE PROCEDURE `spatial-vision-343005`.staging_temp.insert_manual_crs_bytime(thang_var STRING)
BEGIN
DELETE staging.d_manual_tuyenbanhang_crs_bytime where date(thang_var) = thang;
INSERT INTO staging.d_manual_tuyenbanhang_crs_bytime
SELECT
kv,
tinhtp,
quanhuyen,
phuongxa,
macrs,
hovatencrs,
acrmcrm,
ncrm,
note,
inserted_at,
date(thang_var) as thang
FROM `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs`;
END;