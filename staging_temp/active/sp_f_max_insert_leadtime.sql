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