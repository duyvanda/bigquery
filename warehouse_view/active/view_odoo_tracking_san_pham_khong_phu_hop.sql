CREATE VIEW `spatial-vision-343005.warehouse.view_odoo_tracking_san_pham_khong_phu_hop`
AS with nvl_ma_tps as (

  SELECT 
  ma_nvl,
  STRING_AGG(DISTINCT ma_thanh_pham, ', ') AS danh_sach_ma_thanh_pham
FROM 
  `spatial-vision-343005.staging.odoo_dinh_muc_nvl`
WHERE ma_nvl is not null
GROUP BY 
  ma_nvl

)


SELECT a.*, b.danh_sach_ma_thanh_pham
 FROM `spatial-vision-343005.staging.odoo_tracking_san_pham_khong_phu_hop`  a
LEFT JOIN `nvl_ma_tps` b on a.ma_san_pham = b.ma_nvl;