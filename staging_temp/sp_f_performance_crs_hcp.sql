CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_performance_crs_hcp()
BEGIN

TRUNCATE TABLE staging_temp.f_performance_crs_hcp_temp;
--INSERT INTO `staging_temp.f_performance_crs_hcp_temp`
--(
Create or replace table staging_temp.f_performance_crs_hcp_temp as

WITH
    tuyen_thang AS (
        SELECT
            manv,
            thang,
            kenh,
            EXTRACT(QUARTER FROM thang) AS quy,
            EXTRACT(YEAR FROM thang) AS nam,
            ma_khachhang AS makh
        FROM
            `warehouse.f_thongtin_tuyen_mcp_tp_pcl`
        WHERE
            active = 'Active'
            AND kenh in ('PCL','INS','CLC')
    ),
    slkh_mcp_thang AS (
        SELECT
            manv,
            thang,
            EXTRACT(QUARTER FROM thang) AS quy,
            EXTRACT(YEAR FROM thang) AS nam,
            COUNT(DISTINCT makh) AS tong_slkh_mcp,
            COUNT(DISTINCT CASE WHEN kenh = 'PCL' then makh else null end) as tong_slkh_mcp_pcl
        FROM tuyen_thang
        GROUP BY ALL
    ),

    tuyen AS (
        SELECT
            manv,
            quy,
            nam,
            makh
        FROM
            tuyen_thang
        WHERE
            RIGHT(CAST(DATE(thang) AS STRING), 5) IN ('12-01', '09-01', '06-01', '03-01')
        UNION ALL
        SELECT
            manv,
            quy,
            nam,
            makh
        FROM
            tuyen_thang
        WHERE
            RIGHT(CAST(DATE(thang) AS STRING), 5) NOT IN ('12-01', '09-01', '06-01', '03-01')
            AND thang = (
                SELECT
                    MAX(thang)
                FROM
                    tuyen_thang
            )
    ),
    kh_drop_crs AS (
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
            kh_da_co_ds_ps AS (
                SELECT
                    CASE
                        WHEN EXTRACT(QUARTER FROM ngaychungtu) = 4 THEN DATE(EXTRACT(YEAR FROM ngaychungtu), 12, 01)
                        WHEN EXTRACT(QUARTER FROM ngaychungtu) = 3 THEN DATE(EXTRACT(YEAR FROM ngaychungtu), 09, 01)
                        WHEN EXTRACT(QUARTER FROM ngaychungtu) = 2 THEN DATE(EXTRACT(YEAR FROM ngaychungtu), 06, 01)
                        WHEN EXTRACT(QUARTER FROM ngaychungtu) = 1 THEN DATE(EXTRACT(YEAR FROM ngaychungtu), 03, 01)
                        ELSE NULL
                    END AS thang,
                    makhdms AS makh,
                    SUM(doanhsochuavat) AS ds
                FROM
                    `staging.f_sales`
                GROUP BY
                    1,
                    2
                HAVING
                    ds > 0
            ),
            kh_da_co_ds_ps_v2 AS (
                SELECT
                    a.*,
                    makh,
                    SUM(ds) AS ds
                FROM
                    base_date a
                    LEFT JOIN kh_da_co_ds_ps b ON a.thang > b.thang
                GROUP BY
                    ALL
            ),
            base_makh AS (
                SELECT
                    a.manv,
                    CASE
                        WHEN EXTRACT(QUARTER FROM ngaychungtu) = 4 THEN DATE(EXTRACT(YEAR FROM ngaychungtu), 12, 01)
                        WHEN EXTRACT(QUARTER FROM ngaychungtu) = 3 THEN DATE(EXTRACT(YEAR FROM ngaychungtu), 09, 01)
                        WHEN EXTRACT(QUARTER FROM ngaychungtu) = 2 THEN DATE(EXTRACT(YEAR FROM ngaychungtu), 06, 01)
                        WHEN EXTRACT(QUARTER FROM ngaychungtu) = 1 THEN DATE(EXTRACT(YEAR FROM ngaychungtu), 03, 01)
                        ELSE NULL
                    END AS thang,
                    EXTRACT(QUARTER FROM ngaychungtu) AS quy,
                    EXTRACT(YEAR FROM ngaychungtu) AS nam,
                    makhdms AS makh,
                    CASE
                        WHEN a1.makh IS NOT NULL THEN 'Trong MCP'
                        ELSE 'Ngoài MCP'
                    END AS crs_tuyenbanhang_trongmcp,
                    SUM(doanhsochuavat) AS doanhsochuavat
                FROM
                    `staging_temp.f_sales_crs_lhq_bytime` a
                    LEFT JOIN tuyen a1 ON a.manv = a1.manv
                    AND a.makhdms = a1.makh
                    AND EXTRACT(QUARTER FROM ngaychungtu) = a1.quy
                    AND EXTRACT(YEAR FROM ngaychungtu) = a1.nam
                WHERE
                    a.crs_tuyenbanhang_trongmcp NOT IN ('Rural')
                    AND makhdms IS NOT NULL
                    AND a.makenhkh IN ('INS', 'CLC', 'PCL')
                    AND ngaychungtu >= '2023-01-01'
                GROUP BY
                    ALL
            ),
            mapping_kh_quy AS (
                SELECT
                    IFNULL(a.manv, b.manv) AS manv,
                    IFNULL(a.thang, b.thang + INTERVAL 3 MONTH) AS thang,
                    IFNULL(a.doanhsochuavat, b.doanhsochuavat) AS doanhsochuavat,
                    IFNULL(a.crs_tuyenbanhang_trongmcp, b.crs_tuyenbanhang_trongmcp) AS crs_tuyenbanhang_trongmcp,
                    a.makh,
                    b.makh AS pre_makh,
                    c.makh AS back_makh
                FROM
                    base_makh a
                    FULL JOIN base_makh b ON a.manv = b.manv
                    AND a.makh = b.makh
                    AND a.thang = b.thang + INTERVAL 3 MONTH
                    LEFT JOIN kh_da_co_ds_ps_v2 c ON a.thang = c.thang
                    AND a.makh = c.makh
            ),
            phanloai AS (
                SELECT
                    *,
                    CASE
                        WHEN back_makh IS NULL
                        AND pre_makh IS NULL THEN makh
                        ELSE NULL
                    END AS makhdms_quy_new,
                    CASE
                        WHEN pre_makh IS NOT NULL
                        AND makh IS NOT NULL THEN makh
                        ELSE NULL
                    END AS makhdms_quy_duytri,
                    CASE
                        WHEN pre_makh IS NOT NULL
                        AND makh IS NULL THEN pre_makh
                        ELSE NULL
                    END AS makhdms_quy_off,
                    CASE
                        WHEN back_makh IS NOT NULL
                        AND pre_makh IS NULL THEN makh
                        ELSE NULL
                    END AS makhdms_quy_quaylai
                FROM
                    mapping_kh_quy
            )
        SELECT
            manv,
            thang,
            EXTRACT(QUARTER FROM thang) AS quy,
            EXTRACT(YEAR FROM thang) AS nam,
            COUNT(DISTINCT makh) AS sl_kh_quy_hientai,
            COUNT(DISTINCT makhdms_quy_new) AS sl_kh_quy_new,
            COUNT(DISTINCT makhdms_quy_quaylai) AS sl_kh_quy_quaylai,
            COUNT(DISTINCT makhdms_quy_duytri) AS sl_kh_quy_duytri,
            COUNT(DISTINCT makhdms_quy_off) AS sl_kh_quy_off,
            SUM(
                CASE
                    WHEN makh IS NOT NULL THEN doanhsochuavat
                    ELSE 0
                END
            ) AS doanhsochuavat_kh_drop,
            SUM(
                CASE
                    WHEN makhdms_quy_new IS NOT NULL THEN doanhsochuavat
                    ELSE 0
                END
            ) AS ds_new,
            SUM(
                CASE
                    WHEN makhdms_quy_quaylai IS NOT NULL THEN doanhsochuavat
                    ELSE 0
                END
            ) AS ds_quaylai,
            SUM(
                CASE
                    WHEN makhdms_quy_duytri IS NOT NULL THEN doanhsochuavat
                    ELSE 0
                END
            ) AS ds_duytri,
            SUM(
                CASE
                    WHEN makhdms_quy_off IS NOT NULL THEN doanhsochuavat
                    ELSE 0
                END
            ) AS ds_off
        FROM
            phanloai
        GROUP BY
            ALL
        ORDER BY
            thang
    ),
    kh_mcp AS (
        SELECT
            thang,
            manv,
            COUNT(DISTINCT ma_khachhang) AS sl_kh_mcp
        FROM
            `warehouse.f_thongtin_tuyen_mcp_tp_pcl`
        WHERE
            active = 'Active'
            AND kenh = 'PCL'
        GROUP BY
            ALL
        ORDER BY
            1
    ),
    viengtham_kh AS (
        SELECT
            slsperid,
            DATE(DATE_TRUNC(visitdate, MONTH)) AS thang,
            COUNT(DISTINCT ma_kh_can_vieng_tham) AS sl_quydinh,
            COUNT(DISTINCT ma_kh_dat ) AS sl_kh_checkin,
            SAFE_DIVIDE(COUNT(DISTINCT ma_kh_dat ),COUNT(DISTINCT ma_kh_can_vieng_tham)) AS tiendo_viengtham,
            COUNT(DISTINCT ma_kh_checkin_ngoai_mcp) AS sl_kh_checkin_ngoaimcp,
            COUNT(ma_kh_can_vieng_tham) AS sl_call_cancheckin,
            COUNT(DISTINCT ma_call_kh_dat) AS soluong_checkin_thucte,
            COUNT(DISTINCT ma_call_kh_dat_trong_tuyen) AS soluong_trongtuyen,
            COUNT(DISTINCT ma_call_kh_dat_ngoai_tuyen) AS soluong_ngoaituyen,
            SAFE_DIVIDE(COUNT(DISTINCT ma_call_kh_dat_trong_tuyen),COUNT(DISTINCT ma_call_kh_dat)) AS tyle_call_checkin_trongtuyen,
            SAFE_DIVIDE(COUNT(DISTINCT ma_call_kh_dat_ngoai_tuyen),COUNT(DISTINCT ma_call_kh_dat)) AS tyle_call_checkin_ngoaituyen,
            SAFE_DIVIDE(COUNT(DISTINCT ma_call_kh_dat),COUNT(ma_kh_can_vieng_tham)) AS tyle_call_checkin
        FROM
            `warehouse.view_f_data_checkin_pbh_v3`
        WHERE
            visitdate >= '2023-04-01'
            AND channel = 'PCL'
        GROUP BY
            1,
            2
    ),
    data_kenh_phutrach_bh AS (
        SELECT DISTINCT
            a.manv,
            c.tencvbh,
            c.tenquanlytt,
            c.supid
        FROM
            `staging.d_calendar` a
            LEFT JOIN `staging.d_users` c ON c.manv = a.manv
        WHERE
            c.tenquanlyvung IN ('Vũ Mừng')
            AND a.manv NOT LIKE '%KN%'
    ),
    data_sales AS (
        SELECT
            LEFT(a.manv, 6) AS manv,
            'S' AS cap_bac,
            DATE(a.thang) AS thang,
            a.makenhkh,
            a.tencvbh,
            a.crm AS supid,
            a.tenquanlytt,
            SUM(doanhsochuavat) AS doanhsochuavat,
            SUM(kh_total) AS kh_total,
            ROUND(
                SAFE_DIVIDE(SUM(doanhsochuavat), SUM(kh_total)),
                4
            ) AS th_kpi,
            COUNT(
                DISTINCT (
                    CASE
                        WHEN a.makenhkh = 'PCL'
                        AND g.makh IS NOT NULL THEN makhdms
                        ELSE NULL
                    END
                )
            ) AS soluong_kh_active_trongmcp,
            COUNT(
                DISTINCT (
                    CASE
                        WHEN a.makenhkh = 'PCL'
                        AND g.makh IS NULL THEN makhdms
                        ELSE NULL
                    END
                )
            ) AS soluong_kh_active_ngoaimcp,
            COUNT(
                DISTINCT (
                    CASE
                        WHEN a.makenhkh = 'PCL'
                        AND is_ecom = 'Ecom' THEN makhdms
                        ELSE NULL
                    END
                )
            ) AS soluong_kh_active_ecom,
            COUNT(DISTINCT CASE WHEN a.makenhkh = 'PCL' THEN makhdms ELSE NULL END) AS soluong_kh_active,
            COUNT(DISTINCT makhdms) AS soluong_kh_active_total,
            COUNT(DISTINCT sodondathang) AS soluong_donhang,
            ROUND(
                SAFE_DIVIDE(
                    SUM(doanhsochuavat),
                    COUNT(DISTINCT sodondathang)
                ),
                4
            ) AS aov,
            ROUND(
                SAFE_DIVIDE(
                    SUM(doanhsochuavat),
                    COUNT(DISTINCT makhdms)
                ),
                4
            ) AS acv,
            MAX(h.tong_slkh_mcp) AS tong_sl_kh,
            MAX(h.tong_slkh_mcp_pcl) AS tong_sl_kh_pcl
        FROM
            `staging_temp.f_sales_crs_lhq_bytime` a
            JOIN data_kenh_phutrach_bh c ON LEFT(a.manv, 6) = c.manv
            LEFT JOIN tuyen_thang g ON a.manv = g.manv
            AND a.makhdms = g.makh
            AND DATE(a.thang) = DATE(g.thang)
            LEFT JOIN slkh_mcp_thang h ON a.manv = h.manv
            AND DATE(a.thang) = DATE(h.thang)
        WHERE
            a.crs_tuyenbanhang_trongmcp NOT IN ('Rural')
            AND a.makenhkh IN ('INS', 'CLC', 'PCL')
        GROUP BY
            ALL
    ),
    sales_lastmonth AS (
        SELECT
            a.*,
            CASE
                WHEN a.tenquanlytt = 'Nguyễn Văn Tiến' THEN 'SDS'
                ELSE 'CRS/CRSS'
            END AS chucvu,
            CASE
                WHEN a.makenhkh = 'INS' THEN soluong_donhang
                ELSE 0
            END AS soluong_donhang_ins,
            CASE
                WHEN a.makenhkh = 'INS' THEN aov
                ELSE 0
            END AS aov_ins,
            CASE
                WHEN a.makenhkh = 'INS' THEN acv
                ELSE 0
            END AS acv_ins,
            CASE
                WHEN a.makenhkh = 'INS' THEN a.doanhsochuavat
                ELSE 0
            END AS doanhsochuavat_ins,
            CASE
                WHEN a.makenhkh = 'INS' THEN a.kh_total
                ELSE 0
            END AS kh_total_ins,
            CASE
                WHEN a.makenhkh = 'INS' THEN th_kpi
                ELSE 0
            END AS th_kpi_ins,
            CASE
                WHEN a.makenhkh = 'CLC' THEN soluong_donhang
                ELSE 0
            END AS soluong_donhang_clc,
            CASE
                WHEN a.makenhkh = 'CLC' THEN aov
                ELSE 0
            END AS aov_clc,
            CASE
                WHEN a.makenhkh = 'CLC' THEN acv
                ELSE 0
            END AS acv_clc,
            CASE
                WHEN a.makenhkh = 'CLC' THEN a.doanhsochuavat
                ELSE 0
            END AS doanhsochuavat_clc,
            CASE
                WHEN a.makenhkh = 'CLC' THEN a.kh_total
                ELSE 0
            END AS kh_total_clc,
            CASE
                WHEN a.makenhkh = 'CLC' THEN th_kpi
                ELSE 0
            END AS th_kpi_clc,
            CASE
                WHEN a.makenhkh = 'PCL' THEN soluong_donhang
                ELSE 0
            END AS soluong_donhang_pcl,
            CASE
                WHEN a.makenhkh = 'PCL' THEN aov
                ELSE 0
            END AS aov_pcl,
            CASE
                WHEN a.makenhkh = 'PCL' THEN acv
                ELSE 0
            END AS acv_pcl,
            CASE
                WHEN a.makenhkh = 'PCL' THEN a.doanhsochuavat
                ELSE 0
            END AS doanhsochuavat_pcl,
            CASE
                WHEN a.makenhkh = 'PCL' THEN a.kh_total
                ELSE 0
            END AS kh_total_pcl,
            CASE
                WHEN a.makenhkh = 'PCL' THEN th_kpi
                ELSE 0
            END AS th_kpi_pcl,
            ROUND(
                SAFE_DIVIDE(soluong_kh_active_trongmcp, soluong_kh_active),
                4
            ) AS tile_kh_active_trongmcp,
            ROUND(
                SAFE_DIVIDE(soluong_kh_active_ngoaimcp, soluong_kh_active),
                4
            ) AS tile_kh_active_ngoaimcp,
            ROUND(
                SAFE_DIVIDE(soluong_kh_active_ecom, soluong_kh_active),
                4
            ) AS tile_kh_active_ecom,
            ROUND(
                SAFE_DIVIDE(soluong_kh_active_trongmcp, b.sl_quydinh),
                4
            ) AS tile_kh_phanphoi_trongmcp,
            ROUND(
                SAFE_DIVIDE(soluong_kh_active_trongmcp, b.sl_kh_checkin),
                4
            ) AS tile_donhang_thanhcong,
            b.* EXCEPT (
                thang,
                slsperid
            ),
            (b.sl_call_cancheckin - b.soluong_trongtuyen) AS soluong_call_chuacheckin,
            ROUND(
                SAFE_DIVIDE(
                    (b.sl_call_cancheckin - b.soluong_trongtuyen),
                    b.sl_call_cancheckin
                ),
                4
            ) AS tile_call_chuacheckin_dungtuyen,
            c.* EXCEPT (
                thang,
                manv,
                quy,
                nam
            ),
            LAG(a.doanhsochuavat) OVER (PARTITION BY a.manv, a.makenhkh ORDER BY a.thang ASC) AS doanhso_last_month,
            LAG(a.kh_total) OVER (PARTITION BY a.manv, a.makenhkh ORDER BY a.thang ASC) AS kekhoach_last_month,
            LAG(b.sl_quydinh) OVER (PARTITION BY a.manv, a.makenhkh ORDER BY a.thang ASC) AS sl_quydinh_last_month,
            LAG(b.sl_kh_checkin) OVER (PARTITION BY a.manv, a.makenhkh ORDER BY a.thang ASC) AS sl_kh_checkin_last_month,
            LAG(soluong_kh_active) OVER (PARTITION BY a.manv, a.makenhkh ORDER BY a.thang ASC) AS soluong_kh_active_last_month,
            LAG(soluong_kh_active_trongmcp) OVER (PARTITION BY a.manv, a.makenhkh ORDER BY a.thang ASC) AS soluong_kh_active_trongmcp_last_month,
            LAG(soluong_kh_active_ngoaimcp) OVER (PARTITION BY a.manv, a.makenhkh ORDER BY a.thang ASC) AS soluong_kh_active_ngoaimcp_last_month,
            LAG(soluong_kh_active_ecom) OVER (PARTITION BY a.manv, a.makenhkh ORDER BY a.thang ASC) AS soluong_kh_active_ecom_last_month,
            EXTRACT(QUARTER FROM a.thang) AS quy,
            EXTRACT(YEAR FROM a.thang) AS nam,
            IFNULL(e.sl_kh_mcp, 0) AS sl_kh_mcp,
            f.cham_diem_cmsp,
            --f.xeploai_abc,
            f.xeploai_phanloai,
            MAX(Case when f.quy = 1 then f.xeploai_abc else null end) OVER(PARTITION BY a.manv, EXTRACT(YEAR FROM a.thang)) as xeploai_abc_q1,
            MAX(Case when f.quy = 2 then f.xeploai_abc else null end) OVER(PARTITION BY a.manv, EXTRACT(YEAR FROM a.thang)) as xeploai_abc_q2,
            MAX(Case when f.quy = 3 then f.xeploai_abc else null end) OVER(PARTITION BY a.manv, EXTRACT(YEAR FROM a.thang)) as xeploai_abc_q3,
            MAX(Case when f.quy = 4 then f.xeploai_abc else null end) OVER(PARTITION BY a.manv, EXTRACT(YEAR FROM a.thang)) as xeploai_abc_q4,
            f.diem_xeploai_quy
        FROM
            data_sales a
            LEFT JOIN viengtham_kh b ON a.manv = b.slsperid
            AND a.thang = b.thang
            AND a.makenhkh = 'PCL'
            LEFT JOIN kh_drop_crs c ON a.manv = c.manv
            AND EXTRACT(QUARTER FROM a.thang) = EXTRACT(QUARTER FROM c.thang)
            AND EXTRACT(YEAR FROM a.thang) = EXTRACT(YEAR FROM c.thang)
            LEFT JOIN kh_mcp e ON a.manv = e.manv
            AND DATE(a.thang) = DATE(e.thang)
            AND a.makenhkh = 'PCL'
            LEFT JOIN `warehouse.view_thuong_quy_all` f ON a.manv = f.manv
            AND EXTRACT(QUARTER FROM a.thang) = f.quy
            AND EXTRACT(YEAR FROM a.thang) = f.nam
        ORDER BY
            a.thang DESC
    )
SELECT
    *,
    'HCP' AS phongban,
    AVG(doanhso_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS ds_tb_thang,
    AVG(kekhoach_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS kh_tb_thang,
    AVG(sl_quydinh_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS sl_quydinh_tb_thang,
    AVG(sl_kh_checkin_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS sl_kh_checkin_tb_thang,
    AVG(soluong_kh_active_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS soluong_kh_active_tb_thang,
    AVG(soluong_kh_active_trongmcp_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS soluong_kh_active_trongmcp_tb_thang,
    AVG(soluong_kh_active_ngoaimcp_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS soluong_kh_active_ngoaimcp_tb_thang,
    AVG(soluong_kh_active_ecom_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS soluong_kh_active_ecom_tb_thang,
    CASE
        WHEN EXTRACT(QUARTER FROM thang) = 4 THEN DATE(EXTRACT(YEAR FROM thang), 10, 01)
        WHEN EXTRACT(QUARTER FROM thang) = 3 THEN DATE(EXTRACT(YEAR FROM thang), 07, 01)
        WHEN EXTRACT(QUARTER FROM thang) = 2 THEN DATE(EXTRACT(YEAR FROM thang), 04, 01)
        WHEN EXTRACT(QUARTER FROM thang) = 1 THEN DATE(EXTRACT(YEAR FROM thang), 01, 01)
        ELSE NULL
    END AS thang_quy,
    CAST(CURRENT_DATETIME("+7") AS TIMESTAMP) AS inserted_at
FROM
    sales_lastmonth

--)
;

Create or replace table `warehouse.f_performance_crs_hcp`

copy `staging_temp.f_performance_crs_hcp_temp`;


END;