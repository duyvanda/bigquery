CREATE VIEW `spatial-vision-343005.warehouse.view_nvbc_reward_item_by_users`
AS SELECT 
  -- Explicitly listing columns from table 'a' for better performance and clarity
  a.phone,
  a.value,
  a.reward_event as reward_type,
  a.inserted_at,
  a.value1,
  a.value2,
  a.elt_at,
  a.p_manv,
  a.p_version,
  
  -- Joined fields
  ac.follow_name AS ten_duoc_si_ambassador,
  ac.customer_code AS makh,
  ac.customer_name AS tenkh,
  
  -- Handling the nested structure or direct column
  c.col.ma_nvbh, 
  
  d.tencvbh AS crs,
  d.tenquanlytt AS crm
FROM `spatial-vision-343005.staging.nvbc_reward_item_by_users` AS a
LEFT JOIN `spatial-vision-343005.staging.f_crawl_activate_ecom` AS ac 
  ON ac.follow_phone = a.phone
LEFT JOIN `warehouse.f_mapping_crs` AS c 
  ON c.custid = ac.customer_code
LEFT JOIN `staging.d_users` AS d 
  ON d.manv = c.col.ma_nvbh;