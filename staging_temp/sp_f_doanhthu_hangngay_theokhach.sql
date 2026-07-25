CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_doanhthu_hangngay_theokhach()
BEGIN 
  TRUNCATE TABLE staging_temp.f_doanhthu_hangngay_theokhach_temp;

 INSERT INTO staging_temp.f_doanhthu_hangngay_theokhach_temp(

-- Create table staging_temp.f_doanhthu_hangngay_theokhach_temp
-- as

with data_doanhthu_ngay as 
(
select custid,
orderdate as day_,

sum(sotien_da_thanhtoan) as sotien_da_thanhtoan from `staging_temp.d_rawdata_debt_detail`
where orderdate = date_sub(current_date("+7"),interval 1 day)
group by 1 ,2
),

data_doanhthu_ngay_hientai as 
(
select custid,
orderdate as day_,
sum(sotien_da_thanhtoan) as sotien_da_thanhtoan,
 from `staging_temp.d_rawdata_debt_detail`
where orderdate = date_sub(current_date("+7"),interval 0 day)
group by 1 ,2
),

data_congno as 
(
  select custid,sum(so_du_chungtu)  as so_du_chungtu 
  from `staging_temp.d_rawdata_debt`-- where so_du_chungtu >1000 or so_du_chungtu <-1000 or sotien_da_thanhtoan <>0
  group by 1
)
select  
a.custid,
c.channel,
c.custname,
a.so_du_chungtu + ifnull(b1.sotien_da_thanhtoan,0) as so_du_chungtu,
ifnull(b.sotien_da_thanhtoan,0) as sotien_da_thanhtoan,
 from data_congno a 
LEFT JOIN data_doanhthu_ngay b on a.custid =b.custid 
LEFT JOIN data_doanhthu_ngay_hientai b1 on a.custid =b1.custid
LEFT JOIN `staging.d_master_khachhang` c on a.custid =c.custid 

where c.channel not in ('NB','OTH_LAB') and c.custid not like 'DS%'--and (so_du_chungtu >1000 or so_du_chungtu <-1000 ) 
and (a.so_du_chungtu + ifnull(b1.sotien_da_thanhtoan,0)+ b.sotien_da_thanhtoan) <>0
  );

Create or replace table `warehouse.f_doanhthu_hangngay_theokhach`

copy `staging_temp.f_doanhthu_hangngay_theokhach_temp`;

End;