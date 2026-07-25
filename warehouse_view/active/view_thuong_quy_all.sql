CREATE VIEW `spatial-vision-343005.warehouse.view_thuong_quy_all`
AS WITH 
danhsach_ns AS (
    SELECT
        TRIM(UPPER(phaply)) AS phaply,
        msnvcsmmoi,
        chucdanhengtitlesum,
        ngaykyhdldchinhthuc,
        ngayvaolamonboarddate,
        loaihdld,
        diabanlamviec,
        EXTRACT(QUARTER FROM thang) AS quy,
        EXTRACT(YEAR FROM thang) AS nam
    FROM
        `staging.d_hr_dsns_bytime`
    WHERE
        CAST(DATE(thang) AS STRING FORMAT 'MMDD') IN ('0301', '0601', '0901', '1201')
)

,   tile_checkin AS (
SELECT
    slsperid,
    DATE(DATE_TRUNC(visitdate, MONTH)) AS thang,

    CASE
        WHEN MOD(EXTRACT(MONTH FROM DATE_TRUNC(visitdate, MONTH)) - 1, 3) = 0 THEN 1
        WHEN MOD(EXTRACT(MONTH FROM DATE_TRUNC(visitdate, MONTH)) - 1, 3) = 1 THEN 2
        WHEN MOD(EXTRACT(MONTH FROM DATE_TRUNC(visitdate, MONTH)) - 1, 3) = 2 THEN 3
    END AS stt_thang_trong_quy,

    EXTRACT(QUARTER FROM visitdate) AS quy,
    EXTRACT(YEAR FROM visitdate) AS nam,
    COUNT(DISTINCT ma_kh_can_vieng_tham) AS sl_quydinh,
    COUNT(DISTINCT ma_kh_dat) AS sl_kh_checkin,
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT ma_kh_dat), COUNT(DISTINCT ma_kh_can_vieng_tham)) * 100, 1) AS tiendo_viengtham,
    COUNT(ma_call_kh) AS sl_call_cancheckin,
    COUNT(DISTINCT ma_call_kh_dat) AS soluong_checkin_thucte,
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT ma_call_kh_dat), COUNT(ma_kh_can_vieng_tham)) * 100, 1) AS tyle_call_checkin
FROM
    `warehouse.view_f_data_checkin_pbh_v3`
WHERE
    DATE(DATE_TRUNC(visitdate, MONTH)) >= '2025-01-01'
GROUP BY ALL
)

