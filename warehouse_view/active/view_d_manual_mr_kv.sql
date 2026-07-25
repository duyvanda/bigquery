CREATE VIEW `spatial-vision-343005.warehouse.view_d_manual_mr_kv`
AS WITH chuan_hoa_time AS (
  SELECT 
    *,
    -- 1. Bóc tách và chuẩn hóa thời gian truyền đơn từ cột batch_num 
    -- (VD: Bóc chuỗi '09_07_2026_0830' từ '09_07_2026_0830_1' rồi chuyển thành DATETIME)
    SAFE.PARSE_DATETIME(
      '%d_%m_%Y_%H%M', 
      REGEXP_EXTRACT(batch_num, r'^\d{2}_\d{2}_\d{4}_\d{4}')
    ) AS thoi_gian_truyen_don_dt,
    
    -- 2. Chuẩn hóa Ngày giao hàng về kiểu DATETIME (Chống lỗi thiếu giờ hoặc ghi tắt ngày/tháng)
    COALESCE(
      SAFE.PARSE_DATETIME('%d/%m/%Y %H:%M:%S', ngay_giao_hang),
      CAST(SAFE.PARSE_DATE('%d/%m/%Y', ngay_giao_hang) AS DATETIME),
      CAST(SAFE.PARSE_DATE('%e/%c/%Y', ngay_giao_hang) AS DATETIME) -- Đề phòng trường hợp ghi tắt "15/7/2026"
    ) AS ngay_giao_hang_dt
  FROM `spatial-vision-343005.staging.d_manual_mr_kv`
),

tinh_sla AS (
  SELECT 
    *,
    -- 3. Tính Hạn chốt SLA dựa vào THỜI GIAN TRUYỀN ĐƠN (từ batch_num)
    CASE 
      -- TP.HCM: Truyền đơn trước 15:30 -> Hạn chốt là 23:59:59 ngày D+0
      WHEN tinhtp = 'Thành phố Hồ Chí Minh' AND EXTRACT(TIME FROM thoi_gian_truyen_don_dt) < TIME(15, 30, 0) 
        THEN DATETIME(DATE(thoi_gian_truyen_don_dt), TIME(23, 59, 59))

      -- Bình Dương: Truyền đơn trước 10:00 AM -> Hạn chốt là 11:59:00 ngày D+1
      WHEN tinhtp = 'Bình Dương' AND EXTRACT(TIME FROM thoi_gian_truyen_don_dt) < TIME(10, 0, 0) 
        THEN DATETIME(DATE_ADD(DATE(thoi_gian_truyen_don_dt), INTERVAL 1 DAY), TIME(11, 59, 0))
      -- Bình Dương: Truyền đơn từ 10:00 đến trước 15:30 -> Hạn chốt là 23:59:59 ngày D+1
      WHEN tinhtp = 'Bình Dương' AND EXTRACT(TIME FROM thoi_gian_truyen_don_dt) < TIME(15, 30, 0) 
        THEN DATETIME(DATE_ADD(DATE(thoi_gian_truyen_don_dt), INTERVAL 1 DAY), TIME(23, 59, 59))

      -- BR-VT: Truyền đơn trước 10:00 AM -> Hạn chốt là 23:59:59 ngày D+1
      WHEN tinhtp = 'Bà Rịa - Vũng Tàu' AND EXTRACT(TIME FROM thoi_gian_truyen_don_dt) < TIME(10, 0, 0) 
        THEN DATETIME(DATE_ADD(DATE(thoi_gian_truyen_don_dt), INTERVAL 1 DAY), TIME(23, 59, 59))
      -- BR-VT: Truyền đơn từ 10:00 đến trước 15:30 -> Hạn chốt là 23:59:59 ngày D+2
      WHEN tinhtp = 'Bà Rịa - Vũng Tàu' AND EXTRACT(TIME FROM thoi_gian_truyen_don_dt) < TIME(15, 30, 0) 
        THEN DATETIME(DATE_ADD(DATE(thoi_gian_truyen_don_dt), INTERVAL 2 DAY), TIME(23, 59, 59))
      
      ELSE NULL 
    END AS han_chot_sla_dt
  FROM chuan_hoa_time
)
  SELECT 
    -- Lấy toàn bộ cột gốc, bỏ các cột thời gian tạm tính
    * EXCEPT(thoi_gian_truyen_don_dt, ngay_giao_hang_dt, han_chot_sla_dt),
    
    -- Trả về Ngày giao hàng dự kiến dạng text chuẩn đẹp
    FORMAT_DATETIME('%d/%m/%Y %H:%M:%S', han_chot_sla_dt) AS ngay_giao_hang_du_kien,
    
    -- 4. Đánh giá Trễ / Đúng hạn
    CASE 
      WHEN trang_thai_giao_hang = 'Hủy đơn' THEN NULL
      
      -- Chưa giao: So sánh với Thời gian hiện tại
      WHEN ngay_giao_hang_dt IS NULL AND CURRENT_DATETIME('Asia/Ho_Chi_Minh') > han_chot_sla_dt 
        THEN 'Đơn giao trễ'
        
      -- Đã giao: So sánh với Ngày giao thực tế
      WHEN ngay_giao_hang_dt IS NOT NULL AND ngay_giao_hang_dt > han_chot_sla_dt 
        THEN 'Đơn giao trễ'
      
      ELSE NULL
    END AS don_tre
  FROM tinh_sla
;