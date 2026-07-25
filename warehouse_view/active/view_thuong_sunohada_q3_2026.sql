CREATE VIEW `spatial-vision-343005.warehouse.view_thuong_sunohada_q3_2026`
AS WITH 
data_base AS (
SELECT
  DATE(a.thang) as thang,
  DATE(a.ngaychungtu) as ngaychungtu,
  a.ma_crm,
  a.tenquanlytt,
  a.manv,
  a.tencvbh,
  a.ma_ncxm,
  a.tenquanlykhuvuc,
  a.sodondathang,
  a.makhdms,
  a.tenkhachhang,
  a.makenhkh_cu,
  a.makenhphu_cu,
  a.hcoid,
  a.maphanloaihco_cu,
  a.masanpham,
  a.tensanphamnb,
  a.soluong,
  a.doanhsochuavat,
  CONCAT(makhdms,date(thang)) AS ma_kh_tinh_pp,
  0 as kh_doanh_so,
  0 as kh_phan_phoi,
  0 as kh_crs,
  'sales' as data_type
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
where date(ngaychungtu) >='2026-07-01'
  AND date(ngaychungtu) <='2026-09-30'
  AND makenhkh_cu in ('TP')
  AND a.masanpham in ('T4040101001','T4040101002')
  AND a.is_hang_km != 'Hàng KM'
  AND a.doanhsochuavat > 0
  AND IFNULL(a.maphanloaihco_cu,'none') not in ('DLPP','PKNK')
UNION ALL
SELECT
  DATE(a.thang) as thang,
  null as ngaychungtu,
  b.supid as ma_crm,
  b.tenquanlytt,
  a.manv,
  b.tencvbh,
  b.asm as ma_ncxm,
  b.tenquanlykhuvuc,
  null sodondathang,
  null makhdms,
  null tenkhachhang,
  null makenhkh_cu,
  null makenhphu_cu,
  null hcoid,
  null maphanloaihco_cu,
  null masanpham,
  null tensanphamnb,
  null soluong,
  null doanhsochuavat,
  null ma_kh_tinh_pp,
  kh_doanh_so * 1000 as kh_doanh_so,
  kh_phan_phoi,
  Case
    when thang in ('2026-07-01','2026-08-01') then kh_phan_phoi
    else kh_doanh_so * 1000
    end as kh_crs,
  'target' as data_type
FROM `spatial-vision-343005.staging_temp.d_target_chuong_trinh_sunohada_q3_2026` a
LEFT JOIN `staging.d_users` b ON a.manv = b.manv
)
, thuc_hien_nv AS (
select
*,
case
  when data_type = 'target' then COUNT(DISTINCT ma_kh_tinh_pp) OVER (PARTITION BY manv, thang)
  else 0 end as slkh_pp_thang,
case
  when data_type = 'target' then SUM(doanhsochuavat) OVER (PARTITION BY manv, thang)
  else 0 end as th_doanhso_thang
FROM data_base
)
, tinh_ty_le_nv AS (
SELECT
*,
Case when thang in ('2026-07-01','2026-08-01') then slkh_pp_thang 
      when thang in ('2026-09-01') then th_doanhso_thang
      else 0 end as th_thang,
ROUND(SAFE_DIVIDE(
  Case when thang in ('2026-07-01','2026-08-01') then slkh_pp_thang 
      when thang in ('2026-09-01') then th_doanhso_thang
      else 0 end, 
kh_crs) * 100, 2) AS th_kh_thang,
SUM(slkh_pp_thang) OVER (PARTITION BY manv) as th_pp_quy,
SUM(th_doanhso_thang) OVER (PARTITION BY manv) as th_doanhso_quy,

ROUND(SAFE_DIVIDE(SUM(slkh_pp_thang) OVER (PARTITION BY manv), SUM(kh_phan_phoi) OVER (PARTITION BY manv)) * 100, 2) AS th_kh_pp_quy,
ROUND(SAFE_DIVIDE(SUM(th_doanhso_thang) OVER (PARTITION BY manv), SUM(kh_doanh_so) OVER (PARTITION BY manv)) * 100, 2) AS th_kh_ds_quy,
ROUND(
  (
    0.7 * ROUND(CAST(SAFE_DIVIDE(SUM(th_doanhso_thang) OVER (PARTITION BY manv), SUM(kh_doanh_so) OVER (PARTITION BY manv)) AS NUMERIC) * 100, 2) + 
    0.3 * ROUND(CAST(SAFE_DIVIDE(SUM(slkh_pp_thang) OVER (PARTITION BY manv), SUM(kh_phan_phoi) OVER (PARTITION BY manv)) AS NUMERIC) * 100, 2)
  ), 2
) as diem_thuong_quy
FROM thuc_hien_nv
)

