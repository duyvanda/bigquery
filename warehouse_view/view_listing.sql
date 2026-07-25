CREATE VIEW `spatial-vision-343005.warehouse.view_listing`
AS with history_cus as
(
select makhdms,
sum(doanhsocovat) as doanhso
from `staging.f_sales`
where date(ngaychungtu)>= '2023-10-01' and date(ngaychungtu) <= '2024-05-31'
group by 1
),

sum_dh as 
(
select sodondathang,
SUM(doanhsocovat) as ds_tong_dh
from `staging.f_sales` 
group by 1
),

history_product as
(
select masanpham,makhdms,
sum(doanhsocovat) as doanhso
from `staging.f_sales`
where date(ngaychungtu)>= '2023-10-01' and date(ngaychungtu) <= '2024-04-30'
AND doanhsochuavat != 0
group by 1,2
),

dieu_chinh_nv as 
(
SELECT distinct sodondathang, manv 
FROM `spatial-vision-343005.warehouse.f_sales_crs` 
where date(ngaychungtu)>= '2024-05-01')


select
a.ngaychungtu,
a.sodondathang,
a.makhdms,
tenkhachhang,
tentinhkh,
a.masanpham,
tensanphamviettat,
a.soluong,
doanhsocovat,
doanhsochuavat,
a.manv,
e.tencvbh,
e.supid,
e.tenquanlytt,
ifnull(f.manv,a.manv) as manv_fix,
x.supid as supid_fix,
x.tenquanlytt as qltt_fix,
x.tencvbh as tencvbh_fix,
case when b.makhdms is null then 'Chuamua' else 'Damua' end as check_kh_da_mua_trong_lich_su,
ifnull(c.ds_tong_dh,0) as check_ds_tong_dh,
case when d.masanpham is null then 'Chuamua' else 'Damua' end as check_sp_kh_da_mua_trong_lich_su,


from `staging.f_sales` a
left join  history_cus  b on a.makhdms = b.makhdms
left join sum_dh c on a.sodondathang = c.sodondathang
left join history_product d on a.masanpham = d.masanpham AND a.makhdms = d.makhdms
left join `spatial-vision-343005.staging.d_users` e on a.manv = e.manv
left join dieu_chinh_nv f on a.sodondathang = f.sodondathang
left join `spatial-vision-343005.staging.d_users` x on ifnull(f.manv,a.manv) = x.manv

where date(a.ngaychungtu)>= '2024-05-01' 
and kieudonhang in ('IN','CO') 
and tentinhkh = 'Thành phố Hồ Chí Minh'
and makenhkh = 'TP'











;