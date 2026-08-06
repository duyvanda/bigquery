-- ==========================================================================
-- Routine Name : sp_f_kehoachsx_capture_t3_v2
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-03-23 06:40:58.447000+00:00
-- Last Altered : 2026-03-23 06:40:58.447000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_kehoachsx_capture_t3_v2()
BEGIN

-- TRUNCATE TABLE `staging_temp.f_kehoachsx_capture_t3_temp`  ;
-- INSERT INTO `staging_temp.f_kehoachsx_capture_t3_temp`
CREATE TEMP TABLE `f_kehoachsx_capture_t3_temp` AS

(

WITH base AS (
  SELECT
    date(ngaychungtu) AS ngaychungtu,
    CASE
      WHEN masanpham = 'OH053' THEN 'OH087'
      WHEN masanpham = 'OH056' THEN 'OH086'
      WHEN masanpham = 'OH073' THEN 'OH088'
      ELSE masanpham
    END AS masanpham,
    SUM(soluong) AS soluong
  FROM
    `spatial-vision-343005.staging.f_sales`
  WHERE
    date(ngaychungtu) >= date_trunc(date_sub(current_date, INTERVAL 5 MONTH), MONTH)
    AND makenhkh NOT IN ('NB', 'OTH_LAB')
    AND LEFT(masanpham, 1) != 'V'
  GROUP BY
    1,
    2
),
base_tonkho AS (
  SELECT
    date(created_date) AS created_date,
    CASE
      WHEN masanpham = 'OH053' THEN 'OH087'
      WHEN masanpham = 'OH056' THEN 'OH086'
      WHEN masanpham = 'OH073' THEN 'OH088'
      ELSE masanpham
    END AS masanpham,
    SUM(toncn + tonhcm + tonmerap) AS ton_kho_cn,
    SUM(tonnmtp + tonnmhh + tonnmtpbt) AS ton_kho_nm,
    SUM(tonhangdiduong) AS tonhangdiduong,
    SUM(tonvime) AS tonvime,
    SUM(tonhangdiduongvime) AS tonhangdiduongvime,
    SUM(tonao) AS tonao,
    MAX(inserted_at2) AS inserted_at2
  FROM
    `spatial-vision-343005.staging.f_sc_daily_invt`
  WHERE
    date(created_date) >= date_trunc(date_sub(current_date, INTERVAL 5 MONTH), MONTH)
    AND EXTRACT(DAYOFWEEK FROM date(created_date)) = 7
  GROUP BY
    1,
    2
)
, calendar AS (
  SELECT
    date AS calendar_day,
    EXTRACT(DAYOFWEEK FROM date) AS week_day,
    EXTRACT(MONTH FROM date) AS month,
    EXTRACT(YEAR FROM date) AS year
  FROM
    UNNEST(GENERATE_DATE_ARRAY(
      DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 2 MONTH), MONTH),
      CURRENT_DATE()
      )) AS date
),
working_days AS (
  SELECT
    c.calendar_day AS day,
    c.week_day,
    c.month,
    c.year,
    COUNTIF(EXTRACT(DAYOFWEEK FROM d2.calendar_day) BETWEEN 2 AND 7) AS mtd_working_day
  FROM
    calendar c
  LEFT JOIN calendar d2
    ON d2.calendar_day BETWEEN DATE_TRUNC(c.calendar_day, MONTH) AND c.calendar_day
    AND d2.year = c.year
    AND d2.month = c.month
  WHERE c.week_day = 7  -- Saturday
  GROUP BY c.calendar_day, c.week_day, c.month, c.year
  ORDER BY c.calendar_day desc
)
, base_date AS (
SELECT
  day,
  week_day,
  mtd_working_day
FROM
  working_days
)

