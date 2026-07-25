CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_crawl_logqrcode()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_crawl_logqrcode_temp`;


 INSERT INTO `staging_temp.f_crawl_logqrcode_temp`

(   

-- Create table staging_temp.f_crawl_logqrcode_temp as

SELECT * FROM `spatial-vision-343005.staging.f_crawl_logqrcode`

 );

Create or replace table `warehouse.f_crawl_logqrcode`

copy `staging_temp.f_crawl_logqrcode_temp`;




END;