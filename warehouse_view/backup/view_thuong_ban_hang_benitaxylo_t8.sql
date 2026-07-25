CREATE VIEW `spatial-vision-343005.warehouse.view_thuong_ban_hang_benitaxylo_t8`
AS With data_don_tra as
(
SELECT 
DISTINCT sodontrahang,
sodondathang, 
macongtycn,
manv, 
ngaychungtu 
FROM `staging.f_sales` 
where 
masanpham in ('T303102009')
and ngaychungtu >='2025-08-01' and makenhkh ='TP' and kieudonhang = 'CO'
)

,data_sales AS (
SELECT
CASE 
        WHEN l.col.phan_loai_mcp = 'Rural' THEN LEFT(l.col.ma_nvbh,6)
        WHEN a.slsperid = 'TMDT_001' THEN LEFT(l.col.ma_nvbh,6)
        WHEN a.slsperid IN (
              'MR1682KN','MR2504','MR1232','MR0806','MR2608','MR2111','MR1682','MR2504KN',
              'MR1232KN','MR0806KN','MR2608KN','MR2111KN','MR2993','MR2993KN','MR3038','MR3038KN',
              'MR2948','MR2948KN','MR2608','MR3196','MR3196KN'
          )
        THEN LEFT(l.col.ma_nvbh,6)
        ELSE a.slsperid
    END AS manv,
a.custid as makhdms,
c.custname as tenkhachhang,
c.chaNnel as makenhkh_cu,
a.crtd_datetime as ngaychungtu,
a.ordernbr as sodondathang,
b.invtid as masanpham,
--tensanphamviettat,
b.lineqty as soluong,
IF(b.beforevatprice = 0,b.slsprice,b.beforevatprice) * b.lineqty as doanhsochuavat,

CASE
  WHEN SUM(IF(a.crtd_datetime <= '2025-09-30 11:30:00',b.lineqty,0)) OVER (PARTITION BY a.ordernbr) >=5
  THEN a.custid END AS ma_kh_tinh_pp,



FROM `staging.sync_dms_pda_so` a
LEFT JOIN `staging.sync_dms_pda_sod` b on a.ordernbr = b.ordernbr and a.branchid = b.branchid
LEFT JOIN `warehouse.f_mapping_crs` l ON l.custid = a.custid
LEFT JOIN `staging.d_master_khachhang` c ON c.custid = a.custid
LEFT JOIN data_don_tra g ON a.ordernbr = g.sodontrahang

WHERE b.invtid = 'T303102009'
AND DATE(a.crtd_datetime) >= '2025-08-01'
AND DATE(a.crtd_datetime) <= '2025-10-31'
AND c.chaNnel = 'TP'
AND freeitem is false
AND a.custid not in ('014916','014937','014938')
AND a.custid not in ('016364', '016362', '016361', '016360', '016365', '016363', '016023', '016022', '016021', '016020', '016010', '014916', '014937', '014938')
AND g.sodontrahang is null
AND a.status not in ('E','V','X','D')
)

, data_sale_stt AS (
  SELECT 
  *,
  ROW_NUMBER () OVER (PARTITION BY manv) as stt
  FROM data_sales 

)


, slkh_pp as(
SELECT
CASE
  WHEN d.tenquanlytt in ('Lê Duy Chung', 'Lương Đức Tiến', 'Huỳnh Văn Huy', 'Trần Quang Luân') THEN 'Miền Bắc'
  WHEN d.tenquanlytt in ('Lê Đức Châu', 'Nguyễn Văn Án', 'Nguyễn Anh Dũng', 'Nguyễn Thanh Tài', 'Trần Thị Bích Tiền') THEN 'Miền Nam'
  ELSE NULL END AS mien,
s.manv,
d.tencvbh,
CASE 
  WHEN s.manv =  'CX' THEN 'MR1682'
        ELSE LEFT(d.supid, 6)
    END AS ma_crm,
d.tenquanlytt,
sum(if(ngaychungtu <= '2025-09-30 11:30:00',s.soluong,0)) AS soluong,
sum(if(ngaychungtu <= '2025-09-30 11:30:00',s.doanhsochuavat,0)) as tong_ds,
COUNT(DISTINCT ma_kh_tinh_pp) as slkh_tinh_pp
FROM data_sales s
LEFT JOIN `staging.d_users` d ON d.manv = s.manv
GROUP BY ALL
)

,xep_hang AS (
SELECT
*,
RANK() OVER(PARTITION BY mien ORDER BY tong_ds DESC, slkh_tinh_pp DESC) as xep_hang
FROM slkh_pp 
ORDER BY xep_hang

)

SELECT
a.*,
b.mien,
b.tencvbh,
b.ma_crm,
b.tenquanlytt,
IF(a.stt=1,b.slkh_tinh_pp,0) as slkh_tinh_pp,
IF(a.stt=1,b.tong_ds,0) as tong_ds,
IF(a.stt=1,b.xep_hang,null) as xep_hang
FROM data_sale_stt a
LEFT JOIN xep_hang b ON b.manv = a.manv
WHERE b.ma_crm is not null





;