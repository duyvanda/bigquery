CREATE VIEW `spatial-vision-343005.warehouse.view_f_du_thau`
AS SELECT
  cast( created_at as DATETIME) as update_at, 
  phaply,
  khuvuc,
  tinh,
  qlkv,
  hinhthucthau,
  makhachhang,
  tenkhachhang,
  masp,
  tensanpham,
  b.phanloainhom,
  tentatsp,
  dvt,
  giaduthau,
  soluongduthau,
  thanhtienduthau,
  nhomdkt,
  dtengoithauvt,
  cast (baolanh as STRING) as baolanh,
  giatribaolanh,
  songaybaolanh,
  ngayhethieulucbaolanh,
  round(hst,3) as hst,
  giatricktd,
  ngayhethieuluccktd,
  date(ngaydongthau) as ngaydongthau,
  date_diff(date(ngaydongthau), date('2020-01-01'), DAY) as date_sort,
  namdt,
  thangdt,
  hlhd,
  nguoithuchienhsdt,
  id_user,
  access_key,
  active,
  deleted_at,
  created_at,
  created_name,
  created_code,
  ifnull(b.descr,tensanpham)  as tensp, 
  ifnull(b.descr1,tentatsp) as tensp_vt,
  a.ghichu,
  a.matbmt,
  dense_rank() over (order by ngaydongthau, makhachhang, phaply desc) as rowcount
FROM `spatial-vision-343005.staging.thongtin_duthau` a
left join `spatial-vision-343005.staging.d_dms_master_invtid` b on a.masp = b.invtid
order by ngaydongthau, makhachhang, phaply desc;