CREATE VIEW `spatial-vision-343005.warehouse.view_tracking_cust_changes`
AS SELECT

a.lupd_datetime,
lupd_user,
version,
a.custid,
ifnull(`new`, 'unknow') as gia_tri_moi,
ifnull(`old`, 'unknow') as gia_tri_cu,
type as loai_thay_doi,
a.datatype as loai_thong_tin,
b.branchid,
b.custname,
b.channel,
b.shoptypedescr,
b.territorydescr,
b.statedescr,
c.tencvbh


FROM `spatial-vision-343005.staging.d_tracking_cust_changes` a
left join `spatial-vision-343005.staging.d_master_khachhang` b on a.custid = b.custid
left join `spatial-vision-343005.staging.d_users` c on a.lupd_user = c.manv
order by lupd_datetime desc;