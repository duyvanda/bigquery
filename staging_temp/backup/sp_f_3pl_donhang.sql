CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_3pl_donhang()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_3pl_donhang_temp`;


 INSERT INTO `staging_temp.f_3pl_donhang_temp`


(
-- Create table staging_temp.f_3pl_donhang_temp
-- partition by date(crtd_datetime)
-- as
with ketqua as 
(
SELECT a.* , 
b.deliveryunitname,
c.orderstatusname as trangthaigiaohang_vnpost,
c.deliverytime as thoigiangiaohang_vnpost,
c.id,
c.orderstatusid,
d.orders_wod_name as chinhanh_logpharma,
d.time_delivery_reality_asiabangkok as thoigiangiaohang_logpharma,
case 
  when deliveryunitname like 'VNPOST%'
  or deliveryunit = 'VNPOST' 
  or truckid like 'VNP%' then 'VNPOST'
  when deliveryunit = 'PHARMALOG' or deliveryunit = 'PHARMA' then 'LOG PHARMA' else 'Khác' end as nvc,
e.custname,
e.channel,
e.shoptype,
e.statedescr,
e.districtdescr,
e.wardname,
row_number() over (partition by ordernbr order by c.orderstatusid asc) as loc


FROM `spatial-vision-343005.staging.sync_dms_rd` a
left join `spatial-vision-343005.staging.sync_dms_ard` b on concat(a.branchid,a.deliveryunit) = concat(b.branchid,b.deliveryunitid)
left join `spatial-vision-343005.staging.d_vnpost_status` c on CONCAT (a.branchid, a.reportid) = left(c.ordercode, 21)
left join `spatial-vision-343005.staging.d_crawl_logpharma` d on CONCAT (a.branchid, a.reportid) = CONCAT (d.branchid, d.bbnh)
left join `spatial-vision-343005.staging.d_master_khachhang` e on a.custid = e.custid
where status = 'C'
)

select * from ketqua where loc = 1

 );

Create or replace table `warehouse.f_3pl_donhang`

copy `staging_temp.f_3pl_donhang_temp`;




END;