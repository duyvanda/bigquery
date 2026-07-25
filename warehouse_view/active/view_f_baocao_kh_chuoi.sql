CREATE VIEW `spatial-vision-343005.warehouse.view_f_baocao_kh_chuoi`
AS with data_sales as 
(
  select 
  a.macongtycn,
  a.congtycn,
  a.makhdms,
  a.tenkhachhang,
  a.makenhkh,
  a.makenhphu,
  a.sodondathang,
  a.kieudonhang,
  a.mahd,
  a.trangthai,
  a.lineref,
  a.hoadon,
  a.ngaychungtu, 
  a.masanpham,
  a.tensanphamnb,
  sum(soluong) as soluong,
  sum(doanhsochuavat) as doanhsochuavat
from `spatial-vision-343005.staging.f_sales` a
where a.makenhkh = 'MT' AND a.masanpham not like 'V%' AND a.ngaychungtu >= '2025-01-01' 
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
)

select
  'acd' as abc,
  CONCAT(makhdms,"|",tenkhachhang) as ma_ten_kh,
  a.macongtycn,
  a.congtycn,
  a.makhdms,
  a.tenkhachhang,
  a.makenhkh,
  a.makenhphu,
  a.sodondathang,
  a.kieudonhang,
  a.mahd,
  a.trangthai,
  c.invcnote as kyhieu_hoadon,
  a.hoadon,
  a.ngaychungtu, 
  a.masanpham,
  a.tensanphamnb,
  b.taxcat as vat,
  a.soluong,
  a.doanhsochuavat as doanhsochuavat_lamtron,
  case when a.kieudonhang in ('IR','CO','OO') THEN - b.beforevatamount else b.beforevatamount end as doanhsochuavat,
  b.beforevatprice,
  case when a.kieudonhang in ('IR','CO','OO') THEN - b.aftervatamount ELSE b.aftervatamount end as aftervatamount,
  case when a.kieudonhang in ('IR','CO','OO') and (b.discamt + b.docdiscamt + b.groupdiscamt1) <> 0 THEN -(b.discamt + b.docdiscamt + b.groupdiscamt1) else (b.discamt + b.docdiscamt + b.groupdiscamt1) end as tong_ck,
  
from data_sales a
left join  `spatial-vision-343005.staging.sync_dms_sod1` b on a.macongtycn = b.branchid and a.mahd = b.ordernbr and a.masanpham = b.invtid and a.lineref = b.lineref 
left join `spatial-vision-343005.staging.sync_dms_so` c on a.macongtycn = c.branchid and a.mahd = c.ordernbr


UNION ALL

SELECT
  'abc' AS abc,
  CONCAT(b.custid, ' - ', b.custname) AS ma_ten_kh,
  b.branchid AS macongtycn,
  b.branchname AS congtycn,
  a.custid AS makhdms,
  b.custname AS tenkhachhang,
  b.channel AS makenhkh,
  b.shoptype AS makenhphu,
  o.origordernbr AS sodondathang,
  CAST(NULL AS STRING) AS kieudonhang,
  CAST(NULL AS STRING) AS mahd,
  CAST(NULL AS STRING) AS trangthai,
  a.serial AS kyhieu_hoadon,
  a.invcnbr AS hoadon,
  CAST(a.orderdate AS TIMESTAMP) AS ngaychungtu,
  CAST(NULL AS STRING) AS masanpham,
  a.prodname AS tensanphamnb,
  CAST(a.vatrate AS STRING) AS vat,
  CAST(NULL AS FLOAT64) AS soluong,
  CAST(a.total*-1 AS FLOAT64) AS doanhsochuavat_lamtron,
  CAST(a.total*-1 AS FLOAT64) AS doanhsochuavat,
  CAST(NULL AS FLOAT64) AS beforevatprice,
  CAST(NULL AS FLOAT64) AS aftervatamount,
  CAST(NULL AS FLOAT64) AS tong_ck
FROM `spatial-vision-343005.staging.sync_log_invoiceinfo` a
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` b 
  ON a.custid = b.custid
INNER JOIN `staging.sync_dms_so` o ON o.BranchID = a.BranchID AND o.OrderNbr = a.OrderNbr

WHERE a.code IS NULL 
  AND b.channel = 'MT' 
  AND a.total IS NOT NULL;

;