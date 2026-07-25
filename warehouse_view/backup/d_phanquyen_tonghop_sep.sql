CREATE VIEW `spatial-vision-343005.warehouse.d_phanquyen_tonghop_sep`
AS SELECT 
stt,
tenreport,
type,
id,
variable,
accessgroup,
manv,
tencvbh,
chucdanh,
congty,
phongban,
kenhphutrach,
inserted_at
FROM `spatial-vision-343005.staging.d_phanquyen_tonghop_sep`
;