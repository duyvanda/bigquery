CREATE VIEW `spatial-vision-343005.warehouse.view_giai_onlne_toan_ct_crm`
AS WITH DATA_KPI AS (
SELECT

a.ma_crm,
a.crm,
b.he_so_nhom,
sum(doanh_so) as doanh_so,
sum(a.th_slpp) as tong_pp,
sum(so_luong) as so_luong,
round(sum(a.th_slpp)/b.he_so_nhom,1) as avg_pp
From `spatial-vision-343005.warehouse.view_giai_onlne_toan_ct_crs` a
LEFT JOIN staging.d_he_so_tinh_thuong_crm_tp b ON b.ma_ql = a.ma_crm
Group by all
)
select
*,
'manv' as manv,
RANK() OVER (ORDER BY avg_pp DESC) AS rank_avg_pp

FROM DATA_KPI
;