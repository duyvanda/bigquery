CREATE VIEW `spatial-vision-343005.warehouse.view_diem_phu_san_pham_pcl`
AS WITH 
sales AS (
    SELECT 
        a.year,
        a.thang_number,
        a.makhdms,
        b.custname as ten_kh,
        a.masanpham,
        a.tensanphamviettat,
        d.ten_sku,
        a.branddongnhat,
        a.brand2023,
        date(b.crtd_datetime) as ngay_tao_code,
        DATE_DIFF(DATE '2025-12-31', DATE(b.crtd_datetime), MONTH) AS so_thang_hoat_dong_2025,
        DATE_DIFF(CURRENT_DATE(), DATE(b.crtd_datetime), MONTH) AS so_thang_hoat_dong_2026,
        a.ma_crm,
        a.tenquanlytt,
        b.channel as kenh_hien_tai,
        a.maphanloaihco_cu,
        c.chuyen_khoa_pcl,
        d.muc_uu_tien,
        b.active,
        SUM(doanhsochuavat) as doanhsochuavat
    FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
    LEFT JOIN `staging.d_master_khachhang` b ON b.custid = a.makhdms
    LEFT JOIN `staging.d_manual_gs_diem_phu_san_pham_chuyen_khoa` c ON c.ma_kh_dms = a.makhdms
    LEFT JOIN `spatial-vision-343005.staging.d_manual_gs_diem_phu_san_pham_danh_muc_sp` d 
        ON d.ma_sp = a.masanpham AND LOWER(d.chuyen_khoa_pcl) = LOWER(c.chuyen_khoa_pcl)
    where a.makenhphu_cu = 'PCL'
    AND a.is_hang_km = 'Hàng bán'
    GROUP BY ALL
)

, target_sp AS (
    SELECT 
        LOWER(d.chuyen_khoa_pcl) AS chuyen_khoa_pcl,
        STRING_AGG(DISTINCT CASE WHEN muc_uu_tien = '1' THEN d.brand END, ', ') AS brand_ut1_can_phu,
        STRING_AGG(DISTINCT CASE WHEN muc_uu_tien = '2' THEN d.brand END, ', ') AS brand_ut2_can_phu,
        STRING_AGG(DISTINCT CASE WHEN muc_uu_tien = '1' THEN d.ten_sku END, ', ') AS sku_ut1_can_phu,
        COUNT(DISTINCT CASE WHEN d.muc_uu_tien = '1' THEN d.brand END) AS yeu_cau_phu_ut1,
        COUNT(DISTINCT CASE WHEN d.muc_uu_tien = '2' THEN d.brand END) AS yeu_cau_phu_ut2
    FROM `spatial-vision-343005.staging.d_manual_gs_diem_phu_san_pham_danh_muc_sp` d
    GROUP By ALL
)

-- =========================================================================================
-- ĐOẠN MỚI: TÌM RA BRAND/SKU CÒN THIẾU BẰNG TƯ DUY LEFT JOIN BẢNG (KHÔNG DÙNG MẢNG)
-- =========================================================================================

-- 1. Lấy danh sách Khách hàng & Chuyên khoa
, khach_hang_chuyen_khoa AS (
    SELECT DISTINCT makhdms, LOWER(chuyen_khoa_pcl) AS chuyen_khoa_pcl FROM sales
)

-- 2. Dựng bảng TẤT CẢ các Brand/SKU mà khách hàng CẦN PHẢI MUA (Dựa theo Chuyên khoa)
, muc_tieu_cua_khach AS (
    SELECT 
        k.makhdms, 
        k.chuyen_khoa_pcl, 
        d.brand AS target_brand, 
        d.ten_sku AS target_sku, 
        d.muc_uu_tien
    FROM khach_hang_chuyen_khoa k
    JOIN `spatial-vision-343005.staging.d_manual_gs_diem_phu_san_pham_danh_muc_sp` d
        ON LOWER(k.chuyen_khoa_pcl) = LOWER(d.chuyen_khoa_pcl)
)

