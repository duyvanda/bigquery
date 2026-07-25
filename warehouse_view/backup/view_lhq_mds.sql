CREATE VIEW `spatial-vision-343005.warehouse.view_lhq_mds`
AS WITH 
nv_kpi_giao AS (
  SELECT
    ma_nvgh_tinhluong AS manv,
    thang,
    COUNT(DISTINCT madon_tinh_gh) AS sl_don_giao, 
    COUNT(DISTINCT madon_leadtimedat_tinhluong) AS sl_don_lt_dat,
    COUNT(DISTINCT madon_tinh_gh) - COUNT(DISTINCT madon_leadtimedat_tinhluong) AS sl_don_lt_khongdat,
SAFE_DIVIDE(COUNT(DISTINCT madon_leadtimedat_tinhluong), COUNT(DISTINCT madon_tinh_gh)) as ty_le_dat_lt,
    SUM(dschuvat_giaohang) AS ds_giao,
    SUM(CASE WHEN makenhkh IN ('TP', 'PCL') THEN dschuvat_giaohang ELSE 0 END) AS ds_giao_t,
    SUM(CASE WHEN makenhkh IN ('CLC', 'INS', 'MT') THEN dschuvat_giaohang ELSE 0 END) AS ds_giao_t2
  FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2` 
  GROUP BY 1, 2
),

nv_kpi_donghang AS (
  SELECT
    ma_donghang_tinhluong AS manv,
    thang,
    SUM(CASE WHEN donvigiaohang_fix IN ('Nhà vận chuyển', 'NVC') THEN dschuvat_giaohang ELSE 0 END) AS ds_dong_hang_nvc,
    SUM(CASE WHEN donvigiaohang_fix = 'Chành xe' AND tennhavanchuyen != 'MERAPLION' THEN dschuvat_giaohang ELSE 0 END) AS ds_dong_hang_chanh,
    SUM(CASE WHEN donvigiaohang_fix IN ('Nhà vận chuyển', 'NVC') THEN dschuvat_giaohang ELSE 0 END) +
    SUM(CASE WHEN donvigiaohang_fix = 'Chành xe' AND tennhavanchuyen != 'MERAPLION' THEN dschuvat_giaohang ELSE 0 END) AS ds_dong_hang_total
  FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2`
  GROUP BY 1, 2
),

nv_kpi_bbgh AS (
  SELECT
    manv_phu_trach_thu_hoi_bbgh AS manv,
    TIMESTAMP(DATE_ADD(DATE(thang), INTERVAL 1 MONTH)) AS thang,
    COUNT(DISTINCT CASE WHEN ma_noi_tinh_thu_hoi_bbgh IS NOT NULL THEN ma_noi_tinh_thu_hoi_bbgh END) AS sl_bbgh_can_thu_hoi, 
    COUNT(DISTINCT CASE WHEN ma_noi_tinh_thu_hoi_bbgh IS NOT NULL AND (da_thu_hoi_bbgh = 1 OR so_du_chung_tu_het_no = 1) THEN ma_noi_tinh_thu_hoi_bbgh END) AS sl_bb_da_thu_hoi,
    SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN ma_noi_tinh_thu_hoi_bbgh IS NOT NULL AND (da_thu_hoi_bbgh = 1 OR so_du_chung_tu_het_no = 1) THEN ma_noi_tinh_thu_hoi_bbgh END), COUNT(DISTINCT CASE WHEN ma_noi_tinh_thu_hoi_bbgh IS NOT NULL THEN ma_noi_tinh_thu_hoi_bbgh END)) AS ty_le_thu_hoi_bbgh
  FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2`
  WHERE DATE(ngaychungtu) >= '2024-03-01' AND DATE(ngaychungtu) <= '2024-03-31' AND manv_phu_trach_thu_hoi_bbgh LIKE '%MR%'
  GROUP BY 1, 2
),

nv_kpi_thahang_c1 AS (
  SELECT
    manv_thahang_tinhluong_c1 AS manv,
    thang,
    SUM(dschuvat_giaohang) AS ds_thahang_c1,
    SUM(dschuvat_giaohang) AS ds_donghang_di_tha,
    COUNT(DISTINCT CASE WHEN kieudonhang = 'IN' THEN ngaychungtu ELSE NULL END) AS so_chuyen_tha_hang
  FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2`
  GROUP BY 1, 2
),

