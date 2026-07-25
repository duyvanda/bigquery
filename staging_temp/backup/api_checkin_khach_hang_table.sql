CREATE TABLE FUNCTION `spatial-vision-343005`.staging_temp.api_checkin_khach_hang_table(p_ma_crs STRING)
AS
SELECT
        slsperid,
        date(date_trunc(visitdate, MONTH)) AS thang,
        extract(
            quarter
            FROM
                visitdate
        ) AS quy,
        extract(
            year
            FROM
                visitdate
        ) AS nam,
        count(DISTINCT sl_quydinh) AS sl_quydinh,
        count(DISTINCT sl_kh_checkin) AS sl_kh_checkin,
        round(
            safe_divide(
                count(DISTINCT sl_kh_checkin),
                count(DISTINCT sl_quydinh)
            ) * 100,
            1
        ) AS tiendo_viengtham,
        count(DISTINCT sl_kh_checkin_ngoaimcp) AS sl_kh_checkin_ngoaimcp,
        count(sl_quydinh) AS sl_call_cancheckin,
        count(DISTINCT soluong_checkin_thucte) AS soluong_checkin_thucte,
        count(DISTINCT soluong_trongtuyen) AS soluong_trongtuyen,
        count(DISTINCT soluong_ngoaituyen) AS soluong_ngoaituyen,
        round(
            safe_divide(
                count(DISTINCT soluong_checkin_thucte),
                count(sl_quydinh)
            ) * 100,
            1
        ) AS tyle_call_checkin,
    FROM
        `warehouse.f_data_checkin_pbh_v2`
    WHERE
        -- date(date_trunc(visitdate, MONTH)) >= '2024-03-01'
         date(visitdate) between date(date_trunc(current_date("+7"),month)) and date(date_trunc(current_date("+7"),month)) + interval 1 month - interval 1 day
         and starts_with(left(slsperid,6),p_ma_crs)
    GROUP BY
        1,
        2,
        3,
        4;