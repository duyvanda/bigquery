CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_caresoft_tickets()
BEGIN 
  TRUNCATE TABLE staging_temp.f_caresoft_tickets_temp;


 INSERT INTO staging_temp.f_caresoft_tickets_temp(

-- Create or replace table staging_temp.f_caresoft_tickets_temp
-- partition by date(created_at)
-- as

SELECT * FROM `spatial-vision-343005.staging.f_caresoft_tickets`

  );

Create or replace table `warehouse.f_caresoft_tickets`

copy `staging_temp.f_caresoft_tickets_temp`;

End;