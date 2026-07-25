CREATE VIEW `spatial-vision-343005.warehouse.view_mds_pxk_kvcnb`
AS SELECT slsperid, tencvbh, d.role_luong_mds_phanloai, date(crtd_datetime) as ngay_van_chuyen, count(distinct batnbr) as so_chuyen
FROM `spatial-vision-343005.staging.mds_pxkkvcnb_vcnb` a
INNER JOIN `staging.d_users` d on a.slsperid  = d.manv and d.role_luong_mds_phanloai in ( 'LOGHUBTONG_CN','LOGHUBTONG_HY')
group by all

;