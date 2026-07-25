CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_daily_snapshot_tonkhotonghop()
BEGIN 
  TRUNCATE TABLE staging_temp.f_daily_snapshot_tonkhotonghop_temp;


 INSERT INTO staging_temp.f_daily_snapshot_tonkhotonghop_temp(
-- Create table `staging_temp.f_daily_snapshot_tonkhotonghop_temp` as

with base as
(-- select date(thang) ngaychungtu,masanpham,sum(soluong) soluong
 -- from `spatial-vision-343005.staging.f_monthly_sales`
 -- where date(thang)<'2021-05-01'
-- group by 1,2
  --union all
  select date(ngaychungtu) ngaychungtu, masanpham, sum(soluong) soluong
from `spatial-vision-343005.staging.f_sales`
where  tencvbh <> 'Phạm Thị Quỳnh Ảo' and doanhsochuavat>0 and masanpham not like 'V%'
  group by 1,2
  ),
  
  base_tonkho as
  (

    	select *
    	from `spatial-vision-343005.staging.f_sc_daily_invt`
    	where created_date =(select max(created_date) from `spatial-vision-343005.staging.f_sc_daily_invt`)

    )
  
  ,
  base_name as
  ( select *
   from (select masanpham,tensanpham,row_number() over (partition by masanpham order by created_date desc) as row_
         from 	`spatial-vision-343005.staging.f_sc_daily_invt` where tensanpham is not null) a
 where row_=1
    )
    ,
   
   base_date as
(
-- SELECT date(day) day,EXTRACT(ISODOW FROM day) week_day
-- FROM generate_series('2021-01-01', CURRENT_DATE, INTERVAL '1 day') day

select * ,EXTRACT(DAYOFWEEK FROM day) week_day
from
unnest(GENERATE_DATE_ARRAY(
date_sub(current_date,interval 24 month), CURRENT_DATE, INTERVAL 1 DAY))
as day
)
,
  base_max_revise_fc as
	(
	select masp,
	month, max(version) max_version

	from `spatial-vision-343005.staging.d_forecast_sc`
	group by 1,2
	)


select
 COALESCE(a.masanpham,b.masanpham,tb2.masp) masanpham
,c.tensanpham
,a.ton_kho_cn
,a.ton_kho_nm
,a.tonhangdiduong
, b.AVG_7_ngay
,b.SL_ban_MTD,b.AVG_30_ngay
,tb2.fcvalues/(date_diff(date_trunc(date_add(current_date, interval 1 month),month),date_trunc(current_date,month),day)-(select count(day) from base_date where week_day=1 and day <= current_date-1 and day >= current_date-31 )) avg_forecast
,t3.colosx colo,t3.handung,t3.congtykihdoanh,t3.leadtimesx_binhthuong,t3.leadtimesx_gap

from (select 
	 masanpham
	--, tensanpham
	,sum(toncn+tonhcm+tonao+tonvime+tonmerap ) ton_kho_cn --
	,sum(tonnmtp+tonnmhh+tonnmbt) ton_kho_nm
  ,sum(tonhangdiduong) tonhangdiduong
	from base_tonkho 
    
    group by 1) a
full outer join
 (
   select 
	masanpham,
  round(sum(case when date(ngaychungtu) <= current_date-1 and date(ngaychungtu) >= current_date-7 then soluong end)/5.5,0) as  AVG_7_ngay
	,sum(case when date(ngaychungtu) <= current_date-1 and  format_date('%Y-%m',ngaychungtu)= format_date('%Y-%m',current_date) then soluong end) SL_ban_MTD
   ,sum(case when date(ngaychungtu) <= current_date-1 and date(ngaychungtu) >= current_date-30 then soluong end) 
   /(30-(select count(day) from base_date where week_day=1 and day <= current_date-1 and day >= current_date-30 )) AVG_30_ngay

--, sum(case when to_char(ngaychungtu - interval '12 month', 'YYYY-MM')= to_char(current_date - interval '12 month', 'YYYY-MM') then soluong end )/   nullif(DATE_PART('day', date_trunc('month',current_date - interval '12 month') - date_trunc('month',current_date - interval '13 month'))-(select count(day) from base_date where week_day=7 and day>=date_trunc('month',current_date - interval '13 month') and day< date_trunc('month',current_date - interval '12 month')),0) as AVG_thang_cungky

         
	from base tb1
	group by 1
 ) b on a.masanpham= b.masanpham
full outer join( select t5.month,t5.masp,sum(t5.fcvalues) fcvalues 
                  from `spatial-vision-343005.staging.d_forecast_sc` t5
									right join base_max_revise_fc t6 on t5.masp=t6.masp
																									 and t5.month=t6.month
																									 and t5.version= t6.max_version

                where date(t5.month) = date(date_trunc(current_date,month))  group by 1,2) tb2 on COALESCE(a.masanpham,b.masanpham) = tb2.masp 
left join base_name c on COALESCE(a.masanpham,b.masanpham,tb2.masp) =c.masanpham
left join staging.d_master_sanpham t3 on a.masanpham = t3.masp

  );

Create or replace table `warehouse.f_daily_snapshot_tonkhotonghop`

copy `staging_temp.f_daily_snapshot_tonkhotonghop_temp`;

End;