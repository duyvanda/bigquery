CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_cx_chamsoc_kenhtp()
BEGIN 
 
 TRUNCATE TABLE staging_temp.f_cx_chamsoc_kenhtp_temp;

 INSERT INTO `staging_temp.f_cx_chamsoc_kenhtp_temp`

(   

-- Create or replace table `staging_temp.f_cx_chamsoc_kenhtp_temp` as

with doanhso_kh as
(
  select 
    makhdms, 
    date(date_trunc(ngaychungtu,month)) as thang_filter,
    extract(month from ngaychungtu) as thang,
    extract(month from ngaychungtu) || '/'||  extract(year from ngaychungtu) as thang_nam,
    case when manv = 'TMDT_001' then 'online' else 'offline' end as online_offline,
    sum(doanhsochuavat) as ds_chuavat,
    sum(doanhsocovat) as ds_covat,
  from `spatial-vision-343005.staging.f_sales`
  where makenhkh = 'TP' AND ngaychungtu >= '2023-04-01'
  group by 1,2,3,4,5
)

  SELECT a.*,b.thang,b.thang_nam,b.thang_filter, b.ds_chuavat, b.ds_covat,b.online_offline
  FROM `spatial-vision-343005.staging.d_cx_chamsoc_kenhtp` a
  left join doanhso_kh b on a.makhachhang = b.makhdms



);

Create or replace table `warehouse.f_cx_chamsoc_kenhtp`

copy `staging_temp.f_cx_chamsoc_kenhtp_temp`;

END;