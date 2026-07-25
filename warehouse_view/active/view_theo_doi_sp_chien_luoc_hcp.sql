CREATE VIEW `spatial-vision-343005.warehouse.view_theo_doi_sp_chien_luoc_hcp`
AS With base_data AS (
SELECT 
thang,
manv,
tencvbh,
crm as ma_crm,
tenquanlytt,
scrm,
tenquanlykhuvuc,
makhdms,
tenkhachhang,
makenhkh,
makenhphu,
statedescr,
masanpham,
tensanphamnb,
doanhsochuavat,
CASE 
    WHEN masanpham IN ('T3041007', 'T3041008') THEN 'Dypharin'
    WHEN masanpham = 'T4021002' THEN 'Menida'
    WHEN masanpham IN ('T303102010', 'T303102011') THEN 'Meseca AD'
    WHEN masanpham = 'T3041010' THEN 'Meleto Sol'
    WHEN masanpham = 'T4021003' THEN 'Mesabi'
    WHEN masanpham IN ('T4040101001', 'T4040101002') THEN 'SunoHada'
    ELSE 'Khác' 
END AS nhom_sp
FROM `spatial-vision-343005.staging_temp.f_sales_crs_lhq_bytime`
WHERE date(ngaychungtu) >= '2025-01-01'
AND date(ngaychungtu) <= '2026-12-31'
AND makenhkh in ('PCL','CLC','INS')
AND masanpham in ('T3041007','T3041008','T4021002','T303102010','T303102011','T3041010','T4021003','T4040101001','T4040101002')
)

, history_kh AS (
    -- Bước 2: Tìm tập khách hàng CŨ (đã có doanh số > 0) theo từng nhóm sản phẩm trong giai đoạn lịch sử
    SELECT DISTINCT 
        makhdms, 
        nhom_sp,
        MIN(DATE(thang)) AS thang_mua_dau_tien
    FROM base_data
    WHERE COALESCE(doanhsochuavat, 0) > 0
    GROUP BY makhdms, nhom_sp
) 

,raw_data_2026 AS (
    -- Bước 3: Lọc lấy dữ liệu 2026 và JOIN với bảng lịch sử để gắn nhãn Mới/Cũ
    SELECT 
        b.*,
        h.thang_mua_dau_tien,
        CASE 
            WHEN h.thang_mua_dau_tien <= '2026-02-28' THEN 'KH Cũ'
            WHEN DATE(b.thang) = h.thang_mua_dau_tien THEN 'KH Mới'
            ELSE 'KH Cũ'
        END AS phanloai_kh
    FROM base_data b
    LEFT JOIN history_kh h 
        ON b.makhdms = h.makhdms 
        AND b.nhom_sp = h.nhom_sp
    WHERE DATE(b.thang) >= '2026-01-01'
      AND DATE(b.thang) <= '2026-12-31'
)

