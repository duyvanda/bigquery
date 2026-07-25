CREATE VIEW `spatial-vision-343005.warehouse.view_theo_doi_STT_hanghoa_Tiendoupload`
AS WITH sum_dh AS (
select
a.makhdms,
a.tenkhachhang,
a.masanpham,
a.sodondathang,
date_trunc(ngaychungtu, MONTH) AS Thang,
b.branchid,
statedescr,
b.districtdescr,
b.shortterritorydescr,
b.shoptype,
b.channel,
--tao cot giu long chau
--CASE WHEN b.channel = 'MT' AND LOWER(tenkhachhang) != '%long châu%' THEN 'loaibo' ELSE 'giulai' END AS channel_fix,
CASE WHEN b.channel != 'MT' then 'giulai'
    WHEN b.channel = 'MT' AND LOWER(tenkhachhang) like '%long châu%' THEN 'giulai' ELSE 'loaibo' END as channel_fix,



SUM(a.soluong) as soluong
from `staging.f_sales` a
left join `staging.d_master_khachhang` b on a.makhdms = b.custid
where a.kieudonhang = 'IN' and a.masanpham in ('OH031','EH085','EH084','OH044','EH086','T302201014', 'T302201018')
and sodondathang not in ('DL1-0924-00429')
and b.shoptype not in ('CLC1','CLC2')
and b.channel not in ('INS') 
and(CASE 
    WHEN b.channel != 'MT' then 'giulai'
    WHEN b.channel = 'MT' AND LOWER(tenkhachhang) like '%long châu%' THEN 'giulai' ELSE 'loaibo' END) = 'giulai'
and a.ngaychungtu >= '2024-01-01' 
group by all),

loc_trung_da_upload as 
(select distinct ma_dh_full from `spatial-vision-343005.warehouse.Theo_doi_STT_Hanghoa_TONGHOP`)

select q.*,
case when ma_dh_full is null then 'Chưa up' else 'Đã up' end as check_upload
from sum_dh q
left join loc_trung_da_upload e on q.sodondathang = e.ma_dh_full

where masanpham = 'OH031' and soluong >= 150
or masanpham in ('EH085','T302201014') and soluong >= 100
or masanpham in ('EH084','T302201018') and soluong >= 100
or masanpham = 'OH044' and soluong >= 100
or masanpham = 'EH086' and soluong >= 30
;