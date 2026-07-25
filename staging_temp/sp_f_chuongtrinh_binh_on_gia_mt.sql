CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_binh_on_gia_mt()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_chuongtrinh_binh_on_gia_mt_temp`;


 INSERT INTO `staging_temp.f_chuongtrinh_binh_on_gia_mt_temp`

(   
-- Create or replace table staging_temp.f_chuongtrinh_binh_on_gia_mt_temp as
with 
dk2_mt as (
select ma_sp,price,tenkhachhang  from warehouse.f_chitiet_gia_mt_tren_web
qualify row_number () over (partition by tenkhachhang,ma_sp order by created_at desc) = 1
),


raw_data as (
select 
  case when lower(t1.tenkhachhang) like '%fpt long châu%' and makenhkh = 'MT' then 'Long Châu' 
      when lower(t1.tenkhachhang) like '%pharmacity%' and makenhkh = 'MT' then 'Phamacity' 
      when lower(t1.tenkhachhang) like '%trung sơn%' and makenhkh = 'MT' then 'Trung Sơn' 
      when lower(t1.tenkhachhang) like '%medx%' and makenhkh = 'MT' then '4.MedX' 
      when lower(t1.tenkhachhang) like '%guardian%' and makenhkh = 'MT' then '5.Guardian' 
      when lower(t1.tenkhachhang) like '%an khang%' and makenhkh = 'MT' then 'An Khang' 
      when t1.makhdms = '003589' and makenhkh = 'MT' then '9.ECE - Ecommerce enable'
      when lower(t1.tenkhachhang) like '%wincommerce%' and makenhkh ='MT' then '7.WinMart'
      when lower(t1.tenkhachhang) like '%meraki%' and makenhkh ='MT' then '8.Meraki'
      else 'others' end as tenkhachhang,
Case when masanpham in ('OH051') then 'T302201014'
     when masanpham in ('OH052') then 'T302201018'
     else masanpham end as ma_sp,
sum(doanhsochuavat) as doanhsochuavat,
sum(doanhsocovat) as doanhsocovat
from warehouse.f_sales_crs t1

where ngaychungtu >='2023-11-29' and makenh_moi='MT' 
and masanpham in ('OH031','OH052','T302201018','OH051','T302201014')
and (lower(t1.tenkhachhang) like '%an khang%' or lower(t1.tenkhachhang) like '%trung sơn%' or lower(t1.tenkhachhang) like '%fpt long châu%'
or lower(t1.tenkhachhang) like '%pharmacity%' )
group by 1,2
order by 1
)
select a.*
,b.descr
,b.descr1
,Case 
    when sum(doanhsochuavat) over (partition by a.tenkhachhang) >= 100000000
    and a.tenkhachhang ='Trung Sơn' then 'Đạt'
    when sum(doanhsochuavat) over (partition by a.tenkhachhang) >= 150000000
    and a.tenkhachhang !='Trung Sơn' then 'Đạt'
    else 'Không đạt' end as dk1
,Case
    when a.ma_sp ='OH031' and c.price >= 24000 then 'Đạt'
    when a.ma_sp ='T302201014' and c.price >= 30000 then 'Đạt'
    when a.ma_sp ='T302201018' and c.price >= 33000 then 'Đạt'
    else 'Không đạt' end as dk2
,'Đạt' as dk3
,'Không đạt' as tongket_quy
from raw_data a 
LEFT JOIN `staging.d_dms_master_invtid` b on a.ma_sp = b.invtid
LEFT JOIN dk2_mt c on c.ma_sp = a.ma_sp and a.tenkhachhang = c.tenkhachhang
);

Create or replace table `warehouse.f_chuongtrinh_binh_on_gia_mt`

copy `staging_temp.f_chuongtrinh_binh_on_gia_mt_temp`;

END;