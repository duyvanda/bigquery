CREATE VIEW `spatial-vision-343005.warehouse.view_sales_trahang`
AS WITH data_adj as (
SELECT 
DISTINCT sodondathang as so_don_dat_hang,
FROM `spatial-vision-343005.staging.f_sales_adjusted`
WHERE note = 'Nhập trả n_3'
)
SELECT
a.*
-- a.year,
-- a.cycle,
-- a.sodondathang,
-- a.ngaychungtu,
-- a.macongtycn,
-- a.manv,
-- a.tencvbh,
-- a.tenquanlytt,
-- a.tenquanlyvung,
-- a.tenquanlykhuvuc,
-- a.makhdms,
-- a.tenkhachhang,
-- a.masanpham,
-- a.tensanphamnb,
-- a.soluong,
-- a.dongiachuavat,
-- a.doanhsochuavat,
-- a.doanhsocovat,
-- a.territorydescr,
-- a.statedescr,
-- a.districtdescr,
-- a.pubcustid,
-- a.phong_kh_cu,
-- a.makenhkh_cu,
-- a.tensanphamviettat,
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
INNER JOIN data_adj b ON b.so_don_dat_hang = a.sodondathang
;