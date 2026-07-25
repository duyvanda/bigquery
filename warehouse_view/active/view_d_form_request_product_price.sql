CREATE VIEW `spatial-vision-343005.warehouse.view_d_form_request_product_price`
AS -- SELECT
-- a.* EXCEPT (product_name),
-- b.descr as product_name
-- FROM `spatial-vision-343005.staging.d_form_request_product_price` a
-- LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid` b ON a.product_code = b.invtid

SELECT * FROM `spatial-vision-343005.staging.d_form_request_product_price` 

UNION ALL
SELECT * FROM `spatial-vision-343005.staging.d_form_request_thuocsi_price`;