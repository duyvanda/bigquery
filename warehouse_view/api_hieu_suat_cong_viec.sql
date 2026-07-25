CREATE VIEW `spatial-vision-343005.warehouse.api_hieu_suat_cong_viec`
AS WITH tong_quan as
(
SELECT

slsperid,
channel,
date(thang_visitdate) as thang,

COUNT (DISTINCT  ma_kh_can_vieng_tham) as sl_kh_can_vieng_tham,
COUNT (DISTINCT  ma_kh_dat) as sl_kh_dat,
safe_divide (COUNT (DISTINCT ma_kh_dat ), COUNT (DISTINCT ma_kh_can_vieng_tham))*100 as ty_le_vieng_tham_khach_hang,

COUNT(ma_kh_can_vieng_tham) as sl_call_can_checkin,
COUNT(DISTINCT ma_call_kh_dat) as sl_call_checkin_thuc_te,
--safe_divide ( COUNT (DISTINCT  ma_call_kh_dat), COUNT (DISTINCT  ma_call_kh))*100 as ty_le_checkin
ROUND(SAFE_DIVIDE(COUNT(DISTINCT ma_call_kh_dat), COUNT(ma_kh_can_vieng_tham)) * 100, 1) AS ty_le_checkin

FROM `spatial-vision-343005.warehouse.view_f_data_checkin_pbh_v3` 
where date(thang_visitdate) >= '2026-01-01'
GROUP BY ALL

)
, call_result as (
SELECT * FROM tong_quan
QUALIFY ROW_NUMBER() OVER (PARTITION BY slsperid, thang  ORDER BY sl_kh_can_vieng_tham desc) = 1
)

SELECT
  a.manv AS ma_crs,
  b.tencvbh AS ten_crs,
  a.crm AS ma_crm,
  a.tenquanlytt AS ten_crm,
  DATE(a.thang) AS thang,

  CASE
    WHEN a.makenhkh IN ('INS', 'CLC', 'PCL') THEN 'HCP'
    WHEN a.makenhkh IN ('TP') THEN 'TP'
    WHEN a.makenhkh = 'MT' THEN 'MT'
    ELSE NULL
  END AS kenh,

  SUM(doanhsochuavat) AS doanh_so,
  SUM(kh_total) AS ke_hoach,
  ROUND(SAFE_DIVIDE(SUM(doanhsochuavat), SUM(kh_total)) * 100, 1) AS ty_le_doanh_so,

  c.sl_kh_can_vieng_tham,
  c.sl_kh_dat,
  c.ty_le_vieng_tham_khach_hang,

  sl_call_can_checkin,
  sl_call_checkin_thuc_te,
  ty_le_checkin


FROM `staging_temp.f_sales_crs_lhq_bytime` a

LEFT JOIN `staging.d_users_bytime` b 
  ON a.manv = b.manv 
  AND a.thang = b.thang 

LEFT JOIN call_result c on a.manv = c.slsperid and date(a.thang) = c.thang

WHERE 
  a.ngaychungtu >= '2026-01-01'
  GROUP BY ALL;