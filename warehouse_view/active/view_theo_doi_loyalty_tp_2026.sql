CREATE VIEW `spatial-vision-343005.warehouse.view_theo_doi_loyalty_tp_2026`
AS WITH 
-- =========================================================================
-- CTE 1: TÍNH TOÁN TOÀN BỘ SỐ LIỆU (QUÝ CÓ LỌC & KỲ/NĂM KHÔNG LỌC)
-- =========================================================================
RawData AS (
  SELECT 
    s.makhdms AS custid,
    s.inserted_at,
    s.datatype,
    s.doanhsochuavat,
    quy_tham_gia,
    hieu_luc_hd_ket_thuc,
    EXTRACT(QUARTER FROM s.ngaychungtu) AS q,
    -- Đặt cờ TRUE/FALSE nếu ngày chứng từ nằm trong khoảng hiệu lực hợp đồng
    DATE(s.ngaychungtu) BETWEEN DATE(f.hieu_luc_hd) AND DATE(f.hieu_luc_hd_ket_thuc) AS is_hieu_luc
  FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` s
  JOIN `spatial-vision-343005.staging.form_theo_doi_CSBH_loyalty_TP_2026` f
    ON s.makhdms = f.ma_kh
  WHERE 
    s.makenhkh = 'TP'
    AND s.ngaychungtu BETWEEN '2026-01-01' AND '2026-12-26'
)
, sales_ky_nam AS (
  SELECT 
    s.makhdms AS custid,
    -- KỲ 1 (Q1, Q2)
    SUM(IF(EXTRACT(QUARTER FROM s.ngaychungtu) IN (1, 2) AND s.datatype = 'N1', s.doanhsochuavat, 0)) AS ds_n1_ky1,
    SUM(IF(EXTRACT(QUARTER FROM s.ngaychungtu) IN (1, 2) AND s.datatype = 'N2', s.doanhsochuavat, 0)) AS ds_n2_ky1,
    SUM(IF(EXTRACT(QUARTER FROM s.ngaychungtu) IN (1, 2) AND s.datatype IN ('N3', 'N4'), s.doanhsochuavat, 0)) AS ds_n3_n4_ky1,
    SUM(IF(EXTRACT(QUARTER FROM s.ngaychungtu) IN (1, 2), s.doanhsochuavat, 0))  AS tong_ds_ky1,
    
    -- KỲ 2 (Q3, Q4)
    SUM(IF(EXTRACT(QUARTER FROM s.ngaychungtu) IN (3, 4) AND s.datatype = 'N1', s.doanhsochuavat, 0)) AS ds_n1_ky2,
    SUM(IF(EXTRACT(QUARTER FROM s.ngaychungtu) IN (3, 4) AND s.datatype = 'N2', s.doanhsochuavat, 0)) AS ds_n2_ky2,
    SUM(IF(EXTRACT(QUARTER FROM s.ngaychungtu) IN (3, 4) AND s.datatype IN ('N3', 'N4'), s.doanhsochuavat, 0)) AS ds_n3_n4_ky2,
    SUM(IF(EXTRACT(QUARTER FROM s.ngaychungtu) IN (3, 4), s.doanhsochuavat, 0))  AS tong_ds_ky2,

    -- CẢ NĂM
    SUM(IF(s.datatype = 'N1', s.doanhsochuavat, 0)) AS ds_n1_nam,
    SUM(IF(s.datatype = 'N2', s.doanhsochuavat, 0)) AS ds_n2_nam,
    SUM(IF(s.datatype IN ('N3', 'N4'), s.doanhsochuavat, 0)) AS ds_n3_n4_nam,
    SUM(s.doanhsochuavat) AS tong_ds_nam
  FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` s
  WHERE 
    s.makenhkh = 'TP'
    AND s.ngaychungtu BETWEEN '2026-01-01' AND '2026-12-26'
  GROUP BY s.makhdms
)

