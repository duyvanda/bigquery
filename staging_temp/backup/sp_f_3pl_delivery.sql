CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_3pl_delivery()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_3pl_delivery_temp`;


 INSERT INTO `staging_temp.f_3pl_delivery_temp`

(   


-- Create table staging_temp.f_3pl_delivery_temp
-- partition by date(ngaychotso)
-- as

with ketqua as 
(
SELECT a.* , 
b.deliveryunitname,
c.orderstatusname as trangthaigiaohang_vnpost,
c.deliverytime as thoigiangiaohang_vnpost,
d.orders_wod_name as chinhanh_logpharma,
d.time_delivery_reality_asiabangkok as thoigiangiaohang_logpharma,
case 
  when b.deliveryunitname like 'VNPOST%'
  or a.deliveryunit = 'VNPOST' 
  or a.truckid like 'VNP%' then 'VNPOST'
  when a.deliveryunit = 'PHARMALOG' or a.deliveryunit = 'PHARMA' then 'LOG PHARMA' else b.deliveryunitname end as nvc,
e.custname,
e.branchname,
e.channel,
e.shoptype,
e.statedescr,
e.districtdescr,
e.wardname,
row_number() over (partition by a.ordernbr order by d.time_delivery_reality_asiabangkok desc) as loc,
f.crtd_datetime as ngaychotso,
f.batnbr,
g.slsperid,
h.tencvbh,
h.tenquanlytt,
h.tenquanlykhuvuc,
h.tenquanlyvung

FROM `spatial-vision-343005.staging.sync_dms_rd` a
left join `spatial-vision-343005.staging.sync_dms_ard` b on concat(a.branchid,a.deliveryunit) = concat(b.branchid,b.deliveryunitid)
left join `spatial-vision-343005.staging.d_vnpost_status` c on CONCAT (a.branchid, a.reportid) = left(c.ordercode, 21)
left join `spatial-vision-343005.staging.d_crawl_logpharma` d on CONCAT (a.branchid, a.reportid) = CONCAT (d.branchid, d.bbnh)
left join `spatial-vision-343005.staging.d_master_khachhang` e on a.custid = e.custid
left join `spatial-vision-343005.staging.sync_dms_ibd` f on concat(a.branchid,a.ordernbr) = concat(f.branchid,f.ordernbr)
left join `spatial-vision-343005.staging.sync_dms_ib` g on concat (f.branchid,f.batnbr) = concat(g.branchid,g.batnbr)
left join `spatial-vision-343005.staging.d_users` h on g.slsperid = h.manv


where a.status = 'C'
)

select *,

case 
when nvc = 'VNPOST' THEN trangthaigiaohang_vnpost
WHEN nvc = 'LOG PHARMA' AND thoigiangiaohang_logpharma IS NOT NULL THEN 'Thành công'

when nvc = 'LOG PHARMA' and thoigiangiaohang_logpharma is null then 'Khác'
else NULL end as trangthaigiaohang,

case 
when nvc = 'VNPOST' then DATETIME (thoigiangiaohang_vnpost)
when nvc = 'LOG PHARMA' THEN DATETIME (thoigiangiaohang_logpharma)
else null end as thoigiangiaohang,


case 
when trangthaigiaohang_vnpost = 'Phát thành công' and DATETIME_DIFF (thoigiangiaohang_vnpost,ngaychotso,HOUR) <= 24 then '24H'
when trangthaigiaohang_vnpost = 'Phát thành công' and ( DATETIME_DIFF (thoigiangiaohang_vnpost,ngaychotso,HOUR) > 24 and  DATETIME_DIFF (thoigiangiaohang_vnpost,ngaychotso,HOUR) <= 36) then '36H'
when trangthaigiaohang_vnpost = 'Phát thành công' and ( DATETIME_DIFF (thoigiangiaohang_vnpost,ngaychotso,HOUR) > 36 and  DATETIME_DIFF (thoigiangiaohang_vnpost,ngaychotso,HOUR) <= 48) then '48H'
when trangthaigiaohang_vnpost = 'Phát thành công' and ( DATETIME_DIFF (thoigiangiaohang_vnpost,ngaychotso,HOUR) > 48 and  DATETIME_DIFF (thoigiangiaohang_vnpost,ngaychotso,HOUR) <= 60) then '60H'
when trangthaigiaohang_vnpost = 'Phát thành công' and ( DATETIME_DIFF (thoigiangiaohang_vnpost,ngaychotso,HOUR) > 60 and  DATETIME_DIFF (thoigiangiaohang_vnpost,ngaychotso,HOUR) <= 72) then '72H'
when trangthaigiaohang_vnpost = 'Phát thành công' and DATETIME_DIFF (thoigiangiaohang_vnpost,ngaychotso,HOUR) > 72  then 'Vượt 72H'

when thoigiangiaohang_logpharma is not null and DATETIME_DIFF (thoigiangiaohang_logpharma,ngaychotso,HOUR) <= 24 then '24H'
when thoigiangiaohang_logpharma is not null and (DATETIME_DIFF (thoigiangiaohang_logpharma,ngaychotso,HOUR) > 24 and DATETIME_DIFF (thoigiangiaohang_logpharma,ngaychotso,HOUR) <= 36) then '36H'
when thoigiangiaohang_logpharma is not null and (DATETIME_DIFF (thoigiangiaohang_logpharma,ngaychotso,HOUR) > 36 and DATETIME_DIFF (thoigiangiaohang_logpharma,ngaychotso,HOUR) <= 48) then '48H'
when thoigiangiaohang_logpharma is not null and (DATETIME_DIFF (thoigiangiaohang_logpharma,ngaychotso,HOUR) > 48 and DATETIME_DIFF (thoigiangiaohang_logpharma,ngaychotso,HOUR) <= 60) then '60H'
when thoigiangiaohang_logpharma is not null and (DATETIME_DIFF (thoigiangiaohang_logpharma,ngaychotso,HOUR) > 60 and DATETIME_DIFF (thoigiangiaohang_logpharma,ngaychotso,HOUR) <= 72) then '72H'
when thoigiangiaohang_logpharma is not null and DATETIME_DIFF (thoigiangiaohang_logpharma,ngaychotso,HOUR) > 72 then 'Vượt 72H'
else null end AS leadtime




 from ketqua where loc = 1
);

 Create or replace table `warehouse.f_3pl_delivery`

copy `staging_temp.f_3pl_delivery_temp`;




END;