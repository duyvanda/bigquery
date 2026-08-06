-- ==========================================================================
-- Routine Name : last_day_of_month
-- Routine Type : FUNCTION
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-07-27 02:21:20.273000+00:00
-- Last Altered : 2026-07-27 02:21:20.273000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE FUNCTION `spatial-vision-343005`.staging_temp.last_day_of_month(x DATE) RETURNS BOOL
AS (
if ( x =  date(date_trunc(x,month) + interval 1 month - interval 1 day),TRUE,FALSE)
);
