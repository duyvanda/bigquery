CREATE VIEW `spatial-vision-343005.warehouse.view_input_muc_tieu_google_sheet_mt`
AS with 
danh_sach_mt as 
(
  select 'MR3066_KN' as manv,'Dương Thanh Sơn_KN' as tencvbh,'MR3066' as supid,'Dương Thanh Sơn' as tenquanlytt UNION ALL
  select 'MR3070' as manv,'Nguyễn Thị Thạch Thảo' as tencvbh,'MR3066' as supid,'Dương Thanh Sơn' as tenquanlytt UNION ALL
  select 'MR3168' as manv,'Trần Văn Mạnh' as tencvbh,'MR3066' as supid,'Dương Thanh Sơn' as tenquanlytt UNION ALL
  select 'MR0868_KN' as manv,'Nguyễn Thị Nga_KN' as tencvbh,'MR0868' as supid,'Nguyễn Thị Nga' as tenquanlytt UNION ALL
  select 'MR3160' as manv,'Nguyễn Tuấn Anh' as tencvbh,'MR0868' as supid,'Nguyễn Thị Nga' as tenquanlytt UNION ALL
  select 'MR3185' as manv,'Trần Nam Tiên' as tencvbh ,'MR0868' as supid,'Nguyễn Thị Nga' as tenquanlytt
)
,

sales as (
  select makhdms,sum(doanhsochuavat) as ds from `warehouse.f_sales_crs`  
  where date(ngaychungtu) between date(date_trunc(current_date("+7"),month))  and date(date_trunc(current_date("+7"),month) + interval 1 month - interval 1 day)
  group by all
)
,
sales_previous as (
  select makhdms,sum(doanhsochuavat) as ds from `warehouse.f_sales_crs` 
  where date(ngaychungtu) between date(date_trunc(current_date("+7"),month) - interval 1 month)  and date(date_trunc(current_date("+7"),month) - interval 1 day)
  group by all
)
,
congno as (
  select custid,sum(so_du_chungtu) as congno from `warehouse.f_congno_rawdata_mt` group by all
)

select 
d.manv as slsperid,
d.tencvbh,
d.supid,
d.tenquanlytt,
a.custid,
a.custname,
Case 
    when a.shoptype in ('SI24','ECOM') then 'ECOM-SI' 
    when a.shoptype in ('FMCG','CCD') then 'FMCG'  
else a.shoptype end as kenh_phu,
a.channel,
a.statedescr,
0.0 as muc_tieu_thang_trc,
ifnull(e.ds,0) as thuc_hien_thang_trc,
0.0 as thuc_hien_tren_muc_tieu_thang_trc,
concat("https://ds.merapgroup.com/reportscreen/21?params=%257B%22df25%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580MR0000%22%2C%22df26%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580",a.custid,"%22%257D") as link_chi_tiet_doanh_so,
ifnull(c.congno,0) as du_no,
ifnull(b.ds,0) as thuc_hien_mtd,
concat("https://ds.merapgroup.com/reportscreen/103?params=%257B%22df91%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580MR0000%22%2C%22df114%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580",a.custid,"%22%257D") as link_chi_tiet_no,
from `staging.d_master_khachhang` a
LEFT JOIN sales b on a.custid = b.makhdms
LEFT JOIN congno c on a.custid = c.custid
LEFT JOIN sales_previous e on a.custid = e.makhdms
LEFT JOIN danh_sach_mt d on 1 = 1
where a.channel in ('MT')
and a.active = 'Active'
and a.pubcustid is not null
order by pubcustid asc;