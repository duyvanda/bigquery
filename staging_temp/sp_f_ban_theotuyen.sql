CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_ban_theotuyen()
BEGIN 
TRUNCATE TABLE staging_temp.f_ban_theotuyen_temp;
INSERT INTO staging_temp.f_ban_theotuyen_temp(

-- Create table staging_temp.f_ban_theotuyen_temp
-- partition by date(ngaypostdon)
-- as

select
-- *,
t1.crtd_datetime ngaypostdon,
t1.ordernbr,
t1.salesrouteid,
t1.custid,
t3.custname,
t3.channel,
t3.statedescr,
t1.slsperid,
t4.firstname slspername,
t2.srdescr,
t2.slsfreq,
t2.weekofvisit,
t2.weekdate,
extract(DAYOFWEEK FROM t1.crtd_datetime) thupostdon,
-- case when SUBSTRING(weekdate,extract(DAYOFWEEK FROM t1.crtd_datetime)+1,1)='1' then 'post cùng tuyến' else 'post trái tuyến' end post_type,
Case when t2_1.custid is not null  then 'post cùng tuyến' else 'post trái tuyến' end post_type,
case when t2.routetype ='A' then 'Tuyến MDS'
    when t2.routetype ='B' then 'TUYẾN DELIGHT'
    when t2.routetype ='C' then 'TUYẾN NURTURE'
    when t2.routetype ='D' then 'TUYẾN DELIGHT & NURTURE'
    when t2.routetype ='E' then 'TUYẾN KHÔNG DÀNH CHO BÁN HÀNG' end routetype
from `spatial-vision-343005.staging.sync_dms_pda_so` t1
left join `spatial-vision-343005.staging.sync_dms_srm` t2 
                                          on t1.salesrouteid=t2.salesrouteid 
                                         -- and t1.branchid = t2.branchid
                                         -- and t1.slsperid = t2.slsperid
                                          --and t2.routetype !='F'
                                          and t1.custid=t2.custid
left join `staging.sync_dms_salesroutedet` t2_1 on t1.custid =t2_1.custid and t1.slsperid =t2_1.slsperid and date(t1.crtd_datetime) = date(t2_1.visitdate)
left join `spatial-vision-343005.staging.d_master_khachhang` t3 on t1.custid=t3.custid
left join `spatial-vision-343005.staging.d_dms_master_users` t4 on t1.slsperid=t4.username

where ordertype	='IN' 

  );

Create or replace table `warehouse.f_ban_theotuyen`

copy `staging_temp.f_ban_theotuyen_temp`;

End;