CREATE VIEW `spatial-vision-343005.warehouse.view_theo_doi_loyalty_pcl_2026`
AS WITH
-- =========================================================================
-- CTE 1: SALES_DATA (FILTERED - THEO HỢP ĐỒNG)
-- =========================================================================
RawData AS (
  SELECT 
    s.makhdms AS custid,
    s.taxregnbr,
    s.invoicecustid,
    s.custinvcname,
    f.quy_tham_gia,
    s.inserted_at,
    s.datatype,
    s.doanhsochuavat,
    EXTRACT(QUARTER FROM s.ngaychungtu) AS q,
    date(hieu_luc_hd_ket_thuc) as hieu_luc_hd_ket_thuc,
    -- Đặt cờ TRUE/FALSE. Lưu ý: Mệnh đề WHERE bên dưới KHÔNG lọc cứng ngày hiệu lực nữa
    DATE(s.ngaychungtu) >= DATE(f.hieu_luc_hd) AND DATE(s.ngaychungtu) <= DATE(f.hieu_luc_hd_ket_thuc) AS is_hieu_luc
  FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` s
  JOIN `spatial-vision-343005.staging.form_theo_doi_CSBH_loyalty_PCL_2026` f
    ON s.makhdms = f.ma_kh
  WHERE 
    s.makenhkh_cu = 'PCL'
    AND s.macongtycn != 'DL0001'
    AND s.ngaychungtu BETWEEN '2026-01-01' AND '2026-12-26'
)
, sales_ky_nam AS (
  SELECT 
    s.makhdms as custid,
    s.taxregnbr,
    SUM(IF(s.thang_number IN (1,2,3,4,5,6), s.doanhsochuavat, 0))  AS tong_ds_ky1,
    SUM(IF(s.thang_number IN (7,8,9,10,11,12), s.doanhsochuavat, 0))  AS tong_ds_ky2,
   SUM(s.doanhsochuavat) AS tong_ds_nam
 FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` s
  WHERE 
    s.makenhkh_cu = 'PCL'
    AND s.macongtycn != 'DL0001'
    AND s.ngaychungtu BETWEEN '2026-01-01' AND '2026-12-26'
  GROUP BY s.makhdms,s.taxregnbr
)
, sales_data AS (
  SELECT 
   r.custid,
   r.taxregnbr,
   quy_tham_gia,
   MAX(r.invoicecustid) AS custidinvoice,
   MAX(r.custinvcname) AS custnameinvoice,
   MAX(inserted_at) AS inserted_at,
  -- A. SỐ LIỆU QUÝ (CÓ LỌC NGÀY HIỆU LỰC - Dùng cờ is_hieu_luc)
  -- QUY 1
  SUM(IF(q = 1 AND datatype = 'N1' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n1_q1,
  SUM(IF(q = 1 AND datatype = 'N2' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n2_q1,
  SUM(IF(q = 1 AND datatype IN ('N3', 'N4') AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n3_n4_q1,
  SUM(IF(q = 1 AND is_hieu_luc, doanhsochuavat, 0)) AS tong_ds_q1,

  -- QUY 2
  SUM(IF(q = 2 AND datatype = 'N1' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n1_q2,
  SUM(IF(q = 2 AND datatype = 'N2' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n2_q2,
  SUM(IF(q = 2 AND datatype IN ('N3', 'N4') AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n3_n4_q2,
  SUM(IF(q = 2 AND is_hieu_luc, doanhsochuavat, 0)) AS tong_ds_q2,

  -- QUY 3
  SUM(IF(q = 3 AND datatype = 'N1' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n1_q3,
  SUM(IF(q = 3 AND datatype = 'N2' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n2_q3,
  SUM(IF(q = 3 AND datatype IN ('N3', 'N4') AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n3_n4_q3,
  SUM(IF(q = 3 AND is_hieu_luc, doanhsochuavat, 0)) AS tong_ds_q3,

  -- QUY 4
  SUM(IF(q = 4 AND datatype = 'N1' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n1_q4,
  SUM(IF(q = 4 AND datatype = 'N2' AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n2_q4,
  SUM(IF(q = 4 AND datatype IN ('N3', 'N4') AND is_hieu_luc, doanhsochuavat, 0)) AS ds_n3_n4_q4,
  SUM(IF(q = 4 AND is_hieu_luc, doanhsochuavat, 0)) AS tong_ds_q4,
  -- KỲ, NĂM
  MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-06-01' THEN n.tong_ds_ky1 ELSE 0 END) AS tong_ds_ky1,
  MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-12-26' THEN n.tong_ds_ky2 ELSE 0 END) AS tong_ds_ky2,
  MAX(CASE WHEN DATE(r.hieu_luc_hd_ket_thuc) >= '2026-12-26' THEN n.tong_ds_nam ELSE 0 END) AS tong_ds_nam

  FROM RawData r
  LEFT JOIN sales_ky_nam n ON r.custid = n.custid AND IFNULL(r.taxregnbr, 'none') = IFNULL(n.taxregnbr, 'none')
  GROUP BY r.custid,quy_tham_gia,r.taxregnbr
),
-- =========================================================================
-- CTE 3: SALES_REWARDS (TÍNH % THƯỞNG TRÊN TỔNG DOANH SỐ)
-- =========================================================================
sales_rewards AS (
  SELECT 
    t.custid,
    t.taxregnbr,
    t.tong_ds_ky1,
    t.tong_ds_ky2,
    t.tong_ds_nam,
    t.quy_tham_gia,

    CASE 
         WHEN t.tong_ds_ky1 >= 120000000 THEN 0.08 
         WHEN t.tong_ds_ky1 >= 90000000  THEN 0.07 
         WHEN t.tong_ds_ky1 >= 60000000  THEN 0.06 
         WHEN t.tong_ds_ky1 >= 30000000  THEN 0.05 
         WHEN t.tong_ds_ky1 >= 18000000  THEN 0.04 
         ELSE 0 
    END AS pct_thuong_ky1,

    CASE 
        WHEN t.tong_ds_ky2 >= 120000000 THEN 0.08 
        WHEN t.tong_ds_ky2 >= 90000000  THEN 0.07 
        WHEN t.tong_ds_ky2 >= 60000000  THEN 0.06 
        WHEN t.tong_ds_ky2 >= 30000000  THEN 0.05 
        WHEN t.tong_ds_ky2 >= 18000000  THEN 0.04 
        ELSE 0 
    END AS pct_thuong_ky2,

    CASE 
         WHEN t.tong_ds_nam >= 240000000 THEN 0.08 
         WHEN t.tong_ds_nam >= 180000000 THEN 0.07 
         WHEN t.tong_ds_nam >= 120000000 THEN 0.06 
         WHEN t.tong_ds_nam >= 60000000  THEN 0.05 
         WHEN t.tong_ds_nam >= 36000000  THEN 0.04 
         ELSE 0 
    END AS pct_thuong_nam, -- Dùng để so sánh tính cho kỳ 2

    CASE 
         WHEN t.tong_ds_nam >= 600000000 THEN 0.02 
         WHEN t.tong_ds_nam >= 480000000 THEN 0.015 
         WHEN t.tong_ds_nam >= 360000000 THEN 0.01 

         ELSE 0 
    END AS pct_thuong_tl_nam

  FROM sales_data t
)

, thong_tin_ky_hop_dong as (
SELECT
distinct ma_khach_hang,
trang_thai_ky,
internal_promo_code
FROm `spatial-vision-343005.warehouse.view_data_contract_sign_by_users`
where
internal_promo_code ='202601-TL-QD786-PKN-PKQ'
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

-- =========================================================================
-- CTE 4: BASE_METRICS (TÍNH SẴN CÁC TỶ LỆ VÀ TIỀN THƯỞNG THÔ ĐỂ DÙNG CHUNG)
-- =========================================================================
, base_metrics AS (
  SELECT
    a.asm, a.tenquanlykhuvuc, a.supid AS ma_crm, a.tenquanlytt AS crm, a.col.ma_nvbh AS ma_crs, a.tencvbh AS crs,
    b.ma_kh, b.ten_kh, d.custidinvoice, d.custnameinvoice, d.taxregnbr, c.citizenid,
    c.statedescr AS tinh, c.hcoid AS ma_hco, b.pl_hco AS ma_loai_hco, c.stocksales AS tinh_trang_mst,
    b.quy_tham_gia, b.phan_tram_tham_gia, b.kenh, c.shoptype AS kenh_phu, branchid, b.muc_hd_2026, b.dk_doanh_so_quy, b.hieu_luc_hd,hieu_luc_hd_ket_thuc, b.hinh_thuc_tra, d.inserted_at,
    CASE WHEN DATE(c.legaldate) >= DATE_ADD(CURRENT_DATE(), INTERVAL 7 DAY) THEN 'Còn hiệu lực' ELSE 'Hết hiệu lực' END AS hieu_luc_gpp_gdp,
    sc.tong_ds_ky1, sc.pct_thuong_ky1,
    sc.tong_ds_ky2, 
    sc.pct_thuong_ky2, 
    sc.pct_thuong_nam,
    sc.tong_ds_nam, sc.pct_thuong_tl_nam,

    -- Gom chi tiết doanh số từng loại (để in ra cuối cùng)
    COALESCE(d.ds_n1_q1, 0) AS ds_n1_q1, COALESCE(d.ds_n2_q1, 0) AS ds_n2_q1, COALESCE(d.ds_n3_n4_q1, 0) AS ds_n3_n4_q1,
    COALESCE(d.ds_n1_q2, 0) AS ds_n1_q2, COALESCE(d.ds_n2_q2, 0) AS ds_n2_q2, COALESCE(d.ds_n3_n4_q2, 0) AS ds_n3_n4_q2,
    COALESCE(d.ds_n1_q3, 0) AS ds_n1_q3, COALESCE(d.ds_n2_q3, 0) AS ds_n2_q3, COALESCE(d.ds_n3_n4_q3, 0) AS ds_n3_n4_q3,
    COALESCE(d.ds_n1_q4, 0) AS ds_n1_q4, COALESCE(d.ds_n2_q4, 0) AS ds_n2_q4, COALESCE(d.ds_n3_n4_q4, 0) AS ds_n3_n4_q4,
    
    -- Tình trạng hợp đồng / bảng kê
    CASE WHEN t.ngay_thu_hoi IS NOT NULL THEN 'Đã thu'
      WHEN e.ma_khach_hang IS NOT NULL THEN 'Đã thu' 
      ELSE 'Chưa thu' END AS hop_dong,
    CASE WHEN t.ngay_thu_hoi IS NOT NULL THEN 'Ký tay'
      WHEN e.ma_khach_hang IS NOT NULL THEN 'Ký số' 
      ELSE null END as ky_tay_ky_so_hd,
    CASE WHEN f.ngay_thu_hoi_hop_dong_ky_tay IS NOT NULL THEN 'Đã thu' 
        WHEN g.ma_khach_hang IS NOT NULL THEN 'Đã thu'
        ELSE 'Chưa thu' END AS bang_ke_da_thu_chua_thu_q1,

    -- 1. Doanh số quý
    COALESCE(d.tong_ds_q1, 0) AS ds_q1, COALESCE(d.tong_ds_q2, 0) AS ds_q2, COALESCE(d.tong_ds_q3, 0) AS ds_q3, COALESCE(d.tong_ds_q4, 0) AS ds_q4,

    -- 2. Tỷ lệ đạt quý
    SAFE_DIVIDE(COALESCE(d.tong_ds_q1, 0), b.dk_doanh_so_quy) AS pct_th_q1,
    SAFE_DIVIDE(COALESCE(d.tong_ds_q2, 0), b.dk_doanh_so_quy) AS pct_th_q2,
    SAFE_DIVIDE(COALESCE(d.tong_ds_q3, 0), b.dk_doanh_so_quy) AS pct_th_q3,
    SAFE_DIVIDE(COALESCE(d.tong_ds_q4, 0), b.dk_doanh_so_quy) AS pct_th_q4,

    -- 3. Doanh số Lũy kế
    COALESCE(d.tong_ds_q1, 0) AS lk_q1,
    (COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0)) AS lk_q2,
    (COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0) + COALESCE(d.tong_ds_q3, 0)) AS lk_q3,
    (COALESCE(d.tong_ds_q1, 0) + COALESCE(d.tong_ds_q2, 0) + COALESCE(d.tong_ds_q3, 0) + COALESCE(d.tong_ds_q4, 0)) AS lk_q4,

    -- 4. Tỷ lệ Lũy kế theo quý
    SAFE_DIVIDE(COALESCE(d.tong_ds_q1, 0), b.dk_doanh_so_quy) AS pct_lk_q1,

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

    -- 5. Tiền thưởng THÔ (Base CK - Tính theo tỷ lệ % từng khung, chưa xét đk đạt hay rớt)
    ((COALESCE(d.ds_n1_q1, 0) * COALESCE(b.n1, 0)) + (COALESCE(d.ds_n2_q1, 0) * COALESCE(b.n2, 0)) + (COALESCE(d.ds_n3_n4_q1, 0) * COALESCE(b.n3_n4, 0))) AS base_ck_q1,
    ((COALESCE(d.ds_n1_q2, 0) * COALESCE(b.n1, 0)) + (COALESCE(d.ds_n2_q2, 0) * COALESCE(b.n2, 0)) + (COALESCE(d.ds_n3_n4_q2, 0) * COALESCE(b.n3_n4, 0))) AS base_ck_q2,
    ((COALESCE(d.ds_n1_q3, 0) * COALESCE(b.n1, 0)) + (COALESCE(d.ds_n2_q3, 0) * COALESCE(b.n2, 0)) + (COALESCE(d.ds_n3_n4_q3, 0) * COALESCE(b.n3_n4, 0))) AS base_ck_q3,
    ((COALESCE(d.ds_n1_q4, 0) * COALESCE(b.n1, 0)) + (COALESCE(d.ds_n2_q4, 0) * COALESCE(b.n2, 0)) + (COALESCE(d.ds_n3_n4_q4, 0) * COALESCE(b.n3_n4, 0))) AS base_ck_q4

  FROM `spatial-vision-343005.staging.form_theo_doi_CSBH_loyalty_PCL_2026` AS b
  LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` AS a ON a.custid = b.ma_kh
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` AS c ON c.custid = b.ma_kh
  LEFT JOIN sales_data AS d ON d.custid = b.ma_kh AND d.quy_tham_gia = b.quy_tham_gia
  LEFT JOIN sales_rewards AS sc ON sc.custid = b.ma_kh AND sc.quy_tham_gia = b.quy_tham_gia AND IFNULL(sc.taxregnbr, 'none') = IFNULL(d.taxregnbr, 'none')
  LEFT JOIN `spatial-vision-343005.staging.theo_doi_thu_hoi_chung_tu_ky_ben_ngoai_loyaty_pcl_2026` AS t ON t.ma_kh = b.ma_kh
  LEFT JOIN `thong_tin_ky_hop_dong` e ON e.ma_khach_hang = b.ma_kh
  LEFT JOIN `spatial-vision-343005.staging.theo_doi_thu_hoi_chung_tu_ky_ben_ngoai_bang_ke_loyaty_tp_pcl_q12026` AS f ON f.ma_kh = b.ma_kh
  LEFT JOIN `thong_tin_ky_bang_ke` g ON g.ma_khach_hang = b.ma_kh
)

-- =========================================================================
-- CTE 5 -> 8: TÍNH THƯỞNG CUỐN CHIẾU (TRÁNH LẶP CODE)
-- =========================================================================

, calc_q1 AS (
  SELECT *,
    CASE WHEN pct_th_q1 >= 1 THEN base_ck_q1 ELSE 0 END AS ck_q1
  FROM base_metrics
)

, calc_q2 AS (
  SELECT *,
    CASE 
      WHEN pct_lk_q2 >= 1 THEN (base_ck_q1 + base_ck_q2) - ck_q1
      WHEN pct_th_q2 >= 1 THEN base_ck_q2 ELSE 0 
    END AS ck_q2
  FROM calc_q1
)

, calc_q3 AS (
  SELECT *,
    CASE 
      WHEN pct_lk_q3 >= 1 THEN (base_ck_q1 + base_ck_q2 + base_ck_q3) - (ck_q1 + ck_q2)
      WHEN pct_th_q3 >= 1 THEN base_ck_q3 ELSE 0 
    END AS ck_q3
  FROM calc_q2
)

, calc_q4 AS (
  SELECT *,
    CASE 
      WHEN pct_lk_q4 >= 1.0 THEN (base_ck_q1 + base_ck_q2 + base_ck_q3 + base_ck_q4) - (ck_q1 + ck_q2 + ck_q3)
      WHEN pct_th_q4 >= 1 THEN base_ck_q4 ELSE 0 
    END AS ck_q4
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
  accumulateid = '202601-TL-QD786-PKN-PKQ'
GROUP BY ALL
)

SELECT
  -- 1. THÔNG TIN CHUNG
  asm, tenquanlykhuvuc, ma_crm, crm, 
  IFNULL(ma_crs,'None') as ma_crs, crs,
  ma_kh, ten_kh, custidinvoice, custnameinvoice, taxregnbr,citizenid,
  tinh, ma_hco, ma_loai_hco, tinh_trang_mst,
  quy_tham_gia, phan_tram_tham_gia, kenh, kenh_phu, branchid, hieu_luc_gpp_gdp,
  muc_hd_2026, dk_doanh_so_quy, hieu_luc_hd,hieu_luc_hd_ket_thuc, hinh_thuc_tra, inserted_at,

  -- QUÝ 1
  ds_q1 AS tong_dsth_q1, pct_th_q1 AS phan_tram_th_q1, lk_q1 AS ds_luy_ke_q1, pct_lk_q1 AS phan_tram_luy_ke_q1,
  ck_q1 AS tong_tien_ck_q1,
  CASE WHEN pct_th_q1 < 1 AND pct_lk_q1 < 1 THEN ds_q1 ELSE 0 END AS doanh_so_bao_luu_q1,
  CASE WHEN pct_th_q1 < 1 AND pct_lk_q1 < 1 THEN 
      CASE WHEN DATE(hieu_luc_hd) = '2026-01-01' THEN dk_doanh_so_quy - lk_q1 ELSE 0 END 
  ELSE 0 END AS doanh_so_thieu_luy_ke_q1,
  (base_ck_q1 * (1.0/12) * 0.8 * LEAST(EXTRACT(MONTH FROM CURRENT_DATE()), 3)) AS trich_lap_q1,

  -- QUÝ 2
  ds_q2 AS tong_dsth_q2, pct_th_q2 AS phan_tram_th_q2, lk_q2 AS ds_luy_ke_q2, pct_lk_q2 AS phan_tram_luy_ke_q2,
  ck_q2 AS tong_tien_ck_q2,

  ( CASE WHEN pct_th_q2 < 1 AND pct_lk_q2 < 1 THEN ds_q2 ELSE 0 END 
      + CASE WHEN pct_th_q1 < 1 AND pct_lk_q2 < 1 THEN ds_q1 ELSE 0 END) AS doanh_so_bao_luu_q2,

  CASE WHEN pct_th_q2 < 1 AND pct_lk_q2 < 1 THEN 
      CASE 
          WHEN DATE(hieu_luc_hd) = '2026-01-01' THEN (dk_doanh_so_quy * 2) - lk_q2
          WHEN DATE(hieu_luc_hd) = '2026-04-01' THEN dk_doanh_so_quy - lk_q2
          ELSE 0
      END 
  ELSE 0 END AS doanh_so_thieu_luy_ke_q2,

  (base_ck_q2 * (1.0/12) * 0.8 * GREATEST(LEAST(EXTRACT(MONTH FROM CURRENT_DATE()) - 3, 3), 0)) AS trich_lap_q2,

  -- KỲ 1 (6 THÁNG)
  COALESCE(tong_ds_ky1, 0) AS doanh_so_tong_ky_1, pct_thuong_ky1 AS phan_tram_km_ky_1,
  (COALESCE(tong_ds_ky1, 0) * pct_thuong_ky1) AS thanh_tien_km_ky_1,
  FLOOR(SAFE_DIVIDE(COALESCE(tong_ds_ky1, 0) * pct_thuong_ky1, 10000)) AS diem_quy_doi_ky_1,
  ((COALESCE(tong_ds_ky1, 0) * pct_thuong_ky1) * (1.0/12) * 0.8 * LEAST(EXTRACT(MONTH FROM CURRENT_DATE()), 6)) AS trich_lap_ky_1,

  -- QUÝ 3
  ds_q3 AS tong_dsth_q3, pct_th_q3 AS phan_tram_th_q3, lk_q3 AS ds_luy_ke_q3, pct_lk_q3 AS phan_tram_luy_ke_q3,
  ck_q3 AS tong_tien_ck_q3,

  (CASE WHEN pct_th_q3 < 1 AND pct_lk_q3 < 1 THEN ds_q3 ELSE 0 END 
      + CASE WHEN pct_th_q2 < 1 AND pct_lk_q3 < 1 THEN ds_q2 ELSE 0 END 
      + CASE WHEN pct_th_q1 < 1 AND pct_lk_q3 < 1 THEN ds_q1 ELSE 0 END) AS doanh_so_bao_luu_q3,

  CASE WHEN pct_th_q3 < 1 AND pct_lk_q3 < 1 THEN 
      CASE 
          WHEN DATE(hieu_luc_hd) = '2026-01-01' THEN (dk_doanh_so_quy * 3) - lk_q3
          WHEN DATE(hieu_luc_hd) = '2026-04-01' THEN (dk_doanh_so_quy * 2) - lk_q3
          WHEN DATE(hieu_luc_hd) = '2026-07-01' THEN dk_doanh_so_quy - lk_q3
          ELSE 0 
        END 
  ELSE 0 END AS doanh_so_thieu_luy_ke_q3,

  (base_ck_q3 * (1.0/12) * 0.8 * GREATEST(LEAST(EXTRACT(MONTH FROM CURRENT_DATE()) - 6, 3), 0)) AS trich_lap_q3,

  -- QUÝ 4
  ds_q4 AS tong_dsth_q4, pct_th_q4 AS phan_tram_th_q4, lk_q4 AS ds_luy_ke_q4, pct_lk_q4 AS phan_tram_luy_ke_q4,
  ck_q4 AS tong_tien_ck_q4,

  (CASE WHEN pct_th_q4 < 1 AND pct_lk_q4 < 1.00 THEN ds_q4 ELSE 0 END 
      + CASE WHEN pct_th_q3 < 1 AND pct_lk_q4 < 1.00 THEN ds_q3 ELSE 0 END 
      + CASE WHEN pct_th_q2 < 1 AND pct_lk_q4 < 1.00 THEN ds_q2 ELSE 0 END 
      + CASE WHEN pct_th_q1 < 1 AND pct_lk_q4 < 1.00 THEN ds_q1 ELSE 0 END) AS doanh_so_bao_luu_q4,

  CASE WHEN pct_th_q4 < 1 AND pct_lk_q4 < 1.00 THEN 
     CASE 
        WHEN DATE(hieu_luc_hd) = '2026-01-01' THEN (dk_doanh_so_quy * 4) - lk_q4
        WHEN DATE(hieu_luc_hd) = '2026-04-01' THEN (dk_doanh_so_quy * 3) - lk_q4
        WHEN DATE(hieu_luc_hd) = '2026-07-01' THEN (dk_doanh_so_quy * 2) - lk_q4
        WHEN DATE(hieu_luc_hd) = '2026-10-01' THEN dk_doanh_so_quy - lk_q4
        ELSE 0 
      END 
  ELSE 0 END AS doanh_so_thieu_luy_ke_q4,

  (base_ck_q4 * (1.0/12) * 0.8 * GREATEST(LEAST(EXTRACT(MONTH FROM CURRENT_DATE()) - 9, 3), 0)) AS trich_lap_q4,

  -- KỲ 2
  COALESCE(tong_ds_ky2, 0) AS doanh_so_ky_2, 
  pct_thuong_ky2 AS phan_tram_km_ky_2,

  CASE 
    WHEN (COALESCE(tong_ds_nam, 0) * pct_thuong_nam) > ( (COALESCE(tong_ds_ky1, 0) * pct_thuong_ky1) + (COALESCE(tong_ds_ky2, 0) * pct_thuong_ky2) )
    THEN (COALESCE(tong_ds_nam, 0) * pct_thuong_nam) - ( (COALESCE(tong_ds_ky1, 0) * pct_thuong_ky1))
    ELSE (COALESCE(tong_ds_ky2, 0) * pct_thuong_ky2) 
  END AS thanh_tien_km_ky_2,

  FLOOR(SAFE_DIVIDE(
    CASE 
      WHEN (COALESCE(tong_ds_nam, 0) * pct_thuong_nam) > ( (COALESCE(tong_ds_ky1, 0) * pct_thuong_ky1) + (COALESCE(tong_ds_ky2, 0) * pct_thuong_ky2) )
      THEN (COALESCE(tong_ds_nam, 0) * pct_thuong_nam) - ( (COALESCE(tong_ds_ky1, 0) * pct_thuong_ky1) + (COALESCE(tong_ds_ky2, 0) * pct_thuong_ky2) )
      ELSE (COALESCE(tong_ds_ky2, 0) * pct_thuong_ky2) 
    END, 10000)) AS diem_quy_doi_ky_2,
  
    --((COALESCE(tong_ds_ky2, 0) * pct_thuong_ky2) * (1.0/12) * 0.8 * GREATEST(LEAST(EXTRACT(MONTH FROM CURRENT_DATE()) - 6, 6), 0)) AS trich_lap_ky_2,

  -- NĂM
  COALESCE(tong_ds_nam, 0) AS doanh_so_nam, 
  Case when muc_hd_2026 >= 360000000 then  pct_thuong_tl_nam else 0 end AS phan_tram_km_nam,
  (Case when muc_hd_2026 >= 360000000 then COALESCE(tong_ds_nam, 0) * pct_thuong_tl_nam else 0 end) AS thanh_tien_km_nam,
  Case when muc_hd_2026 >= 360000000 then FLOOR(SAFE_DIVIDE(COALESCE(tong_ds_nam, 0) * pct_thuong_tl_nam, 10000)) 
    else 0 end AS diem_quy_doi_ca_nam,

  (Case when muc_hd_2026 >= 360000000 
   then (COALESCE(tong_ds_nam, 0) * pct_thuong_tl_nam) * (1.0/12) * 0.8 * LEAST(EXTRACT(MONTH FROM CURRENT_DATE()), 12) 
   else 0 end) AS trich_lap_nam,

  -- CHI TIẾT DOANH SỐ NHÓM SẢN PHẨM (N1, N2, N3_N4)
  ds_n1_q1, ds_n2_q1, ds_n3_n4_q1,
  ds_n1_q2, ds_n2_q2, ds_n3_n4_q2,
  ds_n1_q3, ds_n2_q3, ds_n3_n4_q3,
  ds_n1_q4, ds_n2_q4, ds_n3_n4_q4,

  -- TRẠNG THÁI HỢP ĐỒNG
  hop_dong,
  ky_tay_ky_so_hd,
  NULL AS phu_luc,
  bang_ke_da_thu_chua_thu_q1,
  NULl as bang_ke_da_thu_chua_thu_q2,
  NULL as bang_ke_da_thu_chua_thu_q3,
  NULL as bang_ke_da_thu_chua_thu_q4,


  -- Chiết khấu đã trả
   IFNULL(f.da_tra_q1,0) as da_tra_q1,
   IFNULL(f.da_tra_q2,0) as da_tra_q2,
   IFNULL(f.da_tra_q3,0) as da_tra_q3,
   IFNULL(f.da_tra_q4,0) as da_tra_q4

FROM calc_q4 a
LEFT JOIN chiet_khau_da_thanh_toan f on f.custid = a.ma_kh
WHERE a.quy_tham_gia BETWEEN EXTRACT(QUARTER FROM a.hieu_luc_hd) AND EXTRACT(QUARTER FROM a.hieu_luc_hd_ket_thuc)



;