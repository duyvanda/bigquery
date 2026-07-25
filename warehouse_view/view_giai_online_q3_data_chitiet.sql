CREATE VIEW `spatial-vision-343005.warehouse.view_giai_online_q3_data_chitiet`
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
masanpham in ('T302203003','T302203014')
and ngaychungtu >='2025-07-01' and makenhkh ='TP' and kieudonhang = 'CO'
)


, data_raw as (
select 
a.ordernbr as sodondathang,
a.branchid as macongtycn,
a.custid as makhdms,
c.custname as ten_kh,
a.crtd_datetime as ngaychungtu,
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
b.lineqty as soluong,
IF(b.beforevatprice = 0,b.slsprice,b.beforevatprice) * b.lineqty as doanhsochuavat,
c.channel as makenhkh,
b.invtid as masanpham
FROM `staging.sync_dms_pda_so` a
LEFT JOIN `staging.sync_dms_pda_sod` b on a.ordernbr = b.ordernbr and a.branchid = b.branchid
LEFT JOIN `warehouse.f_mapping_crs` l ON l.custid = a.custid
LEFT JOIN `staging.d_master_khachhang` c ON c.custid = a.custid
LEFT JOIN data_don_tra g ON a.ordernbr = g.sodontrahang

WHERE date(a.crtd_datetime) >= '2025-07-01' AND date(a.crtd_datetime) <= '2025-10-31'  --a.crtd_datetime <= '2025-09-30 11:30:00'
and b.invtid in ('T302203003','T302203014')
and c.channel  ='TP'
and a.ordertype ='IN' 
and a.status not in ('E','V','X','D')
and freeitem is false
and g.sodontrahang IS NULL
)

SELECT
a.*,
d.tencvbh,
CASE 
  WHEN a.manv =  'CX' THEN 'MR1682'
        ELSE LEFT(d.supid, 6)
    END AS ma_crm,
d.tenquanlytt,
SUM(if(a.ngaychungtu <= '2025-09-30 11:30:00',soluong,0)) OVER (PARTITION BY a.manv) as sl_chai_theo_crs,
CASE
  WHEN SUM(if(a.ngaychungtu <= '2025-09-30 11:30:00',soluong,0)) OVER (PARTITION BY a.manv) >= 1000
  THEN 'Doanh số >= 1.000 chai'
  WHEN SUM(if(a.ngaychungtu <= '2025-09-30 11:30:00',soluong,0)) OVER (PARTITION BY a.manv) >= 800
      AND SUM(if(a.ngaychungtu <= '2025-09-30 11:30:00',soluong,0)) OVER (PARTITION BY a.manv) < 1000
  THEN '800 - Dưới 1.000 chai'
  WHEN SUM(if(a.ngaychungtu <= '2025-09-30 11:30:00',soluong,0)) OVER (PARTITION BY a.manv) >= 600
      AND SUM(if(a.ngaychungtu <= '2025-09-30 11:30:00',soluong,0)) OVER (PARTITION BY a.manv) < 800
  THEN '600 - Dưới 800 chai'
  ELSE 'Dưới 600 chai' END AS muc_doanh_thu,

FROM data_raw a
LEFT JOIN `staging.d_users` d ON d.manv = a.manv

;