CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_tonkho_hangngay_page_tonkhotonghop_v2()
BEGIN 
 
TRUNCATE TABLE staging_temp.f_baocao_tonkho_hangngay_page_tonkhotonghop_temp_v2;
INSERT INTO `staging_temp.f_baocao_tonkho_hangngay_page_tonkhotonghop_temp_v2`

(   

-- Create or replace table staging_temp.f_baocao_tonkho_hangngay_page_tonkhotonghop_temp_v2 as 

WITH base AS (
    SELECT
        masanpham,
        CASE
            WHEN macongtycn IN ('MR0001', 'HCM001') THEN 'HCM'
            WHEN macongtycn = 'MR0003' THEN 'HÀ NỘI'
            WHEN macongtycn IN ('MR0014', 'KHA014') THEN 'KHÁNH HÒA'
            WHEN macongtycn IN ('MR0015', 'DNI015') THEN 'ĐỒNG NAI'
            WHEN macongtycn = 'MR0011' THEN 'HẢI PHÒNG'
            WHEN macongtycn IN ('MR0012', 'NAN012') THEN 'NGHỆ AN'
            WHEN macongtycn IN ('MR0010', 'HNI010') THEN 'HÀ NỘI'
            WHEN macongtycn IN ('MR0013', 'DNG013') THEN 'ĐÀ NẴNG'
            WHEN macongtycn IN ('MR0016', 'CTO016') THEN 'CẦN THƠ'
            WHEN macongtycn IN ('HYN017') THEN 'HY'
            ELSE NULL
        END AS chinhanh,
        SUM(
            CASE
                WHEN DATE(ngaychungtu) <= CURRENT_DATE("+7")
                AND DATE(ngaychungtu) > CURRENT_DATE("+7") - 7 THEN soluong
            END
        ) AS soluong_7ngay,
        SUM(
            CASE
                WHEN DATE(ngaychungtu) <= CURRENT_DATE("+7")
                AND DATE(ngaychungtu) > CURRENT_DATE("+7") - 30 THEN soluong
            END
        ) AS soluong_30ngay,
        SUM(
            CASE
                WHEN DATE_TRUNC(DATE(ngaychungtu), MONTH) = DATE_TRUNC(CURRENT_DATE("+7"), MONTH) THEN soluong
            END
        ) AS SL_ban_MTD,
        SUM(soluong) AS soluong
    FROM
        `spatial-vision-343005.staging.f_sales` a
    WHERE
        LEFT(a.masanpham, 1) != 'V'
        AND makenhkh NOT IN ('NB', 'OTH_LAB')
        AND macongtycn != 'DL0001'
        AND DATE(ngaychungtu) >= DATE_TRUNC(
            DATE_SUB(CURRENT_DATE("+7"), INTERVAL 3 MONTH),
            MONTH
        )
    GROUP BY
        1,
        2
),
base_tonkho AS (
    SELECT
        created_date,
        masanpham,
        tensanpham,
        donvi,
        chinhanh,
        toncn,
        tonhcm,
        tonao,
        tonhangdiduong,
        tonmerap,
        tonvime,
        tonhangdiduongvime,
        tonnmtpbt,
        tonnmtp,
        inserted_at,
        tonnmbt,
        tonnmhh,
        soluong,
        avg_3m,
        songaynhan,
        tonnmpo,
        tonnmno,
        inserted_at2,
        CASE
            WHEN b.chinhanh = 'CT' THEN 'CẦN THƠ'
            WHEN b.chinhanh = 'NA' THEN 'NGHỆ AN'
            WHEN b.chinhanh = 'HN' THEN 'HÀ NỘI'
            WHEN b.chinhanh = 'DNANG' THEN 'ĐÀ NẴNG'
            WHEN b.chinhanh = 'HP' THEN 'HẢI PHÒNG'
            WHEN b.chinhanh = 'HCM' THEN 'HCM'
            WHEN b.chinhanh = 'KH' THEN 'KHÁNH HÒA'
            WHEN b.chinhanh = 'DNAI' THEN 'ĐỒNG NAI'
            WHEN b.chinhanh = 'HUNGYEN' THEN 'HY'
            WHEN b.chinhanh = 'NM' THEN 'HY'
            ELSE b.chinhanh
        END AS chinhanh_new
    FROM
        `spatial-vision-343005.staging.f_sc_daily_invt` b
    WHERE
        created_date = (
            SELECT
                MAX(created_date)
            FROM
                `spatial-vision-343005.staging.f_sc_daily_invt`
        )
        AND LOWER(masanpham) NOT LIKE 'v%'
        AND LOWER(masanpham) NOT LIKE 'p%'
),
group_base_tonkho AS (
    SELECT
        created_date,
        inserted_at2,
        masanpham,
        chinhanh_new AS chinhanh,
        SUM(toncn + tonhcm + tonmerap) AS ton_kho_cn,
        SUM(tonnmtp + tonnmhh + tonnmtpbt) AS ton_kho_nm,
        SUM(tonhangdiduong) AS tonhangdiduong,
        SUM(tonvime) AS tonvime,
        SUM(tonhangdiduongvime) AS tonhangdiduongvime,
        SUM(tonao) AS tonao
    FROM
        base_tonkho
    GROUP BY
        1,
        2,
        3,
        4
)

, fc_month_sales AS (
    SELECT
        t6.month,
        t6.masp,
        SUM(t6.fcvalues) AS fcvalues
    FROM
        `spatial-vision-343005.staging.d_forecast_sc` t6
    WHERE
        DATE(t6.month) = DATE(DATE_TRUNC(CURRENT_DATE("+7"), MONTH))
        AND version = (
            SELECT MAX(version)
            FROM `staging.d_forecast_sc`
            WHERE DATE(month) = DATE(DATE_TRUNC(CURRENT_DATE("+7"), MONTH))
        )
    GROUP BY
        1, 2
),
sales_sp AS (
    SELECT
        masanpham,
        SUM(soluong_30ngay) AS soluong
    FROM
        base
    GROUP BY
        1
),
fc_sales AS (
    SELECT
        tt1.masanpham,
        tt1.chinhanh,
        SAFE_DIVIDE(tt1.soluong_30ngay, tt2.soluong)  * t2.fcvalues as fc_chinhanh
    FROM
        base tt1
        LEFT JOIN sales_sp tt2 ON tt1.masanpham = tt2.masanpham
        LEFT JOIN fc_month_sales t2 ON tt1.masanpham = t2.masp
),
base_sanpham AS (
    SELECT
        a.invtid AS masp,
        a.descr,
        t2.* EXCEPT(masp)
    FROM
        `spatial-vision-343005.staging.d_dms_master_invtid` a
        LEFT JOIN staging.d_master_sanpham t2 ON a.invtid = t2.masp
    WHERE
        status = 'AC' AND classid = 'Product'
),
mapping_all AS (
    SELECT
        created_date,
        inserted_at2,
        COALESCE(a.masanpham, b.masanpham, tb2.masanpham) AS masanpham,
        COALESCE(a.chinhanh, b.chinhanh, tb2.chinhanh) AS chinhanh,
        CASE
            WHEN COALESCE(a.masanpham, b.masanpham, tb2.masanpham) = 'OH072' THEN 'Osla Online'
            ELSE t2.descr
        END AS tensanpham,
        a.ton_kho_cn,
        a.tonao,
        a.ton_kho_nm,
        a.tonhangdiduong,
        a.tonvime,
        a.tonhangdiduongvime,
        ROUND(IFNULL(b.soluong_7ngay, 0) / 5.5, 0) AS AVG_7_ngay,
        IFNULL(b.SL_ban_MTD, 0) AS SL_ban_MTD,
        ROUND(IFNULL(b.soluong_30ngay, 0) / 24, 0) AS AVG_30_ngay,
        ROUND(tb2.fc_chinhanh / 24, 0) AS avg_forecast,
        t2.colosx AS colo,
        IFNULL(t2.handung, '36 tháng') AS handung,
        IFNULL(t2.congtykihdoanh, 'Phanam') AS congtykihdoanh,
        IFNULL(t2.leadtimesx_binhthuong, '45-55') AS leadtimesx_binhthuong,
        IFNULL(t2.leadtimesx_gap, '20 - 24') AS leadtimesx_gap,
        t3.nhomcpa,
        t4.phannhomsp AS nhomcpa2,
        t3.brand2023
    FROM
        group_base_tonkho a
        FULL JOIN base b ON a.masanpham = b.masanpham AND LOWER(a.chinhanh) = LOWER(b.chinhanh)
        FULL JOIN fc_sales tb2 ON COALESCE(a.masanpham, b.masanpham) = tb2.masanpham
            AND LOWER(COALESCE(a.chinhanh, b.chinhanh)) = LOWER(tb2.chinhanh)
        LEFT JOIN base_sanpham t2 ON COALESCE(a.masanpham, b.masanpham, tb2.masanpham) = t2.masp
        LEFT JOIN `staging.d_nhom_sp_trading` t3 ON t3.masanpham = a.masanpham AND t3.masanpham IS NOT NULL
        LEFT JOIN staging.d_nm_quycachdh t4 ON a.masanpham = TRIM(t4.ma_san_pham_pha_nam)
    WHERE
        created_date IS NOT NULL
),
result AS (
    SELECT
        *,
        (ton_kho_cn + ton_kho_nm + tonhangdiduong) / IF(AVG_7_ngay = 0, 0.001, AVG_7_ngay) AS songay_banhet1,
        (ton_kho_cn + ton_kho_nm + tonhangdiduong) / IF(AVG_30_ngay = 0, 0.001, AVG_30_ngay) AS songay_banhet2,
        (ton_kho_cn + ton_kho_nm + tonhangdiduong) / IF(avg_forecast = 0, 0.001, avg_forecast) AS songay_banhet3,
        SUM(ton_kho_cn + ton_kho_nm + tonhangdiduong) OVER (PARTITION BY masanpham) / IF(
            SUM(AVG_7_ngay) OVER(PARTITION BY masanpham) = 0,
            0.001,
            SUM(AVG_7_ngay) OVER(PARTITION BY masanpham)
        ) AS songay_banhet1_all,
        SUM(ton_kho_cn + ton_kho_nm + tonhangdiduong) OVER (PARTITION BY masanpham) / IF(
            SUM(AVG_30_ngay) OVER(PARTITION BY masanpham) = 0,
            0.001,
            SUM(AVG_30_ngay) OVER(PARTITION BY masanpham)
        ) AS songay_banhet2_all,
        SUM(ton_kho_cn + ton_kho_nm + tonhangdiduong) OVER (PARTITION BY masanpham) / IF(
            SUM(avg_forecast) OVER (PARTITION BY masanpham) = 0,
            0.001,
            SUM(avg_forecast) OVER (PARTITION BY masanpham)
        ) AS songay_banhet3_all
    FROM
        mapping_all
),
result1 AS (
    SELECT
        *,
        CASE
            WHEN songay_banhet1 >= 75 AND songay_banhet2 >= 75 THEN 'Sản phẩm bán chậm (>=75)'
            WHEN songay_banhet1 >= 50 AND songay_banhet2 >= 50 THEN 'Sản phẩm bán chậm (>=50)'
            WHEN songay_banhet1 < 10 OR songay_banhet2 < 10 OR songay_banhet3 < 10 THEN 'Sản phẩm gần hết hàng (<10)'
            WHEN songay_banhet1 < 30 OR songay_banhet2 < 30 OR songay_banhet3 < 30 THEN 'Sản phẩm gần hết hàng (<30)'
            WHEN songay_banhet1 < 50 OR songay_banhet2 < 50 OR songay_banhet3 < 50 THEN 'Sản phẩm gần hết hàng (<50)'
            WHEN IFNULL(ton_kho_cn, 0) + IFNULL(ton_kho_nm, 0) + IFNULL(tonhangdiduong, 0) = 0 THEN 'Sản phẩm hết tồn kho'
            ELSE NULL
        END AS is_check_sp,
        CASE
            WHEN songay_banhet1_all >= 75 AND songay_banhet2_all >= 75 THEN 'Sản phẩm bán chậm (>=75)'
            WHEN songay_banhet1_all >= 50 AND songay_banhet2_all >= 50 THEN 'Sản phẩm bán chậm (>=50)'
            WHEN songay_banhet1_all < 10 OR songay_banhet2_all < 10 OR songay_banhet3_all < 10 THEN 'Sản phẩm gần hết hàng (<10)'
            WHEN songay_banhet1_all < 30 OR songay_banhet2_all < 30 OR songay_banhet3_all < 30 THEN 'Sản phẩm gần hết hàng (<30)'
            WHEN songay_banhet1_all < 50 OR songay_banhet2_all < 50 OR songay_banhet3_all < 50 THEN 'Sản phẩm gần hết hàng (<50)'
            WHEN SUM(IFNULL(ton_kho_cn, 0) + IFNULL(ton_kho_nm, 0) + IFNULL(tonhangdiduong, 0)) OVER (PARTITION BY masanpham) = 0 THEN 'Sản phẩm hết tồn kho'
            ELSE NULL
        END AS is_check_sp_all
    FROM
        result
)

SELECT
    *,
    0 AS ton_vattu
FROM
    result1

);

Create or replace table `warehouse.f_baocao_tonkho_hangngay_page_tonkhotonghop_v2`

copy `staging_temp.f_baocao_tonkho_hangngay_page_tonkhotonghop_temp_v2`;




END;