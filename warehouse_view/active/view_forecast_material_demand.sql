CREATE VIEW `spatial-vision-343005.warehouse.view_forecast_material_demand`
AS WITH raw_forecast AS (
    /* Dữ liệu gốc Forecast từ Staging */
    SELECT 
        masp, 
        month, 
        kenh, 
        fcvalues, 
        revised_date
    FROM `spatial-vision-343005.staging.d_forecast_sc`
),

cleaned_forecast AS (
    /* Logic lọc Forecast version:
       1. Group by SP, Tháng và Ngày sửa đổi để tính tổng volume.
       2. Dùng QUALIFY với DENSE_RANK để chỉ giữ lại phiên bản mới nhất.
    */
    SELECT 
        masp,
        month,
        SUM(fcvalues) AS total_forecast_qty
    FROM raw_forecast
    GROUP BY masp, month, revised_date
    QUALIFY DENSE_RANK() OVER(PARTITION BY masp, month ORDER BY revised_date DESC) = 1
),

normalized_bom AS (
    /* Chuẩn hóa bảng BOM (Định mức):
       - Tính định mức cho 1 đơn vị sản phẩm = value / dm1
       - Sử dụng SAFE_DIVIDE để tránh lỗi chia cho 0.
       - UPDATE: Lọc bỏ các dòng mavt bị NULL ngay tại đây (Dữ liệu rác).
    */
    SELECT 
        ma_thanh_pham,
        mavt,
        tenvt,
        dvt,
        SAFE_DIVIDE(value, dm1) AS dinh_muc_don_vi
    FROM `spatial-vision-343005.staging.d_dm_nvl_bbi`
    WHERE dm1 IS NOT NULL 
      AND dm1 != 0
      AND mavt IS NOT NULL /* Lọc rác: Bỏ các dòng định mức không có mã vật tư */
)

/* Kết hợp Forecast và BOM.
   Dùng LEFT JOIN: Giữ lại tất cả Forecast kể cả khi chưa có BOM.
*/
SELECT 
    f.month AS thang,
    f.masp AS ma_thanh_pham,
    
    /* Thông tin vật tư (Sẽ NULL nếu không join được BOM sạch) */
    b.mavt AS ma_vat_tu,
    b.tenvt AS ten_vat_tu,
    b.dvt AS don_vi_tinh,
    
    /* CỘT GỐC: Dùng để tính toán */
    f.total_forecast_qty AS tong_san_luong_du_bao,
    
    /* CỘT HIỂN THỊ: Deduped (Chỉ hiện dòng đầu tiên) */
    CASE 
        WHEN ROW_NUMBER() OVER(PARTITION BY f.masp, f.month ORDER BY b.mavt) = 1 
        THEN f.total_forecast_qty 
        ELSE NULL 
    END AS tong_san_luong_du_bao_hien_thi,
    
    b.dinh_muc_don_vi AS dinh_muc_tieu_chuan,
    (f.total_forecast_qty * b.dinh_muc_don_vi) AS tong_nhu_cau_vat_tu,
    
    /* CỜ BÁO TRẠNG THÁI (FLAG) */
    CASE 
        WHEN b.mavt IS NULL THEN 'Chưa khai định mức'
        ELSE 'Có khai định mức' 
    END AS trang_thai_dinh_muc
    
FROM cleaned_forecast f
LEFT JOIN normalized_bom b 
    ON f.masp = b.ma_thanh_pham;;