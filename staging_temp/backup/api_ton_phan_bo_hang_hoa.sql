CREATE PROCEDURE `spatial-vision-343005`.staging_temp.api_ton_phan_bo_hang_hoa(p_manv STRING, p_version STRING)
OPTIONS(
  strict_mode=false)
BEGIN
-- Default values
DECLARE current_dt DATE DEFAULT CURRENT_DATE();
-- SET PARAMS
DECLARE set_manv STRING DEFAULT 'None';
DECLARE set_version STRING DEFAULT 'None';

SET set_manv = IF (p_manv = '', set_manv, p_manv);
SET set_version = IF (p_version = '', set_version, p_version);

INSERT INTO `warehouse.f_ton_phan_bo_hang_hoa`

(
  
with DMS_DATA as
(
  SELECT 
  cpnyid,
  programid,
  programname,
  fromdate,
  todate,
  invtid,
  amtalloc,
  amtuse,
  amtavail,
  slsperid,
  manv,
  version,
  status
  FROM `spatial-vision-343005.staging.f_distprogram` 
  where manv = set_manv and version = set_version
  )

  select a.*, b.descr, b.descr1, tencvbh, supid, tenquanlytt from DMS_DATA a
  LEFT JOIN `staging.d_dms_master_invtid` b
  on a.invtid = b.invtid
  LEFT JOIN `staging.d_users` c on a.slsperid = c.manv
);

END;