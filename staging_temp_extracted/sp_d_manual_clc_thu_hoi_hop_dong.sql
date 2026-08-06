-- ==========================================================================
-- Routine Name : sp_d_manual_clc_thu_hoi_hop_dong
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2024-04-15 07:13:27.699000+00:00
-- Last Altered : 2024-04-15 07:13:27.699000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

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
