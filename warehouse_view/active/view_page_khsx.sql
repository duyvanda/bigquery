CREATE VIEW `spatial-vision-343005.warehouse.view_page_khsx`
AS WITH so_lo_nam AS (
  -- Retrieve the latest batch number for each product in the year
  SELECT
    DATE_TRUNC(created_date, YEAR) AS nam,
    masanpham,
    so_lo_trong_nam
  FROM `spatial-vision-343005.staging.f_sc_daily_invt`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY masanpham, DATE_TRUNC(created_date, YEAR) ORDER BY so_lo_trong_nam DESC) = 1
),

-- Tách data_da_quy_doi ra thành 1 CTE nối tiếp
data_da_quy_doi AS (
  SELECT 
    t1.* EXCEPT (soluong, thangtruocchuyensang, masanphamphanam),
    SAFE_DIVIDE(t1.soluong, IFNULL(t2.quy_cach_dong_hop, 1)) AS soluong,
    CASE
      WHEN CAST(t1.thangtruocchuyensang AS STRING) = '-' 
           OR thangtruocchuyensang IS NULL THEN 0
      ELSE CAST(
        TRIM(
          REGEXP_REPLACE(CAST(t1.thangtruocchuyensang AS STRING), r"[a-zAZ)()]", '')
        ) AS INT
      )
    END AS thangtruocchuyensang,
    t1.masanphamphanam
  FROM 
    `staging.d_nm_kehoachsanxuat` t1
  LEFT JOIN 
    `staging.d_nm_quycachdh` t2 
    ON t1.masanphamphanam = t2.ma_san_pham_pha_nam
  WHERE 
    DATE(ngaysx) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE, INTERVAL 5 MONTH), MONTH)
),

khsx_t_t_plus AS (
  SELECT
    masanphamphanam,
    MAX(tensanpham) AS tensanpham,
    
    -- Kế hoạch sản xuất Tháng T (Mặc định là tháng hiện tại)
    SUM(CASE 
          WHEN DATE(month) = DATE_TRUNC(CURRENT_DATE(), MONTH) 
          THEN soluong ELSE 0 
        END) AS khsx_thang_t,
        
    -- Kế hoạch sản xuất Tháng T+1 (Tháng tiếp theo)
    SUM(CASE 
          WHEN DATE(month) = DATE_ADD(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 1 MONTH) 
          THEN soluong ELSE 0 
        END) AS khsx_thang_t_plus_1

  FROM data_da_quy_doi
  GROUP BY 
    masanphamphanam
)

SELECT
  t1.*,
  t2.phannhomsp,
  t4.dongiatruocvat AS gia_kd,
  t3.nhomcpa,
  t3.nhomcpa2,
  t3.brand2023,
  t4.dangbaoche,
  t5.so_lo_trong_nam,
  t6.khsx_thang_t,              -- Thêm cột tháng T
  t6.khsx_thang_t_plus_1,       -- Thêm cột tháng T+1
  CURRENT_DATETIME("+7") AS updated_at
FROM `staging.f_kehoachsx_capture_t3` t1
JOIN `staging.d_nm_quycachdh` t2 
  ON t1.masanpham = TRIM(t2.ma_san_pham_pha_nam)
LEFT JOIN `staging.d_nhom_sp_trading` t3 
  ON t3.masanpham = t1.masanpham 
  AND t3.masanpham IS NOT NULL
LEFT JOIN `staging.d_manual_danhsach_banggia_sanpham2023` t4 
  ON t4.masp = t1.masanpham
LEFT JOIN so_lo_nam t5 
  ON t5.masanpham = t1.masanpham 
  AND DATE_TRUNC(t1.day, YEAR) = DATE(t5.nam)
LEFT JOIN khsx_t_t_plus t6      -- JOIN thêm bảng khsx_t_t_plus
  ON t1.masanpham = t6.masanphamphanam;