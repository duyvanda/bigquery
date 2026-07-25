CREATE VIEW `spatial-vision-343005.warehouse.test_f_sales`
AS SELECT *,
row_number() over (order by null) as row
FROM `spatial-vision-343005.staging.f_sales`;