, sales_data AS (
    SELECT 
    r.custid,
    r.quy_tham_gia,
    MAX(r.inserted_at) AS inserted_at,
    -- A. SỐ LIỆU QUÝ (CÓ LỌC NGÀY HIỆU LỰC)
    -- Quý 1
    SUM(IF(q = 1 AND datatype = 'N1' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n1_q1,
    SUM(IF(q = 1 AND datatype = 'N2' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n2_q1,
    SUM(IF(q = 1 AND datatype IN ('N3', 'N4') AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n3_n4_q1,
    SUM(IF(q = 1 AND is_hieu_luc, doanhsochuavat, 0)) AS tong_ds_q1,

    -- Quý 2
    SUM(IF(q = 2 AND datatype = 'N1' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n1_q2,
    SUM(IF(q = 2 AND datatype = 'N2' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n2_q2,
    SUM(IF(q = 2 AND datatype IN ('N3', 'N4') AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n3_n4_q2,
    SUM(IF(q = 2 AND is_hieu_luc, doanhsochuavat, 0)) AS tong_ds_q2,

    -- Quý 3
    SUM(IF(q = 3 AND datatype = 'N1' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n1_q3,
    SUM(IF(q = 3 AND datatype = 'N2' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n2_q3,
    SUM(IF(q = 3 AND datatype IN ('N3', 'N4') AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n3_n4_q3,
    SUM(IF(q = 3 AND is_hieu_luc, doanhsochuavat, 0)) AS tong_ds_q3,

    -- Quý 4
    SUM(IF(q = 4 AND datatype = 'N1' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n1_q4,
    SUM(IF(q = 4 AND datatype = 'N2' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n2_q4,
    SUM(IF(q = 4 AND datatype IN ('N3', 'N4') AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n3_n4_q4,
    SUM(IF(q = 4 AND is_hieu_luc, doanhsochuavat, 0)) AS tong_ds_q4,

    -- KỲ 1
    MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-06-01' THEN n.ds_n1_ky1 ELSE 0 END) AS ds_n1_ky1,
    MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-06-01' THEN n.ds_n2_ky1 ELSE 0 END) AS ds_n2_ky1,
    MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-06-01' THEN n.ds_n3_n4_ky1 ELSE 0 END) AS ds_n3_n4_ky1,
    MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-06-01' THEN n.tong_ds_ky1 ELSE 0 END) AS tong_ds_ky1,

    -- KỲ 2
    MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-12-26' THEN n.ds_n1_ky2 ELSE 0 END) AS ds_n1_ky2,
    MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-12-26' THEN n.ds_n2_ky2 ELSE 0 END) AS ds_n2_ky2,
    MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-12-26' THEN n.ds_n3_n4_ky2 ELSE 0 END) AS ds_n3_n4_ky2,
    MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-12-26' THEN n.tong_ds_ky2 ELSE 0 END) AS tong_ds_ky2,
    -- NĂM
    MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-12-26' THEN n.ds_n1_nam ELSE 0 END) AS ds_n1_nam,
    MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-12-26' THEN n.ds_n2_nam ELSE 0 END) AS ds_n2_nam,
    MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-12-26' THEN n.ds_n3_n4_nam ELSE 0 END) AS ds_n3_n4_nam,
    MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-12-26' THEN n.tong_ds_nam ELSE 0 END) AS tong_ds_nam

    FROM RawData r
    LEFT JOIN sales_ky_nam n ON r.custid = n.custid
    GROUP BY custid, quy_tham_gia 
),

-- =========================================================================
-- CTE 2: TÍNH TOÁN LOGIC % THƯỞNG, TIỀN THƯỞNG, QUÀ, XẾP HẠNG
-- =========================================================================
sales_rewards AS (
  SELECT 
    t.*,

    -- A. LOGIC KỲ 1
    CASE WHEN t.tong_ds_ky1 >= 300000000 THEN 0.04 WHEN t.tong_ds_ky1 >= 120000000 THEN 0.03 WHEN t.tong_ds_ky1 >= 60000000 THEN 0.02 WHEN t.tong_ds_ky1 >= 30000000 THEN 0.01 ELSE 0 END AS pct_n1_ky1,
    CASE WHEN t.tong_ds_ky1 >= 300000000 THEN 0.08 WHEN t.tong_ds_ky1 >= 120000000 THEN 0.07 WHEN t.tong_ds_ky1 >= 60000000 THEN 0.06 WHEN t.tong_ds_ky1 >= 30000000 THEN 0.05 ELSE 0 END AS pct_n2_ky1,
    CASE WHEN t.tong_ds_ky1 >= 300000000 THEN 0.05 WHEN t.tong_ds_ky1 >= 120000000 THEN 0.04 WHEN t.tong_ds_ky1 >= 60000000 THEN 0.03 WHEN t.tong_ds_ky1 >= 30000000 THEN 0.02 ELSE 0 END AS pct_n3_n4_ky1,

   -- B. LOGIC KỲ 2 - BỔ SUNG MỚI (Dùng cùng hạn mức với Kỳ 1)
    CASE WHEN t.tong_ds_ky2 >= 300000000 THEN 0.04 WHEN t.tong_ds_ky2 >= 120000000 THEN 0.03 WHEN t.tong_ds_ky2 >= 60000000 THEN 0.02 WHEN t.tong_ds_ky2 >= 30000000 THEN 0.01 ELSE 0 END AS pct_n1_ky2,
    CASE WHEN t.tong_ds_ky2 >= 300000000 THEN 0.08 WHEN t.tong_ds_ky2 >= 120000000 THEN 0.07 WHEN t.tong_ds_ky2 >= 60000000 THEN 0.06 WHEN t.tong_ds_ky2 >= 30000000 THEN 0.05 ELSE 0 END AS pct_n2_ky2,
    CASE WHEN t.tong_ds_ky2 >= 300000000 THEN 0.05 WHEN t.tong_ds_ky2 >= 120000000 THEN 0.04 WHEN t.tong_ds_ky2 >= 60000000 THEN 0.03 WHEN t.tong_ds_ky2 >= 30000000 THEN 0.02 ELSE 0 END AS pct_n3_n4_ky2, 

    -- C. LOGIC CẢ NĂM
    CASE WHEN t.tong_ds_nam >= 600000000 THEN 0.04 WHEN t.tong_ds_nam >= 240000000 THEN 0.03 WHEN t.tong_ds_nam >= 120000000 THEN 0.02 WHEN t.tong_ds_nam >= 60000000 THEN 0.01 ELSE 0 END AS pct_n1_nam,
    CASE WHEN t.tong_ds_nam >= 600000000 THEN 0.08 WHEN t.tong_ds_nam >= 240000000 THEN 0.07 WHEN t.tong_ds_nam >= 120000000 THEN 0.06 WHEN t.tong_ds_nam >= 60000000 THEN 0.05 ELSE 0 END AS pct_n2_nam,
    CASE WHEN t.tong_ds_nam >= 600000000 THEN 0.05 WHEN t.tong_ds_nam >= 240000000 THEN 0.04 WHEN t.tong_ds_nam >= 120000000 THEN 0.03 WHEN t.tong_ds_nam >= 60000000 THEN 0.02 ELSE 0 END AS pct_n3_n4_nam,

    -- Quà Tết, Điểm, Xếp hạng
    CASE 
      WHEN t.tong_ds_nam >= 600000000 THEN 2100000
      WHEN t.tong_ds_nam >= 120000000 THEN 700000
      WHEN t.tong_ds_nam >= 36000000 THEN 350000 
      ELSE 0 
    END AS gia_tri_qua_tet,

    CASE 
      WHEN t.tong_ds_nam >= 600000000 THEN 1400000
      WHEN t.tong_ds_nam >= 240000000 THEN 700000
      WHEN t.tong_ds_nam >= 60000000 THEN 350000
      ELSE 0 
    END AS gia_tri_qua_cam_xuc

  FROM sales_data t
  
)

, thong_tin_ky_hop_dong as (
SELECT
distinct ma_khach_hang,
trang_thai_ky,
internal_promo_code
FROm `spatial-vision-343005.warehouse.view_data_contract_sign_by_users`
where
internal_promo_code ='202601-TL-QD785-PMC-CTD'
and trang_thai_ky = 'Đã ký'
)

, thong_tin_ky_bang_ke as (
SELECT
distinct ma_khach_hang,
trang_thai_ky,
internal_promo_code
FROm `spatial-vision-343005.warehouse.view_data_contract_sign_by_users`
where
internal_promo_code ='202601-TL-QD785-PMC-CTD-BK-Q1-2026'
and trang_thai_ky = 'Đã ký'
)
, thu_hoi_hd_ky_tay_unique AS (
  SELECT *
  FROM `spatial-vision-343005.staging.theo_doi_thu_hoi_chung_tu_ky_ben_ngoai_loyaty_2026`
  -- Lấy dòng có cập nhật mới nhất, mỗi ma_kh chỉ lấy đúng 1 dòng
  QUALIFY ROW_NUMBER() OVER(PARTITION BY ma_kh ORDER BY ngay_thu_hoi DESC) = 1
)

-- =========================================================================
-- CTE LỚP 1: BASE_METRICS (GOM BẢNG VÀ TÍNH TỶ LỆ)
-- =========================================================================
, base_metrics AS (
  SELECT
    a.asm, a.tenquanlykhuvuc, a.supid AS ma_crm, a.tenquanlytt AS crm, a.col.ma_nvbh AS ma_crs, a.tencvbh AS crs,
    b.ma_kh, b.ten_kh, b.tinh, c.hcoid AS ma_hco, b.pl_hco AS ma_loai_hco, c.stocksales AS tinh_trang_mst,
    b.hang_thanh_vien_2025, b.quy_tham_gia, b.phan_tram_tham_gia, b.kenh, c.shoptype as kenh_phu, branchid,
    CASE WHEN DATE(c.legaldate) >= DATE_ADD(CURRENT_DATE(), INTERVAL 7 DAY) THEN 'Còn hiệu lực' ELSE 'Hết hiệu lực' END AS hieu_luc_gpp_gdp,
    b.muc_hd_2026, b.dk_doanh_so_quy, b.n1, b.n2, b.n3_n4, b.hieu_luc_hd,hieu_luc_hd_ket_thuc, b.hinh_thuc_tra, d.inserted_at,

    -- Trạng thái
    CASE WHEN t.ngay_thu_hoi is not null OR e.ma_khach_hang is not null THEN 'Đã thu' ELSE 'Chưa thu' END AS hop_dong_da_thu_chua_thu,
    CASE WHEN t.ngay_thu_hoi is not null then 'Ký tay'
         WHEN e.ma_khach_hang is not null THEN 'Ký số'
         ELSE null end as ky_tay_ky_so_hd,
    NULL AS phu_luc_da_thu_chua_thu,
    CASE WHEN f.ngay_thu_hoi_hop_dong_ky_tay is not null OR g.ma_khach_hang is not null THEN 'Đã thu' ELSE 'Chưa thu' END AS bang_ke_da_thu_chua_thu_q1, 

    -- Doanh số Quý
    COALESCE(d.ds_n1_q1, 0) AS ds_n1_q1, COALESCE(d.ds_n2_q1, 0) AS ds_n2_q1, COALESCE(d.ds_n3_n4_q1, 0) AS ds_n3_n4_q1, COALESCE(d.tong_ds_q1, 0) AS tong_ds_q1,
    COALESCE(d.ds_n1_q2, 0) AS ds_n1_q2, COALESCE(d.ds_n2_q2, 0) AS ds_n2_q2, COALESCE(d.ds_n3_n4_q2, 0) AS ds_n3_n4_q2, COALESCE(d.tong_ds_q2, 0) AS tong_ds_q2,
    COALESCE(d.ds_n1_q3, 0) AS ds_n1_q3, COALESCE(d.ds_n2_q3, 0) AS ds_n2_q3, COALESCE(d.ds_n3_n4_q3, 0) AS ds_n3_n4_q3, COALESCE(d.tong_ds_q3, 0) AS tong_ds_q3,
    COALESCE(d.ds_n1_q4, 0) AS ds_n1_q4, COALESCE(d.ds_n2_q4, 0) AS ds_n2_q4, COALESCE(d.ds_n3_n4_q4, 0) AS ds_n3_n4_q4, COALESCE(d.tong_ds_q4, 0) AS tong_ds_q4,

    -- Tỷ lệ thực thi Quý so với điều kiện Q
    SAFE_DIVIDE(COALESCE(d.tong_ds_q1, 0), b.dk_doanh_so_quy) AS pct_th_q1,
    SAFE_DIVIDE(COALESCE(d.tong_ds_q2, 0), b.dk_doanh_so_quy) AS pct_th_q2,
    SAFE_DIVIDE(COALESCE(d.tong_ds_q3, 0), b.dk_doanh_so_quy) AS pct_th_q3,
    SAFE_DIVIDE(COALESCE(d.tong_ds_q4, 0), b.dk_doanh_so_quy) AS pct_th_q4,

    -- Lũy kế Tổng
    COALESCE(d.tong_ds_q1, 0) AS lk_tong_q1,
    (COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0)) AS lk_tong_q2,
    (COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0) + COALESCE(d.tong_ds_q3, 0)) AS lk_tong_q3,
    (COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0) + COALESCE(d.tong_ds_q3, 0) + COALESCE(d.tong_ds_q4, 0)) AS lk_tong_q4,

    -- Lũy kế từng nhóm (N1, N2, N3_N4) theo cách cộng dồn tương tự
    -- Q1
    COALESCE(d.ds_n1_q1, 0) AS lk_n1_q1,
    COALESCE(d.ds_n2_q1, 0) AS lk_n2_q1,
    COALESCE(d.ds_n3_n4_q1, 0) AS lk_n3_n4_q1,
    
    -- Q2
    (COALESCE(d.ds_n1_q1, 0) + COALESCE(d.ds_n1_q2, 0)) AS lk_n1_q2,
    (COALESCE(d.ds_n2_q1, 0) + COALESCE(d.ds_n2_q2, 0)) AS lk_n2_q2,
    (COALESCE(d.ds_n3_n4_q1, 0) + COALESCE(d.ds_n3_n4_q2, 0)) AS lk_n3_n4_q2,
    
    -- Q3
    (COALESCE(d.ds_n1_q1, 0) + COALESCE(d.ds_n1_q2, 0) + COALESCE(d.ds_n1_q3, 0)) AS lk_n1_q3,
    (COALESCE(d.ds_n2_q1, 0) + COALESCE(d.ds_n2_q2, 0) + COALESCE(d.ds_n2_q3, 0)) AS lk_n2_q3,
    (COALESCE(d.ds_n3_n4_q1, 0) + COALESCE(d.ds_n3_n4_q2, 0) + COALESCE(d.ds_n3_n4_q3, 0)) AS lk_n3_n4_q3,
    
    -- Q4
    (COALESCE(d.ds_n1_q1, 0) + COALESCE(d.ds_n1_q2, 0) + COALESCE(d.ds_n1_q3, 0) + COALESCE(d.ds_n1_q4, 0)) AS lk_n1_q4,
    (COALESCE(d.ds_n2_q1, 0) + COALESCE(d.ds_n2_q2, 0) + COALESCE(d.ds_n2_q3, 0) + COALESCE(d.ds_n2_q4, 0)) AS lk_n2_q4,
    (COALESCE(d.ds_n3_n4_q1, 0) + COALESCE(d.ds_n3_n4_q2, 0) + COALESCE(d.ds_n3_n4_q3, 0) + COALESCE(d.ds_n3_n4_q4, 0)) AS lk_n3_n4_q4,

    -- Tỷ lệ Lũy kế
    SAFE_DIVIDE(
      COALESCE(d.tong_ds_q1, 0), 
      b.dk_doanh_so_quy
    ) AS pct_lk_q1,

  CASE 
    -- Nếu ký HĐ từ Quý 1 (hiệu lực trước ngày 1/4): Doanh số lũy kế chia cho (Mức DS Quý * 2)
    WHEN DATE(b.hieu_luc_hd) = '2026-01-01' THEN 
      SAFE_DIVIDE((COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0)), b.dk_doanh_so_quy * 2)
      
    -- Nếu ký HĐ từ Quý 2 (hiệu lực từ ngày 1/4 trở đi): Doanh số lũy kế chia cho (Mức DS Quý) không nhân 2
    WHEN DATE(b.hieu_luc_hd) = '2026-04-01' THEN 
      SAFE_DIVIDE((COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0)), b.dk_doanh_so_quy)
      
    ELSE 0 
  END AS pct_lk_q2,

  CASE 
    -- Ký từ Q1 (1/1): Lũy kế 3 quý chia (Mức DS Quý * 3)
    WHEN DATE(b.hieu_luc_hd) = '2026-01-01' THEN 
      SAFE_DIVIDE((COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0) + COALESCE(d.tong_ds_q3, 0)), b.dk_doanh_so_quy * 3)
      
    -- Ký từ Q2 (1/4): Lũy kế Q2+Q3 chia (Mức DS Quý * 2)
    WHEN DATE(b.hieu_luc_hd) = '2026-04-01' THEN 
      SAFE_DIVIDE((COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0) + COALESCE(d.tong_ds_q3, 0)), b.dk_doanh_so_quy * 2)
      
    -- Ký từ Q3 (1/7): Lũy kế Q3 chia (Mức DS Quý)
    WHEN DATE(b.hieu_luc_hd) = '2026-07-01' THEN 
      SAFE_DIVIDE((COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0) + COALESCE(d.tong_ds_q3, 0)), b.dk_doanh_so_quy)
      
    ELSE 0 
  END AS pct_lk_q3,

  CASE 
    -- Ký từ Q1 (1/1): Lũy kế 4 quý chia (Mức DS Quý * 4)
    WHEN DATE(b.hieu_luc_hd) = '2026-01-01' THEN 
      SAFE_DIVIDE((COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0) + COALESCE(d.tong_ds_q3, 0) + COALESCE(d.tong_ds_q4, 0)), b.dk_doanh_so_quy * 4)
      
    -- Ký từ Q2 (1/4): Lũy kế 3 quý (Q2->Q4) chia (Mức DS Quý * 3)
    WHEN DATE(b.hieu_luc_hd) = '2026-04-01' THEN 
      SAFE_DIVIDE((COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0) + COALESCE(d.tong_ds_q3, 0) + COALESCE(d.tong_ds_q4, 0)), b.dk_doanh_so_quy * 3)
      
    -- Ký từ Q3 (1/7): Lũy kế 2 quý (Q3->Q4) chia (Mức DS Quý * 2)
    WHEN DATE(b.hieu_luc_hd) = '2026-07-01' THEN 
      SAFE_DIVIDE((COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0) + COALESCE(d.tong_ds_q3, 0) + COALESCE(d.tong_ds_q4, 0)), b.dk_doanh_so_quy * 2)
      
    -- Ký từ Q4 (1/10): Lũy kế Q4 chia (Mức DS Quý)
    WHEN DATE(b.hieu_luc_hd) = '2026-10-01' THEN 
      SAFE_DIVIDE((COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0) + COALESCE(d.tong_ds_q3, 0) + COALESCE(d.tong_ds_q4, 0)), b.dk_doanh_so_quy)
      
    ELSE 0 
  END AS pct_lk_q4,

    -- Dữ liệu Raw Kỳ & Năm
    COALESCE(d.tong_ds_ky1, 0) AS doanh_so_tong_ky_1, COALESCE(d.ds_n1_ky1, 0) AS ds_n1_ky1, COALESCE(d.ds_n2_ky1, 0) AS ds_n2_ky1, COALESCE(d.ds_n3_n4_ky1, 0) AS ds_n3_n4_ky1,
    d.pct_n1_ky1, d.pct_n2_ky1, d.pct_n3_n4_ky1,

    COALESCE(d.tong_ds_ky2, 0) AS tong_ds_ky2, COALESCE(d.ds_n1_ky2, 0) AS ds_n1_ky2, COALESCE(d.ds_n2_ky2, 0) AS ds_n2_ky2, COALESCE(d.ds_n3_n4_ky2, 0) AS ds_n3_n4_ky2,
    d.pct_n1_ky2, d.pct_n2_ky2, d.pct_n3_n4_ky2,
    
    COALESCE(d.tong_ds_nam, 0) AS doanh_so_tong_ca_nam, COALESCE(d.ds_n1_nam, 0) AS ds_n1_nam, COALESCE(d.ds_n2_nam, 0) AS ds_n2_nam, COALESCE(d.ds_n3_n4_nam, 0) AS ds_n3_n4_nam,
    d.pct_n1_nam, d.pct_n2_nam, d.pct_n3_n4_nam, d.gia_tri_qua_tet, d.gia_tri_qua_cam_xuc

  FROM `spatial-vision-343005.staging.form_theo_doi_CSBH_loyalty_TP_2026` AS b
  LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` AS a ON a.custid = b.ma_kh
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` AS c ON c.custid = b.ma_kh
  LEFT JOIN sales_rewards AS d ON d.custid = b.ma_kh AND d.quy_tham_gia = b.quy_tham_gia
  LEFT JOIN thu_hoi_hd_ky_tay_unique AS t ON t.ma_kh = b.ma_kh
  LEFT JOIN thong_tin_ky_hop_dong e ON e.ma_khach_hang = b.ma_kh
  LEFT JOIN `spatial-vision-343005.staging.theo_doi_thu_hoi_chung_tu_ky_ben_ngoai_bang_ke_loyaty_tp_pcl_q12026` AS f ON f.ma_kh = b.ma_kh
  LEFT JOIN thong_tin_ky_bang_ke g ON g.ma_khach_hang = b.ma_kh
),

-- =========================================================================
-- CTE LỚP 2 -> 5: TÍNH CUỐN CHIẾU ĐỂ XỬ LÝ LŨY KẾ
-- =========================================================================
calc_q1 AS (
  SELECT *,
    CASE WHEN pct_th_q1 >= 1 THEN ds_n1_q1 * n1 ELSE 0 END AS ck_n1_q1,
    CASE WHEN pct_th_q1 >= 1 THEN ds_n2_q1 * n2 ELSE 0 END AS ck_n2_q1,
    CASE WHEN pct_th_q1 >= 1 THEN ds_n3_n4_q1 * n3_n4 ELSE 0 END AS ck_n3_n4_q1,
    CASE WHEN pct_th_q1 < 1 AND pct_lk_q1 < 1 THEN tong_ds_q1 ELSE 0 END AS bl_q1,
    CASE WHEN pct_th_q1 < 1 AND pct_lk_q1 < 1 THEN 
      CASE 
          WHEN DATE(hieu_luc_hd) = '2026-01-01' THEN dk_doanh_so_quy - lk_tong_q1 
          ELSE 0
          END 
      ELSE 0 
    END AS thieu_q1
  FROM base_metrics
),

calc_q2 AS (
  SELECT *,
    CASE WHEN pct_lk_q2 >= 1 THEN (lk_n1_q2 * n1) - ck_n1_q1 WHEN pct_th_q2 >= 1 THEN ds_n1_q2 * n1 ELSE 0 END AS ck_n1_q2,
    CASE WHEN pct_lk_q2 >= 1 THEN (lk_n2_q2 * n2) - ck_n2_q1 WHEN pct_th_q2 >= 1 THEN ds_n2_q2 * n2 ELSE 0 END AS ck_n2_q2,
    CASE WHEN pct_lk_q2 >= 1 THEN (lk_n3_n4_q2 * n3_n4) - ck_n3_n4_q1 WHEN pct_th_q2 >= 1 THEN ds_n3_n4_q2 * n3_n4 ELSE 0 END AS ck_n3_n4_q2,
    CASE 
      WHEN pct_lk_q2 >= 1 THEN 0 
      ELSE bl_q1 + CASE WHEN pct_th_q2 < 1 THEN tong_ds_q2 ELSE 0 END 
    END AS bl_q2,

    CASE WHEN pct_th_q2 < 1 AND pct_lk_q2 < 1 THEN 
      CASE 
          WHEN DATE(hieu_luc_hd) = '2026-01-01' THEN (dk_doanh_so_quy * 2) - lk_tong_q2
          WHEN DATE(hieu_luc_hd) = '2026-04-01' THEN dk_doanh_so_quy - lk_tong_q2
          ELSE 0
      END 
          ELSE 0  
    END AS thieu_q2
  FROM calc_q1
),

calc_q3 AS (
  SELECT *,
    CASE WHEN pct_lk_q3 >= 1 THEN (lk_n1_q3 * n1) - (ck_n1_q1 + ck_n1_q2) WHEN pct_th_q3 >= 1 THEN ds_n1_q3 * n1 ELSE 0 END AS ck_n1_q3,
    CASE WHEN pct_lk_q3 >= 1 THEN (lk_n2_q3 * n2) - (ck_n2_q1 + ck_n2_q2) WHEN pct_th_q3 >= 1 THEN ds_n2_q3 * n2 ELSE 0 END AS ck_n2_q3,
    CASE WHEN pct_lk_q3 >= 1 THEN (lk_n3_n4_q3 * n3_n4) - (ck_n3_n4_q1 + ck_n3_n4_q2) WHEN pct_th_q3 >= 1 THEN ds_n3_n4_q3 * n3_n4 ELSE 0 END AS ck_n3_n4_q3,
    CASE 
      WHEN pct_lk_q3 >= 1 THEN 0 
      ELSE bl_q2 + CASE WHEN pct_th_q3 < 1 THEN tong_ds_q3 ELSE 0 END 
    END AS bl_q3,

    CASE WHEN pct_th_q3 < 1 AND pct_lk_q3 < 1 THEN 
      CASE 
          WHEN DATE(hieu_luc_hd) = '2026-01-01' THEN (dk_doanh_so_quy * 3) - lk_tong_q3
          WHEN DATE(hieu_luc_hd) = '2026-04-01' THEN (dk_doanh_so_quy * 2) - lk_tong_q3
          WHEN DATE(hieu_luc_hd) = '2026-07-01' THEN dk_doanh_so_quy - lk_tong_q3
          ELSE 0 
        END 
      ELSE 0 
    END AS thieu_q3
  FROM calc_q2
),

calc_q4 AS (
  SELECT *,
    CASE WHEN pct_lk_q4 >= 1.00 THEN (lk_n1_q4 * n1) - (ck_n1_q1 + ck_n1_q2 + ck_n1_q3) WHEN pct_th_q4 >= 1 THEN ds_n1_q4 * n1 ELSE 0 END AS ck_n1_q4,
    CASE WHEN pct_lk_q4 >= 1.00 THEN (lk_n2_q4 * n2) - (ck_n2_q1 + ck_n2_q2 + ck_n2_q3) WHEN pct_th_q4 >= 1 THEN ds_n2_q4 * n2 ELSE 0 END AS ck_n2_q4,
    CASE WHEN pct_lk_q4 >= 1.00 THEN (lk_n3_n4_q4 * n3_n4) - (ck_n3_n4_q1 + ck_n3_n4_q2 + ck_n3_n4_q3) WHEN pct_th_q4 >= 1 THEN ds_n3_n4_q4 * n3_n4 ELSE 0 END AS ck_n3_n4_q4,
    CASE 
      WHEN pct_lk_q4 >= 1.00 THEN 0 
      ELSE bl_q3 + CASE WHEN pct_th_q4 < 1 THEN tong_ds_q4 ELSE 0 END 
    END AS bl_q4,
    CASE WHEN pct_th_q4 < 1 AND pct_lk_q4 < 1.00 THEN 
       CASE 
          WHEN DATE(hieu_luc_hd) = '2026-01-01' THEN (dk_doanh_so_quy * 4) - lk_tong_q4
          WHEN DATE(hieu_luc_hd) = '2026-04-01' THEN (dk_doanh_so_quy * 3) - lk_tong_q4
          WHEN DATE(hieu_luc_hd) = '2026-07-01' THEN (dk_doanh_so_quy * 2) - lk_tong_q4
          WHEN DATE(hieu_luc_hd) = '2026-10-01' THEN dk_doanh_so_quy - lk_tong_q4
          ELSE 0 
        END 
       ELSE 0 
    END AS thieu_q4
  FROM calc_q3
)
, chiet_khau_da_thanh_toan as (
SELECT
  accumulateid,
  custid,
  SUM(Case when EXTRACT(QUARTER FROM CAST(todate AS DATE)) = 1 Then IF(left(ordernbr,2) = 'IR', paidamt * -1,paidamt) else 0 end ) as da_tra_q1,
  SUM(Case when EXTRACT(QUARTER FROM CAST(todate AS DATE)) = 2 Then IF(left(ordernbr,2) = 'IR', paidamt * -1,paidamt) else 0 end ) as da_tra_q2,
  SUM(Case when EXTRACT(QUARTER FROM CAST(todate AS DATE)) = 3 Then IF(left(ordernbr,2) = 'IR', paidamt * -1,paidamt) else 0 end ) as da_tra_q3,
  SUM(Case when EXTRACT(QUARTER FROM CAST(todate AS DATE)) = 4 Then IF(left(ordernbr,2) = 'IR', paidamt * -1,paidamt) else 0 end ) as da_tra_q4

FROM
  `spatial-vision-343005.staging.f_paidso_acculate`
WHERE
  accumulateid = '202601-TL-QD785-PMC-CTD'
GROUP BY ALL
)

SELECT
  -- THÔNG TIN CHUNG
  asm, tenquanlykhuvuc, ma_crm, crm, ifnull(ma_crs,'MRNULL') as ma_crs, crs,
  ma_kh, ten_kh, tinh, ma_hco, ma_loai_hco, tinh_trang_mst,
  hang_thanh_vien_2025, quy_tham_gia, phan_tram_tham_gia, kenh, kenh_phu, branchid,
  hieu_luc_gpp_gdp, hop_dong_da_thu_chua_thu, ky_tay_ky_so_hd,
  phu_luc_da_thu_chua_thu, 
  bang_ke_da_thu_chua_thu_q1,
  null as bang_ke_da_thu_chua_thu_q2,
  null as bang_ke_da_thu_chua_thu_q3,
  null as bang_ke_da_thu_chua_thu_q4,
  muc_hd_2026, dk_doanh_so_quy, n1, n2, n3_n4, 
  date(hieu_luc_hd) as hieu_luc_hd,
  date(hieu_luc_hd_ket_thuc) as hieu_luc_hd_ket_thuc, 
  hinh_thuc_tra, inserted_at,

  -- === QUY 1 ===
  ds_n1_q1, ds_n2_q1, ds_n3_n4_q1, tong_ds_q1, pct_th_q1 AS phan_tram_th_q1,
  lk_tong_q1 AS ds_luy_ke_q1, pct_lk_q1 AS phan_tram_luy_ke_q1,
  ck_n1_q1 AS tien_ck_n1_q1, ck_n2_q1 AS tien_ck_n2_q1, ck_n3_n4_q1 AS tien_ck_n3_n4_q1, 
  (ck_n1_q1 + ck_n2_q1 + ck_n3_n4_q1) AS tong_tien_ck_q1,
  bl_q1 AS doanh_so_bao_luu_q1, 
  thieu_q1 AS doanh_so_thieu_luy_ke_q1,
  CASE
  WHEN hinh_thuc_tra LIKE '%Hình thức 2%' 
  THEN FLOOR((ck_n1_q1 + ck_n2_q1 + ck_n3_n4_q1) / 10000)
  ELSE 0 
END AS diem_quy_doi_q1,

  -- === QUY 2 ===
  ds_n1_q2, ds_n2_q2, ds_n3_n4_q2,
  lk_n1_q2 AS ds_luy_ke_n1_q2, lk_n2_q2 AS ds_luy_ke_n2_q2, lk_n3_n4_q2 AS ds_luy_ke_n3_n4_q2,
  tong_ds_q2 AS tong_dsth_q2, pct_th_q2 AS phan_tram_th_q2,
  lk_tong_q2 AS ds_luy_ke_q2, pct_lk_q2 AS phan_tram_luy_ke_q2,
  ck_n1_q2 AS tien_ck_n1_q2, ck_n2_q2 AS tien_ck_n2_q2, ck_n3_n4_q2 AS tien_ck_n3_n4_q2, 
  (ck_n1_q2 + ck_n2_q2 + ck_n3_n4_q2) AS tong_tien_ck_q2,
  bl_q2 AS doanh_so_bao_luu_q2,
  thieu_q2 AS doanh_so_thieu_luy_ke_q2,
  CASE
  WHEN hinh_thuc_tra LIKE '%Hình thức 2%' 
  THEN FLOOR((ck_n1_q2 + ck_n2_q2 + ck_n3_n4_q2) / 10000)
  ELSE 0 
END AS diem_quy_doi_q2,
 

  -- === TỔNG HỢP KỲ 1 (RAW) ===
  doanh_so_tong_ky_1, pct_n1_ky1 AS phan_tram_km_n1_ky_1,
  ds_n1_ky1,ds_n2_ky1,ds_n3_n4_ky1,
  pct_n2_ky1 AS phan_tram_km_n2_ky_1, pct_n3_n4_ky1 AS phan_tram_km_n3_n4_ky_1, 
  (ds_n1_ky1 * pct_n1_ky1) AS thanh_tien_km_n1_ky_1, (ds_n2_ky1 * pct_n2_ky1) AS thanh_tien_km_n2_ky_1, (ds_n3_n4_ky1 * pct_n3_n4_ky1) AS thanh_tien_km_n3_n4_ky_1,
  ((ds_n1_ky1 * pct_n1_ky1) + (ds_n2_ky1 * pct_n2_ky1) + (ds_n3_n4_ky1 * pct_n3_n4_ky1)) AS tong_tien_km_ky_1,
  FLOOR(((ds_n1_ky1 * pct_n1_ky1) + (ds_n2_ky1 * pct_n2_ky1) + (ds_n3_n4_ky1 * pct_n3_n4_ky1))/10000) AS  diem_quy_doi_ky_1,

 

  -- === QUY 3 ===
  ds_n1_q3, ds_n2_q3, ds_n3_n4_q3,
  lk_n1_q3 AS ds_luy_ke_n1_q3, lk_n2_q3 AS ds_luy_ke_n2_q3, lk_n3_n4_q3 AS ds_luy_ke_n3_n4_q3,
  tong_ds_q3 AS tong_dsth_q3, pct_th_q3 AS phan_tram_th_q3,
  lk_tong_q3 AS ds_luy_ke_q3, pct_lk_q3 AS phan_tram_luy_ke_q3,
  ck_n1_q3 AS tien_ck_n1_q3, ck_n2_q3 AS tien_ck_n2_q3, ck_n3_n4_q3 AS tien_ck_n3_n4_q3, 
  (ck_n1_q3 + ck_n2_q3 + ck_n3_n4_q3) AS tong_tien_ck_q3,
  bl_q3 AS doanh_so_bao_luu_q3,
  thieu_q3 AS doanh_so_thieu_luy_ke_q3,

  -- === QUY 4 ===
  ds_n1_q4, ds_n2_q4, ds_n3_n4_q4,
  lk_n1_q4 AS ds_luy_ke_n1_q4, lk_n2_q4 AS ds_luy_ke_n2_q4, lk_n3_n4_q4 AS ds_luy_ke_n3_n4_q4,
  tong_ds_q4 AS tong_dsth_q4, pct_th_q4 AS phan_tram_th_q4,
  lk_tong_q4 AS ds_luy_ke_q4, pct_lk_q4 AS phan_tram_luy_ke_q4,
  ck_n1_q4 AS tien_ck_n1_q4, ck_n2_q4 AS tien_ck_n2_q4, ck_n3_n4_q4 AS tien_ck_n3_n4_q4, 
  (ck_n1_q4 + ck_n2_q4 + ck_n3_n4_q4) AS tong_tien_ck_q4,
  bl_q4 AS doanh_so_bao_luu_q4,
  thieu_q4 AS doanh_so_thieu_luy_ke_q4,

  -- === TỔNG HỢP KỲ 2 ===
  tong_ds_ky2 AS doanh_so_tong_ky_2,
  ds_n1_ky2, ds_n2_ky2, ds_n3_n4_ky2,
  pct_n1_ky2 AS phan_tram_km_n1_ky_2, 
  pct_n2_ky2 AS phan_tram_km_n2_ky_2, 
  pct_n3_n4_ky2 AS phan_tram_km_n3_n4_ky_2,
  (ds_n1_ky2 * pct_n1_ky2) AS thanh_tien_km_n1_ky_2, 
  (ds_n2_ky2 * pct_n2_ky2) AS thanh_tien_km_n2_ky_2, 
  (ds_n3_n4_ky2 * pct_n3_n4_ky2) AS thanh_tien_km_n3_n4_ky_2,

  -- LOGIC MỚI: TÍNH TỔNG TIỀN KM KỲ 2 CÓ BÙ TRỪ NĂM
  CASE 
    -- Nếu [KM Năm] > [KM Kỳ 1] + [KM Kỳ 2]
    WHEN ((ds_n1_nam * pct_n1_nam) + (ds_n2_nam * pct_n2_nam) + (ds_n3_n4_nam * pct_n3_n4_nam)) > 
         ( ((ds_n1_ky1 * pct_n1_ky1) + (ds_n2_ky1 * pct_n2_ky1) + (ds_n3_n4_ky1 * pct_n3_n4_ky1)) + 
           ((ds_n1_ky2 * pct_n1_ky2) + (ds_n2_ky2 * pct_n2_ky2) + (ds_n3_n4_ky2 * pct_n3_n4_ky2)) )
    -- Thì lấy [KM Năm] - [KM Kỳ 1]
    THEN ((ds_n1_nam * pct_n1_nam) + (ds_n2_nam * pct_n2_nam) + (ds_n3_n4_nam * pct_n3_n4_nam)) - 
         ((ds_n1_ky1 * pct_n1_ky1) + (ds_n2_ky1 * pct_n2_ky1) + (ds_n3_n4_ky1 * pct_n3_n4_ky1))
    -- Còn lại (<=) thì vẫn trả về [KM Kỳ 2] như bình thường
    ELSE ((ds_n1_ky2 * pct_n1_ky2) + (ds_n2_ky2 * pct_n2_ky2) + (ds_n3_n4_ky2 * pct_n3_n4_ky2))
  END AS tong_tien_km_ky_2,

  -- === TỔNG HỢP CẢ NĂM (RAW) ===
  doanh_so_tong_ca_nam, pct_n1_nam AS phan_tram_km_n1_nam, pct_n2_nam AS phan_tram_km_n2_nam, pct_n3_n4_nam AS phan_tram_km_n3_n4_nam,
  (ds_n1_nam * pct_n1_nam) AS thanh_tien_km_n1_nam, (ds_n2_nam * pct_n2_nam) AS thanh_tien_km_n2_nam, (ds_n3_n4_nam * pct_n3_n4_nam) AS thanh_tien_km_n3_n4_nam,
  0 as tong_thanh_tien_km_ca_nam,
  --((ds_n1_nam * pct_n1_nam) + (ds_n2_nam * pct_n2_nam) + (ds_n3_n4_nam * pct_n3_n4_nam)) AS tong_thanh_tien_km_ca_nam,
  gia_tri_qua_tet,
  gia_tri_qua_cam_xuc,

   -- === Chiết khấu đã trả === 
   IFNULL(f.da_tra_q1,0) as da_tra_q1,
   IFNULL(f.da_tra_q2,0) as da_tra_q2,
   IFNULL(f.da_tra_q3,0) as da_tra_q3,
   IFNULL(f.da_tra_q4,0) as da_tra_q4

FROM calc_q4 a
LEFT JOIN chiet_khau_da_thanh_toan f on f.custid = a.ma_kh
WHERE a.quy_tham_gia BETWEEN EXTRACT(QUARTER FROM a.hieu_luc_hd) AND EXTRACT(QUARTER FROM a.hieu_luc_hd_ket_thuc)


;