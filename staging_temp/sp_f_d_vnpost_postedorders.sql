CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_d_vnpost_postedorders()
BEGIN 
  TRUNCATE TABLE staging_temp.f_d_vnpost_postedorders_temp;


 INSERT INTO staging_temp.f_d_vnpost_postedorders_temp(
-- Create table staging_temp.f_d_vnpost_postedorders_temp
-- as
SELECT a.*, left(a.ordercode, 21) as CNBBNH,b.orderstatusid, b.orderstatusname, b.deliverytime 
FROM `spatial-vision-343005.staging.d_vnpost_postedorders` a
left join staging.d_vnpost_status b
on a.id = b.id
  );

Create or replace table `warehouse.f_d_vnpost_postedorders`

copy `staging_temp.f_d_vnpost_postedorders_temp`;

End;