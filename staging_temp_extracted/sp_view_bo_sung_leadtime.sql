-- ==========================================================================
-- Routine Name : sp_view_bo_sung_leadtime
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2024-08-29 03:39:20.381000+00:00
-- Last Altered : 2024-08-29 03:39:20.381000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_view_bo_sung_leadtime()
BEGIN

CREATE OR REPLACE FUNCTION `f.thu_post_don`(format_thu INT64)
RETURNS STRING AS (
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

-- Thu post don =
-- CASE
--   WHEN format_thứ = 1 THEN 'Thứ hai'
--   WHEN format_thứ = 2 THEN 'Thứ ba'
--   WHEN format_thứ  = 3 THEN 'Thứ tư'
--   WHEN format_thứ  = 4 THEN 'Thứ năm'
--   WHEN format_thứ  = 5 THEN 'Thứ sáu'
--   WHEN format_thứ  = 6 THEN 'Thứ bảy'
--   WHEN format_thứ  = 0 THEN 'Chủ nhật'
-- END
CREATE TEMP FUNCTION `format_thu`(posted_datetime TIMESTAMP)
RETURNS INT64 AS (
EXTRACT(DAYOFWEEK from posted_datetime)
);

-- format_thu =
-- WEEKDAY(posted_datetime)
CREATE TEMP FUNCTION `gio_post_don`(posted_datetime TIMESTAMP)
RETURNS INT64 AS (
EXTRACT(hour from posted_datetime)
);
-- Giờ post đơn =
-- EXTRACT(hour from posted_datetime)
CREATE OR REPLACE TABLE warehouse.f_extra_leadtime AS
(
SELECT
-- posted_datetime,
branchid,
ordernbr,
-- custid,
-- custname,
-- channel,
-- shoptype,
-- tinh,
-- tram,
CASE
    WHEN f.thu_post_don(format_thu(posted_datetime)) = 'Chủ nhật' AND tram = 'Trạm' THEN 32 - gio_post_don(posted_datetime)
    WHEN f.thu_post_don(format_thu(posted_datetime)) = 'Thứ bảy' AND tram = 'Trạm' AND gio_post_don(posted_datetime) > 10 THEN 56 - gio_post_don(posted_datetime)
    WHEN f.thu_post_don(format_thu(posted_datetime)) in ('Thứ hai','Thứ ba','Thứ tư','Thứ năm') AND tram = 'Trạm' AND gio_post_don(posted_datetime) > 16 THEN 32 - gio_post_don(posted_datetime)
    WHEN f.thu_post_don(format_thu(posted_datetime)) = 'Thứ sáu' AND gio_post_don(posted_datetime) > 16 AND shoptype != 'INS1' AND tram = 'Trạm' THEN 56 - gio_post_don(posted_datetime)
    WHEN f.thu_post_don(format_thu(posted_datetime)) = 'Thứ sáu' AND gio_post_don(posted_datetime) > 16 AND shoptype != 'INS1' and tram = 'VP' THEN 24
    WHEN f.thu_post_don(format_thu(posted_datetime)) = 'Thứ sáu' AND  gio_post_don(posted_datetime) > 16 and shoptype = 'INS1' and tram = 'Trạm' THEN 104 - gio_post_don(posted_datetime)
    WHEN f.thu_post_don(format_thu(posted_datetime)) = 'Thứ sáu' AND  gio_post_don(posted_datetime) > 16 and shoptype = 'INS1' and tram = 'VP' THEN 72
    WHEN f.thu_post_don(format_thu(posted_datetime)) = 'Thứ sáu' AND shoptype = 'INS1' THEN 48
    ELSE 0
END as lt_bo_sung
from warehouse.view_bo_sung_leadtime

-- Leadtime bổ sung =
-- CASE
--     WHEN Thứ post đơn = 'Chủ nhật' AND tram = 'Trạm' THEN 32 - Giờ post đơn
--     WHEN Thứ post đơn = 'Thứ bảy' AND tram = 'Trạm' AND Giờ post đơn > 10 THEN 56 - Giờ post đơn
--     WHEN Thứ post đơn in ('Thứ hai','Thứ ba','Thứ tư','Thứ năm') AND tram = 'Trạm' AND Giờ post đơn > 16 THEN 32 - Giờ post đơn
--     WHEN Thứ post đơn = 'Thứ sáu' AND Giờ post đơn > 16 AND shoptype != 'INS1' AND tram = 'Trạm' THEN 56 - Giờ post đơn
--     WHEN Thứ post đơn = 'Thứ sáu' AND Giờ post đơn > 16 AND shoptype != 'INS1' and tram = 'VP' THEN 24
--     WHEN Thứ post đơn = 'Thứ sáu' AND  Giờ post đơn > 16 and shoptype = 'INS1' and tram = 'Trạm' THEN 104 - Giờ post đơn
--     WHEN Thứ post đơn = 'Thứ sáu' AND  Giờ post đơn > 16 and shoptype = 'INS1' and tram = 'VP' THEN 72
--     WHEN Thứ post đơn = 'Thứ sáu' AND shoptype = 'INS1' THEN 48
--     ELSE 0
-- END
);
END;
