CREATE VIEW `spatial-vision-343005.warehouse.view_luong_hieu_qua_nha_khoa`
AS WITH data_mo_code AS (
  SELECT
    crtd_user,
    DATE(crtd_datetime) AS ngay_ky_hd,
    DATE_TRUNC(DATE(crtd_datetime), MONTH) AS thang,
    custid
  FROM `spatial-vision-343005.staging.d_master_khachhang`
  WHERE DATE(crtd_datetime) >= '2026-07-01'
    AND crtd_user IN ('MR4122','MR4151')
    AND channel = 'TP'
),
slkh_moi AS (
  SELECT
    thang,
    crtd_user AS manv,
    COUNT(DISTINCT custid) AS slkh_moi
  FROM data_mo_code
  GROUP BY ALL
),
data_sales AS (
  SELECT
    manv,
    makhdms,
    DATE_TRUNC(DATE(ngaychungtu), MONTH) AS thang,
    sodondathang,
    SUM(doanhsochuavat) AS doanhso_donhang
  FROM `spatial-vision-343005.staging_temp.f_sales_crs_lhq_bytime`
  WHERE DATE(ngaychungtu) >= '2026-07-01'
    AND manv IN ('MR4122','MR4151')
    AND makenhkh = 'TP'
  GROUP BY ALL
),
-- Gộp 2 CTE kh_mua_hang + doanh_so_tong thành 1, chỉ quét data_sales 1 lần
data_sales_agg AS (
  SELECT
    thang,
    manv,
    COUNT(DISTINCT IF(doanhso_donhang >= 500000, makhdms, NULL)) AS slkh_muahang,
    SUM(doanhso_donhang) AS tong_doanhso
  FROM data_sales
  GROUP BY thang, manv
),
-- Tính điểm thưởng từng tiêu chí, không lặp CASE WHEN
base AS (
  SELECT
    a.thang,
    a.manv,
    a.tencvbh,
    a.supid,
    a.tenquanlytt,
    a.asm,
    a.tenquanlykhuvuc,
    COALESCE(m.slkh_moi, 0) AS slkh_moi,
    COALESCE(d.slkh_muahang, 0) AS slkh_muahang,
    COALESCE(d.tong_doanhso, 0) AS tong_doanhso,
    CASE
      WHEN COALESCE(m.slkh_moi,0) >= 30 THEN 2000000
      WHEN COALESCE(m.slkh_moi,0) >= 20 THEN 1500000
      WHEN COALESCE(m.slkh_moi,0) >= 10 THEN 1000000
      ELSE 0
    END AS lhq_1,
    CASE
      WHEN COALESCE(d.slkh_muahang,0) >= 10 THEN 2000000
      WHEN COALESCE(d.slkh_muahang,0) >= 8  THEN 1500000
      WHEN COALESCE(d.slkh_muahang,0) >= 5  THEN 1000000
      ELSE 0
    END AS lhq_2,
    CASE
      WHEN COALESCE(d.tong_doanhso,0) >= 50000000 THEN 5000000
      WHEN COALESCE(d.tong_doanhso,0) >= 40000000 THEN 4000000
      WHEN COALESCE(d.tong_doanhso,0) >= 30000000 THEN 3000000
      WHEN COALESCE(d.tong_doanhso,0) >= 20000000 THEN 2000000
      WHEN COALESCE(d.tong_doanhso,0) >= 10000000 THEN 1000000
      ELSE 0
    END AS lhq_3
  FROM `spatial-vision-343005.staging.d_users_bytime` a
  LEFT JOIN slkh_moi m
    ON a.manv = m.manv
   AND DATE(a.thang) = DATE(m.thang)
  LEFT JOIN data_sales_agg d
    ON a.manv = d.manv
   AND DATE(a.thang) = DATE(d.thang)
  WHERE a.manv IN ('MR4122','MR4151')
    AND DATE(a.thang) >= '2026-07-01'
)
SELECT
  DATE(thang) AS thang,
  manv,
  tencvbh,
  supid,
  tenquanlytt,
  asm,
  tenquanlykhuvuc,
  slkh_moi,
  slkh_muahang,
  tong_doanhso,
  lhq_1,
  lhq_2,
  lhq_3,
  lhq_1 + lhq_2 + lhq_3 AS tong_lhq
FROM base
ORDER BY manv, thang;;