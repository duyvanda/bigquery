CREATE VIEW `spatial-vision-343005.warehouse.view_omcs_data_chat_data`
AS 
SELECT *,

case 
when time_ori is null and ma_kh = '000328' then timestamp('2025-09-09 11:00:00')
when time_ori is null and ma_kh = '001458' then timestamp('2025-09-10 14:00:00')
when time_ori is null and ma_kh = '002147' then timestamp('2025-09-10 15:00:00')
when time_ori is null and ma_kh = '004410' then timestamp('2025-09-11 18:00:00')
when time_ori is null and ma_kh = '004980' then timestamp('2025-09-10 15:00:00')
when time_ori is null and ma_kh = '007589' then timestamp('2025-09-12 08:00:00')
when time_ori is null and ma_kh = '010193' then timestamp('2025-09-09 15:00:00')
when time_ori is null and ma_kh = '010436' then timestamp('2025-09-09 09:00:00')
when time_ori is null and ma_kh = '013205' then timestamp('2025-09-09 09:00:00')
when time_ori is null and ma_kh = 'HH10O099' then timestamp('2025-09-09 09:00:00')

when time_ori is null and ma_kh = 'HH12O049' then timestamp('2025-09-09 14:00:00')
when time_ori is null and ma_kh = 'HH12O821' then timestamp('2025-09-09 11:00:00')
when time_ori is null and ma_kh = 'M1301241' then timestamp('2025-09-10 13:00:00')
when time_ori is null and ma_kh = 'M1601096' then timestamp('2025-09-08 10:00:00')
when time_ori is null and ma_kh = 'MSPC0672' then timestamp('2025-09-11 07:00:00')
when time_ori is null and ma_kh = 'N01101128' then timestamp('2025-09-08 09:00:00')

when time_ori is null and ma_kh = 'NSPC0110160' then timestamp('2025-09-08 18:00:00')
when time_ori is null and ma_kh = 'P4502-0119' then timestamp('2025-09-10 20:00:00')
when time_ori is null and ma_kh = 'P4505-0044' then timestamp('2025-09-08 17:00:00')
when time_ori is null and ma_kh = 'P4719-0301' then timestamp('2025-09-10 10:00:00')

when time_ori is null and ma_kh = 'TD30E037' then timestamp('2025-09-11 19:00:00')


else timestamp(time_ori) end as time_fix


FROM (

SELECT 
CAST(t.index AS INT64) as index,
SPLIT(JSON_VALUE(js, "$.file_name"), '_')[SAFE_OFFSET(0)] AS ma_kh,
JSON_VALUE(JSON_QUERY_ARRAY(js, "$.lst_image_urls")[SAFE_OFFSET(0)]) AS lst_image_urls_1,
JSON_VALUE(JSON_QUERY_ARRAY(js, "$.lst_image_urls")[SAFE_OFFSET(1)]) AS lst_image_urls_2,
JSON_VALUE(js, "$.message") AS message,
JSON_VALUE(js, "$.role") AS role,
JSON_VALUE(js, "$.time") AS time_ori

FROM `spatial-vision-343005.staging.omcs_data_chat_data` t
ORDER BY CAST(t.index AS INT64)

);