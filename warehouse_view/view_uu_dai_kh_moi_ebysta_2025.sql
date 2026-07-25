CREATE VIEW `spatial-vision-343005.warehouse.view_uu_dai_kh_moi_ebysta_2025`
AS WITH kh_da_mua as
(
select 
makhdms,
sum(doanhsocovat) as dscv


FROM `warehouse.f_raw_data_sales_yoy`
where masanpham = 'EH115' and date(ngaychungtu)>= '2024-10-01' and date(ngaychungtu)<= '2025-03-27'
and is_hang_km  = 'Hàng bán'
group by all
having dscv> 0
)

select
a.macongtycn,
ifnull(a.sodontrahang, a.sodondathang) as sodondathang,
a.manv,
a.makhdms,
case when c.makhdms is not null then 'da_mua' else 'chua_mua' end as tinh_trang_da_mua_hang,
a.masanpham,
a.tensanphamnb,
a.soluong as sl,
a.dongiacovat,
b.tencvbh,
b.supid,
b.tenquanlytt,
d.custname,
SUM(soluong) OVER (PARTITION BY macongtycn, ifnull(a.sodontrahang, a.sodondathang), a.makhdms) as sl_total_dh,


FROM `warehouse.f_raw_data_sales_yoy` a
LEFT JOIN kh_da_mua c on a.makhdms = c.makhdms
left join `spatial-vision-343005.staging.d_users`  b on a.manv = b.manv
left join `spatial-vision-343005.staging.d_master_khachhang`  d on a.makhdms = d.custid
where date(a.ngaychungtu)  >= '2025-04-01'
and date(a.ngaychungtu)  <= '2025-04-29'
and a.kieudonhang in ('IN', 'CO', 'IR')
and masanpham = 'EH115'
and is_hang_km  = 'Hàng bán'
and makenhkh_cu = 'TP';