,   result AS (
    SELECT
    a.*,
    b.diabanlamviec,
    b.phaply,
    
    COALESCE(UPPER(TRIM(b.loaihdld)), 'NGHỈ VIỆC') AS loaihdld,
    DATE(b.ngaykyhdldchinhthuc) AS ngaykyhdldchinhthuc,
    DATE(b.ngayvaolamonboarddate) AS ngayvaolamvc,

    -- Điều kiện 1: SL khách hàng min MCP
    CASE
    
    -- Điều kiện đặc biệt duyệt email
    WHEN chuc_vu IN ('CRM','N.CRM') OR
        (a.quy = 1 AND a.nam = 2025 AND a.manv = 'MR2694') OR
        (a.quy = 3 AND a.nam = 2025 AND a.manv = 'MR3161')
        THEN 'ĐK1: SL Khách hàng MCP - Đạt'

    -- SDS TP
    WHEN makenhkh = 'TP' AND chuc_danh LIKE '%SDS%' AND a.quy_filter >= '2026-04-01' AND tong_sl_pp_mcp < 90
        THEN 'ĐK1: SL Khách hàng MCP - Không đạt (Không đủ SL KH: ' || tong_sl_pp_mcp || ' (SDS >=90))'

    WHEN makenhkh = 'TP' AND chuc_danh LIKE '%SDS%' AND a.quy_filter < '2026-04-01' AND tong_sl_pp_mcp < 100
        THEN 'ĐK1: SL Khách hàng MCP - Không đạt (Không đủ SL KH: ' || tong_sl_pp_mcp || ' (SDS >=100))'
    -- CRS TP
    WHEN makenhkh = 'TP' AND chuc_vu IN ('CRS') AND chuc_danh NOT LIKE '%SDS%' AND tong_sl_pp_mcp < 150
        THEN 'ĐK1: SL Khách hàng MCP - Không đạt (Không đủ SL KH: ' || tong_sl_pp_mcp || ' (CRS >=150))'
    -- CRS HCP
    WHEN makenhkh = 'HCP' AND tong_sl_pp_mcp < 15
        THEN 'ĐK1: SL Khách hàng MCP - Không đạt (Không đủ SL KH: ' || tong_sl_pp_mcp || ' (PCL >=15))'
    ELSE 'ĐK1: SL Khách hàng MCP - Đạt'
    -- Còn lại thì đạt
    END AS is_mcp_checkin,

    -- Điều kiện 2: Tỉ lệ checkin
    CASE
    WHEN chuc_vu IN ('CRM','N.CRM') THEN 'ĐK2: Tỉ lệ checkin - Đạt'

    WHEN makenhkh = 'TP' AND chuc_vu IN ('CRS') AND
            (e.tyle_call_checkin < 90 OR e1.tyle_call_checkin < 90 OR e2.tyle_call_checkin < 90)
        THEN 'ĐK2: Tỉ lệ checkin - Không đạt (tỉ lệ Call checkin: ' ||
            'T' || EXTRACT(MONTH FROM e2.thang) || ': ' || e2.tyle_call_checkin || '%, ' ||
            'T' || EXTRACT(MONTH FROM e1.thang) || ': ' || e1.tyle_call_checkin || '%, ' ||
            'T' || EXTRACT(MONTH FROM e.thang)  || ': ' || e.tyle_call_checkin  || '%)'

    WHEN makenhkh = 'HCP' AND 
            (e.tiendo_viengtham < 80 OR e1.tiendo_viengtham < 80 OR e2.tiendo_viengtham < 80)
        THEN 'ĐK2: Tỉ lệ checkin - Không đạt (viếng thăm PCL: ' ||
            'T' || EXTRACT(MONTH FROM e2.thang) || ': ' || e2.tiendo_viengtham || '%, ' ||
            'T' || EXTRACT(MONTH FROM e1.thang) || ': ' || e1.tiendo_viengtham || '%, ' ||
            'T' || EXTRACT(MONTH FROM e.thang)  || ': ' || e.tiendo_viengtham  || '%)'

    WHEN makenhkh = 'MT' AND chuc_vu IN ('CRS') AND
            (e.tyle_call_checkin < 90 OR e1.tyle_call_checkin < 90 OR e2.tyle_call_checkin < 90)
            THEN 'ĐK2: Tỉ lệ checkin - Không đạt (tỉ lệ Call checkin MT: ' ||
                'T' || EXTRACT(MONTH FROM e2.thang) || ': ' || IFNULL(CAST(e2.tyle_call_checkin AS STRING), '0') || '%, ' ||
                'T' || EXTRACT(MONTH FROM e1.thang) || ': ' || IFNULL(CAST(e1.tyle_call_checkin AS STRING), '0') || '%, ' ||
                'T' || EXTRACT(MONTH FROM e.thang) || ': ' || IFNULL(CAST(e.tyle_call_checkin AS STRING), '0') || '%)'
    ELSE 'ĐK2: Tỉ lệ checkin - Đạt'
    END AS is_tile_checkin,

    -- Điều kiện 3: Đủ công quý, không điều chuyển, không thai sản
    CASE 
        WHEN chuc_vu IN ('CRM', 'N.CRM') THEN 
            'ĐK3: Đủ công quý, không điều chuyển, không thai sản - Đạt'

        WHEN c.invalid_note IS NOT NULL THEN 
            'ĐK3: Đủ công quý, không điều chuyển, không thai sản - Không đạt' || 
            ' (' || c.invalid_note || ')'

        ELSE 'ĐK3: Đủ công quý, không điều chuyển, không thai sản - Đạt'
    END AS is_thai_san,

    CASE 
        WHEN chuc_vu IN ('CRM', 'N.CRM') THEN 
            'ĐK4: Điểm CMSP - Đạt'

        WHEN a.chuc_vu = 'CRS'
             AND d.macrs IS NOT NULL 
             AND d.diemcmsp < 7 
             AND makenhkh IN ('HCP', 'TP','MT') THEN
            'ĐK4: Điểm CMSP - Không đạt' || 
            ' (Điểm CMSP <7: ' || ROUND(d.diemcmsp, 1) || ')'

        WHEN a.chuc_vu = 'CRS'
             AND d.macrs IS NULL 
             AND makenhkh IN ('HCP', 'TP', 'MT') THEN 
            'ĐK4: Điểm CMSP - Không đạt (Không kiểm tra CMSP)'

        ELSE 
            'ĐK4: Điểm CMSP - Đạt'
    END AS is_diem_cmsp,

    c.invalid_note AS ghichu_lydo_tinhthuong_quy,
    d.diemcmsp AS cham_diem_cmsp,

    e.tyle_call_checkin,
    e.tiendo_viengtham

FROM `warehouse.f_thuong_quy_result` a

LEFT JOIN danhsach_ns b 
    ON a.manv = b.msnvcsmmoi
    AND a.quy = b.quy
    AND b.nam = a.nam

LEFT JOIN `staging.d_quarter_eligable` c 
    ON a.manv = c.manv
    AND RIGHT(c.quarter, 5) = CONCAT(a.quy, a.nam)

LEFT JOIN `staging.d_manual_diem_cmsp_thuongquy` d 
    ON d.macrs = a.manv
    AND a.quy = d.quy
    AND a.nam = d.nam

LEFT JOIN tile_checkin e
    ON e.quy = a.quy
    AND e.nam = a.nam
    AND e.slsperid = a.manv
    AND e.stt_thang_trong_quy = 1

LEFT JOIN tile_checkin e1
    ON e1.quy = a.quy
    AND e1.nam = a.nam
    AND e1.slsperid = a.manv
    AND e1.stt_thang_trong_quy = 2

LEFT JOIN tile_checkin e2
    ON e2.quy = a.quy
    AND e2.nam = a.nam
    AND e2.slsperid = a.manv
    AND e2.stt_thang_trong_quy = 3

)


