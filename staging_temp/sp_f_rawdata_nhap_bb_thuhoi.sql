CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_rawdata_nhap_bb_thuhoi(p_manv1 STRING, p_version1 STRING)
OPTIONS(
  strict_mode=false)
BEGIN
-- Default values
DECLARE current_dt DATE DEFAULT CURRENT_DATE();
-- SET PARAMS
DECLARE set_manv STRING DEFAULT 'None';
DECLARE set_version STRING DEFAULT 'None';


SET set_manv = IF (p_manv1 = '', set_manv, p_manv1);
SET set_version = IF (p_version1 = '', set_version, p_version1);

INSERT INTO `warehouse.f_rawdata_nhap_bb_thuhoi`(

-- Create or replace table warehouse.f_rawdata_nhap_bb_thuhoi as
select 
a.invoicenbr,
a.ordernbr,
parse_date("%d-%m-%Y", a.order_date_string) as orderdate,
a.custid,
a.custname,
a.invoicecustid,
a.custnameinvoice,
a.mds_id,
b.tencvbh,
b.supid,
b.tenquanlytt,
ifnull(cast(a.qty as int),0) as qty,
ifnull(cast(a.eh115 as int),0) as eh115,
ifnull(cast(a.t302101007 as int),0) as t302101007,
ifnull(cast(a.oh031 as int),0) as oh031,
ifnull(cast(a.t302201014 as int),0) as t302201014,
ifnull(cast(a.money300 as int),0) as money300,
ifnull(cast(a.gold5 as int),0) as gold5,
ifnull(cast(a.gold1 as int),0) as gold1,
ifnull(cast(a.gold0_5 as int),0) as gold0_5,
a.statuscollect,
a.failcollect,
a.note,
a.crtd_user,
a.crtd_datetime,
a.uuid,
a.p_manv,
a.p_version,
current_timestamp() + interval 7 hour as inserted_at
from `staging.d_ppc_bi_collectdiscitem_by_user` a 
LEFT JOIN `staging.d_users` b on a.mds_id = b.manv
where a.p_manv = p_manv1 and a.p_version = p_version1

);


END;