CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_xuatnhapton_daily()
OPTIONS(
  strict_mode=false)
BEGIN 
 
--  TRUNCATE TABLE staging_temp.f_xuatnhapton_daily_temp;

 INSERT INTO `warehouse.f_xuatnhapton_daily`

(
  
-- Create or replace table `staging_temp.f_xuatnhapton_daily_temp`
-- as

SELECT * , current_timestamp() as updated_at, 
FROM `spatial-vision-343005.warehouse.f_xuatnhapton`


);

-- INSERT INTO `staging_temp.f_xuatnhapton_daily`

-- SELECT * FROM `staging_temp.f_xuatnhapton_daily`;

END;