CREATE VIEW `spatial-vision-343005.warehouse.f_view_khachhang_tm_ck`
AS with
mapping_customer as (
select a.*except(paymentsform),
b2.dueintnv as songay_thanhtoan,

Case when b1.statedescr in ('Thành phố Cần Thơ','Đồng Nai','Khánh Hòa','Nghệ An',
'Thành phố Đà Nẵng','Thành phố Hà Nội','Thành phố Hồ Chí Minh') then 'VP chi nhánh'
else 'Tỉnh' end as is_diadiem,
b1.channel,
b1.shoptype,
b1.statedescr,
b1.custname,
b1.paymentsform,
b1.territorydescr,
b1.active

 from `staging_temp.d_rawdata_debt`  a
-- LEFT JOIN `staging.d_master_khachhang2022` b on a.custid =b.custid and date(dateoforder) <'2023-01-01'
LEFT JOIN `staging.d_master_khachhang` b1 on a.custid =b1.custid and date(dateoforder)>='2023-01-01'
LEFT JOIN staging.d_manual_terms_detail b2 on b2.termsid = a.Terms

where
b1.channel not in ('NB','OTH_LAB','EXP') 
and a.custid not like 'DS%'
and (so_du_dh >1000 or so_du_dh <-1000) 
and b1.paymentsform in('Tiền Mặt/Chuyển Khoản','TM/CK/CTH')
and b1.active in ('Active','Inactive')
-- and a.paymentsform ='C'
),

mapping_mau_no as (
select *, 
Case 
    when songay_thanhtoan <=3 and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 1 day)   
    when songay_thanhtoan <=3 and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 3 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 2 day) 
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 4 day) 

    when songay_thanhtoan <=15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 2 day) 
    when songay_thanhtoan <=15
     and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 4 day) 
    
    when songay_thanhtoan > 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 2 day) 
     when songay_thanhtoan > 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 4 day) 
 
  else  null

 end as thoi_diem_no_vang,


 Case 
    when songay_thanhtoan <=3 and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 6 day)   
    when songay_thanhtoan <=3 and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 8 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 7 day) 
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 9 day) 

    when songay_thanhtoan <= 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 17 day) 
    when songay_thanhtoan <= 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 19 day) 
    
    when songay_thanhtoan > 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 32 day) 
     when songay_thanhtoan > 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 34 day) 
 
 
  else  null

 end as thoi_diem_no_do,
 Case 
    when songay_thanhtoan <= 3 and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 10 day)   
    when songay_thanhtoan <= 3 and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 12 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 11 day) 
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 13 day) 

    when songay_thanhtoan <= 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 32 day) 
    when songay_thanhtoan <= 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 34 day) 
    
    when songay_thanhtoan > 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 62 day) 
     when songay_thanhtoan > 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 64 day) 

  else  null
 end as thoi_diem_no_den
 from mapping_customer ),

mapping_phanloaino as (

 select *,
Case when (select * from `staging.d_current_table`)  
 >= thoi_diem_no_den and (so_du_dh > 1000 or so_du_dh < -1000) then 'Nợ đen'
     when (select * from `staging.d_current_table`)
  < thoi_diem_no_den and (so_du_dh > 1000 or so_du_dh < -1000)  and (select * from `staging.d_current_table`)
 >= thoi_diem_no_do  then 'Nợ đỏ'
     when (select * from `staging.d_current_table`)
  < thoi_diem_no_do and (so_du_dh > 1000 or so_du_dh < -1000)  and (select * from `staging.d_current_table`)
  >= thoi_diem_no_vang  then 'Nợ vàng'
     when (select * from `staging.d_current_table`)
  < thoi_diem_no_vang and (so_du_dh > 1000 or so_du_dh < -1000)  then 'Nợ xanh'

     when date(orderdate) >= thoi_diem_no_den   and (so_du_dh <= 1000 and so_du_dh >= -1000)   then 'Nợ đen'
     when date(orderdate)  < thoi_diem_no_den   and (so_du_dh <= 1000 and so_du_dh >= -1000)   and date(orderdate)  >= thoi_diem_no_do  then 'Nợ đỏ'
     when date(orderdate)  < thoi_diem_no_do   and (so_du_dh <= 1000 and so_du_dh >= -1000)   and date(orderdate)  >= thoi_diem_no_vang   then 'Nợ vàng'
     when date(orderdate)  < thoi_diem_no_vang and (so_du_dh <= 1000 and so_du_dh >= -1000)     then 'Nợ xanh'
     when date(orderdate) is null and (so_du_dh <= 1000 and so_du_dh >= -1000) then 'Nợ xanh'
      when date(orderdate) is null
      and thoi_diem_no_den <= (select * from `staging.d_current_table`)
 then 'Nợ đen'
     when date(orderdate) is null and thoi_diem_no_do <= (select * from `staging.d_current_table`)
 then 'Nợ đỏ'
     when date(orderdate) is null and thoi_diem_no_vang <= (select * from `staging.d_current_table`)
 then 'Nợ vàng'
     when date(orderdate) is null and thoi_diem_no_vang >(select * from `staging.d_current_table`)
 then 'Nợ xanh'
else null
end as phanloaino,

date_trunc(dateoforder,month) as thang_chungtu,
date_trunc(orderdate,month) as thang_thu

  from mapping_mau_no 
),

