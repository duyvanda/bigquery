CREATE VIEW `spatial-vision-343005.warehouse.f_view_tracking_kpi_hcp_2025`
AS WITH ds_kh_tt AS (
    SELECT 
        a.ma_hco_chung AS mahcochung,
        a.kenh,
        hr1.msnvcsmmoi AS ma_crm,
        a.crm,
        a.ncrm,
        hr2.msnvcsmmoi AS ma_ncrm,
        a.q1,
        a.q2,
        a.q3,
        a.q4
    FROM `staging.d_danh_sach_tan_tam` a
    
    LEFT JOIN `staging.d_hr_dsns` hr1 
        ON LOWER(TRIM(a.crm)) = LOWER(TRIM(hr1.hovatenfullname)) 
        AND hr1.phongdeptsummary = 'HCP'

    LEFT JOIN `staging.d_hr_dsns` hr2 
        ON LOWER(TRIM(a.ncrm)) = LOWER(TRIM(hr2.hovatenfullname)) 
        AND hr2.phongdeptsummary = 'HCP'

    QUALIFY row_number() OVER (PARTITION BY a.ma_hco_chung, a.kenh, hr1.msnvcsmmoi ORDER BY a.crs DESC) = 1
),

/* ------------------------------------------------------------------
   CTE unpivot dữ liệu để tách 1 KH thành nhiều dòng theo Quý
   ------------------------------------------------------------------ */
/* ------------------------------------------------------------------
   [ĐÃ SỬA LỖI NHÂN BẢN SỐ] CTE unpivot dữ liệu để tách 1 KH thành nhiều dòng
   ------------------------------------------------------------------ */
ds_kh_tt_unpivoted AS (
    SELECT 
        a.mahcochung,
        a.kenh,
        a.ma_crm,
        a.crm,
        a.ncrm,
        a.ma_ncrm,
        CASE unnest_quy.quy
            WHEN 'q1' THEN DATE '2026-01-01'
            WHEN 'q2' THEN DATE '2026-04-01'
            WHEN 'q3' THEN DATE '2026-07-01'
            WHEN 'q4' THEN DATE '2026-10-01'
        END AS thang_quy,
        
        -- CÁCH GIẢI QUYẾT: Chỉ map số tiền vào đúng cột quý của dòng đó, các quý khác ép về 0
        IF(unnest_quy.quy = 'q1', unnest_quy.val, 0) AS q1,
        IF(unnest_quy.quy = 'q2', unnest_quy.val, 0) AS q2,
        IF(unnest_quy.quy = 'q3', unnest_quy.val, 0) AS q3,
        IF(unnest_quy.quy = 'q4', unnest_quy.val, 0) AS q4

    FROM ds_kh_tt a
    -- Xoay ngang thành dọc: Chỉ tạo dòng cho quý nào có giá trị > 0
    CROSS JOIN UNNEST([
        STRUCT('q1' AS quy, IFNULL(a.q1, 0) AS val),
        STRUCT('q2' AS quy, IFNULL(a.q2, 0) AS val),
        STRUCT('q3' AS quy, IFNULL(a.q3, 0) AS val),
        STRUCT('q4' AS quy, IFNULL(a.q4, 0) AS val)
    ]) AS unnest_quy
    WHERE unnest_quy.val > 0
)

    , sales AS (
        SELECT
            b.pubcustid,
            b.channel AS channel,
            b.shoptype AS makenhphu_cu,
            a.maphanloaihco AS maphanloaihco_cu,
            Case When extract(YEAR FROM ngaychungtu) = 2025 then IFNULL(d.supid,hr.msnvcsmmoi) 
                 else IFNULL(d.supid,a.crm) end  as ma_crm,
            date(date_trunc(a.ngaychungtu,month)) AS thang,
            IFNULL(e.brandnew2023, e1.brandnew2023) AS brandnew2023,
            a.masanpham,
            a.tensanphamnb,
            sum(CASE WHEN extract(year from ngaychungtu)= 2025 THEN a.doanhsochuavat ELSE 0 END) AS doanhsochuavat_2024,
            sum(CASE WHEN extract(year from ngaychungtu)= 2026 THEN a.doanhsochuavat ELSE 0 END) AS doanhsochuavat_2025,
            sum(a.doanhsochuavat) AS doanhsochuavat,
            0 AS kh_total
        FROM `staging_temp.f_sales_crs_lhq_bytime` a
        LEFT JOIN `staging.d_master_khachhang` b ON a.makhdms = b.custid
        LEFT JOIN `staging.d_nhom_sp_trading` e ON e.masanpham = a.masanpham
        LEFT JOIN `staging.d_nhom_sp_trading_bytime` e1 ON e1.masanpham = a.masanpham AND EXTRACT(YEAR FROM ngaychungtu) < 2026 AND e1.nam = 2025
        LEFT JOIN `warehouse.f_mapping_crs` d ON d.custid = a.makhdms
        LEFT JOIN `spatial-vision-343005.warehouse.dskh_dong_nhat_crm_cau_truc_hien_tai` f ON f.ma_kh_dms = a.makhdms
        LEFT JOIN (
    SELECT msnvcsmmoi, hovatenfullname
    FROM `spatial-vision-343005.staging.d_hr_dsns`
    WHERE phongdeptsummary = 'HCP'
        ) hr on hr.hovatenfullname = f.ten_crm
        WHERE ngaychungtu >= '2025-01-01' AND b.channel IN ('INS','PCL','CLC')
        AND ngaychungtu <'2027-01-01'
        AND datatype1 = 'f_sales'
        AND b.pubcustid is not null
        GROUP BY all

        UNION ALL
        SELECT
            'NONE'AS pubcustid,
            a.makenhkh AS channel,
            null AS makenhphu_cu,
            null AS maphanloaihco_cu,
            u.supid as ma_crm,
            date(date_trunc(a.ngaychungtu,month)) AS thang,
            null AS brandnew2023,
            null as masanpham,
            null as tensanphamnb,
            0 AS doanhsochuavat_2024,
            0 AS doanhsochuavat_2025,
            0 AS doanhsochuavat,
            sum(kh_total) AS kh_total
        FROM `staging_temp.f_sales_crs_lhq_bytime` a
        LEFT JOIN `staging.d_users` u ON a.manv = u.manv
        WHERE ngaychungtu >= '2026-01-01' AND a.makenhkh IN ('INS','PCL','CLC')
        AND ngaychungtu <'2027-01-01'
        AND datatype1 = 'd_calendar'
        GROUP BY all
    )

