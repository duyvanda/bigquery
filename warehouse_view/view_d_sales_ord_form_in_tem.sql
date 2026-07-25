CREATE VIEW `spatial-vision-343005.warehouse.view_d_sales_ord_form_in_tem`
AS select
orderdate,
a.branchid,
a.origordernbr,
a.batnbr,
a.status_ori,
a.invtid,
b.descr as descr1,
status_tranl,
a.custid,
d.custname,
d.address,
d.statedescr,
d.districtdescr,
d.channeldescr,
a.siteid,
qty,
lotsernbr,
expdate,
remark,
beforevatamount,
aftervatamount,
vatamount,
freeitem,
p_manv,
p_version,
a.inserted_at,
c.name,
d.chargereceive as nguoi_phu_trach_nhan_hang,
null as thung,
null as le,
null as tui
from staging.d_sales_ord_form_in_tem_by_users a
left join `spatial-vision-343005.staging.d_dms_master_invtid` b on a.invtid = b.invtid
left join `spatial-vision-343005.staging.d_dms_master_siteid` c on a.siteid = c.siteid
left join `staging.d_master_khachhang` d on a.custid = d.custid






;