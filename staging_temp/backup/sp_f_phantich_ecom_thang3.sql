CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_phantich_ecom_thang3()
BEGIN 
  TRUNCATE TABLE staging_temp.f_phantich_ecom_thang3_temp;

 INSERT INTO staging_temp.f_phantich_ecom_thang3_temp(

-- Create table staging_temp.f_phantich_ecom_thang3_temp
-- partition by date(ngaychungtu)
-- as

with tuyen123 as
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

bang_khachhang as
(
 select
  makhdms,
  sum(doanhsochuavat) as doanhsochuavat, 
  sum (doanhsocovat) as doanhsocovat
  from `spatial-vision-343005.staging.f_sales`
  where ngaychungtu < '2023-01-11' and doanhsocovat >0 and trangthai = 'Đã Phát Hành'
  group by 1
)
,
bang_khachhang_ecom as
(
 select
  makhdms,
  sum(doanhsochuavat) as doanhsochuavat, 
  sum (doanhsocovat) as doanhsocovat
  from `spatial-vision-343005.staging.f_sales`
  where ngaychungtu < '2023-01-11' and manv = 'TMDT_001' and doanhsocovat >0 and trangthai = 'Đã Phát Hành'
  group by 1
) 
,
bang_sale as
(
  select 
  ngaydatdon,
  ngaychungtu,
  sodondathang,
  macongtycn,
  makhdms,
  tenkhachhang,
  masanpham,
  tensanphamnb,

  makenhkh,
  makenhphu,
  maphanloaihco,
  manv,
  tencvbh,
  -- row_number()over (partition by sodondathang order by ngaychungtu asc) as loc,
  sum(doanhsochuavat) as doanhsochuavat, 
  sum (doanhsocovat) as doanhsocovat
  from `spatial-vision-343005.staging.f_sales`
  group by 1,2,3,4,5,6,7,8,9,10,11,12,13
)
,
nghivan_datho1 as
(
  select 
  a.ip_address, 
  count(distinct b.makhdms) as sl_kh
  FROM `spatial-vision-343005.staging.f_crawl_logecommerce` a
  left join bang_sale b on a.code_dms = b.sodondathang
  group by 1
)
,
nghivan_datho as
(
select ip_address, 
  case when sl_kh >= 3 then 'đặt hộ' else null end as is_datho
from nghivan_datho1 
)
,

result as
(
  SELECT a.customer_name,a.ip_address, a.created_at,a.device_type,a.code_id,a.code_dms,title_page,a.inserted_at,
  b.ngaydatdon,
  b.ngaychungtu,
  b.sodondathang,
  b.macongtycn,
  b.tenkhachhang,
  b.makhdms,
  b.masanpham,
  b.tensanphamnb,
  c.makhdms as kh_dacodh,
  d.makhdms as kh_dadat_ecom,
  b.makenhkh, 
  b.makenhphu,
  b.maphanloaihco,
  b.doanhsochuavat,
  b.doanhsocovat,
  b.manv,
  b.tencvbh,
  e.is_datho,
  f.datatype,
  extract (hour from b.ngaydatdon) as gio_datdon,
  extract (day from b.ngaydatdon) as ngay_datdon,
  extract (DAYOFWEEK from b.ngaydatdon) as thu_datdon,
  case when c.makhdms is null then b.makhdms else null end as kh_moicodh,
  case when e.is_datho is not null then b.makhdms else null end as kh_datho,
  case when e.is_datho is not null then b.sodondathang else null end as dh_datho,
  case when extract (hour from b.ngaydatdon) >= 19 or extract (hour from b.ngaydatdon) < 7 then 'đặt ngoài giờ'
       when extract (DAYOFWEEK from b.ngaydatdon) = 7 or extract (DAYOFWEEK from b.ngaydatdon) = 1 then 'đặt ngoài giờ' else null end as dh_datngoaigio,

  row_number()over (partition by extract (month from a.created_at), b.makhdms order by a.created_at asc) as loc,
  row_number()over (partition by d.makhdms order by a.created_at asc) as loc_ecom,
  -- row_number()over (partition by c.makhdms order by a.created_at asc) as loc_ecom,

  case when b.doanhsocovat >= 250000 then 'Đạt 1.5%' else 'Không đạt CK' end as kh_ck,
  case when b.doanhsocovat >= 250000 then b.doanhsocovat * 0.015 else 0 end as tinh_chietkhau,

  FROM `spatial-vision-343005.staging.f_crawl_logecommerce` a
  left join bang_sale b on a.code_dms = b.sodondathang
  left join bang_khachhang c on b.makhdms = c.makhdms
  left join bang_khachhang_ecom d on b.makhdms = d.makhdms
  left join nghivan_datho e on a.ip_address = e.ip_address
  left join tuyen123 f on b.makhdms = f.custid

  where 
  b.ngaychungtu >= '2023-01-11' and b.ngaychungtu <= '2023-03-31' and b.sodondathang is not null
)
select *, 
case 
  when loc <= 10 and tinh_chietkhau <= 100000 then tinh_chietkhau 
  when loc <= 10 and tinh_chietkhau > 100000 then 100000
  when loc > 10 then 0 end as sotien_chietkhau,

 row_number()over (partition by kh_moicodh order by created_at asc) as loc_khmoi,

from result --where makhdms = 'P5109-0135'
  );
Create or replace table `warehouse.f_phantich_ecom_thang3`

copy `staging_temp.f_phantich_ecom_thang3_temp`;

End;