-- , songay_lamviec_trong30ngay as (
--     select t1.day ,
--     sum(
--       Case
--         when t2.week_day = 1 then 0
--         when t2.week_day = 7 then 0.5
--         when t2.week_day not in (1, 7) then 1
--         else null
--       end
--     ) as songay_lamviec_trong30ngay
--     from base_date t1
--     left join base_date t2 on 1=1
--                         and t1.day>=t2.day
--                         and date_sub(t1.day,interval 30 day) < t2.day
--     group by 1
-- ),
-- songay_lamviec_trongthang as
-- (
--   select date_trunc(day, month) month,    sum(
--       Case
--         when week_day = 1 then 0
--         when week_day = 7 then 0.5
--         when week_day not in (1, 7) then 1
--         else null
--       end
--     ) as  workdays
--      from base_date group by 1
-- )
, base_avg_sales7 AS (
  SELECT
    tb3.*,
    tb4.masanpham,
    SUM(tb4.soluong) AS soluong_7ngay
  FROM
    base_date tb3
  LEFT JOIN
    base tb4 ON 1 = 1
              AND tb3.day >= tb4.ngaychungtu
              AND DATE_SUB(tb3.day, INTERVAL 7 DAY) < tb4.ngaychungtu
  GROUP BY ALL
),
base_salesmtd AS (
  SELECT
    tb3.*,
    tb4.masanpham,
    SUM(tb4.soluong) AS SL_ban_MTD
  FROM
    base_date tb3
  LEFT JOIN
    base tb4 ON 1 = 1
              AND tb3.day >= tb4.ngaychungtu
              AND DATE_TRUNC(tb3.day, MONTH) = DATE_TRUNC(tb4.ngaychungtu, MONTH)
    GROUP BY ALL
),
base_avg_sales30 AS (
  SELECT
    tb3.*,
    tb4.masanpham,
    SUM(tb4.soluong) AS soluong_30ngay
  FROM
    base_date tb3
  LEFT JOIN
    base tb4 ON 1 = 1
              AND tb3.day >= tb4.ngaychungtu
              AND DATE_SUB(tb3.day, INTERVAL 30 DAY) < tb4.ngaychungtu
GROUP BY ALL
)
, _max_revise_fc as (
  SELECT
  *
FROM
  `spatial-vision-343005.staging.d_forecast_sc`
  where month >= '2026-01-01'
QUALIFY DENSE_RANK() OVER(PARTITION BY month, masp ORDER BY revised_date DESC) = 1
)
, base_max_revise_fc AS (
  SELECT
    t6.month,
    t6.masp,
    SUM(t6.fcvalues) AS fcvalues
  FROM
   `_max_revise_fc` t6
  WHERE
    EXTRACT(YEAR FROM t6.month) = EXTRACT(YEAR FROM CURRENT_DATE("+7"))
    -- AND version = (
    --   SELECT MAX(version)
    --   FROM `staging.d_forecast_sc`
    --   WHERE DATE(month) = DATE(DATE_TRUNC(CURRENT_DATE("+7"), MONTH))
    -- )
GROUP BY ALL
),
base_khsx AS (
  SELECT
    t1.* EXCEPT (soluong, thangtruocchuyensang, masanphamphanam),
    SAFE_DIVIDE(t1.soluong, IFNULL(t2.quy_cach_dong_hop, 1)) AS soluong,
    CASE
      WHEN CAST(t1.thangtruocchuyensang AS STRING) = '-'
           OR thangtruocchuyensang IS NULL THEN 0
      ELSE CAST(
        TRIM(
          REGEXP_REPLACE(CAST(t1.thangtruocchuyensang AS STRING), r"[a-zAZ)()]", '')
        ) AS INT
      )
    END AS thangtruocchuyensang,
    t1.masanphamphanam
  FROM
    `staging.d_nm_kehoachsanxuat` t1
  LEFT JOIN
    `staging.d_nm_quycachdh` t2
    ON t1.masanphamphanam = t2.ma_san_pham_pha_nam
  WHERE
    DATE(ngaysx) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE, INTERVAL 5 MONTH), MONTH)
)

