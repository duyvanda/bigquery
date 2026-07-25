CREATE VIEW `spatial-vision-343005.warehouse.view_daily_trend_kho`
AS SELECT * FROM
(
SELECT

a.branchid,
-- branchname,
siteid,
a.tenkho,
-- class,
a.invtid,
-- tensanpham,
-- tenspviettat,
-- stkunit,
-- quycachdonggoi,
-- quycachthung,
-- lotsernbr,
-- expdate,
-- sothangconlai,
-- tondau,
-- nhapmuahang,
-- nhapkhacnhapchuyendieuchinh,
-- xuatban,
-- nhaptra,
-- xuatkhacxuatchuyendieuchinh,
-- dcbbxuat,
-- dcbbnhap,
toncuoi,
sltreohoadonao,
sltreochuataohoadon,
-- toncuoisosach,
-- giaban,
-- tttoncuoi,
created_date,
-- manufacturedate,
date(created_date) as capture_date,
b.phanloaicn,
c.descr as ten_san_pham,
-- c.descr1
FROM `spatial-vision-343005.staging.f_sc_daily_raw_invt` a
LEFT JOIN `staging.d_sc_kho_chi_nhanh` b on b.makho = a.siteid
LEFT JOIN `staging.d_dms_master_invtid` c on a.invtid = c.invtid
WHERE TIMESTAMP_TRUNC(created_date, DAY) >= TIMESTAMP("2024-01-01")
AND LEFT(a.invtid, 1) not in ('V', 'D')
and ifnull(b.phanloaicn,'NONE') not in ('HUY')

)
QUALIFY dense_rank() over(partition by capture_date order by created_date desc ) =1
;