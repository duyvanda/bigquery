CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_tonkhotonghop_daily()
BEGIN 
TRUNCATE TABLE `staging_temp.f_tonkhotonghop_daily_temp`;
INSERT INTO `staging_temp.f_tonkhotonghop_daily_temp` 

 
-- CREATE OR REPLACE table staging_temp.f_tonkhotonghop_daily_temp
-- as

with base as
(

  select date(ngaychungtu) ngaychungtu, 
  
  Case when masanpham ='OH053' then 'OH087'
     when masanpham ='OH056' then 'OH086'
     when masanpham ='OH073' then 'OH088'
else masanpham end as masanpham
  
  , sum(soluong) soluong
from `spatial-vision-343005.staging.f_sales`
where date(ngaychungtu)>=date_trunc(date_sub(current_date,interval 5 month), month)
 AND makenhkh not in ('NB', 'OTH_LAB')
 AND LEFT(masanpham, 1) != 'V'
  group by 1,2
  ),
  
  base_tonkho as
  (

    	select date(created_date) created_date, inserted_at2,
      Case when masanpham ='OH053' then 'OH087'
     when masanpham ='OH056' then 'OH086'
     when masanpham ='OH073' then 'OH088'
else masanpham end as masanpham
      ,sum(toncn+tonhcm+tonao+tonvime+tonmerap ) ton_kho_cn 
      ,sum(tonnmtp+tonnmhh) ton_kho_nm
      ,sum(tonhangdiduong) tonhangdiduong
    	from `spatial-vision-343005.staging.f_sc_daily_invt`
    	where date(created_date) >=date_trunc(date_sub(current_date,interval 5 month), month) 
      group by 1,2,3
    )
  
   ,

   base_date as
(
select * ,EXTRACT(DAYOFWEEK FROM day) week_day
from
unnest(GENERATE_DATE_ARRAY(
date_trunc(date_sub(current_date,interval 5 month),month), date_trunc(date_add(current_date,interval 2 month),month), INTERVAL 1 DAY))
as day
)
,
 base_max_revise_fc as
	(
    select
        t6.month,
        t6.masp,
        sum(t6.fcvalues) fcvalues
    from
        `spatial-vision-343005.staging.d_forecast_sc_realtime` t6
    where
        date(t6.month) = date(date_trunc(current_date("+7"), month))
    group by
        1,
        2
	)
  ,
  base_fc as
  (
    select tb3.*,round(safe_divide(tb3.fcvalues,tb4.workdays),0) as avg_forecast
     from base_max_revise_fc tb3
      -- đếm số ngày làm việc trung bình trong tháng
    left join(select date_trunc(day, month) month,count(distinct case when week_day!= 1 then day end) workdays
     from base_date group by 1) tb4 on date(tb3.month) = tb4.month
    

  )
  ,base_khsx as
  (
    select t1.*except(soluong,thangtruocchuyensang,masanphamphanam),safe_divide(t1.soluong,t2.quycachdonghop) as soluong,
        Case when cast(t1.thangtruocchuyensang as string)='-'  or thangtruocchuyensang is null then 0 else
    cast(trim(REGEXP_replace(cast(t1.thangtruocchuyensang as string), r"[a-zAZ)()]",'')) as int) end AS thangtruocchuyensang,
    Case when t1.masanphamphanam ='OH053' then 'OH087'
     when t1.masanphamphanam ='OH056' then 'OH086'
     when t1.masanphamphanam ='OH073' then 'OH088'
else t1.masanphamphanam end as masanphamphanam,
     from staging.d_nm_kehoachsanxuat t1
     left join staging.d_sc_quycachdh t2 on (    Case when t1.masanphamphanam ='OH053' then 'OH087'
     when t1.masanphamphanam ='OH056' then 'OH086'
     when t1.masanphamphanam ='OH073' then 'OH088'
else t1.masanphamphanam end )=(    Case when t2.masanphamphanam ='OH053' then 'OH087'
     when t2.masanphamphanam ='OH056' then 'OH086'
     when t2.masanphamphanam ='OH073' then 'OH088'
else t2.masanphamphanam end )
      where date(ngaysx)>=date_trunc(date_sub(current_date,interval 5 month), month)
  )


  -------------------------------------------------------tính toán DB--------------------------------------------------------------------------



