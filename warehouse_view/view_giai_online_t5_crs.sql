CREATE VIEW `spatial-vision-343005.warehouse.view_giai_online_t5_crs`
AS WITH data_raw AS (  
select 
a.* EXCEPT (crtd_datetime),
a.crtd_datetime as crtd_datetime_ori,
CASE 
      WHEN a.ordernbr='DL6-0525-01075' THEN '2025-05-14 00:00:00'
      WHEN a.crtd_datetime > '2025-05-13 17:30:00' AND a.crtd_datetime < '2025-05-14 00:00:00' THEN DATETIME_ADD(a.crtd_datetime, INTERVAL 7 HOUR)
      ELSE a.crtd_datetime 
      END AS crtd_datetime, -- giờ post đơn

FROM `spatial-vision-343005.warehouse.view_giai_online_t5_data_chitiet` a
where date(a.crtd_datetime) >='2025-05-13' and a.crtd_datetime <='2025-05-14 17:30:00' -- THAY NGÀY THỰC TẾ CHẠY CT
)

, data_th_slpp as (
SELECT 
manv,
-- CASE WHEN crtd_datetime >'2025-05-13 17:30' THEN DATE(2025,)
Date(crtd_datetime) as ngay_tao_don,
ten_nv,
ma_crm,
crm,
COUNT(DISTINCT ma_kh_tinh_pp) as th_slpp,
SUM(Doanh_so_chuaVAT) as Doanh_so,
Sum(soluong) as So_luong,
--RANK() OVER (ORDER BY COUNT(DISTINCT ma_kh_tinh_pp) DESC ) AS rank_by_slpp
FROM data_raw

GROUP BY ALL
)

SELECT 
manv,
ngay_tao_don,
ten_nv,
ma_crm,
crm,
th_slpp,
Doanh_so,
So_luong,
RANK() OVER (PARTITION BY ngay_tao_don ORDER BY th_slpp desc,So_luong DESC) AS rank_by_slpp
FROM data_th_slpp a
inner join staging.d_he_so_tinh_thuong_crm_tp b ON b.ma_ql = a.ma_crm
--WHERE ten_nv = 'Đào Thị Nhàn'
ORDER BY rank_by_slpp ASC



;