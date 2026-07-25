CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_tracking_kpi_pcl_tichluy()
BEGIN 


 TRUNCATE TABLE staging_temp.f_tracking_kpi_pcl_tichluy_temp;

 INSERT INTO `staging_temp.f_tracking_kpi_pcl_tichluy_temp`
(

-- Create  or replace table `staging_temp.f_tracking_kpi_pcl_tichluy_temp` as 
with sales as 
(
  select 
  6 as stt,
  'KHÁC' as datatype,
  a.makhdms as custid,
  a.makhdms as custid_kh,
  b.pubcustid,
  b.pubcustname,
  b.custname,
  a.makenh_moi as channel,
  b.shoptype,
  b.statedescr,
  b.shortterritorydescr,
  b.hcoid,
  b.hcotypeid,
  b.branchid,
  b.branchname,
  ifnull(c.ma_crm,a.crm) as ma_crm,
  d.tencvbh as tenquanlytt,
  date(date_trunc(a.ngaychungtu,month)) as thang,
  sum(a.doanhsochuavat) as doanhsochuavat,
  sum(a.kh_total) as kh_total
  from `warehouse.f_sales_crs` a
  LEFT JOIN `staging.d_master_khachhang` b on a.makhdms =b.custid
  LEFT JOIN (select distinct mahcochung,kenh,date(thang) as thang,ma_crm from `staging.d_kpi_tan_tam`) c on c.mahcochung = b.pubcustid and c.kenh = a.makenh_moi and c.thang=date(date_trunc(a.ngaychungtu,month))
  LEFT JOIN `staging.d_users` d on d.manv = ifnull(c.ma_crm,a.crm)
  where ngaychungtu >= '2023-06-01' and a.makenh_moi in ('PCL')
  group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
  -- having sum(a.doanhsochuavat) <> 0
)
,

ngay_tham_gia_diamond as 
(
SELECT ma_kh_dms,date(doanh_so_tinh_tu) as ngay_tham_gia FROM `spatial-vision-343005.staging.d_manual_danhsach_khachhang_diamond` 
)
,
hang_hien_tai as (
SELECT ma_kh,hang_kh,ngay_tham_gia

FROM `spatial-vision-343005.warehouse.f_danhsach_kh_commitment` 
 qualify row_number() over(partition by ma_kh order by ngaychungtu desc) =1

)
,
ds_th_diamond as 
(
SELECT 
    1 as stt,
    'DIAMOND' nangkey,
    a.ma_kh_dms as custid,
    a.ma_kh_dms as custid_kh,
    b.pubcustid, 
    b.pubcustname,
    b.custname,
    b.channel,
    b.shoptype,
    b.statedescr,
    b.shortterritorydescr,
    b.hcoid,
    b.hcotypeid,
    b.branchid,
    b.branchname,
    ifnull(c.ma_crm,a.supid) as ma_crm,
    d.tencvbh as tenquanlytt,
    date(a.thang) as thang,
    sum(doanhsochuavat) as doanhsochuavat ,
    0 ke_hoach
  
  FROM `spatial-vision-343005.warehouse.f_theodoi_danhsach_diamond` a 
  LEFT JOIN `staging.d_master_khachhang` b on a.ma_kh_dms =b.custid
  JOIN (select distinct mahcochung,kenh,date(thang) as thang,ma_crm from `staging.d_kpi_tan_tam` where trim(upper(nangkey)) = 'DIAMOND') c on c.mahcochung = b.pubcustid and c.kenh = a.channel and c.thang=date(a.thang)
  LEFT JOIN `staging.d_users` d on d.manv = ifnull(c.ma_crm,a.supid)
 where b.active ='Active'
 group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
)
,
ds_th_commitment as 
(
SELECT 
    2 as stt,
    'COMMITMENT' nangkey,
    a.ma_kh as custid,
    a.ma_kh as custid_kh,
    b.pubcustid, 
    b.pubcustname,
    b.custname,
    b.channel,
    b.shoptype,
    b.statedescr,
    b.shortterritorydescr,
    b.hcoid,
    b.hcotypeid,
    b.branchid,
    b.branchname,
    ifnull(c.ma_crm,a.supid) as ma_crm,
    d.tencvbh as tenquanlytt,
    date(date_trunc(ngaychungtu,month)) as thang ,
    sum(doanhsochuavat) as doanhsochuavat ,
    0 ke_hoach,

 FROM `spatial-vision-343005.warehouse.f_danhsach_kh_commitment` a
 LEFT JOIN `staging.d_master_khachhang` b on a.ma_kh =b.custid
 JOIN (select distinct mahcochung,kenh,date(thang) as thang,ma_crm from `staging.d_kpi_tan_tam` where trim(upper(nangkey)) <> 'DIAMOND') c on 
          c.mahcochung = b.pubcustid and c.kenh = a.channel and c.thang=date(date_trunc(ngaychungtu,month))
  LEFT JOIN `staging.d_users` d on d.manv = ifnull(c.ma_crm,a.supid)
where b.active ='Active'
 group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18
)
,

kh_diamond_commitment as
(
select  

 a.kenh,
 a.ma_crm,
 date(a.thang) as thang,
 sum(target) as ke_hoach
from `staging.d_kpi_tan_tam` a 
where nangkey is not null
group by 1,2,3
),

kpi_conlai as (
select a.*except(doanhsochuavat,kh_total),
0 as doanhsochuavat,
a.kh_total - ifnull(b.ke_hoach,0) as kh_total
 from sales a
 LEFT JOIN kh_diamond_commitment b on b.kenh = a.channel and b.ma_crm =a.ma_crm and a.thang =b.thang
 where custid is null
),

danh_sach_kh as (
select 
  a.mahcochung,
  a.thang,
  a.kenh,
  'DIAMOND' as nangkey,
  1 as stt,
  a.ma_crm,
  sum(a.target) as ke_hoach,
from `staging.d_kpi_tan_tam` a 
where trim(upper(nangkey)) = 'DIAMOND'
group by 1,2,3,4,5,6
UNION ALL 
select 
  a.mahcochung,
  a.thang,
  a.kenh,
  'COMMITMENT' as nangkey,
  2 as stt,
  a.ma_crm,
  sum(a.target) as ke_hoach,
from `staging.d_kpi_tan_tam` a 
where trim(upper(nangkey)) <> 'DIAMOND'
group by 1,2,3,4,5,6
UNION ALL 
select 
  a.mahcochung,
  a.thang,
  a.kenh,
  'Gold (Cam Kết)' as nangkey,
  3 as stt,
  a.ma_crm,
  sum(a.target) as ke_hoach,
from `staging.d_kpi_tan_tam` a 
where trim(upper(nangkey)) like '%GOLD%'
group by 1,2,3,4,5,6
UNION ALL 
select 
  a.mahcochung,
  a.thang,
  a.kenh,
  'Platinum (Tận tâm)' as nangkey,
  4 as stt,
  a.ma_crm,
  sum(a.target) as ke_hoach,
from `staging.d_kpi_tan_tam` a 
where  trim(upper(nangkey)) like '%PLATINUM%'
group by 1,2,3,4,5,6
)
,
mapping_ds_kh_diamond_commitment as (
select 
    a.stt,
    a.nangkey,
    b.custid,
    cast(null as string) as custid_kh,
    a.mahcochung, 
    b.pubcustname,
    b.custname,
    a.kenh as channel,
    b.shoptype,
    b.statedescr,
    b.shortterritorydescr,
    b.hcoid,
    b.hcotypeid,
    b.branchid,
    b.branchname,
    a.ma_crm,
    d.tencvbh as tenquanlytt,
    date(a.thang) as thang,
    0 as doanhsocovat,
    Case when custid is not null then ke_hoach / count(custid) over(partition by mahcochung,thang,channel,nangkey) 
          else ke_hoach end as ke_hoach
from danh_sach_kh a
   LEFT JOIN `staging.d_master_khachhang` b on a.mahcochung = b.pubcustid and b.channel =trim(a.kenh)
   LEFT JOIN `staging.d_users` d on d.manv =a.ma_crm
   where b.active ='Active'
   


),
result as (

  select * 
  from mapping_ds_kh_diamond_commitment

   UNION ALL
   select * from ds_th_diamond

   UNION ALL
   select * from ds_th_commitment

   UNION ALL 
   select 
   3 as stt,
   'Gold (Cam Kết)' as nangkey,
   *except(stt,nangkey) from ds_th_commitment where custid_kh in (select custid from mapping_ds_kh_diamond_commitment where nangkey ='Gold (Cam Kết)' )

      UNION ALL 
   select 
   4 as stt,
   'Platinum (Tận tâm)' as nangkey,
   *except(stt,nangkey) from ds_th_commitment where custid_kh in (select custid from mapping_ds_kh_diamond_commitment where nangkey ='Platinum (Tận tâm)' )

   UNION ALL
   select * from kpi_conlai

   UNION ALL
   select 
    a.*except(doanhsochuavat,kh_total),
    a.doanhsochuavat,
    0 as kh_total
  from sales a
  LEFT JOIN mapping_ds_kh_diamond_commitment b on b.custid =a.custid and b.thang = date(a.thang) and b.nangkey in ('DIAMOND','COMMITMENT')
  where concat(b.custid,b.thang) is null

  )

  select a.*,
  Case when a.nangkey in ('COMMITMENT') then b.ngay_tham_gia
        when a.nangkey in ('DIAMOND') then c.ngay_tham_gia
        else null end as ngay_tham_gia,
  b.hang_kh,
  timestamp(current_datetime("+7")) as inserted_at
 
   from result a 
   LEFT JOIN hang_hien_tai b on a.custid = b.ma_kh and a.nangkey in ('COMMITMENT')
   LEFT JOIN ngay_tham_gia_diamond c on  a.custid = c.ma_kh_dms and a.nangkey in ('DIAMOND')

);

Create or replace table `warehouse.f_tracking_kpi_pcl_tichluy`

copy `staging_temp.f_tracking_kpi_pcl_tichluy_temp`;


END;