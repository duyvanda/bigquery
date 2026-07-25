CREATE VIEW `spatial-vision-343005.warehouse.ban_do_ban_hang`
AS WITH NGAYGIAOHANG as
(
  select 
  dv.crtd_datetime as crtd_datetime_dv, 
  dv.branchid,
  dv.ordernbr,
  dv.status as status_dv,
  dv.delivery_date
  FROM `spatial-vision-343005.staging.sync_dms_dv` dv
  where dv.delivery_date IS NOT NULL AND dv.status = 'C' and dv.crtd_datetime >= '2024-01-01'
)

SELECT
a.ngaychungtu,
a.sodondathang, 
a.makhdms, 
tenkhachhang,
a.masanpham, 
a.doanhsochuavat, 
makenhkh,
tentinhkh,
tenquanhuyen,
phuongxa,
congtycn,
cluster_state,
address,
tram,
delivery_date as ngay_giao_hang,
concat(makhdms, ' - ',tenkhachhang) as Ma_ten_kh,
concat(masanpham, ' - ',tensanphamnb) as Ma_ten_sp,
ST_GEOGPOINT(lng, lat) as geo_point
FROM `spatial-vision-343005.staging.f_sales` a
left join `staging.d_master_khachhang` b on a.makhdms = b.custid
LEFT JOIN `spatial-vision-343005.staging.d_tinh` c on b.statedescr = c.tinh
LEFT JOIN NGAYGIAOHANG g on a.sodondathang = g.ordernbr and a.macongtycn = g.branchid
WHERE DATE(ngaychungtu)>= '2024-01-01';