,base_avg_sales7 as
(
  select tb3.*,tb4.masanpham,
  sum(tb4.soluong),round(sum(tb4.soluong)/5.5,0) AVG_7_ngay
  from base_date tb3
  left join base tb4 on 1=1
                        and tb3.day>tb4.ngaychungtu
                        and date_sub(tb3.day,interval 7 day)<= tb4.ngaychungtu

  group by 1,2,3
                    
)





,base_salesmtd as
(
  select tb3.*,tb4.masanpham,sum(tb4.soluong) SL_ban_MTD
  from base_date tb3
  left join base tb4 on 1=1
                    and tb3.day>tb4.ngaychungtu
                    and date_trunc(tb3.day,month)= date_trunc(tb4.ngaychungtu,month)
  group by 1,2,3
                    
)


,base_avg_sales30 as
(
select tb6.*,round(safe_divide(tb6.sl_30_ngay,tb5.num_workday),0) AVG_30_ngay
 from
(

      select tb3.*,tb4.masanpham,round(sum(tb4.soluong),0) sl_30_ngay
      from base_date tb3
      left join base tb4 on 1=1
                        and tb3.day>tb4.ngaychungtu
                        and date_sub(tb3.day,interval 30 day)<= tb4.ngaychungtu
       group by 1,2,3
) tb6

  ---đếm số ngày cn trong 30 ngày gần nhất
  left join (
    select t1.day , count(distinct case when t2.week_day!= 1 then t2.day end) num_workday
    from base_date t1
    left join base_date t2 on 1=1
                        and t1.day>t2.day
                        and date_sub(t1.day,interval 30 day)<= t2.day

    group by 1
  ) tb5 on tb6.day=tb5.day
--  where tb6.day='2022-07-11' and masanpham='OH083'
                    
)
,
base_sanpham as 
(
  SELECT a.invtid as masp,t2.*except(masp) FROM `spatial-vision-343005.staging.d_dms_master_invtid` a
  LEFT JOIN staging.d_master_sanpham t2 on a.invtid =t2.masp
  
  where status ='AC' and classid ='Product'
)
,

basepd 
as(
select t1.*,Case when t2.masp ='OH053' then 'OH087'
     when t2.masp ='OH056' then 'OH086'
     when t2.masp ='OH073' then 'OH088'
else t2.masp end as masanpham,t3.descr tensp,t2.colosx colo,ifnull(t2.handung,'36 tháng') as handung,ifnull(t2.congtykihdoanh,'Phanam') as congtykihdoanh
,ifnull(t2.leadtimesx_binhthuong,'45-55') as leadtimesx_binhthuong,ifnull(t2.leadtimesx_gap,'20 - 24') as  leadtimesx_gap
from base_date t1
left join base_sanpham t2 on 1=1 and t2.masp not in ('OH056','OH053','OH073')
left join staging.d_dms_master_invtid t3 on t2.masp=t3.invtid)


