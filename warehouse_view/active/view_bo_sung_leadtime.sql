CREATE VIEW `spatial-vision-343005.warehouse.view_bo_sung_leadtime`
AS SELECT 
a.crtd_datetime AS posted_datetime,
a.branchid,
a.ordernbr,
a.custid,
b.custname,
b.channel,
b.shoptype,
c.tinh,
c.tram
FROM `staging.sync_dms_pda_so` a
LEFT JOIN `staging.d_master_khachhang` b ON a.custid = b.custid
LEFT JOIN `staging.d_tinh` c ON b.statedescr = c.tinh
WHERE date(a.crtd_datetime) >= '2024-07-01'
AND status = 'C' and ordertype = 'IN';