CREATE VIEW `spatial-vision-343005.warehouse.view_ct_thuong_nhap_hang_ent_mesabi`
AS WITH 
-- =========================================================================
-- 1. BASE DATA TỪ VIEW CHI TIẾT
-- =========================================================================
raw_data AS (
    SELECT * FROM `spatial-vision-343005.warehouse.view_ct_thuong_nhap_hang_ent_mesabi_data_chi_tiet`
),

-- =========================================================================
-- 2. DANH SÁCH SỐ LƯỢNG NHÂN VIÊN/TEAM (CỐ ĐỊNH THEO EXCEL CỦA BẠN)
-- =========================================================================
so_luong_nv_quan_ly AS (
    SELECT 'MR1681' AS crm, 5 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR2355' AS crm, 9 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR1579' AS crm, 6 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR1391' AS crm, 8 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR1555' AS crm, 5 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR0253' AS crm, 4 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR0673' AS crm, 3 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR1427' AS crm, 3 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR0683' AS crm, 9 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR0992' AS crm, 11 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR0055' AS crm, 6 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR0538' AS crm, 8 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR1250' AS crm, 4 AS so_luong_nhan_vien UNION ALL
    SELECT 'MR0123' AS crm, 5 AS so_luong_nhan_vien
),

-- =========================================================================
-- 3. CHƯƠNG TRÌNH RIÊNG: THƯỞNG TIỀN MẶT ENT (Phải nhập đủ 3 nhãn ENT)
-- =========================================================================
ent_hco_dat AS (
    SELECT 
        makhdms, 
        crm,
        MAX(makenhphu) AS makenhphu,
        SUM(CASE WHEN phan_loai_kh = 'Khách hàng nhập lại' THEN 1 ELSE 0 END) AS so_nhan_nhap_lai,
        CASE 
            WHEN SUM(CASE WHEN phan_loai_kh = 'Khách hàng nhập lại' THEN 1 ELSE 0 END) = 0 THEN 
                CASE MAX(makenhphu) WHEN 'CLC1' THEN 5000000 WHEN 'CLC2' THEN 3000000 WHEN 'CLC3' THEN 2000000 WHEN 'CLC4' THEN 2000000 ELSE 0 END
            ELSE 
                CASE MAX(makenhphu) WHEN 'CLC1' THEN 3000000 WHEN 'CLC2' THEN 2000000 WHEN 'CLC3' THEN 1000000 WHEN 'CLC4' THEN 1000000 ELSE 0 END
        END AS tien_thuong_khach
    FROM raw_data
    WHERE makenhkh = 'CLC' 
      AND nhom_sanpham = 'ENT' 
      AND CAST(so_don_chot_hco_ent AS INT64) >= 2
      AND DATE(ngaychungtu) <= '2026-08-31'
    GROUP BY makhdms, crm
    HAVING COUNT(DISTINCT nhan_sanpham) = 3 
),
tong_thuong_ent_team AS (
    SELECT 
        crm,
        'ENT' AS nhom_sanpham,
        SUM(tien_thuong_khach) AS tong_tien_ent
    FROM ent_hco_dat
    GROUP BY crm
),
-- =========================================================================
-- 4. GOM THEO KHÁCH HÀNG (CLC) - LỌC BỎ NGAY KHÁCH < 2 ĐƠN 
-- =========================================================================
clc_khach_hang_dat AS (
    SELECT 
        r.crm, 
        r.tenquanlytt,
        r.scrm,
        r.tenquanlykhuvuc,
        r.nhom_sanpham, 
        r.nhan_sanpham,
        r.makhdms, 
        r.phan_loai_kh, 
        r.makenhphu, 
        CAST(r.is_kh_trong_tam AS STRING) AS is_kh_trong_tam,
        SUM(CAST(r.doanhsochuavat AS FLOAT64)) AS ds_clc_cua_nhom
    FROM raw_data r
    WHERE r.makenhkh = 'CLC'
    AND (
        (r.nhom_sanpham = 'Mesabi' AND DATE(r.ngaychungtu) <= '2026-07-31') OR -- PL2: Mesabi gia hạn đến 31/07
        (r.nhom_sanpham = 'ENT' AND DATE(r.ngaychungtu) <= '2026-06-30')       -- ENT (Mục 1.1-1.3) giữ nguyên mốc 30/06
    )
    GROUP BY 
        ALL
    HAVING MAX(CAST(r.so_don_chot_chinh_sach_chung AS INT64)) >= 2 
)

