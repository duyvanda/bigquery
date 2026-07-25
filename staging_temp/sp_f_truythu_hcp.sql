CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_truythu_hcp()
BEGIN

CREATE OR REPLACE TABLE `spatial-vision-343005.warehouse.f_truythu_hcp` AS
WITH data_duyetdon as (
   select 
   --date_trunc(date(dd.ngayduyetdon),month) as thang,
   CAST(EXTRACT(QUARTER FROM dd.ngayduyetdon) AS STRING) || 
   CAST(EXTRACT(YEAR FROM dd.ngayduyetdon) AS STRING) AS quy,
   CASE 
     WHEN LOWER(dd.tenkhachhang) LIKE '%gonsa%' THEN 'MR1137'
     ELSE IFNULL(hr_crm.msnvcsmmoi, c.supid) 
   END as macrm,

   CASE 
     WHEN LOWER(dd.tenkhachhang) LIKE '%gonsa%' THEN 'Vũ Mừng'
     ELSE IFNULL(g.crm, c.tenquanlytt) 
   END as tenquanlytt,
   
   sum(dd.doanhsochuavat) as doanhsochuavat,
   count(distinct dd.ordernbr) as sl_dh
   from `warehouse.f_duyetdonhang_hcp_page2` dd
   LEFT JOIN `warehouse.f_mapping_crs` c on dd.custid = c.custid
   LEFT JOIN `staging.d_manual_dia_ban_cong_no_hcp` g on dd.custid = g.ma_kh
   LEFT JOIN (
       SELECT msnvcsmmoi, hovatenfullname
       FROM `spatial-vision-343005.staging.d_hr_dsns`
       WHERE phongdeptsummary = 'HCP'
   ) hr_crm on hr_crm.hovatenfullname = g.crm
   
   where 
   (dd.ngayduyetdon >='2023-01-01' and dd.ngayduyetdon <'2023-07-08') or dd.ngayduyetdon >='2023-07-16' 
   group by 1,2,3
 )

 , f_thuongdoanhthu_hcp_thang_add_1 as (
  -- 1. Cộng thêm 1 tháng vào trường b.thang
  select
  DATE(
    EXTRACT(YEAR FROM TIMESTAMP_ADD(a.thang, INTERVAL 1 MONTH)), 
    (EXTRACT(QUARTER FROM TIMESTAMP_ADD(a.thang, INTERVAL 1 MONTH)) - 1) * 3 + 1, 
    1
  ) AS thang,
  --TIMESTAMP_ADD(a.thang, INTERVAL 1 MONTH) AS thang,

  -- 2. Lấy Quý và Năm từ giá trị mới vừa cộng
  CAST(EXTRACT(QUARTER FROM TIMESTAMP_ADD(a.thang, INTERVAL 1 MONTH)) AS STRING) || 
  CAST(EXTRACT(YEAR FROM TIMESTAMP_ADD(a.thang, INTERVAL 1 MONTH)) AS STRING) AS quy,

  a.macrm,
  a.tenquanlytt,
  SUM(a.no_do) as no_do,
  SUM(a.no_den) as no_den
  FROM `spatial-vision-343005.warehouse.f_thuongdoanhthu_hcp` a
  GROUP BY 1,2,3,4
 )
, tong_hop_theo_quy AS (
  SELECT 
    a.quy,
    DATE(EXTRACT(YEAR FROM DATE(a.thang)), (EXTRACT(QUARTER FROM DATE(a.thang)) - 1) * 3 + 1, 1) as thang,
    a.macrm,
    a.tenquanlytt,
    SUM(a.no_do) as no_do,
    SUM(a.no_den) as no_den,
    SUM(IFNULL(c.doanhsochuavat, 0)) as doanhsochuavat
  FROM f_thuongdoanhthu_hcp_thang_add_1 a
  LEFT JOIN data_duyetdon c 
    ON c.macrm = a.macrm AND c.quy = a.quy
  GROUP BY 1,2,3,4
)

