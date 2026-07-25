CREATE VIEW `spatial-vision-343005.warehouse.view_lhq_bui_huu_toan_dia_ban_cu`
AS WITH nv_old_list AS (
  -- 1. Lấy dữ liệu chi tiết của các NV cũ
  SELECT 
    thang,
    manv,
    tencvbh,
    'MR1681' as supid,
    'Bùi Hữu Toàn' as tenquanlytt,
    asm,
    tenquanlykhuvuc,
    chuc_vu,
    makenhkh,
    doanhsochuavat,
    kh_total,
    th_kpi,
    ds_ins,
    ds_pcl,
    ds_clc,
    lhq1,
    lhq2,
    lhq3,
    lhq4,
    tong_lhq
  FROM `spatial-vision-343005.warehouse.f_luonghieuqua_all_2024`
  WHERE thang >= '2026-04-01' 
    AND manv IN ('MR1365','MR4113','MR1640','MR1744','MR0952','MR2453','MR4056','MR1674','MR3069')
    AND dtype = 'nv'
),

gom_tong_nv AS (
  -- 2. Gom tổng Data của danh sách NV cũ để tính cho MR1681
  SELECT 
    thang,
    SUM(doanhsochuavat) AS doanhsochuavat,
    SUM(kh_total) AS kh_total,
    SUM(ds_ins) AS ds_ins,
    SUM(ds_pcl) AS ds_pcl,
    SUM(ds_clc) AS ds_clc
  FROM nv_old_list
  GROUP BY thang
),

tinh_toan_kpi AS (
  -- 3. Tính lại % KPI (A) cho CRM
  SELECT
    a.thang,
    'MR1681' AS manv,
    'Bùi Hữu Toàn' AS tencvbh,
    'CRM' AS chuc_vu,
    a.doanhsochuavat,
    a.kh_total,
    ROUND(SAFE_DIVIDE(a.doanhsochuavat, a.kh_total) * 100, 1) AS th_kpi,
    a.ds_ins,
    a.ds_pcl,
    a.ds_clc
  FROM gom_tong_nv a
  
),

tinh_toan_lhq AS (
  -- 4. Áp dụng công thức tính Lương hiệu quả cho HCP CRM
  SELECT 
    thang, a.manv, a.tencvbh, b.supid, b.tenquanlytt, b.asm, b.tenquanlykhuvuc, chuc_vu, doanhsochuavat, kh_total, th_kpi, ds_ins, ds_pcl, ds_clc,
    
    -- LHQ1: Lương hiệu quả 1 (Doanh số)
    CASE
      WHEN doanhsochuavat >= 4500000000 THEN doanhsochuavat * 0.4 / 100
      WHEN doanhsochuavat >= 4000000000 THEN 16000000
      WHEN doanhsochuavat >= 3500000000 THEN 14000000
      WHEN doanhsochuavat >= 3000000000 THEN 12000000
      WHEN doanhsochuavat >= 2500000000 THEN 10000000
      WHEN doanhsochuavat < 2500000000 THEN 
           (CASE WHEN thang >= '2026-01-01' THEN doanhsochuavat * 0.4 / 100 ELSE doanhsochuavat * 0.35 / 100 END)
      ELSE 0 
    END AS lhq1,
    
    -- LHQ2: Lương hiệu quả 2 (Đạt KPI)
    CASE
      WHEN th_kpi < 80 THEN th_kpi * 5000000 / 100
      WHEN th_kpi >= 80 AND th_kpi < 90 THEN th_kpi * 10000000 / 100
      WHEN th_kpi >= 90 AND th_kpi < 100 THEN th_kpi * 11000000 / 100
      WHEN th_kpi >= 100 AND th_kpi < 110 THEN th_kpi * 12000000 / 100
      WHEN th_kpi >= 110 AND th_kpi < 120 THEN th_kpi * 12500000 / 100
      WHEN th_kpi >= 120 THEN th_kpi * 13000000 / 100
      ELSE 0 
    END AS lhq2,
    
    -- LHQ3: Lương hiệu quả 3 (PC)
    ROUND((IFNULL(ds_ins, 0) * 4 + IFNULL(ds_pcl, 0) * 1.2 + IFNULL(ds_clc, 0) * 5) / 100, 1) AS lhq3,
    
    0 AS lhq4
  FROM tinh_toan_kpi a
  LEFT JOIN `staging.d_users` b ON a.manv = b.manv

),

crm_final AS (
  -- 5. Tính tổng LHQ cho MR1681
  SELECT 
    thang, manv, tencvbh, supid, tenquanlytt, asm, tenquanlykhuvuc, chuc_vu, 'HCP' as makenhkh, doanhsochuavat, kh_total, th_kpi, ds_ins, ds_pcl, ds_clc,
    lhq1, lhq2, lhq3, lhq4,
    (IFNULL(lhq1,0) + IFNULL(lhq2,0) + IFNULL(lhq3,0) + IFNULL(lhq4,0)) AS tong_lhq 
  FROM tinh_toan_lhq
)

-- 6. Gộp kết quả: Hiển thị NV cũ ở trên, MR1681 chốt lại ở dưới
SELECT * FROM nv_old_list
UNION ALL
SELECT * FROM crm_final
;