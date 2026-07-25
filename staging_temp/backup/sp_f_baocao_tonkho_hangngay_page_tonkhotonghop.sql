CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_tonkho_hangngay_page_tonkhotonghop()
BEGIN 
  TRUNCATE TABLE staging_temp.f_baocao_tonkho_hangngay_page_tonkhotonghop_temp;


 INSERT INTO staging_temp.f_baocao_tonkho_hangngay_page_tonkhotonghop_temp(

-- Create table staging_temp.f_baocao_tonkho_hangngay_page_tonkhotonghop_temp
-- as

with base as
(
  select date(ngaychungtu) ngaychungtu, masanpham,chinhanh, sum(soluong) soluong
  from `spatial-vision-343005.staging.f_sales`
  where lower(masanpham) not like 'v%' and lower(masanpham) not like 'p%' and tencvbh <> 'Phạm Thị Quỳnh Ảo' and doanhsochuavat>0 
  and date(ngaychungtu)>= date_trunc(date_sub(current_date(),interval 3 month), month)
  group by 1,2,3
  ),
  

tonkho_base as
(
select created_date,
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
case when b.chinhanh = 'CT' then  'CẦN THƠ'
                                                              when b.chinhanh =  'NA' then 'NGHỆ AN'
                                                        when b.chinhanh = 'HN' then 'HÀ NỘI'
                                                        when b.chinhanh = 'DNANG' then 'ĐÀ NẴNG'
                                                        when b.chinhanh =  'HP' then 'HẢI PHÒNG'
                                                        when b.chinhanh = 'HCM' then 'HCM'
                                                        when b.chinhanh = 'KH' then 'KHÁNH HÒA'
                                                        when b.chinhanh = 'DNAI' then 'ĐỒNG NAI'
                                                        else b.chinhanh end chinhanh_new

from `spatial-vision-343005.staging.f_sc_daily_invt` b
where created_date =(select max(created_date) from `spatial-vision-343005.staging.f_sc_daily_invt`)
and lower(masanpham) not like 'v%' and lower(masanpham) not like 'p%'
)

,base_tonkho as
(
select * from tonkho_base --except(tonvime),0 as tonvime

-- union all

-- select 
-- created_date,
-- masanpham,
-- tensanpham,
-- donvi,
-- chinhanh,
-- 0 as toncn,
-- 0 as tonhcm,
-- 0 as tonao,
-- 0 as tonhangdiduong,
-- 0 as tonmerap,
-- -- 0 as tonvime,
-- 0 as tonnmtp,
-- inserted_at,
-- 0 as tonnmbt,
-- 0 as tonnmhh,
-- 0 as soluong,
-- avg_3m,
-- songaynhan,
-- 0 as tonnmpo,
-- 0 as tonnmno,
-- inserted_at2,
-- 'Kho Vime' as chinhanh_new,
-- tonvime
-- from tonkho_base b where tonvime>0
)
  
  ,
  base_name as
  ( select *
   from (select masanpham,tensanpham,row_number() over (partition by masanpham order by created_date) as row_
         from 	`spatial-vision-343005.staging.f_sc_daily_invt` where tensanpham is not null ) a
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
    date_sub(current_date,interval 24 month), date_add(current_date,interval 2 month), INTERVAL 1 DAY))
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
,
result as (
select
created_date,inserted_at2,

 COALESCE(a.masanpham,b.masanpham,tb2.masanpham) masanpham,
 COALESCE(a.chinhanh,b.chinhanh,tb2.chinhanh) chinhanh --a.chinhanh,

,case when COALESCE(a.masanpham,b.masanpham,tb2.masanpham)='OH072' then 'Osla Online' else c.tensanpham end tensanpham
,a.ton_kho_cn,
 a.tonao
,a.ton_kho_nm
,a.tonhangdiduong
,a.tonvime
, b.AVG_7_ngay
,b.SL_ban_MTD,b.AVG_30_ngay
,tb2.fc_chinhanh/(select count(day) from base_date where week_day!=1 and date_trunc(day,month) = date_trunc(current_date-1,month) )
--(date_diff(date_trunc(date_add(current_date, interval 1 month),month),date_trunc(current_date,month),day)-(select count(day) from base_date where week_day=1 and day <= current_date-1 and day >= current_date-31 )) 
avg_forecast
,t3.congtykihdoanh congtykinhdoanh

from (
  select created_date, inserted_at2,
	 masanpham,chinhanh_new chinhanh
	--, tensanpham
	,sum(toncn+tonhcm+tonmerap ) ton_kho_cn --
	,sum(tonnmtp+tonnmhh) ton_kho_nm
  ,sum(tonhangdiduong) tonhangdiduong
  ,sum(tonvime) tonvime
  ,sum(tonao) as tonao
	from base_tonkho 
    
    group by 1,2,3,4
    ) a
full outer join
 (
   select 
	masanpham,chinhanh,
  round(sum(case when date(ngaychungtu) < current_date and date(ngaychungtu) >= current_date-7 then soluong end)/5.5,0) as  AVG_7_ngay
	,sum(case when date(ngaychungtu) < current_date and  format_date('%Y-%m',ngaychungtu)= format_date('%Y-%m',current_date) then soluong end) SL_ban_MTD
   ,sum(case when date(ngaychungtu) < current_date and date(ngaychungtu) >= current_date-30 then soluong end) 
   /(30-(select count(day) from base_date where week_day=1 and day < current_date and day >= current_date-30 )) AVG_30_ngay

--, sum(case when to_char(ngaychungtu - interval '12 month', 'YYYY-MM')= to_char(current_date - interval '12 month', 'YYYY-MM') then soluong end )/   nullif(DATE_PART('day', date_trunc('month',current_date - interval '12 month') - date_trunc('month',current_date - interval '13 month'))-(select count(day) from base_date where week_day=7 and day>=date_trunc('month',current_date - interval '13 month') and day< date_trunc('month',current_date - interval '12 month')),0) as AVG_thang_cungky

         
	from base tb1
	group by 1,2
 ) b on a.masanpham= b.masanpham
     and lower(a.chinhanh)= lower(b.chinhanh)
full outer join( select t1.*,t2.fcvalues,t1.soluong/t1.soluongtong*t2.fcvalues fc_chinhanh
                    from
                        (
                        select tt1.*,tt2.soluong soluongtong
                        from (select chinhanh,masanpham,sum(soluong)soluong from base where date(ngaychungtu) >= current_date-30 group by 1,2 ) tt1
                        left join (select masanpham,sum(soluong)soluong from base where date(ngaychungtu) >= current_date-30 group by 1 ) tt2 on tt1.masanpham=tt2.masanpham

                        ) t1
                    left join 
                        (
                          select t5.month,t5.masp,sum(t5.fcvalues) fcvalues 
                          from `spatial-vision-343005.staging.d_forecast_sc` t5
                          right join base_max_revise_fc t6 on t5.masp=t6.masp
                                                          and t5.month=t6.month
                                                          and t5.version= t6.max_version          
                        where date(t5.month) = date(date_trunc(current_date,month))  group by 1,2
                        ) t2
                    on t1.masanpham= t2.masp
                               
                
                
                
                ) tb2 on COALESCE(a.masanpham,b.masanpham) = tb2.masanpham 
                      and lower(COALESCE(a.chinhanh,b.chinhanh))= lower( tb2.chinhanh)
left join base_name c on COALESCE(a.masanpham,b.masanpham,tb2.masanpham) =c.masanpham

left join staging.d_master_sanpham t3 on COALESCE(a.masanpham,b.masanpham,tb2.masanpham)=t3.masp

)

select * from result

  );

Create or replace table `warehouse.f_baocao_tonkho_hangngay_page_tonkhotonghop`

copy `staging_temp.f_baocao_tonkho_hangngay_page_tonkhotonghop_temp`;

End;