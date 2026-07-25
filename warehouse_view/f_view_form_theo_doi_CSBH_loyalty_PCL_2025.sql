CREATE VIEW `spatial-vision-343005.warehouse.f_view_form_theo_doi_CSBH_loyalty_PCL_2025`
AS with 
thu_hoi_hd as 

(
    select ma_kh,thu_hoi_ttmb,ghi_chu from `staging.d_manual_gs_csbh_loyalty_2025_tp_pcl`
    qualify row_number() over (partition by ma_kh order by thu_hoi_ttmb desc) = 1
)

, base_date as 
(
    SELECT 1 AS quy, 2025 AS nam, date('2025-03-01') as quy_filter,
    UNION ALL
    SELECT 2, 2025, date('2025-06-01')
    UNION ALL
    SELECT 3, 2025, date('2025-09-01')
    UNION ALL
    SELECT 4, 2025, date('2025-12-01')
)

, ds_kh as 
(
     SELECT 
     ma_kh,
     pl_hco,
     CAST(muc_hd_2025 AS INT64) as muc_hd_2025,
     phan_tram_tham_gia,
     CAST(quy_tham_gia AS INT64) as quy_tham_gia,
     CASE 
     WHEN muc_hd_2025 = 360000000 THEN 0.06
     WHEN muc_hd_2025 = 240000000 THEN 0.05
     WHEN muc_hd_2025 = 120000000 THEN 0.04
     WHEN muc_hd_2025 = 60000000 THEN 0.03
     ELSE 0  -- Default case if none of the conditions match
     END AS phan_tram_ck_all_nam_dk,

     dk_doanh_so_quy,
     xo,
     cl,
     ks,
     date(hieu_luc_hd) as hieu_luc_hd,
     date (hieu_luc_hd_ket_thuc) as hieu_luc_hd_ket_thuc
     FROM `spatial-vision-343005.staging.form_theo_doi_CSBH_loyalty_PCL_2025` 
     qualify row_number() over (PARTITION BY ma_kh,quy_tham_gia order by created_at desc) = 1
     )

     , sales as (
     SELECT
     makhdms,
     CAST(muc_hd_2025 AS INT64) as muc_hd_2025,
     EXTRACT(QUARTER FROM ngaychungtu) AS quy,
     EXTRACT(YEAR FROM ngaychungtu) AS nam,
     DATE(
     EXTRACT(YEAR FROM ngaychungtu), 
     EXTRACT(QUARTER FROM ngaychungtu) * 3, 
     1
     ) AS quy_filter,
     SUM(
     CASE 
          WHEN b.nhomcpa2025 = 'XO'  
               AND DATE(ngaychungtu) >= DATE(hl.hieu_luc_hd) 
               AND DATE(ngaychungtu) <= DATE(hl.hieu_luc_hd_ket_thuc)
               AND DATE(ngaychungtu) < '2025-12-27' 
          THEN doanhsocovat 
          ELSE 0 
     END
     ) AS ds_xo,
     SUM(
     CASE 
          WHEN b.nhomcpa2025 = 'CL'  
               AND DATE(ngaychungtu) >= DATE(hl.hieu_luc_hd) 
               AND DATE(ngaychungtu) <= DATE(hl.hieu_luc_hd_ket_thuc)
               AND DATE(ngaychungtu) < '2025-12-27' 
          THEN doanhsocovat 
          ELSE 0 
     END
     ) AS ds_cl,
     SUM(
     CASE 
          WHEN b.nhomcpa2025 = 'KS' 
               AND DATE(ngaychungtu) >= DATE(hl.hieu_luc_hd) 
               AND DATE(ngaychungtu) <= DATE(hl.hieu_luc_hd_ket_thuc)
               AND DATE(ngaychungtu) < '2025-12-27' 
          THEN doanhsocovat 
          ELSE 0 
     END
     ) AS ds_ks,

     FROM 
     `warehouse.f_raw_data_sales_yoy` a 
     LEFT JOIN `staging.d_nhom_sp_trading` b 
     ON a.masanpham = b.masanpham
     LEFT JOIN `ds_kh` hl 
     ON hl.ma_kh = a.makhdms
     WHERE 
     ngaychungtu >= '2025-01-02'
     and date(ngaychungtu) <= '2025-12-26' --PARSE_DATE("%Y%m%d", @DS_END_DATE)
     AND EXTRACT(QUARTER FROM ngaychungtu) between
    EXTRACT(QUARTER FROM DATE(hieu_luc_hd))
    AND EXTRACT(QUARTER FROM DATE(hieu_luc_hd_ket_thuc))
    AND a.macongtycn != 'DL0001'
    AND a.maphanloaihco_cu != 'NTXQPK'
     GROUP BY ALL
     )

