CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_hang_can_date()
BEGIN 
 
TRUNCATE TABLE staging_temp.f_hang_can_date_temp;

INSERT INTO `staging_temp.f_hang_can_date_temp`

(   
-- Create or replace  table `staging_temp.f_hang_can_date_temp`
-- partition by date(orderdate)
-- cluster by custid,ordernbr,channel,ma_crs
-- as

with don_co as

(
  with don_co as
  (
  select distinct macongtycn,sodondathang,makhdms,sodontrahang,mahd,ngaychungtu from `staging.f_sales` where ngaychungtu >='2023-01-01' and kieudonhang ='CO'
  )
  ,
  don_in as 
  (
  select distinct sodondathang,sodontrahang,ngaychungtu from `staging.f_sales` where ngaychungtu >='2023-01-01' and kieudonhang ='IN'
  )

  select a.macongtycn,a.sodondathang,mahd,a.ngaychungtu,a.makhdms,c.remark,
  Case when date_trunc(a.ngaychungtu,month) = date_trunc(b.ngaychungtu,month) then 'Y' else 'Hàng trả lại (CO,OO khác tháng)' end as is_check_cung_thang
  from don_co a 
  LEFT JOIN don_in b on a.sodontrahang = b.sodondathang
  LEFT JOIN `staging.sync_dms_so` c on c.branchid =a.macongtycn and c.ordernbr = a.mahd

),

don_in as
(
  with dms_dv as 
  (
    select  
      branchid,
      batnbr,
      sequence,
      ordernbr,

      slsperid as slsperid_dv,	
      status as status_dv,	
      crtd_datetime as crtd_datetime_dv,
      crtd_user as crtd_user_dv,
      lupd_datetime as lupd_datetime_dv,
      inserted_at
  from `spatial-vision-343005.staging.sync_dms_dv`
  where DATE(crtd_datetime) >= "2023-01-01" 
  qualify row_number() over (partition by branchid,ordernbr order by sequence desc ) = 1
  ),

  ly_do_k_nhan_hang as 
  (
    SELECT branchid,ordernbr,note FROM `spatial-vision-343005.staging.sync_dms_delihistory` 

  qualify row_number() over (partition by branchid,ordernbr order by crtd_datetime desc ) = 1
  )

  select 
  a.branchid,
  a.ordernbr,
  b.ordernbr as mahd,
  lupd_datetime_dv as orderdate,
  b.custid,
  c.note,
  'Hàng KH không nhận' as phanloai
  from dms_dv a
  LEFT JOIN `staging.sync_dms_so`  b on a.branchid = b.branchid and a.ordernbr = b.origordernbr 
  LEFT JOIN ly_do_k_nhan_hang c on a.branchid = c.branchid and a.ordernbr = c.ordernbr
  LEFT JOIN (select distinct sodontrahang from `staging.f_sales` where trahangkhacthang is true and date(ngaychungtu)>= '2023-01-01'  ) d on d.sodontrahang = a.ordernbr
  where status_dv ='D' and d.sodontrahang is null
)
,
don_ni_oo as 

(
select
a.branchid,
a.ordernbr as ordernbr,
a.ordernbr as mahd,
a.orderdate,
a.custid, 
a.remark,
Case 
when a.ordertype in ('OO') then 'Hàng trả lại (CO,OO khác tháng)'
when a.ordertype in ('NI') and upper(remark) like '%DATE%' then 'Hàng đổi date' else 'Hàng hỏng/lỗi' end as phan_loai,
from staging.sync_dms_so a
where a.ordertype in ('NI','OO') and date(a.crtd_datetime)>= '2023-01-01' and IFNULL(lower(a.remark),'none') not like '%davac%'

),

uninon_all as 

(
  select * from don_ni_oo
  UNION ALL 
  select * from don_co where is_check_cung_thang ='Hàng trả lại (CO,OO khác tháng)'
  UNION ALL 
  select * from don_in
)

select 
a.*,
d.custname,
g.channel,
d.shoptype,
d.hcoid,
d.hcotypeid,
d.statedescr,
d.shortterritorydescr,

Case when g.channel ='MT' then b.slsperid else f.col.ma_nvbh end as ma_crs,
e.tencvbh as ten_crs,
e.supid as ma_crm,
e.tenquanlytt as ten_crm,
j.invtid,
c.descr1,
c.descr,
j.qty as lineqty,
case when b.freeitem is true then 0 else j.qty * beforevatprice end as beforevatamount,
j.omlineref as lineref,
j.lotsernbr,
j.expdate,
timestamp(current_datetime("+7")) as inserted_at
from uninon_all a
LEFT JOIN `staging.sync_dms_sod1` b
on a.branchid = b.branchid and a.mahd = b.ordernbr and b.crtd_datetime >='2023-01-01'
LEFT JOIN `staging.d_dms_master_invtid` c
on b.invtid = c.invtid
LEFT JOIN `spatial-vision-343005.staging.sync_dms_lt` j on j.branchid = b.branchid and b.ordernbr = j.ordernbr and b.lineref = j.omlineref
LEFT JOIN `staging.d_master_khachhang` d on d.custid =a.custid 
LEFT JOIN `warehouse.f_mapping_crs_bytime` f on f.custid = a.custid and date(date_trunc(date(b.crtd_datetime),month)) = date(f.thang)
LEFT JOIN `staging.d_master_khachhang_bytime` g on g.custid = a.custid and date(date_trunc(date(b.crtd_datetime),month)) = date(g.thang)
LEFT JOIN `staging.d_users` e on e.manv = (Case when g.channel ='MT' then b.slsperid else f.col.ma_nvbh end)
where  c.classid = 'Product' and d.channel not in ('NB','OTH_LAB')
and (e.tencvbh not in ('Phạm Thị Quỳnh Ảo') or e.tencvbh is null)
and d.market not like '%Không%'
and d.market !='08'
);

Create or replace table `warehouse.f_hang_can_date`

copy `staging_temp.f_hang_can_date_temp`;

END;