CREATE VIEW `spatial-vision-343005.warehouse.view_tong_hop_theo_doi_ct`
AS WITH thong_tin_cpa AS (
    SELECT  
        pl,
        socpacsbh,
        STRING_AGG(DISTINCT tenchuongtrinh, ' | ') AS tenchuongtrinh,
        kenh,
        hieuluc,
        denngay,
        STRING_AGG(DISTINCT mactdms, ' | ') AS mactdms,
        sotbsct,
        linkfilesotbsct,
        linkfile_next_cloud,
        is_active,
        SUM(IFNULL(chi_phi_sct, 0)) AS chi_phi_sct,
        SUM(IFNULL(chi_phi_cpa, 0)) AS chi_phi_cpa,
        SUM(IFNULL(doanhsokh, 0)) AS doanhsokh,
        SUM(IFNULL(chi_phi_tien_ck, 0)) AS chi_phi_tien_ck,
        SUM(IFNULL(chi_phi_hang_km, 0)) AS chi_phi_hang_km
    FROM `spatial-vision-343005.warehouse.f_theo_doi_cpa`
    WHERE 
    EXTRACT (YEAR FROM hieuluc) = 2026
    AND socpacsbh IN ('785/2025/QĐ-MR', '786/2025/QĐ-MR')
    GROUP BY ALL
),
tich_luy_tp AS (
    SELECT 
        '785/2025/QĐ-MR' AS socpacsbh,  
        
        -- === 1. TÍNH CÁC QUÝ ===
        SUM(IFNULL(SAFE_CAST(tong_tien_ck_q1 AS FLOAT64), 0)) AS chi_phi_thuc_q1,
        SUM(IFNULL(SAFE_CAST(tong_tien_ck_q2 AS FLOAT64), 0)) AS chi_phi_thuc_q2,
        SUM(IFNULL(SAFE_CAST(tong_tien_ck_q3 AS FLOAT64), 0)) AS chi_phi_thuc_q3,
        SUM(IFNULL(SAFE_CAST(tong_tien_ck_q4 AS FLOAT64), 0)) AS chi_phi_thuc_q4,

        SUM(IFNULL(SAFE_CAST(tong_trich_lap_q1 AS FLOAT64), 0)) AS trich_lap_q1,
        SUM(IFNULL(SAFE_CAST(tong_trich_lap_q2 AS FLOAT64), 0)) AS trich_lap_q2,
        SUM(IFNULL(SAFE_CAST(tong_trich_lap_q3 AS FLOAT64), 0)) AS trich_lap_q3,
        SUM(IFNULL(SAFE_CAST(tong_trich_lap_q4 AS FLOAT64), 0)) AS trich_lap_q4,

        -- === 2. TÍNH CÁC KỲ ===
        SUM(IFNULL(SAFE_CAST(tong_tien_km_ky_1 AS FLOAT64), 0)) AS chi_phi_thuc_ky1,
        SUM(IFNULL(SAFE_CAST(tong_tien_km_ky_2 AS FLOAT64), 0)) AS chi_phi_thuc_ky2,
        
        SUM(IFNULL(SAFE_CAST(tong_trich_lap_ky1 AS FLOAT64), 0)) AS trich_lap_ky1,
        SUM(IFNULL(SAFE_CAST(tong_trich_lap_ky2 AS FLOAT64), 0)) AS trich_lap_ky2,

        -- === 3. TÍNH NĂM ===
        SUM(
            IFNULL(SAFE_CAST(tong_thanh_tien_km_ca_nam AS FLOAT64), 0) + 
            IFNULL(SAFE_CAST(gia_tri_qua_tet AS FLOAT64), 0)
        ) AS chi_phi_thuc_nam,
        SUM(IFNULL(SAFE_CAST(tong_trich_lap_nam AS FLOAT64), 0)) AS trich_lap_nam

    FROM `spatial-vision-343005.warehouse.f_view_form_theo_doi_CSBH_loyalty_TP_2026`
    GROUP BY socpacsbh
),

