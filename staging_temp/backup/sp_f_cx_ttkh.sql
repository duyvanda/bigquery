CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_cx_ttkh()
BEGIN 
TRUNCATE TABLE staging_temp.f_cx_ttkh_temp;


INSERT INTO staging_temp.f_cx_ttkh_temp 
(

-- CREATE OR REPLACE table staging_temp.f_cx_ttkh_temp
-- as

SELECT 
  a.*,
  supid,
  tenquanlytt,
  -- a.created_at
 FROM `spatial-vision-343005.staging.d_cx_ttkh` a
 left join `spatial-vision-343005.staging.d_users` b on a.ma_nv_crs = b.manv


);

Create or replace table `warehouse.f_cx_ttkh`

copy `staging_temp.f_cx_ttkh_temp`;


End;