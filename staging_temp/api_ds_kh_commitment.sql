CREATE PROCEDURE `spatial-vision-343005`.staging_temp.api_ds_kh_commitment(DS_END_DATE STRING)
BEGIN
-- PARSE_DATE("%Y%m%d", @DS1_END_DATE)
WITH 
-- CTE 1: qua_tang
-- This CTE calculates various transaction amounts per customer (ma_kh) for product exchanges, returns, vouchers, and gifts.
qua_tang AS (
  SELECT 
    ma_kh,
    SUM(IFNULL(thanh_tien, 0)) AS thanh_tien_doi_sp_mr, 
    SUM(IFNULL(thanh_tien_ve, 0)) AS thanh_tien_ve,
    SUM(IFNULL(thanh_tien_suat, 0)) AS thanh_tien_suat,
    SUM(IFNULL(thanh_tien_qua, 0)) AS thanh_tien_qua,
    SUM(
      IFNULL(thanh_tien, 0) + IFNULL(thanh_tien_ve, 0) + IFNULL(thanh_tien_suat, 0) + IFNULL(thanh_tien_qua, 0)
    ) AS tong_gt_qt  -- Total transaction amount
  FROM `spatial-vision-343005.staging.d_manual_theo_doi_chon_qua_cmm_gd2_2024`
  GROUP BY 1
),

-- CTE 2: max_hcotypeid
-- This CTE retrieves the most recent hcotypeid per customer, truncated to the first day of the month.
max_hcotypeid AS (
  SELECT 
    custid, 
    hcotypeid, 
    DATE_TRUNC(crtd_datetime, MONTH) AS thang
  FROM `staging.sync_dms_pda_so` 
  WHERE hcotypeid IS NOT NULL 
  QUALIFY ROW_NUMBER() OVER (PARTITION BY custid ORDER BY crtd_datetime) = 1
),

-- CTE 3: sales
-- This CTE aggregates sales data based on the transaction date and customer ID.
sales AS (
  SELECT 
    masanpham,
    ngaychungtu,
    makhdms,
    IFNULL(b.hcotypeid, c.hcotypeid) AS hcotypeid,
    SUM(doanhsocovat) AS doanhsocovat 
  FROM `warehouse.f_sales_crs` a
  LEFT JOIN `staging.sync_dms_pda_so` b 
    ON a.sodondathang = b.ordernbr 
    AND a.macongtycn = b.branchid
  LEFT JOIN `staging.d_master_khachhang` c 
    ON a.makhdms = c.custid
  WHERE ngaychungtu >= '2023-10-01'
    AND DATE(ngaychungtu) <= PARSE_DATE("%Y-%m-%d", DS_END_DATE) -- MAKE CHANGES OF THIS FORMAT ON REPORT
    AND makenh_moi NOT IN ('NB', 'OTH_LAB') 
  GROUP BY 1, 2, 3, 4
  HAVING doanhsocovat <> 0
),

