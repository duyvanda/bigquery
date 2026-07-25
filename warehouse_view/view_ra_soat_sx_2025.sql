CREATE VIEW `spatial-vision-343005.warehouse.view_ra_soat_sx_2025`
AS with ton_kho as
(
SELECT
-- a.ma_kho,
-- a.kho_hang,
a.ma_vt,
-- a.ma_sp_cu,
-- a.ma_sx,
-- a.ten_vt,
-- a.so_luong_vt,
sum(a.so_luong) as ton_kho_thang_truoc,
-- a.tien_kho,
-- a.capture_date,
-- a.vtth_ty_le,
-- a.he_so_quy_doi,
-- a.vtth_dvt,
FROM `spatial-vision-343005.staging.f_ge_giao_dich_nvl_bao_bi` a
where
trim(a.ma_kho) in (
    'A0101',
    'A0102',
    'A0201',
    'A0202',
    'A0204',
    'A0205',
    'A0301',
    'A0302',
    'A04',
    'A041',
    'A042',
    'A0401',
    'A0402'
)

and date(a.capture_date) = '2025-01-25'

group by all

)

, po_sx as(
SELECT
ma_san_pham,
sum(case when thang = '2025-01-01' then so_luong else 0 end) as po_t1,
sum(case when thang = '2025-02-01' then so_luong else 0 end) as po_t2,
sum(case when thang = '2025-03-01' then so_luong else 0 end) as po_t3,
sum(case when thang = '2025-04-01' then so_luong else 0 end) as po_t4,
sum(case when thang = '2025-05-01' then so_luong else 0 end) as po_t5
FROM `spatial-vision-343005.staging.d_san_xuat_theo_lo`
group by all
)

, ma_vt_va_sl_sp as

-- ví dụ A020014 Glycerin có 22 mã thành phẩm

(
    select
    a.mavt,
    count(a.ma_thanh_pham) as sl_ma_thanh_pham
    FROM `spatial-vision-343005.staging.d_dm_nvl_bbi` a
    group by all
)

SELECT
a.mavt,
a.tenvt,
a.loainvlbb,
a.ma_thanh_pham,
a.dm1,
a.value,
ifnull(b.ton_kho_thang_truoc,0) / sl_ma_thanh_pham as ton_kho_thang_truoc,
c.po_t1,
c.po_t2,
c.po_t3,
c.po_t4,
c.po_t5

FROM `spatial-vision-343005.staging.d_dm_nvl_bbi` a
LEFT JOIN ton_kho b on a.mavt = b.ma_vt
LEFT JOIN po_sx c on a.ma_thanh_pham = c.ma_san_pham
LEFT JOIN ma_vt_va_sl_sp d on a.mavt = d.mavt
where a.loainvlbb not like '%BBC%' 
-- and a.mavt = 'A020014';