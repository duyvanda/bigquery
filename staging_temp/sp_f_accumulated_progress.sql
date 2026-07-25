CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_accumulated_progress()
BEGIN 
  TRUNCATE TABLE staging_temp.f_accumulated_progress_temp;

 INSERT INTO staging_temp.f_accumulated_progress_temp(
with max_d_accumulatedregis as 
(
  select accumulateid ,custid ,max(crtd_datetime) as crtd_datetime 
  from `spatial-vision-343005.staging.d_accumulatedregis` group by 1,2
),

d_accumulatedregis as 
(
  select a.* from `spatial-vision-343005.staging.d_accumulatedregis` a
  JOIN max_d_accumulatedregis b on a.accumulateid =b.accumulateid and a.crtd_datetime = b.crtd_datetime 
  and a.custid =b.custid
),

tuyen_dms_moinhat as 
(
with data_tuyen as (
SELECT custid,slsperid,crtd_datetime,
Case when routetype in ('B','D') then 1 else 2 end as routetype,
FROM `spatial-vision-343005.staging.sync_dms_srm` 
where delroutedet is false --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
)
select * from (
select *,row_number() over (partition by custid order by routetype asc,crtd_datetime desc) as loc  from data_tuyen
)
where loc =1


),


result as (
SELECT  t2.accumulateid
,t2.custid makhdms
,t4.custname tenkhachhang
,
Case when extract(month from t1.orderdate) = 1 then t1.accumulatedvalue else 0 end as accumulatedvalue_t1,
Case when extract(month from t1.orderdate) = 2 then t1.accumulatedvalue else 0 end as accumulatedvalue_t2,
Case when extract(month from t1.orderdate) = 3 then t1.accumulatedvalue else 0 end as accumulatedvalue_t3,
Case when extract(month from t1.orderdate) = 4 then t1.accumulatedvalue else 0 end as accumulatedvalue_t4,
Case when extract(month from t1.orderdate) = 5 then t1.accumulatedvalue else 0 end as accumulatedvalue_5,
Case when extract(month from t1.orderdate) = 6 then t1.accumulatedvalue else 0 end as accumulatedvalue_t6,
Case when extract(month from t1.orderdate) = 7 then t1.accumulatedvalue else 0 end as accumulatedvalue_t7,
Case when extract(month from t1.orderdate) = 8 then t1.accumulatedvalue else 0 end as accumulatedvalue_t8,
Case when extract(month from t1.orderdate) = 9 then t1.accumulatedvalue else 0 end as accumulatedvalue_t9,
Case when extract(month from t1.orderdate) = 10 then t1.accumulatedvalue else 0 end as accumulatedvalue_t10,
Case when extract(month from t1.orderdate) = 11 then t1.accumulatedvalue else 0 end as accumulatedvalue_t11,
Case when extract(month from t1.orderdate) = 12 then t1.accumulatedvalue else 0 end as accumulatedvalue_t12,

t1.accumulatedvalue
,ifnull(date(t1.orderdate),(select * from `staging.d_current_table`) ) as orderdate
,t1.origordernbr
,t1.sumdiscamt
,t3.slsperid as crtd_user
,t2.purchaseagreementvalue
-- ,t3.tencvbh tencvbh1
,t5.supid as ma_crm,
t5.asm as ma_scrm,
LEFT(t5.rsmid,6)  as ma_ncxm
,t5.tencvbh tencvbh
,t5.tenquanlytt as tenquanlytt
,t5.tenquanlykhuvuc as tenquanlykhuvuc
,t5.tenquanlyvung as tenquanlyvung
,t6.descr
-- ,t7.trangthaihoatdong,
,t4.channel,
t4.branchid,
t4.statedescr as tinhtp
FROM d_accumulatedregis t2 
LEFT join `staging.d_accumulated_progress` t1 
                                    on t1.accumulateid= t2.accumulateid
                                    and t1.custid= t2.custid and  orderdate >='2023-01-01'
LEFT JOIN tuyen_dms_moinhat t3 on t3.custid =t2.custid
-- LEFT JOIN `view_report.d_phanquyen_trading_gmail` t7 on t7.manv = t3.slsperid
left join `spatial-vision-343005.staging.d_users` t5 on t3.slsperid=t5.manv
left join `spatial-vision-343005.staging.d_master_khachhang` t4 on t2.custid = t4.custid 
left join `spatial-vision-343005.staging.d_accumulated` t6 on t2.accumulateid = t6.accumulateid
where t2.accumulateid ='202301-TL-QD01-NT-QT-PKN-PKQ'
)

select * from result 


  );
Create or replace table `warehouse.f_accumulated_progress`

copy `staging_temp.f_accumulated_progress_temp`;

End;