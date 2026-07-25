CREATE VIEW `spatial-vision-343005.warehouse.view_theo_doi_hang_hoa_phan_bo`
AS WITH cac_sp_duoc_phan_bo AS (
  SELECT DISTINCT
    a.invtid,
  FROM `spatial-vision-343005.staging.d_rawdatadistprogram` a
  WHERE a.dangung IS NOT NULL
    AND DATE(a.todate) >= CURRENT_DATE()
),
data_sales AS(
SELECT 
a.slsperid,
a.invtid,
-- Tính toán xuất bán riêng cho từng chi nhánh dựa theo branchid
    SUM(CASE WHEN branchid = 'HYN017' AND IFNULL(trangthai_hoadon,'none') = 'Đã phát hành' THEN LineQty ELSE 0 END) AS xuatban_HYN017,
    SUM(CASE WHEN branchid = 'DNG013' AND IFNULL(trangthai_hoadon,'none') = 'Đã phát hành' THEN LineQty ELSE 0 END) AS xuatban_DNG013,
    SUM(CASE WHEN branchid = 'HCM001' AND IFNULL(trangthai_hoadon,'none') = 'Đã phát hành' THEN LineQty ELSE 0 END) AS xuatban_HCM001,
    SUM(CASE WHEN IFNULL(trangthai_hoadon,'none') = 'Đã phát hành' THEN LineQty ELSE 0 END) AS xuatban_TONG,

    -- Tính toán đơn treo riêng cho từng chi nhánh dựa theo branchid
    SUM(CASE WHEN branchid = 'HYN017' AND IFNULL(trangthai_hoadon,'none') != 'Đã phát hành' THEN LineQty ELSE 0 END) AS dontreo_HYN017,
    SUM(CASE WHEN branchid = 'DNG013' AND IFNULL(trangthai_hoadon,'none') != 'Đã phát hành' THEN LineQty ELSE 0 END) AS dontreo_DNG013,
    SUM(CASE WHEN branchid = 'HCM001' AND IFNULL(trangthai_hoadon,'none') != 'Đã phát hành' THEN LineQty ELSE 0 END) AS dontreo_HCM001,
    SUM(CASE WHEN IFNULL(trangthai_hoadon,'none') != 'Đã phát hành' THEN LineQty ELSE 0 END) AS dontreo_TONG
FROM `spatial-vision-343005.warehouse.f_trangthaidonhang_new` a
LEFT JOIN cac_sp_duoc_phan_bo b ON b.invtid = a.invtid
WHERE DATE(crtd_datetime) >= DATE_TRUNC(CURRENT_DATE(), MONTH)
AND channel in ('MT','TP','GT')
AND branchid IN ('HYN017', 'DNG013', 'HCM001')
AND b.invtid is not null
GROUP BY ALL
)
,phan_bo_hang_hoa AS (
SELECT 
a.invtid,
a.supid,
a.tencrm,
a.macrs,
a.tencrs,
MAX(a.descr) AS descr,
CASE 
    WHEN b.tenquanlyvung LIKE '%Sa%' THEN 'MT'
    WHEN b.tenquanlyvung LIKE '%Viễn%' OR b.tenquanlyvung LIKE '%Viển%' THEN 'TP'
    WHEN b.tenquanlyvung LIKE '%Mừng%' THEN 'HCP'
    ELSE 'OTHER'
  END AS phong_ban,
-- Chia sản lượng phân bổ về từng chi nhánh cụ thể ngay tại đây
    SUM(CASE WHEN a.cpnyid = 'HYN017' THEN slphanbochonv ELSE 0 END) AS phanbo_HYN017,
    SUM(CASE WHEN a.cpnyid = 'DNG013' THEN slphanbochonv ELSE 0 END) AS phanbo_DNG013,
    SUM(CASE WHEN a.cpnyid = 'HCM001' THEN slphanbochonv ELSE 0 END) AS phanbo_HCM001,
    SUM(slphanbochonv) AS phanbo_TONG
FROM `spatial-vision-343005.staging.d_rawdatadistprogram` a
LEFT JOIN `staging.d_users` b 
  ON b.manv = a.macrs
--LEFT JOIN data_sales b ON a.invtid = b.invtid AND b.channel = a.channel
WHERE
a.dangung IS NULL
AND DATE(a.todate) >= CURRENT_DATE()
GROUP BY ALL
),

