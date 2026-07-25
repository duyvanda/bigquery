CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_luonghieuqua_all_2024()
BEGIN

-- TRUNCATE TABLE staging_temp.f_luonghieuqua_all_2024_temp;
-- INSERT INTO staging_temp.f_luonghieuqua_all_2024_temp (


Create or replace table staging_temp.f_luonghieuqua_all_2024_temp
partition by thang
as
(

WITH thuc_hien_kpi_vieng_tham_mt AS (

  WITH kpi_vieng_tham_mt AS (
    SELECT 
      a.manv,
      DATE(a.thang) AS thang,
      CASE
        WHEN DATE(a.thang) >= '2025-10-01' THEN count(b.custid)
        ELSE CAST(a.kpi_vieng_tham_kh_mt AS INT)
        END AS kpi_vieng_tham_kh_mt
    FROM staging.d_calendar a
    LEFT JOIN `warehouse.data_quy_dinh_vieng_tham` b ON b.slsperid = a.manv AND DATE_TRUNC(b.visitdate,MONTH) = date(a.thang)
    WHERE 
      thang >= '2024-03-01' 
      AND makenhkh = 'MT'
      AND channel = 'MT'
      --AND kpi_vieng_tham_kh_mt IS NOT NULL
    GROUP BY a.manv,a.thang,a.kpi_vieng_tham_kh_mt
    HAVING kpi_vieng_tham_kh_mt IS NOT NULL
  ),

  thuc_hien_vieng_tham_mt AS (
    SELECT 
      crtd_user,
      DATE(thang) AS thang,
      COUNT(custid) AS so_kh_vieng_tham
    FROM staging.d_master_khachhang_bytime
    WHERE 
      active = 'Active'
      AND DATE_TRUNC(crtd_datetime, MONTH) = DATE_TRUNC(thang, MONTH)
    GROUP BY 1, 2
  ),

  thuc_hien_vieng_tham_theo_checkin AS (
    SELECT 
      slsperid,
      DATE(DATE_TRUNC(visitdate, MONTH)) AS thang,
      COUNT(DISTINCT ma_kh_dat) AS so_kh_checkin,
      COUNT(DISTINCT ma_call_kh_dat) AS so_call_dat
    FROM `warehouse.f_call_result`
    WHERE 
      visitdate >= '2024-05-01' 
      AND channel = 'MT' 
      -- AND shoptype NOT LIKE '%SI%'
    GROUP BY 1, 2
  )

  SELECT 
    a.*,
    CASE
     WHEN a.thang >= '2025-10-01' THEN so_call_dat
      WHEN a.thang >= '2024-05-01' THEN c.so_kh_checkin
      WHEN a.thang < '2024-05-01' THEN b.so_kh_vieng_tham
      ELSE 0 
    END AS so_kh_vieng_tham
  FROM kpi_vieng_tham_mt a
  LEFT JOIN thuc_hien_vieng_tham_mt b 
    ON a.manv = b.crtd_user 
    AND a.thang = b.thang
  LEFT JOIN thuc_hien_vieng_tham_theo_checkin c 
    ON a.manv = c.slsperid 
    AND a.thang = c.thang
)

, kpi_si_kenh_mt AS (
  SELECT 
    manv,
    thang,
    slkh_ebysta * 1000 AS kpi_si
  FROM `staging.d_calendar`
  WHERE 
    thang >= '2024-07-01' 
    AND makenhkh = 'MT' 
    AND slkh_ebysta > 0
)
,

data_sales_nv_kpi as 
( 
SELECT
  Case when a.manv = 'KN1250' Then 'MR1250'
  else a.manv end as manv,
  DATE(a.thang) AS thang,

  CASE
      WHEN a.makenhkh IN ('INS', 'CLC', 'PCL') THEN 'HCP'
      WHEN a.makenhkh IN ('TP','GT') THEN 'TP'
      WHEN a.makenhkh = 'MT' THEN 'MT'
      ELSE NULL
  END AS makenhkh,

  SUM(doanhsochuavat) AS doanhsochuavat,
  SUM(kh_total) AS kh_total,
  ROUND(SAFE_DIVIDE(SUM(doanhsochuavat), SUM(kh_total)) * 100, 1) AS th_kpi,
  
  CASE 
      WHEN max(DATE(a.thang)) >= '2025-05-01' AND max(DATE(a.thang)) <='2025-06-30' THEN COUNT(DISTINCT th_slpp_ebysta)
      WHEN max(DATE(a.thang)) >= '2026-03-01' AND max(DATE(a.thang)) <='2026-04-30' THEN COUNT(DISTINCT th_slpp_ebysta)
      WHEN max(DATE(a.thang)) >= '2026-06-01' AND max(DATE(a.thang)) <='2026-06-30' THEN COUNT(DISTINCT th_slpp_ebysta)
      ELSE SUM(th_ds_sptt) 
  END AS th_sptt,

  SUM(kpi_ds_sptt) AS kpi_ds_sptt,

  ROUND(
    SAFE_DIVIDE
    (
    CASE 
      WHEN max(DATE(a.thang)) >= '2025-05-01' AND max(DATE(a.thang)) <='2025-06-30' THEN COUNT(DISTINCT th_slpp_ebysta)
      WHEN max(DATE(a.thang)) >= '2026-03-01' AND max(DATE(a.thang)) <='2026-04-30' THEN COUNT(DISTINCT th_slpp_ebysta)
      WHEN max(DATE(a.thang)) >= '2026-06-01' AND max(DATE(a.thang)) <='2026-06-30' THEN COUNT(DISTINCT th_slpp_ebysta)
      ELSE SUM(th_ds_sptt) 
    END
    ,
    SUM(kpi_ds_sptt)
  ) 
  * 100, 1) 
  AS th_kpi_sptt,


  COUNT(DISTINCT th_slpp_ebysta) AS th_slpp_ebysta,
  SUM(slpp_ebysta) AS slpp_ebysta,
  COUNT(DISTINCT th_slpp_medoral) AS th_slpp_medoral,
  SUM(slpp_medoral) AS slpp_medoral,
  ROUND(SAFE_DIVIDE((COUNT(DISTINCT th_slpp_medoral) + COUNT(DISTINCT th_slpp_ebysta)), (SUM(slpp_ebysta) + SUM(slpp_medoral))) * 100, 1) AS th_kpi_slpp,

  SUM(CASE WHEN a.makenhkh = 'INS' THEN doanhsochuavat END) AS ds_ins,
  SUM(CASE WHEN a.makenhkh = 'PCL' THEN doanhsochuavat END) AS ds_pcl,
  SUM(CASE WHEN a.makenhkh = 'CLC' THEN doanhsochuavat END) AS ds_clc,

  SUM(CASE WHEN a.makenhkh = 'INS' THEN kh_total END) AS kh_total_ins,
  SUM(CASE WHEN a.makenhkh = 'PCL' THEN kh_total END) AS kh_total_pcl,
  SUM(CASE WHEN a.makenhkh = 'CLC' THEN kh_total END) AS kh_total_clc,

  SUM(CASE  WHEN a.makenhkh = 'MT' AND a.thang >= '2025-10-01' THEN th_ds_fmcg_mt
            WHEN a.makenhkh = 'MT' AND a.thang >= '2023-05-01' THEN th_ds_fmcg
            ELSE 0 END) AS th_fmcg,
  SUM(CASE WHEN a.makenhkh = 'MT' THEN kpi_ds_fmcg END) AS kpi_fmcg,
  ROUND(SAFE_DIVIDE(SUM(CASE WHEN a.makenhkh = 'MT' AND a.thang >= '2025-10-01' THEN th_ds_fmcg_mt
                            WHEN a.makenhkh = 'MT' THEN th_ds_fmcg END), 
                    SUM(CASE WHEN a.makenhkh = 'MT' THEN kpi_ds_fmcg END)) * 100, 1) AS th_kpi_fmcg,
  SUM(CASE WHEN a.makenhkh = 'MT' AND makenhphu LIKE '%SI%' THEN doanhsochuavat END) AS ds_si,

  SUM(CASE WHEN a.makenhkh = 'MT' THEN th_sptt_mt ELSE 0 END) as th_sptt_mt,
  SUM(CASE WHEN a.makenhkh = 'MT' THEN kpi_ds_sptt_mt ELSE 0 END) as kpi_ds_sptt_mt,
  0 AS th_kpi_sptt_mt

  FROM `staging_temp.f_sales_crs_lhq_bytime` a

  WHERE
  a.makenhkh in ('MT','TP', 'INS', 'CLC', 'PCL','GT')
  AND a.ngaychungtu >= '2025-01-01'
  AND crs_tuyenbanhang_trongmcp NOT IN ('Rural')
  AND manv != 'CX'
  
  GROUP BY ALL

)

, data_nv_kpi as
(
  select a.*,
  e.kpi_si,
  ROUND(SAFE_DIVIDE(a.ds_si, e.kpi_si) * 100, 1) as th_kpi_si,
  d.so_kh_vieng_tham,
  d.kpi_vieng_tham_kh_mt,
  CASE WHEN a.manv = 'MR3070' AND a.thang >= '2025-11-01' and a.thang <= '2025-12-31' THEN 100
  ELSE ROUND(SAFE_DIVIDE(d.so_kh_vieng_tham, d.kpi_vieng_tham_kh_mt) * 100, 1) 
  END as th_kpi_vieng_tham_mt

  FROM data_sales_nv_kpi a
  LEFT JOIN thuc_hien_kpi_vieng_tham_mt d 
      ON a.manv = d.manv AND DATE(d.thang) = DATE(a.thang)
  LEFT JOIN kpi_si_kenh_mt e 
      ON a.manv = e.manv AND DATE(e.thang) = DATE(a.thang)
)

, data_sup_kpi as 
(
SELECT
  LEFT(u.supid,6) as supid,

  DATE(a.thang) AS thang,
  makenhkh,

  SUM(doanhsochuavat) AS doanhsochuavat,
  SUM(kh_total) AS kh_total,
  ROUND(SAFE_DIVIDE(SUM(doanhsochuavat), SUM(kh_total)) * 100, 1) AS th_kpi,

  SUM(th_sptt) AS th_sptt,
  SUM(kpi_ds_sptt) AS kpi_ds_sptt,
  ROUND(SAFE_DIVIDE(SUM(th_sptt), SUM(kpi_ds_sptt)) * 100, 1) AS th_kpi_sptt,

  SUM(th_slpp_ebysta) AS th_slpp_ebysta,
  SUM(slpp_ebysta) AS slpp_ebysta,
  SUM(th_slpp_medoral) AS th_slpp_medoral,
  SUM(slpp_medoral) AS slpp_medoral,
  ROUND(SAFE_DIVIDE( SUM(th_slpp_ebysta) + SUM(th_slpp_medoral), SUM(slpp_ebysta) + SUM(slpp_medoral) ) * 100, 1) AS th_kpi_slpp,

  SUM(ds_ins) AS ds_ins,
  SUM(ds_pcl) AS ds_pcl,
  SUM(ds_clc) AS ds_clc,
  SUM(kh_total_ins) AS kh_total_ins,
  SUM(kh_total_pcl) AS kh_total_pcl,
  SUM(kh_total_clc) AS kh_total_clc,

  SUM(th_fmcg) AS th_fmcg,
  SUM(kpi_fmcg) AS kpi_fmcg,
  ROUND(SAFE_DIVIDE( SUM(th_fmcg), SUM(kpi_fmcg) ) * 100, 1) AS th_kpi_fmcg,
  SUM(ds_si) AS ds_si,
  SUM(th_sptt_mt) as th_sptt_mt,
  SUM(kpi_ds_sptt_mt) as kpi_ds_sptt_mt,
  ROUND(SAFE_DIVIDE(SUM(th_sptt_mt), SUM(kpi_ds_sptt_mt)) * 100, 1) AS th_kpi_sptt_mt,
  SUM(kpi_si) as kpi_si,
  ROUND(SAFE_DIVIDE(SUM(ds_si), SUM(kpi_si)) * 100, 1) as th_kpi_si,
  SUM(so_kh_vieng_tham) as so_kh_vieng_tham,
  SUM(kpi_vieng_tham_kh_mt) as kpi_vieng_tham_kh_mt,
  ROUND(SAFE_DIVIDE(SUM(so_kh_vieng_tham), SUM(kpi_vieng_tham_kh_mt)) * 100, 1) as th_kpi_vieng_tham_mt,
  

FROM data_nv_kpi a
LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` u ON u.manv = a.manv AND date(u.thang) = a.thang

group by all

)
--MR TOÀN ONLY
, data_asm_kpi as 
(
SELECT
  b.asm,
  -- b.tenquanlykhuvuc,
  DATE(a.thang) AS thang,
  makenhkh,
  SUM(doanhsochuavat) AS doanhsochuavat,
  SUM(kh_total) AS kh_total,
  ROUND(SAFE_DIVIDE(SUM(doanhsochuavat), SUM(kh_total)) * 100, 1) AS th_kpi,
  --th_ds_sptt
  0 th_sptt,
  0 AS kpi_ds_sptt,
  0 AS th_kpi_sptt,
  0 AS th_slpp_ebysta,
  0 AS slpp_ebysta,
  0 AS th_slpp_medoral,
  0 AS slpp_medoral,
  0 AS th_kpi_slpp,
  sum(ds_ins) as ds_ins,
  sum(ds_pcl) as ds_pcl,
  sum(ds_clc) as ds_clc,

  sum(kh_total_ins) as kh_total_ins,
  sum(kh_total_pcl) as kh_total_pcl,
  sum(kh_total_clc) as kh_total_clc,

  0 AS th_fmcg,
  0 AS kpi_fmcg,
  0 AS th_kpi_fmcg,
  0 AS ds_si,
   0 as th_sptt_mt,
  0 as kpi_ds_sptt_mt,
  0 AS th_kpi_sptt_mt,
  0 AS kpi_si,
  0 AS th_kpi_si,
  0 AS so_kh_vieng_tham,
  0 AS kpi_vieng_tham_kh_mt,
  0 AS th_kpi_vieng_tham_mt,
 

FROM data_sup_kpi a 
LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` b ON b.manv = a.supid AND date(b.thang) = a.thang
where a.makenhkh in ('HCP')
group by all

)

, th_kh_ins_pcl_toan_quoc as
(
  select
  thang,
  sum(ds_ins) as ds_ins_toanquoc,
  sum(kh_total_ins) as kh_total_ins_toanquoc,
  round(safe_divide (sum(ds_ins),sum(kh_total_ins))*100,1) as th_dskh_ins_toanquoc,
  
  sum(ds_pcl) as ds_pcl_toanquoc,
  sum(kh_total_pcl) as kh_total_pcl_toanquoc,
  round(safe_divide (sum(ds_pcl),sum(kh_total_pcl))*100,1) as th_dskh_pcl_toanquoc,
  FROM data_nv_kpi
  group by all
)

, kpi_ds_mt_mix as (
  SELECT
  nv.manv,
  nv.thang,
  (IFNULL(sup.doanhsochuavat, 0) - IFNULL(sup.ds_si, 0)) AS sup_actual_non_si,
  (IFNULL(sup.kh_total, 0) - IFNULL(sup.kpi_si, 0)) AS sup_target_non_si,
  IFNULL(nv.ds_si, 0) AS nv_actual_si,
  IFNULL(nv.kpi_si, 0) AS nv_target_si,
  (IFNULL(sup.doanhsochuavat, 0) - IFNULL(sup.ds_si, 0) + IFNULL(nv.ds_si, 0)) as th_ds_mt,
  (IFNULL(sup.kh_total, 0) - IFNULL(sup.kpi_si, 0) + IFNULL(nv.kpi_si, 0)) as kh_total_mt,
  ROUND(
      SAFE_DIVIDE(
        (IFNULL(sup.doanhsochuavat, 0) - IFNULL(sup.ds_si, 0)) + IFNULL(nv.ds_si, 0),
        (IFNULL(sup.kh_total, 0) - IFNULL(sup.kpi_si, 0)) + IFNULL(nv.kpi_si, 0)
      ) * 100, 1
    ) AS th_kpi_ds_mt,

  sup.th_sptt_mt AS th_sptt_mt,
  sup.kpi_ds_sptt_mt AS kpi_ds_sptt_mt,
  sup.th_kpi_sptt_mt,

  IFNULL(sup.th_fmcg,0) as th_fmcg,
  IFNULL(sup.kpi_fmcg,0) as kpi_fmcg,
  IFNULL(sup.th_kpi_fmcg,0) as th_kpi_fmcg

  FROM data_nv_kpi nv
  LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` u 
    ON nv.manv = u.manv AND nv.thang = DATE(u.thang)
  LEFT JOIN data_sup_kpi sup 
    ON u.supid = sup.supid AND nv.thang = sup.thang
  
)


, _combined as
(
select *, 'nv' as dtype from data_nv_kpi
UNION ALL
select *, 'crm' as dtype from data_sup_kpi
UNION ALL
select *, 'asm' as dtype from data_asm_kpi
)

, combined as
(
select a.*,
hr.chucdanhengtitlesum
from _combined a
LEFT JOIN `staging.d_hr_dsns_bytime` hr on a.manv = hr.msnvcsmmoi and date(hr.thang) = date(a.thang)

)

, agg_kpi_support_cre as
(
  SELECT
    DATE(b.thang) as thang,
    a.ma_cre,
    a.ho_ten_cre as ho_ten_cre,
    b.makenhkh as makenhkh,
    
    -- Tiêu chí A: Tính tổng Doanh số của TẤT CẢ CRS mà CRE hỗ trợ
    SUM(b.doanhsochuavat) as total_ds_thuc_hien,
    SUM(b.kh_total) as total_ds_ke_hoach,
    
    -- Tiêu chí phụ: Tính tổng SPTT (Cho kênh TP)
    SUM(b.th_sptt) as total_th_sptt,
    SUM(b.kpi_ds_sptt) as total_kpi_ds_sptt,
    
    -- Tiêu chí PC: Tính tổng Doanh số PCL & CLC (Cho kênh HCP)
    SUM(IFNULL(b.ds_pcl,0) + IFNULL(b.ds_clc,0)) as total_ds_pc,
    SUM(IFNULL(b.kh_total_pcl,0) + IFNULL(b.kh_total_clc,0)) as total_kh_pc

  FROM `spatial-vision-343005.staging.d_calendar_cre` a
  LEFT JOIN combined b ON b.manv = a.ma_crs and DATE(b.thang) = DATE(a.thang)
  WHERE b.thang >= '2025-09-01'
  GROUP BY 1, 2, 3, 4
)

, th_kpi_support_cre as
(
  SELECT
    thang,
    ma_cre,
    ho_ten_cre,
    
    CASE
      -- Kênh TP: 80% A + 20% SPTT
      WHEN makenhkh = 'TP' THEN 
        (IFNULL(SAFE_DIVIDE(total_ds_thuc_hien, total_ds_ke_hoach), 0) * 100 * 0.8) + 
        (IFNULL(SAFE_DIVIDE(total_th_sptt, total_kpi_ds_sptt), 0) * 100 * 0.2)
        
      -- Kênh HCP: 80% A + 20% PC (PCL & CLC)
      WHEN makenhkh = 'HCP' THEN 
        (IFNULL(SAFE_DIVIDE(total_ds_thuc_hien, total_ds_ke_hoach), 0) * 100 * 0.8) + 
        (IFNULL(SAFE_DIVIDE(total_ds_pc, total_kh_pc), 0) * 100 * 0.2)
        
      ELSE null 
    END as th_kpi_support

  FROM agg_kpi_support_cre
)

--select * from th_kpi_support_cre where thang = '2026-04-01' AND ma_cre = 'MR1674'

---------------------------------------LHQ----------------------------------------

, TP_NV as
(
  select a.*,
  case
  when doanhsochuavat >= 500000000 and makenhkh='TP'  then doanhsochuavat * 1.5 / 100
  when doanhsochuavat >= 450000000 and makenhkh='TP'  then 6000000 
  when doanhsochuavat >= 400000000 and makenhkh='TP'  then 5000000
  when doanhsochuavat >= 350000000 and makenhkh='TP'  then 4000000
  when doanhsochuavat < 350000000 and makenhkh='TP'  then doanhsochuavat * 1 / 100
  else null end as lhq1,

  Case ----Lương hiệu quả 2 kênh TP - Phụ cấp kết quả công việc (LHQ2): Căn cứ vào A

     when th_kpi < 80 and makenhkh='TP'  then 0
     when th_kpi >= 80 and th_kpi < 90 and makenhkh='TP'  then th_kpi * 2500000 / 100
     when th_kpi >= 90 and th_kpi < 100 and makenhkh='TP'  then th_kpi * 3500000 / 100
     when th_kpi >= 100 and th_kpi < 110 and makenhkh='TP'  then th_kpi * 4000000 / 100
     when th_kpi >= 110 and th_kpi < 120 and makenhkh='TP'  then th_kpi * 4500000 / 100
     when th_kpi >= 120  and makenhkh='TP'  then th_kpi * 5000000 / 100
  else null end as lhq2,

  Case 
----Lương hiệu quả 3 kênh TP -	Phụ cấp kết quả công việc (LHQ3): Căn cứ vào N
  when th_kpi_sptt < 80  and a.thang >= '2024-11-01' then 0
  when th_kpi_sptt >= 80 and th_kpi_sptt < 90 and a.thang >= '2024-11-01'  then 500000
  when th_kpi_sptt >= 90 and th_kpi_sptt < 100  and a.thang >= '2024-11-01' then 1000000
  when th_kpi_sptt >= 100 and th_kpi_sptt < 110 and a.thang >= '2024-11-01'  then 2000000
  when th_kpi_sptt >= 110 and th_kpi_sptt < 120 and a.thang >= '2024-11-01'  then 2500000
  when th_kpi_sptt >= 120   and a.thang >= '2024-11-01' then 3000000
  --old
  -- when th_kpi_slpp < 80 and a.thang <'2024-11-01' then 0
  -- when th_kpi_slpp >= 80 and th_kpi_slpp < 90 and a.thang <'2024-11-01' then 500000
  -- when th_kpi_slpp >= 90 and th_kpi_slpp < 100 and a.thang <'2024-11-01' then 1000000
  -- when th_kpi_slpp >= 100 and th_kpi_slpp < 110 and a.thang <'2024-11-01' then 2000000
  -- when th_kpi_slpp >= 110 and th_kpi_slpp < 120 and a.thang <'2024-11-01' then 2500000
  -- when th_kpi_slpp >= 120  and a.thang <'2024-11-01' then 3000000
  else null 
  end as lhq3,
  Case
  When th_kpi_support < 70 then 0
  When b.th_kpi_support >= 70 then th_kpi_support * 4000000 / 100
  else null end as lhq4
  
  from combined a
  LEFT JOIN th_kpi_support_cre b on b.ma_cre = a.manv and b.thang = a.thang
  WHERE makenhkh = 'TP' and dtype = 'nv'
)

--select * FROm TP_NV where manv = 'MR4089' and thang = '2026-01-01'
, TP_CRM as
(
  select a.*,
  
  case
  when doanhsochuavat >= 4500000000  then doanhsochuavat * 0.45 / 100
  when doanhsochuavat >= 4000000000  then 17000000
  when doanhsochuavat >= 3500000000  then 15000000
  when doanhsochuavat >= 3000000000  then 13000000
  when doanhsochuavat >= 2500000000  then 11000000
  when doanhsochuavat < 2500000000  then doanhsochuavat * 0.4 / 100
  else null end as lhq1,

  Case ----Lương hiệu quả 2 kênh TP - Phụ cấp kết quả công việc (LHQ2): Căn cứ vào A
     when th_kpi < 80  then th_kpi * 5000000 / 100
     when th_kpi >= 80 and th_kpi < 90  then th_kpi * 10000000 / 100
     when th_kpi >= 90 and th_kpi < 100  then th_kpi * 11000000 / 100
     when th_kpi >= 100 and th_kpi < 110  then th_kpi * 12000000 / 100
     when th_kpi >= 110 and th_kpi < 120  then th_kpi * 12500000 / 100
     when th_kpi >= 120   then th_kpi * 13000000 / 100
  else null end as lhq2,

  Case 
----Lương hiệu quả 3 kênh TP -	Phụ cấp kết quả công việc (LHQ3): Căn cứ vào N
    when th_kpi_sptt < 80 and a.thang >= '2024-11-01'  then 0
    when th_kpi_sptt >= 80 and th_kpi_sptt < 90  and a.thang >= '2024-11-01' then 3000000
    when th_kpi_sptt >= 90 and th_kpi_sptt < 100  and a.thang >= '2024-11-01' then 4000000
    when th_kpi_sptt >= 100 and th_kpi_sptt < 110  and a.thang >= '2024-11-01' then 6000000
    when th_kpi_sptt >= 110 and th_kpi_sptt < 120  and a.thang >= '2024-11-01' then 7000000
    when th_kpi_sptt >= 120   and a.thang >= '2024-11-01' then 8000000

  else null
  end as lhq3,
  0 as lhq4
  
  from combined a
  WHERE makenhkh = 'TP' and dtype = 'crm'
)



, HCP_NV as
(
  select a.*,
  
  case
  when doanhsochuavat >= 550000000  then doanhsochuavat * 1.5 / 100
  when doanhsochuavat >= 500000000  then 7000000 
  when doanhsochuavat >= 450000000  then 6000000
  when doanhsochuavat >= 400000000  then 5000000
  when doanhsochuavat >= 350000000  then 4000000 
  when doanhsochuavat <  350000000  then doanhsochuavat * 1.0 / 100
  else null
  end as lhq1,

  case
  when th_kpi < 80  then 0
  when th_kpi >= 80 and th_kpi < 90  then th_kpi * 2500000 / 100
  when th_kpi >= 90 and th_kpi < 100  then th_kpi * 3500000 /100
  when th_kpi >= 100 and th_kpi < 110  then th_kpi * 4000000 /100
  when th_kpi >= 110 and th_kpi < 120  then th_kpi * 4500000 /100
  when th_kpi >= 120   then th_kpi *  5000000 / 100
  else null
  end as lhq2,

  ROUND(
      (
      IFNULL(ds_pcl, 0) * 2 +
      IFNULL(ds_clc, 0) * 5.4 +
      IFNULL(ds_ins, 0) * 3.4

      ) / 100, 1
  ) as lhq3,

  Case
  When b.th_kpi_support < 70  then 0
  When b.th_kpi_support >= 70  then th_kpi_support * 4000000 / 100
  else null end as lhq4 

  FROM combined a
  LEFT JOIN th_kpi_support_cre b on b.ma_cre = a.manv and b.thang = a.thang
  WHERE makenhkh = 'HCP' and dtype = 'nv'
)

, HCP_CRM as
-- khong co Vu, Mung, Toan
(
  select a.*,
  
  case
    when doanhsochuavat >= 4500000000  then  doanhsochuavat * 0.4 / 100
    when doanhsochuavat >= 4000000000  then 16000000
    when doanhsochuavat >= 3500000000  then 14000000
    when doanhsochuavat >= 3000000000  then 12000000
    when doanhsochuavat >= 2500000000  then 10000000
    /* từ ngày 1.1.2026 mức thưởng là doanhsochuavat*0.4% */
    when doanhsochuavat < 2500000000  
    then (case when a.thang >= '2026-01-01' then doanhsochuavat * 0.4 / 100 else doanhsochuavat * 0.35 / 100 end) --doanhsochuavat * 0.35 / 100
  else null end as lhq1,

  Case
     when th_kpi < 80  then th_kpi * 5000000 /100
     when th_kpi >= 80 and th_kpi < 90   then th_kpi * 10000000 /100
     when th_kpi >= 90 and th_kpi < 100  then th_kpi * 11000000 /100
     when th_kpi >= 100 and th_kpi < 110 then th_kpi * 12000000 /100
     when th_kpi >= 110 and th_kpi < 120 then th_kpi * 12500000 /100
     when th_kpi >= 120   then th_kpi * 13000000 /100
  else null end as lhq2,

  ROUND(
    (
        IFNULL(a.ds_ins, 0) * 4 + 
        IFNULL(a.ds_pcl, 0) * 1.2 + 
        IFNULL(a.ds_clc, 0) * 5
    ) / 100, 1
) AS lhq3,
  0 as lhq4
  from combined a
  WHERE makenhkh = 'HCP' and dtype = 'crm' and UPPER(TRIM(chucdanhengtitlesum)) in ('CRM','A-CRM','S.CRM','S-CRM') --manv not in ('MR1137','MR0123','MR1681')
)


, HCP_NCRM as 
(
  SELECT 
    a.asm as manv, -- Alias để khớp với cấu trúc bảng
    a.* EXCEPT(asm), -- Lấy các trường dữ liệu
    
    'asm' as dtype, -- Thêm cột dtype để khớp UNION
    CAST(NULL AS STRING) as chucdanhengtitlesum, -- Placeholder để khớp cấu trúc UNION, dữ liệu sẽ được lấy lại ở bước fix_lhq

    -- LHQ1: A (th_kpi) * K
    CASE 
      -- Zone 1: MR0123 -> K7 (40tr)
      WHEN a.asm = 'MR0123' THEN a.th_kpi * 40000000 / 100 
      -- Zone 2: MR1650 -> K4 (25tr)
      WHEN a.asm = 'MR1650' THEN a.th_kpi * 25000000 / 100 
      -- Zone 3: MR0538 -> K2 (15tr)
      WHEN a.asm = 'MR0538' THEN a.th_kpi * 15000000 / 100 
      ELSE 0 
    END AS lhq1,

    /* update: từ tháng 5/2026 trở đi thêm mã MR0123 sẽ được thưởng  LHQ2*/
    -- LHQ2: ds_clc*4% + ds_ins*4% only for MR0538, ds_clc và ds_ins lấy từ bảng data_sup_kpi lấy từ khu vực quản lý trực tiếp
    CASE 
      WHEN a.asm = 'MR0538' THEN (IFNULL(sup.ds_clc, 0) * 0.04 + IFNULL(sup.ds_ins, 0) * 0.04)
      WHEN a.asm = 'MR0123' AND a.thang >= '2026-05-01' THEN (IFNULL(sup.ds_clc, 0) * 0.04 + IFNULL(sup.ds_ins, 0) * 0.04)
      ELSE 0 
    END AS lhq2,

    0 AS lhq3,
    0 AS lhq4

  FROM data_asm_kpi a -- Lấy trực tiếp từ bảng data_asm_kpi
  LEFT JOIN data_sup_kpi sup 
    ON sup.supid = a.asm 
    AND sup.thang = a.thang
    AND sup.makenhkh = 'HCP'
  WHERE a.thang >= '2026-01-01'
  
)
, MT_NV as
(
  select a.*,
  CASE
  WHEN a.thang >= '2025-10-01' THEN
      (
      case
      when mt.th_kpi_ds_mt <80 and a.th_kpi_vieng_tham_mt < 90 then mt.th_kpi_ds_mt * 2000000 / 100 
      when mt.th_kpi_ds_mt >= 80 and mt.th_kpi_ds_mt <90 and a.th_kpi_vieng_tham_mt < 90 then mt.th_kpi_ds_mt * 4000000 / 100
      when mt.th_kpi_ds_mt >= 90 and mt.th_kpi_ds_mt <100 and a.th_kpi_vieng_tham_mt < 90 then mt.th_kpi_ds_mt * 5000000 / 100
      when mt.th_kpi_ds_mt >= 100 and mt.th_kpi_ds_mt <110 and a.th_kpi_vieng_tham_mt < 90 then mt.th_kpi_ds_mt * 6500000 / 100
      when mt.th_kpi_ds_mt >= 110 and mt.th_kpi_ds_mt <120 and a.th_kpi_vieng_tham_mt < 90 then mt.th_kpi_ds_mt * 7000000 / 100
      when mt.th_kpi_ds_mt >= 120 and a.th_kpi_vieng_tham_mt < 90 then mt.th_kpi_ds_mt * 7500000 / 100

      when mt.th_kpi_ds_mt <80 and a.th_kpi_vieng_tham_mt >= 90 then mt.th_kpi_ds_mt * 3000000 / 100 
      when mt.th_kpi_ds_mt >= 80 and mt.th_kpi_ds_mt <90 and a.th_kpi_vieng_tham_mt >= 90 then mt.th_kpi_ds_mt * 5000000 / 100
      when mt.th_kpi_ds_mt >= 90 and mt.th_kpi_ds_mt <100 and a.th_kpi_vieng_tham_mt >= 90 then mt.th_kpi_ds_mt * 6000000 / 100
      when mt.th_kpi_ds_mt >= 100 and mt.th_kpi_ds_mt <110 and a.th_kpi_vieng_tham_mt >= 90 then mt.th_kpi_ds_mt * 7500000 / 100
      when mt.th_kpi_ds_mt >= 110 and mt.th_kpi_ds_mt <120 and a.th_kpi_vieng_tham_mt >= 90 then mt.th_kpi_ds_mt * 8000000 / 100
      when mt.th_kpi_ds_mt >= 120 and a.th_kpi_vieng_tham_mt >= 90 then mt.th_kpi_ds_mt * 8500000 / 100
      else null end
      )

  WHEN a.thang <= '2025-09-30' THEN
    (
    case
    when th_kpi <80 and a.th_kpi_vieng_tham_mt < 95 then th_kpi * 2000000 / 100 
    when th_kpi >= 80 and th_kpi < 90  and a.th_kpi_vieng_tham_mt < 95 then th_kpi * 4000000 / 100 
    when th_kpi >= 90 and th_kpi < 100  and a.th_kpi_vieng_tham_mt < 95 then th_kpi * 5000000 / 100 
    when th_kpi >= 100 and th_kpi < 110  and a.th_kpi_vieng_tham_mt < 95 then th_kpi * 6500000 / 100 
    when th_kpi >= 110 and th_kpi < 120  and a.th_kpi_vieng_tham_mt < 95 then th_kpi * 7000000 / 100 
    when th_kpi >= 120 and a.th_kpi_vieng_tham_mt < 95 then LEAST(th_kpi,150) * 7500000 / 100 

    when th_kpi <80 and a.th_kpi_vieng_tham_mt >= 95 then th_kpi * 3000000 / 100 
    when th_kpi >= 80 and th_kpi < 90  and a.th_kpi_vieng_tham_mt >= 95 then th_kpi * 5000000 / 100 
    when th_kpi >= 90 and th_kpi < 100  and a.th_kpi_vieng_tham_mt >= 95 then th_kpi * 6000000 / 100 
    when th_kpi >= 100 and th_kpi < 110  and a.th_kpi_vieng_tham_mt >= 95 then th_kpi * 7500000 / 100 
    when th_kpi >= 110 and th_kpi < 120  and a.th_kpi_vieng_tham_mt >= 95 then th_kpi * 8000000 / 100 
    when th_kpi >= 120 and a.th_kpi_vieng_tham_mt >= 95 then LEAST(th_kpi,150) * 8500000 / 100
    else null end
  )
  else null
  end as lhq1,
  
  CASE
    WHEN mt.th_kpi_sptt_mt >= 120 THEN 3000000
    WHEN mt.th_kpi_sptt_mt >= 110 THEN 2500000
    WHEN mt.th_kpi_sptt_mt >= 100 THEN 2000000
    WHEN mt.th_kpi_sptt_mt >= 90 THEN 1000000
    WHEN mt.th_kpi_sptt_mt >= 80 THEN 500000
    ELSE 0
  END AS lhq2,

  CASE
      WHEN UPPER(TRIM(chucdanhengtitlesum)) = 'KAS (SI)' THEN
          CASE
              WHEN th_kpi_si >= 120 AND a.thang >= '2025-10-01' THEN 3000000
              WHEN th_kpi_si >= 110 AND a.thang >= '2025-10-01' THEN 2500000
              WHEN th_kpi_si >= 100 AND a.thang >= '2025-10-01' THEN 2000000
              WHEN th_kpi_si >= 90 AND a.thang >= '2025-10-01' THEN 1000000
              WHEN th_kpi_si >= 80 AND a.thang >= '2025-10-01' THEN 500000
              

              WHEN th_kpi_si >= 120 AND a.thang <= '2025-09-30' THEN 4000000
              WHEN th_kpi_si >= 110 AND a.thang <= '2025-09-30' THEN 3500000
              WHEN th_kpi_si >= 100 AND a.thang <= '2025-09-30' THEN 3000000
              WHEN th_kpi_si >= 90 AND a.thang <= '2025-09-30' THEN 2000000
              WHEN th_kpi_si >= 80 AND a.thang <= '2025-09-30' THEN 1000000
              ELSE 0
          END
      WHEN UPPER(TRIM(chucdanhengtitlesum)) = 'KAS (FMCG)' THEN
          CASE
              WHEN mt.th_kpi_fmcg >= 120 AND a.thang >= '2025-10-01' THEN 3000000
              WHEN mt.th_kpi_fmcg >= 110 AND a.thang >= '2025-10-01' THEN 2500000
              WHEN mt.th_kpi_fmcg >= 100 AND a.thang >= '2025-10-01' THEN 2000000
              WHEN mt.th_kpi_fmcg >= 90 AND a.thang >= '2025-10-01' THEN 1000000
              WHEN mt.th_kpi_fmcg >= 80 AND a.thang >= '2025-10-01' THEN 500000
              
            
              WHEN mt.th_kpi_fmcg >= 120 AND a.thang <= '2025-09-30' THEN 6000000
              WHEN mt.th_kpi_fmcg >= 110 AND a.thang <= '2025-09-30' THEN 5000000
              WHEN mt.th_kpi_fmcg >= 100 AND a.thang <= '2025-09-30' THEN 4000000
              WHEN mt.th_kpi_fmcg >= 90 AND a.thang <= '2025-09-30' THEN 2000000
              WHEN mt.th_kpi_fmcg >= 80 AND a.thang <= '2025-09-30' THEN 1000000
              ELSE 0
          END
      ELSE NULL
  END AS lhq3,

  0 as lhq4,

  FROM combined a
  LEFT JOIN kpi_ds_mt_mix mt 
    ON a.manv = mt.manv AND a.thang = mt.thang
  WHERE makenhkh = 'MT' and dtype = 'nv'
  and upper(trim(chucdanhengtitlesum)) not like '%SUP%'
)



, MT_NV_SUP as
(
  select a.*,
  case 
  when a.thang >= '2025-10-01' then
    (case
    when mt.th_kpi_ds_mt <80 and a.th_kpi_vieng_tham_mt < 90 then mt.th_kpi_ds_mt * 6000000 / 100 
    when mt.th_kpi_ds_mt >= 80 and mt.th_kpi_ds_mt < 90  and a.th_kpi_vieng_tham_mt < 90 then mt.th_kpi_ds_mt * 9000000 / 100 
    when mt.th_kpi_ds_mt >= 90 and mt.th_kpi_ds_mt < 100  and a.th_kpi_vieng_tham_mt < 90 then mt.th_kpi_ds_mt * 10000000 / 100 
    when mt.th_kpi_ds_mt >= 100 and mt.th_kpi_ds_mt < 110  and a.th_kpi_vieng_tham_mt < 90 then mt.th_kpi_ds_mt * 11000000 / 100 
    when mt.th_kpi_ds_mt >= 110 and mt.th_kpi_ds_mt < 120  and a.th_kpi_vieng_tham_mt < 90 then mt.th_kpi_ds_mt * 11500000 / 100 
    when mt.th_kpi_ds_mt >= 120 and a.th_kpi_vieng_tham_mt < 90 then mt.th_kpi_ds_mt * 12000000 / 100

    when mt.th_kpi_ds_mt <80 and a.th_kpi_vieng_tham_mt >= 90 then mt.th_kpi_ds_mt * 9000000 / 100 
    when mt.th_kpi_ds_mt >= 80 and mt.th_kpi_ds_mt < 90  and a.th_kpi_vieng_tham_mt >= 90 then mt.th_kpi_ds_mt * 12000000 / 100 
    when mt.th_kpi_ds_mt >= 90 and mt.th_kpi_ds_mt < 100  and a.th_kpi_vieng_tham_mt >= 90 then mt.th_kpi_ds_mt * 13000000 / 100 
    when mt.th_kpi_ds_mt >= 100 and mt.th_kpi_ds_mt < 110  and a.th_kpi_vieng_tham_mt >= 90 then mt.th_kpi_ds_mt * 14000000 / 100 
    when mt.th_kpi_ds_mt >= 110 and mt.th_kpi_ds_mt < 120  and a.th_kpi_vieng_tham_mt >= 90 then mt.th_kpi_ds_mt * 14500000 / 100 
    when mt.th_kpi_ds_mt >= 120 and a.th_kpi_vieng_tham_mt >= 90 then mt.th_kpi_ds_mt * 15000000 / 100

  else null end
    )

  when a.thang <= '2025-09-30' then
  (case
    when th_kpi <80 and a.th_kpi_vieng_tham_mt < 95 then th_kpi * 6000000 / 100 
    when th_kpi >= 80 and th_kpi < 90  and a.th_kpi_vieng_tham_mt < 95 then th_kpi * 9000000 / 100 
    when th_kpi >= 90 and th_kpi < 100  and a.th_kpi_vieng_tham_mt < 95 then th_kpi * 10000000 / 100 
    when th_kpi >= 100 and th_kpi < 110  and a.th_kpi_vieng_tham_mt < 95 then th_kpi * 11000000 / 100 
    when th_kpi >= 110 and th_kpi < 120  and a.th_kpi_vieng_tham_mt < 95 then th_kpi * 11500000 / 100 
    when th_kpi >= 120 and a.th_kpi_vieng_tham_mt < 95 then LEAST(th_kpi,150) * 12000000 / 100

    when th_kpi <80 and a.th_kpi_vieng_tham_mt >= 95 then th_kpi * 9000000 / 100 
    when th_kpi >= 80 and th_kpi < 90  and a.th_kpi_vieng_tham_mt >= 95 then th_kpi * 12000000 / 100 
    when th_kpi >= 90 and th_kpi < 100  and a.th_kpi_vieng_tham_mt >= 95 then th_kpi * 13000000 / 100 
    when th_kpi >= 100 and th_kpi < 110  and a.th_kpi_vieng_tham_mt >= 95 then th_kpi * 14000000 / 100 
    when th_kpi >= 110 and th_kpi < 120  and a.th_kpi_vieng_tham_mt >= 95 then th_kpi * 14500000 / 100 
    when th_kpi >= 120 and a.th_kpi_vieng_tham_mt >= 95 then LEAST(th_kpi,150) * 15000000 / 100

  else null end)

  else null end as lhq1,
  
  CASE
    WHEN mt.th_kpi_sptt_mt >= 120 THEN 3000000
    WHEN mt.th_kpi_sptt_mt >= 110 THEN 2500000
    WHEN mt.th_kpi_sptt_mt >= 100 THEN 2000000
    WHEN mt.th_kpi_sptt_mt >= 90 THEN 1000000
    WHEN mt.th_kpi_sptt_mt >= 80 THEN 500000
    ELSE 0
  END AS lhq2,
  
  CASE
  WHEN UPPER(TRIM(chucdanhengtitlesum)) in ('KA-SUP (SI)') THEN 
  (   CASE
      WHEN th_kpi_si >= 120 AND a.thang >= '2025-10-01' THEN 3000000
      WHEN th_kpi_si >= 110 AND a.thang >= '2025-10-01' THEN 2500000
      WHEN th_kpi_si >= 100 AND a.thang >= '2025-10-01' THEN 2000000
      WHEN th_kpi_si >= 90 AND a.thang >= '2025-10-01' THEN 1000000
      WHEN th_kpi_si >= 80 AND a.thang >= '2025-10-01' THEN 500000
      ELSE NULL END
      )

  WHEN UPPER(TRIM(chucdanhengtitlesum)) = 'KA-SUP (FMCG)' THEN  -- Chưa có sup của SI
  (   CASE
      WHEN mt.th_kpi_fmcg < 80 AND a.thang >= '2025-10-01' THEN 0
      WHEN mt.th_kpi_fmcg >= 80 AND mt.th_kpi_fmcg < 90 AND a.thang >= '2025-10-01' THEN 500000
      WHEN mt.th_kpi_fmcg >= 90 AND mt.th_kpi_fmcg < 100 AND a.thang >= '2025-10-01' THEN 1000000
      WHEN mt.th_kpi_fmcg >= 100 AND mt.th_kpi_fmcg < 110 AND a.thang >= '2025-10-01' THEN 2000000
      WHEN mt.th_kpi_fmcg >= 110 AND mt.th_kpi_fmcg < 120 AND a.thang >= '2025-10-01' THEN 2500000
      WHEN mt.th_kpi_fmcg >= 120 THEN 3000000
      
      WHEN mt.th_kpi_fmcg < 80 AND a.thang <= '2025-09-30' THEN 0
      WHEN mt.th_kpi_fmcg >= 80 AND mt.th_kpi_fmcg < 90 AND a.thang <= '2025-09-30' THEN 1000000
      WHEN mt.th_kpi_fmcg >= 90 AND mt.th_kpi_fmcg < 100 AND a.thang <= '2025-09-30' THEN 2000000
      WHEN mt.th_kpi_fmcg >= 100 AND mt.th_kpi_fmcg < 110 AND a.thang <= '2025-09-30' THEN 4000000
      WHEN mt.th_kpi_fmcg >= 110 AND mt.th_kpi_fmcg < 120 AND a.thang <= '2025-09-30' THEN 5000000
      WHEN mt.th_kpi_fmcg >= 120 THEN 6000000
      ELSE NULL END
  )   
  
  ELSE NULL 
  END AS lhq3,

  --0 as lhq3,
  0 as lhq4,

  FROM combined a
  --LEFT JOIN th_kh_fmcg_toan_quoc tq on a.thang = tq.thang
  LEFT JOIN kpi_ds_mt_mix mt 
    ON a.manv = mt.manv AND a.thang = mt.thang
  WHERE makenhkh = 'MT' and dtype = 'nv' and upper(trim(chucdanhengtitlesum)) like '%SUP%'
)
, MT_KAM as
(
  select a.*,
  
  ---LHQ1 cho kênh MT - KAM căn cứ vào T và có phụ trách kênh FMCG
  case
    when doanhsochuavat >= 6000000000 and a.chucdanhengtitlesum in ('KAM (FMCG)')  then doanhsochuavat * 0.22 /100 
    when doanhsochuavat >= 5500000000 and a.chucdanhengtitlesum in ('KAM (FMCG)') then 11500000
    when doanhsochuavat >= 5000000000 and a.chucdanhengtitlesum in ('KAM (FMCG)') then 10000000 
    when doanhsochuavat >= 4500000000 and a.chucdanhengtitlesum in ('KAM (FMCG)') then 8500000
    when doanhsochuavat >= 4000000000 and a.chucdanhengtitlesum in ('KAM (FMCG)') then 7000000
    when doanhsochuavat < 4000000000 and a.chucdanhengtitlesum in ('KAM (FMCG)') then doanhsochuavat * 0.17 /100

  ---LHQ1 cho kênh MT - KAM căn cứ vào T và k có phụ trách kênh FMCG
    when doanhsochuavat >= 8000000000 and  a.chucdanhengtitlesum not in ('KAM (FMCG)')  then doanhsochuavat * 0.25 /100
    when doanhsochuavat >= 7500000000 and  a.chucdanhengtitlesum not in ('KAM (FMCG)')  then 19000000
    when doanhsochuavat >= 7000000000 and  a.chucdanhengtitlesum not in ('KAM (FMCG)')  then 17000000 
    when doanhsochuavat >= 6500000000 and  a.chucdanhengtitlesum not in ('KAM (FMCG)')  then 15000000
    when doanhsochuavat >= 6000000000 and  a.chucdanhengtitlesum not in ('KAM (FMCG)')  then 13000000
    when doanhsochuavat <  6000000000 and  a.chucdanhengtitlesum not in ('KAM (FMCG)')  then doanhsochuavat * 0.2 /100
  else null end as lhq1,

  Case ----Lương hiệu quả 2 kênh TP - Phụ cấp kết quả công việc (LHQ2): Căn cứ vào A
    when th_kpi < 80 then th_kpi * 5000000 / 100
    when th_kpi >= 80 and th_kpi < 90   then th_kpi * 10000000 / 100
    when th_kpi >= 90 and th_kpi < 100  then th_kpi * 11000000 / 100 
    when th_kpi >= 100 and th_kpi < 110 then th_kpi * 12000000 / 100
    when th_kpi >= 110 and th_kpi < 120 then th_kpi * 12500000 / 100
    when th_kpi >= 120 and makenhkh ='MT' then th_kpi * 13000000 / 100

  else null end as lhq2,

  Case
  ---LHQ 3  kênh MT KAM phụ trách FMCG
    when th_kpi_fmcg < 80 and makenhkh='MT' and a.chucdanhengtitlesum in ('KAM (FMCG)') then 0
    when th_kpi_fmcg >= 80 and th_kpi_fmcg < 90  and makenhkh='MT'and a.chucdanhengtitlesum in ('KAM (FMCG)') then 3000000
    when th_kpi_fmcg >= 90 and th_kpi_fmcg < 100 and makenhkh='MT' and a.chucdanhengtitlesum in ('KAM (FMCG)') then 4000000 
    when th_kpi_fmcg >= 100 and th_kpi_fmcg < 110 and makenhkh='MT' and a.chucdanhengtitlesum in ('KAM (FMCG)') then 6000000
    when th_kpi_fmcg >= 110 and th_kpi_fmcg < 120 and makenhkh='MT' and a.chucdanhengtitlesum in ('KAM (FMCG)') then 7000000
    when th_kpi_fmcg >= 120 and makenhkh ='MT' and a.chucdanhengtitlesum in ('KAM (FMCG)') then 8000000

  ---LHQ 3  kênh MT KAM phụ thuộc vào N --Chị nga SPTT Ebysta ko phụ trách FMCG
    when IF(a.thang >= '2025-10-01',th_kpi_sptt_mt,th_kpi_fmcg ) < 80   and makenhkh='MT' and a.chucdanhengtitlesum not in ('KAM (FMCG)') then 0
    when IF(a.thang >= '2025-10-01',th_kpi_sptt_mt,th_kpi_fmcg ) >= 80  and IF(a.thang >= '2025-10-01',th_kpi_sptt_mt,th_kpi_fmcg ) < 90 and makenhkh='MT' and a.chucdanhengtitlesum not in ('KAM (FMCG)') then 3000000
    when IF(a.thang >= '2025-10-01',th_kpi_sptt_mt,th_kpi_fmcg ) >= 90  and IF(a.thang >= '2025-10-01',th_kpi_sptt_mt,th_kpi_fmcg ) < 100 and makenhkh='MT' and a.chucdanhengtitlesum not in ('KAM (FMCG)') then 4000000
    when IF(a.thang >= '2025-10-01',th_kpi_sptt_mt,th_kpi_fmcg ) >= 100 and IF(a.thang >= '2025-10-01',th_kpi_sptt_mt,th_kpi_fmcg ) < 110 and makenhkh='MT' and a.chucdanhengtitlesum not in ('KAM (FMCG)') then 6000000
    when IF(a.thang >= '2025-10-01',th_kpi_sptt_mt,th_kpi_fmcg ) >= 110 and IF(a.thang >= '2025-10-01',th_kpi_sptt_mt,th_kpi_fmcg ) < 120 and makenhkh='MT' and a.chucdanhengtitlesum not in ('KAM (FMCG)') then 7000000
    when IF(a.thang >= '2025-10-01',th_kpi_sptt_mt,th_kpi_fmcg ) >= 120 and makenhkh='MT' and a.chucdanhengtitlesum not in ('KAM (FMCG)') then 8000000
  else null
  end as lhq3,

  0 as lhq4
  
  from combined a
  WHERE makenhkh = 'MT' and dtype = 'crm' and a.chucdanhengtitlesum like "%KAM%"
)


----------------------------------------------Ghep tat ca lai---------------------------------------
, UNION_ALL as

(

select * from TP_NV
UNION ALL
select * from TP_CRM
UNION ALL
select * from HCP_NV
UNION ALL
select * from HCP_CRM
UNION ALL
select * from HCP_NCRM

UNION ALL
select * from MT_NV
UNION ALL
select * from MT_NV_SUP
UNION ALL
select * from MT_KAM

ORDER BY makenhkh, thang

)

, fix_lhq as

(

select a.*except (manv, lhq1, lhq2, lhq3, lhq4),

case when a.dtype = 'nv' and a.manv = u.supid then concat('KN',RIGHT(a.manv,4)) else a.manv end as manv,

Case 
when Trim(upper(hr.loaihdld)) in ('HỌC VIỆC','THỬ VIỆC') then 0
when hr.loaihdld is null then 0
when u.position ='D' then 0
when a.dtype = 'nv' and a.manv = u.supid then 0
when IFNULL(hr.bophanteam,'null') = 'GT' then 0
when IFNULL(hr.phongdeptsummary,'null') = 'SC' then 0
else round(lhq1,0) end as lhq1,

Case 
when Trim(upper(hr.loaihdld)) in ('HỌC VIỆC','THỬ VIỆC') then 0
when hr.loaihdld is null then 0
when u.position ='D' then 0
when a.dtype = 'nv' and a.manv = u.supid then 0
when IFNULL(hr.bophanteam,'null') = 'GT' then 0
when IFNULL(hr.phongdeptsummary,'null') = 'SC' then 0
else round(lhq2,0) end as lhq2,

case
when Trim(upper(hr.loaihdld)) in ('HỌC VIỆC','THỬ VIỆC') then 0
when hr.loaihdld is null then 0
when u.position ='D' then 0
when a.dtype = 'nv' and a.manv = u.supid then 0
when IFNULL(hr.bophanteam,'null') = 'GT' then 0
when IFNULL(hr.phongdeptsummary,'null') = 'SC' then 0
else round(lhq3,0) end as lhq3,

Case 
when Trim(upper(hr.loaihdld)) in ('HỌC VIỆC','THỬ VIỆC') then 0
when hr.loaihdld is null then 0
when u.position ='D' then 0
when a.dtype = 'nv' and a.manv = u.supid then 0
when IFNULL(hr.bophanteam,'null') = 'GT' then 0
when IFNULL(hr.phongdeptsummary,'null') = 'SC' then 0
else round(lhq4,0) end as lhq4,

tc.ds_ins_toanquoc,
tc.ds_pcl_toanquoc,
tc.kh_total_ins_toanquoc,
tc.kh_total_pcl_toanquoc,
tc.th_dskh_ins_toanquoc,
tc.th_dskh_pcl_toanquoc,


CASE WHEN supid = 'MR0868' THEN 0 ELSE m.th_fmcg END AS th_fmcg_toanquoc,
CASE WHEN supid = 'MR0868' THEN 0 ELSE m.kpi_fmcg END AS kpi_fmcg_toanquoc,
CASE WHEN supid = 'MR0868' THEN 0 ELSE m.th_kpi_fmcg  END AS th_kpi_fmcg_toanquoc,

b.th_kpi_support,

u.position as cap_bac,

case
  when dtype = 'nv' then 'CRS'
  when dtype = 'crm' and a.manv not in ('MR0123', 'MR1137') then 'CRM'
  else 'N.CRM'
end as chuc_vu,

u.tencvbh,
u.supid,
u.tenquanlytt,
u.asm,
u.tenquanlykhuvuc,
u.rsmid,
u.tenquanlyvung,
IFNULL(trim(hr.chucdanhengtitlesum),'chưa có') as chuc_danh,
Case
when hr.loaihdld is null then 'NGHỈ VIỆC' 
else Trim(upper(hr.loaihdld)) 
end as loaihdld,
date(hr.ngaykyhdldchinhthuc) as ngaykyhdldchinhthuc,
date(hr.ngayvaolamonboarddate) as ngayvaolamvc,
trim(upper(phaply)) as phaply,
hr.diabanlamviec as diabanlamviec,

CASE
  WHEN MOD(EXTRACT(MONTH FROM a.thang) - 1, 3) = 0 THEN 1
  WHEN MOD(EXTRACT(MONTH FROM a.thang) - 1, 3) = 1 THEN 2
  WHEN MOD(EXTRACT(MONTH FROM a.thang) - 1, 3) = 2 THEN 3
END AS stt_thang_trong_quy,

timestamp(current_datetime("+7"))  as inserted_at,

m.th_kpi_ds_mt,
m.th_ds_mt,
m.kh_total_mt,
m.th_sptt_mt as th_sptt_mt_crm,
m.kpi_ds_sptt_mt as kpi_ds_sptt_mt_crm,
m.th_kpi_sptt_mt as th_kpi_sptt_mt_crm

from UNION_ALL a
LEFT JOIN `staging.d_hr_dsns_bytime` hr on a.manv = hr.msnvcsmmoi and date(hr.thang) = date(a.thang)
LEFT JOIN `staging.d_users_bytime` u ON a.manv = u.manv AND date(a.thang) = date(u.thang)
LEFT JOIN `th_kh_ins_pcl_toan_quoc` tc on tc.thang = a.thang and a.dtype = 'crm' and a.manv in ('MR0123', 'MR1137')
--LEFT JOIN `th_kh_fmcg_toan_quoc` tq on tq.thang = a.thang
LEFT JOIN th_kpi_support_cre b on b.ma_cre = a.manv and b.thang = a.thang
LEFT JOIN kpi_ds_mt_mix m on m.manv = a.manv and m.thang = a.thang
WHERE 
--IFNULL(hr.bophanteam,'null') not in ('GT')
a.manv != 'MR0485' -- CRM kênh GT Nguyễn Hoàng Viển

)
, data_vieng_tham AS (
SELECT
slsperid AS manv,
thang_visitdate AS thang,
COUNT(DISTINCT ma_kh_can_vieng_tham) AS sl_kh_can_vt,
COUNT(DISTINCT ma_kh_dat) AS sl_kh_da_vt,
ROUND(
        SAFE_DIVIDE(COUNT(DISTINCT ma_kh_dat), COUNT(DISTINCT ma_kh_can_vieng_tham)) * 100, 2
    ) AS phan_tram_tien_do_vt,

COUNT(ma_kh_can_vieng_tham) AS sl_call_can_checkin,
COUNT(DISTINCT ma_call_kh_dat) AS sl_call_da_checkin,
ROUND(
        SAFE_DIVIDE(COUNT(DISTINCT ma_call_kh_dat), COUNT(ma_kh_can_vieng_tham)) * 100, 2
    ) AS phan_tram_call_checkin
FROM `spatial-vision-343005.warehouse.view_f_data_checkin_pbh_v3`
GROUP BY 
    slsperid, 
    thang_visitdate
)

select a.*, ifnull(lhq1,0)+ifnull(lhq2,0)+ifnull(lhq3,0)+ifnull(lhq4,0) as tong_lhq,
b.sl_kh_can_vt,
b.sl_kh_da_vt,
b.phan_tram_tien_do_vt,
b.sl_call_can_checkin,
b.sl_call_da_checkin,
b.phan_tram_call_checkin
from fix_lhq a 
LEFT JOIN data_vieng_tham b ON a.manv = b.manv AND b.thang = a.thang
--where chucdanhengtitlesum = 'CRE'
--where a.thang = '2025-10-01' and a.makenhkh = "MT"

);

Create or replace table `warehouse.f_luonghieuqua_all_2024`

copy `staging_temp.f_luonghieuqua_all_2024_temp`;

End;