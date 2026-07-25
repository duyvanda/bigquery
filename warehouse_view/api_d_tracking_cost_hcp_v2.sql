CREATE VIEW `spatial-vision-343005.warehouse.api_d_tracking_cost_hcp_v2`
AS --WITH data_raw AS (
  SELECT
    ma_crm,
    crm AS ten_crm,
    ma_hco_chung,
    ten_hco_chung,
    ma_hcp_2,
    ten_hcp,
    don_vi,
    khoa_phong,
    nam_thuc_hien,
    thang_thuc_hien,
    hoat_dong,
    hoat_dong_chi_tiet,
    chi_tiet_qua_tang,
    chi_phi_thuc_hien_dong,
    ghi_chu,
    google_link
  FROM `spatial-vision-343005.staging.d_tracking_cost_hcp_v2`
-- )
-- SELECT JSON_OBJECT(
--   'status', 'ok',
--   'time', CAST(CURRENT_TIMESTAMP() AS STRING),
--   'rows', (SELECT COUNT(*) FROM data_raw),
--   'data', TO_JSON(ARRAY(SELECT AS STRUCT * FROM data_raw))
-- ) AS json_output;;