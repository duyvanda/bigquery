CREATE VIEW `spatial-vision-343005.warehouse.view_f_donhang_doidate_test`
AS SELECT
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
b.crtd_datetime,
a.lupd_datetime,
(select max(inserted_at) from `staging.sync_dms_so` )  as inserted_at,
from `staging.sync_dms_so` a
left join `staging.sync_dms_sod1` b
ON a.branchid = b.branchid and a.ordernbr = b.ordernbr
LEFT JOIN `staging.d_users` c on b.slsperid =c.manv
LEFT JOIN staging.d_dms_master_invtid d on d.invtid = b.invtid
LEFT JOIN `staging.d_master_khachhang` e on a.custid =e.custid
LEFT JOIN `staging.sync_dms_lt` f on f.ordernbr = a.ordernbr and b.lineref = f.omlineref and f.branchid = a.branchid
where a.ordertype in ('NI','view_f_donhang_doidate');