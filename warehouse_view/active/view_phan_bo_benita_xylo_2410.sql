CREATE VIEW `spatial-vision-343005.warehouse.view_phan_bo_benita_xylo_2410`
AS WITH phan_bo AS (
  SELECT * FROM `spatial-vision-343005.staging.d_phan_bo_san_pham_tp_2026`
)

, sales AS (
  SELECT sodondathang, macongtycn, manv, masanpham 
  FROM `staging.f_sales` 
  WHERE makenhkh = 'TP' 
  -- Lọc linh động danh sách sản phẩm thay vì hardcode
  AND masanpham IN (SELECT DISTINCT san_pham FROM phan_bo WHERE san_pham IS NOT NULL)
  -- Thêm điều kiện lọc ngaychungtu từ ngày bắt đầu theo dõi sớm nhất để tối ưu data scan
  AND DATE(ngaychungtu) >= (SELECT DATE(MIN(theo_doi_tu_ngay)) FROM phan_bo)
  GROUP BY ALL
)

, raw_trans AS (
  SELECT 
    CASE 
      WHEN l.col.phan_loai_mcp = 'Rural' 
        OR IFNULL(c.manv, b.slsperid) = 'TMDT_001' THEN l.col.ma_nvbh
      WHEN IFNULL(c.manv, b.slsperid) IN (
              'MR1682KN','MR2504','MR1232','MR0806','MR2608','MR2111','MR1682','MR2504KN',
              'MR1232KN','MR0806KN','MR2608KN','MR2111KN','MR2993','MR2993KN','MR3038','MR3038KN',
              'MR2948','MR2948KN','MR2608','MR3196','MR3196KN'
        ) THEN l.col.ma_nvbh
      ELSE IFNULL(c.manv, b.slsperid) 
    END AS manv,
    b.invtid AS san_pham,
    a.custid,
    a.crtd_datetime,
    (CASE WHEN a.ordertype IN ('CO') THEN -1 * b.lineqty ELSE b.lineqty END) AS qty
  FROM `staging.sync_dms_pda_so` a
  INNER JOIN `staging.sync_dms_pda_sod` b ON a.ordernbr = b.ordernbr AND a.branchid = b.branchid
  -- Inner join để thu hẹp dữ liệu các sản phẩm đang được phân bổ
  INNER JOIN (SELECT DISTINCT san_pham FROM phan_bo WHERE san_pham IS NOT NULL) pb ON pb.san_pham = b.invtid
  LEFT JOIN `warehouse.f_mapping_crs` l ON l.custid = a.custid
  -- Join với bảng sales đã được tối ưu filter ngaychungtu
  LEFT JOIN sales c ON c.sodondathang = a.ordernbr AND c.macongtycn = a.branchid AND c.masanpham = b.invtid
  WHERE 
    a.ordertype IN ('IN','CO') 
    AND a.status = 'C'
    -- Tối ưu hóa: chỉ lấy giao dịch từ thời điểm theo dõi sớm nhất trở đi
    AND DATE(a.crtd_datetime) >= (SELECT DATE(MIN(theo_doi_tu_ngay)) FROM phan_bo)
)

SELECT
  CAST(NULL AS INT64) AS stt,
  a.ma_crm,
  a.ten_crm,
  a.ma_crs AS msnv,
  a.ten_crs,
  a.so_luong_ban_dau AS soluong_benita_xylo_duoc_phan_bo,
  a.chi_nhanh AS kho,
  IFNULL(SUM(b.qty), 0) AS soluong_da_duyet,
  -- Số lượng khách hàng và sản phẩm gom về tính chung trong khoảng thời gian theo dõi của bảng phân bổ
  COUNT(DISTINCT b.custid) AS slkh_tu_dau_thang,
  IFNULL(SUM(b.qty), 0) AS slsp_tu_dau_thang
FROM phan_bo a
LEFT JOIN raw_trans b 
  ON a.ma_crs = b.manv 
  AND a.san_pham = b.san_pham
  -- Kiểm tra logic thời gian tracking từ ngày đến ngày theo từng dòng phân bổ
  AND TIMESTAMP(b.crtd_datetime) >= a.theo_doi_tu_ngay
  AND TIMESTAMP(b.crtd_datetime) <= a.theo_doi_den_ngay
GROUP BY ALL;;