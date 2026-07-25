CREATE VIEW `spatial-vision-343005.warehouse.view_data_bi_phong_ke_hoach`
AS WITH data_sales_0 AS (
  SELECT 
    DATE(thang) AS thang,
    EXTRACT(YEAR FROM thang) AS nam,

    CASE 
      WHEN masanpham = 'OH053' THEN 'OH087'
      WHEN masanpham = 'OH056' THEN 'OH086'
      WHEN masanpham = 'OH073' THEN 'OH088'
      ELSE masanpham 
    END AS masanpham,

    SUM(soluongori) AS soluong

  FROM `warehouse.f_raw_data_sales_yoy`

  WHERE thang >= '2024-01-01'
    AND macongtycn != 'DL0001'

  GROUP BY 1, 2, 3

  ORDER BY 1
),

data_sales AS (
  SELECT 
    thang,
    nam,
    masanpham,
    SUM(soluong) AS soluong

  FROM data_sales_0

  GROUP BY 1, 2, 3
),

data_tonkho AS (
  WITH data_tonkho AS (
    SELECT 
      DATE(created_date) AS day,
      DATE_TRUNC(DATE(created_date), MONTH) AS month_,

      CASE 
        WHEN masanpham = 'OH053' THEN 'OH087'
        WHEN masanpham = 'OH056' THEN 'OH086'
        WHEN masanpham = 'OH073' THEN 'OH088'
        ELSE masanpham 
      END AS masanpham,

      SUM(toncn + tonhcm + tonao + tonvime + tonmerap + tonhangdiduong) AS ton_cn,
      SUM(tonnmtp + tonnmhh) AS ton_kho_nm

    FROM `spatial-vision-343005.staging.f_sc_daily_invt`

    GROUP BY 1, 2, 3
  ),

  thoi_diem_ton_kho AS (
    SELECT 
      month_,
      MAX(day) AS day

    FROM data_tonkho

    WHERE day < (SELECT * FROM `staging.d_current_table`)

    GROUP BY 1
  )

  SELECT 
    a.*

  FROM data_tonkho a

  JOIN thoi_diem_ton_kho b 
    ON a.month_ = b.month_ 
   AND b.day = a.day

  ORDER BY a.day DESC
)

SELECT  
  DATE_SUB(
    DATE_ADD(
      IFNULL(a.thang, b.month_), 
      INTERVAL 1 MONTH
    ), 
    INTERVAL 1 DAY
  ) AS thang,

  IFNULL(a.nam, EXTRACT(YEAR FROM b.month_)) AS nam,
  IFNULL(a.masanpham, b.masanpham) AS masanpham,
  IFNULL(a.soluong, 0) AS soluong_ban,
  IFNULL(b.ton_kho_nm, 0) AS ton_kho_nm,
  IFNULL(b.ton_cn, 0) AS tongton_cn,
  b.day AS ngay_ton_kho,

  (
    SELECT MAX(inserted_at2) 
    FROM `spatial-vision-343005.staging.f_sc_daily_invt` 
    WHERE inserted_at2 IS NOT NULL
  ) AS ngay_capnhat_dulieu

FROM data_sales a 

FULL JOIN data_tonkho b 
  ON a.masanpham = b.masanpham 
 AND a.thang = b.month_

ORDER BY thang DESC;