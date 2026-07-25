CREATE VIEW `spatial-vision-343005.warehouse.view_nvbc_track_view_by_users`
AS WITH union_all as (
  SELECT
    a.ma_kh_dms,
    a.phone,
    a.document_id,
    a.inserted_at,
    a.document_name,
    a.type,
    a.category,
    a.subcategory,
    a.url,
    a.point,
    a.data_type,
    --a.elt_at,
    --a.p_manv,
    --a.p_version,
  FROM `staging.view_nvbc_track_view_by_users` a

  -- UNION ALL
  -- SELECT
  --   a.ma_kh_dms,
  --   a.phone,
  --   a.document_id,
  --   a.inserted_at,
  --   b.document_name,
  --   b.type,
  --   b.category,
  --   b.subcategory,
  --   b.url,
  --   b.point,
  --   'doc_point' as data_type,
  --   --b.elt_at,
  --   --a.p_manv,
  --   --a.p_version,
  -- FROM `spatial-vision-343005.staging.nvbc_track_view_q32025` a
  -- LEFT JOIN `spatial-vision-343005.staging.nvbc_docs` b ON a.document_id = CAST(b.document_id as STRING)
)

SELECT
  a.ma_kh_dms,
  a.phone,
  a.document_id,
  a.inserted_at,
  a.document_name,
  a.type,
  a.data_type,
  a.category,
  a.subcategory,
  a.url,
  a.point,
  /*nếu data type = ref_point thì lấy điểm point ngược lại là 0*/
  /*nếu data type = streak_point thì lấy điểm point ngược lại là 0*/
-- Xử lý 2 điều kiện lấy điểm point
  CASE WHEN a.data_type = 'ref_point' THEN a.point ELSE 0 END AS ref_point,
  CASE WHEN a.data_type = 'streak_point' THEN a.point ELSE 0 END AS streak_point,
  b.col.ma_nvbh,
  c.follow_name as ten_duoc_si,
  c.customer_role_name as vai_tro,
  d.branchid,
  d.custname,
  d.address,
  e.tencvbh,
  e.supid,
  e.tenquanlytt

FROM union_all a
LEFT JOIN `warehouse.f_mapping_crs` b ON a.ma_kh_dms = b.custid
LEFT JOIN `staging.f_crawl_activate_ecom` c ON a.phone = c.follow_phone
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` d ON a.ma_kh_dms = d.custid
LEFT JOIN `spatial-vision-343005.staging.d_users` e ON b.col.ma_nvbh = e.manv
WHERE IFNULL(a.ma_kh_dms,'') not in ('00180400')
;