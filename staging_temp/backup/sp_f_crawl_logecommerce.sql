CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_crawl_logecommerce()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_crawl_logecommerce_temp`;


 INSERT INTO `staging_temp.f_crawl_logecommerce_temp`

(   

SELECT

id_customer_oa,
id_customer,
url_link,
pathname,
params,
title_page,
id_order,
code_id,
code_dms,
total,
user_name,
customer_name,
ip_address,
os_type,
os_name,
os_version,
os_title,
device_type,
browser_name,
browser_version,
created_at,
updated_at,
inserted_at,
pathname_01,
pathname_02,
title_page_01,
title_page_02,
title_page_03

FROM `spatial-vision-343005.staging.f_crawl_logecommerce`

 );

Create or replace table `warehouse.f_crawl_logecommerce`

copy `staging_temp.f_crawl_logecommerce_temp`;




END;