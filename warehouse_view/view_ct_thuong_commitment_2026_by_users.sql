CREATE VIEW `spatial-vision-343005.warehouse.view_ct_thuong_commitment_2026_by_users`
AS /* Bước 1: Tính toán và gom nhóm doanh số từ bảng thô (1 CTE duy nhất) */
WITH du_lieu_doanh_so AS (
  SELECT 
    makhdms AS ma_kh,
    IFNULL(b.col. ma_nvbh, a.manv) as manv,
    --tenkhachhang AS ten_kh,
    SUM(CASE WHEN DATE(ngaychungtu) BETWEEN '2025-10-01' AND '2025-12-31' THEN a.doanhsocovat ELSE 0 END) AS ds_q4_25_co_vat,
    SUM(CASE WHEN DATE(ngaychungtu) BETWEEN '2026-01-01' AND '2026-03-31' THEN a.doanhsochuavat ELSE 0 END) AS ds_q1_26_chua_vat,
    SUM(CASE WHEN DATE(ngaychungtu) BETWEEN '2026-04-01' AND '2026-06-30' THEN a.doanhsochuavat ELSE 0 END) AS ds_q2_26_chua_vat,
    SUM(CASE WHEN DATE(ngaychungtu) BETWEEN '2026-07-01' AND '2026-09-30' THEN a.doanhsochuavat ELSE 0 END) AS ds_q3_26_chua_vat,
    
    SUM(
      CASE 
        WHEN DATE(ngaychungtu) BETWEEN '2025-10-01' AND '2025-12-31' THEN a.doanhsocovat 
        WHEN DATE(ngaychungtu) BETWEEN '2026-01-01' AND '2026-09-30' THEN a.doanhsochuavat 
        ELSE 0 
      END
    ) AS tong_ds_cmm_2026,
  FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
  LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` b ON b.custid = a.makhdms
  WHERE macongtycn = 'DL0001'
    --AND hcotypeid = 'PKN'
    AND makhdms NOT IN ('015092')
    AND is_hang_km = 'Hàng bán'
    AND DATE(ngaychungtu) BETWEEN '2025-10-01' AND '2026-09-30'
  GROUP BY ALL
)

, doi_qua_manual AS (
SELECT
  ma_kh,
  SUM(CAST(gia_tri_da_doi_qua AS INT64)) AS gia_tri_da_doi_qua,
  SUM(CAST(ung_du_lich_2025 AS INT64)) AS ung_du_lich_2025,
  SUM(CAST(doi_dot1 AS INT64)) AS doi_dot1, 
  SUM(CAST(doi_dot2 AS INT64)) AS doi_dot2,
  SUM(CAST(doi_dot3 AS INT64)) AS doi_dot3,
  SUM(CAST(doi_dot4 AS INT64)) AS doi_dot4
FROM `spatial-vision-343005.staging.d_manual_theo_doi_chon_qua_cmm_2026`
GROUP BY ma_kh
)

, doi_qua_web AS (
SELECT
customer_code,
SUM(gift_amount) as gia_tri_doi_qua_web
FROM `spatial-vision-343005.staging.f_gift_exchange_commitment`
Where date(created_at) >= '2026-01-01'
GROUP BY customer_code
)

/* BƯỚC CUỐI: Format đầu ra cho báo cáo BI & JOIN trực tiếp với bảng Mapping */
SELECT 
  
  ds.ma_kh,
  c.custname AS ten_kh,
  map.tenquanlytt AS crm,
  map.tencvbh AS crs,
  ds.manv as ma_nv, 
  map.supid AS ma_crm,      
  map.asm AS scrm, 
  map.tenquanlykhuvuc AS ten_quan_ly_khu_vuc,
  
  /* Cột: Thời gian trả thưởng quy định */
  CASE 
    WHEN ds.tong_ds_cmm_2026 >= 60000000 THEN 'Mỗi quý / lần'
    WHEN ds.tong_ds_cmm_2026 >= 36000000 THEN '6 tháng / lần'
    ELSE NULL
  END AS thoi_gian_tra_thuong_quy_dinh,
  
  ds.ds_q4_25_co_vat AS dso_q4_25_vat,
  ds.ds_q1_26_chua_vat AS dso_q1_26_novat,
  ds.ds_q2_26_chua_vat AS dso_q2_26_novat,
  ds.ds_q3_26_chua_vat AS dso_q3_26_novat,
  ds.tong_ds_cmm_2026 AS tong_dso_cmm_2026,

  /* --- ĐOẠN CẦN BỔ SUNG BẮT ĐẦU TỪ ĐÂY --- */
  
  /* 1. Các cột % Thưởng từng quý */
  CASE 
    WHEN ds.ds_q4_25_co_vat >= 60000000 THEN 0.10
    WHEN ds.ds_q4_25_co_vat >= 45000000 THEN 0.09
    WHEN ds.ds_q4_25_co_vat >= 30000000 THEN 0.08
    WHEN ds.ds_q4_25_co_vat >= 15000000 THEN 0.06
    WHEN ds.ds_q4_25_co_vat >= 9000000 THEN 0.05
    ELSE 0
  END AS phan_tram_q4_25,

  CASE 
    WHEN ds.ds_q1_26_chua_vat >= 60000000 THEN 0.10
    WHEN ds.ds_q1_26_chua_vat >= 45000000 THEN 0.09
    WHEN ds.ds_q1_26_chua_vat >= 30000000 THEN 0.08
    WHEN ds.ds_q1_26_chua_vat >= 15000000 THEN 0.06
    WHEN ds.ds_q1_26_chua_vat >= 9000000 THEN 0.05
    ELSE 0
  END AS phan_tram_q1_26,

  CASE 
    WHEN ds.ds_q2_26_chua_vat >= 60000000 THEN 0.10
    WHEN ds.ds_q2_26_chua_vat >= 45000000 THEN 0.09
    WHEN ds.ds_q2_26_chua_vat >= 30000000 THEN 0.08
    WHEN ds.ds_q2_26_chua_vat >= 15000000 THEN 0.06
    WHEN ds.ds_q2_26_chua_vat >= 9000000 THEN 0.05
    ELSE 0
  END AS phan_tram_q2_26,

  CASE 
    WHEN ds.ds_q3_26_chua_vat >= 60000000 THEN 0.10
    WHEN ds.ds_q3_26_chua_vat >= 45000000 THEN 0.09
    WHEN ds.ds_q3_26_chua_vat >= 30000000 THEN 0.08
    WHEN ds.ds_q3_26_chua_vat >= 15000000 THEN 0.06
    WHEN ds.ds_q3_26_chua_vat >= 9000000 THEN 0.05
    ELSE 0
  END AS phan_tram_q3_26,  
  
  /* Cột: Hạng thành viên */
  CASE 
    WHEN ds.tong_ds_cmm_2026 >= 240000000 THEN 'Diamond'
    WHEN ds.tong_ds_cmm_2026 >= 180000000 THEN 'Platinum'
    WHEN ds.tong_ds_cmm_2026 >= 120000000 THEN 'Gold'
    WHEN ds.tong_ds_cmm_2026 >= 60000000 THEN 'Silver'
    WHEN ds.tong_ds_cmm_2026 >= 36000000 THEN 'Member'
    ELSE 'Không đạt'
  END AS hang_thanh_vien,
  
  /* Cột: % Thưởng */
  CASE 
    WHEN ds.tong_ds_cmm_2026 >= 240000000 THEN 0.10
    WHEN ds.tong_ds_cmm_2026 >= 180000000 THEN 0.09
    WHEN ds.tong_ds_cmm_2026 >= 120000000 THEN 0.08
    WHEN ds.tong_ds_cmm_2026 >= 60000000 THEN 0.06
    WHEN ds.tong_ds_cmm_2026 >= 36000000 THEN 0.05
    ELSE 0
  END AS phan_tram_thuong,
  
  /* Cột: Giá trị thưởng */
  ds.tong_ds_cmm_2026 * CASE 
    WHEN ds.tong_ds_cmm_2026 >= 240000000 THEN 0.10
    WHEN ds.tong_ds_cmm_2026 >= 180000000 THEN 0.09
    WHEN ds.tong_ds_cmm_2026 >= 120000000 THEN 0.08
    WHEN ds.tong_ds_cmm_2026 >= 60000000 THEN 0.06
    WHEN ds.tong_ds_cmm_2026 >= 36000000 THEN 0.05
    ELSE 0
  END AS gia_tri_thuong,  

  IFNULL(d.gia_tri_da_doi_qua,0) + IFNULL(w.gia_tri_doi_qua_web,0) AS gia_tri_da_doi_qua,
  IFNULL(d.ung_du_lich_2025,0) AS ung_du_lich_2026,
  IFNULL(d.doi_dot1,0) AS doi_d1,
  IFNULL(d.doi_dot2,0) AS doi_d2,
  IFNULL(d.doi_dot3,0) AS doi_d3,
  IFNULL(d.doi_dot4,0) AS doi_d4,
  IFNULL(w.gia_tri_doi_qua_web,0) AS gia_tri_doi_qua_web

FROM du_lieu_doanh_so ds
LEFT JOIN `staging.d_users` map
  ON ds.manv = map.manv
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` c
  ON ds.ma_kh = c.custid
LEFT JOIN doi_qua_manual d ON d.ma_kh = ds.ma_kh
LEFT JOIN doi_qua_web w ON w.customer_code = ds.ma_kh

ORDER BY ds.tong_ds_cmm_2026 DESC;






;