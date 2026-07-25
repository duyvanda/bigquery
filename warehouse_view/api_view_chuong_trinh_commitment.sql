CREATE VIEW `spatial-vision-343005.warehouse.api_view_chuong_trinh_commitment`
AS WITH data_thuong_4_quy AS (
  SELECT 
  *, 
    -- Xử lý NULL cho từng thành phần trong phép tính thưởng 4 quý
    (IFNULL(dso_q4_25_vat, 0) * IFNULL(phan_tram_q4_25, 0) + 
     IFNULL(dso_q1_26_novat, 0) * IFNULL(phan_tram_q1_26, 0) + 
     IFNULL(dso_q2_26_novat, 0) * IFNULL(phan_tram_q2_26, 0) + 
     IFNULL(dso_q3_26_novat, 0) * IFNULL(phan_tram_q3_26, 0)) AS thuong_4_quy
  FROM `spatial-vision-343005.warehouse.view_ct_thuong_commitment_2026_by_users`
)

SELECT 
  ma_kh as ma_kh_dms,
  ten_kh,
  ma_nv as ma_crs,
  crs as ten_crs,
  CASE 
    WHEN IFNULL(thuong_4_quy, 0) > IFNULL(gia_tri_thuong, 0) THEN IFNULL(thuong_4_quy, 0)
    ELSE IFNULL(gia_tri_thuong, 0)
  END AS gia_tri_tich_luy_quy_doi,

  gia_tri_da_doi_qua as gia_tri_tich_luy_da_doi_qua,
  
  (CASE WHEN IFNULL(thuong_4_quy, 0) > IFNULL(gia_tri_thuong, 0) THEN IFNULL(thuong_4_quy, 0) ELSE IFNULL(gia_tri_thuong, 0) END) - gia_tri_da_doi_qua as gia_tri_tich_luy_con_lai

FROM data_thuong_4_quy;;