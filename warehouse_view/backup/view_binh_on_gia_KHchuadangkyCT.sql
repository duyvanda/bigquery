CREATE VIEW `spatial-vision-343005.warehouse.view_binh_on_gia_KHchuadangkyCT`
AS with regis  as 
(
  select distinct custid from `spatial-vision-343005.staging.d_posm_regis`
)

select 
  c.supid,
  c.tenquanlytt as ten_qltt,
  a.ma_crs,
  a.crs as ten_nv,
  a.ma_hco_dms,
  a.ten_hco,
  tinh as Tinh,
  CONCAT(ma_hco_dms,' - ',ten_hco) as makh_tenkh,
  q.custid

FROM `spatial-vision-343005.staging.d_dskh_ka_can_tham_gia_bog` a
left join regis q  ON a.ma_hco_dms = q.custid
left join `spatial-vision-343005.staging.d_users` c ON a.ma_crs = c.manv
where q.custid is null;