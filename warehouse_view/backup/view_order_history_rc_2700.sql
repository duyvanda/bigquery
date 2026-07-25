CREATE VIEW `spatial-vision-343005.warehouse.view_order_history_rc_2700`
AS with data_kh as 
(
SELECT distinct ma_kh from staging.d_manual_chuong_trinh_rc_cx
UNION ALL
SELECT distinct ma_kh from staging.d_manual_chuong_trinh_rc_mds

)


, order_ecom as

(
  SELECT
  distinct
  ordernbr,
  custid,
  'TMDT_001' as crtd_user
  from
  `spatial-vision-343005.staging.sync_dms_pda_so`
  WHERE
  (
  crtd_user = 'TMDT_001'
  or slsperid = 'TMDT_001'
  )
  and crtd_datetime >= '2023-01-01'
)


SELECT
macongtycn,
congtycn,
ngaychungtu,
sodondathang,
mahd,
sodontrahang,
ngaytrahang,
hoadon,
makhdms,
makhcu,
tenkhachhang,
tenkhuvuc,
tentinhkh,
tenquanhuyen,
makenhkh,
makenhphu,
tensanphamviettat,
soluong,
dongiacovat,
doanhsocovat,
dongiachuavat,
doanhsochuavat,
manv,
tencvbh,
case when o.crtd_user = 'TMDT_001' then 'ecom' else 'truyen_thong' end as check_loai_don,
inserted_at
from staging.f_sales a
INNER JOIN data_kh b on a.makhdms = b.ma_kh
LEFT JOIN order_ecom o on IFNULL(a.sodontrahang, a.sodondathang) = o.ordernbr
where date(ngaychungtu)>= '2023-01-01';