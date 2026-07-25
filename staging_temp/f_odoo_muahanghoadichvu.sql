CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_odoo_muahanghoadichvu()
OPTIONS(
  strict_mode=false)
BEGIN 
 
 TRUNCATE TABLE staging_temp.f_odoo_muahanghoadichvu_temp;

 INSERT INTO `staging_temp.f_odoo_muahanghoadichvu_temp`

(  

-- Create or replace table `staging_temp.f_odoo_muahanghoadichvu_temp`
-- as

SELECT  
  id,
  name,
  code,
  assignee_id,
  active,
  message_main_attachment_id,
  stage_id,
  department_id,
  technical_responsible_uid,
  technical_responsible_name,
  create_uid,
  create_name,
  create_date,
  write_uid,
  write_name,
  write_date,
  sequence,
  prls_name,
  san_pham_id,
  nha_cung_cap_id,
  don_vi_tinh_id,
  so_luong,
  don_gia,
  thanh_tien,
  muc_dich_su_dung,
  ghi_chu,
  sl_da_mua,
  sl_da_ban_giao,
  ngay_giao_du_kien,
  trang_thai,
  duoc_duyet,
  ly_do_tu_choi,
  hd_name,
  prst_name
FROM `spatial-vision-343005.staging.d_odoo_mua_hang_hoa_dich_vu` 

);

Create or replace table `warehouse.f_odoo_muahanghoadichvu`

copy `staging_temp.f_odoo_muahanghoadichvu_temp`;

END;