, DeduplicatedMasterKH AS (
    SELECT *
    FROM `staging.d_master_khachhang`
    -- Lọc trực tiếp lấy dòng đầu tiên không cần subquery
    QUALIFY ROW_NUMBER() OVER (PARTITION BY pubcustid, channel ORDER BY pubcustid) = 1
)

, union_all AS (
SELECT 
        a.mahcochung,
        a.kenh,
        a.ma_crm,
        a.thang_quy AS thang,          -- Lấy cột ngày linh động từ unpivot
        '' AS brandnew2023,
        NULL AS masanpham,
        NULL AS tensanphamnb,
        0 AS doanhsochuavat_2024,
        0 AS doanhsochuavat_2025,
        0 AS doanhsochuavat,           
        0 AS kh_total,
        'DS KH TT' AS datatype,
        'TT' AS pl_kh,
        ifnull(b.pubcustname,'') AS pubcustname,
        b.statedescr,
        b.hcotypeid,
        b.shoptype,
        b.branchid,
        b.shortterritorydescr,
        a.thang_quy AS thang_filter,   -- Lấy cột ngày linh động từ unpivot
        --a.ncrm,       
        --a.ma_ncrm,    
        a.q1,
        a.q2,
        a.q3,
        a.q4
    FROM ds_kh_tt_unpivoted a
    LEFT JOIN `DeduplicatedMasterKH` b ON a.mahcochung = b.pubcustid AND a.kenh = b.channel
    UNION ALL 

    SELECT 
        a.* except(makenhphu_cu, maphanloaihco_cu),
        'Sales' AS datatype, 
        if(b.mahcochung is not null,'TT','Còn lại') AS pl_kh,
        c.pubcustname,
        c.statedescr,
        maphanloaihco_cu AS hcotypeid,
        makenhphu_cu AS shoptype,
        c.branchid,
        c.shortterritorydescr,
        thang AS thang_filter,
        --a.ncrm,       
        --a.ma_ncrm,   
        0 as q1,
        0 as q2,
        0 as q3,
        0 as q4
    FROM sales a
    LEFT JOIN ds_kh_tt b ON a.pubcustid = b.mahcochung AND a.channel = b.kenh AND a.ma_crm = b.ma_crm
    LEFT JOIN `DeduplicatedMasterKH` c ON a.pubcustid = c.pubcustid AND a.channel = c.channel
)

