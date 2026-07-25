CREATE VIEW `spatial-vision-343005.warehouse.view_luonghieuqua_kenh_gt`
AS WITH data_raw_fix as (
SELECT
a.thang,
a.macongtycn,
a.makhdms,
a.tenkhachhang,
a.tentinhkh,
a.makenhkh_cu,
a.manv,
a.tencvbh,
a.ma_crm,
a.tenquanlytt,
IFNULL(a.sodontrahang,a.sodondathang) as sodondathang,
SUM(a.doanhsochuavat) as doanhsochuavat,
a.inserted_at,
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
WHERE date(a.ngaychungtu) >='2025-10-01' --and date(a.ngaychungtu) <='2025-09-30'
AND a.manv in ('MR4013','MR4016','MR4014','MR4015')
AND a.makenhkh_cu in ('GT')
AND a.is_hang_km != 'Hàng KM'
GROUP BY ALL
)
, data_raw as (
SELECT
a.*,
CASE 
  WHEN SUM(a.doanhsochuavat) OVER (PARTITION BY a.sodondathang ) >= 85000 THEN a.makhdms
ELSE NULL END AS ma_kh_tinh_active
FROM data_raw_fix a
)

,slkh_mo_code as (
SELECT
crtd_user as manv,
DATE_TRUNC(date(a.crtd_datetime), MONTH) as thang_ky_hd,
COUNT(DISTINCT a.custid) AS slkh_mo_code
FROM `spatial-vision-343005.staging.d_master_khachhang_bytime` a
WHERE DATE(a.crtd_datetime) >= '2025-10-01'
AND a.channel = 'GT'
AND crtd_user in ('MR4016')
GROUP BY ALL
)
,data_tinh_thuong as (
SELECT
a.thang,
a.macongtycn,
a.manv,
a.tencvbh,
a.ma_crm,
a.tenquanlytt,
a.makenhkh_cu,
SUM(a.doanhsochuavat) AS doanhsochuavat,
COUNT(DISTINCT a.ma_kh_tinh_active) AS slkh_active,
b.slkh_mo_code,
a.inserted_at,
tg.kh_total
FROM data_raw a
LEFT JOIN slkh_mo_code b on b.manv = a.manv AND b.thang_ky_hd = DATE(a.thang)
LEFT JOIN `spatial-vision-343005.staging.d_calendar` tg ON a.manv = tg.manv AND DATE(a.thang) = DATE(tg.thang)
GROUP BY ALL
)
,final_kpi AS (
  SELECT
    t.*,

    SAFE_DIVIDE(t.doanhsochuavat, t.kh_total) AS th_kpi_ds
  FROM data_tinh_thuong t
)
SELECT
a.*,
trim(hr.chucdanhengtitlesum) as chuc_danh,
hr.diabanlamviec as diabanlamviec,
Case
when hr.loaihdld is null then 'NGHỈ VIỆC' 
else Trim(upper(hr.loaihdld)) 
end as loaihdld,
trim(upper(phaply)) as phaply,

CASE
    WHEN DATE(a.thang) >= '2026-01-01' THEN 
      CASE
        WHEN doanhsochuavat >= 50000000 THEN 4000000
        WHEN doanhsochuavat >= 40000000 THEN 3000000
        WHEN doanhsochuavat >= 30000000 THEN 2000000
        WHEN doanhsochuavat >= 20000000 THEN 1000000
        ELSE 0 
      END
    ELSE
      CASE
        WHEN a.slkh_mo_code >= 70 THEN 1500000
        WHEN a.slkh_mo_code >= 50 THEN 1000000
        ELSE 0 
      END
  END AS lhq_1,

CASE
    WHEN DATE(a.thang) >= '2026-01-01' THEN
      CASE
        WHEN a.th_kpi_ds >= 1.1 THEN a.th_kpi_ds * 2000000 
        WHEN a.th_kpi_ds >= 1.0 THEN a.th_kpi_ds * 1500000 
        ELSE a.th_kpi_ds * 1000000         
      END
    ELSE -- Chính sách cũ
      CASE
        WHEN slkh_active >= 40 AND manv = 'MR4016' THEN 2000000
        WHEN slkh_active >= 30 AND manv = 'MR4016' THEN 1500000
        WHEN slkh_active >= 20 AND manv = 'MR4016' THEN 1000000

        WHEN slkh_active >= 50 AND manv in ('MR4013','MR4014','MR4015') THEN 3000000
        WHEN slkh_active >= 40 AND manv in ('MR4013','MR4014','MR4015') THEN 2000000
        WHEN slkh_active >= 30 AND manv in ('MR4013','MR4014','MR4015') THEN 1000000
        ELSE 0 
      END
  END AS lhq_2,

CASE
    WHEN DATE(a.thang) >= '2026-01-01' THEN 
      CASE
        WHEN a.slkh_active >= 40 THEN 2000000 
        WHEN a.slkh_active >= 30 THEN 1500000 
        WHEN a.slkh_active >= 20 THEN 1000000 
        ELSE 0 
      END
    ELSE -- Chính sách cũ
      CASE
        WHEN doanhsochuavat >= 50000000 AND manv = 'MR4016' THEN 4000000
        WHEN doanhsochuavat >= 40000000 AND manv = 'MR4016' THEN 3000000
        WHEN doanhsochuavat >= 30000000 AND manv = 'MR4016' THEN 2000000
        WHEN doanhsochuavat >= 20000000 AND manv = 'MR4016' THEN 1000000

        WHEN doanhsochuavat >= 60000000 AND manv in ('MR4013','MR4014','MR4015') THEN 4500000
        WHEN doanhsochuavat >= 50000000 AND manv in ('MR4013','MR4014','MR4015') THEN 3500000
        WHEN doanhsochuavat >= 40000000 AND manv in ('MR4013','MR4014','MR4015') THEN 2500000
        WHEN doanhsochuavat >= 30000000 AND manv in ('MR4013','MR4014','MR4015') THEN 1000000
        ELSE 0 
      END 
  END AS lhq_3


FROM final_kpi a
LEFT JOIN `staging.d_hr_dsns_bytime` hr on a.manv = hr.msnvcsmmoi and date(hr.thang) = date(a.thang)









;