ton_kho AS (
SELECT 
a.invtid,
-- Tính toán tồn cuối riêng cho từng chi nhánh dựa theo branchid
SUM(CASE WHEN branchid = 'HYN017' THEN toncuoi ELSE 0 END) AS tonkho_HYN017,
SUM(CASE WHEN branchid = 'DNG013' THEN toncuoi ELSE 0 END) AS tonkho_DNG013,
SUM(CASE WHEN branchid = 'HCM001' THEN toncuoi ELSE 0 END) AS tonkho_HCM001,
SUM(toncuoi) AS tonkho_TONG
FROM `spatial-vision-343005.warehouse.view_f_sc_daily_raw_invt_by_users` a
LEFT JOIN cac_sp_duoc_phan_bo b ON b.invtid = a.invtid
WHERE siteid in ('Y0629','Y0632','Y0635')
AND b.invtid is not null
GROUP BY ALL
)
-- TẦNG CUỐI: Kết hợp dữ liệu dựa trên khung danh mục động vừa tạo
SELECT
  a.invtid AS product_code,
  a.descr AS product_name, -- Lấy chuẩn tên từ danh mục phân bổ gốc
  a.phong_ban,
  a.macrs,
  a.tencrs,
  CASE 
    WHEN a.macrs = 'TMDT_001' THEN 'MR1682' 
    ELSE b.supid 
  END AS supid,
  
  CASE 
    WHEN a.macrs = 'TMDT_001' THEN 'Đinh Thị Ngọc Mẫn' 
    ELSE b.tenquanlytt 
  END AS tencrm,
  
  b.asm,
  b.tenquanlykhuvuc,
  b.rsmid,
  b.tenquanlyvung,


  -- ================= NỘI DUNG 1: PHÂN BỔ ĐẦU KỲ =================
  IFNULL(a.phanbo_HYN017, 0) AS phanbo_HYN017,
  IFNULL(a.phanbo_DNG013, 0) AS phanbo_DNG013,
  IFNULL(a.phanbo_HCM001, 0) AS phanbo_HCM001,
  IFNULL(a.phanbo_TONG, 0) AS phanbo_TONG1,

  -- ================= NỘI DUNG 2: XUẤT BÁN NGÀY HIỆN TẠI =================
  IFNULL(s.xuatban_HYN017, 0) AS xuatban_HYN017,
  IFNULL(s.xuatban_DNG013, 0) AS xuatban_DNG013,
  IFNULL(s.xuatban_HCM001, 0) AS xuatban_HCM001,
  IFNULL(s.xuatban_TONG, 0) AS xuatban_TONG2,

  -- ================= NỘI DUNG 3: ĐƠN TREO NGÀY HIỆN TẠI =================
  IFNULL(s.dontreo_HYN017, 0) AS dontreo_HYN017,
  IFNULL(s.dontreo_DNG013, 0) AS dontreo_DNG013,
  IFNULL(s.dontreo_HCM001, 0) AS dontreo_HCM001,
  IFNULL(s.dontreo_TONG, 0) AS dontreo_TONG3,

  -- ================= NỘI DUNG 4: SL CÒN LẠI NGÀY HIỆN TẠI =================
  (IFNULL(a.phanbo_HYN017, 0) - IFNULL(s.xuatban_HYN017, 0) - IFNULL(s.dontreo_HYN017, 0)) AS conlai_HYN017,
  (IFNULL(a.phanbo_DNG013, 0) - IFNULL(s.xuatban_DNG013, 0) - IFNULL(s.dontreo_DNG013, 0)) AS conlai_DNG013,
  (IFNULL(a.phanbo_HCM001, 0) - IFNULL(s.xuatban_HCM001, 0) - IFNULL(s.dontreo_HCM001, 0)) AS conlai_HCM001,
  (IFNULL(a.phanbo_TONG, 0) - IFNULL(s.xuatban_TONG, 0) - IFNULL(s.dontreo_TONG, 0)) AS conlai_TONG4,

  -- ================= NỘI DUNG 5: TỒN KHO =================
  IFNULL(c.tonkho_HYN017, 0) AS tonkho_HYN017,
  IFNULL(c.tonkho_DNG013, 0) AS tonkho_DNG013,
  IFNULL(c.tonkho_HCM001, 0) AS tonkho_HCM001,
  IFNULL(c.tonkho_TONG, 0) AS tonkho_TONG5

FROM phan_bo_hang_hoa a
LEFT JOIN `staging.d_users` b 
  ON b.manv = a.macrs
LEFT JOIN data_sales s 
  ON s.invtid = a.invtid 
 AND s.slsperid = a.macrs
LEFT JOIN ton_kho c 
  ON a.invtid = c.invtid











;