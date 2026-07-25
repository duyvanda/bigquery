CREATE VIEW `spatial-vision-343005.warehouse.view_giai_onlne_toan_ct_crs`
AS WITH data_raw as (
SELECT *
FROM `spatial-vision-343005.warehouse.view_giai_online_t5_data_chitiet`
)
, data_th_slpp as (
SELECT 
manv,
ten_nv,
ma_crm,
crm,
COUNT(DISTINCT ma_kh_tinh_pp) as th_slpp,
SUM(Doanh_so_chuaVAT) as Doanh_so,
Sum(soluong) as So_luong,
FROM data_raw
GROUP BY ALL
)

SELECT 
manv,
ten_nv,
ma_crm,
crm,
th_slpp,
Doanh_so,
So_luong,
--RANK() OVER (PARTITION BY ngay_tao_don ORDER BY th_slpp desc,So_luong DESC) AS rank_by_slpp
FROM data_th_slpp a
inner join staging.d_he_so_tinh_thuong_crm_tp b ON b.ma_ql = a.ma_crm
--WHERE ten_nv = 'Đào Thị Nhàn'
--ORDER BY rank_by_slpp ASC;