nv_kpi_thahang_c2 AS (
  SELECT
    manv_thahang_tinhluong AS manv,
    thang,
    SUM(dschuvat_giaohang) AS ds_thahang_c2
  FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2`
  GROUP BY 1, 2
),

nv_kpi_so_chuyen_noi_bo AS (
  SELECT
    slsperid AS manv,
    DATE_TRUNC(crtd_datetime, MONTH) AS thang,
    COUNT(DISTINCT batnbr) AS so_chuyen_noi_bo
  FROM `spatial-vision-343005.staging.mds_pxkkvcnb_vcnb`
  GROUP BY 1, 2
),

metric_all_nv AS (
  SELECT 
    a.thang,
    a.manv, 
    tencvbh,
    supid,
    tenquanlytt,
    role_luong_mds_phanloai,
    IFNULL(SL_DON_GIAO, 0) AS sl_don_giao,
    IFNULL(sl_don_lt_dat, 0) AS sl_don_lt_dat,
    IFNULL(sl_don_lt_khongdat, 0) AS sl_don_lt_khongdat,
    IFNULL(ty_le_dat_lt, 0) AS ty_le_dat_lt,
    IFNULL(ds_giao, 0) AS ds_giao,
    IFNULL(ds_giao_t, 0) AS ds_giao_t,
    IFNULL(ds_giao_t2, 0) AS ds_giao_t2,
    IFNULL(ds_dong_hang_nvc, 0) AS ds_dong_hang_nvc,
    IFNULL(ds_dong_hang_chanh, 0) AS ds_dong_hang_chanh,
    IFNULL(ds_dong_hang_total, 0) AS ds_dong_hang_total,
    IFNULL(sl_bbgh_can_thu_hoi, 0) AS sl_bbgh_can_thu_hoi,
    IFNULL(sl_bb_da_thu_hoi, 0) AS sl_bb_da_thu_hoi,
    IFNULL(ty_le_thu_hoi_bbgh, 0) AS ty_le_thu_hoi_bbgh,
    IFNULL(ds_thahang_c1, 0) AS ds_thahang_c1,
    IFNULL(ds_donghang_di_tha, 0) AS ds_donghang_di_tha,
    IFNULL(so_chuyen_tha_hang, 0) AS so_chuyen_tha_hang,
    IFNULL(ds_thahang_c2, 0) AS ds_thahang_c2,
    IFNULL(so_chuyen_noi_bo, 0) AS so_chuyen_noi_bo
  FROM `spatial-vision-343005.staging.d_users_bytime` a
  LEFT JOIN nv_kpi_giao n ON a.manv = n.manv AND a.thang = n.thang
  LEFT JOIN nv_kpi_donghang n2 ON a.manv = n2.manv AND a.thang = n2.thang
  LEFT JOIN nv_kpi_bbgh n3 ON a.manv = n3.manv AND a.thang = n3.thang
  LEFT JOIN nv_kpi_thahang_c1 n4 ON a.manv = n4.manv AND a.thang = n4.thang
  LEFT JOIN nv_kpi_thahang_c2 n5 ON a.manv = n5.manv AND a.thang = n5.thang
  LEFT JOIN nv_kpi_so_chuyen_noi_bo n6 ON a.manv = n6.manv AND a.thang = n6.thang
  WHERE role_luong_mds IN ('MDS', 'LOG') AND  a.manv not like '%GH%'
  AND DATE(a.thang) >= '2024-04-01' AND DATE(a.thang) <= '2024-04-30'
),


metric_all_sup AS (
  SELECT
    c.thang,
    b.supid AS manv,
    c.tencvbh,
    c.supid,
    c.tenquanlytt,
    c.role_luong_mds_phanloai,
    IFNULL(SUM(sl_don_giao), 0) AS sl_don_giao,
    IFNULL(SUM(sl_don_lt_dat), 0) AS sl_don_lt_dat,
    IFNULL(SUM(sl_don_lt_khongdat), 0) AS sl_don_lt_khongdat,
    safe_divide (IFNULL(SUM(sl_don_lt_dat), 0) , IFNULL(SUM(sl_don_giao), 0)) as ty_le_dat_lt,
    IFNULL(SUM(ds_giao), 0) AS ds_giao,
    IFNULL(SUM(ds_giao_t), 0) AS ds_giao_t,
    IFNULL(SUM(ds_giao_t2), 0) AS ds_giao_t2,
    IFNULL(SUM(ds_dong_hang_nvc), 0) AS ds_dong_hang_nvc,
    IFNULL(SUM(ds_dong_hang_chanh), 0) AS ds_dong_hang_chanh,
    IFNULL(SUM(ds_dong_hang_total), 0) AS ds_dong_hang_total,
    IFNULL(SUM(sl_bbgh_can_thu_hoi), 0) AS sl_bbgh_can_thu_hoi,
    IFNULL(SUM(sl_bb_da_thu_hoi), 0) AS sl_bb_da_thu_hoi,
safe_divide(IFNULL(SUM(sl_bb_da_thu_hoi), 0), IFNULL(SUM(sl_bbgh_can_thu_hoi), 0)) as ty_le_thu_hoi_bbgh,
    IFNULL(SUM(ds_thahang_c1), 0) AS ds_thahang_c1,
    IFNULL(SUM(ds_donghang_di_tha), 0) AS ds_donghang_di_tha,
    IFNULL(SUM(so_chuyen_tha_hang), 0) AS so_chuyen_tha_hang,
    IFNULL(SUM(ds_thahang_c2), 0) AS ds_thahang_c2,
    IFNULL(SUM(so_chuyen_noi_bo), 0) AS so_chuyen_noi_bo

  FROM metric_all_nv b
  LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` c ON b.supid = c.manv AND b.thang = c.thang
  GROUP BY 1,2,3,4,5,6
),

