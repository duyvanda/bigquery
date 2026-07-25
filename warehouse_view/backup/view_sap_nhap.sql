CREATE VIEW `spatial-vision-343005.warehouse.view_sap_nhap`
AS SELECT
    a.ma,
    a.tentinh,
    b.truocsapnhap as tinhtruocsapnhat,
    a.loai,
    a.tenhc,
    a.cay,
    a.con,
    a.dientichkm2,
    a.dansonguoi,
    a.trungtamhc,
    a.truocsapnhap as donvitruocsapnhat
FROM `spatial-vision-343005.staging.d_sap_nhap_detail`  a
LEFT JOIN `spatial-vision-343005.staging.d_sap_nhap_header` b on staging_temp.strip_accents(a.tentinh) = staging_temp.strip_accents(b.tentinh)
-- where a.truocsapnhap like '%Quận 10%';