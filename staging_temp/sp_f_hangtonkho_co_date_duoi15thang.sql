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