, tinh_dinhmuc AS (
  SELECT 
    a.thang,
    a.quy,
    a.macrm,
    a.tenquanlytt,
    a.no_do,
    a.no_den,
    a.doanhsochuavat,
    IFNULL(b.doanhso_a_chien_duyet_them, 0) AS val_duyet_them, -- Giá trị thô từ file manual
    
    -- Tính định mức duyệt đơn theo tháng
    CASE 
        WHEN a.macrm = 'MR1137' THEN ROUND((a.no_do + a.no_den) * 40 / 100, 1)
        ELSE ROUND((a.no_do + a.no_den) * 20 / 100, 1)
    END AS dinhmuc_duyetdon

  FROM tong_hop_theo_quy a 
  LEFT JOIN `spatial-vision-343005.staging.d_manual_doanh_so_duyet_them_hcp` b ON a.quy = b.quy AND a.macrm = b.macrm
)
, tinh_truythu AS (
  SELECT 
    a.thang,
    a.quy,
    a.macrm,
    a.tenquanlytt,
    
    -- Các trường dùng để tính toán
    a.doanhsochuavat,
    a.dinhmuc_duyetdon,
    a.no_do,
    a.no_den,
    
    CASE WHEN a.macrm = 'MR1137' THEN SUM(a.doanhsochuavat) OVER (PARTITION BY a.quy) 
         ELSE a.doanhsochuavat
    END AS doanhso_duyetdon_theoquy_check,
    
    CASE
         WHEN a.macrm = 'MR1137' THEN SUM(a.doanhsochuavat) OVER (PARTITION BY a.quy)
         WHEN a.macrm NOT LIKE '%MR1137%' THEN a.doanhsochuavat - IFNULL(b.doanhso_a_chien_duyet_them, 0)
         ELSE 0 
    END AS doanhso_duyetdon_theoquy,
    
    a.dinhmuc_duyetdon AS dinhmuc_duyetdon_theoquy,
    (a.no_do + a.no_den) AS doanhthu_noxau_theoquy,
    
    IFNULL(b.doanhso_a_chien_duyet_them, 0) AS doanhso_a_chien_duyet_them

  FROM tinh_dinhmuc a 
  LEFT JOIN `spatial-vision-343005.staging.d_manual_doanh_so_duyet_them_hcp` b 
    ON a.quy = b.quy AND a.macrm = b.macrm
),

gia_tri_duyet_vuot AS (
SELECT
*EXCEPT(doanhso_a_chien_duyet_them),
CASE WHEN macrm LIKE '%MR1137%' THEN 0 ELSE doanhso_a_chien_duyet_them END AS doanhso_a_chien_duyet_them,
ROUND(SAFE_DIVIDE(doanhso_duyetdon_theoquy,doanhthu_noxau_theoquy) * 100, 1) as tyle_duyetdon_theoquy, 
--(doanhso_duyetdon_theoquy - dinhmuc_duyetdon_theoquy) as giatri_duyetvuot

 CASE WHEN macrm LIKE '%MR1137%' THEN doanhthu_noxau_theoquy * 0.2 + doanhso_a_chien_duyet_them - dinhmuc_duyetdon_theoquy
    ELSE (doanhso_duyetdon_theoquy - dinhmuc_duyetdon_theoquy) 
    END AS giatri_duyetvuot, -- Giá trị duyệt vượt
-- --- ĐOẠN THÊM MỚI: Tách tỷ lệ chênh lệch (Ví dụ thực tế đạt 45.3% -> phần vượt là 5.3%) ---
  CASE 
    WHEN macrm = 'MR1137' AND ROUND(SAFE_DIVIDE(doanhso_duyetdon_theoquy, doanhthu_noxau_theoquy) * 100, 1) > 40 
    THEN ROUND(SAFE_DIVIDE(doanhso_duyetdon_theoquy, doanhthu_noxau_theoquy) * 100, 1) - 40 
    ELSE 0 
  END AS pct_vuot_tong
FROM tinh_truythu
),