SELECT
    manv,
    tencvbh,
    ma_crm,
    tenquanlytt,
    scrm,
    tenquanlykhuvuc,
    makhdms,
    tenkhachhang,
    makenhkh,
    makenhphu,
    statedescr,
    masanpham,
    tensanphamnb,
    nhom_sp,
    phanloai_kh,
    thang_mua_dau_tien,

    --- 1. DOANH SỐ KH MỚI THEO TỪNG THÁNG ---
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 1 AND phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS ds_moi_t01,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 2 AND phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS ds_moi_t02,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 3 AND phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS ds_moi_t03,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 4 AND phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS ds_moi_t04,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 5 AND phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS ds_moi_t05,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 6 AND phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS ds_moi_t06,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 7 AND phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS ds_moi_t07,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 8 AND phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS ds_moi_t08,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 9 AND phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS ds_moi_t09,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 10 AND phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS ds_moi_t10,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 11 AND phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS ds_moi_t11,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 12 AND phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS ds_moi_t12,

    --- 2. DOANH SỐ KH CŨ THEO TỪNG THÁNG ---
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 1 AND phanloai_kh = 'KH Cũ' THEN doanhsochuavat ELSE 0 END) AS ds_cu_t01,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 2 AND phanloai_kh = 'KH Cũ' THEN doanhsochuavat ELSE 0 END) AS ds_cu_t02,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 3 AND phanloai_kh = 'KH Cũ' THEN doanhsochuavat ELSE 0 END) AS ds_cu_t03,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 4 AND phanloai_kh = 'KH Cũ' THEN doanhsochuavat ELSE 0 END) AS ds_cu_t04,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 5 AND phanloai_kh = 'KH Cũ' THEN doanhsochuavat ELSE 0 END) AS ds_cu_t05,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 6 AND phanloai_kh = 'KH Cũ' THEN doanhsochuavat ELSE 0 END) AS ds_cu_t06,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 7 AND phanloai_kh = 'KH Cũ' THEN doanhsochuavat ELSE 0 END) AS ds_cu_t07,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 8 AND phanloai_kh = 'KH Cũ' THEN doanhsochuavat ELSE 0 END) AS ds_cu_t08,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 9 AND phanloai_kh = 'KH Cũ' THEN doanhsochuavat ELSE 0 END) AS ds_cu_t09,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 10 AND phanloai_kh = 'KH Cũ' THEN doanhsochuavat ELSE 0 END) AS ds_cu_t10,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 11 AND phanloai_kh = 'KH Cũ' THEN doanhsochuavat ELSE 0 END) AS ds_cu_t11,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 12 AND phanloai_kh = 'KH Cũ' THEN doanhsochuavat ELSE 0 END) AS ds_cu_t12,

    --- 3. SLKH MỚI THEO TỪNG THÁNG ---
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 1 AND phanloai_kh = 'KH Mới' THEN makhdms END) AS slkh_moi_t01,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 2 AND phanloai_kh = 'KH Mới' THEN makhdms END) AS slkh_moi_t02,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 3 AND phanloai_kh = 'KH Mới' THEN makhdms END) AS slkh_moi_t03,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 4 AND phanloai_kh = 'KH Mới' THEN makhdms END) AS slkh_moi_t04,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 5 AND phanloai_kh = 'KH Mới' THEN makhdms END) AS slkh_moi_t05,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 6 AND phanloai_kh = 'KH Mới' THEN makhdms END) AS slkh_moi_t06,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 7 AND phanloai_kh = 'KH Mới' THEN makhdms END) AS slkh_moi_t07,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 8 AND phanloai_kh = 'KH Mới' THEN makhdms END) AS slkh_moi_t08,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 9 AND phanloai_kh = 'KH Mới' THEN makhdms END) AS slkh_moi_t09,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 10 AND phanloai_kh = 'KH Mới' THEN makhdms END) AS slkh_moi_t10,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 11 AND phanloai_kh = 'KH Mới' THEN makhdms END) AS slkh_moi_t11,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 12 AND phanloai_kh = 'KH Mới' THEN makhdms END) AS slkh_moi_t12,

    --- 4. SLKH CŨ THEO TỪNG THÁNG ---
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 1 AND phanloai_kh = 'KH Cũ' THEN makhdms END) AS slkh_cu_t01,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 2 AND phanloai_kh = 'KH Cũ' THEN makhdms END) AS slkh_cu_t02,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 3 AND phanloai_kh = 'KH Cũ' THEN makhdms END) AS slkh_cu_t03,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 4 AND phanloai_kh = 'KH Cũ' THEN makhdms END) AS slkh_cu_t04,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 5 AND phanloai_kh = 'KH Cũ' THEN makhdms END) AS slkh_cu_t05,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 6 AND phanloai_kh = 'KH Cũ' THEN makhdms END) AS slkh_cu_t06,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 7 AND phanloai_kh = 'KH Cũ' THEN makhdms END) AS slkh_cu_t07,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 8 AND phanloai_kh = 'KH Cũ' THEN makhdms END) AS slkh_cu_t08,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 9 AND phanloai_kh = 'KH Cũ' THEN makhdms END) AS slkh_cu_t09,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 10 AND phanloai_kh = 'KH Cũ' THEN makhdms END) AS slkh_cu_t10,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 11 AND phanloai_kh = 'KH Cũ' THEN makhdms END) AS slkh_cu_t11,
    COUNT(DISTINCT CASE WHEN EXTRACT(MONTH FROM thang) = 12 AND phanloai_kh = 'KH Cũ' THEN makhdms END) AS slkh_cu_t12,

    --- 5. TỔNG CỘNG CẢ THÁNG ---
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 1 THEN doanhsochuavat ELSE 0 END) AS tong_ds_t01,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 2 THEN doanhsochuavat ELSE 0 END) AS tong_ds_t02,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 3 THEN doanhsochuavat ELSE 0 END) AS tong_ds_t03,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 4 THEN doanhsochuavat ELSE 0 END) AS tong_ds_t04,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 5 THEN doanhsochuavat ELSE 0 END) AS tong_ds_t05,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 6 THEN doanhsochuavat ELSE 0 END) AS tong_ds_t06,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 7 THEN doanhsochuavat ELSE 0 END) AS tong_ds_t07,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 8 THEN doanhsochuavat ELSE 0 END) AS tong_ds_t08,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 9 THEN doanhsochuavat ELSE 0 END) AS tong_ds_t09,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 10 THEN doanhsochuavat ELSE 0 END) AS tong_ds_t10,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 11 THEN doanhsochuavat ELSE 0 END) AS tong_ds_t11,
    SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 12 THEN doanhsochuavat ELSE 0 END) AS tong_ds_t12,

    --- 6. TỔNG CỘNG CẢ NĂM ---
    SUM(doanhsochuavat) AS total_ds_nam,
    COUNT(DISTINCT makhdms) AS total_slkh_nam,
    SUM(CASE WHEN phanloai_kh = 'KH Mới' THEN doanhsochuavat ELSE 0 END) AS total_ds_moi_nam,
    COUNT(DISTINCT CASE WHEN phanloai_kh = 'KH Mới' THEN makhdms END) AS total_slkh_moi_nam

FROM raw_data_2026
GROUP BY ALL

;