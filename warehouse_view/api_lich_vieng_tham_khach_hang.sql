CREATE VIEW `spatial-vision-343005.warehouse.api_lich_vieng_tham_khach_hang`
AS SELECT
a.slsperid as ma_crs,
b.tencvbh as ten_crs, 
b.supid as ma_crm, 
b.tenquanlytt as ten_crm,
visitdate as ngay_vieng_tham,
a.custid as ma_kh_dms,
c.custname as ten_kh_dms,
c.address as dia_chi_kh,
a.channel as kenh,

FROM `spatial-vision-343005.warehouse.data_quy_dinh_vieng_tham` a

LEFT JOIN `staging.d_users` b 
ON a.slsperid = b.manv

LEFT JOIN `staging.d_master_khachhang` c ON a.custid = c.custid

WHERE visitdate >= DATE_TRUNC(CURRENT_DATE(), MONTH)
AND visitdate <  DATE_TRUNC(DATE_ADD(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH);;