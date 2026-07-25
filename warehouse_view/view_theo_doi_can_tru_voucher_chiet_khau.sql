CREATE VIEW `spatial-vision-343005.warehouse.view_theo_doi_can_tru_voucher_chiet_khau`
AS WITH ma_hd_loytalty as (
  SELECT distinct ordernbr FROM `spatial-vision-343005.staging.f_paidso_acculate` where
  AccumulateID IN (
  '202501-TL-QD884-PKN-PK',
  '202501-TL-QD885-PMC-CTD'
  )
  and date(todate) = '2025-06-30'
)

-- SELECT
-- 'Voucher Benita Xylo' as chuongtrinh,
-- s.sodondathang,
-- s.manvgh as incharge_slsperid,
-- s.nguoigiaohang as ten_mds,
-- d.supid,
-- d.tenquanlytt,
-- s.makhdms,
-- s.macongtycn,
-- s.tenkhachhang,
-- s.makenhkh,
-- s.tentinhkh,
-- s.mahco,
-- s.soluong,
-- s.masanpham,
-- s.trangthaigiaohang,
-- case when th.ketoandanhan is not null then 'thu_hoi' else 'chua_thu' end as status_thu_hoi
-- FROM `spatial-vision-343005.staging.f_sales` s 
-- LEFT JOIN `spatial-vision-343005.staging.d_users` d ON d.manv = s.manv
-- LEFT JOIN `spatial-vision-343005.staging.d_kt_thuhoi_bbgh` th ON th.noimadhsohoadon = CONCAT(sodondathang,'-',hoadon)
-- WHERE ngaychungtu >= '2025-01-01' and masanpham = 'V1HML'
-- UNION ALL
SELECT
'CK Loyalty' as chuongtrinh,
s.sodondathang,
s.manvgh as incharge_slsperid,
s.nguoigiaohang as ten_mds,
d.supid,
d.tenquanlytt,
s.makhdms,
s.macongtycn,
s.tenkhachhang,
s.makenhkh,
s.tentinhkh,
s.mahco,
null as soluong,
null as masanpham,
null as trangthaigiaohang,
case when th.thu_hoi_bang_ke_chiet_khau is not null then 'thu_hoi' else 'chua_thu' end as status_thu_hoi
FROM `spatial-vision-343005.staging.f_sales` s 
LEFT JOIN ma_hd_loytalty hd on hd.ordernbr = s.mahd
LEFT JOIN `spatial-vision-343005.staging.d_users` d ON d.manv = s.manvgh
LEFT JOIN `spatial-vision-343005.staging.d_manual_loyaltyq22025` th ON th.ma_kh_1 = s.makhdms
WHERE ngaychungtu >= '2025-01-01' and hd.ordernbr is not null;