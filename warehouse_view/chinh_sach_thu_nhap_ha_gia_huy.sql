CREATE VIEW `spatial-vision-343005.warehouse.chinh_sach_thu_nhap_ha_gia_huy`
AS WITH data_raw as (
SELECT
a.*,
DATE(b.crtd_datetime) as ngay_ky_hd,
CASE
WHEN a.month = 6 AND DATE(b.crtd_datetime) >= '2025-06-01' THEN 'KH mới'
WHEN a.month = 7  AND DATE(b.crtd_datetime) >= '2025-07-01' THEN 'KH mới'
WHEN a.month = 8 AND DATE(b.crtd_datetime) >= '2025-08-01' THEN 'KH mới'
WHEN a.month = 9 AND DATE(b.crtd_datetime) >= '2025-09-01' THEN 'KH mới'
WHEN date(b.crtd_datetime) <= '2025-05-31' THEN  'KH cũ'
ELSE NULL END AS type_kh,
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` b on b.custid = a.makhdms
WHERE date(a.ngaychungtu) >='2025-06-01' and date(a.ngaychungtu) <='2025-09-30'
AND a.manv = 'MR3948'
AND a.makenhkh_cu in ('PCL','CLC')
AND a.is_hang_km != 'Hàng KM'
)
,slkh_moi AS (
SELECT
manv,
EXTRACT(MONTH FROM inserted_at) as thang,
COUNT(DISTINCT ten_hcp ) as slkh_moi
FROM `spatial-vision-343005.staging.d_master_hcp`
WHERE date (inserted_at) >= '2025-06-01' AND  date (inserted_at) <= '2025-09-30'
and manv='MR3948'
GROUP BY ALL
)
,do_bao_phu as (
SELECT
manv,
tencvbh,
EXTRACT(MONTH FROM thang) as thang,
makenhkh_cu,
soluong,
doanhsochuavat,
CASE
  WHEN 
  makenhkh_cu ='PCL'
  and masanpham in ('T4040101001','T4040101002')
  and SUM (soluong) OVER (PARTITION BY sodondathang )>=5
  and type_kh = 'KH mới'
  THEN makhdms
  ELSE NULL END AS kh_tinh_pp_pcl_moi,
  CASE
  WHEN 
  makenhkh_cu ='PCL'
  and masanpham in ('T4040101001','T4040101002')
  and SUM (soluong) OVER (PARTITION BY sodondathang )>=5
  and type_kh = 'KH cũ'
  THEN makhdms
  ELSE NULL END AS kh_tinh_pp_pcl_cu,
CASE
  WHEN 
  makenhkh_cu ='CLC'
  and masanpham in ('T4040101001','T4040101002')
  and SUM (soluong) OVER (PARTITION BY sodondathang )>=5
  THEN makhdms
  ELSE NULL END AS kh_tinh_pp_clc,
FROM data_raw
)
,slkh_do_bao_phu AS(
SELECT
manv,
tencvbh,
thang,
makenhkh_cu,
SUM(soluong) as soluong,
SUM(doanhsochuavat) as doanhsochuavat,
COUNT(DISTINCT kh_tinh_pp_pcl_moi ) as slkh_do_bao_phu_pcl_moi,
COUNT(DISTINCT kh_tinh_pp_pcl_cu ) as slkh_do_bao_phu_pcl_cu,
COUNT(DISTINCT kh_tinh_pp_clc ) as slkh_do_bao_phu_clc,
FROM do_bao_phu
GROUP BY ALL
)
,vieng_tham AS (
SELECT 
tencvbh,
EXTRACT(month from visitdate) as thang,
COUNT(DISTINCT ma_kh_can_vieng_tham) as slkh_can_vieng_tham,
COUNT(DISTINCT ma_kh_dat) as slkgkh_dat_vieng_tham
FROM `spatial-vision-343005.warehouse.view_f_data_checkin_pbh_v3`
WHERE tencvbh = 'Hà Gia Huy'
AND date(visitdate) >= '2025-06-01' AND date(visitdate) <= '2025-09-30'
GROUP BY ALL
)
SELECT
a.manv,
a.tencvbh,
a.thang,
a.doanhsochuavat,
b.slkh_moi,
a.slkh_do_bao_phu_pcl_moi,
a.slkh_do_bao_phu_pcl_cu,
slkh_do_bao_phu_clc,
slkh_can_vieng_tham,
slkgkh_dat_vieng_tham,
slkgkh_dat_vieng_tham/slkh_can_vieng_tham as ty_le_vt
FROM slkh_do_bao_phu a
LEFT JOIN slkh_moi b ON a.manv=b.manv and a.thang=b.thang
LEFT JOIN vieng_tham c ON a.tencvbh=c.tencvbh and a.thang=c.thang



;