-------------------------------------------------------tính toán DB--------------------------------------------------------------------------
, base_sanpham AS (
  SELECT
    a.invtid AS masp,
    a.descr AS tensp,
    t3.ton_min,
    t3.ton_an_toan,
    t3.ton_max,
    t3.ton_tren_min,
    t3.ton_tren_max,
    t2.* EXCEPT (masp)
  FROM
    `spatial-vision-343005.staging.d_dms_master_invtid` a
  LEFT JOIN
    `staging.d_master_sanpham` t2
    ON a.invtid = t2.masp
      LEFT JOIN
    `staging.form_scn_ton_min_max` t3
    ON a.invtid = t3.ma_sp
  WHERE
    status = 'AC'
    AND classid = 'Product'
    AND a.invtid NOT IN ('OH056', 'OH053', 'OH073')
),
basepd AS (
  SELECT
    t1.*,
    t2.masp AS masanpham,
    t2.tensp,
    t2.colosx AS colo,
    IFNULL(t2.handung, '36 tháng') AS handung,
    IFNULL(t2.congtykihdoanh, 'Phanam') AS congtykihdoanh,
    IFNULL(t2.leadtimesx_binhthuong, '45-55') AS leadtimesx_binhthuong,
    IFNULL(t2.leadtimesx_gap, '20 - 24') AS leadtimesx_gap,
    ton_min,
    ton_an_toan,
    ton_max,
    ton_tren_min,
    ton_tren_max
  FROM
    base_date t1
  LEFT JOIN
    base_sanpham t2 ON 1 = 1
) -- #kế hoạch sản xuất next 11,14,30 ngày
,
basekhsx1 AS ( -- 7 ngày tính từ tuần thứ 2 so với ngày capture
  SELECT
    tb3.*,
    tb4.masanphamphanam AS masanpham,
    SUM(tb4.soluong) AS soluongkh1
  FROM
    base_date tb3
  LEFT JOIN
    base_khsx tb4 ON 1 = 1
                  AND DATE_ADD(tb3.day, INTERVAL 2 DAY) <= DATE(tb4.ngaysx) --6,13
                  AND DATE_ADD(tb3.day, INTERVAL 9 DAY) > DATE(tb4.ngaysx)
GROUP BY ALL
),
basekhsx2 AS ( -- 7 ngày tính từ tuần thứ 3 so với ngày capture
  SELECT
    tb3.*,
    tb4.masanphamphanam AS masanpham,
    SUM(tb4.soluong) AS soluongkh2
  FROM
    base_date tb3
  LEFT JOIN
    base_khsx tb4 ON 1 = 1
                  AND DATE_ADD(tb3.day, INTERVAL 9 DAY) <= DATE(tb4.ngaysx) --13,20
                  AND DATE_ADD(tb3.day, INTERVAL 16 DAY) > DATE(tb4.ngaysx)
GROUP BY ALL
),
basekhsx3 AS ( -- 7 ngày tính từ tuần thứ 4 so với ngày capture
  SELECT
    tb3.*,
    tb4.masanphamphanam AS masanpham,
    SUM(tb4.soluong) AS soluongkh3
  FROM
    base_date tb3
  LEFT JOIN
    base_khsx tb4 ON 1 = 1
                  AND DATE_ADD(tb3.day, INTERVAL 16 DAY) <= DATE(tb4.ngaysx)
                  AND DATE_ADD(tb3.day, INTERVAL 23 DAY) > DATE(tb4.ngaysx)
GROUP BY ALL
),
basekhsx4 AS ( -- 7 ngày tính từ tuần thứ 5 so với ngày capture
  SELECT
    tb3.*,
    tb4.masanphamphanam AS masanpham,
    SUM(tb4.soluong) AS soluongkh4
  FROM
    base_date tb3
  LEFT JOIN
    base_khsx tb4 ON 1 = 1
                  AND DATE_ADD(tb3.day, INTERVAL 23 DAY) <= DATE(tb4.ngaysx)
                  AND DATE_ADD(tb3.day, INTERVAL 30 DAY) > DATE(tb4.ngaysx)
GROUP BY ALL
)

