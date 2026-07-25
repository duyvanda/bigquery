CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_mds_xnt_xuan_thinh_vuong(p_manv1 STRING, p_version1 STRING)
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

INSERT INTO `warehouse.f_mds_xnt_xuan_thinh_vuong`(

-- Create or replace table `warehouse.f_mds_xnt_xuan_thinh_vuong` as

with 

hoadon as (
  SELECT ordernbr,invoicenbr,date(orderdate) as orderdate,p_version,p_manv FROM `spatial-vision-343005.staging.d_xnt_xtv_by_user` 
  where datatype = 'xuat_the_cao' and p_version = p_version1 and p_manv =p_manv1
),

raw_data as (
SELECT 

  trim(upper(a.invtid)) invtid,
  -- a.descr as ten_hang,
  a.username as ma_mds,
  a.p_manv,
  a.p_version,
  count(date(trandate)) as so_lan_xuat,
  string_agg(cast(qty as string),",") as sl_moi_lan_xuat,
  max(date(trandate)) as ngay_nhap_xuat,
  sum(qty) as nhap_trong_ky,


 FROM `spatial-vision-343005.staging.d_xnt_xtv_by_user` a

where a.datatype ='xuat' and p_manv = p_manv1 and  p_version = p_version1
 group by 1,2,3,4
),

solo_handung as 

(
  select branchid,trim(upper(a.invtid)) invtid,username,tositeid,siteid,p_version,p_manv,lotsernbr,expdate from `spatial-vision-343005.staging.d_xnt_xtv_by_user` a
    where p_manv = p_manv1 and  p_version = p_version1
  qualify row_number() over (partition by trim(upper(a.invtid)),username,p_version,p_manv order by a.expdate desc) = 1

),

chot_xtv as 

(
SELECT trim(upper(invtid)) as invtid,mds_id,p_version,p_manv,sum(result_qty) as xuat_trong_ky FROM `spatial-vision-343005.staging.d_xnt_xtv_by_user`

 where datatype = 'chot'and result_qty is not null and p_manv = p_manv1 and  p_version = p_version1
group by 1,2,3,4
),

xuat_the_cao as 
(
  SELECT branchid,mds_id,p_manv,p_version,cast(sum(qty) as int) as sl_thecao FROM `spatial-vision-343005.staging.d_xnt_xtv_by_user` where datatype = 'xuat_the_cao'
group by 1,2,3,4 having sl_thecao >1
),
result as (
select 
ifnull(a.ngay_nhap_xuat,date(current_timestamp() +interval 7 hour)) as ngay_nhap_xuat,
ifnull(a.invtid,c.invtid) as invtid,
coalesce(ma_mds,c.mds_id,g.mds_id) as ma_mds,
f.descr as ten_hang,
ifnull(a.nhap_trong_ky,0) as nhap_trong_ky,
ifnull(c.xuat_trong_ky,0) as xuat_trong_ky,
ifnull(a.nhap_trong_ky,0) -ifnull(c.xuat_trong_ky,0) as ton_cuoi_ky,
a.so_lan_xuat,
a.sl_moi_lan_xuat,
ifnull(b.branchid,g.branchid) as branchid,
b.tositeid,
d.name as ten_kho,
b.lotsernbr as so_lo, 
parse_date("%Y-%m-%d",ifnull(left(b.expdate,10),'2026-01-01')) as han_dung,
e.tencvbh as ten_mds,
e.supid as ma_sup,
e.tenquanlytt as ten_sup,
round(safe_divide(a.nhap_trong_ky -ifnull(c.xuat_trong_ky,0),a.nhap_trong_ky)*100,2) as ty_le,
current_timestamp() + interval 7 hour as inserted_at,
coalesce(a.p_manv,c.p_manv,g.p_manv) as p_manv,
coalesce(a.p_version,c.p_version,g.p_version) as p_version,
g.sl_thecao as sl_thecao_ori,
g.sl_thecao / count(sl_thecao) over(partition by b.branchid,ifnull(ma_mds,c.mds_id),ifnull(a.p_manv,c.p_manv),ifnull(a.p_version,c.p_version)) as sl_the_cao,
'xtv' as datatype,
'' as ordernbr,
a.ngay_nhap_xuat as orderdate,
'' as custid,
'' as custname,
'' as channel,
'' as shoptype,
'' as hcoid,
'' as statedescr,
'' as shortterritorydescr,
0 as sl_thecao_chitiet,
'' invoicenbr,
date(1900,01,01) as orderdate1

from raw_data a 
LEFT JOIN solo_handung b on a.invtid = b.invtid and a.ma_mds = b.username and a.p_manv = b.p_manv and a.p_version = b.p_version
FULL JOIN chot_xtv c on a.invtid = c.invtid and a.ma_mds = c.mds_id and a.p_manv = c.p_manv and a.p_version = c.p_version
LEFT JOIN `staging.d_dms_master_siteid` d on d.siteid =b.tositeid
LEFT JOIN `staging.d_dms_master_invtid` f on f.invtid = ifnull(a.invtid,c.invtid)
FULL JOIN xuat_the_cao g on g.mds_id = ifnull(ma_mds,c.mds_id) and b.branchid = g.branchid and ifnull(a.p_version,c.p_version) = g.p_version and ifnull(a.p_manv,c.p_manv) =g.p_manv
LEFT JOIN `staging.d_users` e on e.manv = coalesce(ma_mds,c.mds_id,g.mds_id)

UNION ALL

SELECT 
PARSE_DATE('%Y-%m-%d',  left(a.orderdate,10)) as ngay_nhap_xuat,
null as invtid,
a.mds_id as ma_mds,
null as ten_hang,
null as nhap_trong_ky,
null as xuat_trong_ky,
null as ton_cuoi_ky,
null as so_lan_xuat,
null as sl_moi_lan_xuat,
a.branchid,
null as tositeid,
null as ten_kho,
null as so_lo,
null as han_dung,
c.tencvbh as ten_mds,
c.supid as ma_sup,
c.tenquanlytt as ten_sup,
null as ty_le,
null as inserted_at,
a.p_manv,
a.p_version,
null as sl_thecao_ori,
null as sl_the_cao,
'chi_tiet_xuat_the_cao' as datatype,
a.ordernbr,
PARSE_DATE('%Y-%m-%d',  left(a.orderdate,10)) as orderdate,
a.custid,
b.custname,
b.channel,
b.shoptype,
b.hcoid,
b.statedescr,
b.shortterritorydescr,
cast (a.qty as int) as sl_thecao_chitiet,
d.invoicenbr,
d.orderdate as orderdate1
 FROM `spatial-vision-343005.staging.d_xnt_xtv_by_user` a 
 LEFT JOIN `staging.d_master_khachhang` b on a.custid =b.custid
 LEFT JOIN `staging.d_users` c on c.manv = a.mds_id
 LEFT JOIN hoadon d on d.ordernbr = a.ordernbr and a.p_manv = d.p_manv and a.p_version = d.p_version
  where a.datatype = 'xuat_the_cao' and a.p_manv =p_manv1 and a.p_version =p_version1
--  group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32

)

select * from result





);


END;