-- ==========================================================================
-- Routine Name : sp_f_luonghieuqua_sds
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-02-04 02:14:06.388000+00:00
-- Last Altered : 2026-02-04 02:14:06.388000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_luonghieuqua_sds()
BEGIN
TRUNCATE TABLE staging_temp.f_luonghieuqua_sds_temp;
INSERT INTO staging_temp.f_luonghieuqua_sds_temp

(
-- Create or replace table staging_temp.f_luonghieuqua_sds_temp as
WITH diaban_lamviec AS (
  SELECT
    manv,
    thang,
    STRING_AGG(statedescr, ',') AS diaban
  FROM (
    SELECT DISTINCT
      manv,
      thang,
      statedescr
    FROM `staging_temp.f_sales_crs_lhq_bytime`
    WHERE ngaychungtu >= '2024-01-01'
    ORDER BY 1, 2, 3
  )
  GROUP BY 1, 2
)
,   f_baocao_daily_performance_mds_new_v2_fix as
(
SELECT
* except(thang),
DATE_TRUNC(ngaygiaohang_fix, MONTH) AS thang,
FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2`
where date(ngaychungtu)>= '2025-04-01' and trangthaigiaohang = 'Đã giao hàng' --and date(ngaygiaohang_fix)<=  '2025-12-31'
and makenhkh not in ('EXP', 'ECE')
)
, ds_giaohang AS (
  SELECT
    thang,
    ma_nvgh_tinhluong,
    SUM(dschuvat_giaohang) AS dschuavat_giaohang
  FROM `f_baocao_daily_performance_mds_new_v2_fix`
  WHERE thang >= '2024-01-01'
  GROUP BY 1, 2
)
, sl_kh_pcl_thang_phucap AS (
  SELECT
    DATE(DATE_TRUNC(ngaychungtu, MONTH)) AS thang,
    ma_nvgh_tinhluong,
    COUNT(DISTINCT makhdms) AS sl_kh_pcl_phucap
  FROM `f_baocao_daily_performance_mds_new_v2_fix`
  WHERE
    ngaychungtu >= '2024-01-01'
    AND makenhkh = 'PCL'
    AND don_tinh_gh = 1
  GROUP BY 1, 2
),
sl_kh_thang AS (
  WITH sl_kh_pcl_theo_ngay AS (
    SELECT
      ngaychungtu,
      DATE(DATE_TRUNC(ngaychungtu, MONTH)) AS thang,
      ma_nvgh_tinhluong,
      COUNT(DISTINCT makhdms) AS sl_kh_pcl
    FROM `f_baocao_daily_performance_mds_new_v2_fix`
    WHERE
      ngaychungtu >= '2024-01-01'
      AND don_tinh_gh = 1
    GROUP BY 1, 2, 3
  )
  SELECT
    thang,
    ma_nvgh_tinhluong,
    SUM(sl_kh_pcl) AS sl_kh_pcl
  FROM sl_kh_pcl_theo_ngay
  GROUP BY 1, 2
),
data_sales AS (
  SELECT
    a.manv,
    a.tencvbh,
    a.tenquanlytt,
    LEFT(a.crm, 6) AS crm,
    a.ncxm,
    a.tenquanlyvung,
    'S' AS cap_bac,
    DATE(a.thang) AS thang,
    'TP' AS makenhkh,
    SUM(doanhsochuavat) AS doanhsochuavat,
    SUM(kh_total) AS kh_total,
    ROUND(SAFE_DIVIDE(SUM(doanhsochuavat), SUM(kh_total)) * 100, 1) AS th_kpi
  FROM `staging_temp.f_sales_crs_lhq_bytime` a
  LEFT JOIN `staging.d_users_bytime` b
    ON a.manv = b.manv AND a.thang = b.thang
  WHERE
    a.ngaychungtu >= '2024-01-01'
    AND crs_tuyenbanhang_trongmcp NOT IN ('Rural')
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
),
mapping AS (
  SELECT
    a.thang,
    a.manv,
    a.tencvbh,
    a.makenhkh,
    a.cap_bac,
    a.tenquanlytt,
    a.crm,
    a.ncxm,
    a.tenquanlyvung,
    a.doanhsochuavat,
    a.kh_total,
    a.th_kpi,
    c.dschuavat_giaohang,
    d.sl_kh_pcl,
    CASE
      WHEN a.th_kpi < 80 THEN a.doanhsochuavat * 2.6 / 100
      WHEN a.th_kpi BETWEEN 80 AND 89.99 THEN a.doanhsochuavat * 3.0 / 100
      WHEN a.th_kpi BETWEEN 90 AND 99.99 THEN a.doanhsochuavat * 3.2 / 100
      WHEN a.th_kpi BETWEEN 100 AND 109.99 THEN a.doanhsochuavat * 3.4 / 100
      WHEN a.th_kpi >= 110 THEN a.doanhsochuavat * 3.6 / 100
      ELSE NULL
    END AS lhq1,
    CASE
      WHEN c.dschuavat_giaohang < 250000000 THEN d.sl_kh_pcl * 18000
      WHEN c.dschuavat_giaohang >= 250000000 THEN d.sl_kh_pcl * 20000
      ELSE NULL
    END AS lhq2,
    e.sl_kh_pcl_phucap * 20000 AS phu_cap_t1,
    e.sl_kh_pcl_phucap,
    b.chucdanhengtitlesum AS chuc_danh,
    CASE
      WHEN b.thang IS NULL THEN NULL
      WHEN b.loaihdld IS NULL THEN 'NGHỈ VIỆC'
      ELSE TRIM(UPPER(b.loaihdld))
    END AS loaihdld,
    DATE(b.ngaykyhdldchinhthuc) AS ngaykyhdldchinhthuc,
    DATE(b.ngayvaolamonboarddate) AS ngayvaolamvc,
    f.diaban AS diabanlamviec,
    b.phongdeptsummary as phong_ban
  FROM data_sales a
  JOIN `staging.d_hr_dsns_bytime` b
    ON b.msnvcsmmoi = a.manv
    AND DATE(a.thang) = DATE(b.thang)
    AND b.chucdanhengtitlesum LIKE '%SDS%'
  LEFT JOIN ds_giaohang c
    ON a.manv = c.ma_nvgh_tinhluong
    AND DATE(a.thang) = DATE(c.thang)
  LEFT JOIN sl_kh_thang d
    ON d.thang = a.thang
    AND d.ma_nvgh_tinhluong = a.manv
  LEFT JOIN sl_kh_pcl_thang_phucap e
    ON e.thang = a.thang
    AND e.ma_nvgh_tinhluong = a.manv
  LEFT JOIN diaban_lamviec f
    ON a.manv = f.manv
    AND DATE(a.thang) = DATE(f.thang)
)

SELECT
  a.* EXCEPT(lhq1, lhq2, phu_cap_t1,phong_ban),
  CASE
    WHEN loaihdld IN ('HỌC VIỆC', 'THỬ VIỆC', 'NGHỈ VIỆC') THEN 0
    WHEN phong_ban = 'SC' THEN 0
    ELSE lhq1
  END AS lhq1,
  CASE
    WHEN loaihdld IN ('HỌC VIỆC', 'THỬ VIỆC', 'NGHỈ VIỆC') THEN 0
    WHEN phong_ban = 'SC' THEN 0
    ELSE lhq2
  END AS lhq2,
  CASE
    WHEN loaihdld IN ('HỌC VIỆC', 'THỬ VIỆC', 'NGHỈ VIỆC') THEN 0
    WHEN phong_ban = 'SC' THEN 0
    ELSE phu_cap_t1
  END AS phu_cap_t1,
  'Công ty cổ phần tập đoàn Merap' AS phaply,
  (
    SELECT MAX(inserted_at)
    FROM staging.f_sales
    WHERE inserted_at IS NOT NULL
  ) AS inserted_at
FROM mapping a
);

Create or replace table `warehouse.f_luonghieuqua_sds`

copy `staging_temp.f_luonghieuqua_sds_temp`;

End;