-- 3. TÁCH RA 2 BẢNG THỰC TẾ RIÊNG BIỆT (Ngăn chặn lỗi đúp dòng khi 1 Brand có nhiều SKU)
, thuc_te_brand AS (
    SELECT DISTINCT makhdms, branddongnhat FROM sales WHERE branddongnhat IS NOT NULL
)
, thuc_te_sku AS (
    SELECT DISTINCT makhdms, ten_sku FROM sales WHERE ten_sku IS NOT NULL
)

-- 4. LEFT JOIN: Lấy Mục tiêu nối với Thực tế. Cái nào Thực tế = NULL tức là chưa mua (BỊ THIẾU)
, danh_sach_con_thieu AS (
    SELECT 
        m.makhdms,
        m.chuyen_khoa_pcl,
        STRING_AGG(DISTINCT CASE WHEN m.muc_uu_tien = '1' AND t_brand.branddongnhat IS NULL THEN m.target_brand END, ', ') AS brand_can_tang_phu_ut1,
        STRING_AGG(DISTINCT CASE WHEN m.muc_uu_tien = '2' AND t_brand.branddongnhat IS NULL THEN m.target_brand END, ', ') AS brand_can_tang_phu_ut2,
        STRING_AGG(DISTINCT CASE WHEN m.muc_uu_tien = '1' AND t_sku.ten_sku IS NULL THEN m.target_sku END, ', ') AS sku_can_tang_phu_ut1
    FROM muc_tieu_cua_khach m
    -- Nối với bảng Brand độc lập
    LEFT JOIN thuc_te_brand t_brand 
        ON m.makhdms = t_brand.makhdms AND m.target_brand = t_brand.branddongnhat
    -- Nối với bảng SKU độc lập
    LEFT JOIN thuc_te_sku t_sku 
        ON m.makhdms = t_sku.makhdms AND m.target_sku = t_sku.ten_sku
    GROUP BY 
        m.makhdms, 
        m.chuyen_khoa_pcl
)
-- =========================================================================================

