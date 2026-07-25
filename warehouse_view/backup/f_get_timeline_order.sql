CREATE VIEW `spatial-vision-343005.warehouse.f_get_timeline_order`
AS SELECT 
a.*,
b.img1,
b.img2,
b.img3
FROM `spatial-vision-343005.staging.f_get_timeline_order` a 
LEFT JOIN `staging.view_sync_dms_bbgh_checkin` b on a.madonhang = b.ordernbr and a.machinhanh = b.branchid;