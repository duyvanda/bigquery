-- ==========================================================================
-- Routine Name : sp_f_performance_crs_view2
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2025-07-06 03:49:01.692000+00:00
-- Last Altered : 2025-07-06 03:49:01.692000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_performance_crs_view2()
BEGIN

TRUNCATE TABLE staging_temp.f_performance_crs_view2_temp;
INSERT INTO staging_temp.f_performance_crs_view2_temp (

WITH
    base_date AS (
        SELECT DISTINCT
            CASE
                WHEN EXTRACT(QUARTER FROM ngay) = 4 THEN DATE(EXTRACT(YEAR FROM ngay), 12, 01)
                WHEN EXTRACT(QUARTER FROM ngay) = 3 THEN DATE(EXTRACT(YEAR FROM ngay), 09, 01)
                WHEN EXTRACT(QUARTER FROM ngay) = 2 THEN DATE(EXTRACT(YEAR FROM ngay), 06, 01)
                WHEN EXTRACT(QUARTER FROM ngay) = 1 THEN DATE(EXTRACT(YEAR FROM ngay), 03, 01)
                ELSE NULL
            END AS thang
        FROM
            UNNEST(
                GENERATE_DATE_ARRAY(
                    DATE_SUB(CURRENT_DATE("+7"), INTERVAL 36 MONTH),
                    DATE_ADD(CURRENT_DATE("+7"), INTERVAL 12 MONTH),
                    INTERVAL 1 DAY
                )
            ) AS ngay
    ),
    sl_sku_quy AS (
        SELECT
            makhdms,
            masanpham,
            CASE
                WHEN EXTRACT(QUARTER FROM ngaychungtu) = 4 THEN DATE(EXTRACT(YEAR FROM ngaychungtu), 12, 01)
                WHEN EXTRACT(QUARTER FROM ngaychungtu) = 3 THEN DATE(EXTRACT(YEAR FROM ngaychungtu), 09, 01)
                WHEN EXTRACT(QUARTER FROM ngaychungtu) = 2 THEN DATE(EXTRACT(YEAR FROM ngaychungtu), 06, 01)
                WHEN EXTRACT(QUARTER FROM ngaychungtu) = 1 THEN DATE(EXTRACT(YEAR FROM ngaychungtu), 03, 01)
                ELSE NULL
            END AS thang,
            EXTRACT(QUARTER FROM ngaychungtu) AS quy,
            EXTRACT(YEAR FROM ngaychungtu) AS nam,
            SUM(doanhsochuavat) AS ds
        FROM
            `staging.f_sales`
        GROUP BY
            ALL
        HAVING
            ds > 0
    ),
    result_sl_sku_quy AS (
        SELECT
            makhdms,
            thang,
            quy,
            nam,
            COUNT(DISTINCT masanpham) AS sl_sku
        FROM
            sl_sku_quy
        GROUP BY
            ALL
    ),
    result_doanhso_quy AS (
        SELECT
            makhdms,
            thang,
            quy,
            nam,
            SUM(ds) AS doanhsochuavat
        FROM
            sl_sku_quy
        GROUP BY
            ALL
        HAVING
            doanhsochuavat > 0
    ),
    kh_da_co_ds_ps AS (
        SELECT
            a.*,
            b.makhdms,
            SUM(b.doanhsochuavat) AS ds
        FROM
            base_date a
            LEFT JOIN result_doanhso_quy b ON a.thang > b.thang
        GROUP BY
            ALL
    ),
    danhsach_kh AS (
        SELECT
            CASE
                WHEN EXTRACT(QUARTER FROM a.thang) = 4 THEN DATE(EXTRACT(YEAR FROM a.thang), 12, 01)
                WHEN EXTRACT(QUARTER FROM a.thang) = 3 THEN DATE(EXTRACT(YEAR FROM a.thang), 09, 01)
                WHEN EXTRACT(QUARTER FROM a.thang) = 2 THEN DATE(EXTRACT(YEAR FROM a.thang), 06, 01)
                WHEN EXTRACT(QUARTER FROM a.thang) = 1 THEN DATE(EXTRACT(YEAR FROM a.thang), 03, 01)
                ELSE NULL
            END AS thang,
            EXTRACT(QUARTER FROM a.thang) AS quy,
            EXTRACT(YEAR FROM a.thang) AS nam,
            a.custid,
            b.custname,
            a.statedescr,
            a.districtdescr,
            a.wardname,
            a.channel,
            a.shoptype,
            b.classid,
            a.active,
            col.ma_nvbh AS manv,
            CASE
                WHEN col.phan_loai_mcp LIKE '%Trong%' THEN 'Trong MCP'
                WHEN col.phan_loai_mcp LIKE '%Ngoài%' THEN 'Ngoài MCP'
                ELSE col.phan_loai_mcp
            END AS phan_loai_mcp,
            EXTRACT(MONTH FROM b.crtd_datetime) AS thang_tao,
            EXTRACT(YEAR FROM b.crtd_datetime) AS nam_tao
        FROM
            `warehouse.f_mapping_crs_bytime` a
            LEFT JOIN `staging.d_master_khachhang_bytime` b ON a.custid = b.custid
            AND a.thang = b.thang
        WHERE
            a.thang >= '2023-01-01'
            AND RIGHT(CAST(DATE(a.thang) AS STRING), 5) IN ('12-01', '09-01', '06-01', '03-01')
            AND (
                col.phan_loai_mcp LIKE '%Trong%'
                OR col.phan_loai_mcp LIKE '%Ngoài%'
            )
        UNION ALL
        SELECT
            CASE
                WHEN EXTRACT(QUARTER FROM a.thang) = 4 THEN DATE(EXTRACT(YEAR FROM a.thang), 12, 01)
                WHEN EXTRACT(QUARTER FROM a.thang) = 3 THEN DATE(EXTRACT(YEAR FROM a.thang), 09, 01)
                WHEN EXTRACT(QUARTER FROM a.thang) = 2 THEN DATE(EXTRACT(YEAR FROM a.thang), 06, 01)
                WHEN EXTRACT(QUARTER FROM a.thang) = 1 THEN DATE(EXTRACT(YEAR FROM a.thang), 03, 01)
                ELSE NULL
            END AS thang,
            EXTRACT(QUARTER FROM a.thang) AS quy,
            EXTRACT(YEAR FROM a.thang) AS nam,
            a.custid,
            b.custname,
            a.statedescr,
            a.districtdescr,
            a.wardname,
            a.channel,
            a.shoptype,
            b.classid,
            a.active,
            col.ma_nvbh AS manv,
            CASE
                WHEN col.phan_loai_mcp LIKE '%Trong%' THEN 'Trong MCP'
                WHEN col.phan_loai_mcp LIKE '%Ngoài%' THEN 'Ngoài MCP'
                ELSE col.phan_loai_mcp
            END AS phan_loai_mcp,
            EXTRACT(MONTH FROM b.crtd_datetime) AS thang_tao,
            EXTRACT(YEAR FROM b.crtd_datetime) AS nam_tao
        FROM
            `warehouse.f_mapping_crs_bytime` a
            LEFT JOIN `staging.d_master_khachhang_bytime` b ON a.custid = b.custid
            AND a.thang = b.thang
        WHERE
            a.thang >= '2023-01-01'
            AND RIGHT(CAST(DATE(a.thang) AS STRING), 5) NOT IN ('12-01', '09-01', '06-01', '03-01')
            AND a.thang = (
                SELECT
                    MAX(thang)
                FROM
                    `warehouse.f_mapping_crs_bytime`
            )
            AND (
                col.phan_loai_mcp LIKE '%Trong%'
                OR col.phan_loai_mcp LIKE '%Ngoài%'
            )
    ),
    result AS (
        SELECT
            a.*,
            f.tencvbh,
            f.supid,
            f.tenquanlytt,
            f.rsmid,
            f.tenquanlyvung,
            e.manv AS manv_quy_trc,
            f1.tencvbh AS tencvbh_quy_trc,
            IFNULL(b.sl_sku, 0) AS sl_sku_quy_trc,
            IFNULL(b1.sl_sku, 0) AS sl_sku_quy_ht,
            IFNULL(c.doanhsochuavat, 0) AS doanhsochuavat_quy_trc,
            IFNULL(c1.doanhsochuavat, 0) AS doanhsochuavat_quy_ht,
            CASE
                WHEN IFNULL(c1.doanhsochuavat, 0) = 0
                AND IFNULL(c.doanhsochuavat, 0) != 0 THEN IFNULL(c.doanhsochuavat, 0)
                ELSE 0
            END AS doanhsochuavat_kh_off,
            CASE
                WHEN IFNULL(c1.doanhsochuavat, 0) != 0
                AND d.makhdms IS NULL THEN IFNULL(c1.doanhsochuavat, 0)
                ELSE 0
            END AS doanhsochuavat_kh_new,
            CASE
                WHEN IFNULL(c.doanhsochuavat, 0) = 0
                AND d.makhdms IS NOT NULL THEN IFNULL(c1.doanhsochuavat, 0)
                ELSE 0
            END AS doanhsochuavat_kh_back,
            CASE
                WHEN d.makhdms IS NULL
                AND a.active = 'Active' THEN 'Y'
                ELSE 'N'
            END AS chua_ps_ds_active,
            CURRENT_DATETIME('+7') AS inserted_at
        FROM
            danhsach_kh a
            LEFT JOIN result_sl_sku_quy b ON a.custid = b.makhdms
            AND a.thang = b.thang + INTERVAL 3 MONTH
            LEFT JOIN result_sl_sku_quy b1 ON a.custid = b1.makhdms
            AND a.thang = b1.thang
            LEFT JOIN result_doanhso_quy c ON a.custid = c.makhdms
            AND a.thang = c.thang + INTERVAL 3 MONTH
            LEFT JOIN result_doanhso_quy c1 ON a.custid = c1.makhdms
            AND a.thang = c1.thang
            LEFT JOIN kh_da_co_ds_ps d ON a.thang = d.thang
            AND a.custid = d.makhdms
            LEFT JOIN danhsach_kh e ON a.custid = e.custid
            AND a.thang = e.thang + INTERVAL 3 MONTH
            LEFT JOIN `staging.d_users_bytime` f ON a.manv = f.manv
            AND a.thang = DATE(f.thang)
            LEFT JOIN `staging.d_users` f1 ON e.manv = f1.manv
    )
SELECT
    *
FROM
    result

);

Create or replace table `warehouse.f_performance_crs_view2`

copy `staging_temp.f_performance_crs_view2_temp`;

End;
