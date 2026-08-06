-- ==========================================================================
-- Routine Name : sp_f_baocao_theodoi_nghiepvu_mds
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2023-07-18 09:48:37.986000+00:00
-- Last Altered : 2023-07-18 09:48:37.986000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

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
