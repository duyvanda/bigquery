CREATE VIEW `spatial-vision-343005.warehouse.theo_doi_binh_on_gia_TP_B1`
AS SELECT supid, 
tenquanlytt,
a.*
FROM `spatial-vision-343005.staging.f_theo_doi_binh_on_gia_tp` a
LEFT JOIN `spatial-vision-343005.staging.d_users` b ON a.slsperid = b.manv
;