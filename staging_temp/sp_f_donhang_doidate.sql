CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_donhang_doidate()
BEGIN 
  TRUNCATE TABLE staging_temp.f_donhang_doidate_temp;


 INSERT INTO staging_temp.f_donhang_doidate_temp(
-- Create or replace table staging_temp.f_donhang_doidate_temp as 
select 
a.ordernbr,
b.lineref,
e.custid,
e.custname,
e.channel,
e.shoptype,
e.hcoid,
e.hcotypeid,
e.shortterritorydescr,
a.orderdate,b.slsperid,c.tencvbh, remark,
b.invtid,
d.descr as tensanpham,lineqty,aftervatamount,
d.classid,
Case when d.classid ='VATTU' then 'Y' else 'N' end as is_vattu,
f.lotsernbr,
f.expdate,
a.crtd_datetime,
a.lupd_datetime,
(select max(inserted_at) from `staging.sync_dms_so` )  as inserted_at
 from `staging.sync_dms_so` a
left join `staging.sync_dms_sod1` b
ON a.branchid = b.branchid and a.ordernbr = b.ordernbr
LEFT JOIN `staging.d_users` c on b.slsperid =c.manv
LEFT JOIN staging.d_dms_master_invtid d on d.invtid = b.invtid
LEFT JOIN `staging.d_master_khachhang` e on a.custid =e.custid
LEFT JOIN `staging.sync_dms_lt` f on f.ordernbr = a.ordernbr and b.lineref =f.omlineref and f.branchid = a.branchid
where a.ordertype = 'NI' 
and a.crtd_datetime >= '2023-07-01'
order by orderdate asc
 );

Create or replace table `warehouse.f_donhang_doidate`

copy `staging_temp.f_donhang_doidate_temp`;


End;