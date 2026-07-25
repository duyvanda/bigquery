CREATE VIEW `spatial-vision-343005.warehouse.view_mds_online_rc`
AS with ecom_data_pda as (
  SELECT
  distinct
  custid,
  'TMDT_001' as crtd_user
  from
  `spatial-vision-343005.staging.sync_dms_pda_so`
  WHERE
  (
  crtd_user = 'TMDT_001'
  or slsperid = 'TMDT_001'
  )
  and crtd_datetime >= '2024-06-10'
)

, activa_zalo as
(
select distinct customer_code from staging.f_crawl_activate_ecom where date(created_at)>= '2024-06-10'
)

, activa_zalo_old as
(
select distinct customer_code from staging.f_crawl_activate_ecom where date(created_at) < '2024-06-10'
)

, order_ecom as

(
  SELECT
  distinct
  ordernbr,
  custid,
  'TMDT_001' as crtd_user
  from
  `spatial-vision-343005.staging.sync_dms_pda_so`
  WHERE
  (
  crtd_user = 'TMDT_001'
  or slsperid = 'TMDT_001'
  )
  and crtd_datetime >= '2024-06-10'
)

, ds_ecom_theo_kh as

(
  select makhdms, sum(doanhsochuavat) as ds_ecom from staging.f_sales a
  INNER JOIN order_ecom b on a.sodondathang = b.ordernbr and a.makhdms = b.custid
  where date(ngaychungtu)>= '2024-06-10' and 
  
  --date(ngaychungtu)<= '2024-06-13'
  
  date(ngaychungtu)<= PARSE_DATE("%Y%m%d", @DS_END_DATE)
  group by all
)

SELECT a.*,
case when ac.customer_code is not null then 'y' else 'n' end as check_da_ket_noi_zalo,
case when aco.customer_code is not null then 'y' else 'n' end as check_da_ket_noi_zalo_truoc_1006,
case when e.custid is not null then 'y' else 'n' end as check_da_mua_onl,
300000 as gia_tri_tong_dh,
d.ds_ecom,
b.custname,
b.districtdescr,
b.statedescr,
b.shoptype,
b.channel,
b.shortterritorydescr
FROM `spatial-vision-343005.staging.d_manual_chuong_trinh_rc_mds` a
LEFT JOIN ecom_data_pda e on e.custid = a.ma_kh
LEFT JOIN activa_zalo ac on ac.customer_code = a.ma_kh
LEFT JOIN activa_zalo_old aco on aco.customer_code = a.ma_kh
LEFT JOIN ds_ecom_theo_kh d on a.ma_kh = d.makhdms

--Khach hang
LEFT JOIN `staging.d_master_khachhang`  b ON a.ma_kh = b.custid;