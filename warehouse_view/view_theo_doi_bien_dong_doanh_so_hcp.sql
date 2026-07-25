CREATE VIEW `spatial-vision-343005.warehouse.view_theo_doi_bien_dong_doanh_so_hcp`
AS WITH 
-- 1. BẢNG BIẾN & THAM SỐ
vars AS (
  SELECT 
    DATE_TRUNC(CURRENT_DATE(), MONTH) as thang_hien_tai,
    DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 1 MONTH) as thang_bao_cao,
    DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 4 MONTH) as moc_3_ky,
    DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 7 MONTH) as moc_6_ky,
    0.3 as ts_tang_manh,
    0.3 as ts_giam_manh,
    10000000 as ts_chen_lech,
    5 as ts_nguong_don,
    3 as ts_nguong_sku
),

-- 2. QUÉT RAW DATA 
data_sale_raw AS (
  SELECT
    DATE_TRUNC(DATE(ngaychungtu), MONTH) as thang,
    ngaychungtu,
    a.makhdms as ma_khach_hang,
    a.tenkhachhang as ten_khach_hang,
    IFNULL(c.col.ma_nvbh,a.manv) as ma_crs,  
    IFNULL(c.tencvbh,a.tencvbh) as tencvbh,
    IFNULL(c.supid,a.ma_crm) as supid,
     IFNULL(c.tenquanlytt,a.tenquanlytt) as tenquanlytt,
    a.statedescr as tinh_thanh,
    a.makenhkh as kenh_khach_hang,
    a.masanpham,
    a.tensanphamnb,
    a.sodondathang,
    a.soluong,
    a.doanhsocovat
  FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
  LEFT JOIN `spatial-vision-343005.warehouse.dim_excluded_makhdms` b ON a.makhdms = b.makhdms
  LEFT JOIN `warehouse.f_mapping_crs` c ON c.custid = a.makhdms
  WHERE makenhkh_cu IN ('PCL', 'CLC', 'INS') 
    AND DATE(ngaychungtu) >= '2025-07-01'
    AND DATE(ngaychungtu) <= '2026-12-31'
    AND doanhsocovat <> 0
    AND b.makhdms is null
),

-- 3. ĐÁNH DẤU CẢNH BÁO & TÍNH TRUNG BÌNH CẤP KHÁCH HÀNG
kh_status AS (
  SELECT 
    ma_khach_hang,
    -- Doanh số
    SUM(CASE WHEN thang = (SELECT thang_bao_cao FROM vars) THEN doanhsocovat ELSE 0 END) as ds_thang_bao_cao,
    SUM(CASE WHEN thang BETWEEN (SELECT moc_3_ky FROM vars) AND DATE_SUB((SELECT thang_bao_cao FROM vars), INTERVAL 1 MONTH) THEN doanhsocovat ELSE 0 END) / 3 as avg_ds_3_ky,
    SUM(CASE WHEN thang BETWEEN (SELECT moc_6_ky FROM vars) AND DATE_SUB((SELECT thang_bao_cao FROM vars), INTERVAL 1 MONTH) THEN doanhsocovat ELSE 0 END) / 6 as avg_ds_6_ky,
    
    -- Số đơn
    COUNT(DISTINCT CASE WHEN thang = (SELECT thang_bao_cao FROM vars) THEN ngaychungtu END) as don_thang_bao_cao,
    COUNT(DISTINCT CASE WHEN thang BETWEEN (SELECT moc_3_ky FROM vars) AND DATE_SUB((SELECT thang_bao_cao FROM vars), INTERVAL 1 MONTH) THEN ngaychungtu END) / 3 as avg_don_3_ky,
    COUNT(DISTINCT CASE WHEN thang BETWEEN (SELECT moc_6_ky FROM vars) AND DATE_SUB((SELECT thang_bao_cao FROM vars), INTERVAL 1 MONTH) THEN ngaychungtu END) / 6 as avg_don_6_ky,
    
    -- Số SKU (Đang gọi masanpham ở đây)
    COUNT(DISTINCT CASE WHEN thang = (SELECT thang_bao_cao FROM vars) THEN masanpham END) as sku_thang_bao_cao,
    COUNT(DISTINCT CASE WHEN thang BETWEEN (SELECT moc_3_ky FROM vars) AND DATE_SUB((SELECT thang_bao_cao FROM vars), INTERVAL 1 MONTH) THEN masanpham END) / 3 as avg_sku_3_ky
  FROM data_sale_raw
  GROUP BY ma_khach_hang
),

kh_canh_bao AS (
  SELECT 
    *,
    (ds_thang_bao_cao - avg_ds_3_ky) as chenh_lech_ds,
    SAFE_DIVIDE((ds_thang_bao_cao - avg_ds_3_ky), avg_ds_3_ky) as phan_tram_bien_dong
  FROM kh_status
),