-- #kế hoạch sản xuất next 11,14,30 ngày
,
basekhsx1 -- 7 ngày tính từ tuần thứ 2 so với ngày capture
as(
  select tb3.*
  ,tb4.masanphamphanam masanpham,
  sum(tb4.soluong) soluongkh1
  from base_date tb3
  left join base_khsx tb4 on 1=1
                    and date_add(tb3.day,interval 6 day)<=date(tb4.ngaysx)
                    and date_add(tb3.day,interval 13 day)> date(tb4.ngaysx)

  group by 1,2,3
)
------
,
basekhsx2-- 7 ngày tính từ tuần thứ 3 so với ngày capture
as(
  select  tb3.*
  ,tb4.masanphamphanam masanpham,
  sum(tb4.soluong) soluongkh2
  from base_date tb3
  left join base_khsx tb4 on 1=1
                    and date_add(tb3.day,interval 13 day)<=date(tb4.ngaysx)
                    and date_add(tb3.day,interval 20 day)> date(tb4.ngaysx)

  group by 1,2,3
)
------
,
basekhsx3-- 7 ngày tính từ tuần thứ 4 so với ngày capture
as(
  select  tb3.*
  ,tb4.masanphamphanam masanpham,
  sum(tb4.soluong) soluongkh3
  from base_date tb3
  left join base_khsx tb4 on 1=1
                    and date_add(tb3.day,interval 20 day)<=date(tb4.ngaysx)
                    and date_add(tb3.day,interval 27 day)> date(tb4.ngaysx)

  group by 1,2,3
)

------
,
basekhsx4-- 7 ngày tính từ tuần thứ 5 so với ngày capture
as(
  select  tb3.*
  ,tb4.masanphamphanam masanpham,
  sum(tb4.soluong) soluongkh4
  from base_date tb3
  left join base_khsx tb4 on 1=1
                    and date_add(tb3.day,interval 27 day)<=date(tb4.ngaysx)
                    and date_add(tb3.day,interval 34 day)> date(tb4.ngaysx)

  group by 1,2,3
)

-- --------------------------------------------------------Final-----------------------------------------------------------------------
-- #nối các data lại
,base_final 
as
(
select t1.*,
a.ton_kho_cn
,a.ton_kho_nm
,a.tonhangdiduong
,a.inserted_at2 inserted_at
, b.AVG_7_ngay
,d.SL_ban_MTD
,c.AVG_30_ngay
,avg_forecast



-- d.*

from basepd t1

left join base_tonkho a on t1.day=a.created_date and t1.masanpham= a.masanpham

left join base_avg_sales7  b 
            on t1.day=b.day and t1.masanpham= b.masanpham
left join base_avg_sales30 c
            on t1.day=c.day and t1.masanpham= c.masanpham
left join base_salesmtd d
            on t1.day=d.day and t1.masanpham= d.masanpham
left join base_fc tb2 on t1.masanpham = tb2.masp and date_trunc(t1.day,month)=date(tb2.month)


)

-- select * from base_tonkho where masanpham ='T3046003'


select 
t1.*
,t3.soluongkh1
,t4.soluongkh2
,t5.soluongkh3
,t7.soluongkh4
,t6.giaidoan
,cast(t6.thangtruocchuyensang as FLOAT64) as thangtruocchuyensang
,cast (t6.poton as STRING) as poton
,cast (t6.podathang as STRING) as podathang
,cast (t6.pobosung as STRING) as pobosung
,cast (t6.tong as STRING) as tong
,cast (t6.phanbothuchien as STRING) as phanbothuchien
,cast (t6.conton as STRING) as conton
from base_final t1
left join basekhsx1  t3 
            on t1.day=date_sub(t3.day,interval 2 day ) and t1.masanpham= t3.masanpham
left join basekhsx2  t4 
            on t1.day=date_sub(t4.day,interval 2 day ) and t1.masanpham= t4.masanpham
left join basekhsx3  t5 
            on t1.day=date_sub(t5.day,interval 2 day ) and t1.masanpham= t5.masanpham
left join basekhsx4  t7
            on t1.day=date_sub(t7.day,interval 2 day ) and t1.masanpham= t7.masanpham
left join (select distinct month,giaidoan,masanphamphanam,thangtruocchuyensang,poton,podathang,pobosung,tong,phanbothuchien,conton from base_khsx )  t6
            on date_trunc(t1.day,month) = date(t6.month) and t1.masanpham= t6.masanphamphanam   

           
;

Create or replace table `staging_temp.f_tonkhotonghop_daily`

copy `staging_temp.f_tonkhotonghop_daily_temp`;

End;