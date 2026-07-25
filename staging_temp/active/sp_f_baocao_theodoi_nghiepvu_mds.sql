CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_theodoi_nghiepvu_mds()
BEGIN 
  TRUNCATE TABLE staging_temp.f_baocao_theodoi_nghiepvu_mds_temp;


 INSERT INTO staging_temp.f_baocao_theodoi_nghiepvu_mds_temp(

-- Create or replace table staging_temp.f_baocao_theodoi_nghiepvu_mds_temp
-- partition by date(accessdate)
-- as 
SELECT 
accessdate,
descr, 	
firstname,
screennumber,
internetaddress,
computername
 FROM `spatial-vision-343005.staging.d_sync_sysaccess`

   );

Create or replace table `warehouse.f_baocao_theodoi_nghiepvu_mds`

copy `staging_temp.f_baocao_theodoi_nghiepvu_mds_temp`;

End;