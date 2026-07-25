CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_baocao_congno_daily_mds()
BEGIN 
 
-- TRUNCATE TABLE staging_temp.f_baocao_congno_daily_mds_temp;

INSERT INTO `warehouse.f_baocao_congno_daily_mds`

-- Create or replace table `staging_temp.f_baocao_congno_daily_mds_temp` as

-- with congno_mds as
-- (
--   select * 
--   from `spatial-vision-343005.warehouse.f_congno_rawdata_mds` 
-- )

select 
ma_nvgh as slsperid, 
nvgh as slspername, 
manv_sup_gh as supid,
sup_gh as tenquanlytt,
dir_gh as tenquanlyvung, 
mgr_gh as tenquanlykhuvuc,
thoihanthanhtoan as terms, 
no_toi_han,
paymentsform,
sum(so_du_chungtu) as tiennocongty, 
current_datetime("+7") as updated_at
from warehouse.f_congno_rawdata_mds  
group by 1,2,3,4,5,6,7,8,9


;

-- INSERT INTO `warehouse.f_baocao_congno_daily_mds`

-- SELECT * FROM `staging_temp.f_baocao_congno_daily_mds_temp`;

END;