, union_pre AS (
    SELECT *, 0 AS pre_ds FROM union_all
    
    UNION ALL
    
    SELECT 
        mahcochung,
        kenh,
        ma_crm,
        thang,
        brandnew2023,
        masanpham,
        tensanphamnb,
        0 AS doanhsochuavat_2024,
        0 AS doanhsochuavat_2025,
        0 AS doanhsochuavat,
        0 AS kh_total,
        datatype,
        pl_kh,
        pubcustname,
        statedescr,
        hcotypeid,
        shoptype,
        branchid,
        shortterritorydescr,
        thang + interval 1 year AS thang_filter,
        --ncrm,         -- Giữ lại cột tên
        --ma_ncrm,      -- Thêm cột mã
        0 as q1,
        0 as q2,
        0 as q3,
        0 as q4,
        doanhsochuavat AS pre_ds
    FROM union_all 
    WHERE datatype ='Sales' AND thang >='2025-01-01' AND thang <'2026-01-01'

    UNION ALL

    /* ------------------------------------------------------------------
       THÊM DỮ LIỆU KẾ HOẠCH 2026 (Đẩy số KH vào cột kh_total)
       ------------------------------------------------------------------ */
    SELECT 
        '' AS mahcochung,
        '' AS kenh,
        '' AS ma_crm,
        DATE '2026-01-01' AS thang,
        kh.brandnew2023,
        NULL AS masanpham,
        NULL AS tensanphamnb,
        0 AS doanhsochuavat_2024,
        0 AS doanhsochuavat_2025,
        0 AS doanhsochuavat,
        kh.kehoach_val AS kh_total, 
        'Kế Hoạch nhóm sản phẩm 2026' AS datatype,
        'Còn lại' AS pl_kh,
        '' AS pubcustname,
        '' AS statedescr,
        '' AS hcotypeid,
        '' AS shoptype,
        '' AS branchid,
        '' AS shortterritorydescr,
        DATE '2026-01-01' AS thang_filter,
        0 AS q1,
        0 AS q2,
        0 AS q3,
        0 AS q4,
        0 AS pre_ds
    FROM UNNEST([
        STRUCT('ENT' AS brandnew2023, 209500000000 AS kehoach_val),
        STRUCT('ANTI' AS brandnew2023, 117100000000 AS kehoach_val),
        STRUCT('GI' AS brandnew2023, 96700000000 AS kehoach_val),
        STRUCT('EYE' AS brandnew2023, 71500000000 AS kehoach_val),
        STRUCT('DERM' AS brandnew2023, 9100000000 AS kehoach_val),
        STRUCT('OC' AS brandnew2023, 600000000 AS kehoach_val),
        STRUCT('OTH' AS brandnew2023, 500000000 AS kehoach_val)
    ]) AS kh
)

,cost_summary AS (
    SELECT 
        ma_hco_chung,
        SUM(chi_phi_thuc_hien_dong) AS chi_phi
    FROM `spatial-vision-343005.staging.d_tracking_cost_hcp_v2`
    WHERE nam_thuc_hien = 2026
    GROUP BY 
        ma_hco_chung
)

, ton_kho_summary AS (
    SELECT 
        m.pubcustid AS ma_hco_chung,
        SUM(CAST(x.thanhtien_ton AS FLOAT64)) AS tong_thanhtien_ton
    FROM `spatial-vision-343005.warehouse.f_xuatnhapton` x
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` m
        ON x.custid = m.custid
    WHERE 
        /* Lọc hợp đồng còn hiệu lực: Ngày hết hạn HĐ >= Ngày hiện tại */
        DATE(CAST(COALESCE(x.gentodate, x.todate) AS TIMESTAMP)) >= CURRENT_DATE('+07')
        AND x.channel = 'INS'
    GROUP BY 
        m.pubcustid
)

, result AS (
    SELECT 
        a.*,
        '' as custid,
        '' as custname,
        u.tencvbh AS ten_crm,
        u.asm as ma_ncrm,
        u.tenquanlykhuvuc as ncrm,
        CASE 
            WHEN EXTRACT(QUARTER FROM a.thang) <= EXTRACT(QUARTER FROM CURRENT_DATE('+07')) 
            THEN (IFNULL(a.q1, 0) + IFNULL(a.q2, 0) + IFNULL(a.q3, 0) + IFNULL(a.q4, 0))
            ELSE 0 
        END AS total_kh_tt,
    
        IFNULL(c.chi_phi, 0) AS chi_phi,
        IFNULL(t.tong_thanhtien_ton, 0) AS ton_thau,
        
        (SELECT max(updated_at) FROM `staging_temp.f_sales_crs_lhq_bytime` WHERE ngaychungtu >='2025-01-01') AS inserted_at 
    FROM union_pre a 
    LEFT JOIN `staging.d_users` u ON a.ma_crm = u.manv
    LEFT JOIN cost_summary c 
        ON a.mahcochung = c.ma_hco_chung
    LEFT JOIN ton_kho_summary t 
        ON a.mahcochung = t.ma_hco_chung AND a.kenh = 'INS'
)

SELECT * FROM result --where thang >= '2026-01-01' and ncrm = 'Nguyễn Thọ Chiến(KN)'
--where mahcochung = '000128'





;