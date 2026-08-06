-- ==========================================================================
-- Routine Name : sp_f_doanhso_sanluong_theokhachhang
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2024-09-17 08:39:01.022000+00:00
-- Last Altered : 2024-09-17 08:39:01.022000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_doanhso_sanluong_theokhachhang()
BEGIN
  TRUNCATE TABLE staging_temp.f_doanhso_sanluong_theokhachhang_temp;

 INSERT INTO staging_temp.f_doanhso_sanluong_theokhachhang_temp(

-- Create or replace table staging_temp.f_doanhso_sanluong_theokhachhang_temp
-- partition by date(ngaychungtu)
-- as
with
tuyen123 as
(
select * from
(
  select custid, datatype, row_number() over (partition by custid order by datatype asc) as loc from
  (

  SELECT custid, routetype, 1 as datatype from `staging.sync_dms_srm` where routetype in ('B','C','D') and delroutedet is false
  UNION ALL
  SELECT custid, routetype, 2 as datatype from `staging.sync_dms_srm` where routetype in ('F') and delroutedet is false
  UNION ALL
  SELECT custid, routetype, 3 as datatype from `staging.sync_dms_srm` where routetype in ('A') and delroutedet is false
  )
)
where loc = 1
)
,
leadtime as(

select custid, avg (full_leadtime) as avgfullleadtime  from  `spatial-vision-343005.warehouse.f_leadtime_new_detail1`
where status_dv = 'Đã giao hàng'
group by 1
)
,
raw_sales as (
select
t1.ngaychungtu,
t1.makhdms,
t1.makhcu,
t1.sodondathang,
t1.soluong,
t1.doanhsochuavat,
t1.masanpham,
case when t2.ordernbr is not null then 'Y' else 'N' end as is_ecom1,
case when t2.ordernbr is not null then t2.ordernbr else null end as is_ecom,
case when t2.ordernbr is  null then t1.sodondathang else null end as is_original,
case when t2.ordernbr is not null then t1.soluong else 0 end as is_ecom_sl,
case when t2.ordernbr is  null then t1.soluong else 0 end as is_original_sl,
case when t2.ordernbr is not null then t1.doanhsochuavat else 0 end as is_ecom_ds,
case when t2.ordernbr is  null then t1.doanhsochuavat else 0 end as is_original_ds,
t1.inserted_at,
from `spatial-vision-343005.staging.f_sales` t1
left join  `spatial-vision-343005.staging.sync_dms_pda_so`  t2 on t1.makhdms = t2.custid and t1.sodondathang = t2.ordernbr and t2.crtd_user = 'TMDT_001'
where
   LEFT(t1.masanpham,1) != 'V'
      AND t1.manv NOT IN ( 'GH001', 'MA001', 'MA002', 'QUYNHPTA')
     -- and a.phanam not in ( 'PHA NAM')
      AND makenhkh not in ( 'NB','OTH_LAB')
),
result as (
select
a.makhdms,
a.ngaychungtu,
a.masanpham,
g.descr,
g.descr1,
a.sodondathang as total_dh,
a.doanhsochuavat as total_ds,
a.is_ecom as sl_dhecom,
a.is_original as sl_dhtt,
a.is_ecom_ds as ds_ecom,
a.is_original_ds as ds_tt,
ifnull(b1.custname,b.custname) as tenkhachhang,
ifnull(b1.territorydescr,b.territorydescr) tenkhuvuc,
ifnull(b1.channel,b.channel) as kenh,
ifnull(b1.shoptype,b.shoptype) as kenhphu,
ifnull(b1.active,b.active) active,
ifnull(b1.branchid,b.branchid) as branchid,
ifnull(b1.statedescr,b.statedescr) as statedescr,
ifnull(b1.districtdescr,b.districtdescr) as districtdescr,
ifnull(b1.wardname,b.wardname) as wardname,
cast(b.legaldate as date) as thoihanhieulucgdpgpp,
Case when ifnull(b1.legaldate,b.legaldate) is not null then 'Y' else 'N' end as is_co_gpp,
ifnull(b1.taxregnbr,b.taxregnbr) as taxregnbr,
ifnull(b1.classid,b.classid) as classid,
ifnull(b1.hcotypeid,b.hcotypeid) as hcotypeid,
case when lower(ifnull(b1.custname,b.custname)) like '%fpt long châu%' then '1.Long Châu'
     when lower(ifnull(b1.custname,b.custname)) like '%pharmacity%' then '2.Phamacity'
     when lower(ifnull(b1.custname,b.custname)) like '%trung sơn%' then '3.Trung Sơn'
     when lower(ifnull(b1.custname,b.custname)) like '%medx%' then '4.MedX'
     when lower(ifnull(b1.custname,b.custname)) like '%guardian%' then '5.Guardian'
     when lower(ifnull(b1.custname,b.custname)) like '%an khang%' then '6.An Khang'
     when ifnull(b1.custid,b.custid) = '003589' then '7.ECE - Ecommerce enable'
     else 'others' end as group_khach_hang,
ifnull(b1.businessscope,b.businessscope) as businessscope,
-- case when c.makhdms is not null then 'Y' else 'N' end iscaresoft_customer,
'N' as iscaresoft_customer,
case when d.customer_code is not null then 'Y' else 'N' end activate_customer,
ifnull(b1.terms,b.terms) as terms,
ifnull(b1.phone,b.phone) phone,
ifnull(b1.emailinvoice,b.emailinvoice) emailinvoice,
ifnull(b1.custidinvoice,b.custidinvoice) as custidinvoice,
ifnull(b1.custnameinvoice,b.custnameinvoice) as custnameinvoice,
e.avgfullleadtime,
f.datatype as tuyen123,
a.inserted_at,
from raw_sales a
LEFT JOIN `staging.d_master_khachhang` b on a.makhdms = b.custid and a.ngaychungtu >='2023-01-01'
LEFT JOIN `staging.d_master_khachhang2022` b1 on a.makhdms = b1.custid and a.ngaychungtu <'2023-01-01'
-- left join (select distinct makhdms from `staging.f_caresoft_contact_detail`) c on a.makhdms= c.makhdms
left join (select distinct customer_code from `spatial-vision-343005.staging.f_crawl_activate_ecom`) d on a.makhdms =  d.customer_code
left join leadtime e on a.makhdms = e.custid
left join tuyen123 f on a.makhdms = f.custid
LEFT JOIN `staging.d_dms_master_invtid` g on g.invtid = a.masanpham
-- group by all
)

select * from result

  );

Create or replace table `warehouse.f_doanhso_sanluong_theokhachhang`

copy `staging_temp.f_doanhso_sanluong_theokhachhang_temp`;

End;
