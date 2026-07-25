CREATE VIEW `spatial-vision-343005.warehouse.view_thuong_ban_hang_sunohada_q4_2025`
AS WITH data_raw as (
  select 
a.ngaychungtu,
a.inserted_at,
a.macongtycn,
a.ma_crm,
a.tenquanlytt,
a.manv,
a.tencvbh,
a.territorydescr,--khu vực
a.statedescr, -- tỉnh
a.sodondathang,
a.makhdms,
a.tenkhachhang,
a.makenhkh_cu,
a.makenhphu_cu,
a.hcoid,
a.maphanloaihco_cu,
a.masanpham,
a.tensanphamnb ,
a.tensanphamviettat,
a.soluong,
a.doanhsocovat,
a.doanhsochuavat,
a.ngay_ky_hd,
IF (date(ngay_ky_hd) >= '2025-10-01', 'KH mới', 'KH cũ') as kh_type,
CASE
  WHEN 
  makenhkh_cu = 'PCL'
  and a.masanpham in ('T4040101001','T4040101002')
  and date (ngaychungtu) >= '2025-10-01' and date (ngaychungtu) <= '2025-12-31'
  and DATE(ngay_don_hang_dau_tien) = DATE(ngaychungtu)
  and SUM (a.soluong) OVER (PARTITION BY a.sodondathang )>=4
  THEN makhdms 
  ELSE NULL
  END AS ma_kh_tinh_pp,
target_crm,
ngay_don_hang_dau_tien,
FROM `warehouse.view_thuong_ban_hang_sunohada_data_chitiet` a
where date(ngaychungtu) >='2025-07-01' and ngaychungtu <='2025-12-31'
)

SELECT
*
FROM data_raw























;