CREATE VIEW `spatial-vision-343005.warehouse.view_d_date_check`
AS SELECT 
c.answer, 
o.slsperid, 
o.custid, 
b.custname,
o.visitdate,
o.imagefilename,
a.tencvbh,
a.supid,
a.tenquanlytt,
c.salesid,
o.distance,
Case when o.descr ='Sai tọa độ khách hàng' then 'Có' else 'Không' end as is_check_mds_checkin_gh_saitoado,
FROM `spatial-vision-343005.staging.d_date_check`  c
LEFT JOIN `staging.sync_dms_oc`  o on c.salesid = o.salesid and o.visitdate >= '2025-09-01'
left join `spatial-vision-343005.staging.d_users` a on o.slsperid = a.manv
LEFT JOIN staging.d_master_khachhang b ON b.custid = o.custid;