metric_all_nv_sup as (


SELECT * FROM metric_all_sup

UNION ALL

SELECT * 
FROM metric_all_nv )

----------------TINH LHQ-------------------------------------------------------


, MDS as (
select *,

case 
  when ds_giao_t < 350000000 then ds_giao_t * 0.55/100
  when ds_giao_t >= 350000000 and ds_giao_t < 500000000 then ds_giao_t * 0.57/100
  when ds_giao_t  >= 500000000 then 2900000+(ds_giao_t - 500000000) * 0.6/100
  else 0 end as lhq_1,

-------leadtime = 100
case 

when ty_le_dat_lt =1
  and sl_don_giao < 150 
  then ty_le_dat_lt * 1000000
  when ty_le_dat_lt =1
  and sl_don_giao >= 150 
  and sl_don_giao < 200
  then ty_le_dat_lt * 1200000
when
  ty_le_dat_lt =1
  and sl_don_giao >= 200 
  and sl_don_giao < 250
  then ty_le_dat_lt * 1400000
when
  ty_le_dat_lt =1
  and sl_don_giao >= 250 
  then ty_le_dat_lt * 1700000
----leadtime 95-100
when
  ty_le_dat_lt < 1
  and ty_le_dat_lt >= 0.95
  and sl_don_giao < 150 
  then ty_le_dat_lt * 800000
when
  ty_le_dat_lt <1
  and ty_le_dat_lt >= 0.95
  and sl_don_giao >= 150 
  and sl_don_giao <200
  then ty_le_dat_lt * 900000
when
  ty_le_dat_lt < 1
  and ty_le_dat_lt >= 0.95
  and sl_don_giao >= 200 
  and sl_don_giao < 250
  then ty_le_dat_lt * 1000000
when
  ty_le_dat_lt <1
  and ty_le_dat_lt >= 0.95
  and sl_don_giao >= 250 
  then ty_le_dat_lt * 1200000

----leadtime < 95
when 
  ty_le_dat_lt < 0.95
  and sl_don_giao < 150 
  then ty_le_dat_lt * 600000
when 
  ty_le_dat_lt < 0.95
  and sl_don_giao >= 150 
  and sl_don_giao <200
  then ty_le_dat_lt * 700000
when 
  ty_le_dat_lt < 0.95
  and sl_don_giao >= 200 
  and sl_don_giao < 250
  then ty_le_dat_lt * 800000
when  
  ty_le_dat_lt < 0.95
  and sl_don_giao >= 250 
  then ty_le_dat_lt * 1000000
else 0 end as lhq_2,

(ds_giao_t2) * 0.4 /100 as lhq_3 ,

0 as lhq_4
from metric_all_nv_sup

where role_luong_mds_phanloai = 'MDS'
) ,

SUP as
( select *,

case 
  when ds_giao < 4000000000 then ds_giao * 0.22/100
  when ds_giao >= 4000000000 and ds_giao < 5000000000 then 10000000
  when ds_giao  >= 5000000000 and ds_giao < 6000000000 then 11000000
  when ds_giao >= 6000000000 then 12000000+(ds_giao - 6000000000) * 0.1/100
  else 0 end as lhq_1,

----SUP MDS leadtime =100
case
when
  (ds_giao) < 5000000000 
  and ty_le_dat_lt = 1 
then ty_le_dat_lt * 5000000

when
  (ds_giao) >= 5000000000 
  and (ds_giao) < 6000000000 
  and ty_le_dat_lt = 1 
then ty_le_dat_lt * 6000000

when
  (ds_giao) >= 6000000000 
  and ty_le_dat_lt = 1 
then ty_le_dat_lt * 7000000

---- leadtime >95 và <100
when
  (ds_giao) < 5000000000 
  and ty_le_dat_lt < 1 
  and ty_le_dat_lt >= 0.95
then ty_le_dat_lt * 4000000

when
  (ds_giao) >= 5000000000 
  and (ds_giao) < 6000000000 
  and ty_le_dat_lt < 1 
  and ty_le_dat_lt >= 0.95
then ty_le_dat_lt * 5000000

when
  (ds_giao) >= 6000000000 
  and ty_le_dat_lt < 1 
  and ty_le_dat_lt >= 0.95
then ty_le_dat_lt * 6000000

    ---- leadtime <95

when
  (ds_giao) < 5000000000 
  and ty_le_dat_lt < 0.95 
then ty_le_dat_lt * 3000000

when
  (ds_giao) >= 5000000000 
  and  (ds_giao) < 6000000000 
  and ty_le_dat_lt < 0.95 
  then ty_le_dat_lt * 4000000

when
  (ds_giao) >= 6000000000 
  and ty_le_dat_lt < 0.95  
  then ty_le_dat_lt * 5000000
else 0 end as lhq_2,

-----lhq3
case
  when ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1 then 1000000
  when ty_le_thu_hoi_bbgh = 1 then 2000000
else 0 end as lhq_3,

0 as lhq_4

from metric_all_nv_sup
where role_luong_mds_phanloai = 'SUP'

) ,