kh_final_flag AS (
  SELECT 
    ma_khach_hang,
    avg_ds_3_ky,
    avg_ds_6_ky,
    avg_don_6_ky,
    chenh_lech_ds,
    phan_tram_bien_dong,
    CASE 
      WHEN phan_tram_bien_dong >= (SELECT ts_tang_manh FROM vars) AND ABS(chenh_lech_ds) >= (SELECT ts_chen_lech FROM vars) THEN 'Tăng mạnh'
      WHEN phan_tram_bien_dong <= -(SELECT ts_giam_manh FROM vars) AND ABS(chenh_lech_ds) >= (SELECT ts_chen_lech FROM vars) THEN 'Giảm mạnh'
      WHEN avg_ds_3_ky = 0 AND ds_thang_bao_cao > 5000000 THEN 'Tái mua'
      WHEN ABS(don_thang_bao_cao - avg_don_3_ky) >= (SELECT ts_nguong_don FROM vars) THEN 'Biến động số đơn'
      WHEN ABS(sku_thang_bao_cao - avg_sku_3_ky) >= (SELECT ts_nguong_sku FROM vars) AND ABS(COALESCE(phan_tram_bien_dong, 0)) < 0.1 THEN 'Dịch chuyển SKU'
      ELSE 'Theo dõi'
    END as loai_canh_bao
  FROM kh_canh_bao
)

-- 3a. GOM TỔNG THEO TỪNG THÁNG TRƯỚC
, kh_monthly AS (
  SELECT 
    ma_khach_hang,
    thang,
    SUM(doanhsocovat) as ds_thang,
    COUNT(DISTINCT ngaychungtu) as don_thang
  FROM data_sale_raw
  GROUP BY ma_khach_hang, thang
),

-- 3b. LẤY LÙI ĐÚNG 3 THÁNG VÀ 6 THÁNG
kh_rolling AS (
  SELECT 
    a.ma_khach_hang,
    a.thang,
    -- Tính trung bình doanh số 3 tháng trước
    COALESCE(SUM(b.ds_thang), 0) / 3 as avg_ds_3_ky,
    
    -- Tính trung bình doanh số 6 tháng trước (MỚI THÊM)
    COALESCE(SUM(c.ds_thang), 0) / 6 as avg_ds_6_ky,
    SUM(c.ds_thang) as ds_6th,
    
    -- Tính trung bình số đơn 6 tháng trước
    COALESCE(SUM(c.don_thang), 0) / 6 as avg_don_6_ky 
  FROM kh_monthly a
  
  -- Join để lấy khoảng thời gian 3 tháng trước
  LEFT JOIN kh_monthly b 
    ON a.ma_khach_hang = b.ma_khach_hang 
    AND b.thang >= DATE_SUB(a.thang, INTERVAL 3 MONTH) 
    AND b.thang < a.thang
    
  -- Join để lấy khoảng thời gian 6 tháng trước
  LEFT JOIN kh_monthly c
    ON a.ma_khach_hang = c.ma_khach_hang 
    AND c.thang >= DATE_SUB(a.thang, INTERVAL 6 MONTH) 
    AND c.thang < a.thang
    
  GROUP BY a.ma_khach_hang, a.thang
)



-- [THÊM MỚI] 3d. GOM NHÓM VÀ TÍNH ROLLING 6 THÁNG THEO TỈNH
, tinh_monthly AS (
  SELECT thang, tinh_thanh, SUM(doanhsocovat) as ds_thang
  FROM data_sale_raw
  GROUP BY thang, tinh_thanh
),
tinh_rolling AS (
  SELECT a.tinh_thanh, a.thang, COALESCE(SUM(b.ds_thang), 0) / 6 as avg_ds_6_ky_tinh
  FROM tinh_monthly a
  LEFT JOIN tinh_monthly b 
    ON a.tinh_thanh = b.tinh_thanh AND b.thang >= DATE_SUB(a.thang, INTERVAL 6 MONTH) AND b.thang < a.thang
  GROUP BY a.tinh_thanh, a.thang
),

-- 3e. GOM NHÓM VÀ TÍNH ROLLING 6 THÁNG THEO CRS
crs_monthly AS (
  SELECT thang, ma_crs, SUM(doanhsocovat) as ds_thang
  FROM data_sale_raw
  GROUP BY thang, ma_crs
),
crs_rolling AS (
  SELECT a.ma_crs, a.thang, COALESCE(SUM(b.ds_thang), 0) / 6 as avg_ds_6_ky_crs
  FROM crs_monthly a
  LEFT JOIN crs_monthly b 
    ON a.ma_crs = b.ma_crs AND b.thang >= DATE_SUB(a.thang, INTERVAL 6 MONTH) AND b.thang < a.thang
  GROUP BY a.ma_crs, a.thang
)