-- CTE 4: mapping_sales
-- This CTE joins various data sources to track the customer commitments, transaction points, and other customer-related data.
mapping_sales AS (
  SELECT
    a.ma_kh,
    a.ma_pl_hco AS hcotypeid,
    a.ten_kh,
    a.da_ky_bb_thoa_thuan,
    a.da_quan_tam_zalo_oa,
    a.hien_trang_doi_qua,
    CASE 
      WHEN CAST(a.ngay_sinh AS STRING) LIKE '%1970-01-01%' THEN NULL 
      ELSE CAST(a.ngay_sinh AS STRING)  
    END AS ngay_sinh,
    DATE(a.ngay_tham_gia) AS ngay_tham_gia,
    DATE(a.ngay_ket_thuc) AS ngay_ket_thuc,
    IFNULL(a.diem_tich_luy_quan_tam_oa_dang_ky, 0) AS diem_tich_luy_quan_tam_oa_dang_ky,
    IFNULL(a.diem_tich_luy_sinh_nhat, 0) AS diem_tich_luy_sinh_nhat,
    IFNULL(a.diem_tich_luy_sp_moitang_diem, 0) AS diem_tich_luy_sp_moitang_diem,
    IFNULL(a.diem_tl_da_sd, 0) AS diem_tl_da_sd,
    IFNULL(a.tien_quy_doi_da_sd, 0) AS tien_quy_doi_da_sd,
    IFNULL(a.diem_tl_da_sd_gd2, 0) AS diem_tl_da_sd_gd2,
    IFNULL(CAST(a.tien_quy_doi_da_sd_gd2 AS INT), 0) AS tien_quy_doi_da_sd_gd2,
    MIN(
      CASE 
        WHEN TRIM(c.commitment) IN ('Kháng sinh', 'Tiêu hóa', 'Còn lại') THEN ngaychungtu
        ELSE NULL
      END
    ) AS ngaychungtu,
    SUM(
      CASE
        WHEN DATE(ngaychungtu) >= DATE(a.ngay_tham_gia)
             AND DATE(ngaychungtu) <= DATE(a.ngay_ket_thuc)
             AND TRIM(c.commitment) IN ('Kháng sinh', 'Tiêu hóa') THEN doanhsocovat
        ELSE 0
      END
    ) AS doanhsocovat_ks,
    SUM(
      CASE
        WHEN DATE(ngaychungtu) >= DATE(a.ngay_tham_gia)
             AND DATE(ngaychungtu) <= DATE(a.ngay_ket_thuc)
             AND TRIM(c.commitment) IN ('Còn lại') THEN doanhsocovat
        ELSE 0
      END
    ) AS doanhsocovat_cl
  FROM `staging.d_manual_danhsach_commitment` a
  LEFT JOIN sales b 
    ON a.ma_kh = b.makhdms 
    AND a.ma_pl_hco = b.hcotypeid
  LEFT JOIN `staging.d_manual_danhsach_commitment` c 
    ON b.masanpham = c.ma_sp 
    AND c.ma_sp IS NOT NULL 
  WHERE a.ma_kh IS NOT NULL 
  GROUP BY all
),

-- CTE 5: quydoi_diem
-- This CTE calculates conversion points based on sales amounts and commitment details.
quydoi_diem AS (
  SELECT a.*,
    (doanhsocovat_ks + doanhsocovat_cl) AS doanhsocovat,
    CASE
      WHEN doanhsocovat_ks < 0 THEN 0
      ELSE DIV(CAST(doanhsocovat_ks AS INT), 
               (SELECT CAST(ds_quy_doi_kh_th AS INT) 
                FROM `staging.d_manual_danhsach_commitment` 
                WHERE ds_quy_doi_kh_th IS NOT NULL)) * 
               (SELECT CAST(diem_quy_doi_kh_th AS INT) 
                FROM `staging.d_manual_danhsach_commitment` 
                WHERE diem_quy_doi_kh_th IS NOT NULL)
    END AS diem_quy_doi_ks_th,
    CASE
      WHEN doanhsocovat_cl < 0 THEN 0
      ELSE DIV(CAST(doanhsocovat_cl AS INT),  
               (SELECT CAST(ds_quy_doi_cl AS INT) 
                FROM `staging.d_manual_danhsach_commitment` 
                WHERE ds_quy_doi_cl IS NOT NULL)) * 
               (SELECT CAST(diem_quy_doi_cl AS INT) 
                FROM `staging.d_manual_danhsach_commitment` 
                WHERE diem_quy_doi_cl IS NOT NULL)
    END AS diem_quy_doi_ks_cl
  FROM mapping_sales a
)

-- CTE 1: tong_diem_tl
-- This CTE calculates the total points (tongdiem_tl) by summing up various accumulated points from different categories.
, tong_diem_tl AS (
  SELECT 
    a.*,
    a.diem_tich_luy_quan_tam_oa_dang_ky 
    + a.diem_tich_luy_sinh_nhat 
    + a.diem_tich_luy_sp_moitang_diem  
    + a.diem_quy_doi_ks_cl 
    + a.diem_quy_doi_ks_th AS tongdiem_tl
  FROM quydoi_diem a
),