MGR as 
(select *,

case 
  when (ds_giao) < 5000000000 then (ds_giao) * 0.22/100
  when (ds_giao) >= 5000000000 and (ds_giao) < 6000000000 then 13000000
  when (ds_giao) >= 6000000000 and (ds_giao) < 8000000000 then 16000000
  when (ds_giao) >= 8000000000 then 21000000+( ((ds_giao) - 8000000000) * 0.1/100)
  else 0 end as lhq_1,

-------leadtime < 95
case
  when ty_le_dat_lt < 0.95
  and (ds_giao) < 6000000000 
  then ty_le_dat_lt * 4000000

  when ty_le_dat_lt < 0.95
  and (ds_giao) >= 6000000000 and (ds_giao) < 7000000000 
  then ty_le_dat_lt * 5000000

  when ty_le_dat_lt < 0.95
  and (ds_giao) >= 7000000000
  then ty_le_dat_lt * 6000000


------leadtime 95-100
  when ty_le_dat_lt >= 0.95 and ty_le_dat_lt < 1
  and ds_giao < 6000000000 
  then ty_le_dat_lt * 5000000

  when ty_le_dat_lt >= 0.95 and ty_le_dat_lt < 1
  and (ds_giao) >= 6000000000 and ds_giao < 7000000000 
  then ty_le_dat_lt * 6000000

  when ty_le_dat_lt >= 0.95 and ty_le_dat_lt < 1
  and (ds_giao) >= 7000000000  
  then ty_le_dat_lt * 8000000


 ------leadtime = 100
  when ty_le_dat_lt =1 and (ds_giao) < 6000000000 then ty_le_dat_lt * 7000000
  when ty_le_dat_lt =1 and (ds_giao) >= 6000000000 and (ds_giao) < 7000000000 then ty_le_dat_lt * 8000000
  when ty_le_dat_lt =1 and (ds_giao) >= 7000000000 then ty_le_dat_lt * 10000000
else 0 end as lhq_2,

-----lhq3
CASE WHEN ty_le_thu_hoi_bbgh >= 0.97 AND ty_le_thu_hoi_bbgh < 1.0 THEN 1000000
WHEN ty_le_thu_hoi_bbgh >= 1.0  THEN 2000000
ELSE 0 END AS lhq_3,

0 as lhq_4

from metric_all_nv_sup
where role_luong_mds_phanloai = 'MGR'

),

