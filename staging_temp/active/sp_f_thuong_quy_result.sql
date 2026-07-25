CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_thuong_quy_result()
BEGIN
  
CREATE TEMP TABLE `f_thuong_quy_result` AS

(

WITH danhsach_ns AS (
    SELECT
        msnvcsmmoi,
        chucdanhengtitlesum,
        ngaykyhdldchinhthuc,
        ngayvaolamonboarddate,
        loaihdld,
        thang,
        extract( quarter  FROM thang ) AS quy,
        extract( year FROM  thang ) AS nam,
    FROM
        `staging.d_hr_dsns_bytime`
    WHERE

        CAST(DATE(thang) AS STRING FORMAT 'MMDD') IN('0301','0601', '0901', '1201')
)

,
-- data_luong AS (
from_luong AS (
        SELECT
        dtype,
        extract(quarter FROM a.thang ) AS quy,
        extract( year FROM a.thang) AS nam,
        a.thang,
        a.stt_thang_trong_quy,
        manv,
        tencvbh,
        chuc_vu,
        makenhkh,
        supid,
        tenquanlytt,
        asm,
        tenquanlykhuvuc,
        tenquanlyvung,
        rsmid,
        doanhsochuavat,
        kh_total,

        /* METRICS TP */
        -- th_sptt,
        -- kpi_ds_sptt,
        th_kpi_sptt,

        /* METRICS MT */
        CASE
            WHEN a.thang >= '2025-10-01' THEN th_fmcg_toanquoc
            ELSE th_fmcg END AS th_fmcg,
        CASE
            WHEN a.thang >= '2025-10-01' THEN kpi_fmcg_toanquoc
            ELSE kpi_fmcg END AS kpi_fmcg,
        so_kh_vieng_tham,
        kpi_vieng_tham_kh_mt,
        kpi_ds_sptt_mt,
        th_sptt_mt,

        /* METRICS HCP */
        ds_pcl,
        kh_total_pcl,
        ds_clc,
        kh_total_clc,

        kh_total_ins_toanquoc,
        ds_ins_toanquoc,
        kh_total_pcl_toanquoc,
        ds_pcl_toanquoc,

        th_ds_mt,
        kh_total_mt,
        
        th_sptt_mt_crm,
        kpi_ds_sptt_mt_crm,
        
        th_fmcg_toanquoc,
        kpi_fmcg_toanquoc
        

    FROM
        `warehouse.f_luonghieuqua_all_2024` a 
where a.thang >='2025-01-01'
--AND a.thang <='2025-03-01' 
    
)
-- SELECT *
-- FROM from_luong 
-- where quy = 1 and manv = 'MR1179'


,   distint_manv AS (
    SELECT
        DISTINCT manv,
        quy,
        nam,
        makenhkh,
        tencvbh,
        supid,
        tenquanlytt,
        asm,
        tenquanlykhuvuc,
        tenquanlyvung,
        rsmid
    FROM
        from_luong
)

, mapping_nv_ql AS (
    SELECT
        manv,
        tencvbh,
        makenhkh,
        quy,
        nam,
        string_agg(distinct supid, ',') AS supid,
        string_agg(distinct tenquanlytt, ',') tenquanlytt,
        string_agg(distinct asm, ',') AS asm,
        string_agg(distinct tenquanlykhuvuc, ',') tenquanlykhuvuc,
        string_agg(distinct rsmid, ',') AS rsmid,
        string_agg(distinct tenquanlyvung, ',') AS tenquanlyvung
    FROM
        distint_manv
    GROUP BY all
)

, trich_lap_crm as
(
SELECT 
    macrm,
    EXTRACT(QUARTER FROM thang) AS quy,
    EXTRACT(YEAR FROM thang) AS nam,
    SUM(tong_trich_hientai_crm) AS tong_trich_hientai_crm,
    SUM(noxautrichlap) AS noxautrichlap,
    ROUND(
        SAFE_DIVIDE(SUM(tong_trich_hientai_crm), SUM(noxautrichlap)) * 100,1
    ) AS ty_le_trich_lap

FROM 
    `spatial-vision-343005.warehouse.f_trich_lap_du_phong_du_no`

WHERE
    true
    -- AND date(thang)>= '2025-01-01'
    AND CAST(DATE(thang) AS STRING FORMAT 'MMDD') IN ('0301', '0601', '0901', '1201')
    AND (
        channel IN ('INS', 'PCL', 'CLC')
        OR noxautrichlap <> 0
    )

GROUP BY 1, 2, 3
)

, trich_lap_no_xau
as
(
SELECT * from trich_lap_crm
UNION ALL
SELECT
'MR1681' as macrm,
quy,
nam,
SUM(tong_trich_hientai_crm) as tong_trich_hientai_crm,
SUM(noxautrichlap) as noxautrichlap,
ROUND(
    SAFE_DIVIDE(SUM(tong_trich_hientai_crm),
    SUM(noxautrichlap)) * 100,1
) AS ty_le_trich_lap
FROM trich_lap_crm where macrm in ('MR1391','MR1579','MR2355') and nam <= 2025
GROUP BY ALL
)

/* TÍNH NỢ XẤU TỪ 2026 CHO LỚP CRM (GỘP THỰC TẾ + KẾ HOẠCH) */
, tieu_chi_no_xau_crm AS (
    SELECT 
        k.ma_nv,
        c.asm, 
        EXTRACT(QUARTER FROM PARSE_DATE('%d/%m/%Y', k.thang)) AS quy, 
        EXTRACT(YEAR FROM PARSE_DATE('%d/%m/%Y', k.thang)) AS nam,
        
        /* Chỉ lấy Tổng nợ xấu */
        SUM(CASE WHEN a.phanloai_no IN ('Nợ đỏ', 'Nợ đen') THEN a.du_cuoi_ky_no ELSE 0 END) AS tong_no_xau,
        
        /* Chỉ lấy Kế hoạch nợ xấu */
        MAX(k.ke_hoach) AS ke_hoach_no_xau

    FROM `spatial-vision-343005.staging.d_manual_ke_hoach_no_xau_crm` k
    /* JOIN thẳng với bảng manual để lấy tỷ lệ kế hoạch theo Quý/Năm */
    LEFT JOIN `spatial-vision-343005.warehouse.view_cong_no_kt_thuong_quy_hcp` a
        ON a.ma_crm = k.ma_nv 
        AND EXTRACT(QUARTER FROM CAST(a.thang AS TIMESTAMP)) = EXTRACT(QUARTER FROM PARSE_DATE('%d/%m/%Y', k.thang))
        AND EXTRACT(YEAR FROM CAST(a.thang AS TIMESTAMP)) = EXTRACT(YEAR FROM PARSE_DATE('%d/%m/%Y', k.thang))
    LEFT JOIN `staging.d_users_bytime` c ON c.manv = k.ma_nv AND PARSE_DATE('%d/%m/%Y', k.thang) = date(c.thang)
    GROUP BY 1, 2, 3, 4
)

/* 2. TÍNH NỢ XẤU TỪ 2026 CHO LỚP N.CRM (CUỘN TỪ CTE CRM LÊN) */
, tieu_chi_no_xau_ncrm AS (
    SELECT 
        c.asm AS ma_nv, 
        c.quy, 
        c.nam,
        
        /* Cuộn tổng nợ xấu từ CRM lên */
        SUM(c.tong_no_xau) AS tong_no_xau,
        
        /* Cuộn Kế hoạch của cấp N.CRM/ASM */
        MAX(k.ke_hoach) AS ke_hoach_no_xau

    FROM tieu_chi_no_xau_crm c
    LEFT JOIN `spatial-vision-343005.staging.d_manual_ke_hoach_no_xau_crm` k
        ON k.ma_nv = c.asm 
        AND EXTRACT(QUARTER FROM PARSE_DATE('%d/%m/%Y', k.thang)) = c.quy
        AND EXTRACT(YEAR FROM PARSE_DATE('%d/%m/%Y', k.thang)) = c.nam
    GROUP BY 1, 2, 3
)

, data_nv_kpi AS (
SELECT
    DATE(a.nam, a.quy * 3, 1) AS quy_filter,
    a.quy,
    a.nam,
    a.manv,
    a.makenhkh,

    a.chuc_vu,
    trim(upper(d.chucdanhengtitlesum)) as chuc_danh,
    
    SUM(doanhsochuavat) AS doanhsochuavat,
    SUM(kh_total) AS kh_total,

    IFNULL(tong_sl_pp_mcp, 0) as tong_sl_pp_mcp,
    IFNULL(b.th_kh_pp, 0) AS th_kh_pp,
    IFNULL(b.sl_kh_mcp, 0) AS sl_kh_mcp,
    ROUND(SAFE_DIVIDE(IFNULL(b.th_kh_pp, 0), IFNULL(b.sl_kh_mcp, 0)) * 100, 1) AS kpi_pp_kh,

    -- SUM(th_sptt) AS th_sptt,
    -- SUM(kpi_ds_sptt) AS kpi_ds_sptt,

    SUM(IF(a.stt_thang_trong_quy = 1,a.th_kpi_sptt, 0.0 )) as th_kpi_sptt_t1,
    SUM(IF(a.stt_thang_trong_quy = 2,a.th_kpi_sptt, 0.0 )) as th_kpi_sptt_t2,
    SUM(IF(a.stt_thang_trong_quy = 3,a.th_kpi_sptt, 0.0 )) as th_kpi_sptt_t3,
    ---th/kh t2
    ---th/kh t3



    0.0 as ds_pcl,
    0.0 as kh_total_pcl,

    SUM(
        ds_pcl + ds_clc
    ) AS ds_pcl_clc,

    SUM(
        kh_total_pcl + kh_total_clc
    ) AS kh_total_pcl_clc,


    0.0 AS th_nhaphang_mt,
    0.0 AS kpi_nhaphang_mt,
    0.0 as tile_sp_dat,

    0.0 as tong_trich_hientai_crm,

    SUM(IFNULL(th_ds_mt, 0)) AS th_ds_mt,
    SUM(IFNULL(kh_total_mt, 0)) AS kh_total_mt,

    SUM(IFNULL(th_sptt_mt_crm, 0)) AS th_sptt_mt_crm,
    SUM(IFNULL(kpi_ds_sptt_mt_crm, 0)) AS kpi_ds_sptt_mt_crm,

    SUM(IFNULL(th_fmcg_toanquoc, 0)) AS th_fmcg_toanquoc,
    SUM(IFNULL(kpi_fmcg_toanquoc, 0)) AS kpi_fmcg_toanquoc,

    0.0 as noxautrichlap,
    0.0 as ty_le_trich_lap,

    0.0 as kh_total_ins_toanquoc,
    0.0 as ds_ins_toanquoc,
    0.0 as kh_total_pcl_toanquoc,
    0.0 as ds_pcl_toanquoc,

    SUM(IFNULL(th_fmcg, 0)) AS th_fmcg,
    SUM(IFNULL(kpi_fmcg, 0)) AS kpi_fmcg,

    SUM(IFNULL(th_sptt_mt,0)) AS th_sptt_mt,
    SUM(IFNULL(kpi_ds_sptt_mt,0)) AS kpi_ds_sptt_mt,

    SUM(so_kh_vieng_tham) AS so_kh_vieng_tham,
    SUM(kpi_vieng_tham_kh_mt) AS kpi_vieng_tham_kh_mt,

    FROM
    from_luong a
    -- LEFT JOIN mapping_nv_ql c ON a.manv = c.manv
    -- AND a.quy = c.quy
    -- AND a.nam = c.nam
    -- AND c.makenhkh = a.makenhkh

    LEFT JOIN danhsach_ns d on d.msnvcsmmoi = a.manv and DATE(a.nam, a.quy * 3, 1) = date(d.thang)

    LEFT JOIN `staging_temp.view_dynamic_sl_kh_pp_mcp_manv` b
    
    ON a.manv = b.manv
    AND a.quy = b.quy
    AND a.nam = b.nam

    where a.dtype = 'nv'
    GROUP BY ALL
    
)

, data_sup_kpi as

(   
    SELECT
    DATE(a.nam, a.quy * 3, 1) AS quy_filter,
    a.quy,
    a.nam,
    a.manv,
    a.makenhkh,

    a.chuc_vu,
    trim(upper(d.chucdanhengtitlesum)) as chuc_danh,

    SUM(doanhsochuavat) AS doanhsochuavat,
    SUM(kh_total) AS kh_total,

    IFNULL(tong_sl_pp_mcp, 0) as tong_sl_pp_mcp,
    IFNULL(b.th_kh_pp, 0) AS th_kh_pp,
    IFNULL(b.sl_kh_mcp, 0) AS sl_kh_mcp,
    ROUND(SAFE_DIVIDE(IFNULL(b.th_kh_pp, 0), IFNULL(b.sl_kh_mcp, 0)) * 100, 1) AS kpi_pp_kh,

    -- SUM(th_sptt) AS th_sptt,
    -- SUM(kpi_ds_sptt) AS kpi_ds_sptt,

    SUM(IF(a.stt_thang_trong_quy = 1,a.th_kpi_sptt, 0.0 )) as th_kpi_sptt_t1,
    SUM(IF(a.stt_thang_trong_quy = 2,a.th_kpi_sptt, 0.0 )) as th_kpi_sptt_t2,
    SUM(IF(a.stt_thang_trong_quy = 3,a.th_kpi_sptt, 0.0 )) as th_kpi_sptt_t3,    
    -- 1. Nhóm PCL (NV có, SUP gán 0)
    0.0 as ds_pcl,
    0.0 as kh_total_pcl,

    -- 2. Nhóm Tổng PCL+CLC
    SUM(ds_pcl + ds_clc) AS ds_pcl_clc,
    SUM(kh_total_pcl + kh_total_clc) AS kh_total_pcl_clc,

    -- 3. Nhóm Nhập hàng MT
    MAX(mt.sl_sp_dat) AS th_nhaphang_mt,
    MAX(mt.kpi_sp) AS kpi_nhaphang_mt,
    MAX(mt.tile_sp_dat) as tile_sp_dat,

    -- 4. Nhóm Trích lập CRM
    tl.tong_trich_hientai_crm,

    -- 5. Nhóm MT (NV có, SUP gán NULL/0) - Cần chú ý thứ tự: th_ds_mt -> kh_total_mt
    NULL AS th_ds_mt,
    NULL AS kh_total_mt,

    -- 6. Nhóm SPTT MT CRM (NV có, SUP gán NULL)
    NULL AS th_sptt_mt_crm,
    NULL AS kpi_ds_sptt_mt_crm,

    -- 7. Nhóm FMCG Toàn quốc (NV có, SUP gán NULL)
    NULL AS th_fmcg_toanquoc,
    NULL AS kpi_fmcg_toanquoc,

    -- 8. Nhóm Nợ xấu (tiếp tục của trích lập)
    tl.noxautrichlap,
    tl.ty_le_trich_lap,

    -- 9. Nhóm INS/PCL Toàn quốc
    sum(a.kh_total_ins_toanquoc) as kh_total_ins_toanquoc,
    sum(a.ds_ins_toanquoc) as ds_ins_toanquoc,
    sum(a.kh_total_pcl_toanquoc) as kh_total_pcl_toanquoc,
    sum(a.ds_pcl_toanquoc) as ds_pcl_toanquoc,

    -- 10. Nhóm FMCG (Bây giờ mới đến nhóm này)
    SUM(IFNULL(th_fmcg, 0)) AS th_fmcg,
    SUM(IFNULL(kpi_fmcg, 0)) AS kpi_fmcg,

    -- 11. Nhóm SPTT MT
    SUM(IFNULL(th_sptt_mt,0)) AS th_sptt_mt,
    SUM(IFNULL(kpi_ds_sptt_mt,0)) AS kpi_ds_sptt_mt,

    -- 12. Nhóm Viếng thăm
    SUM(so_kh_vieng_tham) AS so_kh_vieng_tham,
    SUM(kpi_vieng_tham_kh_mt) AS kpi_vieng_tham_kh_mt
    
    

    FROM
    from_luong a
    LEFT JOIN danhsach_ns d on d.msnvcsmmoi = a.manv and DATE(a.nam, a.quy * 3, 1) = date(d.thang)
    LEFT JOIN `staging_temp.view_dynamic_sl_kh_pp_mcp_supid` b
    ON a.manv = b.manv
    AND a.quy = b.quy
    AND a.nam = b.nam

    LEFT JOIN `staging_temp.view_kpi_nhap_hang_mt` mt -- chỉ có KAM MT mới có
    ON mt.crm = a.manv
    AND mt.quy = a.quy
    AND mt.nam = a.nam

    LEFT JOIN `trich_lap_no_xau` tl -- chỉ có HCP mới có
    ON tl.macrm = a.manv
    AND tl.quy = a.quy
    AND tl.nam = a.nam

    where a.dtype in ('crm')
    GROUP BY all
)

, data_ncrm_kpi as
(   
    SELECT
    DATE(a.nam, a.quy * 3, 1) AS quy_filter,
    a.quy,
    a.nam,
    a.manv, /* N.CRM sẽ map với mã asm */
    a.makenhkh,

    'N.CRM' as chuc_vu,
    trim(upper(MAX(d.chucdanhengtitlesum))) as chuc_danh,

    /* Lấy đúng 2 dữ kiện cần thiết cho Tiêu chí A */
    SUM(a.doanhsochuavat) AS doanhsochuavat,
    SUM(a.kh_total) AS kh_total,

    /* Đệm các field không dùng đến cho bằng với schema của data_sup_kpi */
    0.0 as tong_sl_pp_mcp, 0.0 as th_kh_pp, 0.0 as sl_kh_mcp, 0.0 as kpi_pp_kh,
    0.0 as th_kpi_sptt_t1, 0.0 as th_kpi_sptt_t2, 0.0 as th_kpi_sptt_t3,    
    0.0 as ds_pcl, 0.0 as kh_total_pcl, 0.0 as ds_pcl_clc, 0.0 as kh_total_pcl_clc,
    0.0 as th_nhaphang_mt, 0.0 as kpi_nhaphang_mt, 0.0 as tile_sp_dat,
    
    0.0 as tong_trich_hientai_crm,
    NULL AS th_ds_mt, NULL AS kh_total_mt, NULL AS th_sptt_mt_crm, NULL AS kpi_ds_sptt_mt_crm,
    NULL AS th_fmcg_toanquoc, NULL AS kpi_fmcg_toanquoc,
    0.0 as noxautrichlap,
    
    /* Lấy dữ kiện cần thiết cho Tiêu chí D (trước 2026) */
    tl.ty_le_trich_lap,

    0.0 as kh_total_ins_toanquoc, 0.0 as ds_ins_toanquoc, 0.0 as kh_total_pcl_toanquoc, 0.0 as ds_pcl_toanquoc,
    0.0 AS th_fmcg, 0.0 AS kpi_fmcg, 0.0 AS th_sptt_mt, 0.0 AS kpi_ds_sptt_mt,
    0.0 AS so_kh_vieng_tham, 0.0 AS kpi_vieng_tham_kh_mt
    
    FROM
    from_luong a
    LEFT JOIN danhsach_ns d on d.msnvcsmmoi = a.asm and DATE(a.nam, a.quy * 3, 1) = date(d.thang)
    LEFT JOIN `trich_lap_no_xau` tl 
        ON tl.macrm = a.asm
        AND tl.quy = a.quy
        AND tl.nam = a.nam
    WHERE 
        a.makenhkh = 'HCP' 
        AND a.asm IS NOT NULL /* Lọc chuẩn xác cho kênh HCP và phải có mã quản lý */
        and a.dtype in ('asm')
    GROUP BY 
        quy_filter, a.quy, a.nam, a.manv, a.makenhkh, tl.ty_le_trich_lap
)

, TP_SDS_NV as
(

SELECT 
a.*,

ROUND(SAFE_DIVIDE(doanhsochuavat, kh_total) * 100, 1) AS a_tieuchi,

CASE
    WHEN chuc_danh LIKE '%SDS%' then 0.0 --- SDS không có tiêu chí N
    WHEN a.nam >= 2025 THEN ROUND((th_kpi_sptt_t1+th_kpi_sptt_t2+th_kpi_sptt_t3)/3, 1)
END AS n_tieuchi,

ROUND(SAFE_DIVIDE(IFNULL(th_kh_pp, 0), IFNULL(sl_kh_mcp, 0)) * 100, 1) AS c_tieuchi,
-- Không có tiêu chí
0.0 AS f_tieuchi,
0.0 AS l_tieuchi,
0.0 AS v_tieuchi,
0.0 AS p_tieuchi,
0.0 AS d_tieuchi,
0.0 AS tong_no_xau,
0.0 AS ty_le_no_xau,
0.0 AS ke_hoach_no_xau,

FROM
data_nv_kpi a
WHERE makenhkh = 'TP'

)
,   TP_SDS_NV_CAP_DO AS (
SELECT
    *,
    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE
                WHEN a_tieuchi < 80 THEN 1
                WHEN a_tieuchi >= 80 AND a_tieuchi < 100 THEN 2
                WHEN a_tieuchi >= 100 AND a_tieuchi < 110 THEN 3
                WHEN a_tieuchi >= 110 AND a_tieuchi < 120 THEN 4
                WHEN a_tieuchi >= 120 THEN 5
                ELSE 1
            END
        ELSE 
            CASE
                WHEN a_tieuchi < 90 THEN 1
                WHEN a_tieuchi >= 90 AND a_tieuchi < 100 THEN 2
                WHEN a_tieuchi >= 100 AND a_tieuchi < 110 THEN 3
                WHEN a_tieuchi >= 110 AND a_tieuchi < 120 THEN 4
                WHEN a_tieuchi >= 120 THEN 5
                ELSE 1
            END
    END AS a_capdo,

    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE
                WHEN n_tieuchi < 80 THEN 1
                WHEN n_tieuchi >= 80 AND n_tieuchi < 100 THEN 2
                WHEN n_tieuchi >= 100 AND n_tieuchi < 110 THEN 3
                WHEN n_tieuchi >= 110 AND n_tieuchi < 120 THEN 4
                WHEN n_tieuchi >= 120 THEN 5
                ELSE 1
            END
        ELSE
            CASE
                WHEN n_tieuchi < 90 THEN 1
                WHEN n_tieuchi >= 90 AND n_tieuchi < 100 THEN 2
                WHEN n_tieuchi >= 100 AND n_tieuchi < 110 THEN 3
                WHEN n_tieuchi >= 110 AND n_tieuchi < 120 THEN 4
                WHEN n_tieuchi >= 120 THEN 5
                ELSE 1
            END
    END AS n_capdo,

    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE 
                WHEN sl_kh_mcp < 180 THEN -- Thang điểm tuyến nhỏ (< 180 KH)
                    CASE
                        WHEN c_tieuchi < 70 THEN 1
                        WHEN c_tieuchi >= 70 AND c_tieuchi < 75 THEN 2
                        WHEN c_tieuchi >= 75 AND c_tieuchi < 80 THEN 3
                        WHEN c_tieuchi >= 80 AND c_tieuchi < 85 THEN 4
                        WHEN c_tieuchi >= 85 THEN 5
                        ELSE 1
                    END
                ELSE -- Thang điểm tuyến lớn (>= 180 KH)
                    CASE
                        WHEN c_tieuchi < 65 THEN 1
                        WHEN c_tieuchi >= 65 AND c_tieuchi < 70 THEN 2
                        WHEN c_tieuchi >= 70 AND c_tieuchi < 75 THEN 3
                        WHEN c_tieuchi >= 75 AND c_tieuchi < 80 THEN 4
                        WHEN c_tieuchi >= 80 THEN 5
                        ELSE 1
                    END
            END
        ELSE
            CASE
                when c_tieuchi < 75 THEN 1
                when c_tieuchi >= 75 AND c_tieuchi < 80 THEN 2
                WHEN  c_tieuchi >= 80 AND c_tieuchi < 85 THEN 3
                WHEN  c_tieuchi >= 85 AND c_tieuchi < 90 THEN 4
                WHEN  c_tieuchi >= 90 THEN 5
            ELSE 1
            END
    END AS c_capdo,


    1 AS f_capdo,
    1 AS l_capdo,
    1 AS v_capdo,
    1 AS p_capdo,
    1 as d_capdo          
FROM
    TP_SDS_NV
)

,TP_SDS_NV_XEP_LOAI AS (
SELECT
    *,
CASE
    WHEN chuc_danh NOT LIKE '%SDS%' THEN ROUND(
        IFNULL(a_capdo, 0) * 0.8 +
        IFNULL(n_capdo, 0) * 0.1 +
        IFNULL(c_capdo, 0) * 0.1,
        1
    )

    WHEN chuc_danh LIKE '%SDS%' THEN ROUND(
        IFNULL(a_capdo, 0) * 0.8 +
        IFNULL(c_capdo, 0) * 0.2,
        1
    )

    ELSE NULL
END AS diem_xeploai_quy
FROM
    TP_SDS_NV_CAP_DO
)

,   TP_SDS_NV_RESULT AS (
SELECT
    *,
    staging_temp.fun_get_xeploai_abc(diem_xeploai_quy) AS xeploai_abc,
    staging_temp.fun_get_xeploai_phanloai(diem_xeploai_quy) as xeploai_phanloai,

    CASE
    -- CRS/CRSS - TP/HCP
    WHEN diem_xeploai_quy >= 3
         AND diem_xeploai_quy < 4
         AND chuc_danh NOT LIKE '%SDS%'
        THEN 5000000

    WHEN diem_xeploai_quy >= 4
         AND diem_xeploai_quy < 4.5
         AND chuc_danh NOT LIKE '%SDS%'
        THEN 8000000

    WHEN diem_xeploai_quy >= 4.5
         AND chuc_danh NOT LIKE '%SDS%'
        THEN 11000000

    -- SDS - TP
    WHEN diem_xeploai_quy >= 3
         AND diem_xeploai_quy < 4
         AND chuc_danh LIKE '%SDS%'
         THEN 2000000

    WHEN diem_xeploai_quy >= 4
         AND diem_xeploai_quy < 4.5
         AND chuc_danh LIKE '%SDS%'
         THEN 3000000

    WHEN diem_xeploai_quy >= 4.5
         AND chuc_danh LIKE '%SDS%'
         THEN 5000000
    ELSE 0
END AS thuong_quy

FROM
    TP_SDS_NV_XEP_LOAI
)

, TP_SUP as
(

SELECT 
a.*,

ROUND(SAFE_DIVIDE(doanhsochuavat, kh_total) * 100, 1) AS a_tieuchi,

CASE
    WHEN chuc_danh LIKE '%SDS%' then 0.0 --- SDS không có tiêu chí N
    WHEN a.nam >= 2025 THEN ROUND((th_kpi_sptt_t1+th_kpi_sptt_t2+th_kpi_sptt_t3)/3, 1)
END AS n_tieuchi,

ROUND(SAFE_DIVIDE(IFNULL(th_kh_pp, 0), IFNULL(sl_kh_mcp, 0)) * 100, 1) AS c_tieuchi,
-- Không có tiêu chí
0.0 AS f_tieuchi,
0.0 AS l_tieuchi,
0.0 AS v_tieuchi,
0.0 AS p_tieuchi,
0.0 AS d_tieuchi,
0.0 AS tong_no_xau,
0.0 AS ty_le_no_xau,
0.0 AS ke_hoach_no_xau,

FROM
data_sup_kpi a
WHERE makenhkh = 'TP'

)

-- select * from TP_SUP where manv = 'MR2465'


,   TP_SUP_CAP_DO AS (
SELECT
    *,
    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE
                WHEN a_tieuchi < 80 THEN 1
                WHEN a_tieuchi >= 80 AND a_tieuchi < 100 THEN 2
                WHEN a_tieuchi >= 100 AND a_tieuchi < 110 THEN 3
                WHEN a_tieuchi >= 110 AND a_tieuchi < 120 THEN 4
                WHEN a_tieuchi >= 120 THEN 5
                ELSE 1
            END
        ELSE
            CASE
                WHEN a_tieuchi < 90 THEN 1
                WHEN a_tieuchi >= 90 AND a_tieuchi < 100 THEN 2
                WHEN a_tieuchi >= 100 AND a_tieuchi < 110 THEN 3
                WHEN a_tieuchi >= 110 AND a_tieuchi < 120 THEN 4
                WHEN a_tieuchi >= 120 THEN 5
                ELSE 1
            END
    END AS a_capdo,

    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE
                WHEN n_tieuchi < 80 THEN 1
                WHEN n_tieuchi >= 80 AND n_tieuchi < 100 THEN 2
                WHEN n_tieuchi >= 100 AND n_tieuchi < 110 THEN 3
                WHEN n_tieuchi >= 110 AND n_tieuchi < 120 THEN 4
                WHEN n_tieuchi >= 120 THEN 5
                ELSE 1
            END
        ELSE
            CASE 
                WHEN n_tieuchi < 90 THEN 1
                WHEN n_tieuchi >= 90 AND n_tieuchi < 100 THEN 2
                WHEN n_tieuchi >= 100 AND n_tieuchi < 110 THEN 3
                WHEN n_tieuchi >= 110 AND n_tieuchi < 120 THEN 4
                WHEN n_tieuchi >= 120 THEN 5
                ELSE 1
            END
    END AS n_capdo,

    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE
                WHEN c_tieuchi < 70 THEN 1
                WHEN c_tieuchi >= 70 AND c_tieuchi < 75 THEN 2
                WHEN c_tieuchi >= 75 AND c_tieuchi < 80 THEN 3
                WHEN c_tieuchi >= 80 AND c_tieuchi < 85 THEN 4
                WHEN c_tieuchi >= 85 THEN 5
                ELSE 1
            END
        ELSE
            CASE
                when c_tieuchi < 75 THEN 1
                when c_tieuchi >= 75
                AND c_tieuchi < 80 THEN 2
                WHEN  c_tieuchi >= 80
                AND c_tieuchi < 85 THEN 3
                WHEN  c_tieuchi >= 85
                AND c_tieuchi < 90 THEN 4
                WHEN  c_tieuchi >= 90 THEN 5
                ELSE 1
            END
    END AS c_capdo,


    1 AS f_capdo,
    1 AS l_capdo,
    1 AS v_capdo,
    1 AS p_capdo,
    1 as d_capdo          
FROM
    TP_SUP
)

,TP_SUP_XEP_LOAI AS (
SELECT
    *,
    ROUND(
        IFNULL(a_capdo, 0) * 0.8 +
        IFNULL(c_capdo, 0) * 0.1 +
        IFNULL(n_capdo, 0) * 0.1,
        1
    ) AS diem_xeploai_quy
FROM
    TP_SUP_CAP_DO
)

, TP_SUP_RESULT AS (
SELECT
    *,
    staging_temp.fun_get_xeploai_abc(diem_xeploai_quy) AS xeploai_abc,
    staging_temp.fun_get_xeploai_phanloai(diem_xeploai_quy) as xeploai_phanloai,

    CASE
        WHEN diem_xeploai_quy >= 3
        AND diem_xeploai_quy < 4 THEN 8000000
        WHEN diem_xeploai_quy >= 4
        AND diem_xeploai_quy < 4.5 THEN 12000000
        WHEN diem_xeploai_quy >= 4.5 THEN 16000000
        ELSE 0
    END AS thuong_quy,

FROM
    TP_SUP_XEP_LOAI
)

-- SELECT * FROM TP_SUP_RESULT where manv = 'MR2465'

, MT_SUP_NV as
(

SELECT 
a.*,

/* TIÊU CHÍ A (Rule 1) 
    - Từ Q4/2025: Dùng th_ds_mt / kh_total_mt
    - Trước đó: Dùng công thức cũ (doanhsochuavat / kh_total)
*/
CASE 
    WHEN quy_filter >= '2025-10-01' THEN ROUND(SAFE_DIVIDE(th_ds_mt, kh_total_mt) * 100, 1)
    ELSE ROUND(SAFE_DIVIDE(doanhsochuavat, kh_total) * 100, 1)
END AS a_tieuchi,


/* TIÊU CHÍ N (Rule 2)
    - Từ Q4/2025: Dùng th_sptt_mt_crm / kpi_ds_sptt_mt_crm
    - Trước đó: Về 0.0 (theo logic cũ của bạn là cột này chỉ tính từ T10/2025)
*/
CASE 
    WHEN quy_filter >= '2025-10-01' THEN ROUND(SAFE_DIVIDE(th_sptt_mt_crm, kpi_ds_sptt_mt_crm) * 100, 1)
    ELSE 0.0 
END as n_tieuchi,

0.0 c_tieuchi,


/* TIÊU CHÍ F (Rule 3)
    - Từ Q4/2025: Dùng th_fmcg_toanquoc / kpi_fmcg_toanquoc
    - Trước đó: Về 0.0 (theo logic cũ của bạn là cột này chỉ tính từ T10/2025)
*/
CASE 
    WHEN quy_filter >= '2025-10-01' THEN ROUND(SAFE_DIVIDE(th_fmcg_toanquoc, kpi_fmcg_toanquoc) * 100, 1) 
    ELSE 0.0 
END AS f_tieuchi,

0.0 AS l_tieuchi,


ROUND(SAFE_DIVIDE(so_kh_vieng_tham, kpi_vieng_tham_kh_mt) * 100, 1) AS v_tieuchi,
0.0 AS p_tieuchi,
0.0 AS d_tieuchi,
0.0 AS tong_no_xau,
0.0 AS ty_le_no_xau,
0.0 AS ke_hoach_no_xau,

FROM
data_nv_kpi a
WHERE makenhkh = 'MT'

)

, MT_SUP_NV_CAP_DO AS (
SELECT
    *,
    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE
                WHEN a_tieuchi < 80 THEN 1
                WHEN a_tieuchi >= 80 AND a_tieuchi < 100 THEN 2
                WHEN a_tieuchi >= 100 AND a_tieuchi < 110 THEN 3
                WHEN a_tieuchi >= 110 AND a_tieuchi < 120 THEN 4
                WHEN a_tieuchi >= 120 THEN 5
                ELSE 1
            END
        ELSE
            CASE
               WHEN a_tieuchi < 90 THEN 1
              WHEN a_tieuchi >= 90 AND a_tieuchi < 100 THEN 2
              WHEN a_tieuchi >= 100 AND a_tieuchi < 110 THEN 3
              WHEN a_tieuchi >= 110 AND a_tieuchi < 120 THEN 4
              WHEN a_tieuchi >= 120 THEN 5
              ELSE 1
              END
    END AS a_capdo,

    CASE 
      WHEN quy_filter >= '2026-04-01' THEN
            CASE
                WHEN n_tieuchi < 80 THEN 1
                WHEN n_tieuchi >= 80 AND n_tieuchi < 100 THEN 2
                WHEN n_tieuchi >= 100 AND n_tieuchi < 110 THEN 3 
                WHEN n_tieuchi >= 110 AND n_tieuchi < 120 THEN 4
                WHEN n_tieuchi >= 120 THEN 5
                ELSE 1 END
      
      WHEN quy_filter >= '2025-10-01' THEN
        (CASE
            WHEN n_tieuchi < 90 THEN 1
            WHEN n_tieuchi >= 90 AND n_tieuchi < 100 THEN 2
            WHEN n_tieuchi >= 100 AND n_tieuchi < 110 THEN 3 
            WHEN n_tieuchi >= 110 AND n_tieuchi < 120 THEN 4
            WHEN n_tieuchi >= 120 THEN 5
            ELSE 1 END  )
        ELSE 1 END AS n_capdo,

    1 AS c_capdo,

    CASE 
      WHEN quy_filter >= '2026-04-01' THEN
            CASE
                WHEN f_tieuchi < 80 THEN 1
                WHEN f_tieuchi >= 80 AND f_tieuchi < 100 THEN 2
                WHEN f_tieuchi >= 100 AND f_tieuchi < 110 THEN 3 
                WHEN f_tieuchi >= 110 AND f_tieuchi < 120 THEN 4
                WHEN f_tieuchi >= 120 THEN 5
                ELSE 1 END
      
      WHEN quy_filter >= '2025-10-01' THEN
        (CASE
            WHEN f_tieuchi < 90 THEN 1
            WHEN f_tieuchi >= 90
            AND f_tieuchi < 100 THEN 2
            WHEN f_tieuchi >= 100
            AND f_tieuchi < 110 THEN 3 
            WHEN f_tieuchi >= 110
            AND f_tieuchi < 120 THEN 4
            WHEN f_tieuchi >= 120 THEN 5
            ELSE 1 END  )
        ELSE 1 END AS f_capdo,

    1 AS l_capdo,

    CASE  
        WHEN quy_filter >= '2025-10-01' THEN 0
        WHEN v_tieuchi < 85 THEN 1
        WHEN v_tieuchi >= 85 AND v_tieuchi < 95 THEN 2
        WHEN v_tieuchi >= 95 AND v_tieuchi < 110 THEN 3
        WHEN v_tieuchi >= 110 AND v_tieuchi < 120 THEN 4
        WHEN v_tieuchi >= 120 THEN 5
        ELSE 1
    END AS v_capdo,

    1 AS p_capdo,
    1 as d_capdo          
FROM
    MT_SUP_NV
)

,MT_SUP_NV_XEP_LOAI AS (
SELECT
    *,
    CASE 
        WHEN quy_filter >= '2025-10-01' 
        THEN round(
            IFNULL(a_capdo, 0) * 0.8
            + IFNULL( Case when UPPER(TRIM(chuc_danh)) like '%FMCG%' then f_capdo else n_capdo end, 0) * 0.2
            ,1)
        ELSE round(
            IFNULL(a_capdo, 0) * 0.8 + IFNULL(v_capdo, 0) * 0.2 ,
            1
            )  
    END AS diem_xeploai_quy
FROM
    MT_SUP_NV_CAP_DO
)

,   MT_SUP_NV_RESULT AS (
SELECT
    *,
    staging_temp.fun_get_xeploai_abc(diem_xeploai_quy) AS xeploai_abc,
    staging_temp.fun_get_xeploai_phanloai(diem_xeploai_quy) as xeploai_phanloai,

CASE
    WHEN diem_xeploai_quy >= 3
        AND diem_xeploai_quy < 4 
        AND chuc_danh like '%SUP%'
    THEN 6000000
    WHEN diem_xeploai_quy >= 4
        AND diem_xeploai_quy < 4.5 
        AND chuc_danh like '%SUP%'
    THEN 9000000
    WHEN diem_xeploai_quy >= 4.5 
        AND chuc_danh like '%SUP%'
    THEN 12000000

    WHEN diem_xeploai_quy >= 3
        AND diem_xeploai_quy < 4 
        AND chuc_danh like '%KAS%'
    THEN 4000000
    WHEN diem_xeploai_quy >= 4
        AND diem_xeploai_quy < 4.5 
        AND chuc_danh like '%KAS%'
    THEN 6000000
    WHEN diem_xeploai_quy >= 4.5 
        AND chuc_danh like '%KAS%'
    THEN 8000000
    ELSE 0
END AS thuong_quy

FROM
    MT_SUP_NV_XEP_LOAI
)

, MT_KAM as
(

SELECT 
a.*,

ROUND(SAFE_DIVIDE(doanhsochuavat, kh_total) * 100, 1) AS a_tieuchi,

CASE 
    WHEN quy_filter >= '2025-10-01' THEN ROUND(SAFE_DIVIDE(th_sptt_mt, kpi_ds_sptt_mt) * 100, 1)
    ELSE 0.0 END as n_tieuchi,
0.0 c_tieuchi,

round(safe_divide(th_fmcg, kpi_fmcg) * 100, 1) AS f_tieuchi, -- bao gồm cả tiêu chí N kênh MT, TỪ NGÀY 10/1 ĐÃ TÁCH LÀM 2 CỘT

ROUND(a.th_nhaphang_mt / a.kpi_nhaphang_mt * 100, 1) as l_tieuchi,

ROUND(SAFE_DIVIDE(so_kh_vieng_tham, kpi_vieng_tham_kh_mt) * 100, 1) AS v_tieuchi,
0.0 AS p_tieuchi,
0.0 AS d_tieuchi,
0.0 AS tong_no_xau,
0.0 AS ty_le_no_xau,
0.0 AS ke_hoach_no_xau,
FROM
data_sup_kpi a
WHERE makenhkh = 'MT' and manv in ('MR3066', 'MR0868')

)


, MT_KAM_CAP_DO AS (
SELECT
    *,
    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE
                WHEN a_tieuchi < 80 THEN 1
                WHEN a_tieuchi >= 80 AND a_tieuchi < 100 THEN 2
                WHEN a_tieuchi >= 100 AND a_tieuchi < 110 THEN 3
                WHEN a_tieuchi >= 110 AND a_tieuchi < 120 THEN 4
                WHEN a_tieuchi >= 120 THEN 5
                ELSE 1
            END
        ELSE
            CASE
                WHEN a_tieuchi < 90 THEN 1
                WHEN a_tieuchi >= 90 AND a_tieuchi < 100 THEN 2
                WHEN a_tieuchi >= 100 AND a_tieuchi < 110 THEN 3
                WHEN a_tieuchi >= 110 AND a_tieuchi < 120 THEN 4
                WHEN a_tieuchi >= 120 THEN 5
                ELSE 1 END
    END AS a_capdo,

    CASE 
      WHEN quy_filter >= '2026-04-01' THEN
            CASE
                WHEN n_tieuchi < 80 THEN 1
                WHEN n_tieuchi >= 80 AND n_tieuchi < 100 THEN 2
                WHEN n_tieuchi >= 100 AND n_tieuchi < 110 THEN 3
                WHEN n_tieuchi >= 110 AND n_tieuchi < 120 THEN 4
                WHEN n_tieuchi >= 120 THEN 5    
                ELSE 1 END
      WHEN quy_filter >= '2025-10-01' THEN
        (CASE
            WHEN n_tieuchi < 90 THEN 1
            WHEN n_tieuchi >= 90 AND n_tieuchi < 100 THEN 2
            WHEN n_tieuchi >= 100 AND n_tieuchi < 110 THEN 3
            WHEN n_tieuchi >= 110 AND n_tieuchi < 120 THEN 4
            WHEN n_tieuchi >= 120 THEN 5    
            ELSE 1 END)
        ELSE 1 END AS n_capdo,

    1 AS c_capdo,

    CASE 
      WHEN quy_filter >= '2026-04-01' THEN
            CASE
                WHEN f_tieuchi < 80 THEN 1
                WHEN f_tieuchi >= 80 AND f_tieuchi < 100 THEN 2
                WHEN f_tieuchi >= 100 AND f_tieuchi < 110 THEN 3
                WHEN f_tieuchi >= 110 AND f_tieuchi < 120 THEN 4
                WHEN f_tieuchi >= 120 THEN 5    
                ELSE 1 END

      WHEN quy_filter >= '2025-10-01' THEN
        (CASE
            WHEN f_tieuchi < 90 THEN 1
            WHEN f_tieuchi >= 90 AND f_tieuchi < 100 THEN 2
            WHEN f_tieuchi >= 100 AND f_tieuchi < 110 THEN 3
            WHEN f_tieuchi >= 110 AND f_tieuchi < 120 THEN 4
            WHEN f_tieuchi >= 120 THEN 5    
            ELSE 1 END)
        ELSE 1 END AS f_capdo,
    
    CASE
        WHEN l_tieuchi < 80 THEN 1
        WHEN l_tieuchi >= 80 AND l_tieuchi < 100 THEN 2
        WHEN l_tieuchi >= 100 AND l_tieuchi < 110 THEN 3
        WHEN l_tieuchi >= 110 AND l_tieuchi < 120 THEN 4
        WHEN l_tieuchi >= 120 THEN 5
        ELSE 1
    END AS l_capdo,

    CASE
        WHEN quy_filter >= '2025-10-01' THEN 0
        WHEN v_tieuchi < 85 THEN 1
        WHEN v_tieuchi >= 85
        AND v_tieuchi < 95 THEN 2
        WHEN v_tieuchi >= 95
        AND v_tieuchi < 110 THEN 3
        WHEN v_tieuchi >= 110
        AND v_tieuchi < 120 THEN 4
        WHEN v_tieuchi >= 120 THEN 5
        ELSE 1
    END AS v_capdo,

    1 AS p_capdo,
    1 as d_capdo          
FROM
    MT_KAM
)

,   MT_KAM_XEP_LOAI AS (
SELECT
    *,

    CASE
        WHEN quy_filter >= '2025-10-01' THEN
            round(
            IFNULL(a_capdo, 0) * 0.8 
            + IFNULL( Case when UPPER(TRIM(chuc_danh)) like '%FMCG%' then f_capdo else n_capdo end, 0) * 0.1
            + IFNULL(l_capdo, 0) * 0.1,
            1)

        --- trước ngày 10/01/2025
        ELSE round(IFNULL(a_capdo, 0) * 0.8 
            + IFNULL(f_capdo, 0) * 0.1 
            + IFNULL(l_capdo, 0) * 0.1,
            1) 
        END AS diem_xeploai_quy
FROM
    MT_KAM_CAP_DO
)

,   MT_KAM_RESULT AS (
SELECT
    *,
    staging_temp.fun_get_xeploai_abc(diem_xeploai_quy) AS xeploai_abc,
    staging_temp.fun_get_xeploai_phanloai(diem_xeploai_quy) as xeploai_phanloai,

    CASE
        WHEN diem_xeploai_quy >= 3
        AND diem_xeploai_quy < 4 THEN 8000000
        WHEN diem_xeploai_quy >= 4
        AND diem_xeploai_quy < 4.5 THEN 12000000
        WHEN diem_xeploai_quy >= 4.5 THEN 16000000
        ELSE 0
    END AS thuong_quy,

FROM
    MT_KAM_XEP_LOAI
)

,   HCP_NV as
(

SELECT 
a.*,

ROUND(SAFE_DIVIDE(doanhsochuavat, kh_total) * 100, 1) AS a_tieuchi,
0.0 AS n_tieuchi,
0.0 AS c_tieuchi,
0.0 AS f_tieuchi,
0.0 AS l_tieuchi,
0.0 AS v_tieuchi,
round(safe_divide(ds_pcl_clc, kh_total_pcl_clc) * 100, 1) AS p_tieuchi,
0.0 AS d_tieuchi,
0.0 AS tong_no_xau,
0.0 AS ty_le_no_xau,
0.0 AS ke_hoach_no_xau,

FROM
data_nv_kpi a
WHERE makenhkh = 'HCP'

)

,   HCP_NV_CAP_DO AS (
SELECT
    *,
    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE
            WHEN a_tieuchi < 80 THEN 1
            WHEN a_tieuchi >= 80  AND a_tieuchi < 100 THEN 2
            WHEN a_tieuchi >= 100 AND a_tieuchi < 110 THEN 3
            WHEN a_tieuchi >= 110 AND a_tieuchi < 120 THEN 4
            WHEN a_tieuchi >= 120 THEN 5
            ELSE 1
            END
        ELSE
            CASE
            WHEN a_tieuchi < 90 THEN 1
            WHEN a_tieuchi >= 90 AND a_tieuchi < 100 THEN 2
            WHEN a_tieuchi >= 100 AND a_tieuchi < 110 THEN 3
            WHEN a_tieuchi >= 110 AND a_tieuchi < 120 THEN 4
            WHEN a_tieuchi >= 120 THEN 5
            ELSE 1
            END
    END AS a_capdo,

    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE
            WHEN n_tieuchi < 80 THEN 1
            WHEN n_tieuchi >= 80  AND n_tieuchi < 100 THEN 2
            WHEN n_tieuchi >= 100 AND n_tieuchi < 110 THEN 3
            WHEN n_tieuchi >= 110 AND n_tieuchi < 120 THEN 4
            WHEN n_tieuchi >= 120 THEN 5
            ELSE 1
            END
        ELSE 1
    END AS n_capdo,

    1 AS c_capdo,
    1 AS f_capdo,
    1 AS l_capdo,
    1 AS v_capdo,
    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE
            WHEN p_tieuchi < 80 THEN 1
            WHEN p_tieuchi >= 80  AND p_tieuchi < 100 THEN 2
            WHEN p_tieuchi >= 100 AND p_tieuchi < 110 THEN 3
            WHEN p_tieuchi >= 110 AND p_tieuchi < 120 THEN 4
            WHEN p_tieuchi >= 120 THEN 5
            ELSE 1
            END
        ELSE
            CASE
            WHEN p_tieuchi < 90 THEN 1
            WHEN p_tieuchi >= 90
            AND p_tieuchi < 100 THEN 2
            WHEN p_tieuchi >= 100
            AND p_tieuchi < 110 THEN 3
            WHEN p_tieuchi >= 110
            AND p_tieuchi < 120 THEN 4
            WHEN p_tieuchi >= 120 THEN 5
            ELSE 1
            END
    END AS p_capdo,
    1 as d_capdo          
FROM
    HCP_NV
)

,   HCP_NV_XEP_LOAI AS (
SELECT
    *,
    round(
        IFNULL(a_capdo, 0) * 0.8  + IFNULL(p_capdo, 0) * 0.2,
    1
    ) as diem_xeploai_quy
FROM
    HCP_NV_CAP_DO
)

,   HCP_NV_RESULT AS (
SELECT
    *,
    staging_temp.fun_get_xeploai_abc(diem_xeploai_quy) AS xeploai_abc,
    staging_temp.fun_get_xeploai_phanloai(diem_xeploai_quy) as xeploai_phanloai,

    CASE
    -- CRS/CRSS - TP/HCP
    WHEN diem_xeploai_quy >= 3
    AND diem_xeploai_quy < 4
    THEN 5000000

    WHEN diem_xeploai_quy >= 4
    AND diem_xeploai_quy < 4.5
    THEN 8000000

    WHEN diem_xeploai_quy >= 4.5
    THEN 11000000
    ELSE 0
END AS thuong_quy

FROM
    HCP_NV_XEP_LOAI
)


,   HCP_CRM as
(
SELECT 
a.*,

ROUND(SAFE_DIVIDE(doanhsochuavat, kh_total) * 100, 1) AS a_tieuchi,
0.0 AS n_tieuchi,
0.0 AS c_tieuchi,
0.0 AS f_tieuchi,
0.0 AS l_tieuchi,
0.0 AS v_tieuchi,
0.0 as p_tieuchi,
/* Lấy tiêu chí D mới từ 2026, các năm trước giữ nguyên tỷ lệ trích lập */
CASE 
        WHEN a.quy_filter >= '2026-01-01' THEN 
            ROUND(SAFE_DIVIDE(
                (SAFE_DIVIDE(IFNULL(d.tong_no_xau, 0.0), a.doanhsochuavat) * 100), 
                IFNULL(d.ke_hoach_no_xau, 0.0)
            ) * 100, 1)
        ELSE a.ty_le_trich_lap 
    END AS d_tieuchi,

CASE WHEN a.quy_filter >= '2026-01-01' THEN IFNULL(d.tong_no_xau, 0.0) ELSE 0.0 END AS tong_no_xau,

CASE WHEN a.quy_filter >= '2026-01-01' THEN 
    SAFE_DIVIDE(IFNULL(d.tong_no_xau, 0.0), a.doanhsochuavat) * 100 
    ELSE 0.0 END AS ty_le_no_xau,

CASE WHEN a.quy_filter >= '2026-01-01' THEN IFNULL(d.ke_hoach_no_xau, 0.0) ELSE 0.0 END AS ke_hoach_no_xau,

FROM
data_sup_kpi a
LEFT JOIN tieu_chi_no_xau_crm d ON a.manv = d.ma_nv AND a.quy = d.quy AND a.nam = d.nam
WHERE makenhkh = 'HCP' and manv not in ('MR1137','MR0123','MR1681','MR0538','MR1650')
)


,   HCP_CRM_CAP_DO AS (
SELECT
    *,
    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE
            WHEN a_tieuchi < 80 THEN 1
            WHEN a_tieuchi >= 80  AND a_tieuchi < 100 THEN 2
            WHEN a_tieuchi >= 100 AND a_tieuchi < 110 THEN 3
            WHEN a_tieuchi >= 110 AND a_tieuchi < 120 THEN 4
            WHEN a_tieuchi >= 120 THEN 5
            ELSE 1
            END
        ELSE
            CASE
            WHEN a_tieuchi < 90 THEN 1
            WHEN a_tieuchi >= 90 AND a_tieuchi < 100 THEN 2
            WHEN a_tieuchi >= 100 AND a_tieuchi < 110 THEN 3
            WHEN a_tieuchi >= 110 AND a_tieuchi < 120 THEN 4
            WHEN a_tieuchi >= 120 THEN 5
            ELSE 1
            END
    END AS a_capdo,

    1 as n_capdo,

    1 as c_capdo,

    1 AS f_capdo,
    1 AS l_capdo,
    1 AS v_capdo,
    1 AS p_capdo,

    CASE
        WHEN d_tieuchi <= 95 THEN 5
        WHEN d_tieuchi > 95 AND d_tieuchi <= 100 THEN 4
        WHEN d_tieuchi > 100 AND d_tieuchi <= 110 THEN 3
        WHEN d_tieuchi > 110 AND d_tieuchi <= 120 THEN 2
        WHEN d_tieuchi > 120 THEN 1
        ELSE 1
    END AS d_capdo,     
FROM
    HCP_CRM
)

,   HCP_CRM_XEP_LOAI AS (
SELECT
    *,
    round(
    IFNULL(a_capdo, 0) * 0.8 + IFNULL(d_capdo, 0) * 0.2 ,
    1
    )
    AS diem_xeploai_quy
FROM
    HCP_CRM_CAP_DO
)

,   HCP_CRM_RESULT AS (
SELECT
    *,
    staging_temp.fun_get_xeploai_abc(diem_xeploai_quy) AS xeploai_abc,
    staging_temp.fun_get_xeploai_phanloai(diem_xeploai_quy) as xeploai_phanloai,

    CASE
        WHEN diem_xeploai_quy >= 3
        AND diem_xeploai_quy < 4 THEN 8000000
        WHEN diem_xeploai_quy >= 4
        AND diem_xeploai_quy < 4.5 THEN 12000000
        WHEN diem_xeploai_quy >= 4.5 THEN 16000000
        ELSE 0
    END AS thuong_quy,

FROM
    HCP_CRM_XEP_LOAI
)


,   HCP_NCRM as
(
/* TRƯỚC 2026: Dùng bảng data_sup_kpi với 3 mã nhân viên cũ */
SELECT 
a.*,

CASE
    WHEN manv = 'MR1681' THEN ROUND(SAFE_DIVIDE(doanhsochuavat, kh_total) * 100, 1)
    WHEN manv = 'MR1137' THEN ROUND(SAFE_DIVIDE(ds_ins_toanquoc, kh_total_ins_toanquoc) * 100, 1)
    WHEN manv = 'MR0123' THEN ROUND(SAFE_DIVIDE(ds_pcl_toanquoc, kh_total_pcl_toanquoc) * 100, 1)

END AS a_tieuchi,

0.0 AS n_tieuchi,
0.0 AS c_tieuchi,
0.0 AS f_tieuchi,
0.0 AS l_tieuchi,
0.0 AS v_tieuchi,
0.0 as p_tieuchi,
ty_le_trich_lap AS d_tieuchi,
0.0 AS tong_no_xau,
0.0 AS ty_le_no_xau,
0.0 AS ke_hoach_no_xau,

FROM
data_sup_kpi a
WHERE 
        a.makenhkh = 'HCP' 
        AND a.quy_filter < '2026-01-01'
        AND a.manv in ('MR1137','MR0123','MR1681')

/* TỪ 2026 TRỞ ĐI: Lấy data cuộn từ CTE data_ncrm_kpi */
UNION ALL
SELECT 
        b.*,
        ROUND(SAFE_DIVIDE(b.doanhsochuavat, b.kh_total) * 100, 1) AS a_tieuchi,
        0.0 AS n_tieuchi, 
        0.0 AS c_tieuchi,
        0.0 AS f_tieuchi,
        0.0 AS l_tieuchi,
        0.0 AS v_tieuchi,
        0.0 as p_tieuchi,
        ROUND(SAFE_DIVIDE(
            (SAFE_DIVIDE(IFNULL(d.tong_no_xau, 0.0), b.doanhsochuavat) * 100 ), 
            IFNULL(d.ke_hoach_no_xau, 0.0)
        ) * 100, 1) AS d_tieuchi,
        IFNULL(d.tong_no_xau, 0.0) AS tong_no_xau,

        /* TỶ LỆ NỢ XẤU = Nợ xấu / Doanh số thực hiện */
        SAFE_DIVIDE(IFNULL(d.tong_no_xau, 0.0), b.doanhsochuavat) * 100 AS ty_le_no_xau,

        IFNULL(d.ke_hoach_no_xau, 0.0) AS ke_hoach_no_xau,
    FROM
        data_ncrm_kpi b
    LEFT JOIN tieu_chi_no_xau_ncrm d 
        ON b.manv = d.ma_nv AND b.quy = d.quy AND b.nam = d.nam
    WHERE 
        b.makenhkh = 'HCP' 
        AND b.quy_filter >= '2026-01-01'
)


,   HCP_NCRM_CAP_DO AS (
SELECT
    *,
    CASE
        WHEN quy_filter >= '2026-04-01' THEN
            CASE
            WHEN a_tieuchi < 80 THEN 1
            WHEN a_tieuchi >= 80  AND a_tieuchi < 100 THEN 2
            WHEN a_tieuchi >= 100 AND a_tieuchi < 105 THEN 3
            WHEN a_tieuchi >= 105 AND a_tieuchi < 110 THEN 4
            WHEN a_tieuchi >= 110 THEN 5
            ELSE 1
            END    
        ELSE
            CASE  
            WHEN a_tieuchi < 90 THEN 1
            WHEN a_tieuchi >= 90 AND a_tieuchi < 100 THEN 2
            WHEN a_tieuchi >= 100 AND a_tieuchi < 105 THEN 3
            WHEN a_tieuchi >= 105 AND a_tieuchi < 115 THEN 4
            WHEN a_tieuchi >= 115 THEN 5
            ELSE 1 END
    END AS a_capdo,

    1 as n_capdo,

    1 as c_capdo,

    1 AS f_capdo,
    1 AS l_capdo,
    1 AS v_capdo,
    1 AS p_capdo,

    CASE
        WHEN d_tieuchi <= 95 THEN 5
        WHEN d_tieuchi > 95 AND d_tieuchi <= 100 THEN 4
        WHEN d_tieuchi > 100 AND d_tieuchi <= 110 THEN 3
        WHEN d_tieuchi > 110 AND d_tieuchi <= 120 THEN 2
        WHEN d_tieuchi > 120 THEN 1
        ELSE 1
    END AS d_capdo,     
FROM
    HCP_NCRM
)

,   HCP_NCRM_XEP_LOAI AS (
SELECT
    *,
    round(
    IFNULL(a_capdo, 0) * 0.8 + IFNULL(d_capdo, 0) * 0.2 ,
    1
    )
    AS diem_xeploai_quy
FROM
    HCP_NCRM_CAP_DO
)

,   HCP_NCRM_RESULT AS (
SELECT
    *,
    staging_temp.fun_get_xeploai_abc(diem_xeploai_quy) AS xeploai_abc,
    staging_temp.fun_get_xeploai_phanloai(diem_xeploai_quy) as xeploai_phanloai,

    CASE
        WHEN diem_xeploai_quy >= 3
        AND diem_xeploai_quy < 4 THEN 15000000
        WHEN diem_xeploai_quy >= 4
        AND diem_xeploai_quy < 4.5 THEN 20000000
        WHEN diem_xeploai_quy >= 4.5 THEN 25000000
        ELSE 0
    END AS thuong_quy,

FROM
    HCP_NCRM_XEP_LOAI
)

,   FINAL as
(

SELECT * FROM TP_SDS_NV_RESULT
UNION ALL
SELECT * FROM TP_SUP_RESULT
UNION ALL
SELECT * FROM MT_SUP_NV_RESULT
UNION ALL
SELECT * FROM MT_KAM_RESULT
UNION ALL
SELECT * FROM HCP_NV_RESULT
UNION ALL
SELECT * FROM HCP_CRM_RESULT
UNION ALL
SELECT * FROM HCP_NCRM_RESULT
)

SELECT 
a.* EXCEPT(
        doanhsochuavat, 
        kh_total, 
        th_sptt_mt,    
        kpi_ds_sptt_mt,
        kpi_fmcg,
        th_fmcg
),
/* rule1
cột doanhsochuavat thay bằng cột với điều kiện chuc_vu CRM lấy doanhsochuavat, chuc vu CRS nếu trước ngày 1/10/2025 thì lấy doanhsochuavat, sau ngày 1/10/2025 lấy th_ds_mt chỉ riêng kênh MT
*/
    -- <<<< ADD BLOCK LOGIC RULE 1 MỚI
    CASE 
        WHEN chuc_vu = 'CRM' AND a.makenhkh = 'MT' THEN doanhsochuavat
        WHEN chuc_vu = 'CRS' AND a.makenhkh = 'MT' AND quy_filter >= '2025-10-01' THEN th_ds_mt
        ELSE doanhsochuavat -- Bao gồm CRS trước 1/10/2025 và các chức vụ khác
    END AS doanhsochuavat,
    -- >>>> END ADD

/* rule2
cột kh_total thay bằng cột với điều kiện chuc_vu CRM lấy kh_total, chuc vu CRS nếu trước ngày 1/10/2025 thì lấy kh_total, sau ngày 1/10/2025 lấy kh_total_mt
*/
    -- <<<< ADD BLOCK LOGIC RULE 2 MỚI
    CASE 
        WHEN chuc_vu = 'CRM' AND a.makenhkh = 'MT' THEN kh_total
        WHEN chuc_vu = 'CRS' AND a.makenhkh = 'MT' AND quy_filter >= '2025-10-01' THEN kh_total_mt
        ELSE kh_total -- Bao gồm CRS trước 1/10/2025 và các chức vụ khác
    END AS kh_total,

CASE 
        WHEN chuc_vu = 'CRM' AND a.makenhkh = 'MT' THEN th_sptt_mt
        WHEN chuc_vu = 'CRS' AND a.makenhkh = 'MT' AND quy_filter >= '2025-10-01' THEN th_sptt_mt_crm
        ELSE th_sptt_mt -- Lấy cột cũ (th_sptt_mt) cho dữ liệu lịch sử
    END AS th_sptt_mt,

    -- Cột: KPI SPTT MT CRM
    CASE 
        WHEN chuc_vu = 'CRM' AND a.makenhkh = 'MT' THEN kpi_ds_sptt_mt
        WHEN chuc_vu = 'CRS' AND a.makenhkh = 'MT' AND quy_filter >= '2025-10-01' THEN kpi_ds_sptt_mt_crm
        ELSE kpi_ds_sptt_mt -- Lấy cột cũ (kpi_ds_sptt_mt) cho dữ liệu lịch sử
    END AS kpi_ds_sptt_mt,

CASE 
        WHEN chuc_vu = 'CRM' AND a.makenhkh = 'MT' THEN kpi_fmcg_toanquoc
        WHEN chuc_vu = 'CRS' AND a.makenhkh = 'MT' AND quy_filter >= '2025-10-01' THEN kpi_fmcg_toanquoc
        ELSE kpi_fmcg 
    END AS kpi_fmcg,

CASE 
        WHEN chuc_vu = 'CRM' AND a.makenhkh = 'MT' THEN th_fmcg_toanquoc
        WHEN chuc_vu = 'CRS' AND a.makenhkh = 'MT' AND quy_filter >= '2025-10-01' THEN th_fmcg_toanquoc
        ELSE th_fmcg 
    END AS th_fmcg,

m.tencvbh,
m.supid,
m.tenquanlytt,
m.asm,
m.tenquanlykhuvuc,
m.rsmid as ncxm,
m.tenquanlyvung,

--field bo
0.0 AS kh_slpp,
0.0 AS th_ds_sptt,
0.0 AS th_ds_sptt_t11,
0.0 AS kpi_ds_sptt_t11,
0.0 AS th_kpi_sptt_t11,
0.0 AS th_ds_sptt_t12,
0.0 AS kpi_ds_sptt_t12,
0.0 AS th_kpi_sptt_t12,
0.0 AS h_tieuchi,
0 AS th_slpp,
0 AS sl_kh_mm_si,
0 AS kpi_sl_kh_mm_si,
0 AS h_capdo,
0.0 as th_sptt,
0.0 as kpi_ds_sptt,



FROM FINAL a
LEFT JOIN mapping_nv_ql m on a.manv = m.manv and a.quy = m.quy and a.nam = m.nam and a.makenhkh = m.makenhkh
--Where a.manv in ('MR3168') and a.quy_filter >= '2025-10-01'
);

Create or replace table `warehouse.f_thuong_quy_result`
copy `f_thuong_quy_result`;

END;