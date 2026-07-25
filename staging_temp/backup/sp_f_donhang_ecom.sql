CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_donhang_ecom()
BEGIN

TRUNCATE TABLE staging_temp.f_donhang_ecom_temp;
INSERT INTO staging_temp.f_donhang_ecom_temp(

-- Create or replace table staging_temp.f_donhang_ecom_temp
-- partition by date(ngaychungtu)
-- as

with data_leadtime as 
(
  select distinct ordernbr, status_dv as trangthaigiaohang,ngaygiaohang from `warehouse.f_leadtime_new_detail1` 
  where ngayphathanhhd >='2024-07-01'
)

select 
a.*except(manv,tencvbh,crm,scrm,ncxm,hoadon,updated_at),
hoadon as sohoadon,
manv as macrs,
tencvbh as tencvbhcrs,
crm as ma_crm,
scrm as ma_scrm,
ncxm as ma_ncxm,
b.trangthaigiaohang,
b.ngaygiaohang,
ifnull(c.type,'ecom') as type ,
d.classid,
timestamp(current_datetime("+7")) as updated_at,
 from `warehouse.f_sales_crs` a 
 LEFT JOIN data_leadtime b on a.sodondathang = b.ordernbr
 LEFT JOIN `staging.d_master_khachhang` d on d.custid = a.makhdms
 LEFT JOIN `staging.f_crawl_order_ecom` c on a.sodondathang = c.code_dms and c.code_dms is not null
where is_ecom ='Ecom' 
and ngaychungtu >='2023-01-01' 

);

Create or replace table `warehouse.f_donhang_ecom`
copy `staging_temp.f_donhang_ecom_temp`;
End;