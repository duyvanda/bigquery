CREATE FUNCTION `spatial-vision-343005`.f.thu_post_don(format_thu INT64) RETURNS STRING
AS (
(
SELECT
  CASE 
  WHEN format_thu = 2 THEN 'Thứ hai'
  WHEN format_thu = 3 THEN 'Thứ ba'
  WHEN format_thu  = 4 THEN 'Thứ tư'
  WHEN format_thu  = 5 THEN 'Thứ năm'
  WHEN format_thu  = 6 THEN 'Thứ sáu'
  WHEN format_thu  = 7 THEN 'Thứ bảy'
  WHEN format_thu  = 1 THEN 'Chủ nhật'
  ELSE ''
END
)
);