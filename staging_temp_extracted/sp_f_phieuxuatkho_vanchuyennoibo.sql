-- ==========================================================================
-- Routine Name : sp_f_phieuxuatkho_vanchuyennoibo
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2023-07-17 03:45:36.698000+00:00
-- Last Altered : 2023-07-17 03:45:36.698000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_phieuxuatkho_vanchuyennoibo()
BEGIN
  TRUNCATE TABLE staging_temp.f_phieuxuatkho_vanchuyennoibo_temp;

 INSERT INTO staging_temp.f_phieuxuatkho_vanchuyennoibo_temp(

-- Create table staging_temp.f_phieuxuatkho_vanchuyennoibo_temp
-- partition by date(crtd_datetime)
-- as
SELECT
branchid,
batnbr,
trnsfrdocnbr,
trandate,
crtd_datetime,
comment,
transferstatus,
batchstatus,
rlsed,
rcptbatnbr,
rcptdate,
usercpt,
fromsite,
fromsitename,
tocpnyid,
tocpnyname,
tositeid,
tositename,
impexp,
invcnote,
invcnbr,
taxinvcode,
invtid,
descr,
lotsernbr,
expdate,
qty,
unitdesc,
inserted_at
 FROM `spatial-vision-343005.staging.f_pxkkvcnb`
   );
Create or replace table `warehouse.f_phieuxuatkho_vanchuyennoibo`

copy `staging_temp.f_phieuxuatkho_vanchuyennoibo_temp`;

End;
