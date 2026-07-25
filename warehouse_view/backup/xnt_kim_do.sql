CREATE VIEW `spatial-vision-343005.warehouse.xnt_kim_do`
AS WITH 

kd_con as (
  
  select 
  sodondathang, 
  sum(soluong) as soluong 
  from `staging.f_sales` where date(ngaychungtu)>= '2025-04-01'
  group by all
)

,combined as
(
SELECT
'sellout' as dtype,
a.branchid as macongtycn,
a.ordernbr as sodondathang,
a.custid as makhdms,
a.custname as tenkhachhang,
a.statename as tentinhkh,
DATE(a.crtd_datetime) as ngaychungtu,
a.invtid as masanpham,
a.free_item,
case
when ordernbr like '%OO%' then a.line_qty *-1 else a.line_qty 
end as soluong,
case when k.sodondathang is not null then 0 else a.line_qty end as soluongao,
a.discidpn
FROM `staging.d_data_kim_do_final` a
LEFT Join `kd_con` k on a.ordernbr = k.sodondathang
UNION ALL
SELECT
'sellin' as dtype,
a.macongtycn,
a.sodondathang,
a.makhdms,
a.tenkhachhang,
a.tentinhkh,
DATE(ngaychungtu) as ngaychungtu,
a.masanpham,
a.sp_kmai as free_item,
a.soluong,
0.0 as soluongao,
a.discidpn
FROM `warehouse.f_tongquat_ctkm` a
WHERE makhdms in ('014916','014937','014938')
AND DATE(ngaychungtu)>= '2025-04-01'
)

SELECT 
a.*,
b.descr,
k.kho
FROM combined a
LEFT JOIN `staging.d_dms_master_invtid` b on a.masanpham = b.invtid
LEFT JOIN `staging.d_phan_vung_kd_kim_do` k on k.ten_tinh_merap = a.tentinhkh;