MDSS as 
( select*,
case 
  when ds_giao < 1000000000 then ds_giao * 0.27/100
  when ds_giao >= 1000000000 and ds_giao < 2000000000 then 2700000+(ds_giao - 1000000000) * 0.08/100
  when ds_giao >= 2000000000 then 3500000+(ds_giao - 2000000000) * 0.07/100
  else 0 end as lhq_1,

--- TY LE < 97%
    CASE
    WHEN ty_le_thu_hoi_bbgh < 0.97 and sl_bbgh_can_thu_hoi < 50 then ty_le_thu_hoi_bbgh * 200000 
    WHEN ty_le_thu_hoi_bbgh < 0.97 and sl_bbgh_can_thu_hoi >= 50 and sl_bbgh_can_thu_hoi < 75 then ty_le_thu_hoi_bbgh * 400000 
    WHEN ty_le_thu_hoi_bbgh < 0.97 and sl_bbgh_can_thu_hoi >= 75 AND sl_bbgh_can_thu_hoi < 100 then ty_le_thu_hoi_bbgh * 600000 
    WHEN ty_le_thu_hoi_bbgh < 0.97 and sl_bbgh_can_thu_hoi >= 100 then ty_le_thu_hoi_bbgh * 800000
    --- TY LE 97% - 100
    WHEN ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 and sl_bbgh_can_thu_hoi < 50 then ty_le_thu_hoi_bbgh * 600000 
    WHEN ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 and sl_bbgh_can_thu_hoi >= 50 and sl_bbgh_can_thu_hoi < 75 then ty_le_thu_hoi_bbgh * 900000
    WHEN ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 and sl_bbgh_can_thu_hoi >= 75 and sl_bbgh_can_thu_hoi < 100 then ty_le_thu_hoi_bbgh * 1100000 
    WHEN ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 and sl_bbgh_can_thu_hoi >= 100 then ty_le_thu_hoi_bbgh * 1300000 
    --- TY LE 100 TRO LEN
    WHEN ty_le_thu_hoi_bbgh >= 1.0 and sl_bbgh_can_thu_hoi < 50 then ty_le_thu_hoi_bbgh * 900000 
    WHEN ty_le_thu_hoi_bbgh >= 1.0 and sl_bbgh_can_thu_hoi >= 50 and sl_bbgh_can_thu_hoi < 75 then ty_le_thu_hoi_bbgh * 1100000 
    WHEN ty_le_thu_hoi_bbgh >= 1.0 and sl_bbgh_can_thu_hoi >= 75 and sl_bbgh_can_thu_hoi < 100 then ty_le_thu_hoi_bbgh * 1300000 
    WHEN ty_le_thu_hoi_bbgh >= 1.0 and sl_bbgh_can_thu_hoi >= 100 then ty_le_thu_hoi_bbgh * 1500000 
    ELSE 0 END AS lhq_2,

    CASE 
    WHEN ds_thahang_c1 < 1000000000 THEN ds_thahang_c1 * 0.15/100
    WHEN ds_thahang_c1 >= 1000000000 AND ds_thahang_c1 < 1500000000  THEN 1500000 + (ds_thahang_c1 - 1000000000) * 0.07/100
    WHEN ds_thahang_c1 < 1500000000 AND ds_thahang_c1 < 2000000000 THEN 1900000 + (ds_thahang_c1 - 1500000000) * 0.05/100
    WHEN ds_thahang_c1 >= 2000000000 THEN 2200000 + (ds_thahang_c1 - 2000000000) * 0.04/100
    END AS lhq_3,

    so_chuyen_noi_bo * 150000 AS lhq_4

from metric_all_nv_sup
where role_luong_mds_phanloai = 'MDSS'
),

MGRS AS 
( select*,

case 
  when ds_giao < 5000000000 then ds_giao * 0.22/100
  when ds_giao >= 5000000000 and ds_giao < 6000000000 then 13000000
  when ds_giao >= 6000000000 and ds_giao < 7000000000 then 15000000
  when ds_giao >= 7000000000 then 16000000+(ds_giao - 7000000000) * 0.1/100
  else 0 end as lhq_1,

case
    when  
    (ds_giao) < 5000000000  
    and ty_le_dat_lt = 1
    then ty_le_dat_lt * 5000000

    when  
    (ds_giao) >= 5000000000  
    and (ds_giao) < 6000000000 
    and ty_le_dat_lt = 1
    then ty_le_dat_lt * 6000000

    when  
    (ds_giao) >= 6000000000  
    and ty_le_dat_lt = 1
    then ty_le_dat_lt * 7000000

    -------leadtime >=95 và <100
    when  
    (ds_giao) < 5000000000  
    and ty_le_dat_lt < 1
    and ty_le_dat_lt >= 0.95
    then ty_le_dat_lt * 4000000

    when 
    (ds_giao) >= 5000000000  
    and (ds_giao) < 6000000000 
    and ty_le_dat_lt < 1
    and ty_le_dat_lt >= 0.95
    then ty_le_dat_lt * 5000000

    when  
    (ds_giao) >= 6000000000  
    and ty_le_dat_lt < 1
    and ty_le_dat_lt >= 0.95
    then ty_le_dat_lt * 5000000

    -------leadtime <95
    when  
    (ds_giao) < 5000000000  
    and ty_le_dat_lt < 0.95
    then ty_le_dat_lt * 3000000

    when  
    (ds_giao) >= 5000000000  
    and (ds_giao) < 6000000000 
    and ty_le_dat_lt < 0.95
    then ty_le_dat_lt * 4000000

    when  
    (ds_giao) >= 6000000000  
    and ty_le_dat_lt < 0.95
    then ty_le_dat_lt * 5000000
    else 0 end as lhq_2,

------lhq3
case 
  when ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1 then ty_le_thu_hoi_bbgh * 1000000
  when ty_le_thu_hoi_bbgh = 1 then ty_le_thu_hoi_bbgh * 2000000
else 0 end as lhq_3,

0 as lhq_4

from metric_all_nv_sup
where role_luong_mds_phanloai = 'MGRS'

),

