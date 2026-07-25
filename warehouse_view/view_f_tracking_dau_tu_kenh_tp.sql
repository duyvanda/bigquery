CREATE VIEW `spatial-vision-343005.warehouse.view_f_tracking_dau_tu_kenh_tp`
AS WITH sales AS (
    SELECT 
        makhdms,
        tenquanlytt,
        thang,
        SUM(doanhsochuavat) AS doanhsochuavat 
    FROM `staging_temp.f_sales_crs_lhq_bytime`
    WHERE 
        DATE(ngaychungtu) BETWEEN DATE('2026-01-01') AND DATE('2026-12-31') AND
        tenquanlyvung = 'Nguyễn Hoàng Viển' AND 
        manv NOT LIKE '%CX%' AND 
        makhdms IS NOT NULL
    GROUP BY ALL
),

union_all_data AS (
    -- Nguồn 1: MKT
    SELECT 
        'MKT' AS datatype,
        TRIM(UPPER(ho_ten_duoc_sy_nvyt)) AS ho_ten_duoc_sy_nvyt,
        TRIM(UPPER(chuc_vu)) AS chuc_vu,
        crm AS tenquanlytt,
        ma_hco,
        kh_vip,
        ten_chuong_trinh,
        chi_phi_thuc_hien,
        DATE(ngay_thuc_hien) AS ngay_thuc_hien,
        0 AS doanhsochuavat
    FROM `staging.d_tracking_cost_mkt_tp` 

    UNION ALL

    -- Nguồn 2: Sales
    SELECT 
        'Sales' AS datatype,
        NULL AS ho_ten_duoc_sy_nvyt,
        NULL AS chuc_vu,
        tenquanlytt,
        makhdms AS ma_hco,
        NULL AS kh_vip,
        NULL AS ten_chuong_trinh,
        0 AS chi_phi_thuc_hien,
        DATE(thang) AS ngay_thuc_hien,
        doanhsochuavat
    FROM sales
)

SELECT 
    a.*,
    b.channel,
    b.statedescr,
    b.hcotypeid,
    b.shortterritorydescr,
    b.shoptype,
    b.classid,
    b.custname,
    CURRENT_TIMESTAMP() AS inserted_at
FROM union_all_data a 
LEFT JOIN `staging.d_master_khachhang` b 
    ON a.ma_hco = b.custid;