CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_phantich_xos_thang3()
BEGIN 
  TRUNCATE TABLE staging_temp.f_phantich_xos_thang3_temp;

 INSERT INTO staging_temp.f_phantich_xos_thang3_temp(

-- Create table staging_temp.f_phantich_xos_thang3_temp
-- partition by crtd_datetime
-- as

 with doanhso1 as
(
  select ordernbr, sum (aftervatamount) as aftervatamount
  from `spatial-vision-343005.staging.sync_dms_sod1` 
  group by 1
)
,
doanhso as
(
select *, 
  case 
  when aftervatamount < 1000000 then 'Mức 500 ngàn'
  when (aftervatamount >= 1000000 and aftervatamount < 2000000) then 'Mức 1 triệu' 
  when (aftervatamount >= 2000000 and aftervatamount < 3000000) then 'Mức 2 triệu' 
  when (aftervatamount >= 3000000 and aftervatamount < 5000000) then 'Mức 3 triệu'
  when aftervatamount >= 5000000 then 'Mức 5 triệu'
  else null end as mucdoanhso 
  from doanhso1
)


SELECT a.branchid, a.ordernbr, a.glineref, a.descr, a.descr1, a.descr2, a.descr3,Cast (a.crtd_datetime as date) as crtd_datetime,

b.freeitem,
b.invtid,
b.lineqty,
b.ordertype,
b.beforevatamount,
b.aftervatamount,
b.discamt,
b.docdiscamt,
b.groupdiscamt1,
c.makhdms,
c.tenkhachhang,
c.makenhphu,
d.mucdoanhso,

case when a.glineref = '00006' then b.invtid else null end as hangtang,
case when a.glineref = '00006' then b.lineqty else null end as soluong_hangtang,

case when c.makenhphu in ('PMC','PCL') THEN 'Nhóm 1'
when c.makenhphu in ('CTD','SI23') THEN 'Nhóm 2' else null end as nhom_kh,

case when a.crtd_datetime in ('2023-03-08') then a.ordernbr else null end as dh_8_3,


FROM `spatial-vision-343005.staging.sync_dms_omorddics` a

Join `spatial-vision-343005.staging.sync_dms_sod1` b  on a.branchid = b.branchid and a.ordernbr = b.ordernbr and a.glineref = b.lineref
join  `spatial-vision-343005.staging.f_sales` c on a.branchid = c.macongtycn and a.ordernbr = c.mahd and a.glineref = c.lineref
left join doanhso d on a.ordernbr = d.ordernbr

where (a.discidpn1 = '202303-DH-CPA10-PMC-PCL-CTD-SI' or a.discidpn2 = '202303-DH-CPA10-PMC-PCL-CTD-SI' or a.discidpn3 = '202303-DH-CPA10-PMC-PCL-CTD-SI') 
--and a.ordernbr = 'HL5-0323-01029'
  );
Create or replace table `warehouse.f_phantich_xos_thang3`

copy `staging_temp.f_phantich_xos_thang3_temp`;

End;