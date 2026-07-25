CREATE VIEW `spatial-vision-343005.warehouse.view_theo_doi_thu_hoi_bb_tra_thuong`
AS -- CTE 1: Lấy trạng thái "Đã lên đơn" (Từ câu trước)
WITH paid_so_summary AS (
  SELECT DISTINCT
    custid,
    accumulateid,
    CAST(EXTRACT(YEAR FROM PARSE_DATE('%Y-%m-%d', fromdate)) AS float64) AS nam,
    CAST(EXTRACT(QUARTER FROM PARSE_DATE('%Y-%m-%d', fromdate)) AS float64) AS quy
  FROM
    `staging.f_paidso_acculate`
  WHERE
    paidamt > 0
),

-- CTE 2: Lấy trạng thái "Đã thu" từ bảng mới (Xử lý de-duplicate)
thu_hoi_status AS (
  SELECT
    makh as ma_kh,
    quytratichluy as quy,
    nam,
    machuongtrinh as ma_ct,
    

    -- LOGICAL_OR sẽ trả về TRUE nếu CÓ BẤT KỲ dòng nào chứa 'đã thu'
    LOGICAL_OR(
      STRPOS(LOWER(thuhoibangkynhan), 'đã thu') > 0
    ) AS da_thu_hoi
  FROM
    `staging.d_manual_theo_doi_thu_hoi_bb_tra_thuong_da_tra`
  GROUP BY
    makh, quytratichluy, nam, machuongtrinh
)

SELECT
  t1.kenh,
  t1.ma_kh,
  t1.ten_kh,
  t1.quy,
  t1.nam,
  t1.ma_chuong_trinh,
  t1.ten_chuong_trinh,
  t1.ma_mds,
  t1.mds,
  -- Các cột được thêm từ các bảng khác và tính toán
  q.supid,
  q.tenquanlytt,
  -- Cột 1: Trạng thái lên đơn
  CASE
    WHEN t2.custid IS NOT NULL THEN 'Đã lên đơn'
    ELSE 'Chưa lên đơn'
  END AS trang_thai_len_don,
  
  -- Cột 2: Trạng thái thu hồi
  CASE
    WHEN t3.da_thu_hoi = TRUE THEN 'Đã thu'
    ELSE 'Chưa thu'
  END AS trang_thai_thu_hoi
  
FROM
  -- Bảng gốc của bạn
  `staging.d_manual_theo_doi_thu_hoi_bb_tra_thuong_can_tra` AS t1
LEFT JOIN
  -- Join với CTE 1 (trạng thái lên đơn)
  paid_so_summary AS t2
ON
  t1.ma_kh = t2.custid
  AND t1.ma_chuong_trinh = t2.accumulateid
  AND t1.nam = t2.nam
  AND t1.quy = t2.quy
LEFT JOIN
  -- Join với CTE 2 (trạng thái thu hồi)
  thu_hoi_status AS t3
ON
  t1.ma_kh = t3.ma_kh
  AND t1.quy = t3.quy
  AND t1.nam = t3.nam
  AND t1.ma_chuong_trinh = t3.ma_ct

LEFT JOIN
  `spatial-vision-343005.staging.d_users` AS q
ON 
  t1.ma_mds = q.manv;