-- --------------------------------------------------------Final-----------------------------------------------------------------------
-- #nối các data lại
,  base_final AS (
  SELECT
    t1.*,
    a.ton_kho_cn,
    a.ton_kho_nm,
    a.tonhangdiduong,
    a.tonvime,
    a.tonhangdiduongvime,
    a.tonao,
    a.inserted_at2 AS inserted_at,
    ROUND(IFNULL(b.soluong_7ngay, 0) / 5.5, 0) AS AVG_7_ngay,
    IFNULL(b1.SL_ban_MTD, 0) AS SL_ban_MTD,
    IFNULL(b1.SL_ban_MTD, 0) / t1.mtd_working_day as AVG_MTD,
    ROUND(IFNULL(b2.soluong_30ngay, 0) / 24, 0) AS AVG_30_ngay,
    ROUND( IFNULL(c.fcvalues,0)  / 24, 0) AS avg_forecast
  FROM
    basepd t1
    LEFT JOIN base_tonkho a ON t1.day = a.created_date AND t1.masanpham = a.masanpham
    LEFT JOIN base_avg_sales7 b ON t1.masanpham = b.masanpham AND b.day = t1.day
    LEFT JOIN base_salesmtd b1 ON t1.masanpham = b1.masanpham AND b1.day = t1.day
    LEFT JOIN base_avg_sales30 b2 ON t1.masanpham = b2.masanpham AND b2.day = t1.day
    LEFT JOIN base_max_revise_fc c ON c.masp = t1.masanpham AND DATE_TRUNC(t1.day, MONTH) = DATE(c.month)
),
f_tonkhotonghop_daily AS (
  SELECT
    t1.*,
    t3.soluongkh1,
    t4.soluongkh2,
    t5.soluongkh3,
    t7.soluongkh4,
    t6.giaidoan,
    CAST(t6.thangtruocchuyensang AS FLOAT64) AS thangtruocchuyensang,
    CAST(t6.poton AS STRING) AS poton,
    CAST(t6.podathang AS STRING) AS podathang,
    CAST(t6.pobosung AS STRING) AS pobosung,
    CAST(t6.tong AS STRING) AS tong,
    CAST(t6.phanbothuchien AS STRING) AS phanbothuchien,
    CAST(t6.conton AS STRING) AS conton
  FROM
    base_final t1
    LEFT JOIN basekhsx1 t3 ON t1.day = t3.day AND t1.masanpham = t3.masanpham
    LEFT JOIN basekhsx2 t4 ON t1.day = t4.day AND t1.masanpham = t4.masanpham
    LEFT JOIN basekhsx3 t5 ON t1.day = t5.day AND t1.masanpham = t5.masanpham
    LEFT JOIN basekhsx4 t7 ON t1.day = t7.day AND t1.masanpham = t7.masanpham
    LEFT JOIN (
      SELECT
        DISTINCT
        month,
        giaidoan,
        masanphamphanam,
        thangtruocchuyensang,
        poton,
        podathang,
        pobosung,
        tong,
        phanbothuchien,
        conton
      FROM
        base_khsx
    ) t6 ON DATE_TRUNC(t1.day, MONTH) = DATE(t6.month) AND t1.masanpham = t6.masanphamphanam
),
max_review AS (
  SELECT
    MAX(DATE(ngayreview)) AS maxday
  FROM
    `staging.d_nm_tonchuanhap`
    -- where date(ngayreview) != '2025-11-25'
),
ton_chua_nhap_last_review AS (
  SELECT
    masanphamphanam,
    soluong
  FROM
    `staging.d_nm_tonchuanhap` t1
    JOIN max_review t2 ON DATE(t1.ngayreview) = t2.maxday
),
mapping_ton_chua_nhap AS (
  SELECT
    tb1.*,
    tb2.soluong AS tonkhsxchuanhapkho,
    (
      ton_kho_cn + ton_kho_nm + tonhangdiduong + CAST(IFNULL(tb2.soluong, 0) AS FLOAT64)
    ) AS tongton,
    IF(
      avg_forecast IS NULL,
      (0.25 * AVG_7_ngay + 0.75 * AVG_30_ngay),
      (
        0.25 * AVG_7_ngay + 0.5 * AVG_30_ngay + 0.25 * avg_forecast
      )
    ) AS tocdoban
  FROM
    f_tonkhotonghop_daily tb1
    LEFT JOIN ton_chua_nhap_last_review tb2 ON tb1.masanpham = tb2.masanphamphanam
)
, result AS (
  SELECT
    day,
    week_day,
    masanpham,
    tensp,
    colo,
    handung,
    congtykihdoanh,
    leadtimesx_binhthuong,
    leadtimesx_gap,
    ton_kho_cn,
    ton_kho_nm,
    tonhangdiduong,
    tonvime,
    tonhangdiduongvime,
    tonao,
    ton_min,
    ton_an_toan,
    ton_max,
    ton_tren_min,
    ton_tren_max,
    inserted_at,
    AVG_7_ngay,
    AVG_MTD,
    SL_ban_MTD,
    AVG_30_ngay,
    avg_forecast,
    soluongkh1,
    soluongkh2,
    soluongkh3,
    soluongkh4,
    giaidoan,
    thangtruocchuyensang,
    poton,
    podathang,
    pobosung,
    tong,
    phanbothuchien,
    conton,
    CAST(tonkhsxchuanhapkho AS INT) AS tonkhsxchuanhapkho,
    tongton,
    tocdoban,
    ROUND(SAFE_DIVIDE(tongton, tocdoban), 0) AS songayhetton,
    DATE_ADD(
      day,
      INTERVAL CAST(ROUND(SAFE_DIVIDE(tongton, tocdoban), 0) AS INT64) DAY
    ) AS ngaybanhetton,
    ROUND(
      SAFE_DIVIDE((tongton + IFNULL(soluongkh1, 0)), tocdoban),
      0
    ) AS songayhet1,
    DATE_ADD(
      DATE_ADD(
        day,
        INTERVAL CAST(ROUND(SAFE_DIVIDE(tongton, tocdoban), 0) AS INT64) DAY
      ),
      INTERVAL CAST(ROUND(SAFE_DIVIDE((IFNULL(soluongkh1, 0)), tocdoban), 0) AS INT64) DAY
    ) AS ngaybanhet1,
    ROUND(
      SAFE_DIVIDE(
        (tongton + IFNULL(soluongkh1, 0) + IFNULL(soluongkh2, 0)),
        tocdoban
      ),
      0
    ) AS songayhet2,
    DATE_ADD(
      DATE_ADD(
        DATE_ADD(
          day,
          INTERVAL CAST(ROUND(SAFE_DIVIDE(tongton, tocdoban), 0) AS INT64) DAY
        ),
        INTERVAL CAST(ROUND(SAFE_DIVIDE((IFNULL(soluongkh1, 0)), tocdoban), 0) AS INT64) DAY
      ),
      INTERVAL CAST(ROUND(SAFE_DIVIDE((IFNULL(soluongkh2, 0)), tocdoban), 0) AS INT64) DAY
    ) AS ngaybanhet2,
    ROUND(
      SAFE_DIVIDE(
        (tongton + IFNULL(soluongkh1, 0) + IFNULL(soluongkh2, 0) + IFNULL(soluongkh3, 0)),
        tocdoban
      ),
      0
    ) AS songayhet3,
    DATE_ADD(
      DATE_ADD(
        DATE_ADD(
          DATE_ADD(
            day,
            INTERVAL CAST(ROUND(SAFE_DIVIDE(tongton, tocdoban), 0) AS INT64) DAY
          ),
          INTERVAL CAST(ROUND(SAFE_DIVIDE((IFNULL(soluongkh1, 0)), tocdoban), 0) AS INT64) DAY
        ),
        INTERVAL CAST(ROUND(SAFE_DIVIDE((IFNULL(soluongkh2, 0)), tocdoban), 0) AS INT64) DAY
      ),
      INTERVAL CAST(ROUND(SAFE_DIVIDE((IFNULL(soluongkh3, 0)), tocdoban), 0) AS INT64) DAY
    ) AS ngaybanhet3,
    ROUND(
      SAFE_DIVIDE(
        (tongton + IFNULL(soluongkh1, 0) + IFNULL(soluongkh2, 0) + IFNULL(soluongkh3, 0) + IFNULL(soluongkh4, 0)),
        tocdoban
      ),
      0
    ) AS songayhet4,
    DATE_ADD(
      DATE_ADD(
        DATE_ADD(
          DATE_ADD(
            DATE_ADD(
              day,
              INTERVAL CAST(ROUND(SAFE_DIVIDE(tongton, tocdoban), 0) AS INT64) DAY
            ),
            INTERVAL CAST(ROUND(SAFE_DIVIDE((IFNULL(soluongkh1, 0)), tocdoban), 0) AS INT64) DAY
          ),
          INTERVAL CAST(ROUND(SAFE_DIVIDE((IFNULL(soluongkh2, 0)), tocdoban), 0) AS INT64) DAY
        ),
        INTERVAL CAST(ROUND(SAFE_DIVIDE((IFNULL(soluongkh3, 0)), tocdoban), 0) AS INT64) DAY
      ),
      INTERVAL CAST(ROUND(SAFE_DIVIDE((IFNULL(soluongkh4, 0)), tocdoban), 0) AS INT64) DAY
    ) AS ngaybanhet4,
    CURRENT_DATE("+7") AS captured_date
  FROM
    mapping_ton_chua_nhap
)

SELECT
  *
FROM
  result

)
;

Create or replace table `staging.f_kehoachsx_capture_t3`
partition by captured_date
as
select * from `f_kehoachsx_capture_t3_temp` ;
END;
