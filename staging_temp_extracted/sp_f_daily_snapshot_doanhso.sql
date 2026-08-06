-- ==========================================================================
-- Routine Name : sp_f_daily_snapshot_doanhso
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2025-11-06 02:26:32.299000+00:00
-- Last Altered : 2025-11-06 02:26:32.299000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_daily_snapshot_doanhso()
BEGIN
  TRUNCATE TABLE staging_temp.f_daily_snapshot_doanhso_temp;

 INSERT INTO staging_temp.f_daily_snapshot_doanhso_temp(
-- Create table staging_temp.f_daily_snapshot_doanhso_temp as
with saleecom as
 (SELECT
    thang,
    SUM(doanhsochuavat) AS doanhsoluyke,
    SUM(CASE
        WHEN  date_sub(current_date("+7"),interval 1 day) = date(ngaychungtu) THEN doanhsochuavat
      ELSE
      0
    END
      ) AS doanhso_1dago,
       count (distinct (CASE
        WHEN  date_sub(current_date("+7"),interval 1 day) = date(ngaychungtu) then sodondathang
      ELSE
      null
    END
      )) AS sodon_1dago,
     count (distinct (CASE
        WHEN  date_sub(current_date("+7"),interval 1 day) = date(ngaychungtu) then makhdms
      ELSE
      null
    END
      )) AS sokhach_1dago,
    count (DISTINCT sodondathang) AS so_don,
    count (DISTINCT makhdms) AS so_nt
  FROM
    `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
  WHERE
    is_ecom='Ecom'
    and  EXTRACT(YEAR FROM thang)  =  EXTRACT(YEAR FROM date_sub(current_date("+7"),interval 1 day))
    and  EXTRACT(month FROM thang) =  EXTRACT(month FROM date_sub(current_date("+7"),interval 1 day))
   and date(ngaychungtu) <= date_sub(current_date("+7"),interval 1 day)
  GROUP BY
    1 )

SELECT
  a.*,
  b.kh_total,
  b.kh_nt,
  b.kh_don
FROM
  saleecom a
LEFT JOIN
  `staging.d_calendar_ecom` b
ON
  a.thang = b.thang
    );

Create or replace table `warehouse.f_daily_snapshot_doanhso`

copy `staging_temp.f_daily_snapshot_doanhso_temp`;

End;
