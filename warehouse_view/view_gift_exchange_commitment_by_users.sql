CREATE VIEW `spatial-vision-343005.warehouse.view_gift_exchange_commitment_by_users`
AS SELECT  
  
  JSON_VALUE(js, "$.created_at") AS created_at,
  JSON_VALUE(js, "$.customer_code") AS customer_code,
  JSON_VALUE(js, "$.customer_name") AS customer_name,

  JSON_VALUE(g, "$.amount") AS amount,
  JSON_VALUE(g, "$.gift_code") AS gift_code,
  JSON_VALUE(g, "$.gift_name") AS gift_name,
  JSON_VALUE(g, "$.gift_price") AS gift_price,
  JSON_VALUE(g, "$.id_gift") AS id_gift,
  JSON_VALUE(g, "$.image_name") AS image_name,
  JSON_VALUE(g, "$.image_path") AS image_path,
  JSON_VALUE(g, "$.image_thumb") AS image_thumb,
  JSON_VALUE(g, "$.quantity") AS quantity,
  JSON_VALUE(g, "$.quantity") AS unit_name,

  JSON_VALUE(js, "$.id_order") AS id_order,
  JSON_VALUE(js, "$.order_code") AS order_code,
  JSON_VALUE(js, "$.total_amount") AS total_amount,
  
  index,
  p_manv,
  p_version,
  etl_at
FROM `staging.gift_exchange_commitment_by_users` t,
UNNEST(JSON_QUERY_ARRAY(t.js, "$.gifts")) AS g;