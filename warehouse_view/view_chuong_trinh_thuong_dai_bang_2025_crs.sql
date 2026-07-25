CREATE VIEW `spatial-vision-343005.warehouse.view_chuong_trinh_thuong_dai_bang_2025_crs`
AS WITH data_sptt AS (
SELECT
CONCAT('Quý ', EXTRACT(QUARTER FROM a.thang)) AS quy,
a.manv,
SUM(a.doanhsocovat) as doanhsocovat,
SUM (a.doanhsochuavat) as doanhsochuavat,
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
WHERE 
date (a.ngaychungtu) >= '2025-01-02' AND date (a.ngaychungtu) <= '2025-12-31'
AND makenhkh_cu = 'TP'
AND a.is_hang_km != 'Hàng KM'
AND a.makhdms not in ('014916','014937','014938')
AND a.makhdms not in ('016010', '016020','016022','016023','016021')
AND a.masanpham in 
(
  'EH115',
  'EH092',
  'OH082',
  'EH102',
  'EH121',
  'OH084',
  'T302204001',
  'T302204002',
  'T302204004',
  'T3041006',
  'T302101008',
  'T302101007',
  'T302101005',
  'T302101006',
  'T302203003',
  'T302203014',
  'T303102009'
)
GROUP BY ALL
)
,tieu_chi_k_chang AS (
SELECT
c.code_crs,
CASE
WHEN trim(c.quy)='Quý 2'THEN 2
WHEN trim(c.quy)='Quý 3'THEN 3
ELSE NULL END AS quy,
SUM(IFNULL(a.doanhsocovat,0)) as th_ds_sptt_covat ,
SUM(IFNULL(a.doanhsochuavat,0)) as th_ds_sptt_chuavat,
SUM(IFNULL(c.target,0)*1000) as target,
SAFE_DIVIDE( SUM(a.doanhsochuavat), SUM(IFNULL(c.target,0)* 1000) ) as ty_le_tieu_chi_k,
FROM  `spatial-vision-343005.staging.d_sptt_dai_bang_2025` c
LEFT JOIN data_sptt a ON c.code_crs = a.manv and trim(a.quy) = trim(c.quy)
WHERE trim(c.quy) in ('Quý 2','Quý 3')
GROUP BY ALL
)
,tieu_chi_k_nam AS (
SELECT
c.code_crs,
0 as quy,
SUM(IFNULL(a.doanhsocovat,0)) as th_ds_sptt_covat ,
SUM(IFNULL(a.doanhsochuavat,0)) as th_ds_sptt_chuavat,
SUM(IFNULL(c.target,0)*1000) as target_sptt,
SAFE_DIVIDE( SUM(a.doanhsochuavat), SUM(IFNULL(c.target,0)* 1000) ) as ty_le_tieu_chi_k,
FROM  `spatial-vision-343005.staging.d_sptt_dai_bang_2025` c
LEFT JOIN data_sptt a ON c.code_crs = a.manv and trim(a.quy) = trim(c.quy)
GROUP BY ALL
)
,tieu_chi_k AS (
SELECT * FROM tieu_chi_k_chang
UNION ALL
SELECT * FROM tieu_chi_k_nam
)
,data_loyalty_c1 AS(
SELECT 
a.makhdms,
2 as quy,
SUM(
        CASE 
            WHEN b.nhomcpa = 'XO' AND DATE(ngaychungtu) >= '2025-01-02' AND DATE(ngaychungtu) < '2025-06-30' THEN doanhsocovat
            ELSE 0 END
    ) AS ds_xo,
SUM(
        CASE WHEN b.nhomcpa = 'CL' AND DATE(ngaychungtu) >= '2025-01-02'AND  DATE(ngaychungtu) < '2025-06-30' THEN doanhsocovat 
            ELSE 0 END
    ) AS ds_cl,
SUM(
        CASE WHEN b.nhomcpa = 'KS' AND DATE(ngaychungtu) >= '2025-01-02' AND DATE(ngaychungtu) < '2025-06-30' THEN doanhsocovat 
            ELSE 0 END
    )AS ds_ks,

FROM `warehouse.f_raw_data_sales_yoy` a
LEFT JOIN 
    `staging.d_nhom_sp_trading` b 
    ON a.masanpham = b.masanpham
WHERE a.ngaychungtu >= '2025-01-02' and a.ngaychungtu <= '2025-06-30'
GROUP BY a.makhdms
)
,data_loyalty_c2 AS(
SELECT 
a.makhdms,
3 as quy,
SUM(
        CASE WHEN b.nhomcpa = 'XO' AND DATE(ngaychungtu) >= '2025-01-02' AND DATE(ngaychungtu) < '2025-09-30'THEN doanhsocovat
            ELSE 0 END
    ) AS ds_xo,
SUM(
        CASE WHEN b.nhomcpa = 'CL' AND DATE(ngaychungtu) >= '2025-01-02'AND  DATE(ngaychungtu) < '2025-09-30' THEN doanhsocovat 
            ELSE 0 END
    ) AS ds_cl,
SUM(
        CASE WHEN b.nhomcpa = 'KS' AND DATE(ngaychungtu) >= '2025-01-02' AND DATE(ngaychungtu) < '2025-09-30' THEN doanhsocovat 
            ELSE 0 END
    )AS ds_ks,
FROM `warehouse.f_raw_data_sales_yoy` a
LEFT JOIN 
    `staging.d_nhom_sp_trading` b 
    ON a.masanpham = b.masanpham
WHERE a.ngaychungtu >= '2025-01-02' and a.ngaychungtu <= '2025-09-30'
GROUP BY a.makhdms
)
,data_loyalty_nam AS (
SELECT
a.makhdms,
0 as quy,
SUM(
        CASE WHEN b.nhomcpa = 'XO' AND DATE(ngaychungtu) >= '2025-01-02' AND DATE(ngaychungtu) < '2025-12-31'THEN doanhsocovat
            ELSE 0 END
    ) AS ds_xo,
SUM(
        CASE WHEN b.nhomcpa = 'CL' AND DATE(ngaychungtu) >= '2025-01-02'AND  DATE(ngaychungtu) < '2025-12-31' THEN doanhsocovat 
            ELSE 0 END
    ) AS ds_cl,
SUM(
        CASE WHEN b.nhomcpa = 'KS' AND DATE(ngaychungtu) >= '2025-01-02' AND DATE(ngaychungtu) < '2025-12-31' THEN doanhsocovat 
            ELSE 0 END
    )AS ds_ks,
FROM `warehouse.f_raw_data_sales_yoy` a
LEFT JOIN 
    `staging.d_nhom_sp_trading` b 
    ON a.masanpham = b.masanpham
WHERE a.ngaychungtu >= '2025-01-02' and a.ngaychungtu <= '2025-12-31'
GROUP BY a.makhdms
)
,data_loyalty as (
SELECT * FROM data_loyalty_c1
UNION ALL
SELECT * FROM data_loyalty_c2 
UNION ALL
SELECT * FROM data_loyalty_nam
)
,kh_dat_ct_loyalty as (
SELECT
d.makh,
d.crs,
a.quy,
CASE
WHEN a.quy = 2 THEN d.muc_hd_2025 * 0.45
WHEN a.quy = 3 THEN d.muc_hd_2025 * 0.7 
WHEN a.quy = 0 THEN d.muc_hd_2025
ELSE NULL END AS muc_hd_theo_tien_do,
ds_xo + ds_cl + ds_ks as tong_ds_loyalty,
CASE 
WHEN a.quy= 2 AND (ds_xo + ds_cl + ds_ks) >= d.muc_hd_2025 * 0.45 THEN TRUE
WHEN a.quy= 3 AND (ds_xo + ds_cl + ds_ks) >= d.muc_hd_2025 * 0.7 THEN TRUE
WHEN a.quy= 0 AND (ds_xo + ds_cl + ds_ks) >= d.muc_hd_2025 THEN TRUE
ELSE NULL END AS is_loyalty,
COUNT(DISTINCT makh) OVER (partition by crs) as sl_kh_tham_gia
FROM `spatial-vision-343005.staging.d_loyalty_dai_bang_2025` d
LEFT JOIN data_loyalty a ON a.makhdms = d.makh
)
,data_chi_tieu_c AS (
SELECT
crs,
quy,
sl_kh_tham_gia,
COUNTIF(is_loyalty) AS sl_kh_dat_loyalty,
SUM (tong_ds_loyalty) as tong_ds_loyalty,
SUM(muc_hd_theo_tien_do) as muc_hd_theo_tien_do,
FROM kh_dat_ct_loyalty
GROUP BY ALL
)

