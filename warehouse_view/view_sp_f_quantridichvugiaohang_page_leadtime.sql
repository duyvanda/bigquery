CREATE VIEW `spatial-vision-343005.warehouse.view_sp_f_quantridichvugiaohang_page_leadtime`
AS with cum as
(select null)

, ds_0 as
(
SELECT ifnull(sodontrahang, sodontrahang) as ma_dh, sum(doanhsochuavat) FROM `spatial-vision-343005.staging.f_sales`
where date(ngaychungtu)>= '2025-01-01'
group by all
having sum(doanhsochuavat) = 0
)

select
f.ma_dh,
  a.*,
  extract(dayofweek from a.ngaytaodon) as thutaodon,
  extract (hour from a.ngaytaodon) as giotaodon,
  c.supid,
  d.chinhanh as chinhanh_dialy,
  e.cluster_state,
  trim(a.thongtinxe) as thongtinxe_fix,
  case when role = 'LOG' and deliveryunit = 'Pha Nam' and (thongtinxe is null or thongtinxe like 'NVC%') then 'thongtinxe_sai'
       when role in ('LOG','MDS') and deliveryunit = 'Chành Xe' and (thongtinxe is null or thongtinxe like 'NVC%') then 'thongtinxe_sai'
       when role in ('LOG') and deliveryunit = 'NVC' and thongtinxe is null then 'thongtinxe_sai'
       else null end as check_ttxe

from `spatial-vision-343005.warehouse.f_overview_mds_hanh1` a
left join `spatial-vision-343005.staging.d_users`  c on a.slsperid_dv = c.manv
left join `spatial-vision-343005.staging.d_tinh` d on a.tinh = d.tinh
left join `staging.d_master_khachhang`  e on e.custid = a.custid
left join `ds_0` f on f.ma_dh = a.ordernbr
where kenh not in ('OTH_LAB', 'NB') 
and f.ma_dh is null
and a.ngaytaodon >= '2026-01-01' 
--and a.ordernbr =  'DL7-0326-02119';