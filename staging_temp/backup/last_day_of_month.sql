CREATE FUNCTION `spatial-vision-343005`.staging_temp.last_day_of_month(x DATE) RETURNS BOOL
AS (
if ( x =  date(date_trunc(x,month) + interval 1 month - interval 1 day),TRUE,FALSE)
);