CREATE VIEW `spatial-vision-343005.warehouse.view_ds_pkk_trong_tam_2025`
AS with sales as

(
  
SELECT
a.macongtycn,
a.makhcu,
a.makhdms,
a.tenkhachhang,
a.makenhkh,
a.makenhphu,
a.tentinhkh,
a.statedescr,
a.territorydescr,
a.districtdescr,
a.wardname,
a.khuvucviettat,
a.sodondathang,
a.ngaychungtu,
a.soluong,
CASE
WHEN a.maphanloaihco_cu IN ('NTXQPK')
and DATE(ngaychungtu) >= '2025-01-01' AND DATE(ngaychungtu) <= '2025-03-31'
THEN a.doanhsocovat

WHEN a.macongtycn IN ('DL0001')
and DATE(ngaychungtu) >= '2025-04-01'
THEN a.doanhsocovat
ELSE 0 END as doanhsocovat ,

CASE
WHEN a.maphanloaihco_cu IN ('NTXQPK')
and DATE(ngaychungtu) >= '2025-01-01' AND DATE(ngaychungtu) <= '2025-03-31'
THEN a.doanhsochuavat

WHEN a.macongtycn IN ('DL0001')
and DATE(ngaychungtu) >= '2025-04-01'
THEN a.doanhsochuavat
ELSE 0 END as doanhsochuavat,
a.inserted_at,
--a.ma_crm,
--a.tenquanlytt,
b.phan_loai_kh,
b.tour,
t.col. ma_nvbh as ma_crs,  --b.ma_crs,
d.tencvbh as ten_crs, --b.ten_crs,
d.supid as ma_crm,
d.tenquanlytt,
b.hien_trang_doi_qua,
b.cochua_quan_tam_zalo_oa,
b.thoi_gian_tich_luy_tu,
b.thoi_gian_tich_luy_den,

ROW_NUMBER() OVER (PARTITION BY makhdms ORDER BY ngaychungtu DESC) as rn

FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
INNER JOIN `staging.ds_pkk_trong_tam_2025` b on a.makhdms = b.ma_kh
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` t on t.custid = a.makhdms
LEFT JOIN `spatial-vision-343005.staging.d_users` d on d.manv = t.col. ma_nvbh
WHERE TIMESTAMP_TRUNC(ngaychungtu, DAY) >= TIMESTAMP("2025-01-01")
AND is_hang_km = 'Hàng bán'
)

,so_ke_hoach as(
SELECT
a.*,
-- FILE AN
gia_tri_da_doi_qua as gia_tri_tich_luy_da_doi_qua,
b.doanh_so_ke_hoach,
b.gia_tri_luy_ke_hoach,
CASE WHEN a.ngaychungtu >= a.thoi_gian_tich_luy_tu AND a.ngaychungtu <= a.thoi_gian_tich_luy_den THEN doanhsocovat
ELSE 0 END as doanh_so_tich_luy,
FROM `sales` a
LEFT JOIN `staging.ds_pkk_trong_tam_2025` b on a.makhdms = b.ma_kh and a.rn = 1
)

SELECT
--a.macongtycn,
a.makhcu,
a.makhdms,
a.tenkhachhang,
a.makenhkh,
STRING_AGG(DISTINCT a.makenhphu, ', ') AS makenhphu,
a.tentinhkh,
a.statedescr,
a.territorydescr,
a.districtdescr,
a.wardname,
a.khuvucviettat,
SUM(IFNULL(a.soluong,0)) as soluong,
SUM(IFNULL(a.doanhsocovat,0)) as doanhsocovat,
SUM(IFNULL(a.doanhsochuavat,0)) as doanhsochuavat,
MAX(a.inserted_at) as inserted_at,
a.tour,
a.ma_crs,
a.ten_crs,
a.ma_crm,
a.tenquanlytt,
a.hien_trang_doi_qua,
a.cochua_quan_tam_zalo_oa,
a.thoi_gian_tich_luy_tu,
a.thoi_gian_tich_luy_den,
a.phan_loai_kh,
SUM(IFNULL(gia_tri_tich_luy_da_doi_qua,0)) as gia_tri_tich_luy_da_doi_qua,
SUM(IFNULL(a.doanh_so_ke_hoach,0)) as doanh_so_ke_hoach,
SUM (IFNULL(a.gia_tri_luy_ke_hoach,0)) as gia_tri_luy_ke_hoach,
SUM(a.doanh_so_tich_luy) as doanh_so_tich_luy,
floor(SUM(IFNULL(a.doanh_so_tich_luy,0)) / 1000000) * 100000 as gia_tri_tich_luy_quy_doi
FROM so_ke_hoach a
--where makhdms = '005591'
GROUP BY ALL
ORDER BY makhdms



;