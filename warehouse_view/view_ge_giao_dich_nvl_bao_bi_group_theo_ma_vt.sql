CREATE VIEW `spatial-vision-343005.warehouse.view_ge_giao_dich_nvl_bao_bi_group_theo_ma_vt`
AS WITH groupby_vt AS
(
  SELECT
    ma_vt,
    ten_vt,
    capture_date,
    MAX(loainvlbb) AS loainvlbb,
    SUM(so_luong_vt) AS tong_so_luong,
    -- Sử dụng SAFE_DIVIDE để tránh lỗi chia cho 0
    SAFE_DIVIDE(SUM(tien_kho), SUM(so_luong_vt)) AS don_gia
  FROM `warehouse.view_ge_giao_dich_nvl_bao_bi`
  GROUP BY ALL
)

SELECT
  a.*,
  
  -- Lấy số lượng tồn min/max (nếu null thì gán = 0)
  IFNULL(b.ton_min, 0) AS ton_min,
  IFNULL(b.ton_max, 0) AS ton_max,
  
  -- Tạo cột giá trị tồn min/max = đơn giá * số lượng (nếu null thì gán = 0)
  IFNULL(a.don_gia * b.ton_min, 0) AS gia_tri_ton_min,
  IFNULL(a.don_gia * b.ton_max, 0) AS gia_tri_ton_max

FROM `groupby_vt` a
LEFT JOIN `staging.d_manual_gs_ton_kho_min_max_nvl` b ON a.ma_vt = b.ma_vt;;