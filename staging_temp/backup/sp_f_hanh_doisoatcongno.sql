CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_hanh_doisoatcongno()
BEGIN 
  TRUNCATE TABLE staging_temp.f_hanh_doisoatcongno_temp;


 INSERT INTO staging_temp.f_hanh_doisoatcongno_temp(

-- Create table staging_temp.f_hanh_doisoatcongno_temp
-- as
select * from `staging.f_hanh_doisoatcongno`

  );

Create or replace table `warehouse.f_hanh_doisoatcongno`

copy `staging_temp.f_hanh_doisoatcongno_temp`;

End;