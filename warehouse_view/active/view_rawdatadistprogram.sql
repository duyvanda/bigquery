CREATE VIEW `spatial-vision-343005.warehouse.view_rawdatadistprogram`
AS WITH don_treo AS (
  -- Đơn treo chi tiết theo từng nhân viên (Logic cũ)
  SELECT 
    branchid,
    slsperid,
    invtid,
    SUM(lineqty) AS sl_sp_don_treo
  FROM `spatial-vision-343005.staging.f_sales_pending`
  GROUP BY 1, 2, 3
),
don_treo_mt AS (
  -- Đơn treo tổng của toàn chi nhánh & sản phẩm lấy chuẩn theo kênh MT (Dành riêng cho MR2685)
  SELECT 
    branchid,
    invtid,
    SUM(lineqty) AS sl_sp_don_treo_mt
  FROM `spatial-vision-343005.staging.f_sales_pending`
  WHERE channel = 'MT'
  GROUP BY 1, 2
),
sales_mt AS (
  -- Doanh số kênh MT từ ngày 2026-06-01 trở đi
  SELECT 
    macongtycn,
    masanpham,
    SUM(soluong) AS sl_ban_mt
  FROM `warehouse.view_raw_data_theo_don_hang`
  WHERE ngaychungtu >= '2026-06-01'
    AND makenhkh_cu = 'MT' 
  GROUP BY 1, 2
)

SELECT 
  -- Đã bỏ sl_sp_don_treo ra khỏi hàm EXCEPT
  a.* EXCEPT(supid, tencrm, slnvdasudung, slconlaicuanv),
  
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

  -- THÊM CỘT PHÒNG BAN DỰA TRÊN TÊN CRD
  CASE 
    WHEN b.tenquanlyvung LIKE '%Sa%' THEN 'MT'
    WHEN b.tenquanlyvung LIKE '%Viễn%' OR b.tenquanlyvung LIKE '%Viển%' THEN 'TP'
    WHEN b.tenquanlyvung LIKE '%Mừng%' THEN 'HCP'
    ELSE 'OTHER'
  END AS phong_ban,
  
  CASE 
    WHEN a.dangung IS NOT NULL THEN 'Hết hiệu lực'
    WHEN DATE(a.todate) < CURRENT_DATE() THEN 'Hết hiệu lực'
    ELSE 'Còn hiệu lực' 
  END AS hieu_luc_phan_bo,

  -- 1. Xử lý cột slnvdasudung
  CASE 
    WHEN a.macrs = 'MR2685' THEN COALESCE(s.sl_ban_mt, 0)
    ELSE a.slnvdasudung 
  END AS slnvdasudung,
  
  -- 2. Xử lý cột sl_sp_don_treo
  CASE 
    WHEN a.macrs = 'MR2685' THEN COALESCE(dt_mt.sl_sp_don_treo_mt, 0)
    ELSE COALESCE(c.sl_sp_don_treo, 0)
  END AS sl_sp_don_treo,
  
  -- 3. Xử lý cột slconlaicuanv = Phân bổ - Đã sử dụng - Đơn treo
  a.slphanbochonv 
  - (CASE WHEN a.macrs = 'MR2685' THEN COALESCE(s.sl_ban_mt, 0) ELSE a.slnvdasudung END) 
  - (CASE WHEN a.macrs = 'MR2685' THEN COALESCE(dt_mt.sl_sp_don_treo_mt, 0) ELSE COALESCE(c.sl_sp_don_treo, 0) END) 
  AS slconlaicuanv

FROM `spatial-vision-343005.staging.d_rawdatadistprogram` a
LEFT JOIN `staging.d_users` b 
  ON b.manv = a.macrs
LEFT JOIN don_treo c 
  ON c.invtid = a.invtid 
  AND c.slsperid = a.macrs 
  AND c.branchid = a.cpnyid
LEFT JOIN don_treo_mt dt_mt 
  ON dt_mt.invtid = a.invtid 
  AND dt_mt.branchid = a.cpnyid
LEFT JOIN sales_mt s 
  ON s.macongtycn = a.cpnyid 
  AND s.masanpham = a.invtid;;