-- 3f. GOM NHÓM VÀ TÍNH ROLLING 6 THÁNG THEO SẢN PHẨM
, sp_monthly AS (
  SELECT thang, masanpham, SUM(doanhsocovat) as ds_thang
  FROM data_sale_raw
  GROUP BY thang, masanpham
),
sp_rolling AS (
  SELECT a.masanpham, a.thang, COALESCE(SUM(b.ds_thang), 0) / 6 as avg_ds_6_ky_sp
  FROM sp_monthly a
  LEFT JOIN sp_monthly b 
    ON a.masanpham = b.masanpham AND b.thang >= DATE_SUB(a.thang, INTERVAL 6 MONTH) AND b.thang < a.thang
  GROUP BY a.masanpham, a.thang
)
-- 4. KẾT QUẢ CUỐI CÙNG 
, result as (
SELECT
  CASE WHEN date(raw.thang) = (SELECT thang_bao_cao FROM vars) THEN 'Y' ELSE 'N' END as is_thang_bao_cao,
  raw.*,
    -- Nhãn cảnh báo
  COALESCE(kf.loai_canh_bao, 'Theo dõi') as nhan_dien_bien_dong,
  CASE WHEN COALESCE(kf.loai_canh_bao, 'Theo dõi') NOT IN ('Theo dõi' ,'Giảm mạnh') THEN 'Y' ELSE 'N' END as is_kh_canh_bao,
  -- Row Numbers (STT dòng) để khử đúp khi lên BI
  -- ROW_NUMBER() OVER(PARTITION BY raw.ma_khach_hang, DATE_TRUNC(DATE(ngaychungtu), MONTH) ORDER BY ngaychungtu) as stt_dong,
  -- ROW_NUMBER() OVER(PARTITION BY tinh_thanh, DATE_TRUNC(DATE(ngaychungtu), MONTH) ORDER BY ngaychungtu) as stt_dong_tinh,
  -- ROW_NUMBER() OVER(PARTITION BY raw.ma_crs, DATE_TRUNC(DATE(ngaychungtu), MONTH) ORDER BY ngaychungtu) as stt_dong_crs,
  -- ROW_NUMBER() OVER(PARTITION BY raw.masanpham, DATE_TRUNC(DATE(ngaychungtu), MONTH) ORDER BY ngaychungtu) as stt_dong_sp

FROM data_sale_raw raw
LEFT JOIN kh_final_flag kf ON raw.ma_khach_hang = kf.ma_khach_hang

WHERE DATE(ngaychungtu) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 7 MONTH), MONTH)

)

select 
raw.*,
COALESCE(rol.avg_ds_3_ky, 0) as avg_ds_3_ky,
COALESCE(rol.avg_ds_6_ky, 0) as avg_ds_6_ky,
COALESCE(rol.avg_don_6_ky, 0) as avg_don_6_ky,
COALESCE(rol.ds_6th, 0) as ds_6th,
  
  -- Khử đúp cột chênh lệch: Chỉ hiện ở dòng đầu tiên VÀ chỉ thuộc tháng báo cáo
CASE WHEN is_thang_bao_cao = 'Y' THEN COALESCE(kf.chenh_lech_ds, 0) ELSE 0 END as chenh_lech_ds,
CASE WHEN is_thang_bao_cao = 'Y' THEN COALESCE(kf.phan_tram_bien_dong, 0) ELSE 0 END as phan_tram_bien_dong,

COALESCE(t_rol.avg_ds_6_ky_tinh, 0) as avg_ds_6_ky_tinh,
  COALESCE(c_rol.avg_ds_6_ky_crs, 0) as avg_ds_6_ky_crs,
  COALESCE(s_rol.avg_ds_6_ky_sp, 0) as avg_ds_6_ky_sp,

SUM(if (is_thang_bao_cao = 'Y', doanhsocovat, 0)) OVER (PARTITION BY raw.ma_crs) as ds_thang_bc_crs

from result raw
LEFT JOIN kh_rolling rol 
  ON raw.ma_khach_hang = rol.ma_khach_hang AND raw.thang = rol.thang

LEFT JOIN kh_final_flag kf ON raw.ma_khach_hang = kf.ma_khach_hang
LEFT JOIN tinh_rolling t_rol
  ON raw.tinh_thanh = t_rol.tinh_thanh AND raw.thang = t_rol.thang

LEFT JOIN crs_rolling c_rol
  ON raw.ma_crs = c_rol.ma_crs AND raw.thang = c_rol.thang

LEFT JOIN sp_rolling s_rol
  ON raw.masanpham = s_rol.masanpham AND raw.thang = s_rol.thang




;