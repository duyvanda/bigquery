CREATE VIEW `spatial-vision-343005.warehouse.view_ct_thuong_nhap_hang_ent_mesabi_data_chi_tiet`
AS WITH 
-- =========================================================================
-- 1. LỊCH SỬ MUA HÀNG (01/01/2025 - 28/02/2026)
-- =========================================================================
lich_su_mua_hang AS (
    SELECT 
        makhdms,
        CASE 
            WHEN masanpham IN ('T303102010', 'T303102011') THEN 'Meseca Advanced'
            WHEN masanpham IN ('T3041007', 'T3041008')     THEN 'Dypharin'
            WHEN masanpham = 'T4021003'                    THEN 'Mesabi'
            WHEN masanpham = 'T3041010'               THEN 'Meletosol'
            ELSE 'Khác' 
        END AS nhan_sanpham,
        SUM(doanhsochuavat) AS tong_ds_lich_su
    FROM `spatial-vision-343005.staging_temp.f_sales_crs_lhq_bytime` 
    WHERE DATE(ngaychungtu) BETWEEN '2025-01-01' AND '2026-02-28'
      AND masanpham IN ('T4021003','T3041007','T3041008','T303102010','T303102011','T3041010')
      AND makenhkh IN ('PCL', 'CLC')
    GROUP BY 1, 2
    HAVING tong_ds_lich_su > 0
),

-- =========================================================================
-- 2. DỮ LIỆU BÁN HÀNG KỲ XÉT THƯỞNG (01/03/2026 - 30/06/2026)
-- =========================================================================
raw_sales AS (
    SELECT 
        makhdms, tenkhachhang, makenhkh, makenhphu, manv, tencvbh,
        -- ĐIỀU CHỈNH MÃ CRM MỚI
        CASE 
            WHEN manv IN ('MR0952', 'MR2453', 'MR4056') THEN 'MR1555'
            WHEN manv = 'MR1241' THEN 'MR0992'
            ELSE crm 
        END AS crm, 
        
        -- ĐIỀU CHỈNH TÊN CRM MỚI (Tên quản lý trực tiếp)
        CASE 
            WHEN manv IN ('MR0952', 'MR2453', 'MR4056') THEN 'Trần Thanh Quang'
            WHEN manv = 'MR1241' THEN 'Nguyễn Hồng Hà'
            ELSE tenquanlytt 
        END AS tenquanlytt,tenquanlyvung,
        scrm, tenquanlykhuvuc,
        ncxm, 
        sodondathang, ngaychungtu, 
        macongtycn, masanpham, tensanphamnb, soluong, doanhsochuavat,
        CASE 
            WHEN masanpham IN ('T303102010', 'T303102011') THEN 'Meseca Advanced'
            WHEN masanpham IN ('T3041007', 'T3041008')     THEN 'Dypharin'
            WHEN masanpham = 'T4021003'                    THEN 'Mesabi'
            WHEN masanpham = 'T3041010'               THEN 'Meletosol'
            ELSE 'Khác' 
        END AS nhan_sanpham
    FROM `spatial-vision-343005.staging_temp.f_sales_crs_lhq_bytime` 
    WHERE DATE(ngaychungtu) BETWEEN '2026-03-01' AND '2026-08-31'
      AND masanpham IN ('T4021003','T3041007','T3041008','T303102010','T303102011','T3041010')
      AND makenhkh IN ('PCL', 'CLC')
      AND doanhsochuavat > 0
),

-- =========================================================================
-- 3. DANH SÁCH KHÁCH HÀNG TRỌNG TÂM
-- =========================================================================
kh_trong_tam AS (
    SELECT DISTINCT ma_kh_dms, brand 
    FROM `spatial-vision-343005.staging.dskh_trong_tam_ct_nhap_hang_ent_mesabi_hcp_2026`
),

-- =========================================================================
-- 4. ĐẾM SỐ ĐƠN KHÁCH HÀNG ĐÃ MUA THEO NHÃN (TRONG KỲ XÉT THƯỞNG)
-- =========================================================================
so_don_kh_mua AS (
  SELECT 
        makhdms,
        manv,    
        nhan_sanpham,
        -- CỘT 1: Dùng cho Luật 1 (Điểm CLC & PCL) -> ENT chốt 30/06, Mesabi chốt 31/07
        COUNT(DISTINCT CASE 
            WHEN (nhan_sanpham = 'Mesabi' AND DATE(ngaychungtu) <= '2026-07-31') OR 
                 (nhan_sanpham != 'Mesabi' AND DATE(ngaychungtu) <= '2026-06-30') 
            THEN sodondathang 
        END) AS so_don_chot_chinh_sach_chung,

        -- CỘT 2: Dùng riêng cho Luật 2 (Thưởng tiền mặt ENT HCO - Mục 1.4 & 1.5) -> Chốt 31/08
        COUNT(DISTINCT CASE 
            WHEN DATE(ngaychungtu) <= '2026-08-31' 
            THEN sodondathang 
        END) AS so_don_chot_hco_ent
    FROM raw_sales
    GROUP BY 1, 2, 3
)

