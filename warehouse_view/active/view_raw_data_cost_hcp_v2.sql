CREATE VIEW `spatial-vision-343005.warehouse.view_raw_data_cost_hcp_v2`
AS WITH d_avg_ds_6t AS (
    SELECT
        pubcustid,
        SUM(doanhsochuavat)/6 as avg_ds_6t
    FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy`
    WHERE DATE(ngaychungtu) >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
    GROUP BY pubcustid
    HAVING SUM(doanhsochuavat) > 1000
)

, d_shoptype AS (
        SELECT
            pubcustid,
            STRING_AGG(
                shoptype, '&' 
                ORDER BY 
                    CASE WHEN branchid NOT LIKE 'MR%' THEN 0 ELSE 1 END ASC,
                    CASE WHEN shoptype like '%DLPP_CLC%' THEN 1 ELSE 0 END ASC, 
                    shoptype ASC
            ) AS shoptype
        FROM (
            SELECT
                pubcustid,
                shoptype,
                branchid
            FROM `spatial-vision-343005.staging.d_master_khachhang`
            WHERE pubcustid IS NOT NULL 
            GROUP BY 
                pubcustid,
                shoptype,
                branchid
        )
        GROUP BY 
            pubcustid
)

, d_master_hcp_fix AS (
    SELECT
        b.*,
        staging_temp.fun_get_phan_hang_hcp (kenh_lam_viec, chuc_vu, avg_ds_6t, so_luot_kham, so_tiem_nang) as phan_hang_hcp
    FROM `spatial-vision-343005.staging.d_master_hcp` b
    LEFT JOIN d_avg_ds_6t d ON d.pubcustid = b.hco_bv
    WHERE b.status = 'active'
)

, thuong_commitment_2026_tmp AS (
    SELECT 
        ma_crm,
        ma_kh,
        -- Dùng GREATEST để lấy số lớn hơn giữa Thưởng 4 Quý và Giá trị thưởng
        GREATEST(
            (CAST(dso_q4_25_vat AS FLOAT64) * CAST(phan_tram_q4_25 AS FLOAT64)) + 
            (CAST(dso_q1_26_novat AS FLOAT64) * CAST(phan_tram_q1_26 AS FLOAT64)) + 
            (CAST(dso_q2_26_novat AS FLOAT64) * CAST(phan_tram_q2_26 AS FLOAT64)) + 
            (CAST(dso_q3_26_novat AS FLOAT64) * CAST(phan_tram_q3_26 AS FLOAT64)),
            CAST(gia_tri_thuong AS FLOAT64)
        ) AS tong_gia_tri_thuong
    FROM `spatial-vision-343005.warehouse.view_ct_thuong_commitment_2026_by_users`
)
, cost_data_raw AS (
    /* 1. Tracking Cost HCP */
    SELECT 
        ma_crm, ma_hco_chung, CAST(ma_hcp_2 AS STRING) as ma_hcp_2, 
        hoat_dong, CAST(hoat_dong_chi_tiet AS STRING) as hoat_dong_chi_tiet, 
        CAST(chi_tiet_qua_tang AS STRING) as chi_tiet_qua_tang, CAST(ghi_chu AS STRING) as ghi_chu,
        DATE(CAST(nam_thuc_hien AS INT64), CAST(thang_thuc_hien AS INT64), 1) as ngay, 
        chi_phi_thuc_hien_dong as gia_tri,
        CAST(khoa_phong AS STRING) AS khoa_phong,
        CAST(chi_phi_thuc_hien_dong/NULLIF(SUM(chi_phi_thuc_hien_dong) OVER (), 0) AS FLOAT64) AS ty_le_cost,
        CAST(don_vi AS STRING) as don_vi_goc 
    FROM `spatial-vision-343005.staging.d_tracking_cost_hcp_v2`

    UNION ALL
    /* 2. PCL (PKK) 2025 */
    SELECT 
        Case when kh.pubcustid ='000703' then a.ma_crm
        else IFNULL(c.supid,a.ma_crm) end as ma_crm, 
        kh.pubcustid, 
        CAST(NULL AS STRING), 'PCL (PKK)', 
        CAST(NULL AS STRING), 
        CAST(NULL AS STRING), 
        CAST(NULL AS STRING), 
        DATE('2025-01-01'), 
        SUM(gia_tri_tich_luy_quy_doi),
        CAST(NULL AS STRING), CAST(NULL AS FLOAT64),
        STRING_AGG(DISTINCT a.makenhphu, '&')
    FROM `spatial-vision-343005.warehouse.view_ds_pkk_trong_tam_2025` a
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` kh ON kh.custid = a.makhdms
    LEFT JOIN `warehouse.f_mapping_crs` c ON c.custid = a.makhdms
    GROUP BY 1,2,3,4,5,6,7,8

    UNION ALL
    /* 2.1 PCL (PKK) 2026 - Lấy từ bảng tạm phía trên */
    SELECT 
        Case when kh.pubcustid ='000703' then a.ma_crm
        else IFNULL(c.supid,a.ma_crm) end as ma_crm, 
        kh.pubcustid, 
        CAST(NULL AS STRING), 
        'PCL (PKK)', 
        CAST(NULL AS STRING), 
        CAST(NULL AS STRING),
        CAST(NULL AS STRING), 
        DATE('2026-01-01'), SUM(a.tong_gia_tri_thuong),
        CAST(NULL AS STRING), CAST(NULL AS FLOAT64),
        STRING_AGG(DISTINCT kh.shoptype, '&')
    FROM thuong_commitment_2026_tmp a
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` kh ON kh.custid = a.ma_kh
    LEFT JOIN `warehouse.f_mapping_crs` c ON c.custid = a.ma_kh
    GROUP BY 1,2,3,4,5,6,7,8

    UNION ALL
    /* 3. CPA PCL 2024 */
    SELECT 
        Case when kh.pubcustid ='000703' then a.ma_crm
        else IFNULL(c.supid,a.ma_crm) end as ma_crm,
        kh.pubcustid,
        CAST(NULL AS STRING),
        'CPA CLC', 
        CAST(NULL AS STRING),
        CAST(NULL AS STRING),
        CAST(NULL AS STRING), 
        DATE('2025-01-01'), 
        SUM(IFNULL(tong_tienthuong_clc12_q1,0) + IFNULL(tong_tienthuong_clc12_q2,0) + IFNULL(tong_tienthuong_clc12_q3,0) + IFNULL(tong_tienthuong_clc12,0) + 
            IFNULL(tong_tienthuong_clc3_q1,0) + IFNULL(tong_tienthuong_clc3_q2,0) + IFNULL(tong_tienthuong_clc3_q3,0) + IFNULL(tong_tienthuong_clc3,0)),
        CAST(NULL AS STRING), CAST(NULL AS FLOAT64),
        STRING_AGG(DISTINCT kh.shoptype, '&')
    FROM `spatial-vision-343005.warehouse.f_chuongtrinh_clc123_2024` a
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` kh ON kh.custid = a.makhdms
    LEFT JOIN `warehouse.f_mapping_crs` c ON c.custid = a.makhdms
    GROUP BY 1,2,3,4,5,6,7,8

    UNION ALL
    /* 4. KH VIP HCP */
    SELECT 
        Case when kh.pubcustid ='000703' then a.ma_crm
        else IFNULL(c.supid,a.ma_crm) end as ma_crm,
        kh.pubcustid,
        CAST(NULL AS STRING),
        'KH VIP HCP', 
        CAST(NULL AS STRING),
        CAST(NULL AS STRING),
        CAST(NULL AS STRING), 
        DATE('2025-01-01'), SUM(tong_tien_chiet_khau),
        CAST(NULL AS STRING), CAST(NULL AS FLOAT64),
        STRING_AGG(DISTINCT kh.shoptype, '&')
    FROM `spatial-vision-343005.warehouse.view_f_chuongtrinh_vip_hcp_2025_pbh` a
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` kh ON kh.custid = a.custid
    LEFT JOIN `warehouse.f_mapping_crs` c ON c.custid = a.custid
    GROUP BY 1,2,3,4,5,6,7,8

    UNION ALL
    /* 5. CT Loyalty 2025 */
    SELECT 
        Case when kh.pubcustid ='000703' then a.ma_crm
        else IFNULL(c.supid,a.ma_crm) end as ma_crm, 
        kh.pubcustid, CAST(NULL AS STRING), 'CT Loyalty', 
        CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING), 
        DATE('2025-01-01'), SUM(tong_tien_ck) + MAX(tong_tien_ck_nam),
        CAST(NULL AS STRING), CAST(NULL AS FLOAT64),
        STRING_AGG(DISTINCT kh.shoptype, '&')
    FROM `spatial-vision-343005.warehouse.f_view_form_theo_doi_CSBH_loyalty_PCL_2025` a
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` kh ON kh.custid = a.ma_kh
    LEFT JOIN `warehouse.f_mapping_crs` c ON c.custid = a.ma_kh
    GROUP BY 1,2,3,4,5,6,7,8

    UNION ALL
    /* 6. CT theo đơn hàng */
    SELECT 
        CASE 
        when kh.pubcustid ='000703' then a.crm
        WHEN b.makhdms IS NOT NULL THEN 'MR1137' ELSE IFNULL(c.supid, a.crm) END AS crm,
        kh.pubcustid,
        CAST(NULL AS STRING),
        CASE 
            WHEN a.makenhkh = 'CLC' THEN 'CT theo đơn hàng CLC'
            WHEN a.makenhkh = 'PCL' THEN 'CT theo đơn hàng PCL'
            ELSE 'CT theo đơn hàng'
        END AS hoat_dong,

        CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING), 
        DATE(ngaychungtu), SUM(IFNULL(chi_phi_hang_km,0)) + SUM(IFNULL(discamt,0)),
        CAST(NULL AS STRING), CAST(NULL AS FLOAT64),
        STRING_AGG(DISTINCT a.makenhphu, '&')
    FROM `spatial-vision-343005.warehouse.f_tongquat_ctkm` a
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` kh ON kh.custid = a.makhdms
    LEFT JOIN `warehouse.dim_excluded_makhdms` b ON b.makhdms = a.makhdms
    LEFT JOIN `warehouse.f_mapping_crs` c ON c.custid = a.makhdms
    WHERE a.makenhkh IN ('CLC','PCL')
      --AND b.makhdms IS NULL
      AND DATE(ngaychungtu) >= '2025-01-01'
    GROUP BY 1,2,3,4,5,6,7,8

    UNION ALL
    /* 7. MRTT */
    SELECT /* update nam_thuc_hien: ngày tháng luôn là 1/1 còn năm lấy cột nam*/
        supid, ma_kh_chung, CAST(NULL AS STRING), 'MRTT', 
        CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING), 
        DATE(CAST(nam AS INT64), 1, 1), SUM(ttyt_q1_lamtron+ttyt_q2_lamtron+ttyt_q3_lamtron+ttyt_q4_lamtron+chi_phi_dieu_chinh),
        CAST(NULL AS STRING), CAST(NULL AS FLOAT64),
        STRING_AGG(DISTINCT kenh_phu, '&')
    FROM `spatial-vision-343005.warehouse.view_mrtt_2025` a
    GROUP BY 1,2,3,4,5,6,7,8

    UNION ALL
    /* 8. CT Loyalty 2026 */
    SELECT 
        Case when kh.pubcustid ='000703' then a.ma_crm
        else IFNULL(c.supid,a.ma_crm) end as ma_crm, 
        kh.pubcustid, CAST(NULL AS STRING), 'CT Loyalty', 
        CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING), 
        DATE('2026-01-01'), 
        SUM(IFNULL(CAST(a.tong_tien_ck_q1 AS FLOAT64), 0) + IFNULL(CAST(a.tong_tien_ck_q2 AS FLOAT64), 0) + 
            IFNULL(CAST(a.tong_tien_ck_q3 AS FLOAT64), 0) + IFNULL(CAST(a.tong_tien_ck_q4 AS FLOAT64), 0) + 
            IFNULL(CAST(a.thanh_tien_km_ky_1 AS FLOAT64), 0) + IFNULL(CAST(a.thanh_tien_km_ky_2 AS FLOAT64), 0)
            + IFNULL(CAST(a.thanh_tien_km_nam AS FLOAT64), 0)),
        CAST(NULL AS STRING), CAST(NULL AS FLOAT64),
        STRING_AGG(DISTINCT a.kenh_phu, '&')
    FROM `spatial-vision-343005.warehouse.view_theo_doi_loyalty_pcl_2026` a
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` kh ON kh.custid = a.ma_kh
    LEFT JOIN `warehouse.f_mapping_crs` c ON c.custid = a.ma_kh
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8

    UNION ALL
    /* 9. CPA PCL 2026 */
    SELECT 
        Case when kh.pubcustid ='000703' then a.ma_crm
        else IFNULL(c.supid,a.ma_crm) end as ma_crm,
        kh.pubcustid, CAST(NULL AS STRING), 'CPA CLC', 
        CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING), 
        DATE('2026-01-01'), 
        SUM(IFNULL(a.tong_tienthuong_clc12_q1, 0) + IFNULL(a.tong_tienthuong_clc12_q2, 0) + 
            IFNULL(a.tong_tienthuong_clc12_q3, 0) + IFNULL(a.tong_tienthuong_clc12, 0) + 
            IFNULL(a.tong_tienthuong_clc3_q1, 0) + IFNULL(a.tong_tienthuong_clc3_q2, 0) + 
            IFNULL(a.tong_tienthuong_clc3_q3, 0) + IFNULL(a.tong_tienthuong_clc3, 0)),
        CAST(NULL AS STRING), CAST(NULL AS FLOAT64),
        STRING_AGG(DISTINCT a.shoptype, '&')
    FROM `spatial-vision-343005.warehouse.view_chuongtrinh_clc123_2026` a
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` kh ON kh.custid = a.makhdms
    LEFT JOIN `warehouse.f_mapping_crs` c ON c.custid = a.makhdms
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
)
, d_makenhphu_agg AS (
    -- Bảng tạo chuỗi makenhphu gom theo toàn bộ pubcustid
    SELECT 
        pubcustid,
        STRING_AGG(DISTINCT makenhphu, '&') AS chuoi_kenh_phu
    FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy`
    WHERE year >= 2025 
      AND pubcustid IS NOT NULL
    GROUP BY pubcustid
)
, raw_data AS (
    SELECT 
        ma_crm, ma_hco_chung, ma_hcp_2, CAST(hoat_dong AS STRING) AS hoat_dong, 
        CAST(hoat_dong_chi_tiet AS STRING) AS hoat_dong_chi_tiet, CAST(chi_tiet_qua_tang AS STRING) AS chi_tiet_qua_tang, 
        CAST(ghi_chu AS STRING) AS ghi_chu, ngay, gia_tri, khoa_phong, ty_le_cost, 'cost' as data_type,
        don_vi_raw
    FROM (SELECT *, don_vi_goc as don_vi_raw FROM cost_data_raw)
    
    UNION ALL
    SELECT 
        c.ma_crm1, c.hco_bv, CAST(c.ma_hcp_2 AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING), CAST(NULL AS STRING), 
        CAST(NULL AS STRING), DATE('2026-01-01'), 1, CAST(c.nganh_khoa_phong AS STRING), CAST(NULL AS FLOAT64), 
        'hcp_list',don_vi as don_vi_raw
   FROM `spatial-vision-343005.warehouse.view_data_tao_hcp_bv` c
    Where status = 'active'
    
    UNION ALL
    SELECT 
        Case
            when kh.pubcustid ='000703' then a.ma_crm
            when a.makhdms = 'NSPC0110144' then 'MR1555'
            when a.statedescr = 'Thừa Thiên Huế' AND IFNULL(c.supid,a.ma_crm) = 'MR1681' Then 'MR1555'
            else IFNULL(c.supid,a.ma_crm) end as ma_crm, 
        a.pubcustid, 
        CAST(NULL AS STRING),  
        'sales',              
        CAST(NULL AS STRING), 
        CAST(NULL AS STRING), 
        CAST(NULL AS STRING), 
        DATE(ngaychungtu), 
        SUM(a.doanhsochuavat), 
        CAST(NULL AS STRING), 
        CAST(NULL AS FLOAT64), 
        'sales', 
        STRING_AGG(DISTINCT a.makenhphu, '&')
    FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` kh on kh.custid = a.makhdms
    LEFT JOIN `warehouse.f_mapping_crs` c ON c.custid = a.makhdms
    LEFT JOIN `warehouse.dim_excluded_makhdms` b ON b.makhdms = a.makhdms
    WHERE a.year >= 2025 AND a.makenhkh_cu IN ('INS','CLC','PCL') 
    AND b.makhdms IS NULL
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12
)

, mapped_data AS (
    SELECT 
        u.*,
        
        -- BIẾN THÔNG MINH CHECK DLPP_CLC:
        CASE 
            WHEN u.don_vi_raw = 'DLPP_CLC' THEN s_master.shoptype
            ELSE u.don_vi_raw
        END AS v_check_don_vi,
        
        IFNULL(kh_m.pubcustname,p.custname) as ten_hco_chung,
        hcp.ten_hcp,
        hcp.kenh_lam_viec,
        hcp.tinh,
        hcp.phan_loai_hcp,
        COALESCE(REGEXP_EXTRACT(hcp.nganh_chuyen_khoa, r'([^-]+)-'), hcp.nganh_chuyen_khoa) AS khoa_phong_lam_viec,
        COALESCE(REGEXP_EXTRACT(hcp.nganh_khoa_phong, r'([^-]+)-'), hcp.nganh_khoa_phong) AS chuyen_khoa_hcp_hoc,
        hcp.chuc_vu,
        b.tencvbh as ten_crm,
        b.asm,
        b.tenquanlykhuvuc
        
    FROM raw_data u
    LEFT JOIN `spatial-vision-343005.staging.d_users` b on u.ma_crm = b.manv
    LEFT JOIN d_master_hcp_fix hcp ON hcp.ma_hcp_2 = u.ma_hcp_2
    LEFT JOIN (SELECT DISTINCT pubcustid, pubcustname FROM `spatial-vision-343005.staging.d_master_khachhang`) kh_m ON kh_m.pubcustid = u.ma_hco_chung
    LEFT JOIN `spatial-vision-343005.staging.d_public_cust` p ON p.pubcust = u.ma_hco_chung
    
    -- JOIN bảng master để vớt lại những khách hàng rớt vào DLPP_CLC
    LEFT JOIN d_shoptype s_master ON s_master.pubcustid = u.ma_hco_chung
)

SELECT 
    a.* EXCEPT(v_check_don_vi,khoa_phong),
    SPLIT(khoa_phong, '-')[SAFE_OFFSET(0)] AS khoa_phong,
    
    CASE 
        WHEN a.kenh_lam_viec IN ('PCL', 'GO', 'ED') THEN a.kenh_lam_viec
        WHEN a.don_vi_raw IN ('PCL', 'GO', 'ED', 'BV', 'PK') THEN don_vi_raw
        
        WHEN v_check_don_vi LIKE '%INS1%' OR v_check_don_vi LIKE '%CLC1%' OR v_check_don_vi LIKE '%CLC4%' 
          OR v_check_don_vi LIKE '%INS2%' OR v_check_don_vi LIKE '%CLC2%' THEN 'BV'
          
        WHEN v_check_don_vi LIKE '%INS3%' OR v_check_don_vi LIKE '%CLC3%' THEN 'PK'
        
        WHEN v_check_don_vi LIKE '%PCL%' THEN 'PCL'
        WHEN v_check_don_vi LIKE '%GO%' THEN 'GO'
        WHEN v_check_don_vi LIKE '%ED%' THEN 'ED'
        
        WHEN v_check_don_vi LIKE '%DLPP_CLC%' THEN 'DLPP_CLC'
        
        ELSE SPLIT(don_vi_raw, '&')[SAFE_OFFSET(0)] 
    END AS don_vi,

    /* LOGIC MỚI CHO kenh_hco_chung */
    CASE 
        WHEN a.kenh_lam_viec IN ('PCL', 'GO', 'ED') THEN a.kenh_lam_viec
        
        WHEN v_check_don_vi LIKE '%INS1%' OR v_check_don_vi LIKE '%CLC1%' OR v_check_don_vi LIKE '%CLC4%' THEN 'BVNN'
        
        WHEN v_check_don_vi LIKE '%INS2%' OR v_check_don_vi LIKE '%CLC2%' THEN 'BVTN'
        
        WHEN v_check_don_vi LIKE '%INS3%' OR v_check_don_vi LIKE '%CLC3%' THEN 'PK'
        
        WHEN v_check_don_vi LIKE '%PCL%' THEN 'PCL'
        WHEN v_check_don_vi LIKE '%GO%' THEN 'GO'
        WHEN v_check_don_vi LIKE '%ED%' THEN 'ED'
        
        WHEN v_check_don_vi LIKE '%DLPP_CLC%' THEN 'DLPP_CLC'

        ELSE SPLIT(don_vi_raw, '&')[SAFE_OFFSET(0)]
    END AS kenh_hco_chung,
    b.phan_hang_hcp

FROM mapped_data a
LEFT JOIN `spatial-vision-343005.warehouse.view_data_tao_hcp_bv` b ON b.ma_hcp_2 = a.ma_hcp_2



-- SELECT 
--     a.* EXCEPT(khoa_phong),
--     SPLIT(khoa_phong, '-')[SAFE_OFFSET(0)] AS khoa_phong,
--     b.phan_hang_hcp,
--     b.don_vi,
--     b.kenh_hco_chung

-- FROM mapped_data a
-- LEFT JOIN `spatial-vision-343005.warehouse.view_data_tao_hcp_bv` b ON b.ma_hcp_2 = a.ma_hcp_2




;