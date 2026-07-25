CREATE VIEW `spatial-vision-343005.warehouse.view_chuong_trinh_thuong_dai_bang_2025_crm`
AS WITH view_thuong_quy_all_chang as
(
    select 
    b.manv,
    b.quy,  
    b.tencvbh,
    STRING_AGG(b.diabanlamviec) as diabanlamviec ,
     sum(doanhsochuavat) as th_tongdoanhso,
     sum(kh_total) as kh_tongdoanhso,
     SAFE_DIVIDE(sum(doanhsochuavat),sum(kh_total)) as ty_le_tieu_chi_a
FROM `spatial-vision-343005.warehouse.view_thuong_quy_all` b 
     WHERE chuc_vu = 'CRM' and b.makenhkh = 'TP'
AND b.quy in (2,3) and nam = 2025
     group by all
)
,view_thuong_quy_all_nam AS (
    select 
    b.manv,
    0 as quy,  
    b.tencvbh,
    STRING_AGG(b.diabanlamviec) as diabanlamviec,
     sum(doanhsochuavat) as th_tongdoanhso,
     sum(kh_total) as kh_tongdoanhso,
    SAFE_DIVIDE(sum(doanhsochuavat),sum(kh_total)) as ty_le_tieu_chi_a
FROM `spatial-vision-343005.warehouse.view_thuong_quy_all` b 
     WHERE chuc_vu = 'CRM' and b.makenhkh = 'TP'
AND nam = 2025
     group by all
)
,view_thuong_quy_all AS (
SELECT * FROM view_thuong_quy_all_chang
UNION ALL
SELECT * FROM view_thuong_quy_all_nam
)

,data_tieu_chi_k_c as (
SELECT 
quy,
supid as ma_crm,
tenquanlytt,
--TC K
SUM(th_ds_sptt_chuavat) as th_ds_sptt_chuavat,
SUM(a.target) as target_sptt,
SAFE_DIVIDE(SUM(th_ds_sptt_chuavat),SUM(a.target)) as ty_le_tieu_chi_k,
--TC C
SUM(sl_kh_tham_gia) as sl_kh_tham_gia,
SUM(sl_kh_dat_loyalty) as sl_kh_dat_loyalty,
SUM(tong_ds_loyalty) as tong_ds_loyalt,
SUM(muc_hd_theo_tien_do) as muc_hd_theo_tien_d,
SAFE_DIVIDE(SUM(sl_kh_dat_loyalty),SUM(sl_kh_tham_gia)) as ty_le_sl_kh_dat,
SAFE_DIVIDE(SUM(tong_ds_loyalty),SUM(muc_hd_theo_tien_do)) as ty_le_ds_loyalty,
SAFE_DIVIDE(SUM(sl_kh_dat_loyalty),SUM(sl_kh_tham_gia)) * 0.3 + SAFE_DIVIDE(SUM(tong_ds_loyalty),SUM(muc_hd_theo_tien_do)) * 0.7 as ty_le_tieu_chi_c
FROM `spatial-vision-343005.warehouse.view_chuong_trinh_thuong_dai_bang_2025_crs` a
GROUP BY ALL
)

,data_theo_crm AS
(
SELECT
b.*,
--TC A
a.th_tongdoanhso,
a.kh_tongdoanhso,
SAFE_DIVIDE(SUM(th_tongdoanhso),SUM(kh_tongdoanhso)) as ty_le_tieu_chi_a,
FROM view_thuong_quy_all a
LEFT JOIN data_tieu_chi_k_c b ON a.manv = b.ma_crm and b.quy = a.quy
GROUP BY ALL
ORDER BY quy

)

,diem_tung_tieu_chi AS (
SELECT
*,
-- TC A
CASE
WHEN ty_le_tieu_chi_a < 0.9 THEN 1
WHEN ty_le_tieu_chi_a >= 0.9 and ty_le_tieu_chi_a < 1 THEN 2
WHEN ty_le_tieu_chi_a >= 1 and ty_le_tieu_chi_a < 1.05 THEN 3
WHEN ty_le_tieu_chi_a >= 1.05 and ty_le_tieu_chi_a < 1.10 THEN 4
WHEN ty_le_tieu_chi_a >= 1.10 THEN 5
ELSE 0
END AS tieu_chi_a,
--TC K
CASE
WHEN ty_le_tieu_chi_k < 0.9 THEN 1
WHEN ty_le_tieu_chi_k >= 0.9 AND ty_le_tieu_chi_k < 1 THEN 2
WHEN ty_le_tieu_chi_k >= 1 AND ty_le_tieu_chi_k < 1.05 THEN 3
WHEN ty_le_tieu_chi_k >= 1.05 AND ty_le_tieu_chi_k < 1.1 THEN 4
WHEN ty_le_tieu_chi_k >= 1.1 THEN 5
ELSE 0
END AS tieu_chi_k,
--TC C
CASE
WHEN ty_le_tieu_chi_c < 0.9 THEN 1
WHEN ty_le_tieu_chi_c >= 0.9 AND ty_le_tieu_chi_c < 0.95 THEN 2
WHEN ty_le_tieu_chi_c >= 0.95 AND ty_le_tieu_chi_c < 1 THEN 3
WHEN ty_le_tieu_chi_c >= 1 AND ty_le_tieu_chi_c < 1.05 THEN 4
WHEN ty_le_tieu_chi_c >= 1.05 THEN 5
ELSE 0
END AS tieu_chi_c,
FROM data_theo_crm

)
SELECT * EXCEPT(
tieu_chi_a,
tieu_chi_k,
tieu_chi_c
),
tieu_chi_a * 0.7 as tieu_chi_a,
tieu_chi_k * 0.2 as tieu_chi_k,
tieu_chi_c * 0.1 as tieu_chi_c,
ROUND (tieu_chi_a * 0.7 + tieu_chi_k * 0.2 + tieu_chi_c * 0.1,1) as diem_danh_gia,
RANK() OVER (PARTITION BY quy ORDER BY tieu_chi_a * 0.7 + tieu_chi_k * 0.2 + tieu_chi_c * 0.1 DESC,th_tongdoanhso DESC ) as xep_hang,
RANK() OVER (PARTITION BY quy ORDER BY tieu_chi_a * 0.7 + tieu_chi_k * 0.2 + tieu_chi_c * 0.1 DESC ,th_tongdoanhso DESC ) as xep_hang_nam
FROM diem_tung_tieu_chi
ORDER BY xep_hang

;