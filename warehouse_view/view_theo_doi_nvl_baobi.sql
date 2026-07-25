CREATE VIEW `spatial-vision-343005.warehouse.view_theo_doi_nvl_baobi`
AS SELECT ma_kho, kho_hang, ma_vt, ma_sp_cu, ma_sx, ten_vt, 
so_luong_vt, so_luong, tien_kho, capture_date, he_so_quy_doi, vtth_dvt
FROM `spatial-vision-343005.staging.f_ge_giao_dich_nvl_bao_bi` 
WHERE LOWER(kho_hang) NOT LIKE '%qc%'
  AND LOWER(kho_hang) NOT LIKE '%nghiên cứu%'
  AND 
  (ma_vt LIKE 'A%'
  OR ma_vt LIKE 'B%'
  OR ma_vt LIKE 'C%')




;