CREATE VIEW `spatial-vision-343005.warehouse.view_gia_vang`
AS WITH
  -- 1. Trích xuất giá vàng của chi nhánh Hồ Chí Minh (HCM)
  hcm_data AS (
    SELECT
      JSON_VALUE(t.js, '$.currentDate') AS date,
      CAST(JSON_VALUE(gold_data, '$.SellValue') AS BIGNUMERIC) AS sell_hcm,
      CAST(JSON_VALUE(gold_data, '$.BuyValue') AS BIGNUMERIC) AS buy_hcm
    FROM
      `spatial-vision-343005.staging.d_gia_vang` AS t
      -- Làm phẳng mảng 'data'
      CROSS JOIN UNNEST(JSON_EXTRACT_ARRAY(t.js, '$.data')) AS gold_data
    WHERE
      -- Chỉ lọc dữ liệu HCM
      JSON_VALUE(gold_data, '$.BranchName') = 'Hồ Chí Minh'
  ),
  
  -- 2. Trích xuất giá vàng của chi nhánh Miền Bắc (HN)
  hn_data AS (
    SELECT
      JSON_VALUE(t.js, '$.currentDate') AS date,
      CAST(JSON_VALUE(gold_data, '$.SellValue') AS BIGNUMERIC) AS sell_hn,
      CAST(JSON_VALUE(gold_data, '$.BuyValue') AS BIGNUMERIC) AS buy_hn
    FROM
      `spatial-vision-343005.staging.d_gia_vang` AS t
      CROSS JOIN UNNEST(JSON_EXTRACT_ARRAY(t.js, '$.data')) AS gold_data
    WHERE
      -- Chỉ lọc dữ liệu Miền Bắc
      JSON_VALUE(gold_data, '$.BranchName') = 'Miền Bắc'
  )
  
-- 3. Ghép (JOIN) dữ liệu của hai chi nhánh dựa trên trường 'date'
SELECT
  hcm.date,
  hcm.sell_hcm,
  hcm.buy_hcm,
  hn.sell_hn,
  hn.buy_hn
FROM
  hcm_data AS hcm
INNER JOIN
  hn_data AS hn
ON
  hcm.date = hn.date;