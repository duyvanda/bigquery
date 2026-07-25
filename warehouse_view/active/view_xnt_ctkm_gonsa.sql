CREATE VIEW `spatial-vision-343005.warehouse.view_xnt_ctkm_gonsa`
AS WITH union_all as (
SELECT
a.macongtycn,
a.sodondathang,
a.makhdms,
a.tenkhachhang,
a.makenhkh,
a.ngaychungtu,
a.discidpn,
a.masanpham,
a.tensanphamnb,
a.soluong as gia_tri,
'sellin' as type
FROM `spatial-vision-343005.warehouse.f_tongquat_ctkm` a
WHERE 
true
AND sp_kmai = 1
AND makhdms in ('016364', '016362', '016361', '016360', '016365', '016363', '016023', '016022', '016021', '016020', '016010', '014916', '014937', '014938')

UNION ALL
SELECT
a.branchid,
a.ordernbr,
a.custid,
a.custname,
b.channel,
a.crtd_datetime,
a.discidpn,
a.invtid,
a.invtname,
a.line_qty as gia_tri,
'sellout' as type
FROM`spatial-vision-343005.warehouse.view_rawdata_gonsa` a
LEFT JOIN staging.d_master_khachhang b ON b.custid = a.custid
where a.discidpn is not null
and a.free_item = 1

UNION ALL
SELECT
a.macongtycn,
a.sodondathang,
a.makhdms,
a.tenkhachhang,
a.makenhkh,
a.ngaychungtu,
a.discidpn,
a.masanpham,
a.tensanphamnb,
IFNULL(a.discamt,0) as gia_tri,
'ck_sellin' as type

FROM `spatial-vision-343005.warehouse.f_tongquat_ctkm` a
WHERE makhdms in ('016364', '016362', '016361', '016360', '016365', '016363', '016023', '016022', '016021', '016020', '016010', '014916', '014937', '014938')


UNION ALL
SELECT
a.branchid,
a.ordernbr,
a.custid,
a.custname,
b.channel,
a.crtd_datetime,
a.discidpn,
a.invtid,
a.invtname,
IFNULL(a.line_amt,0) as gia_tri,
'ck_sellout' as type

FROM `spatial-vision-343005.warehouse.view_rawdata_gonsa` a
LEFT JOIN staging.d_master_khachhang b ON b.custid = a.custid
WHERE item_type = 'Disccount'
AND a.discidpn is not null
)

SELECT
a.*EXCEPT(gia_tri),
CASE
  WHEN TYPE IN ('sellin','sellout')
  THEN gia_tri
  ELSE 0 END as soluong,
b.hieuluc,
b.denngay,
CASE
  WHEN ROW_NUMBER() OVER (PARTITION BY a.type,a.discidpn ORDER BY a.masanpham ) = 1
  AND type = 'ck_sellin'
  THEN SUM(a.gia_tri) OVER (PARTITION BY a.type,a.discidpn)
  Else 0 End as ck_sellin,

CASE
  WHEN ROW_NUMBER() OVER (PARTITION BY a.type,a.discidpn ORDER BY a.masanpham ) = 1
  AND type = 'ck_sellout'
  THEN SUM(a.gia_tri) OVER (PARTITION BY a.type,a.discidpn)
  Else 0 End as ck_sellout,

FROM union_all a
LEFT JOIN staging.d_manual_theo_doi_cpa b on b.mactdms = a.discidpn and b.kenh = a.makenhkh






















;