CREATE VIEW `spatial-vision-343005.warehouse.view_bao_cao_tong_quan_tp_vieng_tham`
AS SELECT 
    DATETIME_TRUNC(a.ngay, MONTH) AS thang,
    EXTRACT(MONTH FROM a.ngay) AS thang_number,
    a.manv,
    a.tencvbh,
    a.supid,
    a.tenquanlytt,
    b.asm,
    tenquanlykhuvuc,
    
    -- Tổng số ngày cần chấm công trong Tháng
    SUM(a.ngay_cong_co_dinh) AS so_ngay_can_cham_cong,
    
    -- Tổng số ngày ngày công làm việc trong Tháng
    SUM(a.quy_doi_ngay_cong) AS tong_so_ngay_cong_lam_viec,
    SUM(ngay_nghi_co_ly_do) as tong_so_ngay_nghi_phep,
    
    -- Tổng số ngày công làm việc còn thiếu trong Tháng
    SUM(a.ngay_cong_co_dinh) - SUM(ngay_nghi_co_ly_do) - SUM(a.quy_doi_ngay_cong) AS so_ngay_cong_lam_viec_con_thieu,

    -- Tổng số ngày (buổi) có call đầu tiên buổi SÁNG CHECK IN sau 9h45 (đến ngày hiện tại, không tính nghỉ phép)
    COUNT(DISTINCT CASE 
        WHEN a.ngay_cong_co_dinh > 0 
        AND IFNULL(a.ngay_nghi_co_ly_do, 0) = 0
        AND DATE(a.ngay) <= CURRENT_DATE('Asia/Ho_Chi_Minh')
        AND TIME(a.vt_dau_tien_truoc_12pm) > TIME '09:45:00' 
        THEN a.ngay 
    END) AS so_ngay_call_dau_tien_sang_sau_9h45,

    -- Tổng số ngày (buổi) không làm việc buổi SÁNG (đến ngày hiện tại, không tính nghỉ phép)
    COUNT(DISTINCT CASE 
        WHEN a.ngay_cong_co_dinh > 0 
        AND IFNULL(a.ngay_nghi_co_ly_do, 0) = 0
        AND DATE(a.ngay) <= CURRENT_DATE('Asia/Ho_Chi_Minh')
        AND a.vt_dau_tien_truoc_12pm IS NULL 
        THEN a.ngay 
    END) AS so_ngay_khong_lam_viec_buoi_sang,

    -- Tổng số ngày (buổi) có call cuối cùng buổi CHIỀU CHECK OUT trước 16h00 (đến ngày hiện tại, không tính nghỉ phép)
    COUNT(DISTINCT CASE 
        WHEN a.ngay_cong_co_dinh > 0 
        AND IFNULL(a.ngay_nghi_co_ly_do, 0) = 0
        AND DATE(a.ngay) <= CURRENT_DATE('Asia/Ho_Chi_Minh')
        AND a.checkout_cuoi_cung_trong_ngay IS NOT NULL 
        AND TIME(a.checkout_cuoi_cung_trong_ngay) < TIME '16:00:00' 
        THEN a.ngay 
    END) AS so_ngay_call_cuoi_ngay_ket_thuc_truoc_16h00,

    -- Tổng số ngày (buổi) không làm việc buổi CHIỀU (đến ngày hiện tại, không tính nghỉ phép)
    COUNT(DISTINCT CASE 
        WHEN a.ngay_cong_co_dinh > 0 
        AND IFNULL(a.ngay_nghi_co_ly_do, 0) = 0
        AND DATE(a.ngay) <= CURRENT_DATE('Asia/Ho_Chi_Minh')
        AND a.vt_dau_tien_sau_12pm IS NULL 
        THEN a.ngay 
    END) AS so_ngay_khong_lam_viec_buoi_chieu

FROM `spatial-vision-343005.warehouse.view_quan_ly_cham_cong_pkh` a
LEFT JOIN `spatial-vision-343005.staging.d_users` b ON a.manv = b.manv
WHERE phongdeptsummary = 'TP'
GROUP BY 1,2,3,4,5,6,7,8
ORDER BY thang, a.supid,a.manv;