, tinh_ty_le_ql AS (
SELECT
  DATE('2026-07-01') as thang,
  DATE('2026-07-01') ngaychungtu,
  ma_crm,
  tenquanlytt,
  ma_crm as manv,
  tenquanlytt as tencvbh,
  ma_ncxm,
  tenquanlykhuvuc,
  CAST(null AS STRING) sodondathang,
  CAST(null AS STRING) makhdms,
  CAST(null AS STRING) tenkhachhang,
  CAST(null AS STRING) makenhkh_cu,
  CAST(null AS STRING) makenhphu_cu,
  CAST(null AS STRING) hcoid,
  CAST(null AS STRING) maphanloaihco_cu,
  CAST(null AS STRING) masanpham,
  CAST(null AS STRING) tensanphamnb,
  SUM(soluong) as soluong,
  SUM(doanhsochuavat) as doanhsochuavat,
  CAST(null AS STRING) as ma_kh_tinh_pp,
  SUM(kh_doanh_so) as kh_doanh_so,
  SUM(kh_phan_phoi) as kh_phan_phoi,
  null as kh_crs,
  'Quản lý' as data_type,
  null as slkh_pp_thang,
  null as th_doanhso_thang,
  null as th_thang,
  null as th_kh_thang,
  COUNT(DISTINCT ma_kh_tinh_pp) as th_pp_quy,
  SUM(doanhsochuavat) as th_doanhso_quy,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT ma_kh_tinh_pp),SUM(kh_phan_phoi)) *100 , 2) as th_kh_pp_quy,
  ROUND(SAFE_DIVIDE(SUM(doanhsochuavat),SUM(kh_doanh_so)) *100 , 2) as th_kh_ds_quy,
  ROUND(
    (
      0.7 * ROUND(CAST(SAFE_DIVIDE(SUM(doanhsochuavat), SUM(kh_doanh_so)) AS NUMERIC) * 100, 2) + 
      0.3 * ROUND(CAST(SAFE_DIVIDE(COUNT(DISTINCT ma_kh_tinh_pp), SUM(kh_phan_phoi)) AS NUMERIC) * 100, 2)
    ), 2
  ) as diem_thuong_quy,
  null as muc_thuong_thang,
  CASE 
    WHEN ma_crm in ('MR1530','MR2438','MR1161') then 'Nhóm 2'
    ELSE 'Nhóm 1' end as nhom
FROM tinh_ty_le_nv
GROUP BY ALL
)
,xep_hang_quan_ly AS (
SELECT
  *,
  CASE 
    WHEN diem_thuong_quy >= 100 
    THEN RANK() OVER (PARTITION BY nhom ORDER BY diem_thuong_quy DESC)
    ELSE NULL 
  END as xep_hang_ql
FROM tinh_ty_le_ql
)

/* update: xếp hạng theo diem thuong quy group theo nhóm để xếp hạng */
,tinh_thuong_ql AS (
SELECT
  *,
  CASE 
    WHEN nhom = 'Nhóm 1' AND diem_thuong_quy >= 100 
         AND xep_hang_ql = 1 THEN 5000000
    WHEN nhom = 'Nhóm 1' AND diem_thuong_quy >= 100 
         AND xep_hang_ql = 2 THEN 4000000
    WHEN nhom = 'Nhóm 1' AND diem_thuong_quy >= 100 
         AND xep_hang_ql = 3 THEN 3000000
    WHEN nhom = 'Nhóm 2' AND diem_thuong_quy >= 100 
         AND xep_hang_ql = 1 THEN 3000000
    ELSE 0
  END as muc_thuong_quy
FROM xep_hang_quan_ly
)

SELECT
  *,
  -- Cột 1: Tính mức thưởng THÁNG (Chỉ điền vào dòng target)
  CASE 
    WHEN data_type = 'target' AND th_kh_thang >= 120 THEN 1000000
    WHEN data_type = 'target' AND th_kh_thang >= 110 THEN 700000
    WHEN data_type = 'target' AND th_kh_thang >= 100 THEN 500000
    ELSE 0 
  END as muc_thuong_thang,

  -- Cột 2: Tính mức thưởng QUÝ dựa trên điểm số A1 (Chỉ điền vào dòng target)
  CASE 
    WHEN data_type = 'target' AND diem_thuong_quy >= 120 THEN 2000000
    WHEN data_type = 'target' AND diem_thuong_quy >= 100 THEN 1000000
    ELSE 0 
  END as muc_thuong_quy,
  'nv' as nhom,
  null as xep_hang_ql
FROM tinh_ty_le_nv

UNION ALL
SELECT
* EXCEPT(xep_hang_ql,nhom),
nhom,
xep_hang_ql
FROM tinh_thuong_ql




;