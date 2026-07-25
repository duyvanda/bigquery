CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_doanhthu_hangngay()
BEGIN 
  TRUNCATE TABLE staging_temp.f_doanhthu_hangngay_temp;

 INSERT INTO staging_temp.f_doanhthu_hangngay_temp(

-- create table staging_temp.f_doanhthu_hangngay_temp

-- as

with data_doanhthu_quy as 
(
select custid,
date_trunc(orderdate,quarter) as quarter_,

sum(sotien_da_thanhtoan) as sotien_da_thanhtoan_quy from `staging_temp.d_rawdata_debt_detail`
where extract(quarter from orderdate) = extract(quarter from date_sub(current_date("+7"),interval 1 day))
and extract(year from orderdate) = extract(year from date_sub(current_date("+7"),interval 1 day))
group by 1 ,2
),

data_doanhthu_thang as 
(
select custid,
date_trunc(orderdate,month) as month_,

sum(sotien_da_thanhtoan) as sotien_da_thanhtoan from `staging_temp.d_rawdata_debt_detail`
where date_trunc(orderdate,month) = date_trunc(date_sub(current_date("+7"),interval 1 day),month)
group by 1 ,2
),

data_doanhthu_ngay as 
(
select custid,
orderdate as day_,

sum(sotien_da_thanhtoan) as sotien_da_thanhtoan from `staging_temp.d_rawdata_debt_detail`
where orderdate = date_sub(current_date("+7"),interval 1 day)
group by 1 ,2
)

select d.channel,a.*,
  ifnull(b.sotien_da_thanhtoan,0) as sotien_da_thanhtoan_thang,
  ifnull(c.sotien_da_thanhtoan,0) as sotien_da_thanhtoan_ngay,
  date_sub(current_date("+7"),interval 1 day)  as inserted_at
from data_doanhthu_quy a 
LEFT JOIN data_doanhthu_thang b on a.custid =b.custid
LEFT JOIN data_doanhthu_ngay c on a.custid = c.custid
LEFT JOIN `staging.d_master_khachhang` d on a.custid = d.custid
where d.channel not in ('NB','OTH_LAB') and d.custid not like 'DS%'
  );

Create or replace table `warehouse.f_doanhthu_hangngay`

copy `staging_temp.f_doanhthu_hangngay_temp`;


End;