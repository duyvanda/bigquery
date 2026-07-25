CREATE VIEW `spatial-vision-343005.warehouse.view_thong_tin_crs12_pcl`
AS WITH data_tuyen AS (
SELECT
    a.custid, 
    a.slsperid, 
    a.crtd_datetime,
    CASE 
        WHEN routetype IN ('B', 'D') THEN 1 
        ELSE 2 
    END AS routetype
FROM `spatial-vision-343005.staging.sync_dms_srm` a
INNER JOIN `staging.d_users` b 
    ON a.slsperid = b.manv 
    AND b.tenquanlyvung = 'Vũ Mừng'
LEFT JOIN `staging.d_master_khachhang` c 
    ON a.custid = c.custid
WHERE 
    delroutedet = FALSE  
    AND routetype IN ('B', 'D') 
    AND c.channel = 'PCL'
)

, tuyen_dms AS (
SELECT 
custid, 
slsperid
FROM data_tuyen
QUALIFY ROW_NUMBER() OVER (
PARTITION BY custid 
ORDER BY routetype ASC, crtd_datetime DESC
) = 1
)

, tuyen_cvbh_hd AS (
SELECT DISTINCT
a.custid, 
a.genslsperid
FROM `warehouse.f_danhmuchopdong` a
LEFT JOIN `staging.d_users` c 
ON c.manv = a.genslsperid
LEFT JOIN `staging.d_master_khachhang` b 
ON a.custid = b.custid
WHERE 
c.tenquanlyvung = 'Vũ Mừng' 
AND b.channel IN ('INS', 'CLC')
AND a.active_within_x_days = 1
)

,
mapping_mcp_hd as (
SELECT * FROM tuyen_dms
UNION DISTINCT
SELECT * FROM tuyen_cvbh_hd
)

, scored_data AS (
    select
    distinct
    a.slsperid,
    c.position,
    a.custid,

    /* --- START LOGIC ƯU TIÊN --- */
    /* Giả sử cột chức vụ trong bảng d_users tên là 'position'. 
        Nếu tên khác (vd: chuc_vu), bạn hãy đổi lại nhé */
    CASE 
        WHEN c.position = 'S' THEN 1   -- Ưu tiên 1
        WHEN c.position = 'SS' THEN 2  -- Ưu tiên 2
        WHEN c.position = 'AM' THEN 3  -- Ưu tiên 2
        ELSE 4                         -- Còn lại
    END AS priority_score
    /* --- END LOGIC ƯU TIÊN --- */

    FROM `mapping_mcp_hd` a
    INNER JOIN `staging.d_master_khachhang` b on a.custid = b.custid and channel  in ('INS', 'CLC', 'PCL')
    LEFT JOIN `staging.d_users` c on c.manv = a.slsperid
    where a.slsperid not like '%MA%' and b.pubcustid is not null 
    --and a.custid in ('P0808-0057','P0808-0078')
    /* Order by ở đây chỉ để hiển thị, quan trọng là cột priority_score được tạo ra */
    ORDER BY priority_score ASC, a.slsperid ASC
)

, ranked_data AS (
    SELECT 
        custid,
        slsperid,
        position,
        priority_score,
        ROW_NUMBER() OVER(
            PARTITION BY custid 
            ORDER BY priority_score ASC, slsperid ASC
        ) as rn
    FROM scored_data
)

-- Tạo CTE Pivot để lấy 2 mã nhân viên
, pivot_data AS (
    SELECT 
        custid,
        MAX(CASE WHEN rn = 1 THEN slsperid END) AS crs1,
        MAX(CASE WHEN rn = 2 THEN slsperid END) AS crs2
    FROM ranked_data
    GROUP BY custid
)

-- JOIN lại với d_users để lấy tên và thông tin quản lý
SELECT 
    p.custid AS ma_kh,
    
    -- Thông tin CRS 1
    p.crs1 AS ma_crs1,
    u1.tencvbh AS ten_crs1,           
    u1.supid AS ma_ql1,               
    u1.tenquanlytt AS ten_ql1,        
    
    -- Thông tin CRS 2
    p.crs2 AS ma_crs2,
    u2.tencvbh AS ten_crs2,           
    u2.supid AS ma_ql2,              
    u2.tenquanlytt AS ten_ql2         

FROM pivot_data p
-- Join lần 1 cho crs1
LEFT JOIN `staging.d_users` u1 ON p.crs1 = u1.manv
-- Join lần 2 cho crs2
LEFT JOIN `staging.d_users` u2 ON p.crs2 = u2.manv

ORDER BY p.custid;


;