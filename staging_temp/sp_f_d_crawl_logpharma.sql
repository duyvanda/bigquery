CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_d_crawl_logpharma()
BEGIN 
  TRUNCATE TABLE staging_temp.f_d_crawl_logpharma_temp;


 INSERT INTO staging_temp.f_d_crawl_logpharma_temp(

-- CREATE OR REPLACE table staging_temp.f_d_crawl_logpharma_temp
-- as
SELECT *
from `spatial-vision-343005.staging.d_crawl_logpharma`

  );

Create or replace table `warehouse.f_d_crawl_logpharma`

copy `staging_temp.f_d_crawl_logpharma_temp`;

End;