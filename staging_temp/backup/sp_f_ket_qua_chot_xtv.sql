CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_ket_qua_chot_xtv()
BEGIN 
  TRUNCATE TABLE staging_temp.f_ket_qua_chot_xtv_temp;

 INSERT INTO staging_temp.f_ket_qua_chot_xtv_temp
 
(
-- Create or replace table staging_temp.f_ket_qua_chot_xtv_temp as 
SELECT 
a.invoicenbr,
a.ordernbr,
a.orderdate,
a.custid,
a.invoicecustid,
a.mds_id,
a.crs_id,
a.qty,
a.eh115,
a.t302101007,
a.oh031,
a.t302201014,
a.money300,
a.gold5,
a.gold1,
a.gold0_5,
a.qtytotal,
a.crtd_user,
a.crtd_datetime,
a.id,
a.resultdate,
b.custname,
b.channel,
b.statedescr,
b.shortterritorydescr,
b.hcotypeid,
b.branchid,
b.custidinvoice,
b.custnameinvoice,
c.tencvbh as ten_mds,
c.supid as ma_sup_mds,
c.tenquanlytt as ten_sup_mds,
d.tencvbh as ten_crs,
d.tenquanlytt as ten_sup_crs,
e.firstname as ten_nguoi_tao
 FROM `spatial-vision-343005.staging.d_bi_collect_item_result` a
 LEFT JOIN `staging.d_master_khachhang` b on a.custid =b.custid
 LEFT JOIN `staging.d_users` c on c.manv = a.mds_id
 LEFT JOIN `staging.d_users` d on d.manv = a.crs_id
 LEFT JOIN `staging.d_dms_master_users` e on e.username = a.crtd_user
 );

Create or replace table `warehouse.f_ket_qua_chot_xtv`

copy `staging_temp.f_ket_qua_chot_xtv_temp`;

End;