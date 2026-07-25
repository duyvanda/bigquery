CREATE VIEW `spatial-vision-343005.warehouse.view_thuong_ban_hang_benitaxylo_t10_2025`
AS SELECT  
a.*,
b.crtd_datetime,
CASE
  WHEN SUM(a.soluong) OVER (PARTITION BY a.sodondathang) >= 5
  THEN a.makhdms
  ELSE NULL END AS ma_kh_tinh_pp
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy`  a
LEFT JOIN `staging.sync_dms_pda_so` b 
        ON a.sodondathang = b.ordernbr
        AND a.macongtycn = b.branchid
        AND a.makhdms = b.custid
WHERE date(b.crtd_datetime) >= '2025-10-20' 
AND b.crtd_datetime <= '2025-12-20 10:00:00'
AND a.masanpham = 'T303102009'
AND a.makenhkh = 'TP'
AND a.makhdms not in ('014916','014937','014938')
AND a.makhdms not in ('016364', '016362', '016361', '016360', '016365', '016363', '016023', '016022', '016021', '016020', '016010', '014916', '014937', '014938')
AND a.is_hang_km != 'Hàng KM';