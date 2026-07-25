CREATE PROCEDURE `spatial-vision-343005`.staging_temp.api_ds_theo_khach_nhan(p_makhdms STRING, p_startdate STRING, p_enddate STRING, p_page STRING, p_limit STRING)
OPTIONS(
  strict_mode=false)
BEGIN


-- Default values
DECLARE current_dt DATE DEFAULT CURRENT_DATE();
-- SET PARAMS
DECLARE set_makhdms STRING DEFAULT 'None';
DECLARE set_enddate, set_startdate DATE;
DECLARE set_page NUMERIC DEFAULT 1;
DECLARE set_limit NUMERIC DEFAULT 30000;


SET set_makhdms = IF (p_makhdms = '', set_makhdms, p_makhdms);
SET set_startdate = IF (p_startdate = '', current_dt, DATE(p_startdate) );
SET set_enddate = IF (p_enddate = '', current_dt, DATE(p_enddate) );
SET set_page = IF (p_page = '', set_page, PARSE_NUMERIC(p_page) );
SET set_limit = IF (p_limit = '', set_limit, PARSE_NUMERIC(p_limit) );

IF set_makhdms = 'None'
THEN
with leadtime as 
(
  select makhdms,--date(ngaychungtu) as ngaychungtu,
  avg(full_leadtime_1) as full_leadtime 
  from `warehouse.f_baocao_daily_performance_mds_new_v2`
  where madon_tinh_gh is not null
    and date(ngaychungtu) >= set_startdate
  and date(ngaychungtu) <= set_enddate
  group by 1
)
,

data_sales as (
select 
makhdms,
-- date(ngaychungtu) as ngaychungtu,
sum(doanhsochuavat) as doanhsochuavat ,
sum(doanhsocovat) as doanhsocovat,
sum(Case when t2.ordernbr is not null then doanhsochuavat else 0 end) as doanhsochuavat_ecom,
sum(doanhsochuavat) - sum(Case when t2.ordernbr is not null then doanhsochuavat else 0 end) as doanhsochuavat_truyenthong,
count(distinct t1.sodondathang) as tong_sodh,
count(distinct Case when t2.ordernbr is not null then t1.sodondathang else null end) as tong_sodh_ecom,
count(distinct t1.sodondathang) - count(distinct Case when t2.ordernbr is not null then t1.sodondathang else null end)  as tong_sodh_truyenthong,
max(t1.inserted_at) as last_sync_time

from `spatial-vision-343005.staging.f_sales` t1
left join  `spatial-vision-343005.staging.sync_dms_pda_so`  t2 on t1.makhdms = t2.custid and t1.sodondathang = t2.ordernbr and (t2.crtd_user = 'TMDT_001' or t2.slsperid = 'TMDT_001')


where 

   LEFT(t1.masanpham,1) != 'V' 
      AND t1.manv NOT IN ( 'GH001', 'MA001', 'MA002', 'QUYNHPTA') 
     -- and a.phanam not in ( 'PHA NAM')
      AND makenhkh not in ( 'NB','OTH_LAB')
        and date(ngaychungtu) >= set_startdate
  and date(ngaychungtu) <= set_enddate
group by 1
)
--RESULTS
select 
a.makhdms,
doanhsochuavat,
doanhsocovat,
doanhsochuavat_ecom,
doanhsochuavat_truyenthong,
tong_sodh,
tong_sodh_ecom,
tong_sodh_truyenthong,
ifnull(b.full_leadtime,0) as full_leadtime,
last_sync_time,
CEIL( count(a.makhdms) over(order by a.makhdms asc) /set_limit) as page 
from data_sales a 
LEFT JOIN leadtime b on --a.ngaychungtu =b.ngaychungtu and 
a.makhdms = b.makhdms
  -- where
  -- date(a.ngaychungtu) >= if(p_startdate ='',current_dt,date(p_startdate))
  -- and date(a.ngaychungtu) <= if(p_enddate='',current_dt,date(p_enddate))
  -- qualify CEIL( count(a.ngaychungtu) over(order by a.ngaychungtu asc) /set_limit) = set_page
;

ELSE
with leadtime as 
(
  select makhdms,--date(ngaychungtu) as ngaychungtu,
  avg(full_leadtime_1) as full_leadtime 
  from `warehouse.f_baocao_daily_performance_mds_new_v2`
  where madon_tinh_gh is not null 
  and makhdms =set_makhdms
  and date(ngaychungtu) >= set_startdate
  and date(ngaychungtu) <= set_enddate
  group by 1
)
,

data_sales as (
select 
makhdms,
-- date(ngaychungtu) as ngaychungtu,
sum(doanhsochuavat) as doanhsochuavat ,
sum(doanhsocovat) as doanhsocovat,
sum(Case when t2.ordernbr is not null then doanhsochuavat else 0 end) as doanhsochuavat_ecom,
sum(doanhsochuavat) - sum(Case when t2.ordernbr is not null then doanhsochuavat else 0 end) as doanhsochuavat_truyenthong,
count(distinct t1.sodondathang) as tong_sodh,
count(distinct Case when t2.ordernbr is not null then t1.sodondathang else null end) as tong_sodh_ecom,
count(distinct t1.sodondathang) - count(distinct Case when t2.ordernbr is not null then t1.sodondathang else null end)  as tong_sodh_truyenthong,
max(t1.inserted_at) as last_sync_time

from `spatial-vision-343005.staging.f_sales` t1
left join  `spatial-vision-343005.staging.sync_dms_pda_so`  t2 on t1.makhdms = t2.custid and t1.sodondathang = t2.ordernbr and (t2.crtd_user = 'TMDT_001' or t2.slsperid = 'TMDT_001')


where 

   LEFT(t1.masanpham,1) != 'V' 
      AND t1.manv NOT IN ( 'GH001', 'MA001', 'MA002', 'QUYNHPTA') 
     -- and a.phanam not in ( 'PHA NAM')
      AND makenhkh not in ( 'NB','OTH_LAB') 
      and makhdms =set_makhdms   
  and date(ngaychungtu) >= set_startdate
  and date(ngaychungtu) <= set_enddate
group by 1
)

select 
a.makhdms,
doanhsochuavat,
doanhsocovat,
doanhsochuavat_ecom,
doanhsochuavat_truyenthong,
tong_sodh,
tong_sodh_ecom,
tong_sodh_truyenthong,
ifnull(b.full_leadtime,0) as full_leadtime,
last_sync_time,
CEIL( count(a.makhdms) over(order by a.makhdms asc) /set_limit) as page
from data_sales a 
LEFT JOIN leadtime b on --a.ngaychungtu =b.ngaychungtu and
 a.makhdms =b.makhdms
--where a.makhdms = '00001'

  -- qualify CEIL( count(a.ngaychungtu) over(order by a.ngaychungtu asc) /set_limit) = set_page
;
END IF;
END;