tich_luy_pcl AS (
    SELECT 
        '786/2025/QĐ-MR' AS socpacsbh,  
        
        /* === 1. TÍNH CÁC QUÝ === */
        SUM(IFNULL(SAFE_CAST(tong_tien_ck_q1 AS FLOAT64), 0)) AS chi_phi_thuc_q1,
        SUM(IFNULL(SAFE_CAST(tong_tien_ck_q2 AS FLOAT64), 0)) AS chi_phi_thuc_q2,
        SUM(IFNULL(SAFE_CAST(tong_tien_ck_q3 AS FLOAT64), 0)) AS chi_phi_thuc_q3,
        SUM(IFNULL(SAFE_CAST(tong_tien_ck_q4 AS FLOAT64), 0)) AS chi_phi_thuc_q4,

        SUM(IFNULL(SAFE_CAST(trich_lap_q1 AS FLOAT64), 0)) AS trich_lap_q1,
        SUM(IFNULL(SAFE_CAST(trich_lap_q2 AS FLOAT64), 0)) AS trich_lap_q2,
        SUM(IFNULL(SAFE_CAST(trich_lap_q3 AS FLOAT64), 0)) AS trich_lap_q3,
        SUM(IFNULL(SAFE_CAST(trich_lap_q4 AS FLOAT64), 0)) AS trich_lap_q4,

        /* === 2. TÍNH CÁC KỲ === */
        /* Sửa lại tên cột chi phí thực theo đúng PCL */
        SUM(IFNULL(SAFE_CAST(thanh_tien_km_ky_1 AS FLOAT64), 0)) AS chi_phi_thuc_ky1,
        SUM(IFNULL(SAFE_CAST(thanh_tien_km_ky_2 AS FLOAT64), 0)) AS chi_phi_thuc_ky2, 
        
        /* Sửa lại tên cột trích lập kỳ theo đúng PCL (có dấu gạch dưới) */
        SUM(IFNULL(SAFE_CAST(trich_lap_ky_1 AS FLOAT64), 0)) AS trich_lap_ky1,
        SUM(IFNULL(SAFE_CAST(trich_lap_ky_2 AS FLOAT64), 0)) AS trich_lap_ky2,  

        /* === 3. TÍNH NĂM === */
        /* PCL dùng thanh_tien_km_nam và KHÔNG có gia_tri_qua_tet */
        SUM(IFNULL(SAFE_CAST(thanh_tien_km_nam AS FLOAT64), 0)) AS chi_phi_thuc_nam,
        
        SUM(IFNULL(SAFE_CAST(trich_lap_nam AS FLOAT64), 0)) AS trich_lap_nam

    FROM `spatial-vision-343005.warehouse.f_view_form_theo_doi_CSBH_loyalty_PCL_2026`
    GROUP BY socpacsbh
),

tich_luy_tong_hop AS (
    SELECT * FROM tich_luy_tp
    UNION ALL
    SELECT * FROM tich_luy_pcl
)

SELECT 
    a.*,
    
    -- CHI PHÍ & TRÍCH LẬP THEO QUÝ (Tự động nhảy Q1 -> Q4)
    CASE EXTRACT(QUARTER FROM DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))
        WHEN 1 THEN b.chi_phi_thuc_q1
        WHEN 2 THEN b.chi_phi_thuc_q2
        WHEN 3 THEN b.chi_phi_thuc_q3
        WHEN 4 THEN b.chi_phi_thuc_q4
        ELSE 0 
    END AS chi_phi_thuc_quy_hien_hanh,

    CASE EXTRACT(QUARTER FROM DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))
        WHEN 1 THEN b.trich_lap_q1
        WHEN 2 THEN b.trich_lap_q2
        WHEN 3 THEN b.trich_lap_q3
        WHEN 4 THEN b.trich_lap_q4
        ELSE 0 
    END AS trich_lap_quy_hien_hanh,

    -- CHI PHÍ & TRÍCH LẬP THEO KỲ (Lấy theo tháng M-1)
    CASE 
        WHEN EXTRACT(MONTH FROM DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH)) <= 6 THEN b.chi_phi_thuc_ky1
        ELSE b.chi_phi_thuc_ky2
    END AS chi_phi_thuc_ky_hien_hanh,

    CASE 
        WHEN EXTRACT(MONTH FROM DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH)) <= 6 THEN b.trich_lap_ky1
        ELSE b.trich_lap_ky2
    END AS trich_lap_ky_hien_hanh,

    -- CHI PHÍ & TRÍCH LẬP THEO NĂM (Lấy tổng cả năm)
    b.chi_phi_thuc_nam,
    b.trich_lap_nam

FROM thong_tin_cpa a
LEFT JOIN tich_luy_tong_hop b  
    ON a.socpacsbh = b.socpacsbh;






;