result_truythu AS (
  SELECT 
    a.*,
    CASE 
        WHEN a.macrm = 'MR1137' THEN
          ROUND(
            -- Công thức: (Số tiền vượt / Tổng % vượt) = Số tiền của mỗi 1% vượt. 
            -- Rồi nhân với số % phân bổ của từng bậc.
            SAFE_DIVIDE(a.giatri_duyetvuot, a.pct_vuot_tong) * (
              
              -- Bậc 1 (>40% đến 45%): Lấy tối đa 5%, nếu ít hơn thì lấy chính nó
              CASE WHEN a.pct_vuot_tong <= 5 THEN a.pct_vuot_tong ELSE 5 END * 1.0/100
              
              -- Bậc 2 (>45% đến 50%): Nếu tổng vượt > 5%, lấy phần dư tối đa 5%
              + CASE 
                  WHEN a.pct_vuot_tong > 5 AND a.pct_vuot_tong <= 10 THEN (a.pct_vuot_tong - 5)
                  WHEN a.pct_vuot_tong > 10 THEN 5 
                  ELSE 0 
                END * 1.5/100
              
              -- Bậc 3 (>50% đến 55%): Nếu tổng vượt > 10%, lấy phần dư tối đa 5%
              + CASE 
                  WHEN a.pct_vuot_tong > 10 AND a.pct_vuot_tong <= 15 THEN (a.pct_vuot_tong - 10)
                  WHEN a.pct_vuot_tong > 15 THEN 5 
                  ELSE 0 
                END * 2.0/100
              
              -- Bậc 4 (>55%): Nếu tổng vượt > 15%, ôm hết phần còn lại
              + CASE WHEN a.pct_vuot_tong > 15 THEN (a.pct_vuot_tong - 15) ELSE 0 END * 3.0/100
            )
          , 1)
        
        -- Các mã CRM khác giữ nguyên
        WHEN tyle_duyetdon_theoquy > 35 THEN ROUND(giatri_duyetvuot * 2/100, 1)
        WHEN tyle_duyetdon_theoquy > 30 THEN ROUND(giatri_duyetvuot * 1.5/100, 1)
        WHEN tyle_duyetdon_theoquy > 25 THEN ROUND(giatri_duyetvuot * 1/100, 1)
        WHEN tyle_duyetdon_theoquy > 20 THEN ROUND(giatri_duyetvuot * 0.5/100, 1)
        ELSE 0 
    END AS truythu_vuot_dinhmuc,

    -- CASE 
    --     WHEN tyle_duyetdon_theoquy > 55 AND a.macrm = 'MR1137' THEN ROUND( giatri_duyetvuot * 3/100, 1)
    --     WHEN tyle_duyetdon_theoquy > 50 AND a.macrm = 'MR1137' THEN ROUND(giatri_duyetvuot * 2/100, 1)
    --     WHEN tyle_duyetdon_theoquy > 45 AND a.macrm = 'MR1137' THEN ROUND(giatri_duyetvuot * 1.5/100, 1)
    --     WHEN tyle_duyetdon_theoquy > 40 AND a.macrm = 'MR1137' THEN ROUND(giatri_duyetvuot * 1/100, 1)
    --     WHEN tyle_duyetdon_theoquy > 35 THEN ROUND(giatri_duyetvuot * 2/100, 1)
    --     WHEN tyle_duyetdon_theoquy > 30 THEN ROUND(giatri_duyetvuot * 1.5/100, 1)
    --     WHEN tyle_duyetdon_theoquy > 25 THEN ROUND(giatri_duyetvuot * 1/100, 1)
    --     WHEN tyle_duyetdon_theoquy > 20 THEN ROUND(giatri_duyetvuot * 0.5/100, 1)
    --     ELSE 0 
    -- END AS truythu_vuot_dinhmuc,

    CASE 
        WHEN a.macrm IN ('MR1137', 'MR1137_KN') THEN 'N-CRD (HCP)' 
        ELSE hr.chucdanhengtitlesum 
    END AS chucdanh,

    'Công ty cổ phần tập đoàn Merap' AS phaply

  FROM gia_tri_duyet_vuot a 
  LEFT JOIN `spatial-vision-343005.staging.d_hr_dsns` hr 
    ON LEFT(a.macrm, 6) = hr.msnvcsmmoi --AND DATE(a.thang) = DATE(hr.thang)
  WHERE hr.msnvcsmmoi IS NOT NULL
    AND hr.phongdeptsummary NOT IN ('TP')
)

SELECT 
  -- Giữ lại thang và quy để quản lý dữ liệu gốc
  thang,
  quy,
  
  -- Sắp xếp đúng theo thứ tự các cột như trong ảnh của bạn
  phaply,                                             -- Pháp lý
  macrm,                                              -- MSNV
  tenquanlytt,                                        -- Quản lý
  chucdanh,                                           -- Chức danh
  no_do,                                              -- Doanh thu nợ đỏ
  no_den,                                             -- Doanh thu nợ đen
  doanhthu_noxau_theoquy,                            -- Doanh thu nợ xấu
  dinhmuc_duyetdon_theoquy,                           -- Định mức duyệt đơn
  doanhso_duyetdon_theoquy_check, -- Doanh số đã duyệt
  doanhso_a_chien_duyet_them,-- Doanh số được N.CRD duyệt bổ sung
  doanhso_duyetdon_theoquy,                           -- Doanh số đã duyệt tính truy thu
  tyle_duyetdon_theoquy,                              -- Tỷ lệ DS duyệt/ DT nợ xấu
  giatri_duyetvuot,
  --(doanhso_duyetdon_theoquy - dinhmuc_duyetdon_theoquy) AS giatri_duyetvuot, -- Giá trị duyệt vượt
  CASE WHEN truythu_vuot_dinhmuc <= 0 THEN 0 ELSE truythu_vuot_dinhmuc END AS truythu_vuot_dinhmuc, -- Truy thu vượt định mức 
  CURRENT_DATETIME("+7") AS updated_at,
  pct_vuot_tong
FROM result_truythu
--where quy = '22026'
ORDER BY thang;

END;