LOGHUBCUM as 
(select*,

case 
  when ds_giao < 500000000 then ds_giao * 0.4/100
  when ds_giao >= 500000000 and ds_giao < 1000000000 then 2000000+(ds_giao - 500000000) * 0.1/100
  when ds_giao >= 1000000000 and ds_giao < 2000000000 then 2500000+(ds_giao - 1000000000) * 0.08/100
  when ds_giao >= 2000000000 then 3000000+(ds_giao - 2000000000) * 0.04/100
else 0 end as lhq_1,

-------LHQ2
    case

    when
    (ifnull(ds_thahang_c2,0)) < 1000000000
    then (ifnull(ds_thahang_c2,0)) * 0.2 / 100

    when
    (ifnull(ds_thahang_c2,0)) >= 1000000000 
    and (ifnull(ds_thahang_c2,0)) < 1500000000
    then 2000000 +  ( ((ifnull(ds_thahang_c2,0)) - 1000000000) * 0.07 / 100 )

    when
    (ifnull(ds_thahang_c2,0)) >= 1500000000 
    and (ifnull(ds_thahang_c2,0)) < 2000000000
    then 2500000 +  ( ((ifnull(ds_thahang_c2,0)) - 1500000000) * 0.05 / 100 )

    when
    (ifnull(ds_thahang_c2,0)) >= 2000000000
    then 2800000 +  ( ((ifnull(ds_thahang_c2,0)) - 2000000000) * 0.04 / 100 )
    else 0 end as lhq_2,


------LHQ3---
    --- TY LE < 97%
    CASE
    WHEN ty_le_thu_hoi_bbgh < 0.97 and sl_bb_da_thu_hoi < 50 then ty_le_thu_hoi_bbgh * 300000
    WHEN ty_le_thu_hoi_bbgh < 0.97 and sl_bb_da_thu_hoi >= 50 and ty_le_thu_hoi_bbgh < 75 then ty_le_thu_hoi_bbgh * 400000 
    WHEN ty_le_thu_hoi_bbgh < 0.97 and sl_bb_da_thu_hoi >= 75 AND ty_le_thu_hoi_bbgh < 100 then ty_le_thu_hoi_bbgh * 500000 
    WHEN ty_le_thu_hoi_bbgh < 0.97 and sl_bb_da_thu_hoi >= 100 then ty_le_thu_hoi_bbgh * 600000 
    --- TY LE 97% - 100
    WHEN ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 and sl_bb_da_thu_hoi < 50 then ty_le_thu_hoi_bbgh * 600000 
    WHEN ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 and sl_bb_da_thu_hoi >= 50 and ty_le_thu_hoi_bbgh < 75 then ty_le_thu_hoi_bbgh * 700000 
    WHEN ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 and sl_bb_da_thu_hoi >= 75 and sl_bb_da_thu_hoi < 100 then ty_le_thu_hoi_bbgh * 800000 
    WHEN ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 and sl_bb_da_thu_hoi >= 100 then ty_le_thu_hoi_bbgh * 900000 
    --- TY LE 100 TRO LEN
    WHEN ty_le_thu_hoi_bbgh >= 1.0 and sl_bb_da_thu_hoi < 50 then ty_le_thu_hoi_bbgh * 800000 
    WHEN ty_le_thu_hoi_bbgh >= 1.0 and sl_bb_da_thu_hoi >= 50 and sl_bb_da_thu_hoi < 75 then ty_le_thu_hoi_bbgh * 900000 
    WHEN ty_le_thu_hoi_bbgh >= 1.0 and sl_bb_da_thu_hoi >= 75 and sl_bb_da_thu_hoi < 100 then ty_le_thu_hoi_bbgh * 1000000 
    WHEN ty_le_thu_hoi_bbgh >= 1.0 and sl_bb_da_thu_hoi >= 100 then ty_le_thu_hoi_bbgh * 1200000 
    ELSE 0 END AS lhq_3,  

0 as lhq_4

from metric_all_nv_sup
where role_luong_mds_phanloai = 'LOGHUBCUM'


) ,

LOGHUBTONG_HY as 
(select* ,

so_chuyen_tha_hang * 250000 + so_chuyen_noi_bo * 150000 as lhq_1,  

-------LHQ2
case
  when (ds_dong_hang_total + ds_donghang_di_tha) < 2000000000 then (ds_dong_hang_total + ds_donghang_di_tha) * 0.1/100
  when (ds_dong_hang_total + ds_donghang_di_tha) >= 2000000000 and (ds_dong_hang_total + ds_donghang_di_tha) < 3000000000 
  then 2000000+((ds_dong_hang_total + ds_donghang_di_tha) - 2000000000) * 0.05/100

  when (ds_dong_hang_total + ds_donghang_di_tha) >= 3000000000 and (ds_dong_hang_total + ds_donghang_di_tha) < 4000000000 
  then 2500000+((ds_dong_hang_total + ds_donghang_di_tha) - 3000000000) * 0.05/100

  when (ds_dong_hang_total + ds_donghang_di_tha) >= 4000000000 
  then 3000000+((ds_dong_hang_total + ds_donghang_di_tha) - 4000000000) * 0.05/100
else 0 end as lhq_2,

------LHQ3---
(ds_giao * 0.2) / 100 as lhq_3,  

0 as lhq_4

from metric_all_nv_sup
where role_luong_mds_phanloai = 'LOGHUBTONG_HY'

) ,

