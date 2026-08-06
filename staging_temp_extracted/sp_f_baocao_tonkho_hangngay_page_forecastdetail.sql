-- ==========================================================================
-- Routine Name : sp_f_baocao_tonkho_hangngay_page_forecastdetail
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2024-11-18 03:55:31.272000+00:00
-- Last Altered : 2024-11-18 03:55:31.272000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_tonkho_hangngay_page_forecastdetail()
BEGIN
TRUNCATE TABLE staging_temp.f_baocao_tonkho_hangngay_page_forecastdetail_temp;
INSERT INTO staging_temp.f_baocao_tonkho_hangngay_page_forecastdetail_temp(
-- Create or replace table `staging_temp.f_baocao_tonkho_hangngay_page_forecastdetail_temp`
-- as
SELECT
t1.masp,
c.descr as tensp,
t1.*except(masp,tensp),
0 gap
FROM `spatial-vision-343005.staging.d_forecast_sc` t1 --WHERE "version" = 0
-- LEFT JOIN `spatial-vision-343005.staging.d_forecast_sc_gap` as b
-- ON t1.masp = b.masp
-- and t1.month = b.month
-- and t1.version =  b.version
-- and t1.kenh =  b.kenh
LEFT JOIN `staging.d_dms_master_invtid` c on c.invtid = t1.masp
);

Create or replace table `warehouse.f_baocao_tonkho_hangngay_page_forecastdetail`

copy `staging_temp.f_baocao_tonkho_hangngay_page_forecastdetail_temp`;

End;
