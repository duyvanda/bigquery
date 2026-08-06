-- ==========================================================================
-- Routine Name : sp_f_canhbao_sales_fc
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-06-25 07:30:35.608000+00:00
-- Last Altered : 2026-06-25 07:30:35.608000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_canhbao_sales_fc()
BEGIN

-- TRUNCATE TABLE staging_temp.f_canhbao_sales_fc_temp;
-- INSERT INTO staging_temp.f_canhbao_sales_fc_temp(
Create or replace table staging_temp.f_canhbao_sales_fc_temp
as
(
with

so_lo_nam as

(
  SELECT date_trunc(created_date,year) as nam, masanpham,so_lo_trong_nam FROM `spatial-vision-343005.staging.f_sc_daily_invt`
qualify row_number() over (partition by masanpham,date_trunc(created_date,year) order by so_lo_trong_nam desc ) = 1
)
,
ton_kho_cn as
(
select
masanpham,
sum(ton_kho_cn+tonhangdiduong+tonvime+tonhangdiduongvime+tonao) as ton_kho_cn,
sum(ton_kho_cn+tonhangdiduong+tonvime+tonhangdiduongvime+tonao+ton_kho_nm) as tong_ton ,
sum(ton_kho_nm) as ton_kho_nm
from `warehouse.f_baocao_tonkho_hangngay_page_tonkhotonghop_v2`  group by 1
)
,
sale_days as (
with songay as ( SELECT *,
EXTRACT(month from generate_series) as month,
EXTRACT(year from generate_series) as year,
extract(dayofweek from generate_series) as name,
-- trim(to_char(generate_series, 'day')) as name,
Case when extract(dayofweek from generate_series) = 1 then 0
		 when extract(dayofweek from generate_series) =7 then 0.5
		 else 1 end as songayban
FROM unnest(generate_date_array( date(date_trunc( (select * from `staging.d_current_table`),year) - interval 1 year) ,
date(date_trunc((select * from `staging.d_current_table`),year) + interval 1 year) , interval 1 day ) ) as generate_series),
songayban as  ( SELECT month,year,sum(songayban) as songaybantrongthang from songay GROUP BY month,year ),
songaybanmtd as (SELECT month,year,sum(songayban) as songaybanMTD from songay where
 cast(generate_series as date)<(select * from `staging.d_current_table`)
GROUP BY month,year )

SELECT a.*,b.songaybanmtd from songayban a
LEFT JOIN songaybanmtd b on a.month=b.month and a.year =b.year
ORDER BY YEAR,month  ),
-- [CTE 4] MASTER FORECAST (Dùng Dense Rank + Subquery trực tiếp)
    clean_forecast_source AS (
        SELECT
            masp,
            month,
            kenh,
            insert_at,
            fcvalues
        FROM `staging.d_forecast_sc`
        WHERE
            -- FIX: Subquery trực tiếp
            DATE(month) >= DATE_TRUNC((SELECT DATE(transaction_date) FROM `staging.d_current_table` LIMIT 1), MONTH) - INTERVAL 1 MONTH
            AND DATE(month) <= DATE_TRUNC((SELECT DATE(transaction_date) FROM `staging.d_current_table` LIMIT 1), MONTH) + INTERVAL 2 MONTH
        QUALIFY
            DENSE_RANK() OVER (PARTITION BY masp, month, kenh ORDER BY insert_at DESC) = 1
    ),
    -- [CTE 5] Data FC hiện tại
    data_fc AS (
        SELECT
            masp,
            month,
            kenh,
            SUM(fcvalues) as fcvalues
        FROM clean_forecast_source
        WHERE DATE(month) = DATE_TRUNC((SELECT DATE(transaction_date) FROM `staging.d_current_table` LIMIT 1), MONTH)
        GROUP BY 1, 2, 3
    ),
    -- [CTE 6] Data FC lân cận
    data_fc_int2 AS (
        SELECT
            masp,
            month,
            kenh,
            SUM(fcvalues) as fcvalues
        FROM clean_forecast_source
        WHERE DATE(month) >= DATE_TRUNC((SELECT DATE(transaction_date) FROM `staging.d_current_table` LIMIT 1), MONTH) - INTERVAL 1 MONTH
          AND DATE(month) <= DATE_TRUNC((SELECT DATE(transaction_date) FROM `staging.d_current_table` LIMIT 1), MONTH) + INTERVAL 2 MONTH
        GROUP BY 1, 2, 3
    )
,data_sales as
(
  select masanpham,thang,makenhkh as makenh_moi,
  sum(Case when date_trunc(date(ngaychungtu),month) =date_trunc((select * from `staging.d_current_table`),month) then soluong else 0 end)
 as soluong_mtd,
    sum(Case when date_trunc(date(ngaychungtu),month) = date_trunc((select * from `staging.d_current_table`),month) - interval 1 month then soluong else 0 end)
 as soluong_last_month,
   from `warehouse.f_raw_data_sales_yoy` where ngaychungtu >='2023-01-01'
  and date_trunc(date(ngaychungtu),month) >= date_trunc((select * from `staging.d_current_table`),month)- interval 1 month
   AND LEFT(masanpham,1) != 'V'
      -- AND manv NOT IN ( 'GH001', 'MA001', 'MA002', 'QUYNHPTA')
      AND makenhkh not in ( 'NB','OTH_LAB')
      group by 1,2,3
)
,
result as (
select a.*except(month),
a.month as thang,
f.descr as tensanpham,
f.descr1 as tensp_vt,
ifnull(b.soluong_mtd,0) as soluong_mtd,
round(ifnull(safe_divide(ifnull(b.soluong_mtd,0),a.fcvalues),0),2)*100/100 as fc_rate,
round(safe_divide( ifnull(b.soluong_mtd,0) * g.songaybantrongthang,g.songaybanMTD),0) as soluong_run_rate,
round(ifnull( safe_divide (safe_divide( ifnull(b.soluong_mtd,0) * g.songaybantrongthang,g.songaybanMTD),a.fcvalues),0),2)*100/100 as run_rate,
c.month as thang1,
d.month as thang2,
e.month as thang3,
c.fcvalues as fcvalues1,
d.fcvalues as fcvalues2,
e.fcvalues as fcvalues3,
b.soluong_last_month,
g.songaybanMTD,
g.songaybantrongthang,
f.status,
h.ton_kho_cn,
h.ton_kho_nm as tong_ton_ori,
SUBSTR(CAST(k.so_lo_trong_nam AS STRING), 3) || LEFT(CAST(k.so_lo_trong_nam AS STRING), 2) as so_lo_trong_nam,
current_datetime("+7") as inserted_at
from data_fc a
left join data_sales b on a.masp =b.masanpham and date(a.month) = date(b.thang) and a.kenh = b.makenh_moi
left join data_fc_int2 c on a.masp =c.masp and date(c.month) = date(a.month) + interval 1 month and a.kenh = c.kenh
left join data_fc_int2 d on a.masp =d.masp and date(d.month) = date(a.month) + interval 2 month and a.kenh = d.kenh
left join data_fc_int2 e on a.masp =e.masp and date(e.month) = date(a.month) - interval 1 month and a.kenh = e.kenh
left join staging.d_dms_master_invtid f on f.invtid = a.masp
left join sale_days g on g.month = extract(month from a.month) and g.year =extract(year from a.month)
left join ton_kho_cn h on h.masanpham = a.masp
left join so_lo_nam k on k.masanpham = a.masp and date(date_trunc(a.month,year)) = date(k.nam)
),
result1 as (
select *,
row_number() over (partition by (run_rate >=1.2 or run_rate <0.8) order by run_rate desc) as row_,
ton_kho_cn / count(kenh) over (partition by masp) as ton_kho_div,
tong_ton_ori / count(kenh) over (partition by masp) as tong_ton
 from result
 where fcvalues + soluong_mtd <>0
 order by result.run_rate
)

select *,
 Case when run_rate >=1.2 or run_rate <0.8 then row_ else 100 end as row_column
from result1
order by row_

 );

Create or replace table `warehouse.f_canhbao_sales_fc`

copy `staging_temp.f_canhbao_sales_fc_temp`;

End;
