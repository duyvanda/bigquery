-- ==========================================================================
-- Routine Name : sp_f_max_insert_leadtime
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2024-07-06 10:55:35.815000+00:00
-- Last Altered : 2024-07-06 10:55:35.815000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_max_insert_leadtime()
BEGIN
TRUNCATE TABLE staging_temp.f_max_insert_leadtime_temp;
INSERT INTO staging_temp.f_max_insert_leadtime_temp(
-- Create table staging_temp.f_max_insert_leadtime_temp
-- as
select max(inserted_at) as max_inserted from `warehouse.f_leadtime_new_detail1` where inserted_at is not null

  );
Create or replace table `warehouse.f_max_insert_leadtime`

copy `staging_temp.f_max_insert_leadtime_temp`;

End;
