CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_performance_crs()
BEGIN 
TRUNCATE TABLE staging_temp.f_performance_crs_temp;
--INSERT INTO staging_temp.f_performance_crs_temp(
Create or replace table staging_temp.f_performance_crs_temp as
WITH
    tuyen_thang AS (
        SELECT
            manv,
            thang,
            EXTRACT(QUARTER FROM thang) AS quy,
            EXTRACT(YEAR FROM thang) AS nam,
            ma_khachhang AS makh,
            tuyen_cn,
            tansuat_bh,
            ma_tuyenbh,
            classid
        FROM
            `warehouse.f_thongtin_tuyen_mcp_tp_pcl`
        WHERE
            active = 'Active'
            AND kenh = 'TP'
    ),

 chi_tiet_tuyen_mcp AS (
        SELECT
            DATE(DATE_TRUNC(a.thang, MONTH)) AS thang,
            a.manv,            
            -- Tính SLKH có tần suất F chưa hợp lý ngay trên tuyến
            COUNT(DISTINCT CASE 
                    WHEN a.classid IN ('KA', 'RB') AND a.tansuat_bh = 'F1' AND CAST(a.tuyen_cn AS STRING) != '1' THEN a.makh
                    WHEN a.classid = 'RC' AND a.tansuat_bh = 'F4' AND CAST(a.tuyen_cn AS STRING) != '1' THEN a.makh
                    ELSE NULL 
                    END) AS slkh_f_chua_hop_ly_tuyen,

            COUNT(DISTINCT CASE 
                WHEN b.businessscope IN ('05', '06', '05,06','06,05') 
                AND CAST(a.tuyen_cn AS STRING) != '1' 
                THEN a.makh
                ELSE NULL 
            END) AS slkh_thieu_hspl
        FROM 
            tuyen_thang a
        LEFT JOIN 
            `staging.d_master_khachhang_bytime` b 
            ON a.makh = b.custid 
            AND DATE(a.thang) = DATE(b.thang)
        GROUP BY 
            1, 2
    ),
    
    mcp_metrics AS (
        SELECT
            thang,
            manv,
            -- Tổng hợp lại số khách hàng F chưa hợp lý của nhân viên
            SUM(slkh_f_chua_hop_ly_tuyen) AS slkh_f_chua_hop_ly,
            SUM(slkh_thieu_hspl) AS slkh_thieu_hspl
        FROM 
            chi_tiet_tuyen_mcp
        GROUP BY 
            1, 2
    ),

    tuyen_mcp_duoi_12_kh AS (
        SELECT 
            DATE_TRUNC(ngay,MONTH) as thang,
            manv,
            COUNT(DISTINCT CASE WHEN sl_kh < 12 THEN ngay ELSE NULL END) AS sl_tuyen_duoi_12kh
            FROM `spatial-vision-343005.warehouse.f_crs_mcp_thap` 
            GROUP BY 1,2
    ),

    tuyen AS (
        SELECT
            manv,
            quy,
            nam,
            makh,
            tuyen_cn
        FROM
            tuyen_thang
        WHERE
            RIGHT(CAST(DATE(thang) AS STRING), 5) IN ('12-01', '09-01', '06-01', '03-01')
        UNION ALL
        SELECT
            manv,
            quy,
            nam,
            makh,
            tuyen_cn
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
                    a1.tuyen_cn,
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
                    AND ngaychungtu >= '2023-01-01'
                    AND makenhkh = 'TP'
                GROUP BY
                    ALL
            ),
            mapping_kh_quy AS (
                SELECT
                    IFNULL(a.manv, b.manv) AS manv,
                    IFNULL(a.thang, b.thang + INTERVAL 3 MONTH) AS thang,
                    IFNULL(a.doanhsochuavat, b.doanhsochuavat) AS doanhsochuavat,
                    IFNULL(a.crs_tuyenbanhang_trongmcp, b.crs_tuyenbanhang_trongmcp) AS crs_tuyenbanhang_trongmcp,
                    a.tuyen_cn,
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
            , kh_mcp_quy AS (
                SELECT
                manv,
                quy,
                nam,
                COUNT(DISTINCT CASE WHEN CAST(tuyen_cn AS STRING) != '1' THEN makh ELSE NULL END) AS slkh_mcp_t2_t7_quy
        FROM
            tuyen
        GROUP BY
            1, 2, 3
    )

        SELECT
            a.manv,
            thang,
            EXTRACT(QUARTER FROM thang) AS quy,
            EXTRACT(YEAR FROM thang) AS nam,
            COUNT(DISTINCT makh) AS sl_kh_quy_hientai,
            COUNT(DISTINCT makhdms_quy_new) AS sl_kh_quy_new,
            COUNT(DISTINCT makhdms_quy_quaylai) AS sl_kh_quy_quaylai,
            COUNT(DISTINCT makhdms_quy_duytri) AS sl_kh_quy_duytri,
            COUNT(DISTINCT makhdms_quy_off) AS sl_kh_quy_off,
            b.slkh_mcp_t2_t7_quy,
            COUNT(DISTINCT CASE WHEN crs_tuyenbanhang_trongmcp = 'Trong MCP' AND makh IS NOT NULL AND CAST(tuyen_cn AS STRING) != '1' THEN makh ELSE NULL END) AS slkh_active_tuyen_t2_t7,
            COUNT(DISTINCT CASE WHEN crs_tuyenbanhang_trongmcp = 'Trong MCP' AND makh IS NOT NULL AND CAST(tuyen_cn AS STRING) = '1' THEN makh ELSE NULL END) AS slkh_active_tuyen_cn,
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
            ) AS ds_off,
            SUM(
                CASE
                    WHEN crs_tuyenbanhang_trongmcp = 'Trong MCP'
                    AND makh IS NOT NULL THEN doanhsochuavat
                    ELSE 0
                END
            ) AS doanhsochuavat_trongmcp,
            SUM(
                CASE
                    WHEN crs_tuyenbanhang_trongmcp = 'Ngoài MCP'
                    AND makh IS NOT NULL THEN doanhsochuavat
                    ELSE 0
                END
            ) AS doanhsochuavat_ngoaimcp,
            COUNT(DISTINCT CASE WHEN crs_tuyenbanhang_trongmcp = 'Trong MCP' AND makh IS NOT NULL THEN makh ELSE NULL END) AS sl_kh_trongmcp,
            COUNT(DISTINCT CASE WHEN crs_tuyenbanhang_trongmcp = 'Ngoài MCP' AND makh IS NOT NULL THEN makh ELSE NULL END) AS sl_kh_ngoaimcp
        FROM
            phanloai a
        LEFT JOIN kh_mcp_quy b ON a.manv = b.manv
            AND EXTRACT(QUARTER FROM a.thang) = b.quy
            AND EXTRACT(YEAR FROM a.thang) = b.nam    
        GROUP BY
            ALL
        ORDER BY
            thang
    ),
    kh_mcp AS (
        SELECT
            thang,
            manv,
            COUNT(DISTINCT CASE WHEN tuyen_cn = 0 THEN ma_khachhang ELSE NULL END) AS sl_kh_mcp
        FROM
            `warehouse.f_thongtin_tuyen_mcp_tp_pcl`
        WHERE
            active = 'Active'
            AND kenh in ('TP','GT')
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
            SAFE_DIVIDE(COUNT(DISTINCT ma_call_kh_dat),COUNT( ma_kh_can_vieng_tham)) AS tyle_call_checkin
        FROM
            `warehouse.view_f_data_checkin_pbh_v3` a    
        WHERE
            visitdate >= '2023-04-01'
            AND a.channel in ('TP','GT')
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
            c.tenquanlyvung IN ('Nguyễn Hoàng Viển')
            AND a.manv NOT LIKE '%KN%'
    ),
    data_sales AS (
        SELECT
            CASE
                WHEN a.manv = 'MR2355_KN' THEN 'MR2355'
                ELSE a.manv
            END AS manv,
            'S' AS cap_bac,
            DATE(a.thang) AS thang,
            'TP' AS makenhkh,
            a.tencvbh,
            a.crm AS supid,
            a.tenquanlytt,
            SUM(doanhsochuavat) AS doanhsochuavat,
            COUNT(DISTINCT CASE WHEN g.makh IS NOT NULL AND CAST(g.tuyen_cn AS STRING) != '1' THEN a.makhdms ELSE NULL END) AS slkh_active_tuyen_t2_t7_thang,
            SUM(CASE WHEN CAST(g.tuyen_cn AS STRING) = '1' THEN a.doanhsochuavat ELSE 0 END) AS ds_tuyen_chunhat,
            SUM(CASE WHEN CAST(g.tuyen_cn AS STRING) != '1' THEN a.doanhsochuavat ELSE 0 END) AS ds_tuyen_t2_t7,
            SUM(kh_total) AS kh_total,
            ROUND(
                SAFE_DIVIDE(SUM(doanhsochuavat), SUM(kh_total)),
                4
            ) AS th_kpi,
            COUNT(DISTINCT th_slpp_ebysta) AS th_slpp_ebysta,
            SUM(slpp_ebysta) AS slpp_ebysta,
            COUNT(DISTINCT th_slpp_medoral) AS th_slpp_medoral,
            SUM(slpp_medoral) AS slpp_medoral,
            COUNT(DISTINCT th_slpp_medoral) + COUNT(DISTINCT th_slpp_ebysta) AS total_th_slpp,
            SUM(slpp_ebysta) + SUM(slpp_medoral) AS total_kpi_slpp,
            ROUND(
                SAFE_DIVIDE (
                    (
                        COUNT(DISTINCT th_slpp_medoral) + COUNT(DISTINCT th_slpp_ebysta)
                    ),
                    (SUM(slpp_ebysta) + SUM(slpp_medoral))
                ),
                4
            ) AS th_kpi_slpp,
            SUM(th_ds_sptt) AS th_ds_sptt,
            SUM(kpi_ds_sptt) AS kpi_ds_sptt,
            ROUND(
                SAFE_DIVIDE(SUM(th_ds_sptt), SUM(kpi_ds_sptt)),
                4
            ) AS th_kpi_sptt,
            COUNT(
                DISTINCT (
                    CASE
                        WHEN g.makh IS NOT NULL THEN makhdms
                        ELSE NULL
                    END
                )
            ) AS soluong_kh_active_trongmcp,
            COUNT(
                DISTINCT (
                    CASE
                        WHEN g.makh IS NULL THEN makhdms
                        ELSE NULL
                    END
                )
            ) AS soluong_kh_active_ngoaimcp,
            COUNT(
                DISTINCT (
                    CASE
                        WHEN is_ecom = 'Ecom' THEN makhdms
                        ELSE NULL
                    END
                )
            ) AS soluong_kh_active_ecom,
            COUNT(DISTINCT makhdms) AS soluong_kh_active,
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
            ) AS acv
        FROM
            `staging_temp.f_sales_crs_lhq_bytime` a
            LEFT JOIN tuyen_thang g ON a.manv = g.manv
            AND a.makhdms = g.makh
            AND DATE(a.thang) = DATE(g.thang)
        WHERE
            a.crs_tuyenbanhang_trongmcp NOT IN ('Rural')
            AND makenhkh = 'TP'
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
            ROUND(SAFE_DIVIDE(soluong_kh_active_trongmcp, soluong_kh_active), 4) AS tile_kh_active_trongmcp,
            ROUND(SAFE_DIVIDE(soluong_kh_active_ngoaimcp, soluong_kh_active), 4) AS tile_kh_active_ngoaimcp,
            ROUND(SAFE_DIVIDE(soluong_kh_active_ecom, soluong_kh_active), 4) AS tile_kh_active_ecom,
            ROUND(SAFE_DIVIDE(soluong_kh_active_trongmcp, b.sl_quydinh), 4) AS tile_kh_phanphoi_trongmcp,
            ROUND(SAFE_DIVIDE(soluong_kh_active_trongmcp, b.sl_kh_checkin), 4) AS tile_donhang_thanhcong,
            b.* EXCEPT (thang, slsperid),
            (b.sl_call_cancheckin - b.soluong_trongtuyen) AS soluong_call_chuacheckin,
            ROUND(SAFE_DIVIDE((b.sl_call_cancheckin - b.soluong_trongtuyen), b.sl_call_cancheckin), 4) AS tile_call_chuacheckin_dungtuyen,
            n.sl_tuyen_duoi_12kh,
            m.slkh_f_chua_hop_ly,
            m.slkh_thieu_hspl,
            c.* EXCEPT (thang, manv, quy, nam),
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
            e.sl_kh_mcp,
            f.cham_diem_cmsp,
           MAX(Case when f.quy = 1 then f.xeploai_abc else null end) OVER(PARTITION BY a.manv, EXTRACT(YEAR FROM a.thang)) as xeploai_abc_q1,
            MAX(Case when f.quy = 2 then f.xeploai_abc else null end) OVER(PARTITION BY a.manv, EXTRACT(YEAR FROM a.thang)) as xeploai_abc_q2,
            MAX(Case when f.quy = 3 then f.xeploai_abc else null end) OVER(PARTITION BY a.manv, EXTRACT(YEAR FROM a.thang)) as xeploai_abc_q3,
            MAX(Case when f.quy = 4 then f.xeploai_abc else null end) OVER(PARTITION BY a.manv, EXTRACT(YEAR FROM a.thang)) as xeploai_abc_q4,
            --f.xeploai_abc,
            f.xeploai_phanloai,
            f.diem_xeploai_quy,
            f.is_noi_dat_tinhthuong_quy,
            f.a_tieuchi as th_kpi_kh_total_quy,
            f.n_tieuchi as th_kpi_kh_sptt_quy,
            f.c_tieuchi as th_kpi_pp_kh_mcp_quy
        FROM
            data_sales a
            LEFT JOIN viengtham_kh b ON a.manv = b.slsperid
            AND a.thang = b.thang
            LEFT JOIN kh_drop_crs c ON a.manv = c.manv
            AND EXTRACT(QUARTER FROM a.thang) = EXTRACT(QUARTER FROM c.thang)
            AND EXTRACT(YEAR FROM a.thang) = EXTRACT(YEAR FROM c.thang)
            LEFT JOIN kh_mcp e ON a.manv = e.manv
            AND DATE(a.thang) = DATE(e.thang)
            LEFT JOIN `warehouse.view_thuong_quy_all` f ON a.manv = f.manv
            AND EXTRACT(QUARTER FROM a.thang) = f.quy
            AND EXTRACT(YEAR FROM a.thang) = f.nam
            LEFT JOIN mcp_metrics m ON a.manv = m.manv AND a.thang = m.thang
            LEFT JOIN tuyen_mcp_duoi_12_kh n ON a.thang = n.thang AND a.manv = n.manv
        ORDER BY
            a.thang DESC
    ),
    avg_month AS (
        SELECT
            *,
            AVG(doanhso_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS ds_tb_thang,
            AVG(kekhoach_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS kh_tb_thang,
            AVG(sl_quydinh_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS sl_quydinh_tb_thang,
            AVG(sl_kh_checkin_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS sl_kh_checkin_tb_thang,
            AVG(soluong_kh_active_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS soluong_kh_active_tb_thang,
            AVG(soluong_kh_active_trongmcp_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS soluong_kh_active_trongmcp_tb_thang,
            AVG(soluong_kh_active_ngoaimcp_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS soluong_kh_active_ngoaimcp_tb_thang,
            AVG(soluong_kh_active_ecom_last_month) OVER (PARTITION BY manv, makenhkh ORDER BY thang DESC ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS soluong_kh_active_ecom_tb_thang,
            ROW_NUMBER() OVER (PARTITION BY quy, nam, manv ORDER BY thang) AS loc_kh_drop_quy,
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
    )
SELECT
    a.*,
    CASE
        WHEN b.msnvcsmmoi IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS is_active,
    b.diabanlamviec,
    b.chucdanhengtitlesum,
    b.ngayvaolamonboarddate
FROM
    avg_month a
    LEFT JOIN `staging.d_hr_dsns` b ON a.manv = b.msnvcsmmoi


--)
;

Create or replace table `warehouse.f_performance_crs`

copy `staging_temp.f_performance_crs_temp`;


End;