-- ==========================================================================
-- Routine Name : sp_f_rawdata_tonkho_daily
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2024-07-19 05:49:14.608000+00:00
-- Last Altered : 2024-07-19 05:49:14.608000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_rawdata_tonkho_daily()
BEGIN

TRUNCATE TABLE staging_temp.f_rawdata_tonkho_daily_temp;
INSERT INTO staging_temp.f_rawdata_tonkho_daily_temp(

-- Create table staging_temp.f_rawdata_tonkho_daily_temp
-- partition by date(ngay_capture)
-- as
SELECT
branchid,
branchname,
siteid as makho,
tenkho,
invtid,
tensanpham,
tenspviettat,
lotsernbr,
expdate,
toncuoi,
sltreohoadonao,
sltreochuataohoadon,
toncuoisosach,
created_date as ngay_capture
FROM `spatial-vision-343005.staging.f_sc_daily_raw_invt`
where DATE(created_date) >= DATE_SUB(current_date(), INTERVAL 30 DAY)
);
Create or replace table `warehouse.f_rawdata_tonkho_daily`

copy `staging_temp.f_rawdata_tonkho_daily_temp`;

End;
