-- ==========================================================================
-- Routine Name : sp_f_hangtonkho_co_date_duoi15thang
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2023-07-24 03:42:52.221000+00:00
-- Last Altered : 2023-07-24 03:42:52.221000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_hangtonkho_co_date_duoi15thang()
BEGIN
  TRUNCATE TABLE staging_temp.f_hangtonkho_co_date_duoi15thang_temp;

 INSERT INTO staging_temp.f_hangtonkho_co_date_duoi15thang_temp(

-- CREATE OR REPLACE table staging_temp.f_hangtonkho_co_date_duoi15thang_temp as
select t1.*,case when t2.chuahangdeban is null then 'N' else t2.chuahangdeban end chuahangdeban
from staging.d_sctonkho_hsd t1
left join staging.d_phanloaikho t2 on t1.makho=t2.makho
where masanpham not like 'P%' and masanpham not like 'V%'

  );

Create or replace table `warehouse.f_hangtonkho_co_date_duoi15thang`

copy `staging_temp.f_hangtonkho_co_date_duoi15thang_temp`;

End;
