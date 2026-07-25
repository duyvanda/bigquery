CREATE VIEW `spatial-vision-343005.warehouse.view_cx_mds_tong_hop_rc`
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

, combine_data as
(
select
stt,
ma_kh,
ma_nv,
ho_va_ten_nv,
ma_ql,
ho_va_ten_ql,
'CX' as bo_phan
FROM `spatial-vision-343005.staging.d_manual_chuong_trinh_rc_cx`
UNION ALL
select
stt,
ma_kh,
ma_nv,
ho_va_ten_nv,
ma_ql,
ho_va_ten_ql,
'MDS' as bo_phan
FROM `spatial-vision-343005.staging.d_manual_chuong_trinh_rc_mds`
)




SELECT
a.*,
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
b.shortterritorydescr,

Case
when b.territorydescr = 'Miền Đông 1' then 'MN'
when b.territorydescr = 'Bắc Trung Bộ' then 'MB'
when b.territorydescr = 'Nam Trung Bộ' then 'MN'
when b.territorydescr = 'Đông Nam 2' then 'MN'
when b.territorydescr = 'Hà Nội 2' then 'MB'
when b.territorydescr = 'Hồ Chí Minh 2' then 'MN'
when b.territorydescr = 'Đông Bắc 1' then 'MB'
when b.territorydescr = 'Mê Kông 2' then 'MN'
when b.territorydescr = 'Mê Kông 1' then 'MN'
when b.territorydescr = 'Tây Bắc HN' then 'MB'
when b.territorydescr = 'Hà Nội 1' then 'MB'
when b.territorydescr = 'Miền Đông 2' then 'MN'
when b.territorydescr = 'Đông Bắc 2' then 'MB'
when b.territorydescr = 'Đông Nam 1' then 'MN'
when b.territorydescr = 'Hồ Chí Minh 1' then 'MN'
else null
end as vungmien,

FROM combine_data a
LEFT JOIN ecom_data_pda e on e.custid = a.ma_kh
LEFT JOIN activa_zalo ac on ac.customer_code = a.ma_kh
LEFT JOIN activa_zalo_old aco on aco.customer_code = a.ma_kh
LEFT JOIN ds_ecom_theo_kh d on a.ma_kh = d.makhdms

--Khach hang
LEFT JOIN `staging.d_master_khachhang`  b ON a.ma_kh = b.custid;