GENERAL_HUB_LEAD as 
( select* ,


case
    when 
    ((ds_giao) + (ds_dong_hang_total) + (ds_donghang_di_tha)) <15000000000
    then ((ds_giao) + (ds_dong_hang_total) + (ds_donghang_di_tha)) * 0.1 / 100

    when 
    ((ds_giao) + (ds_dong_hang_total) + (ds_donghang_di_tha)) >= 15000000000
    and ((ds_giao) + (ds_dong_hang_total) + (ds_donghang_di_tha)) < 25000000000
    then 14000000

    when 
    ((ds_giao) + (ds_dong_hang_total) + (ds_donghang_di_tha)) >= 25000000000
    and ((ds_giao) + (ds_dong_hang_total) + (ds_donghang_di_tha)) < 35000000000
    then 16000000

    when 
    ((ds_giao) + (ds_dong_hang_total) + (ds_donghang_di_tha)) >= 35000000000
    then 16000000 + 
    ( ((ds_giao) + (ds_dong_hang_total) + (ds_donghang_di_tha)) - 35000000000 ) * 0.02 / 100
    else 0 end as lhq_1,  

--- TY LE >= 100%
    case
    when  
    ty_le_thu_hoi_bbgh >= 1.0
    and (ds_giao) < 5000000000
    then 7000000

    when  
    ty_le_thu_hoi_bbgh >= 1.0
    and  (ds_giao) >= 5000000000 
    and  (ds_giao) < 7000000000 
    then 8000000

    when  
    ty_le_thu_hoi_bbgh >= 1.0
    and  (ds_giao) >= 7000000000 
    then  9000000

    --- TY LE 97% - 100
    when  
    ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0
    and (ds_giao) < 5000000000
    then 5000000

    when  
    ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 
    and  (ds_giao) >= 5000000000 
    and  (ds_giao) < 7000000000 
    then 6000000

    when  
    ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0
    and  (ds_giao) >= 7000000000 
    then 7000000

    --- TY LE < 97%
    when  
    ty_le_thu_hoi_bbgh < 0.97
    and (ds_giao) < 5000000000
    then 4000000

    when  
    ty_le_thu_hoi_bbgh < 0.97
    and  (ds_giao) >= 5000000000 
    and  (ds_giao) < 7000000000 
    then 5000000

    when  
    ty_le_thu_hoi_bbgh < 0.97
    and  (ds_giao) >= 7000000000 
    then 6000000

    else 0 end as lhq_2,

------LHQ3---
    case
    when  
    ty_le_dat_lt = 1
    then 2000000
    when  
    ty_le_dat_lt < 1 
    and ty_le_dat_lt >= 0.95 
    then ty_le_dat_lt * 1000000
    when  
    ty_le_dat_lt < 0.95
    then 0
    else 0 end as lhq_3,

0 as lhq_4

from metric_all_nv_sup
where role_luong_mds_phanloai = 'GENERAL_HUB_LEAD'

) ,

