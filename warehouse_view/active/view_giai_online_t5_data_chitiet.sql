CREATE VIEW `spatial-vision-343005.warehouse.view_giai_online_t5_data_chitiet`
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
and ngaychungtu >='2025-05-13' and makenhkh ='TP' and kieudonhang = 'CO'
)

,data_raw AS(
select 
a.ordernbr, -- sodondathang
a.branchid, -- macongtycn
a.custid, --makhdms
c.custname,
a.crtd_datetime as crtd_datetime_ori,
CASE 
      WHEN a.ordernbr='DL6-0525-01075' THEN '2025-05-14 00:00:00'
      WHEN a.crtd_datetime > '2025-05-13 17:30:00' AND a.crtd_datetime < '2025-05-14 00:00:00' THEN DATETIME_ADD(a.crtd_datetime, INTERVAL 7 HOUR)
      ELSE a.crtd_datetime 
      END AS crtd_datetime, -- giờ post đơn
time(a.crtd_datetime) as crtd_time,
b.slsperid, -- mã nv
-- mapping lại cột mã NV
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
d.tencvbh AS ten_nv,
CASE 
  WHEN b.slsperid =  'CX' THEN 'MR1682'
        ELSE LEFT(d.supid, 6)
    END AS ma_crm,
d.tenquanlytt as crm,
Case when b.slsperid ='TMDT_001' then 'Ecom'
else 'Merap' end as is_ecom,
b.lineqty as soluong, --so luong ori
IF(b.beforevatprice = 0,b.slsprice,b.beforevatprice) * b.lineqty as Doanh_so_chuaVAT,
c.channel as makenhkh,
b.invtid as masanpham,
CASE
  WHEN 
  c.channel= 'TP'
  AND SUM (b.lineqty) OVER (PARTITION BY a.ordernbr,b.invtid )>=5
  THEN a.custid END AS ma_kh_tinh_pp
FROM `staging.sync_dms_pda_so` a
LEFT JOIN `staging.sync_dms_pda_sod` b on a.ordernbr = b.ordernbr and a.branchid = b.branchid
LEFT JOIN `warehouse.f_mapping_crs` l ON l.custid = a.custid
LEFT JOIN `staging.d_master_khachhang` c ON c.custid = a.custid
LEFT JOIN `staging.d_users` d ON d.manv = a.slsperid
LEFT JOIN data_don_tra g ON a.ordernbr = g.sodontrahang
where date(a.crtd_datetime) >='2025-05-13' and a.crtd_datetime <='2025-06-30 11:30:00' -- THAY NGÀY THỰC TẾ CHẠY CT
and a.ordertype ='IN' 
and a.status not in ('E','V','X','D') -- Bỏ các đơn hàng đóng
and b.invtid in ('T302203003','T302203014') -- thay đổi khi có sp thực tế
and c.chaNnel  ='TP'
and freeitem is false
and g.sodontrahang IS NULL
)

SELECT
*
FROM data_raw a
inner join staging.d_he_so_tinh_thuong_crm_tp b ON b.ma_ql = a.ma_crm
--WHere a.ordernbr = 'DL5-0525-00968'

;