-- CTE 2: hang_kh_result
-- This CTE calculates various reward and remaining points based on the total points and the rewards logic.
hang_kh_result AS (
  SELECT
    a.* EXCEPT(tongdiem_tl),
    c1.hang_kh,
    c1.muc_diem_tu,
    c1.muc_diem_den,
    c1.thuong_thang_hang,
    CAST(c1.tien_quy_doi AS INT) AS tien_quy_doi,
    a.tongdiem_tl + IFNULL(c1.thuong_thang_hang, 0) AS tongdiem_tl,
    (a.tongdiem_tl + IFNULL(c1.thuong_thang_hang, 0)) * CAST(c1.tien_quy_doi AS INT) AS tien_quydoi,
    (a.tongdiem_tl + IFNULL(c1.thuong_thang_hang, 0)) - a.diem_tl_da_sd - a.diem_tl_da_sd_gd2 AS diem_tl_conlai,
    (a.tongdiem_tl + IFNULL(c1.thuong_thang_hang, 0) - a.diem_tl_da_sd) * CAST(c1.tien_quy_doi AS INT) - a.tien_quy_doi_da_sd_gd2 AS tien_quydoi_conlai,
    l.col.ma_nvbh AS slsperid,
    e.tencvbh,
    e.supid,
    e.tenquanlytt,
    e.asm,
    e.tenquanlykhuvuc,
    e.rsmid,
    e.tenquanlyvung,
    f.custname,
    f.channel,
    f.shoptype,
    f.hcoid,
    f.statedescr,
    f.shortterritorydescr,
    f.branchid,
    f.branchname,
    g.* EXCEPT(ma_kh)
  FROM tong_diem_tl a
  LEFT JOIN `spatial-vision-343005.staging.d_manual_danhsach_commitment` c1 
    ON a.tongdiem_tl >= c1.muc_diem_tu
    AND a.tongdiem_tl <= c1.muc_diem_den
    AND c1.hang_kh IS NOT NULL
  LEFT JOIN `warehouse.f_mapping_crs` l 
    ON l.custid = a.ma_kh
  LEFT JOIN `staging.d_users` e 
    ON e.manv = l.col.ma_nvbh
  LEFT JOIN `staging.d_master_khachhang` f 
    ON f.custid = a.ma_kh
  LEFT JOIN qua_tang g 
    ON a.ma_kh = g.ma_kh
)

-- Final SELECT: Selecting all columns from the hang_kh_result CTE.
SELECT 
  '202311-TL-QD60-PCL' AS ma_chuong_trinh,
  branchid AS ma_cn,
  slsperid AS ma_cvbh,
  tencvbh AS ten_cvbh,
  supid AS ma_ql_tt,
  tenquanlytt AS ten_ql_tt,
  ma_kh,
  custname AS ten_khach_hang,
  hcotypeid AS ma_pl_hco,
  ngay_sinh,
  ngay_tham_gia,
  ngay_ket_thuc,
  null as da_ky_bb_thoa_thuan,
  hang_kh,
  doanhsocovat AS doanh_so_co_vat,
  doanhsocovat_ks AS doanh_so_co_vat_ks_th,
  doanhsocovat_cl AS doanh_so_co_vat_cl,
  diem_quy_doi_ks_th,
  diem_quy_doi_ks_cl AS diem_quy_doi_cl,
  thuong_thang_hang AS diem_thuong_thang_hang,
  diem_tich_luy_quan_tam_oa_dang_ky,
  diem_tich_luy_sinh_nhat,
  diem_tich_luy_sp_moitang_diem AS diem_tich_luy_sp_moi_tang_diem,
  tongdiem_tl AS tong_diem_tl,
  diem_tl_da_sd,
  diem_tl_conlai AS diem_tl_con_lai,
  tien_quydoi AS tien_quy_doi,
  tien_quy_doi_da_sd,
  tien_quydoi_conlai AS tien_quy_doi_con_lai
FROM 
  hang_kh_result a
ORDER BY 
  doanh_so_co_vat DESC

;
END;