LOGHUBTONG_CN as 
( select* ,

case
  when (ds_giao + ds_thahang_c1) < 3000000000 then (ds_giao + ds_thahang_c1) * 0.12/100
  when (ds_giao + ds_thahang_c1) >= 3000000000 and (ds_giao + ds_thahang_c1) < 4000000000 
  then 3700000+((ds_giao + ds_thahang_c1) - 3000000000) * 0.05/100
  when (ds_giao + ds_thahang_c1) >= 4000000000 and (ds_giao + ds_thahang_c1) < 5000000000 
  then 4200000+((ds_giao + ds_thahang_c1) - 4000000000) * 0.05/100
  when (ds_giao + ds_thahang_c1) >= 5000000000 then 4700000+((ds_giao + ds_thahang_c1) - 5000000000) * 0.05/100
else 0 end as lhq_1,  

-------LHQ2
case
  when ds_dong_hang_total < 1000000000 then ds_dong_hang_total * 0.17/100
  when ds_dong_hang_total >= 1000000000 and ds_dong_hang_total < 2000000000 
  then 1700000+(ds_dong_hang_total - 1000000000) * 0.05/100
  when ds_dong_hang_total > 2000000000 then 2200000+(ds_dong_hang_total - 2000000000) * 0.05/100
else 0 end as lhq_2,  


------LHQ3---BBGH < 97---------
    CASE
    WHEN ty_le_thu_hoi_bbgh < 0.97 and sl_bbgh_can_thu_hoi < 50 then ty_le_thu_hoi_bbgh * 300000
    WHEN ty_le_thu_hoi_bbgh < 0.97 and sl_bbgh_can_thu_hoi >= 50 and sl_bbgh_can_thu_hoi < 75 then ty_le_thu_hoi_bbgh * 400000 
    WHEN ty_le_thu_hoi_bbgh < 0.97 and sl_bbgh_can_thu_hoi >= 75 AND sl_bbgh_can_thu_hoi < 100 then ty_le_thu_hoi_bbgh * 500000 
    WHEN ty_le_thu_hoi_bbgh < 0.97 and sl_bbgh_can_thu_hoi >= 100 then ty_le_thu_hoi_bbgh * 600000 
    --- TY LE 97% - 100
    WHEN ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 and sl_bbgh_can_thu_hoi < 50 then ty_le_thu_hoi_bbgh * 600000 
    WHEN ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 and sl_bbgh_can_thu_hoi >= 50 and sl_bbgh_can_thu_hoi < 75 then ty_le_thu_hoi_bbgh * 700000 
    WHEN ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 and sl_bbgh_can_thu_hoi >= 75 and sl_bbgh_can_thu_hoi < 100 then ty_le_thu_hoi_bbgh * 800000 
    WHEN ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1.0 and sl_bbgh_can_thu_hoi >= 100 then ty_le_thu_hoi_bbgh * 900000 
    --- TY LE 100 TRO LEN
    WHEN ty_le_thu_hoi_bbgh >= 1.0 and sl_bbgh_can_thu_hoi < 50 then ty_le_thu_hoi_bbgh * 800000 
    WHEN ty_le_thu_hoi_bbgh >= 1.0 and sl_bbgh_can_thu_hoi >= 50 and sl_bbgh_can_thu_hoi < 75 then ty_le_thu_hoi_bbgh * 900000 
    WHEN ty_le_thu_hoi_bbgh >= 1.0 and sl_bbgh_can_thu_hoi >= 75 and sl_bbgh_can_thu_hoi < 100 then ty_le_thu_hoi_bbgh * 1000000 
    WHEN ty_le_thu_hoi_bbgh >= 1.0 and sl_bbgh_can_thu_hoi >= 100 then ty_le_thu_hoi_bbgh * 1200000 
    ELSE 0 END AS lhq_3,

--------LHQ4
(so_chuyen_noi_bo * 150000) AS lhq_4

from metric_all_nv_sup
where role_luong_mds_phanloai = 'LOGHUBTONG_CN'

) ,

TINH_LUONG_HE_QUA as 
( SELECT * FROM MDS

UNION ALL
SELECT * FROM SUP

UNION ALL
SELECT* FROM MGR

UNION ALL
SELECT* FROM MDSS

UNION ALL
SELECT* FROM MGRS

UNION ALL
SELECT* FROM LOGHUBCUM

UNION ALL
SELECT* FROM LOGHUBTONG_HY

UNION ALL
SELECT* FROM GENERAL_HUB_LEAD

UNION ALL
SELECT* FROM LOGHUBTONG_CN

)

SELECT sal.* except (lhq_1, lhq_2, lhq_3, lhq_4) ,
phaply,
loaihdld,
msnvcsmmoi,
hovatenfullname,
TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour) as inserted_at,

CASE 
  WHEN trim(loaihdld) NOT IN ('Có xác định thời hạn','Không xác định thời hạn') OR manv LIKE '%KN%' THEN 0 
  else lhq_1 end as lhq1_fix,
CASE 
  WHEN trim(loaihdld) NOT IN ('Có xác định thời hạn','Không xác định thời hạn') OR manv LIKE '%KN%' THEN 0 
  else lhq_2 end as lhq2_fix,
CASE  
  WHEN trim(loaihdld) NOT IN ('Có xác định thời hạn','Không xác định thời hạn') OR manv LIKE '%KN%' THEN 0 
  else lhq_3 end as lhq3_fix,
CASE  
  WHEN trim(loaihdld) NOT IN ('Có xác định thời hạn','Không xác định thời hạn') OR manv LIKE '%KN%' THEN 0 
  else lhq_4 end as lhq4_fix

FROM TINH_LUONG_HE_QUA         sal
LEFT JOIN `spatial-vision-343005.staging.d_hr_dsns_bytime` h ON
(CASE WHEN sal.manv LIKE '%KN%' THEN REPLACE(manv, 'KN','') ELSE sal.manv END) = h.msnvcsmmoi AND sal.thang = h.thang
AND phongdeptsummary = 'MDS' AND hovatenfullname NOT IN ('Quách Ngọc Hải','Trần Thị Mỹ Uyên','Lương Trịnh Thắng')

where msnvcsmmoi is not null 







;