-- =========================================================================
-- 5. OUTPUT CUỐI CÙNG (GỘP CHỈ BẰNG 1 LƯỢT JOIN CHO MỖI BẢNG)
-- =========================================================================
SELECT 
    -- 1. Thông tin Chứng từ & Khách hàng
    r.ngaychungtu,
    r.macongtycn,
    r.sodondathang,
    r.makhdms,
    r.tenkhachhang,
    r.makenhkh,
    r.makenhphu,
    
    -- 2. Phân loại Khách hàng & Target 
    IF(ls.makhdms IS NULL, 'Khách hàng nhập mới', 'Khách hàng nhập lại') AS phan_loai_kh,
    IF(ktt.ma_kh_dms IS NOT NULL, TRUE, FALSE) AS is_kh_trong_tam,
    
    -- 3. Thông tin Nhân sự (Sales & Quản lý)
    r.manv,
    r.tencvbh,
    r.crm,
    r.tenquanlytt,
    r.scrm,
    r.tenquanlykhuvuc,
    r.ncxm,
    r.tenquanlyvung,
    
    -- 4. Thông tin Sản phẩm & Doanh số
    r.masanpham,
    r.tensanphamnb,
    r.nhan_sanpham,
    CASE WHEN r.nhan_sanpham = 'Mesabi' THEN 'Mesabi' ELSE 'ENT' END AS nhom_sanpham,
    r.soluong,
    r.doanhsochuavat,
    
    -- 6. Thông tin Số đơn Khách hàng mua (Kỳ xét thưởng)
    COALESCE(sd.so_don_chot_chinh_sach_chung, 0) AS so_don_chot_chinh_sach_chung,
    COALESCE(sd.so_don_chot_hco_ent, 0) AS so_don_chot_hco_ent,
    SUM(r.soluong) OVER(PARTITION BY r.sodondathang, r.nhan_sanpham) AS tong_sl_cua_nhan_tren_don,

    -- 6. ĐIỀU KIỆN ĐẠT THƯỞNG PCL (Theo chính sách)
    CASE 
        WHEN r.makenhkh = 'PCL'                                                             -- Là phòng khám PCL
             AND r.nhan_sanpham IN ('Mesabi', 'Meletosol')                                  -- Chỉ áp dụng 2 nhãn này
             AND ls.makhdms IS NULL                                                         -- Tiêu chí 2.1: Nhập mới
             AND SUM(r.soluong) OVER(PARTITION BY r.sodondathang, r.nhan_sanpham) >= 5      -- Tiêu chí 2.3: Đơn hàng >= 5 hộp
             AND COALESCE(sd.so_don_chot_chinh_sach_chung, 0) >= 2                               -- Tiêu chí 2.3: Có >= 2 đơn hàng
             AND (
                 (r.nhan_sanpham = 'Mesabi' AND DATE(r.ngaychungtu) <= '2026-07-31') OR       -- PL2: Mesabi gia hạn đến 31/07
                 (r.nhan_sanpham = 'Meletosol' AND DATE(r.ngaychungtu) <= '2026-06-30')       -- Meletosol (ENT) ở kênh PCL giữ nguyên mốc 30/06
             )
        THEN r.makhdms 
        ELSE NULL
    END AS makh_dat_pcl

FROM raw_sales r

-- Chỉ join 1 lần lấy luôn cả việc xác định Khách mới/cũ VÀ doanh số
LEFT JOIN lich_su_mua_hang ls 
    ON r.makhdms = ls.makhdms 
    AND r.nhan_sanpham = ls.nhan_sanpham

LEFT JOIN kh_trong_tam ktt 
    ON r.makhdms = ktt.ma_kh_dms 
    AND r.nhan_sanpham = ktt.brand

LEFT JOIN so_don_kh_mua sd
    ON r.makhdms = sd.makhdms
    AND r.nhan_sanpham = sd.nhan_sanpham
    AND r.manv = sd.manv

ORDER BY 
    r.ngaychungtu DESC, 
    r.sodondathang, 
    r.nhan_sanpham;;