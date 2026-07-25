CREATE VIEW `spatial-vision-343005.warehouse.f_phan_tich_ecom_rfm`
AS with data_kh_ngoai_mcp as (
select makhdms,kenhphu,kenh,tinh,khuvuc, from `staging.d_manual_kh_ngoai_mcp_phantich_ecom` )
,
sales as (
select 
makhdms,
-- thang,
sum(doanhsochuavat) as doanhsochuavat,
min(Case when is_ecom='Ecom' then ngaychungtu else null end) as ngay_dat_don_dautien,
max(Case when is_ecom='Ecom' then ngaychungtu else null end) as ngay_dat_don_cuoicung,
sum(Case when is_ecom='Ecom' then doanhsochuavat else 0 end) as ds_ecom,
count(distinct Case when is_ecom='Ecom' then sodondathang else null end) sl_dh_ecom,
count(distinct ngaychungtu) as tan_suat_ngay_dat,--tần suất giao dịch thường xuyên của khách hàng khi đặt hàng
 from `warehouse.f_sales_crs` a 
where ngaychungtu >='2024-07-01' and makenh_moi in ('TP')
and is_ecom='Ecom'
group by all
)
,

mapping as (
select 
a.*,
sl_dh_ecom,

ifnull(ngay_dat_don_dautien,'2024-07-01') as ngay_dat_don_dautien,
ifnull(ngay_dat_don_cuoicung,'2024-07-01') as ngay_dat_don_cuoicung,
round(safe_divide( if(ds_ecom =0 or ds_ecom is null,1,sl_dh_ecom),date_diff(current_date("+7"),date(ifnull(ngay_dat_don_dautien,'2024-07-01')),day)),2) as tan_suat_datdon, --- từ ngày mua đơn hàng đầu tiên đến ngày hiện tại
ifnull(b.doanhsochuavat,0) as doanhsochuavat,
-- round(ifnull(b.doanhsochuavat,0)/6.5,2) as avg_doanhsochuavat_thang,
date_diff(current_date("+7"),date(ifnull(ngay_dat_don_cuoicung,'2024-07-01')),day) as rfm_recency,
ifnull(tan_suat_ngay_dat,0) as rfm_frequency,
ifnull(b.ds_ecom,0) as rfm_monetary,
round(ifnull(b.ds_ecom,0)/6.5,2) as avg_ds_ecom_thang,

 from data_kh_ngoai_mcp a 
LEFT JOIN sales b on a.makhdms =b.makhdms
order by ds_ecom desc
)
,
cal_mapping as (
select *,
Case when rfm_monetary <> 0 then
rank() over (partition by rfm_monetary <> 0 order by rfm_recency desc) 
else 0 end as rank_rr,
Case when rfm_monetary <> 0 then
rank() over (partition by rfm_monetary <> 0  order by rfm_frequency) else 0 end  as rank_rf,
Case when rfm_monetary <> 0 then
rank() over (partition by rfm_monetary <> 0  order by rfm_monetary) else 0 end  as rank_rm,

 from mapping
--  where rfm_monetary <> 0
 order by rfm_monetary desc
)
,
max_rank as (
select *,
Case when rfm_monetary <> 0 then
max(rank_rr) over (partition by rfm_monetary <> 0 ) else null end   as max_rr,
Case when rfm_monetary <> 0 then
max(rank_rf) over (partition by rfm_monetary <> 0 ) else null end   as max_rf,
Case when rfm_monetary <> 0 then
max(rank_rm) over (partition by rfm_monetary <> 0 ) else null end   as max_rm

from cal_mapping
),
diem_pl as (
select *,
rank_rr/max_rr * 0.15 * 100  as diem_rr,
rank_rf/max_rf * 0.28 * 100 as diem_rf,
rank_rm/max_rm * 0.57 * 100 as diem_rm,
ifnull( round((rank_rr/max_rr * 0.15 * 100 + rank_rf/max_rf * 0.28 * 100 + rank_rm/max_rm * 0.57 * 100 ) * 0.05,2),0) as diem_xh_kh
from max_rank
),

phanloai_kh as (
select *,
Case 
  when rfm_monetary = 0 then 'Mất khách hàng'
  when diem_xh_kh >=4.5 then 'Khách hàng hàng đầu'
  when diem_xh_kh < 4.5 and diem_xh_kh >=4 then 'Khách hàng có giá trị cao'
  when diem_xh_kh < 4 and diem_xh_kh >=3 then 'Khách hàng có giá trị trung bình'
  when diem_xh_kh < 3 and diem_xh_kh >=1.6 then 'Khách hàng có giá trị thấp'
  when diem_xh_kh < 1.6 and diem_xh_kh > 0 then 'Khách hàng có giá trị rất thấp'
else null end as pl_kh,
Case 
  when rfm_monetary = 0 then 0
  when diem_xh_kh >=4.5 then 5
  when diem_xh_kh < 4.5 and diem_xh_kh >=4 then 4
  when diem_xh_kh < 4 and diem_xh_kh >=3 then 3
  when diem_xh_kh < 3 and diem_xh_kh >=1.6 then 2
  when diem_xh_kh < 1.6  and diem_xh_kh > 0 then 1
else 0 end as pl_kh_int,
 from diem_pl
)

select * from phanloai_kh;