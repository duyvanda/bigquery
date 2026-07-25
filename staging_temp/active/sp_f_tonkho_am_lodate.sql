CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_tonkho_am_lodate()
BEGIN 
  TRUNCATE TABLE staging_temp.f_tonkho_am_lodate_temp;


 INSERT INTO staging_temp.f_tonkho_am_lodate_temp(
-- Create table staging_temp.f_tonkho_am_lodate_temp
-- as

select t1.*, soluong + tonao as tongton,case when t2.phanloaicn is null or t2.phanloaicn in ('HUY','VT') then 'N' else 'Y' end chuahangdeban
from staging.d_sctonkho_hsd t1
-- left join staging.d_phanloaikho t2 on t1.makho=t2.makho
left join 
(
  select distinct phanloaicn,makho from `staging.d_sc_kho_chi_nhanh`
) t2 
on t1.makho=t2.makho
where masanpham not like 'P%' and masanpham not like 'V%'

  );

Create or replace table `warehouse.f_tonkho_am_lodate`

copy `staging_temp.f_tonkho_am_lodate_temp`;

End;