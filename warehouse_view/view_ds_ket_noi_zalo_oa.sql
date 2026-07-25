CREATE VIEW `spatial-vision-343005.warehouse.view_ds_ket_noi_zalo_oa`
AS SELECT 
  a.customer_code,
  a.customer_phone,
  a.customer_name,
  b.branchid,
  b.branchname,
  b.statedescr,
  b.shortterritorydescr,
  b.active,
  b.channel,
  b.shoptype,
  b.hcotypeid,
  b.hcoid,
  b.classid,
  a.follow_name,
  a.follow_phone,
  a.gender,
  a.birthday,
  -- Thêm cột tháng sinh nhật định dạng mm-yyyy ở đây
  FORMAT_DATE('%m', SAFE_CAST(a.birthday AS DATE)) as birthday_month, 
  a.follow_address,
  a.customer_address,
  a.updated_at,
  a.customer_role_name,
  a.office_code,
  a.office_name,
  a.user_name,
  a.user_code,
  a.pharmacy_name,
  a.status,
  '' as labels,
  0 as total_mess,
  a.created_at,
  a.etl_at as inserted_at,
  'N' as is_check_today_birthday,
  b.citizenid,
  a.citizenIdentity_number
FROM `warehouse.view_data_follow_by_users` a
LEFT JOIN `staging.d_master_khachhang` b on a.customer_code = b.custid;