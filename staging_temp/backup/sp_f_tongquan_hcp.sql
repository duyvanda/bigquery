CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_tongquan_hcp()
BEGIN 
  TRUNCATE TABLE staging_temp.f_tongquan_hcp_temp;

 INSERT INTO staging_temp.f_tongquan_hcp_temp(

-- Create table staging_temp.f_tongquan_hcp_temp
-- as

with data_crs_lap_kh as ( 

  with data_crs_lap_kh as ( 
  select distinct manv as codecrscrssmoi,makenhkh as kenhphutrach from `staging.d_calendar` where makenhkh in ('CLC','INS')
)
select a.*,b.*
from (select * from 
unnest(generate_date_array('2022-01-01', '2023-12-01', INTERVAL 1 month)) as date_mapping ) a
LEFT JOIN data_crs_lap_kh b on 1=1 

),

data_lap_kh as (

with data_kh_hcp as (
SELECT slsperid,custid,hcpid,month,year,
terrname,
statename,
channelname,
kenhphu,
custname,hcpname,
thoigian,
date_trunc(date(ngaydicall),month) as date_filter,
count(distinct thoigian) as sl_kh_daxaclap,
count(date(ngaydicall)) as sl_call_xaclap,
Case when  quanlyduyet ='Đã duyệt' then thoigian
else null end as sl_kh_ql_duyet
FROM `spatial-vision-343005.staging.sync_dms_etc_workingplan` 
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,quanlyduyet)

select slsperid,custid,hcpid,month,year,
terrname,
statename,
channelname,
kenhphu,
thoigian, -- Bổ sung để đếm sl kế hoạch
custname,hcpname,date_filter,
sl_kh_ql_duyet,
sum(sl_kh_daxaclap) as sl_kh_daxaclap,
sum(sl_call_xaclap) as sl_call_xaclap
from data_kh_hcp group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14


),

data_hcp_result as 
(

with hcp_result as (
select 

hcpid ,custid ,slsperid ,date_trunc(date(visitdate),month) as month_mapping,
Case when notmeet ='Đã gặp' then count(notmeet)
else 0 end as sl_call_checkin,
Case when result ='Đạt' then count(result)
else 0 end as sl_call_dat
from `staging.sync_dms_etc_workingresult`
group by 1,2,3,4,notmeet,result
) 

select hcpid ,custid ,slsperid ,month_mapping,sum(sl_call_checkin) as sl_call_checkin, sum(sl_call_dat)  as sl_call_dat 
from hcp_result 
group by 1,2,3,4 

),


result as (

select a.*except(date_filter),
d.custid as custid_daviengtham,
d.hcpid as hcpid_daviengtham,
Case when d.sl_call_checkin is null then 0 else  d.sl_call_checkin end as sl_call_checkin,
Case when d.sl_call_dat is null then 0 else d.sl_call_dat end as sl_call_dat,
ifnull(a.date_filter,b.date_mapping) as date_filter,
b.codecrscrssmoi,
Case when b.codecrscrssmoi is null then 'Không có trong danh sách CRS và đã lập KH'
    when  a.slsperid is null then 'Có trong danh sách CRS và không lập kế hoạch'
    when a.slsperid = b.codecrscrssmoi then 'Có trong danh sách CRS và đã lập kế hoạch'
    else null end as is_phanloai,
ifnull(a.slsperid,b.codecrscrssmoi) as slsperid_new,
c.tencvbh as slsname,
c.tenquanlytt as supname,
c.tenquanlykhuvuc as asmname,
c.tenquanlyvung as rsmname,
c.supid as ma_crm,
c.asm as ma_scrm,
Left(c.rsmid,6) as ma_ncxm
 from data_lap_kh a 
FULL JOIN data_crs_lap_kh b on a.slsperid =b.codecrscrssmoi and a.date_filter =b.date_mapping
LEFT JOIN `staging.d_users` c on ifnull(a.slsperid,b.codecrscrssmoi) =c.manv 
LEFT JOIN data_hcp_result d on ifnull(a.slsperid,b.codecrscrssmoi) = d.slsperid and a.date_filter =d.month_mapping and a.custid =d.custid and a.hcpid =d.hcpid
)

select * from result
  );
Create or replace table `warehouse.f_tongquan_hcp`

copy `staging_temp.f_tongquan_hcp_temp`;

End;