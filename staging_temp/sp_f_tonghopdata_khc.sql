CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_tonghopdata_khc(manv_p STRING, version_p STRING)
BEGIN 

INSERT INTO warehouse.f_tonghopdata_khc
(

-- create or replace table warehouse.f_tonghopdata_khc as

SELECT  
  id,
  ma_crs,
  b.tencvbh as ten_crs,
  ngaytao,
  nguoitao,
  ten_khc,
  ma_khc,
  ngaysua,
  nguoisua,
  diachi_hoadon,
  quocgia,
  tinh_tp,
  form_layout,
  donvi,
  case when a.inactive = 'True' then 'Ngưng' else 'Còn hoạt động' end as inactive,
  phanloai_bv,
  khuvuc,
  ngaydonhang_moinhat,
  hang,
  tuyen,
  crm,
  substring(crm, STRPOS(crm,'MR'),6) as ma_crm,
  b1.tencvbh as ten_crm,
  p_manv,
  p_version 
FROM `spatial-vision-343005.staging.khc_theo_user` a
left join `spatial-vision-343005.staging.d_users` b on a.ma_crs = b.manv
left join `spatial-vision-343005.staging.d_users` b1 on  TRIM(substring(crm, STRPOS(crm,'MR'),6)) = b1.manv
where p_manv = manv_p and p_version = version_p
);

End;