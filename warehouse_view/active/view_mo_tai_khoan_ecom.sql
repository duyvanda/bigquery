CREATE VIEW `spatial-vision-343005.warehouse.view_mo_tai_khoan_ecom`
AS with

ecom as 
(
    select 
      distinct date(created_at) as ngayactive,
      customer_phone,
      customer_code,
      follow_phone,
      row_number() over (partition by customer_code order by created_at asc) as loc
    from `spatial-vision-343005.staging.f_crawl_activate_ecom`
    QUALIFY row_number() over (partition by customer_code order by created_at asc)= 1
)


, dscv as 

(
  select makhdms, sum(doanhsochuavat) as doanhsochuavat from `warehouse.f_raw_data_sales_yoy` where date(ngaychungtu)>= '2021-01-01' 
  and is_ecom = 'Ecom'
  group by all 
)


select 
c.custid, 
c.custname,
c.channel,
c.shoptype,
c.territorydescr,
c.statedescr,
c.active,
e.ngayactive,
e.customer_phone,
e.customer_code,
e.follow_phone,
ds.doanhsochuavat
from `staging.d_master_khachhang` c
LEFT JOIN ecom e on c.custid = e.customer_code
LEFT JOIN dscv ds on ds.makhdms = c.custid;