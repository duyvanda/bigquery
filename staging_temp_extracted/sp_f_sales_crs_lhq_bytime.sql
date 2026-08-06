-- ==========================================================================
-- Routine Name : sp_f_sales_crs_lhq_bytime
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-07-31 04:37:34.324000+00:00
-- Last Altered : 2026-07-31 04:37:34.324000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_sales_crs_lhq_bytime()
BEGIN

/*
Auto refresh https://bi.meraplion.com/airflow/dags/SYNC_warehouse_pg
*/

-- TRUNCATE TABLE staging_temp.f_sales_crs_temp;
-- INSERT INTO `staging_temp.f_sales_crs_temp`
-- (
CREATE TEMP TABLE `f_sales_crs_lhq_bytime_temp` PARTITION BY DATE(ngaychungtu) AS

(

With raw_data as
(
SELECT
a.macongtycn,
congtycn,
makhcu,
a.makhdms,
tenkhachhang,
tentinhkh,
statedescr,
territorydescr,
districtdescr,
wardname,
khuvucviettat,
cluster_state,
a.sodondathang,
sodontrahang,
-- Xử lý dời ngày chứng từ
IFNULL(ad.ngaychungtu, a.ngaychungtu) as ngaychungtu,
-- Xử lý dời tháng chứng từ
IFNULL(ad.thangchungtu, a.thang) as thang,
month,
masanpham,
tensanphamnb,
tensanphamviettat,
ten_sp_day_du,
-- Xử lý soluong
IFNULL(ad.soluong, a.soluong) as soluong,
dongiachuavat,
dongiacovat,
-- Xử lý doanhsocovat,
IFNULL(ad.doanhsocovat, a.doanhsocovat) as doanhsocovat,
-- Xử lý doanhsochuavat,
IFNULL(ad.doanhsochuavat, a.doanhsochuavat) as doanhsochuavat,
kieudonhang,
mahco_cu as mahco,
maphanloaihco_cu as maphanloaihco,
maphanhanghco_cu as maphanhanghco,
mahd,
hoadon,
makenhkh_cu as makenhkh,
makenhphu_cu as makenhphu,
is_ecom,
datatype,
brand as team,
ori_manv as manv_original,
updated_at,
is_phanam,
manv,
phanloai_tuyen_chitiet as phanloai,
phanloai_tuyen as crs_tuyenbanhang_trongmcp,
ma_crm as crm,
scrm,
ma_ncxm as ncxm,
tencvbh,
tenquanlytt,
tenquanlykhuvuc,
tenquanlyvung,
ds_sp_thang
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
LEFT JOIN `spatial-vision-343005.staging.f_sales_adjusted` ad on a.macongtycn = ad.macongtycn and a.sodondathang = ad.sodondathang
LEFT JOIN `spatial-vision-343005.warehouse.dim_excluded_makhdms` excl ON a.makhdms = excl.makhdms
WHERE date(a.ngaychungtu)>= '2023-01-01'
AND excl.makhdms IS NULL
AND phanloai_tuyen NOT IN ('Rural')
)
, combined as
(
SELECT
a.*,
'f_sales' AS datatype1,
0 AS kh_total,
0 as slpp_ebysta,
0 as slpp_medoral,
0 as kpi_ds_pcl,
CASE
     WHEN a.ngaychungtu >= '2026-06-01'
         AND a.ngaychungtu <= '2026-06-30'
         AND masanpham IN ('EH086', 'T303102008', 'T303102009', 'T303102005', 'T303102006')
         AND a.makenhkh = 'TP'
         AND doanhsochuavat > 0
         -- Không cần điều kiện SUM(soluong) vì mua bất kỳ SP nào cũng được tính 1 phân phối
    THEN makhdms
     WHEN a.ngaychungtu >= '2026-04-01'
         AND a.ngaychungtu <= '2026-04-30'
         AND masanpham IN ('T4040101001','T4040101002')
         AND a.makenhkh in ('TP','GT')
         AND doanhsochuavat > 0
         AND SUM(IF(masanpham IN ('T4040101001','T4040101002'), soluong, 0))
             OVER (PARTITION BY IFNULL(sodontrahang, sodondathang)) >= 3
    THEN makhdms
     WHEN a.ngaychungtu >= '2026-03-01'
         AND a.ngaychungtu <= '2026-03-31'
         AND masanpham IN ('T4040101001','T4040101002')
         AND a.makenhkh in ('TP','GT')
         AND doanhsochuavat > 0
         AND SUM(IF(masanpham IN ('T4040101001','T4040101002'), soluong, 0))
             OVER (PARTITION BY IFNULL(sodontrahang, sodondathang)) >= 2
    THEN makhdms
     WHEN a.ngaychungtu >= '2025-05-01'
         AND a.ngaychungtu <= '2025-06-30'
         AND masanpham IN ('T302203003','T302203014')
         AND a.makenhkh = 'TP'
         AND doanhsochuavat > 0
         AND SUM(soluong) OVER (PARTITION BY IFNULL(sodontrahang, sodondathang), masanpham) >=5
    THEN  makhdms
    WHEN a.ngaychungtu >= '2024-10-01'
        AND ngaychungtu < '2024-11-01'
        AND masanpham IN ('T303102009')
        AND a.makenhkh = 'TP'
        AND doanhsochuavat <> 0
        AND SUM(soluong) OVER (PARTITION BY doanhsochuavat <> 0, IFNULL(sodontrahang, sodondathang), makhdms, masanpham) >= 5
    THEN makhdms
    WHEN a.ngaychungtu >= '2024-07-01'
        AND a.ngaychungtu < '2024-10-01'
        AND masanpham IN ('T302203003')
        AND a.makenhkh = 'TP'
        AND soluong > 0
        AND doanhsochuavat > 0
        AND SUM(soluong) OVER (PARTITION BY macongtycn, sodondathang, masanpham) >= 5
    THEN IFNULL(makhcu, makhdms)
    WHEN a.ngaychungtu >= '2024-04-01'
        AND ngaychungtu < '2024-07-01'
        AND masanpham IN ('T3044004')
        AND a.makenhkh = 'TP'
        AND soluong > 0
        AND doanhsochuavat > 0
        AND SUM(soluong) OVER (PARTITION BY macongtycn, sodondathang, masanpham) >= 3
    THEN IFNULL(makhcu, makhdms)
    WHEN a.ngaychungtu >= '2024-01-01'
        AND ngaychungtu < '2024-04-01'
        AND masanpham IN ('T302202003', 'T302202004', 'T302202005')
        AND a.makenhkh = 'TP'
        AND doanhsochuavat > 0
    THEN IFNULL(makhcu, makhdms)
    WHEN a.ngaychungtu < '2023-10-01'
        AND masanpham = 'EH115'
        AND a.makenhkh = 'TP'
        AND doanhsochuavat > 0
    THEN IFNULL(makhcu, makhdms)
    ELSE NULL
END AS th_slpp_ebysta,
CASE
    WHEN a.ngaychungtu >= '2024-07-01'
        THEN NULL -- Không có tiêu chí sp2
    WHEN a.ngaychungtu >= '2024-04-01'
        AND masanpham IN ('T302204004') AND a.makenhkh = 'TP'
        AND soluong > 0 AND doanhsochuavat > 0
        AND SUM(soluong) OVER (PARTITION BY macongtycn, sodondathang, masanpham) >= 3
        THEN IFNULL(makhcu, makhdms)
    WHEN a.ngaychungtu >= '2024-01-01' AND a.ngaychungtu < '2024-04-01'
        AND masanpham IN ('T302105002') AND a.makenhkh = 'TP'
        AND doanhsochuavat > 0
        THEN IFNULL(makhcu, makhdms)
    WHEN ngaychungtu >= '2023-10-01'
        THEN NULL -- Tháng 10 chuyển sang KPI doanh số sản phẩm TT XPL
    WHEN masanpham IN ('EH092', 'OH082', 'OH084', 'EH102', 'EH121')
        AND a.makenhkh = 'TP' AND doanhsochuavat > 0 AND ngaychungtu < '2023-07-01'
        THEN IFNULL(makhcu, makhdms)
    WHEN masanpham IN ('OH074','OH075','OH077','OH078','T302101008','T302101007','T302101006','T302101005')
        AND a.makenhkh = 'TP' AND doanhsochuavat > 0 AND ngaychungtu >= '2023-09-01'
        AND SUM(soluong) OVER (PARTITION BY macongtycn, sodondathang,
            CASE WHEN masanpham IN ('OH074','OH075','OH077','OH078','T302101008','T302101007','T302101006','T302101005') THEN 1 ELSE 2 END) >= 3
        THEN IFNULL(makhcu, makhdms)
    WHEN masanpham IN ('OH074','OH075','OH077','OH078','T302101008','T302101007','T302101006','T302101005')
        AND a.makenhkh = 'TP' AND doanhsochuavat > 0
        AND ngaychungtu >= '2023-07-01' AND ngaychungtu < '2023-09-01'
        THEN IFNULL(makhcu, makhdms)
    ELSE NULL
END AS th_slpp_medoral,
CASE
    WHEN makenhkh = 'PCL'
        THEN doanhsochuavat
    ELSE 0
END AS th_ds_pcl,
CASE
    WHEN ngaychungtu >= '2025-08-01' AND ngaychungtu <= '2025-09-30'
        AND (manv IN ('MR3057','MR3066','MR3070') OR tenquanlytt IN ('Võ Thị Kim Thi'))
        AND makenhphu IN ('FMCG')
        AND makenhkh = 'MT' AND makhdms NOT IN ('008140', '003589')
        THEN doanhsochuavat
    -- Từ 2024 chị Nga phụ trách SPTT Ebysta còn Đạt phụ trách FMCG
    WHEN ngaychungtu >= '2024-03-01' AND ngaychungtu <= '2025-07-31'
        AND (manv IN ('MR3057','MR3066','MR3070') OR tenquanlytt IN ('Dương Thanh Sơn'))
        AND makenhphu IN ('FMCG')
        AND makenhkh = 'MT' AND makhdms NOT IN ('008140', '003589')
        THEN doanhsochuavat
    WHEN ngaychungtu < '2024-03-01' AND ngaychungtu >= '2024-01-01'
        AND manv = 'MR3057' AND makenhphu IN ('ECOM', 'FMCG')
        AND makenhkh = 'MT' AND makhdms NOT IN ('008140', '003589')
        THEN doanhsochuavat
    -- Từ tháng 7/2023 cập nhật thêm doanh số ECOM để tính lương
    WHEN (manv IN ('MR0868','MR1360') OR tenquanlytt IN ('Nguyễn Thị Nga'))
        AND makenhkh = 'MT' AND masanpham = 'EH115'
        AND ngaychungtu >= '2024-01-01' AND ngaychungtu <= '2025-09-30'
        THEN doanhsochuavat
    -- Rule cho năm 2024 trở xuống
    WHEN makenhphu IN ('ECOM', 'FMCG')
        AND makenhkh = 'MT' AND makhdms NOT IN ('008140', '003589')
        AND ngaychungtu >= '2023-07-01' AND ngaychungtu < '2024-01-01'
        THEN doanhsochuavat
    WHEN (makhdms = 'MC017' OR makenhphu IN ('CCD', 'FMCG'))
        AND makenhkh = 'MT' AND ngaychungtu < '2023-07-01'
        THEN doanhsochuavat
    ELSE 0
END AS th_ds_fmcg,
-- rule từ 01/10/2025 cho MT
CASE
    WHEN ngaychungtu >= '2025-10-01'
    AND makenhphu IN ('FMCG')
    --AND manv IN ('MR3057','MR3066','MR3070','MR4037','MR4080')
    AND makenhkh = 'MT' AND makhdms NOT IN ('008140', '003589')
    THEN doanhsochuavat
    ELSE 0
END AS th_ds_fmcg_mt,
CASE
    WHEN ngaychungtu >= '2026-03-01'
        AND masanpham in ('EH092' ,'T302204001','OH084','T302204004','T3041006','EH115')
        AND makenhkh = 'MT'
        AND makenhphu = 'NTC'
        THEN doanhsochuavat
    WHEN ngaychungtu >= '2026-01-01'
        AND ngaychungtu <= '2026-02-28'
        AND masanpham in ('EH092' ,'T302204001','OH084','T302204004','T3041006','EH115')
        AND makenhkh = 'MT'
        THEN doanhsochuavat
    WHEN ngaychungtu >= '2025-10-01'
        AND ngaychungtu <= '2025-12-31'
        AND masanpham = 'EH115'
        AND makenhkh = 'MT'
        THEN doanhsochuavat
        ELSE 0
END AS th_sptt_mt,
0 AS kpi_ds_fmcg,
CASE
    WHEN ngaychungtu >= '2026-07-01'
        --AND ngaychungtu <= '2026-05-31'
        AND masanpham IN('T302203002','T302201014','T302201018','T302201017')
        AND a.makenhkh in ('TP','GT')
    THEN doanhsochuavat
    WHEN ngaychungtu >= '2026-05-01'
        AND ngaychungtu <= '2026-05-31'
        AND masanpham IN('EH115','T3044004','T3044006','EH111','EH124')
        AND a.makenhkh = 'TP'
    THEN doanhsochuavat
    WHEN ngaychungtu >= '2026-02-01'
        AND ngaychungtu <= '2026-02-28'
        AND masanpham IN('EH086','T303102008','T303102009','EH087','EH108','T303102010','T303102011','T303102005','T303102006')
        AND a.makenhkh = 'TP'
    THEN doanhsochuavat
    WHEN ngaychungtu >= '2026-01-01'
        AND ngaychungtu <= '2026-01-31'
        AND masanpham IN('EH115','EH111','EH124','T3044004','T3044006')
        AND a.makenhkh = 'TP'
    THEN doanhsochuavat
    WHEN ngaychungtu >= '2025-10-01'
        AND ngaychungtu <= '2025-12-31'
        AND masanpham IN('EH086','T303102008','T303102009','EH087','EH108','T303102010','T303102011','T303102005','T303102006')
        AND a.makenhkh = 'TP'
    THEN doanhsochuavat
    WHEN ngaychungtu >= '2025-09-01'
        AND ngaychungtu <= '2025-09-30'
        AND masanpham IN('T302203003','T302203014','T303102009')
        AND a.makenhkh = 'TP'
    THEN doanhsochuavat
    WHEN ngaychungtu >= '2025-08-01'
        AND ngaychungtu <= '2025-08-31'
        AND masanpham IN('T302203003','T302203014','EH115')
        AND a.makenhkh = 'TP'
    THEN doanhsochuavat
    WHEN ngaychungtu >= '2025-07-01'
        AND ngaychungtu <= '2025-07-31'
        AND masanpham IN('T302203003','T302203014')
        AND a.makenhkh = 'TP'
    THEN doanhsochuavat
    WHEN ngaychungtu >= '2025-04-01'
        AND ngaychungtu <= '2025-04-30'
        AND masanpham IN('EH115')
        AND a.makenhkh = 'TP'
    THEN doanhsochuavat
    WHEN ngaychungtu >= '2025-01-01' AND ngaychungtu < '2025-04-01'
        AND masanpham IN ('T303102009') AND a.makenhkh = 'TP'
        THEN doanhsochuavat
    WHEN ngaychungtu >= '2024-11-01' AND ngaychungtu < '2025-01-01'
        AND masanpham IN ('T303102006','T303102005','EH086','EH087','EH108','T303102008','T303102010','T303102011','T303102009')
        AND a.makenhkh = 'TP'
        THEN doanhsochuavat
    WHEN ngaychungtu >= '2023-10-01' AND ngaychungtu < '2024-01-01'
        AND masanpham IN ('T303102005','EH087','EH108','EH086') AND a.makenhkh = 'TP'
        THEN doanhsochuavat
    ELSE 0
END AS th_ds_sptt,
0 AS kpi_ds_sptt,
0 AS  kpi_ds_sptt_mt,
FROM raw_data a
UNION ALL
SELECT
null as macongtycn,
null as congtycn,
null as makhcu,
null as makhdms,
null as tenkhachhang,
null as tentinhkh,
null as statedescr,
null as territorydescr,
null as districtdescr,
null as wardname,
null as khuvucviettat,
null as cluster_state,
null as sodondathang,
null as sodontrahang,
a.thang AS ngaychungtu,
a.thang,
EXTRACT(MONTH FROM a.thang) AS month,
null as masanpham,
null as tensanphamnb,
null as tensanphamviettat,
null as ten_sp_day_du,
null as soluong,
null as dongiachuavat,
null as dongiacovat,
null as doanhsocovat,
null as doanhsochuavat,
null as kieudonhang,
null as mahco,
null as maphanloaihco,
null as maphanhanghco,
null as mahd,
null as hoadon,
CASE
    WHEN a.makenhkh = 'SI' THEN 'TP'
    WHEN a.htbh = 'MDS' AND a.thang <= '2023-01-01' THEN 'MDS'
    ELSE a.makenhkh
END AS makenhkh,
null as makenhphu,
null as is_ecom,
null as datatype,
null as team,
null as manv_original,
a.inserted_at AS updated_at,
null as is_phanam,
CASE
    WHEN UPPER(a.manv) LIKE '%KN%' THEN LEFT(a.manv, 6)
    ELSE a.manv
END AS manv,
null as phanloai,
'Khác' as crs_tuyenbanhang_trongmcp,
u.supid as crm,
u.asm as scrm,
u.rsmid as ncxm,
u.tencvbh as tencvbh,
u.tenquanlytt as tenquanlytt,
u.tenquanlykhuvuc as tenquanlykhuvuc,
u.tenquanlyvung as tenquanlyvung,
null as ds_sp_thang,
'd_calendar' AS datatype1,
a.kh_total,
CASE
    WHEN a.makenhkh in ('TP','GT') AND a.thang >= '2025-05-01' AND a.thang <= '2025-06-30' THEN slkh_ebysta
    WHEN a.makenhkh = 'TP' AND a.thang >= '2023-10-01' AND a.thang < '2024-01-01' THEN 0
    WHEN a.makenhkh = 'TP' AND a.thang < '2024-11-01' THEN ROUND(slkh_ebysta, 1)
    ELSE 0
END AS slkh_ebysta,
CASE
    WHEN makenhkh = 'TP' AND a.thang >= '2024-01-01' THEN ROUND(slkh_ladoi, 1)
    WHEN makenhkh = 'TP' AND a.thang >= '2023-07-01' AND a.thang < '2024-01-01' THEN ROUND(slkh_ladoi, 1)
    WHEN makenhkh = 'TP' AND a.thang < '2024-11-01' THEN ROUND(slkh_medoral, 1)
    ELSE 0
END AS slkh_medoral,
CASE WHEN makenhkh = 'PCL' THEN kh_total END AS kpi_ds_pcl,
NULL AS th_slpp_ebysta,
NULL AS th_slpp_medoral,
0 AS th_ds_pcl,
0 AS th_ds_fmcg,
0 AS th_ds_fmcg_mt,
0 AS th_sptt_mt,
kh_fmcg AS kpi_ds_fmcg,
0 AS th_ds_sptt,
CASE
    WHEN makenhkh = 'TP' AND a.thang >= '2026-07-01' THEN slkh_ebysta * 1000
    WHEN makenhkh = 'TP' AND a.thang >= '2026-06-01' AND a.thang <= '2026-06-30' THEN slkh_ebysta
    WHEN makenhkh = 'TP' AND a.thang >= '2026-05-01' AND a.thang <= '2026-05-31' THEN slkh_ebysta * 1000
    WHEN makenhkh = 'TP' AND a.thang >= '2026-03-01' AND a.thang <= '2026-04-30' THEN slkh_ebysta
    WHEN makenhkh = 'TP' AND a.thang >= '2025-07-01' AND a.thang <= '2026-02-28' THEN slkh_ebysta * 1000
    WHEN makenhkh = 'TP' AND a.thang >= '2025-05-01' AND a.thang <= '2025-06-30' THEN slkh_ebysta
    WHEN makenhkh = 'TP' AND a.thang >= '2025-01-01' AND a.thang < '2025-05-01' THEN slkh_ebysta * 1000
    WHEN makenhkh = 'TP' AND a.thang >= '2024-11-01' AND a.thang < '2025-01-01' THEN slkh_ebysta * 1000
    WHEN makenhkh = 'TP' AND a.thang >= '2023-10-01' AND a.thang < '2024-01-01' THEN slkh_ebysta * 1000
    ELSE 0
END AS kpi_ds_sptt,
CASE
    WHEN makenhkh = 'MT' AND a.thang >= '2025-10-01' THEN kpi_sptt_mt * 1000
   ELSE 0
END AS kpi_ds_sptt_mt,
FROM
`spatial-vision-343005.staging.d_calendar` a
LEFT JOIN `staging.d_users_bytime` u on

a.thang = u.thang
AND
(CASE
    WHEN UPPER(a.manv) LIKE '%KN' THEN LEFT(a.manv, 6)
    WHEN UPPER(a.manv) LIKE 'KN%' THEN CONCAT('MR',RIGHT(a.manv, 4))
    ELSE a.manv
END
) = u.manv
WHERE
a.thang >= '2023-01-01'
-- AND a.makenhkh NOT IN ('OTH_LAB')
)

select a.*,
a.makenhkh as makenh_moi,
---FIELD BỎ
null as manvghreal,
null as pda_crtd_user,
null as pda_slsperid,
null as tenkenhkh,
null as tenkenhphu,
null as vungmien,
null as manv_mds,
null as is_mrtd,
null as ten_nguoi_taodon,
null as tencvbh_header,
null as tencvbh_ori,
null as doanhso_gh_crs,
null as th_slpp_ebysta_ori,
null as th_slpp_medoral_ori,
null as thuchien_spmoi,
null as kh_spmoi,
null as thuchien_yttn,
null as kh_yttn,
FROM combined a
--where a.thang = '2026-04-01' and a.makenhkh = 'MT'
);

Create or replace table `staging_temp.f_sales_crs_lhq_bytime`
copy `f_sales_crs_lhq_bytime_temp`;
END;