,chi_tieu_c as(
SELECT
crs,
quy,
sl_kh_tham_gia,
sl_kh_dat_loyalty,
tong_ds_loyalty,
muc_hd_theo_tien_do,
SAFE_DIVIDE(sl_kh_dat_loyalty,sl_kh_tham_gia) as ty_le_sl_kh_dat,
SAFE_DIVIDE(tong_ds_loyalty,muc_hd_theo_tien_do) as ty_le_ds_loyalty ,
SAFE_DIVIDE(sl_kh_dat_loyalty,sl_kh_tham_gia) * 0.3 + SAFE_DIVIDE(tong_ds_loyalty,muc_hd_theo_tien_do) * 0.7 as ty_le_tieu_chi_c
FROM data_chi_tieu_c
GROUP BY ALL
)
,view_thuong_quy_all_chang as
(
    select 
    b.manv,
    b.quy,  
    b.tencvbh,
    STRING_AGG(DISTINCT b.diabanlamviec) as diabanlamviec ,
     sum(doanhsochuavat) as th_tongdoanhso,
     sum(kh_total) as kh_tongdoanhso,
     SAFE_DIVIDE(sum(doanhsochuavat),sum(kh_total)) as ty_le_tieu_chi_a
FROM `spatial-vision-343005.warehouse.view_thuong_quy_all` b 
     WHERE chuc_vu = 'CRS' and b.makenhkh = 'TP'
AND b.quy in (2,3) and nam = 2025
     group by all
)
,view_thuong_quy_all_nam AS (
    select 
    b.manv,
    0 as quy,  
    b.tencvbh,
    STRING_AGG(DISTINCT b.diabanlamviec) as diabanlamviec,
     sum(doanhsochuavat) as th_tongdoanhso,
     sum(kh_total) as kh_tongdoanhso,
    SAFE_DIVIDE(sum(doanhsochuavat),sum(kh_total)) as ty_le_tieu_chi_a
FROM `spatial-vision-343005.warehouse.view_thuong_quy_all` b 
     WHERE chuc_vu = 'CRS' and b.makenhkh = 'TP'
AND nam = 2025
     group by all
)
,view_thuong_quy_all AS (
SELECT * FROM view_thuong_quy_all_chang
UNION ALL
SELECT * FROM view_thuong_quy_all_nam
)
,diem_tung_tieu_chi AS (
SELECT
b.quy,
b.manv,
b.tencvbh,
d.supid,
d.tenquanlytt,
--KV1: Châu, Án, Dũng, Luân, Tiền, Tài
CASE
WHEN d.tenquanlytt in ('Lê Đức Châu','Nguyễn Văn Án','Nguyễn Anh Dũng','Trần Quang Luân','Trần Thị Bích Tiền','Nguyễn Thanh Tài') THEN 1
--KV2: Chung, Tiến, Huy
WHEN d.tenquanlytt in ('Lê Duy Chung','Lương Đức Tiến','Huỳnh Văn Huy') THEN 2
ELSE NULL
END AS vung,
b.diabanlamviec as khu_vuc,
b.th_tongdoanhso,
b.kh_tongdoanhso,
b.ty_le_tieu_chi_a,

-- TC A
CASE
WHEN b.ty_le_tieu_chi_a < 0.9 THEN 1
WHEN b.ty_le_tieu_chi_a >= 0.9 and b.ty_le_tieu_chi_a < 1 THEN 2
WHEN b.ty_le_tieu_chi_a >= 1 and b.ty_le_tieu_chi_a < 1.1 THEN 3
WHEN b.ty_le_tieu_chi_a >= 1.1 and b.ty_le_tieu_chi_a < 1.2 THEN 4
WHEN b.ty_le_tieu_chi_a >= 1.2 THEN 5
ELSE 0
END AS tieu_chi_a,
--TC K
k.th_ds_sptt_covat ,
k.th_ds_sptt_chuavat,
k.target,
k.ty_le_tieu_chi_k,
CASE
WHEN ty_le_tieu_chi_k < 0.9 THEN 1
WHEN ty_le_tieu_chi_k >= 0.9 AND ty_le_tieu_chi_k < 1 THEN 2
WHEN ty_le_tieu_chi_k >= 1 AND ty_le_tieu_chi_k < 1.1 THEN 3
WHEN ty_le_tieu_chi_k >= 1.1 AND ty_le_tieu_chi_k < 1.2 THEN 4
WHEN ty_le_tieu_chi_k >= 1.2 THEN 5
ELSE 0
END AS tieu_chi_k,
--TC C
c.sl_kh_tham_gia,
c.sl_kh_dat_loyalty,
c.tong_ds_loyalty,
c.muc_hd_theo_tien_do,
c.ty_le_sl_kh_dat,
c.ty_le_ds_loyalty,
c.ty_le_tieu_chi_c,
CASE
WHEN c.ty_le_tieu_chi_c < 0.9 THEN 1
WHEN c.ty_le_tieu_chi_c >= 0.9 AND c.ty_le_tieu_chi_c < 0.95 THEN 2
WHEN c.ty_le_tieu_chi_c >= 0.95 AND c.ty_le_tieu_chi_c < 1 THEN 3
WHEN c.ty_le_tieu_chi_c >= 1 AND c.ty_le_tieu_chi_c < 1.05 THEN 4
WHEN c.ty_le_tieu_chi_c >= 1.05 THEN 5
ELSE 0
END AS tieu_chi_c,
FROM view_thuong_quy_all b
LEFT JOIN tieu_chi_k k ON k.code_crs = b.manv and b.quy = k.quy
LEFT JOIN chi_tieu_c c ON trim(c.crs) = trim(b.tencvbh) and b.quy = c.quy
LEFT JOIN `spatial-vision-343005.staging.d_users` d ON b.manv = d.manv
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
RANK() OVER (PARTITION BY vung,quy  ORDER BY tieu_chi_a * 0.7 + tieu_chi_k * 0.2 + tieu_chi_c * 0.1 DESC ,th_tongdoanhso DESC ) as xep_hang,
RANK() OVER (PARTITION BY quy ORDER BY tieu_chi_a * 0.7 + tieu_chi_k * 0.2 + tieu_chi_c * 0.1 DESC ,th_tongdoanhso DESC ) as xep_hang_nam
FROM diem_tung_tieu_chi
--WHERE quy = 0
--manv= 'MR1560'
ORDER BY xep_hang





;