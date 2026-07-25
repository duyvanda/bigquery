CREATE VIEW `spatial-vision-343005.warehouse.view_ct_thuong_commitment_hcp_2025`
AS WITH th_doanh_so as (
  SELECT 
  a.manv,
  a.tencvbh,
  a.crm,
  a.tenquanlytt,
  date(a.thang) as thang,
  a.makenhkh,
  SUM(a.doanhsochuavat) as th_kh_total,
  SUM(  
  CASE
    WHEN a.makenhkh = 'CLC' THEN a.doanhsochuavat
    ELSE 0 END) AS th_kh_ds_clc,

  FROM `spatial-vision-343005.staging_temp.f_sales_crs_lhq_bytime` a
  WHERE
  a.makenhkh in ('PCL','CLC','INS')
  AND date(a.thang) >='2025-07-01'
  AND date(a.ngaychungtu) <='2025-12-31'
  GROUP BY ALL
)

,th_kh_doanh_so as (
    SELECT
    a.manv,
    a.tencvbh,
    a.crm,
    a.tenquanlytt,
    SUM(d.kh_total) as kh_total,
    SUM(th_kh_total) as th_kh_total,
    SUM(
      CASE
      WHEN d.makenhkh = 'CLC' THEN d.kh_total
      ELSE 0 END) AS kh_ds_clc,
   SUM(th_kh_ds_clc) as th_kh_ds_clc,
    FROM th_doanh_so a
    LEFT JOIN `spatial-vision-343005.staging.d_calendar` d ON a.manv = d.manv AND date(a.thang) = date(d.thang) and d.makenhkh = a.makenhkh
    GROUP BY ALL
)

,do_phu_sunohada as (
  SELECT
  a.manv,
  CASE
    WHEN SUM(soluong) OVER (PARTITION BY sodondathang) >= 4 THEN makhdms
    ELSE NULL END AS ma_kh_tinh_diem_phu,
  FROM `spatial-vision-343005.staging_temp.f_sales_crs_lhq_bytime` a
  WHERE
  a.makenhkh in ('PCL','CLC')
  AND masanpham in ('T4040101001','T4040101002')
  AND date(a.ngaychungtu) >='2025-07-01'
  AND date(a.ngaychungtu) <='2025-12-31'
)

,diem_tieu_chi_nv as (
  SELECT
  a.*,
  SAFE_DIVIDE(th_kh_total,kh_total)*100 as ty_le_th_kh_total,
  SAFE_DIVIDE(th_kh_ds_clc,kh_ds_clc)*100 as ty_le_th_kh_ds_clc,
  COUNT(DISTINCT ma_kh_tinh_diem_phu) as sl_kh_tinh_diem_phu,
  CASE
    WHEN SAFE_DIVIDE(th_kh_total,kh_total)*100 >= 120 THEN 5
    WHEN SAFE_DIVIDE(th_kh_total,kh_total)*100 >= 110 THEN 4
    WHEN SAFE_DIVIDE(th_kh_total,kh_total)*100 >= 100 THEN 3
    ELSE 0
    END AS a_tieuchi,
  CASE
    WHEN SAFE_DIVIDE(th_kh_ds_clc,kh_ds_clc)*100 >= 120 THEN 5
    WHEN SAFE_DIVIDE(th_kh_ds_clc,kh_ds_clc)*100 >= 110 THEN 4
    WHEN SAFE_DIVIDE(th_kh_ds_clc,kh_ds_clc)*100 >= 90 THEN 3
    ELSE 0
    END AS c_tieuchi,
  CASE
    WHEN COUNT(DISTINCT ma_kh_tinh_diem_phu) >= 7 then 5
    WHEN COUNT(DISTINCT ma_kh_tinh_diem_phu) >= 5 then 4
    WHEN COUNT(DISTINCT ma_kh_tinh_diem_phu) >= 3 then 3 ELSE 0
    END AS sh_tieuchi
  FROM th_kh_doanh_so a
  LEFT JOIN do_phu_sunohada b ON a.manv = b.manv
  GROUP BY ALL
)

,th_kh_ql as (
  With union_all as (
      SELECT 'Hoàng Trung Thành' AS tenquanlytt, 12080630000 AS target_crm UNION ALL
      SELECT 'Lâm Văn Cảnh', 13155000000 UNION ALL
      SELECT 'Lê Văn Tùng', 11163581000 UNION ALL
      SELECT 'Mai Thị Thanh Phúc', 7850000000 UNION ALL
      SELECT 'Ngô Tiến Vũ', 13723200000 UNION ALL
      SELECT 'Nguyễn Hồng Hà', 11540000000 UNION ALL
      SELECT 'Nguyễn Ngọc Thiên Trang', 14488110000 UNION ALL
      SELECT 'Nguyễn Thị Dung', 8952200000 UNION ALL
      SELECT 'Nguyễn Toàn', 9117000000 UNION ALL
      SELECT 'Nguyễn Văn Đôn', 11301000000 UNION ALL
      SELECT 'Phan Thị Bình Khê', 9738100000 UNION ALL
      SELECT 'Vũ Mừng', 11265375000
        )
    SELECT 
    a.*,
    d.msnvcsmmoi as manv,
    SUM(b.doanhsochuavat) as th_kh_ds,
    SAFE_DIVIDE(SUM(b.doanhsochuavat),target_crm)*100 as ty_le_th_ds_crm
    FROM union_all a
    LEFT JOIN `spatial-vision-343005.staging.d_hr_dsns` d ON d.hovatenfullname = a.tenquanlytt
    LEFT JOIN `spatial-vision-343005.staging_temp.f_sales_crs_lhq_bytime` b ON b.crm = d.msnvcsmmoi
    WHERE 
    b.makenhkh in ('PCL','CLC','INS')
    AND date(b.ngaychungtu) >='2025-10-01'
    AND date(b.ngaychungtu) <='2025-12-31'
    GROUP BY ALL
)

,th_kh_tong_phong_hcp as (
  SELECT
  SUM(th_kh_ds) as th_kh_ds_phong_hcp,
  134347000000 as kh_ds_phong_hcp,
  SAFE_DIVIDE(SUM(th_kh_ds),SUM(target_crm)) *100 as ty_le_th_ds_phong_hcp
  FROM th_kh_ql
)

SELECT 
a.*,
0.7*IFNULL(a_tieuchi,0) + 0.15*IFNULL(c_tieuchi,0) + 0.15*IFNULL(sh_tieuchi,0) as tong_diem,
0 as kh_ds_phong_hcp,
0 as th_kh_ds_phong_hcp,
0 as ty_le_th_ds_phong_hcp,
'CRS' as chuc_vu
FROM diem_tieu_chi_nv a
WHERE manv != crm

UNION ALL
SELECT
a.manv,
a.tenquanlytt as tencvbh,
a.manv as crm,
a.tenquanlytt as tenquanlytt,
SUM(a.target_crm) as kh_total,
SUM(a.th_kh_ds) as th_kh_total,
0 AS kh_ds_clc,
0 AS th_kh_ds_clc,
a.ty_le_th_ds_crm  AS ty_le_th_kh_total,
0 as ty_le_th_kh_ds_clc,
0 as sl_kh_tinh_diem_phu,
0 as a_tieuchi,
0 as c_tieuchi,
0 as sh_tieuchi,
0 as tong_diem,
b.kh_ds_phong_hcp,
b.th_kh_ds_phong_hcp,
b.ty_le_th_ds_phong_hcp,
'CRM' as chuc_vu

FROM th_kh_ql a
LEFT JOIN th_kh_tong_phong_hcp b ON 1=1
GROUP BY ALL











;