CREATE VIEW `spatial-vision-343005.warehouse.view_tracking_survey_sunohana_by_users`
AS SELECT 

  JSON_VALUE(js, "$.status_send") AS status_send,
  JSON_VALUE(js, "$.full_name") AS full_name,
  JSON_VALUE(js, "$.phone") AS phone,
  JSON_VALUE(js, "$.province_name") AS province_name,
  JSON_VALUE(js, "$.pharmacy_code") AS pharmacy_code,
  JSON_VALUE(js, "$.customer_code") AS customer_code,
  JSON_VALUE(js, "$.customer_name") AS customer_name,

  JSON_VALUE(js, "$.product_code") AS product_code,
  JSON_VALUE(js, "$.id_product") AS id_product,
  JSON_VALUE(js, "$.product_name") AS product_name,
  JSON_VALUE(js, "$.label") AS label,

  JSON_VALUE(js, "$.object_uses_concat") AS object_uses_concat,
  JSON_VALUE(js, "$.skin_condition_concat") AS skin_condition_concat,


  CAST(JSON_VALUE(js, "$.is_surveyed") AS STRING) AS is_surveyed,
  JSON_VALUE(js, "$.status_name") AS status_name,
  JSON_VALUE(js, "$.status_times") AS status_times,

  JSON_VALUE(js, "$.tham_gia_link_1") AS tra_loi_ks_1,
  JSON_VALUE(js, "$.tham_gia_link_2") AS tra_loi_ks_2,
  JSON_VALUE(js, "$.tham_gia_link_3") AS tra_loi_ks_3,
  JSON_VALUE(js, "$.tham_gia_link_4") AS tra_loi_ks_4,
  JSON_VALUE(js, "$.tham_gia_link_5") AS tra_loi_ks_5,
  JSON_VALUE(js, "$.tham_gia_link_6") AS tra_loi_ks_6,


  CAST(JSON_VALUE(js, "$.created_at") AS TIMESTAMP) AS created_at,

  p_manv,
  p_version,
  etl_at
FROM `staging.get_survey_sunohana_by_users` t;