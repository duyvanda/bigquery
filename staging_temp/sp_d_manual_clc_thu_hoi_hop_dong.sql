CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_d_manual_clc_thu_hoi_hop_dong()
BEGIN
TRUNCATE TABLE `staging_temp.d_manual_clc_thu_hoi_hop_dong_temp`;

INSERT INTO `staging_temp.d_manual_clc_thu_hoi_hop_dong_temp`

(  
  -- Create table `staging_temp.d_manual_clc_thu_hoi_hop_dong_temp` as
SELECT * FROM `spatial-vision-343005.staging.d_manual_clc_thu_hoi_hop_dong`


);

Create or replace table `warehouse.d_manual_clc_thu_hoi_hop_dong`

copy `staging_temp.d_manual_clc_thu_hoi_hop_dong_temp`;




END;