congno as (
select  *,
Case when so_du_dh >1000 or so_du_dh <-1000 then date_diff((select * from `staging.d_current_table`), date(dateoforder),day)
     when  (so_du_dh <=1000 and so_du_dh >=-1000) then date_diff(orderdate, date(dateoforder),day)

      else 0 end as thoigian_no,
Case when so_du_dh >1000 or so_du_dh <-1000 then date_diff((select * from `staging.d_current_table`), date(dateoforder),month)
      when  (so_du_dh <=1000 and so_du_dh >=-1000) then date_diff(orderdate, date(dateoforder),month)

      else 0 end as thoigian_no_thang,
Case when so_du_dh >1000 or so_du_dh <-1000 and phanloaino in('Nợ vàng','Nợ đỏ','Nợ đen') then date_diff((select * from `staging.d_current_table`), date(thoi_diem_no_vang),day)
      when (so_du_dh <=1000 and so_du_dh >=-1000) and phanloaino in('Nợ vàng','Nợ đỏ','Nợ đen') then date_diff(orderdate, date(thoi_diem_no_vang),day)
      else 0 end as thoigian_noqh,
Case when phanloaino ='Nợ xanh' then so_du_chungtu else 0 end as no_xanh,
Case when phanloaino ='Nợ vàng' then so_du_chungtu else 0 end as no_vang,
Case when phanloaino ='Nợ đỏ' then so_du_chungtu else 0 end as no_do,
Case when phanloaino ='Nợ đen' then so_du_chungtu else 0 end as no_den,
Case when phanloaino in('Nợ vàng','Nợ đỏ','Nợ đen') then so_du_chungtu else 0 end as no_qh,

 from mapping_phanloaino
),

result_congno as (
select 
custid,
custname,
channel,
shoptype,
statedescr,
paymentsform,
territorydescr,
active,
songay_thanhtoan,
phanloaino,
ordnbr,
dateoforder,
sum(no_xanh) as no_xanh,
sum(no_vang) as no_vang,
sum(no_do) as no_do,
sum(no_den) as no_den,
sum(no_qh) as no_qh,
sum(no_xanh) as no_tronghan,
sum(no_qh) + sum(no_xanh) as du_no_hientai,
-- round(avg(thoigian_no),1) as songayno_bq,
-- round(avg(thoigian_no_thang),1) as songayno_bq_thang,
-- round(safe_divide( ( sum(no_do) + sum(no_den) ) , (sum(no_qh) + sum(no_xanh)) )*100,1)  as tile_noxau,

from congno group by all
),

doanhso_hientai as 
 (
 select 
 makhdms,
sum(doanhsochuavat) as doanhso 
from `staging.f_sales`  a 
where 
   LEFT(a.masanpham,1) != 'V' 
      AND a.manv NOT IN ( 'GH001', 'MA001', 'MA002', 'QUYNHPTA') 
group by all )

select 
a.*,
b.doanhso,
b.doanhso / count(a.custid) over (partition by custid) as doanhso_divide,
current_timestamp() + interval 7 hour as inserted_at
 from result_congno a 
 LEFT JOIN doanhso_hientai b on a.custid =b.makhdms
 order by a.custid;