CREATE PROCEDURE `spatial-vision-343005`.warehouse.get_doanh_so_theo_ke_hoach_crs(url_param STRING)
BEGIN
    -- Declare biến theo chuẩn BigQuery
    DECLARE p_slsperid STRING;
    DECLARE p_thang_eq STRING;
    DECLARE current_dt DATE DEFAULT CURRENT_DATE("+07");
    DECLARE set_enddate DATE;

    BEGIN
        -- 1. Parse parameters từ JSON input
        SET p_slsperid = COALESCE(JSON_VALUE(url_param, '$.slsperid'), '');
        SET p_thang_eq = JSON_VALUE(url_param, '$.thang_eq');

        -- 2. Xử lý set_enddate
        IF p_thang_eq IS NULL OR p_thang_eq = '' THEN
            SET set_enddate = DATE_TRUNC(current_dt, MONTH);
        ELSE
            SET set_enddate = DATE(p_thang_eq);
        END IF;

        -- 3. Query chính, gom CTE và trả ra 1 JSON string duy nhất (SELECT trực tiếp)
        SELECT (
            WITH base_data AS (
                SELECT 
                    a.makhdms,
                    a.tenkhachhang,
                    a.manv,
                    a.crm,
                    a.tenquanlytt,
                    DATE(a.thang) AS thang_date,
                    a.sodondathang,
                    a.doanhsochuavat,
                    a.kh_total
                FROM `spatial-vision-343005.staging_temp.f_sales_crs_lhq_bytime` a
                WHERE a.ngaychungtu >= '2024-01-01'
                  AND DATE(a.thang) = set_enddate
                  -- Trên BigQuery, CONTAINS_SUBSTR tối ưu và an toàn hơn STRPOS khi tìm kiếm
                  AND (p_slsperid = '' OR CONTAINS_SUBSTR(CONCAT(COALESCE(a.crm, ''), COALESCE(a.manv, '')), p_slsperid))
            ),
            joined_data AS (
                SELECT 
                    bd.makhdms,
                    bd.tenkhachhang,
                    bd.manv,
                    bd.crm,
                    bd.tenquanlytt,
                    bd.thang_date,
                    bd.sodondathang,
                    bd.doanhsochuavat,
                    bd.kh_total,
                    b.tencvbh
                FROM base_data bd
                LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` b 
                       ON bd.manv = b.manv AND bd.thang_date = DATE(b.thang)
            ),
            overview_data AS (
                SELECT 
                    'Overview' AS datatype,
                    'NONE' AS ma_kh_dms,
                    'NONE' AS ten_kh,
                    manv AS ma_crs,
                    tencvbh AS ten_crs,
                    crm AS ma_crm,
                    tenquanlytt AS ten_crm,
                    CAST(thang_date AS STRING) AS thang,
                    CAST(current_dt AS STRING) AS ngay_hien_tai,
                    CASE 
                        WHEN DATE_TRUNC(thang_date, MONTH) < DATE_TRUNC(current_dt, MONTH) THEN 0 
                        ELSE DATE_DIFF(DATE(DATE_TRUNC(current_dt, MONTH) + INTERVAL 1 MONTH - INTERVAL 1 DAY), current_dt, DAY)
                    END AS so_ngay_con_lai,
                    COUNT(DISTINCT sodondathang) AS don_hang,
                    SUM(doanhsochuavat) AS doanh_so,
                    SUM(kh_total) AS ke_hoach,
                    ROUND(SAFE_DIVIDE(SUM(doanhsochuavat), SUM(kh_total)) * 100, 1) AS ty_le
                FROM joined_data
                GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
            ),
            detail_data AS (
                SELECT 
                    'Detail' AS datatype,
                    makhdms AS ma_kh_dms,
                    tenkhachhang AS ten_kh,
                    manv AS ma_crs,
                    tencvbh AS ten_crs,
                    crm AS ma_crm,
                    tenquanlytt AS ten_crm,
                    CAST(thang_date AS STRING) AS thang,
                    CAST(current_dt AS STRING) AS ngay_hien_tai,
                    CASE 
                        WHEN DATE_TRUNC(thang_date, MONTH) < DATE_TRUNC(current_dt, MONTH) THEN 0 
                        ELSE DATE_DIFF(DATE(DATE_TRUNC(current_dt, MONTH) + INTERVAL 1 MONTH - INTERVAL 1 DAY), current_dt, DAY)
                    END AS so_ngay_con_lai,
                    COUNT(DISTINCT sodondathang) AS don_hang,
                    SUM(doanhsochuavat) AS doanh_so,
                    SUM(kh_total) AS ke_hoach,
                    0 AS ty_le
                FROM joined_data
                WHERE makhdms IS NOT NULL
                GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
            )
            -- Tạo structure JSON bằng JSON_OBJECT và ARRAY_AGG của BigQuery
            SELECT JSON_OBJECT(
                'status', 'ok',
                'rows', (SELECT COUNT(*) FROM overview_data) + (SELECT COUNT(*) FROM detail_data),
                'data', JSON_OBJECT(
                    -- Sắp xếp overview_data bằng ORDER BY ngay trong hàm ARRAY_AGG
                    'Overview', COALESCE((SELECT TO_JSON(ARRAY_AGG(t ORDER BY t.doanh_so DESC)) FROM overview_data t), JSON_ARRAY()),
                    'Detail', COALESCE((SELECT TO_JSON(ARRAY_AGG(t)) FROM detail_data t), JSON_ARRAY())
                )
            )
        ) AS json_result;

    EXCEPTION WHEN ERROR THEN
        -- Bắt lỗi chuẩn của BigQuery
        SELECT JSON_OBJECT(
            'status', 'fail',
            'error_message', @@error.message
        ) AS json_result;
    END;
END;