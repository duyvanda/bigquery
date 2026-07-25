CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_tongket_tichluy_thang_mt()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_tongket_tichluy_thang_mt_temp`;


 INSERT INTO `staging_temp.f_tongket_tichluy_thang_mt_temp`

(   

-- create table warehouse.f_tongket_tichluy_thang_mt as

with 
base_date as (
    select
    distinct
        date(date_trunc(day,month)) as thang
    from
        unnest(
            GENERATE_DATE_ARRAY(
                date_sub(current_date("+7"), interval 4 month),
                date_add(current_date("+7"), interval 4 month),
                INTERVAL 1 DAY
            )
        ) as day
),

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

data_kh_thang as 
(
select * from base_date a 
LEFT JOIN data_kh b on 1=1
),

data_f_sales as (
  select 
  makhdms,
  ngaychungtu,
  date(date_trunc(ngaychungtu,month)) as thang,
  masanpham,
  doanhsochuavat 
  from `staging.f_sales` 
  where ngaychungtu >='2023-10-01' and ngaychungtu <'2024-01-01'
),

data_sales as (
select 
a.*,
sum(
  Case 
    when trim(upper(c.nhomcpa)) ='XOS' then doanhsochuavat else 0 end
) as doanhsochuavat_xos,
sum(ifnull(doanhsochuavat,0)) - sum(
  Case 
    when trim(upper(c.nhomcpa)) ='XOS' then doanhsochuavat else 0 end
) as doanhsochuavat_conlai,

sum(ifnull(doanhsochuavat,0)) as doanhsochuavat

 from 
 data_kh_thang a
 LEFT JOIN data_f_sales b on a.makhdms =b.makhdms and b.thang=a.thang
 LEFT JOIN `staging.d_nhom_sp_trading` c on c.masanpham =b.masanpham
group by 1,2,3,4,5,6,7,8,9
),
chietkhau as (
select 
a.*,
Case 
    when phanloai_kh in ('Long Châu') and sum(doanhsochuavat_xos) over (partition by thang,phanloai_kh) >= 30000000 then 0.06
    when phanloai_kh in ('Meraki') and sum(doanhsochuavat_xos) over (partition by thang,phanloai_kh) >= 20000000 then 0.04
    when phanloai_kh in ('An Khang') and sum(doanhsochuavat_xos) over (partition by thang,phanloai_kh) >= 3000000 then 0.06
    else 0 
end as chietkhau_xos,

Case 
    when phanloai_kh in ('Long Châu') and sum(doanhsochuavat_conlai) over (partition by thang,phanloai_kh) >= 20000000 then 0.11
    when phanloai_kh in ('Meraki') and sum(doanhsochuavat_conlai) over (partition by thang,phanloai_kh) >= 5000000 then 0.08
    when phanloai_kh in ('An Khang') and sum(doanhsochuavat_conlai) over (partition by thang,phanloai_kh) >= 2000000 then 0.11
    else 0 
end as chietkhau_conlai

 from data_sales a )

 select  
 *,
 round(a.doanhsochuavat_xos * chietkhau_xos,0) as sotien_thuong_xos,
 round(a.doanhsochuavat_conlai * chietkhau_conlai,0) as sotien_thuong_conlai,
 (select max(inserted_at) from `staging.f_sales` where ngaychungtu >='2023-10-01' and ngaychungtu <'2024-01-01' and inserted_at is not null) as inserted_at 
 from chietkhau a

  );

Create or replace table `warehouse.f_tongket_tichluy_thang_mt`

copy `staging_temp.f_tongket_tichluy_thang_mt_temp`;


END;