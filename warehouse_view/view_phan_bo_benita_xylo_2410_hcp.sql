CREATE VIEW `spatial-vision-343005.warehouse.view_phan_bo_benita_xylo_2410_hcp`
AS -- with sales as (
--   select sodondathang,macongtycn,manv from `staging.f_sales` where masanpham ='T303102009' and ngaychungtu >='2024-10-10' and makenhkh in ('INS','CLC','PCL') group by all
-- )

with cn_sl
as (
select
case 
when a.branchid = 'HCM001' then 'HCM'
when a.branchid = 'HYN017' then 'Hưng Yên'
when a.branchid = 'KHA014' then 'Khánh Hòa'
when a.branchid = 'DNG013' then 'Đà Nẵng'
when a.branchid = 'DNI015' then 'Đồng Nai'
when a.branchid = 'CTO016' then 'Cần Thơ'
when a.branchid = 'HNI010' then 'Hà Nội'
else null end as kho,
sum(Case when a.ordertype in ('CO') then -1*b.lineqty else b.lineqty end) as soluong,
from `staging.sync_dms_pda_so` a
LEFT JOIN `staging.sync_dms_pda_sod` b on a.ordernbr =b.ordernbr and a.branchid =b.branchid
INNER JOIN `staging.d_master_khachhang` c on a.custid = c.custid and c.channel in ('INS','PCL','CLC')
where 
date(a.crtd_datetime) >='2024-10-24' 
and a.ordertype in ('IN','CO') 
and a.status = 'C'
and b.invtid ='T303102009'  
group by all

)

select
a.kho,
phan_bo_benita_xylo_hcp,
ifnull(soluong,0) as soluong_da_duyet
from `spatial-vision-343005.staging.phan_bo_benita_xylo_2410_v2` a
LEFT JOIN cn_sl b on a.kho = b.kho

;