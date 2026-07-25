CREATE VIEW `spatial-vision-343005.warehouse.view_check_chuong_trinh_cpa_27`
AS WITH don_hang_gan_km as

(

SELECT sodondathang, sum(soluong) as soluong FROM `spatial-vision-343005.warehouse.f_tongquat_ctkm` 
WHERE 
TIMESTAMP_TRUNC(ngaychungtu, DAY) >= TIMESTAMP("2025-01-01") AND discidpn = '202504-DH-CPA27-PCL'
AND masanpham = 'EH115' and sp_kmai = 1
GROUP BY ALL

)

SELECT
s.macongtycn,
s.ngaychungtu,
s.sodondathang,

s.makhdms,
s.tenkhachhang,
s.makenhkh_cu,
s.makenhphu_cu,
s.statedescr,
s.khuvucviettat,
s.mahco_cu,
s.maphanloaihco_cu,
'EH115' as masanpham_km,
'Ebysta (10 ml gói)' as tensanpham_km,
'202504-DH-CPA27-PCL' as discidpn,
s.tencvbh,
s.tenquanlytt,


s.masanpham,
s.tensanphamnb,
s.tensanphamviettat,
s.soluongori as soluongthucte,
IFNULL(km.soluong,0) as soluong,
case when doanhsochuavat= 0 then 0 else dongiacovat end as dongiachuavat,
IF (doanhsochuavat=0, "khuyen_mai", "ban_hang") as phan_loai_hang
FROM
`warehouse.f_raw_data_sales_yoy` s
LEFT JOIN don_hang_gan_km km on km.sodondathang = s.sodondathang
WHERE s.ngaychungtu >= '2025-04-01'
AND s.makhdms in ('014916', '014937', '014938');