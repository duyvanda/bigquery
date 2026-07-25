CREATE VIEW `spatial-vision-343005.warehouse.view_tong_quat_kh_page_hspl`
AS 
with dscv as 

(
  select makhdms, sum(doanhsochuavat) as doanhsochuavat from staging.f_sales where date(ngaychungtu)>= '2024-01-01'
  and date(ngaychungtu) < date(date_trunc(current_timestamp(), month))
  group by all 
)

select
a.branchid,
a.custid, 
a.custname,
a.refcustid as ma_kh_cu,
a.legalname as chu_nt_tren_gpkd,
a.personaltaxregnbr as  ma_so_thue_ca_nhan,
a.custidinvoice as ma_kh_thue,
a.custnameinvoice as ten_kh_thue,
a.taxregnbr as ma_so_thue,
a.channel as kenh,
a.shoptype as kenh_phu,
a.hcotypeid as phan_loai_hco,
a.businessscope as pham_vi_kinh_doanh,
IFNULL(a.taxdeclaration,'Chưa xác định') as loai_ma_so_thue,
case when a.legaldate = '1990-01-01' then '1900-01-01' else legaldate end as legaldate,
a.territorydescr as ten_khu_vuc,
a.statedescr as ten_tinh,
a.stocksales as tinh_trang_ma_so_thue,
a.market,
b.doanhsochuavat

from `staging.d_master_khachhang` a
LEFT JOIN dscv b on a.custid = b.makhdms
WHERE 
(
  case 
  when a.channel = 'TP' then 1
  when a.channel = 'CLC' then 1
  when a.channel = 'MT' then 1
  when a.channel = 'PCL' and hcotypeid != 'NTXQPK' then 1
  END
) = 1

AND a.active = 'Active'
AND ifnull(market,'NONE') != '08'
AND ifnull(market,'NONE') not like '%Không%';