CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_doanhso_hangngay()
BEGIN 
  TRUNCATE TABLE staging_temp.f_doanhso_hangngay_temp;

 INSERT INTO staging_temp.f_doanhso_hangngay_temp(

-- Create table staging_temp.f_doanhso_hangngay_temp
-- as

with data_doanhso_quy as 
(

select makhdms,
date_trunc(date(ngaychungtu),quarter) as quarter_,
sum(doanhsochuavat) as doanhso_quy
from `staging.f_sales` a
  WHERE a.ngaychungtu >= '2023-01-01' 
  AND LEFT(a.masanpham,1) != 'V' 
      AND a.manv NOT IN ( 'GH001', 'MA001', 'MA002', 'QUYNHPTA') 
     -- and a.phanam not in ( 'PHA NAM')
      AND makenhkh not in ( 'NB','OTH_LAB')
and extract(quarter from ngaychungtu) = extract(quarter from date_sub(current_date("+7"),interval 1 day))
and extract(year from ngaychungtu) = extract(year from date_sub(current_date("+7"),interval 1 day))
group by 1,2
),
data_doanhso_thang as 
(

select makhdms,
date_trunc(ngaychungtu,month) as month_,
sum(doanhsochuavat) as doanhso_thang
from `staging.f_sales` a
  WHERE a.ngaychungtu >= '2023-01-01' 
  AND LEFT(a.masanpham,1) != 'V' 
      AND a.manv NOT IN ( 'GH001', 'MA001', 'MA002', 'QUYNHPTA') 
     -- and a.phanam not in ( 'PHA NAM')
      AND makenhkh not in ( 'NB','OTH_LAB')
and date_trunc(date(ngaychungtu),month) = date_trunc(date_sub(current_date("+7"),interval 1 day),month)
group by 1,2
),
data_doanhso_ngay as 
(

select makhdms,
date(ngaychungtu) as day_,
sum(doanhsochuavat) as doanhso_ngay
from `staging.f_sales` a
  WHERE a.ngaychungtu >= '2023-01-01' 
  AND LEFT(a.masanpham,1) != 'V' 
      AND a.manv NOT IN ( 'GH001', 'MA001', 'MA002', 'QUYNHPTA') 
     -- and a.phanam not in ( 'PHA NAM')
      AND makenhkh not in ( 'NB','OTH_LAB')
and date(ngaychungtu) = date_sub(current_date("+7"),interval 1 day)
group by 1,2
)
select d.channel,a.makhdms as custid,a.*except(makhdms),
  ifnull(b.doanhso_thang,0) as doanhso_thang,
  ifnull(c.doanhso_ngay,0) as doanhso_ngay,
(select max(inserted_at) from `staging.f_sales` where ngaychungtu > '2023-01-01') as inserted_at
from data_doanhso_quy a 
LEFT JOIN data_doanhso_thang b on a.makhdms=b.makhdms
LEFT JOIN data_doanhso_ngay c on a.makhdms =c.makhdms
LEFT JOIN `staging.d_master_khachhang` d on a.makhdms = d.custid

  );

Create or replace table `warehouse.f_doanhso_hangngay`

copy `staging_temp.f_doanhso_hangngay_temp`;


End;