SELECT
    * EXCEPT (thuong_quy),

    is_mcp_checkin 
    || ' , ' || IFNULL(is_tile_checkin, 'ĐK2: Tỉ lệ checkin - Không đạt(Không có kế hoạch viếng thăm)')
    || ' , ' || is_thai_san
    || ' , ' || is_diem_cmsp AS is_noi_dat_tinhthuong_quy,


    CASE 
        WHEN manv LIKE '%KN%' THEN 'Không đạt'
        WHEN UPPER(loaihdld) IN ('HỌC VIỆC','THỬ VIỆC','NGHỈ VIỆC') THEN 'Không đạt'
        WHEN is_mcp_checkin like '%Không đạt%' THEN 'Không đạt'
        WHEN is_tile_checkin like '%Không đạt%' THEN 'Không đạt'
        WHEN is_thai_san like '%Không đạt%' THEN 'Không đạt'
        WHEN is_diem_cmsp like '%Không đạt%' THEN 'Không đạt'
        ELSE 'Đạt'
    END AS is_dat_tinhthuong_quy,


    CASE 
        WHEN manv LIKE '%KN%' THEN 0
        WHEN UPPER(loaihdld) IN ('HỌC VIỆC','THỬ VIỆC','NGHỈ VIỆC') THEN 0
        WHEN is_mcp_checkin like '%Không đạt%' THEN 0
        WHEN is_tile_checkin like '%Không đạt%' THEN 0
        WHEN is_thai_san like '%Không đạt%' THEN 0
        WHEN is_diem_cmsp like '%Không đạt%' THEN 0
        ELSE thuong_quy
    END AS thuong_quy,

    CURRENT_DATETIME("Asia/Bangkok") as inserted_at

FROM
    result

--where quy_filter = '2026-03-01'--and manv = 'MR1351'



;