CREATE VIEW `spatial-vision-343005.warehouse.view_ge_giao_dich_nvl_bao_bi`
AS WITH dm_nvl AS (
  SELECT DISTINCT
    mavt,
    CASE 
      WHEN loainvlbb IN ('DC', 'TD') THEN 'NL' 
      ELSE loainvlbb 
    END AS loainvlbb,
    1 AS dm_pallet
  FROM `spatial-vision-343005.staging.d_dm_nvl_bbi` 
)

SELECT
  a.ma_kho,
  a.kho_hang,
  TRIM(a.ma_vt) AS ma_vt,
  a.ma_sp_cu,
  a.ma_sx,
  TRIM(a.ten_vt) AS ten_vt,
  a.so_luong_vt,
  a.so_luong,
  a.tien_kho,
  a.capture_date,
  a.vtth_ty_le,
  a.he_so_quy_doi,
  a.vtth_dvt,
  b.dm_pallet,
  b.loainvlbb
FROM `spatial-vision-343005.staging.f_ge_giao_dich_nvl_bao_bi` a
LEFT JOIN dm_nvl b 
  ON TRIM(b.mavt) = TRIM(a.ma_vt) 
-- Giữ nguyên cột gốc ở vế trái, ép kiểu TIMESTAMP cho vế phải bằng subquery
  where date(a.capture_date) = date(TIMESTAMP(DATE_SUB(CURRENT_DATE('Asia/Ho_Chi_Minh'), INTERVAL 1 DAY)))
  -- 2. Lọc các kho cần thiết
  AND TRIM(a.ma_kho) IN (
    'A0101', 'A0102', 'A0201', 'A0202', 'A0204', 
    'A0205', 'A0301', 'A0302', 'A04', 'A041', 
    'A042', 'A0401', 'A0402'
  );;