, tong_hop_chi_tieu_kh AS (
    SELECT 
        s.makhdms,
        s.ngay_tao_code,
        LOWER(s.chuyen_khoa_pcl) AS chuyen_khoa_pcl, -- Giữ nguyên cải tiến đồng bộ của bạn
        -- Dữ liệu thực tế đã phủ
        STRING_AGG(DISTINCT s.branddongnhat, ', ') AS total_brand_da_phu,
        STRING_AGG(DISTINCT CASE WHEN s.muc_uu_tien = '1' THEN s.branddongnhat END, ', ') AS brand_ut1_da_phu,
        STRING_AGG(DISTINCT CASE WHEN s.muc_uu_tien = '2' THEN s.branddongnhat END, ', ') AS brand_ut2_da_phu,
        COUNT(DISTINCT s.branddongnhat) as tong_so_brand_da_phu ,
        COUNT(DISTINCT CASE WHEN s.muc_uu_tien = '1' THEN s.branddongnhat END ) AS tong_so_brand_ut1_da_phu,
        COUNT(DISTINCT CASE WHEN s.muc_uu_tien = '2' THEN s.branddongnhat END ) AS tong_so_brand_ut2_da_phu,

        -- Dữ liệu target (từ target_sp)
        t.yeu_cau_phu_ut1,
        t.yeu_cau_phu_ut2,

        -- Kéo 3 cột phần thiếu từ bảng "danh_sach_con_thieu" sang đây
        p.brand_can_tang_phu_ut1,
        p.sku_can_tang_phu_ut1,
        p.brand_can_tang_phu_ut2,

        -- Tính % Thực hiện Brand
        SAFE_DIVIDE(
            COUNT(DISTINCT CASE WHEN s.muc_uu_tien = '1' THEN s.branddongnhat END), 
            t.yeu_cau_phu_ut1
        ) AS phan_tram_hoan_thanh_ut1,

        SAFE_DIVIDE(
            COUNT(DISTINCT CASE WHEN s.muc_uu_tien = '2' THEN s.branddongnhat END), 
            t.yeu_cau_phu_ut2
        ) AS phan_tram_hoan_thanh_ut2,

        SAFE_DIVIDE(
            COUNT(DISTINCT s.branddongnhat), 
            (IFNULL(t.yeu_cau_phu_ut1, 0) + IFNULL(t.yeu_cau_phu_ut2, 0))
        ) AS phan_tram_hoan_thanh_tong_brand,
        
        -- Tính tổng doanh số năm 2025 chia cho số tháng hoạt động của 2025
        SUM(CASE WHEN s.year = 2025 THEN s.doanhsochuavat ELSE 0 END) 
        / 
        NULLIF(
            CASE 
                WHEN s.ngay_tao_code IS NULL THEN 12
                WHEN EXTRACT(YEAR FROM s.ngay_tao_code) < 2025 THEN 12
                WHEN EXTRACT(YEAR FROM s.ngay_tao_code) = 2025 THEN 13 - EXTRACT(MONTH FROM s.ngay_tao_code)
                ELSE 1 
            END, 0
        ) AS dstb_nam_truoc,
        -- Tính tổng doanh số năm 2026 chia cho số tháng hoạt động của 2026 tính tới tháng hiện tại
        SUM(CASE WHEN s.year = 2026 THEN s.doanhsochuavat ELSE 0 END) 
        / 
        NULLIF(
            CASE 
                WHEN s.ngay_tao_code IS NULL THEN EXTRACT(MONTH FROM CURRENT_DATE())
                WHEN EXTRACT(YEAR FROM s.ngay_tao_code) < 2026 THEN EXTRACT(MONTH FROM CURRENT_DATE())
                WHEN EXTRACT(YEAR FROM s.ngay_tao_code) = 2026 THEN EXTRACT(MONTH FROM CURRENT_DATE()) - EXTRACT(MONTH FROM s.ngay_tao_code) + 1
                ELSE 1 
            END, 0
        ) AS dstb_nam_nay

    FROM sales s
    LEFT JOIN target_sp t ON LOWER(s.chuyen_khoa_pcl) = LOWER(t.chuyen_khoa_pcl)
    -- JOIN bảng danh sách phần thiếu vào đây để lấy số liệu
    LEFT JOIN danh_sach_con_thieu p ON s.makhdms = p.makhdms AND LOWER(s.chuyen_khoa_pcl) = LOWER(p.chuyen_khoa_pcl)
    GROUP BY 
        s.makhdms,
        s.ngay_tao_code,
        LOWER(s.chuyen_khoa_pcl),
        t.yeu_cau_phu_ut1,
        t.yeu_cau_phu_ut2,
        p.brand_can_tang_phu_ut1,
        p.sku_can_tang_phu_ut1,
        p.brand_can_tang_phu_ut2
)