-- =========================================================================
-- 5. TÍNH ĐIỂM TRỰC TIẾP CHO KÊNH CLC
-- =========================================================================
, tinh_diem_clc AS (
    SELECT 
        k.*,
        CASE 
            WHEN k.phan_loai_kh = 'Khách hàng nhập lại' AND k.makenhphu IN ('CLC1','CLC2','CLC3','CLC4') THEN 1
            WHEN k.phan_loai_kh = 'Khách hàng nhập mới' THEN 
                CASE 
                    WHEN k.makenhphu IN ('CLC1','CLC2','CLC4') AND k.is_kh_trong_tam = 'true'  THEN 4
                    WHEN k.makenhphu IN ('CLC1','CLC2','CLC4') AND k.is_kh_trong_tam = 'false' THEN 3
                    WHEN k.makenhphu = 'CLC3'                  AND k.is_kh_trong_tam = 'true'  THEN 2
                    WHEN k.makenhphu = 'CLC3'                  AND k.is_kh_trong_tam = 'false' THEN 1
                    ELSE 0 
                END
            ELSE 0 
        END AS diem_thuong
    FROM clc_khach_hang_dat k
)

--select * from tinh_diem_clc where tenquanlytt = 'Nguyễn Toàn' AND nhom_sanpham = 'ENT'

