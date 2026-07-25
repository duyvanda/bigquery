CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_viengtham_hcp()
BEGIN 
  TRUNCATE TABLE staging_temp.f_viengtham_hcp_temp;

 INSERT INTO staging_temp.f_viengtham_hcp_temp(

-- Create table staging_temp.f_viengtham_hcp_temp
-- as
with data as (SELECT a.*except(rsmname,asmname,supname,slsname)
,b.result
,b.notmeet
,b.reason
,b.noidungcall
,b.sanpham
,b.question
,c.tencvbh as slsname
,c.tenquanlytt as supname
,c.tenquanlykhuvuc as asmname
,c.tenquanlyvung as rsmname
,c.supid as ma_crm
,c.asm as ma_scrm
,left(c.rsmid,6) as ma_ncxm
,d.channel
FROM `spatial-vision-343005.staging.sync_dms_etc_workingplan`  a
LEFT JOIN `staging.sync_dms_etc_workingresult` b 
on a.hcpid=b.hcpid and a.custid=b.custid and a.slsperid=b.slsperid and date(a.ngaydicall) = date(b.visitdate)
LEFT JOIN `staging.d_users` c on a.slsperid =c.manv 
LEFT JOIN `staging.d_master_khachhang` d on d.custid =a.custid
)

select *,
Case when quanlyduyet ='Đã duyệt' then 1 else 0 end as daduyet,
Case when notmeet ='Đã gặp' then custid else null end as hco_daviengtham,
Case when notmeet ='Đã gặp' then hcpid else null end as hcp_daviengtham,
Case when result ='Đạt' then 1 else 0 end as sl_kq_dat,
 
 from data

   );
Create or replace table `warehouse.f_viengtham_hcp`

copy `staging_temp.f_viengtham_hcp_temp`;

End;