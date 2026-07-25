CREATE VIEW `spatial-vision-343005.warehouse.view_data_follow_by_users`
AS SELECT
  -- Date & Time Types
  SAFE_CAST(JSON_VALUE(js, '$.birthday') AS DATE) AS birthday,
  SAFE_CAST(JSON_VALUE(js, '$.created_at') AS DATETIME) AS created_at,
  SAFE_CAST(JSON_VALUE(js, '$.updated_at') AS DATETIME) AS updated_at,

  -- Integer Types (Numbers)
  SAFE_CAST(JSON_VALUE(js, '$.gender') AS INT64) AS gender,
  SAFE_CAST(JSON_VALUE(js, '$.status') AS INT64) AS status,

  -- String Types
  JSON_VALUE(js, '$.customer_code') AS customer_code,
  JSON_VALUE(js, '$.customer_name') AS customer_name,
  JSON_VALUE(js, '$.customer_address') AS customer_address,
  JSON_VALUE(js, '$.customer_role_name') AS customer_role_name,
  
  
  -- Keep Phones as String to preserve leading '0'
  JSON_VALUE(js, '$.customer_phone') AS customer_phone, 
  JSON_VALUE(js, '$.follow_phone') AS follow_phone,
  JSON_VALUE(js, '$.citizenIdentity_number') AS citizenIdentity_number,

  JSON_VALUE(js, '$.follow_name') AS follow_name,
  JSON_VALUE(js, '$.follow_address') AS follow_address,
  JSON_VALUE(js, '$.office_code') AS office_code,
  JSON_VALUE(js, '$.office_name') AS office_name,
  JSON_VALUE(js, '$.pharmacy_name') AS pharmacy_name,
  
  -- Nullable fields (Strings)
  JSON_VALUE(js, '$.user_code') AS user_code,
  JSON_VALUE(js, '$.user_name') AS user_name,
  etl_at

FROM
  `staging.data_follow_by_users`;