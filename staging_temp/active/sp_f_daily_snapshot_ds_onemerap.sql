CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_daily_snapshot_ds_onemerap()
BEGIN 
  TRUNCATE TABLE staging_temp.f_daily_snapshot_ds_onemerap_temp;


 INSERT INTO staging_temp.f_daily_snapshot_ds_onemerap_temp(
-- Create or replace table `staging_temp.f_daily_snapshot_ds_onemerap_temp`
-- as
with sales as (
select sum(doanhsochuavat) as ds 
from `staging.f_sales` 
where date(ngaychungtu) between date_trunc(date_sub(current_date("+7"),interval 1 day),month) and date_sub(current_date("+7"),interval 1 day)
and LEFT(masanpham,1) != 'V'
),
calendar as (
  select sum(kh_total) as kpi from `staging.d_calendar`
  where date(thang) between date_trunc(date_sub(current_date("+7"),interval 1 day),month) and date_sub(current_date("+7"),interval 1 day)
)
select *,round( safe_divide(ds , kpi) *100,1) as ty_le from calendar
LEFT JOIN sales on 1=1
 );

Create or replace table `warehouse.f_daily_snapshot_ds_onemerap`

copy `staging_temp.f_daily_snapshot_ds_onemerap_temp`;


End;