, phan_loai_muc_ds AS (
    SELECT 
        *,
        -- Phân loại mức Doanh số trung bình (Áp dụng cho năm hiện tại đang xét - 2026)
        CASE 
            WHEN dstb_nam_nay >= 10000000 THEN 'N1: >= 10tr'
            WHEN dstb_nam_nay >= 5000000 THEN 'N2: >= 5 đến 10tr'
            WHEN dstb_nam_nay >= 3000000 THEN 'N3: >= 3 đến 5tr'
            WHEN dstb_nam_nay > 0 THEN 'N4: < 3tr'
            WHEN dstb_nam_truoc IS NULL OR dstb_nam_truoc = 0 THEN 'Không PSDS 25'
            ELSE NULL
        END AS muc_dstb_thang,
        -- Xét Brand đã phủ / Yêu cầu phủ - ƯT1
        CASE 
            WHEN phan_tram_hoan_thanh_ut1 >= 1 THEN 'Đạt'
            ELSE 'Chưa đạt'
        END AS trang_thai_phu_ut1,

        -- Xét Brand đã phủ / Yêu cầu phủ - ƯT2
        CASE 
            WHEN phan_tram_hoan_thanh_ut2 >= 1 THEN 'Đạt'
            ELSE 'Chưa đạt'
        END AS trang_thai_phu_ut2,

        -- Định hướng  
        CASE 
            -- Xử lý ngoại lệ: Nếu Chuyên khoa Hô hấp hoặc Khác thì xét mức phủ ƯT2
            WHEN LOWER(chuyen_khoa_pcl) IN ('hô hấp', 'khác') THEN
                CASE
                    WHEN dstb_nam_nay >= 10000000 THEN -- N1
                        CASE WHEN phan_tram_hoan_thanh_ut2 >= 1 THEN 'CS Riêng' ELSE 'Tăng phủ ƯT2' END
                    WHEN dstb_nam_nay >= 5000000 THEN -- N2
                        CASE WHEN phan_tram_hoan_thanh_ut2 >= 1 THEN 'CTKM' ELSE 'Tăng phủ ƯT2 ---> CTKM' END
                    WHEN dstb_nam_nay > 0 THEN -- N3 & N4 có logic giống nhau khi xét ƯT2
                        CASE WHEN phan_tram_hoan_thanh_ut2 >= 1 THEN 'CTKM' ELSE 'CTKM ---> Tăng phủ ƯT2' END
                END
            -- Các trường hợp thông thường theo bảng
            ELSE
                CASE
                    WHEN dstb_nam_nay >= 10000000 THEN -- N1
                        CASE 
                            WHEN phan_tram_hoan_thanh_ut1 < 1 THEN 'Tăng phủ ƯT1' 
                            ELSE 'CS Riêng' 
                        END
                    WHEN dstb_nam_nay >= 5000000 THEN -- N2
                        CASE 
                            WHEN phan_tram_hoan_thanh_ut1 < 1 THEN 'Tăng phủ ƯT1'
                            WHEN phan_tram_hoan_thanh_ut1 >= 1 AND phan_tram_hoan_thanh_ut2 < 1 THEN 'Tăng phủ ƯT2 ---> CTKM'
                            WHEN phan_tram_hoan_thanh_ut1 >= 1 AND phan_tram_hoan_thanh_ut2 >= 1 THEN 'CTKM'
                        END
                    WHEN dstb_nam_nay > 0 THEN -- N3 và N4 dùng chung logic như trong hình
                        CASE 
                            WHEN phan_tram_hoan_thanh_ut1 < 1 THEN 'Tăng phủ ƯT1'
                            WHEN phan_tram_hoan_thanh_ut1 >= 1 AND phan_tram_hoan_thanh_ut2 < 1 THEN 'CTKM ---> Tăng phủ ƯT2'
                            WHEN phan_tram_hoan_thanh_ut1 >= 1 AND phan_tram_hoan_thanh_ut2 >= 1 THEN 'CTKM'
                        END
                END
        END AS dinh_huong
    FROM tong_hop_chi_tieu_kh
)

-- =========================================================================================
-- KẾT QUẢ CUỐI CÙNG: BẢNG CHI TIẾT + GẮN THÊM CỘT TỔNG HỢP (JOIN LẠI VỚI BẢNG SALES)
-- =========================================================================================
SELECT 
    s.* EXCEPT(chuyen_khoa_pcl),
    UPPER(s.chuyen_khoa_pcl) as chuyen_khoa_pcl,
    p.* EXCEPT(makhdms, chuyen_khoa_pcl, ngay_tao_code)
FROM sales s
LEFT JOIN phan_loai_muc_ds p 
    ON s.makhdms = p.makhdms 
    AND LOWER(s.chuyen_khoa_pcl) = LOWER(p.chuyen_khoa_pcl)
--WHERE year >= 2025





;