, tong_ds_nam_du_kien as (
SELECT  
a.makhdms,

SUM(
    CASE    WHEN b.nhomcpa2025 in ('XO','CL','KS')
        THEN doanhsocovat
        ELSE 0 
    END
) AS tong_ds_nam,

SUM(
    CASE 
        WHEN b.nhomcpa2025 = 'XO' 
        THEN doanhsocovat
        ELSE 0 
    END
) AS tong_ds_xo_nam,

   SUM(
        CASE 
            WHEN b.nhomcpa2025 = 'CL' 
            THEN doanhsocovat 
            ELSE 0 
        END
    ) AS tong_ds_cl_nam,
   SUM(
        CASE 
            WHEN b.nhomcpa2025 = 'KS'
            THEN doanhsocovat 
            ELSE 0 
        END
    )AS tong_ds_ks_nam,
FROM `warehouse.f_raw_data_sales_yoy` a 
     LEFT JOIN `staging.d_nhom_sp_trading` b 
     ON a.masanpham = b.masanpham

WHERE DATE(ngaychungtu) >= '2025-01-02'
AND  DATE(ngaychungtu) < '2025-12-27'
AND a.macongtycn != 'DL0001'
AND a.maphanloaihco_cu != 'NTXQPK'
--and date(ngaychungtu) <= PARSE_DATE("%Y%m%d", @DS_END_DATE)
GROUP BY ALL
)


