CREATE VIEW `spatial-vision-343005.warehouse.view_f_theo_doi_binh_on_gia_ctd`
AS SELECT
posmid,
branchid,
cpnyname,
slsperid,
firstname,
visitdate,
crtd_datetime,
custid,
custname,
descr,
custaddress,
channel,
shoptype,
hcoid,
hcotypeid,
invtid,
invtname,
suggest,
result,
resultid,
remark,
pic1,
pic2,
pic3,
pic4,
pic5,
inserted_at,
b.supid,
b.tenquanlytt
FROM `spatial-vision-343005.staging.f_theo_doi_binh_on_gia_tp` a
left join `spatial-vision-343005.staging.d_users` b on a.slsperid = b.manv
;