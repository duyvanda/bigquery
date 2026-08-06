-- ==========================================================================
-- Routine Name : api_doanh_so_theo_ke_hoach_crs
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2025-05-19 08:42:52.276000+00:00
-- Last Altered : 2025-05-19 08:42:52.276000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.api_doanh_so_theo_ke_hoach_crs(p_ma_crs STRING, p_month STRING)
BEGIN
DECLARE current_dt DATE DEFAULT CURRENT_DATE();
DECLARE set_enddate DATE;
DECLARE set_ma_crs STRING DEFAULT 'None';
SET set_ma_crs = IF (p_ma_crs = '', set_ma_crs, p_ma_crs);
SET set_enddate = IF (p_month = '', date(date_trunc(current_dt,month)), DATE(p_month) );
SELECT
  'Detail' AS datatype,
  makhdms AS ma_kh_dms,
  a.tenkhachhang AS ten_kh,
  a.manv AS ma_crs,
  b.tencvbh AS ten_crs,
  a.crm AS ma_crm,
  a.tenquanlytt AS ten_crm,
  DATE(a.thang) AS thang,
  CURRENT_DATE("+7") AS ngay_hien_tai,
  CASE
    WHEN DATE(DATE_TRUNC(a.thang, MONTH)) < DATE_TRUNC(CURRENT_DATE("+7"), MONTH) THEN 0
    ELSE DATE_DIFF(
           DATE(DATE_TRUNC(CURRENT_DATE("+7"), MONTH) + INTERVAL 1 MONTH - INTERVAL 1 DAY),
           CURRENT_DATE("+7"),
           DAY
         )
  END AS so_ngay_con_lai,
  COUNT(DISTINCT sodondathang) AS don_hang,
  SUM(doanhsochuavat) AS doanh_so,
  SUM(kh_total) AS ke_hoach,
  SUM(0) AS ty_le
FROM `staging_temp.f_sales_crs_lhq_bytime` a
LEFT JOIN `staging.d_users_bytime` b
  ON a.manv = b.manv
  AND a.thang = b.thang
WHERE
  a.ngaychungtu >= '2024-01-01'
  AND CONTAINS_SUBSTR(CONCAT(crm, a.manv), p_ma_crs)
  AND DATE(a.thang) = set_enddate
  -- AND crs_tuyenbanhang_trongmcp NOT IN ('Rural')
  -- AND a.manv NOT IN ('OTH_LAB')
  AND a.makhdms IS NOT NULL
GROUP BY
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10

UNION ALL

SELECT
  'Overview' AS datatype,
  'NONE' AS ma_kh_dms,
  'NONE' AS ten_kh,
  a.manv AS ma_crs,
  b.tencvbh AS ten_crs,
  a.crm AS ma_crm,
  a.tenquanlytt AS ten_crm,
  DATE(a.thang) AS thang,
  CURRENT_DATE("+7") AS ngay_hien_tai,
  CASE
    WHEN DATE(DATE_TRUNC(a.thang, MONTH)) < DATE_TRUNC(CURRENT_DATE("+7"), MONTH) THEN 0
    ELSE DATE_DIFF(
           DATE(DATE_TRUNC(CURRENT_DATE("+7"), MONTH) + INTERVAL 1 MONTH - INTERVAL 1 DAY),
           CURRENT_DATE("+7"),
           DAY
         )
  END AS so_ngay_con_lai,
  COUNT(DISTINCT sodondathang) AS don_hang,
  SUM(doanhsochuavat) AS doanh_so,
  SUM(kh_total) AS ke_hoach,
  ROUND(SAFE_DIVIDE(SUM(doanhsochuavat), SUM(kh_total)) * 100, 1) AS ty_le
FROM `staging_temp.f_sales_crs_lhq_bytime` a
LEFT JOIN `staging.d_users_bytime` b
  ON a.manv = b.manv
  AND a.thang = b.thang
WHERE
  a.ngaychungtu >= '2024-01-01'
  AND CONTAINS_SUBSTR(CONCAT(crm, a.manv), p_ma_crs)
  AND DATE(a.thang) = set_enddate
  -- AND crs_tuyenbanhang_trongmcp NOT IN ('Rural')
  -- AND a.manv NOT IN ('OTH_LAB')
GROUP BY
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10
ORDER BY
  doanh_so DESC;
END;