, mapping_sales as (
     SELECT 
     a.*,
     c.quy,
     c.nam,
     DATE(c.nam, c.quy * 3, 1) AS quy_filter,
     IFNULL(b.ds_xo, 0) AS ds_xo,
     IFNULL(b.ds_cl, 0) AS ds_cl,
     IFNULL(b.ds_ks, 0) AS ds_ks,
     IFNULL(b.ds_xo, 0) + IFNULL(b.ds_cl, 0) + IFNULL(b.ds_ks, 0) AS ds,
    d.tong_ds_nam,
    d.tong_ds_xo_nam,
    d.tong_ds_cl_nam,
    d.tong_ds_ks_nam
     FROM 
     ds_kh a
     LEFT JOIN base_date c 
     ON 1 = 1 
     AND c.nam = 2025
     LEFT JOIN sales b 
     ON a.ma_kh = b.makhdms  
     AND b.quy = c.quy 
     AND c.nam = b.nam
     and a.muc_hd_2025 = b.muc_hd_2025
     LEFT JOIN tong_ds_nam_du_kien d on a.ma_kh = d.makhdms
     WHERE true
    and c.quy >= EXTRACT(QUARTER FROM DATE(hieu_luc_hd))
    and c.quy <= EXTRACT(QUARTER FROM DATE(hieu_luc_hd_ket_thuc))
     )
     ,

     tinh_ds_luy_ke as (
     SELECT 
     *,
     SUM(ds_xo) 
     OVER (
          PARTITION BY ma_kh , muc_hd_2025
          ORDER BY quy_filter 
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
     ) AS ds_xo_luy_ke,
     SUM(ds_cl) 
     OVER (
          PARTITION BY ma_kh ,muc_hd_2025
          ORDER BY quy_filter 
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
     ) AS ds_cl_luy_ke,
     SUM(ds_ks) 
     OVER (
          PARTITION BY ma_kh ,muc_hd_2025
          ORDER BY quy_filter 
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
     ) AS ds_ks_luy_ke,
     SUM(ds) 
     OVER (
          PARTITION BY ma_kh , muc_hd_2025
          ORDER BY quy_filter 
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
     ) AS ds_luy_ke,
     SUM(dk_doanh_so_quy) OVER (
        PARTITION BY ma_kh,quy_tham_gia
        ORDER BY quy
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS dk_doanh_so_quy_luy_ke,
     ROUND(SAFE_DIVIDE(ds, dk_doanh_so_quy), 3) AS th_kpi_ds
     FROM 
     mapping_sales
)
, ty_le_thuc_hien_luy_ke as (
    SELECT *,
        SAFE_DIVIDE(
        ds_luy_ke,
        (muc_hd_2025*phan_tram_tham_gia)
        ) AS th_kpi_ds_luy_ke
    from 
    tinh_ds_luy_ke
)

,tinh_tien_ck_q1 as (
     SELECT 
     *,
    
     
     CASE 
     WHEN quy = 1 
          AND ROUND(th_kpi_ds_luy_ke, 3) >= 0.25 
     THEN ds_xo * xo
     ELSE 0 
     END AS tien_ck_xo,

     CASE 
     WHEN quy = 1 
          AND ROUND(th_kpi_ds_luy_ke, 3) >= 0.25 
     THEN ds_ks * ks
     ELSE 0 
     END AS tien_ck_ks,

     CASE 
     WHEN quy = 1 
          AND ROUND(th_kpi_ds_luy_ke, 3) >= 0.25 
     THEN ds_cl * cl
     ELSE 0 
     END AS tien_ck_cl,

    -- DỰ KIẾN
    CASE
        WHEN quy = 1 AND ds_luy_ke >= 0.8 * muc_hd_2025 / 12 * 3 -- rule 80%
        THEN ds_xo * xo
        ELSE 0 
    END AS tien_ck_xo_dukien,

    CASE 
        WHEN quy = 1 AND ds_luy_ke >= 0.8 * muc_hd_2025 / 12 * 3 -- rule 80%
        THEN ds_ks * ks
        ELSE 0 
    END AS tien_ck_ks_dukien,

    CASE
        WHEN quy = 1 AND ds_luy_ke >= 0.8 * muc_hd_2025 / 12 * 3 -- rule 80%
        THEN ds_cl * cl
        ELSE 0 
    END AS tien_ck_cl_dukien
FROM ty_le_thuc_hien_luy_ke
)
,tinh_tien_ck_q2 as (

SELECT 
     * EXCEPT (
     --ds_bao_luu_chua_ck, 
     tien_ck_xo_dukien, 
     tien_ck_ks_dukien, 
     tien_ck_cl_dukien, 
     tien_ck_cl, 
     tien_ck_xo, 
     tien_ck_ks
     ),
     

    CASE    
        WHEN quy = 2 AND ds_luy_ke >= dk_doanh_so_quy_luy_ke
            THEN ds_xo_luy_ke * xo - IFNULL(LAG(tien_ck_xo) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
        WHEN quy = 2 AND th_kpi_ds >= 1 
            THEN ds_xo * xo
        ELSE tien_ck_xo
    END AS tien_ck_xo,

    CASE    
        WHEN quy = 2 AND ds_luy_ke >= dk_doanh_so_quy_luy_ke 
        THEN ds_ks_luy_ke * ks - IFNULL(LAG(tien_ck_ks) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
        WHEN quy = 2 AND th_kpi_ds >= 1 
        THEN ds_ks * ks
        ELSE tien_ck_ks
    END AS tien_ck_ks,

    CASE    
        WHEN quy = 2 AND ds_luy_ke >= dk_doanh_so_quy_luy_ke
        THEN ds_cl_luy_ke * cl - IFNULL(LAG(tien_ck_cl) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
        WHEN quy = 2 AND th_kpi_ds >= 1 
        THEN ds_cl * cl
        ELSE tien_ck_cl
    END AS tien_ck_cl,
     
    --- DỰ KIẾN
    CASE
        WHEN quy = 2  AND ds_luy_ke >= 0.8 * muc_hd_2025 / 12 * EXTRACT(MONTH FROM CURRENT_DATE()) -- rule 80% ưu tiên 1
            THEN ds_xo_luy_ke * xo - IFNULL(LAG(tien_ck_xo) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
        WHEN quy = 2  AND ds >= 0.8 * muc_hd_2025 / 12 * -- rule 80% ưu tiên 2
            CASE 
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (1,4,7,10) THEN 1
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (2,5,8,11) THEN 2
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (3,6,9,12) THEN 3
                ELSE 0 END
            THEN ds_xo * xo
        ELSE tien_ck_xo_dukien 
    END AS tien_ck_xo_dukien,

    CASE    
        WHEN quy = 2 AND ds_luy_ke >= 0.8 * muc_hd_2025 / 12 * EXTRACT(MONTH FROM CURRENT_DATE()) -- rule 80% ưu tiên 1
            THEN ds_ks_luy_ke * ks - IFNULL(LAG(tien_ck_ks) OVER (PARTITION BY ma_kh, muc_hd_2025 ORDER BY quy_filter),0)
        WHEN quy = 2  AND ds >= 0.8 * muc_hd_2025 / 12 *  -- rule 80% ưu tiên 2
            CASE 
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (1,4,7,10) THEN 1
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (2,5,8,11) THEN 2
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (3,6,9,12) THEN 3
                ELSE 0 END
            THEN ds_ks * ks
        ELSE tien_ck_ks_dukien 
    END AS tien_ck_ks_dukien,

    CASE    
        WHEN quy = 2 AND ds_luy_ke >= 0.8 * muc_hd_2025 / 12 * EXTRACT(MONTH FROM CURRENT_DATE()) -- rule 80% -- rule 80% ưu tiên 1
            THEN ds_cl_luy_ke * cl - IFNULL(LAG(tien_ck_cl) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
        WHEN quy = 2  AND ds >= 0.8 * muc_hd_2025 / 12 *  -- rule 80% ưu tiên 2
            CASE 
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (1,4,7,10) THEN 1
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (2,5,8,11) THEN 2
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (3,6,9,12) THEN 3
                ELSE 0 END
            THEN ds_cl * cl
        ELSE tien_ck_cl_dukien 
    END AS tien_ck_cl_dukien,
     
    --  IF(
    --  quy = 2 
    --  AND th_kpi_ds_luy_ke < 0.5 
    --  AND LAG(th_kpi_ds) 
    --            OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter) < 1,
    --  ds_bao_luu_chua_ck + LAG(ds) 
    --            OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),
    --  ds_bao_luu_chua_ck
    --  ) AS ds_bao_luu_chua_ck
     
     FROM 
     tinh_tien_ck_q1
),
tinh_tien_ck_q3 as (
SELECT 
     * EXCEPT (
     --ds_bao_luu_chua_ck, 
     tien_ck_xo_dukien, 
     tien_ck_ks_dukien, 
     tien_ck_cl_dukien, 
     tien_ck_cl, 
     tien_ck_xo, 
     tien_ck_ks
     ),
     
     CASE    
          WHEN quy = 3 AND ds_luy_ke >= dk_doanh_so_quy_luy_ke
               THEN ds_xo_luy_ke * xo 
                - IFNULL(LAG(tien_ck_xo,1) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
                - IFNULL(LAG(tien_ck_xo,2) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
          WHEN quy = 3 AND th_kpi_ds >= 1 
               THEN ds_xo * xo
          ELSE  tien_ck_xo
     END AS tien_ck_xo,

     CASE    
          WHEN quy = 3 AND ds_luy_ke >= dk_doanh_so_quy_luy_ke
          THEN ds_ks_luy_ke * ks 
            - IFNULL(LAG(tien_ck_ks,1) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
            - IFNULL(LAG(tien_ck_ks,2) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
          WHEN quy = 3 AND th_kpi_ds >= 1 
          THEN ds_ks * ks
          ELSE tien_ck_ks
     END AS tien_ck_ks,
    -- ds_cl_luy_ke * cl as luy_ke_q3_cl,
    -- LAG(tien_ck_cl,1) OVER (PARTITION BY ma_kh ORDER BY quy_filter) as ck_cl_q2,
    -- LAG(tien_ck_cl,2) OVER (PARTITION BY ma_kh ORDER BY quy_filter) as ck_cl_q1,
     CASE    
          WHEN quy = 3 AND ds_luy_ke >= dk_doanh_so_quy_luy_ke
          THEN (ds_cl_luy_ke * cl)
            - IFNULL(LAG(tien_ck_cl,1) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
            - IFNULL(LAG(tien_ck_cl,2) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
          WHEN quy = 3 AND th_kpi_ds >= 1 
          THEN ds_cl * cl
          ELSE tien_ck_cl 
     END AS tien_ck_cl,
     
    --- DỰ KIẾN
    CASE
        WHEN quy = 3  AND ds_luy_ke >= 0.8 * muc_hd_2025 / 12 * EXTRACT(MONTH FROM CURRENT_DATE()) -- rule 80% ưu tiên 1
            THEN ds_xo_luy_ke * xo 
                - IFNULL(LAG(tien_ck_xo,1) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
                - IFNULL(LAG(tien_ck_xo,2) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
        WHEN quy = 3  AND ds >= 0.8 * muc_hd_2025 / 12 *  -- rule 80% ưu tiên 2
            CASE 
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (1,4,7,10) THEN 1
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (2,5,8,11) THEN 2
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (3,6,9,12) THEN 3
                ELSE 0 END
            THEN ds_xo * xo
        ELSE tien_ck_xo_dukien 
    END AS tien_ck_xo_dukien,

    CASE    
        WHEN quy = 3 AND ds_luy_ke >= 0.8 * muc_hd_2025 / 12 * EXTRACT(MONTH FROM CURRENT_DATE()) -- rule 80% ưu tiên 1
            THEN ds_ks_luy_ke * ks
             - IFNULL(LAG(tien_ck_ks,1) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
             - IFNULL(LAG(tien_ck_ks,2) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
        WHEN quy = 3  AND ds >= 0.8 * muc_hd_2025 / 12 *  -- rule 80% ưu tiên 2
            CASE 
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (1,4,7,10) THEN 1
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (2,5,8,11) THEN 2
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (3,6,9,12) THEN 3
                ELSE 0 END
            THEN ds_ks * ks
        ELSE tien_ck_ks_dukien 
    END AS tien_ck_ks_dukien,

    CASE    
        WHEN quy = 3 AND ds_luy_ke >= 0.8 * muc_hd_2025 / 12 * EXTRACT(MONTH FROM CURRENT_DATE()) -- rule 80% -- rule 80% ưu tiên 1
            THEN ds_cl_luy_ke * cl
             - IFNULL(LAG(tien_ck_cl,1) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
             - IFNULL(LAG(tien_ck_cl,2) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
        WHEN quy = 3  AND ds >= 0.8 * muc_hd_2025 / 12 *  -- rule 80% ưu tiên 2
            CASE 
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (1,4,7,10) THEN 1
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (2,5,8,11) THEN 2
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (3,6,9,12) THEN 3
                ELSE 0 END
            THEN ds_cl * cl
        ELSE tien_ck_cl_dukien 
    END AS tien_ck_cl_dukien,
     
    --  ds_bao_luu_chua_ck + IF(
    --  quy = 3 
    --  AND th_kpi_ds_luy_ke < 0.75 
    --  AND LAG(th_kpi_ds, 2) 
    --            OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter) < 1, 
    --  LAG(ds) 
    --            OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),
    --  0
    --  ) + IF(
    --  quy = 3 
    --  AND th_kpi_ds_luy_ke < 0.75 
    --  AND LAG(th_kpi_ds, 2) 
    --            OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter) < 1, 
    --  LAG(ds, 2) 
    --            OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),
    --  0
    --  ) AS ds_bao_luu_chua_ck
     
     FROM 
     tinh_tien_ck_q2
)

,
tinh_tien_ck_q4 as (

SELECT 
     * EXCEPT (
     tien_ck_xo_dukien, 
     tien_ck_ks_dukien, 
     tien_ck_cl_dukien, 
     tien_ck_cl, 
     tien_ck_xo, 
     tien_ck_ks
     ),
    tong_ds_xo_nam AS tong_ds_xo_nam_dk,
    tong_ds_cl_nam AS tong_ds_cl_nam_dk,
    tong_ds_ks_nam AS tong_ds_ks_nam_dk,
    tong_ds_nam as tong_ds_nam_dk,
     CASE    
          WHEN quy = 4 AND ds_luy_ke >= dk_doanh_so_quy_luy_ke
               THEN ds_xo_luy_ke * xo 
                - IFNULL(LAG(tien_ck_xo,1) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
                - IFNULL(LAG(tien_ck_xo,2) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
                - IFNULL(LAG(tien_ck_xo,3) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
          WHEN quy = 4 AND th_kpi_ds >= 1 
               THEN ds_xo * xo
          ELSE  tien_ck_xo
     END AS tien_ck_xo,

     CASE    
          WHEN quy = 4 AND ds_luy_ke >= dk_doanh_so_quy_luy_ke 
          THEN ds_ks_luy_ke * ks 
            - IFNULL(LAG(tien_ck_ks,1) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
            - IFNULL(LAG(tien_ck_ks,2) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
            - IFNULL(LAG(tien_ck_ks,3) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
          WHEN quy = 4 AND th_kpi_ds >= 1 
          THEN ds_ks * ks
          ELSE tien_ck_ks
     END AS tien_ck_ks,

     CASE    
          WHEN quy = 4 AND ds_luy_ke >= dk_doanh_so_quy_luy_ke
          THEN ds_cl_luy_ke * cl 
            - IFNULL(LAG(tien_ck_cl,1) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
            - IFNULL(LAG(tien_ck_cl,2) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
            - IFNULL(LAG(tien_ck_cl,3) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
          WHEN quy = 4 AND th_kpi_ds >= 1 
          THEN ds_cl * cl
          ELSE tien_ck_cl
     END AS tien_ck_cl,

    --- DỰ KIẾN
    CASE
        WHEN quy = 4  AND ds_luy_ke >= 0.8 * muc_hd_2025 / 12 * EXTRACT(MONTH FROM CURRENT_DATE()) -- rule 80% ưu tiên 1
            THEN ds_xo_luy_ke * xo 
                - IFNULL(LAG(tien_ck_xo,1) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
                - IFNULL(LAG(tien_ck_xo,2) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
                - IFNULL(LAG(tien_ck_xo,3) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
        WHEN quy = 4  AND ds >= 0.8 * muc_hd_2025 / 12 *  -- rule 80% ưu tiên 2
            CASE 
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (1,4,7,10) THEN 1
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (2,5,8,11) THEN 2
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (3,6,9,12) THEN 3
                ELSE 0 END
            THEN ds_xo * xo
        ELSE tien_ck_xo_dukien 
    END AS tien_ck_xo_dukien,

    CASE    
        WHEN quy = 4 AND ds_luy_ke >= 0.8 * muc_hd_2025 / 12 * EXTRACT(MONTH FROM CURRENT_DATE()) -- rule 80% ưu tiên 1
            THEN ds_ks_luy_ke * ks 
                - IFNULL(LAG(tien_ck_ks,1) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
                - IFNULL(LAG(tien_ck_ks,2) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
                - IFNULL(LAG(tien_ck_ks,3) OVER (PARTITION BY ma_kh,quy_tham_gia ORDER BY quy_filter),0)
        WHEN quy = 4  AND ds >= 0.8 * muc_hd_2025 / 12 *  -- rule 80% ưu tiên 2
            CASE 
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (1,4,7,10) THEN 1
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (2,5,8,11) THEN 2
                WHEN EXTRACT(MONTH FROM CURRENT_DATE()) in (3,6,9,12) THEN 3
                ELSE 0 END
            THEN ds_ks * ks
        ELSE tien_ck_ks_dukien 
    END AS tien_ck_ks_dukien,

    CASE    
        WHEN quy = 4 AND ds_luy_ke >= 0.8 * muc_hd_2025 / 12 * EXTRACT(MONTH FROM CURRENT_DATE()) -- rule 80% -- rule 80% ưu tiên 1
            THEN ds_cl_luy_ke * cl 
                - IFNULL(LAG(tien_ck_cl,1) OVER (PARTITION BY ma_kh,muc_hd_2025 ORDER BY quy_filter),0)
                - IFNULL(LAG(tien_ck_cl,2) OVER (PARTITION BY ma_kh,muc_hd_2025 ORDER BY quy_filter),0)
                - IFNULL(LAG(tien_ck_cl,3) OVER (PARTITION BY ma_kh,muc_hd_2025 ORDER BY quy_filter),0)
        WHEN quy = 4  AND ds >= 0.8 * muc_hd_2025 / 12 * 1 -- rule 80% ưu tiên 2
            THEN ds_cl * cl
        ELSE tien_ck_cl_dukien 
    END AS tien_ck_cl_dukien,

     FROM 
     tinh_tien_ck_q3 a
)

,ty_le_ck_nam AS  (
SELECT *,
        CASE 
               WHEN tong_ds_nam >= 360000000 AND pl_hco IN ('PKN','PKQ') THEN 'Diamond'
               WHEN tong_ds_nam >= 600000000 THEN 'Diamond'
               WHEN tong_ds_nam >= 240000000 THEN 'Platinum'
               WHEN tong_ds_nam >= 120000000 THEN 'Gold'
               WHEN tong_ds_nam >= 60000000 THEN 'Silver'
               WHEN tong_ds_nam >= 36000000 THEN 'Copper'
               ELSE ''  -- If none of the conditions are met
          END AS hang_tv_nam,
        CASE 
          WHEN tong_ds_nam >= 360000000 AND pl_hco IN ('PKN','PKQ') THEN 0.06
          WHEN tong_ds_nam >= 600000000 THEN 0.06
          WHEN tong_ds_nam >= 240000000 THEN 0.05
          WHEN tong_ds_nam >= 120000000 THEN 0.04
          WHEN tong_ds_nam >= 60000000 THEN 0.03
          ELSE 0
          END AS ck_nam,
FROM tinh_tien_ck_q4
)
, chiet_khau_da_thanh_toan as (
SELECT
  branchid,
  accumulateid,
  custid,
  EXTRACT(QUARTER FROM CAST(todate AS DATE)) AS quy,
  EXTRACT(YEAR FROM CAST(todate AS DATE)) AS nam,
  SUM(amt) AS thuong_tich_luy,
  SUM(paidamt) AS da_tra
FROM
  `staging.f_paidso_acculate`
WHERE
  accumulateid IN ('202501-TL-QD884-PKN-PKQ')
GROUP BY ALL
)

, ds_ctkm_dstl as (
SELECT  
makhdms,
SUM(CASE WHEN discidpn = '202511-DH-CPA99-PCL-TL' THEN doanhsocovat ELSE 0 END) as dstl_ct134,
SUM(CASE WHEN discidpn = '202512-DH-CPA103-PCL-TL' THEN doanhsocovat ELSE 0 END) as dstl_tri_an_kh,
SUM(CASE WHEN discidpn = '202512-DH-CPA104-PCL-TL' THEN doanhsocovat ELSE 0 END) as dstl_ct_ks,

FROM `spatial-vision-343005.warehouse.f_tongquat_ctkm` 
WHERE 
date(ngaychungtu) <= '2025-12-26' --PARSE_DATE("%Y%m%d", @DS_END_DATE)
AND discidpn in ('202511-DH-CPA99-PCL-TL','202512-DH-CPA103-PCL-TL','202512-DH-CPA104-PCL-TL')
GROUP By 1

)
SELECT 
     a.*,
     tien_ck_xo + tien_ck_ks + tien_ck_cl AS tong_tien_ck,
     tien_ck_xo_dukien + tien_ck_ks_dukien + tien_ck_cl_dukien AS tong_tien_ck_dukien,
     tong_ds_nam * ck_nam AS tong_tien_ck_nam,
     
     CASE 
     WHEN tong_ds_nam_dk >= 0.8 * muc_hd_2025 / 12 * EXTRACT(MONTH FROM CURRENT_DATE()) -- rule 80%
     THEN tong_ds_nam_dk * phan_tram_ck_all_nam_dk 
     ELSE 0
     END AS tong_tien_ck_nam_du_kien,
     IF(ds_luy_ke < dk_doanh_so_quy_luy_ke, dk_doanh_so_quy_luy_ke - ds_luy_ke,0 ) as ds_thieu_luy_ke,
     0.06 AS ck_nam_dukien,
     'Diamond' AS hang_nam_dukien,

     b.custname,
     b.channel,
     b.hcotypeid,
     b.branchid,
     b.statedescr,
     b.shortterritorydescr,

     IF(
     DATE(b.legaldate) >= CURRENT_DATE("+7"), 
     'Còn hiệu lực', 
     'Hết hiệu lực'
     ) AS hieu_luc_gdp,

     b.shoptype,
     b.stocksales AS tinh_trang_ma_so_thue, 
     b.businessscope AS pham_vi_kinh_doanh,

     d.manv AS ma_crs,
     d.tencvbh AS ten_crs,
     h.ma_cre,
     h.ho_ten_cre,
     d.supid AS ma_crm,
     d.tenquanlytt AS ten_crm,
     d.rsmid AS ma_ncxm,
     d.tenquanlyvung AS ten_ncxm,

     IFNULL(e.thu_hoi_ttmb, 'Chưa thu') AS thu_hoi_ttmb,
     e.ghi_chu,
  	 IFNULL(f.da_tra,0) as ck_da_tra,
     IFNULL(f.thuong_tich_luy,0) as thuong_tich_luy,
     (
     SELECT MAX(inserted_at) 
     FROM warehouse.f_raw_data_sales_yoy 
     WHERE ngaychungtu >= '2025-01-01'
     ) AS inserted_at,

     IFNULL(g.dstl_ct134,0) as dstl_ct134,
     IFNULL(g.dstl_tri_an_kh,0) as dstl_tri_an_kh,
     IFNULL(g.dstl_ct_ks,0) as dstl_ct_ks
     
     FROM 
     ty_le_ck_nam a
     LEFT JOIN `staging.d_master_khachhang` b ON a.ma_kh = b.custid
     LEFT JOIN `warehouse.f_mapping_crs` c ON a.ma_kh = c.custid
     LEFT JOIN `staging.d_users` d ON c.col.ma_nvbh = d.manv
     LEFT JOIN thu_hoi_hd e ON e.ma_kh = a.ma_kh
  	 LEFT JOIN chiet_khau_da_thanh_toan f on f.custid = a.ma_kh and a.quy = f.quy and a.nam=f.nam
     LEFT JOIN `spatial-vision-343005.staging.d_calendar_cre` h ON c.col.ma_nvbh = h.ma_crs AND date(h.thang) = DATE_TRUNC(DATE(CURRENT_DATE()),MONTH)
     LEFT JOIN ds_ctkm_dstl g on g.makhdms = a.ma_kh
     --WHERE EXTRACT(QUARTER FROM PARSE_DATE("%Y%m%d", @DS_END_DATE) ) = a.quy
     --date (quy_filter) >= '2025-01-01'
     --a.ma_kh ='010577'
  ;