-- =========================================================================
-- 6. XỬ LÝ KÊNH PCL (DÙNG TRỰC TIẾP CỘT ĐÃ CÓ SẴN TRONG VIEW)
-- =========================================================================
, diem_pcl_team AS (
    SELECT 
        crm,
        nhom_sanpham,
        nhan_sanpham,
        
        -- Đếm SLKH đạt (Khách mới + Có mã KH đạt PCL)
        COUNT(DISTINCT CASE WHEN phan_loai_kh = 'Khách hàng nhập mới' AND makh_dat_pcl IS NOT NULL THEN makhdms END) AS slkh_pcl_dat,
        
        -- Tổng doanh số các dòng đạt PCL
        SUM(CASE WHEN phan_loai_kh = 'Khách hàng nhập mới' AND makh_dat_pcl IS NOT NULL THEN CAST(doanhsochuavat AS FLOAT64) ELSE 0 END) AS ds_pcl_team
    FROM raw_data
    WHERE makenhkh = 'PCL'
    AND (
        (nhom_sanpham = 'Mesabi' AND DATE(ngaychungtu) <= '2026-07-31') OR -- PL2: Mesabi gia hạn đến 31/07
        (nhom_sanpham = 'ENT' AND DATE(ngaychungtu) <= '2026-06-30')       -- ENT ở kênh PCL giữ nguyên mốc 30/06
    )
    GROUP BY 1, 2,3
)
, tong_hop_cap_quan_ly AS (
SELECT 
    clc.crm,
    clc.tenquanlytt,
    clc.scrm,
    clc.tenquanlykhuvuc,
    clc.nhom_sanpham,
    COALESCE(nvql.so_luong_nhan_vien, 0) AS So_luong_nhan_vien_Team,
    
    -- [1] ĐIỂM SỐ CLC
    SUM(clc.diem_thuong) AS Tong_diem_CLC,
    CASE WHEN COALESCE(nvql.so_luong_nhan_vien, 0) > 0 THEN SAFE_DIVIDE(SUM(clc.diem_thuong), nvql.so_luong_nhan_vien) ELSE 0 END AS Diem_binh_quan_CLC,
    
    -- [2] PHÂN TÍCH KHÁCH HÀNG CLC (Dựa trên điểm)
    SUM(CASE WHEN clc.phan_loai_kh = 'Khách hàng nhập mới' THEN clc.diem_thuong ELSE 0 END) AS Diem_KH_nhap_moi,
    COUNT(DISTINCT CASE WHEN clc.phan_loai_kh = 'Khách hàng nhập mới' AND clc.makenhphu IN ('CLC1','CLC2','CLC4') AND clc.is_kh_trong_tam = 'true'  AND clc.diem_thuong > 0 THEN clc.makhdms END) AS SL_KH_Moi_CLC124_Trong_tam,
    COUNT(DISTINCT CASE WHEN clc.phan_loai_kh = 'Khách hàng nhập mới' AND clc.makenhphu IN ('CLC1','CLC2','CLC4') AND clc.is_kh_trong_tam = 'false' AND clc.diem_thuong > 0 THEN clc.makhdms END) AS SL_KH_Moi_CLC124_Thuong,
    COUNT(DISTINCT CASE WHEN clc.phan_loai_kh = 'Khách hàng nhập mới' AND clc.makenhphu = 'CLC3' AND clc.is_kh_trong_tam = 'true'  AND clc.diem_thuong > 0 THEN clc.makhdms END) AS SL_KH_Moi_CLC3_Trong_tam,
    COUNT(DISTINCT CASE WHEN clc.phan_loai_kh = 'Khách hàng nhập mới' AND clc.makenhphu = 'CLC3' AND clc.is_kh_trong_tam = 'false' AND clc.diem_thuong > 0 THEN clc.makhdms END) AS SL_KH_Moi_CLC3_Thuong,
    SUM(CASE WHEN clc.phan_loai_kh = 'Khách hàng nhập lại' THEN clc.diem_thuong ELSE 0 END) AS Diem_KH_nhap_lai,
    COUNT(DISTINCT CASE WHEN clc.phan_loai_kh = 'Khách hàng nhập lại' AND clc.diem_thuong > 0 THEN clc.makhdms END) AS SL_KH_Nhap_lai_CLC1234,

    -- [3] GIẢI THƯỞNG TIỀN MẶT ENT (Chương trình HCO riêng)
    COUNT(DISTINCT CASE WHEN clc.nhom_sanpham = 'ENT' AND ent.so_nhan_nhap_lai = 0 AND ent.makenhphu = 'CLC1' THEN ent.makhdms END) AS ENT_SL_KH_Moi_CLC1,
    COUNT(DISTINCT CASE WHEN clc.nhom_sanpham = 'ENT' AND ent.so_nhan_nhap_lai = 0 AND ent.makenhphu = 'CLC2' THEN ent.makhdms END) AS ENT_SL_KH_Moi_CLC2,
    COUNT(DISTINCT CASE WHEN clc.nhom_sanpham = 'ENT' AND ent.so_nhan_nhap_lai = 0 AND ent.makenhphu = 'CLC3' THEN ent.makhdms END) AS ENT_SL_KH_Moi_CLC3,
    COUNT(DISTINCT CASE WHEN clc.nhom_sanpham = 'ENT' AND ent.so_nhan_nhap_lai = 0 AND ent.makenhphu = 'CLC4' THEN ent.makhdms END) AS ENT_SL_KH_Moi_CLC4,
    COUNT(DISTINCT CASE WHEN clc.nhom_sanpham = 'ENT' AND ent.so_nhan_nhap_lai > 0 AND ent.makenhphu = 'CLC1' THEN ent.makhdms END) AS ENT_SL_KH_Da_Nhap_CLC1,
    COUNT(DISTINCT CASE WHEN clc.nhom_sanpham = 'ENT' AND ent.so_nhan_nhap_lai > 0 AND ent.makenhphu = 'CLC2' THEN ent.makhdms END) AS ENT_SL_KH_Da_Nhap_CLC2,
    COUNT(DISTINCT CASE WHEN clc.nhom_sanpham = 'ENT' AND ent.so_nhan_nhap_lai > 0 AND ent.makenhphu = 'CLC3' THEN ent.makhdms END) AS ENT_SL_KH_Da_Nhap_CLC3,
    COUNT(DISTINCT CASE WHEN clc.nhom_sanpham = 'ENT' AND ent.so_nhan_nhap_lai > 0 AND ent.makenhphu = 'CLC4' THEN ent.makhdms END) AS ENT_SL_KH_Da_Nhap_CLC4,
    COALESCE(MAX(t_ent.tong_tien_ent), 0) AS ENT_Muc_Thuong_Tien,

    -- [4] DOANH SỐ ĐẠT (Tính SUM đơn giản vì KH đã được lọc sẵn)
    SUM(clc.ds_clc_cua_nhom) AS Doanh_So_CLC_Dat,

    -- [5] BEST TEAM (CLC + PCL)
    SUM(clc.diem_thuong) + COALESCE(MAX(pcl.slkh_pcl_dat), 0) AS BT_Tong_Diem,
    SUM(clc.ds_clc_cua_nhom) + COALESCE(MAX(pcl.ds_pcl_team), 0) AS BT_Tong_Doanh_So,
    CASE WHEN COALESCE(nvql.so_luong_nhan_vien, 0) > 0 
         THEN SAFE_DIVIDE(SUM(clc.diem_thuong) + COALESCE(MAX(pcl.slkh_pcl_dat), 0), nvql.so_luong_nhan_vien) 
         ELSE 0 END AS BT_Binh_Quan_Diem_Phu,
    CASE WHEN COALESCE(nvql.so_luong_nhan_vien, 0) > 0 
         THEN SAFE_DIVIDE(SUM(clc.ds_clc_cua_nhom) + COALESCE(MAX(pcl.ds_pcl_team), 0), nvql.so_luong_nhan_vien) 
         ELSE 0 END AS BT_Binh_Quan_Doanh_So

FROM tinh_diem_clc clc
--LEFT JOIN (SELECT crm, MAX(tenquanlytt) AS tenquanlytt FROM raw_data GROUP BY 1) r_ten ON clc.crm = r_ten.crm
LEFT JOIN so_luong_nv_quan_ly nvql ON clc.crm = nvql.crm
LEFT JOIN ent_hco_dat ent ON clc.makhdms = ent.makhdms AND clc.nhom_sanpham = 'ENT' AND clc.crm = ent.crm
LEFT JOIN diem_pcl_team pcl ON clc.crm = pcl.crm AND clc.nhom_sanpham = pcl.nhom_sanpham AND clc.nhan_sanpham = pcl.nhan_sanpham
LEFT JOIN tong_thuong_ent_team t_ent ON clc.crm = t_ent.crm AND clc.nhom_sanpham = t_ent.nhom_sanpham
GROUP BY 
    clc.crm,
    clc.tenquanlytt,
    clc.scrm,
    clc.tenquanlykhuvuc,
    clc.nhom_sanpham,
    nvql.so_luong_nhan_vien
)
, xep_hang_best_team AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nhom_sanpham ORDER BY BT_Binh_Quan_Diem_Phu DESC) AS Hang_Phu,
        RANK() OVER (PARTITION BY nhom_sanpham ORDER BY BT_Binh_Quan_Doanh_So DESC) AS Hang_DoanhSo
    FROM tong_hop_cap_quan_ly
)
-- Bước quy đổi hạng ra điểm và cộng theo tỷ trọng 70/30
SELECT 
    *,
    GREATEST(0, 100 - (Hang_Phu - 1) * 5) AS Diem_Phu,
    GREATEST(0, 100 - (Hang_DoanhSo - 1) * 5) AS Diem_DoanhSo,
    ROUND(
        GREATEST(0, 100 - (Hang_Phu - 1) * 5) * 0.7 
      + GREATEST(0, 100 - (Hang_DoanhSo - 1) * 5) * 0.3
    , 2) AS Diem_Best_Team
FROM xep_hang_best_team
ORDER BY nhom_sanpham, Diem_Best_Team DESC;


    ;