CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_tongket_tichluy_mt()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_tongket_tichluy_mt_temp`;


 INSERT INTO `staging_temp.f_tongket_tichluy_mt_temp`

(   


-- create or replace table staging_temp.f_tongket_tichluy_mt_temp as

/*
-  Chuỗi MT (NT): áp dụng tất cả sản phẩm
   >= 100.000.000 tr CK 1% (cấn trừ đơn hàng)					
   >= 800.000.000 tr CK 1,5% (cấn trừ đơn hàng)		

-  Chuỗi Long châu
Ebysta: DS quý >= 350.000.000 CK 10% (cấn trừ đơn hàng)

-  CHUỖI PHAMARCITY - QUÝ 3/2023
Ebysta			DS quý >= 2.500.000.000 CK 10% (cấn trừ đơn hàng)	
Tất cả sp		>= 2.500.000.000 CK 1% (cấn trừ đơn hàng)		

- MERAKI - QUÝ 3/2023
Tất cả SP  >= 500.000.000 CK 1% doanh số trước VAT

- CHUỖI AN KHANG - QUÝ 3/2023
Ebysta  DS Ebysta (trước VAT) >= 25.000.000đ CK 10%
Shema 100, 200  DS Shema, lá đôi (100ml/200ml) >= 25.000.000 Shema 100ml CK 9%, Shema 200ml CK 13%

- MEDX - QUÝ 3/2023
Tất cả sp  >= 2 tỷ CK 1% doanh số trước VAT

- TRUNG SƠN - QUÝ 3/2023
Tất cả sp >= 500.000.000đ CK 1% doanh số trước VAT
*/
with 

data_kh as 
(
  select 
custid as makhdms,
Case 
    when a.custid in ('007449','007447','007569','007568','007213') then 'Wincommerce'
    when a.custid in ('MC007') then 'MT-Chuỗi NT'
    when a.custid in ('M0318001','004659') then 'Long Châu'
    when a.custid in ('MC013','004677') then 'Pharmacity'
    when a.custid in ('002193','002065') then 'Meraki'
    when a.custid in ('004802','004718','MC018') then 'An Khang'
    when a.custid in ('005732','P4724-0337','004680','005735') then 'Med'
    when a.custid in ('N07102074') then 'Trung Sơn'
    when a.custid in ('MC017') then 'Guardian'
    else null 
end as phanloai_kh,
a.branchid,
a.statedescr,
a.custname,
a.custidinvoice,
a.custnameinvoice,
a.hcoid
From `staging.d_master_khachhang` a
 where custid in('MC007','M0318001','004659','004802','004718','MC018','002193','002065','MC013','004677','005732','P4724-0337','004680','005735','N07102074','MC017','007449','007447','007569','007568','007213')

),

data_f_sales as (
  select 
  makhdms,
  ngaychungtu
  ,masanpham,
  doanhsochuavat 
  from `staging.f_sales` 
  where ngaychungtu >='2023-10-01' and ngaychungtu <'2024-01-01'
),

data_sales as (
select 
a.*,
sum(
  Case 
      when  extract(month from ngaychungtu)=10 then doanhsochuavat else 0 end
  ) as doanhsochuavat_t10,
sum(
  Case 
      when extract(month from ngaychungtu)=11 then doanhsochuavat else 0 end
  ) as doanhsochuavat_t11,
sum(
  Case 
      when extract(month from ngaychungtu)=12 then doanhsochuavat else 0 end
  ) as doanhsochuavat_t12,

sum(
  Case 
    when masanpham='EH115' and extract(month from ngaychungtu)=10 then doanhsochuavat else 0 end
) as doanhsochuavat_ebysta_t10,
sum(
  Case 
    when masanpham='EH115' and extract(month from ngaychungtu)=11 then doanhsochuavat else 0 end
) as doanhsochuavat_ebysta_t11,
sum(
  Case 
    when  masanpham='EH115' and extract(month from ngaychungtu)=12 then doanhsochuavat else 0 end
) as doanhsochuavat_ebysta_t12,
sum(
  Case 
    when masanpham in ('OH074','OH075','OH077','OH078','T302101005','T302101006','T302101007','T302101008') and extract(month from ngaychungtu)=10 then doanhsochuavat else 0 end
) as doanhsochuavat_ladoi_t10,
sum(
  Case 
    when masanpham in ('OH074','OH075','OH077','OH078','T302101005','T302101006','T302101007','T302101008') and extract(month from ngaychungtu)=11 then doanhsochuavat else 0 end
) as doanhsochuavat_ladoi_t11,
sum(
  Case 
    when  masanpham in ('OH074','OH075','OH077','OH078','T302101005','T302101006','T302101007','T302101008') and extract(month from ngaychungtu)=12 then doanhsochuavat else 0 end
) as doanhsochuavat_ladoi_t12,

sum(ifnull(doanhsochuavat,0)) as doanhsochuavat,
sum(
  Case when masanpham='EH115' then doanhsochuavat
       else 0 end
    ) as doanhsochuavat_ebysta,
sum(
  Case when masanpham in ('OH074','OH075','T302101005','T302101006') then doanhsochuavat
       else 0 end
    ) as doanhsochuavat_ladoi_100ml,
sum(
  Case when masanpham in ('OH077','OH078','T302101007','T302101008') then doanhsochuavat
       else 0 end
    ) as doanhsochuavat_ladoi_200ml,
sum(
  Case 
    when  masanpham in ('OH074','OH075','OH077','OH078','T302101005','T302101006','T302101007','T302101008')  then doanhsochuavat else 0 end
) as doanhsochuavat_ladoi,

 from 
 data_kh a
 LEFT JOIN data_f_sales b on a.makhdms =b.makhdms
group by 1,2,3,4,5,6,7,8
),
chietkhau as (
select 
  a.*,
  Case 
    -- Khách hàng MT chuỗi NT
    when makhdms ='MC007'and sum(doanhsochuavat) over (partition by phanloai_kh ) >= 800000000 then 0.015
    when makhdms ='MC007'and sum(doanhsochuavat) over (partition by phanloai_kh )  >= 100000000 then 0.01
      -- Khách hàng Pharmacity
    when makhdms in ('MC013','004677') and sum(doanhsochuavat) over (partition by phanloai_kh )  >= 2500000000 then 0.01
      -- Khách hàng Meraki
    when makhdms in ('002193','002065') and sum(doanhsochuavat) over (partition by phanloai_kh )  >= 500000000 then 0.01
      -- Khách hàng Med
    when makhdms in ('005732','P4724-0337','004680','005735') and sum(doanhsochuavat) over (partition by phanloai_kh )  >= 2000000000 then 0.01
      -- Khách hàng Trung sơn
    when makhdms in ('N07102074') and sum(doanhsochuavat) over (partition by phanloai_kh )  >= 500000000 then 0.01
  else 0 end as chietkhau_datthuong,

    Case 
    -- Khách hàng FPT Long Châu
    when makhdms in ('M0318001','004659') and sum(doanhsochuavat_ebysta) over (partition by phanloai_kh )  >= 350000000 then 0.1
    -- Khách hàng Pharmacity
    when makhdms in ('MC013','004677') and sum(doanhsochuavat_ebysta) over (partition by phanloai_kh ) >= 2500000000 then 0.1
     -- Khách hàng An Khang
    when makhdms in ('004802','004718','MC018') and sum(doanhsochuavat_ebysta) over (partition by phanloai_kh ) >= 25000000 then 0.1   
  else 0 end as chietkhau_datthuong_ebysta,
Case 
     -- Khách hàng An Khang
    when makhdms in ('004802','004718','MC018') and sum(doanhsochuavat_ladoi) over (partition by phanloai_kh ) >= 25000000 then 0.09   
  else 0 end as chietkhau_datthuong_ladoi_100ml,
Case 
     -- Khách hàng An Khang
    when makhdms in ('004802','004718','MC018') and sum(doanhsochuavat_ladoi) over (partition by phanloai_kh )  >= 25000000 then 0.13   
  else 0 end as chietkhau_datthuong_ladoi_200ml,

from data_sales a
)
select 
a.*,
Case 
  -- Khách hàng MT chuỗi NT
  when makhdms ='MC007' then round(doanhsochuavat * chietkhau_datthuong,0) 
   -- Khách hàng Pharmacity
  when makhdms in ('MC013','004677') then round(doanhsochuavat * chietkhau_datthuong,0) 
      -- Khách hàng Meraki
    when makhdms in ('002193','002065') then round(doanhsochuavat * chietkhau_datthuong,0) 
      -- Khách hàng Med
    when makhdms in ('005732','P4724-0337','004680','005735') then round(doanhsochuavat * chietkhau_datthuong,0) 
      -- Khách hàng Trung sơn
    when makhdms in ('N07102074') then round(doanhsochuavat * chietkhau_datthuong,0) 
else 0 
end as sotien_thuong,
Case 
   -- Khách hàng FPT Long Châu
  when makhdms in ('M0318001','004659') then round(doanhsochuavat_ebysta * chietkhau_datthuong_ebysta,0)
   -- Khách hàng Pharmacity
  when makhdms in ('MC013','004677') then round(doanhsochuavat_ebysta * chietkhau_datthuong_ebysta,0)  
       -- Khách hàng An Khang
  when makhdms in ('004802','004718','MC018') then round(doanhsochuavat_ebysta * chietkhau_datthuong_ebysta,0)  
else 0 
end as sotien_thuong_ebysta,
Case
       -- Khách hàng An Khang
  when makhdms in ('004802','004718','MC018') then round(doanhsochuavat_ladoi_100ml * chietkhau_datthuong_ladoi_100ml + doanhsochuavat_ladoi_200ml * chietkhau_datthuong_ladoi_200ml,0)  
else 0 
end as sotien_thuong_ladoi,
(select max(inserted_at) from `staging.f_sales` where ngaychungtu >='2023-10-01' and ngaychungtu <'2024-01-01' and inserted_at is not null) as inserted_at 
from chietkhau a


 );

Create or replace table `warehouse.f_tongket_tichluy_mt`

copy `staging_temp.f_tongket_tichluy_mt_temp`;




END;