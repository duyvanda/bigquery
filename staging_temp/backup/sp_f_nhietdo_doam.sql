CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_nhietdo_doam()
BEGIN 
  TRUNCATE TABLE staging_temp.f_nhietdo_doam_temp;

 INSERT INTO staging_temp.f_nhietdo_doam_temp(

-- Create table staging_temp.f_nhietdo_doam_temp
-- partition by date_filter
-- as

with data_nhietdo_doam as (
SELECT 
kho,congty,mamay,cambien,nam,thang,tuan,
round(count(nhietdo),1) as nhietdo_solando,
round(avg(nhietdo),1) as nhietdo_trungbinh,
round(sum(vuot_nhietdo),1) as nhietdo_solanvuotnguong,
round(sum(vuot_nhietdo)/count(nhietdo)*100,1) as nhietdo_tilevuotnguong,
round(count(doam),1) as doam_solando,
round(avg(doam),1) as doam_trungbinh,
round(sum(vuot_doam),1) as doam_solanvuotnguong,
round(sum(vuot_doam)/count(doam)*100,1) as doam_tilevuotnguong,

 FROM `spatial-vision-343005.staging.f_nhietdo_doam` 
--  where congty='CÔNG TY CỔ PHẦN DƯỢC PHA NAM' 
--  and kho ='Kho 438' and mamay ='MR0001-WH0002' and cambien ='S02'
 group by 1,2,3,4,5,6,7
 ),

 data_vuotnguong_tronggio as 
 (
   select kho,congty,mamay,cambien,nam,thang,tuan,
round(sum(vuot_nhietdo),1) as nhietdo_solanvuotnguong_tronggio
    FROM `spatial-vision-343005.staging.f_nhietdo_doam` 
 where 
--  congty='CÔNG TY CỔ PHẦN DƯỢC PHA NAM' 
--  and kho ='Kho 438' and mamay ='MR0001-WH0002' and cambien ='S02' and 
 trong_gio =1
 group by 1,2,3,4,5,6,7
 ),

  data_vuotnguong_ngoaigio as 
 (
   select kho,congty,mamay,cambien,nam,thang,tuan,
round(sum(vuot_nhietdo),1) as nhietdo_solanvuotnguong_ngoaigio
    FROM `spatial-vision-343005.staging.f_nhietdo_doam` 
 where 
--  congty='CÔNG TY CỔ PHẦN DƯỢC PHA NAM' 
--  and kho ='Kho 438' and mamay ='MR0001-WH0002' and cambien ='S02' and 
 trong_gio =0
 group by 1,2,3,4,5,6,7
 ),

  data_vuotnguong_tronggio_doam as 
 (
   select kho,congty,mamay,cambien,nam,thang,tuan,
round(sum(vuot_doam),1) as doam_solanvuotnguong_tronggio
    FROM `spatial-vision-343005.staging.f_nhietdo_doam` 
 where 
--  congty='CÔNG TY CỔ PHẦN DƯỢC PHA NAM' 
--  and kho ='Kho 438' and mamay ='MR0001-WH0002' and cambien ='S02' and 
 trong_gio =1
 group by 1,2,3,4,5,6,7
 ),

  data_vuotnguong_ngoaigio_doam as 
 (
   select kho,congty,mamay,cambien,nam,thang,tuan,
round(sum(vuot_doam),1) as doam_solanvuotnguong_ngoaigio
    FROM `spatial-vision-343005.staging.f_nhietdo_doam` 
 where 
--  congty='CÔNG TY CỔ PHẦN DƯỢC PHA NAM' 
--  and kho ='Kho 438' and mamay ='MR0001-WH0002' and cambien ='S02' and 
 trong_gio =0
 group by 1,2,3,4,5,6,7
 ),

 mapping_all as 

 (
select a.*,
b.nhietdo_solanvuotnguong_tronggio,c.nhietdo_solanvuotnguong_ngoaigio,
round(ifnull(safe_divide(b.nhietdo_solanvuotnguong_tronggio,a.nhietdo_solanvuotnguong )*100,0),1) as nhietdo_tilevuotnguong_tronggio,
round(ifnull(safe_divide(c.nhietdo_solanvuotnguong_ngoaigio,a.nhietdo_solanvuotnguong )*100,0),1) as nhietdo_tilevuotnguong_ngoaigio,
d.doam_solanvuotnguong_tronggio,e.doam_solanvuotnguong_ngoaigio,
round(ifnull(safe_divide(d.doam_solanvuotnguong_tronggio,a.doam_solanvuotnguong )*100,0),1) as doam_tilevuotnguong_tronggio,
round(ifnull(safe_divide(e.doam_solanvuotnguong_ngoaigio,a.doam_solanvuotnguong )*100,0),1) as doam_tilevuotnguong_ngoaigio,
 from data_nhietdo_doam  a
LEFT JOIN data_vuotnguong_tronggio b on b.kho =a.kho and b.congty=a.congty and b.mamay=a.mamay and b.cambien=a.cambien
and b.nam =a.nam and b.thang = a.thang and b.tuan =a.tuan
LEFT JOIN data_vuotnguong_ngoaigio c on c.kho =a.kho and c.congty=a.congty and c.mamay=a.mamay and c.cambien=a.cambien
and c.nam =a.nam and c.thang = a.thang and c.tuan =a.tuan

LEFT JOIN data_vuotnguong_tronggio_doam d on d.kho =a.kho and d.congty=a.congty and d.mamay=a.mamay and d.cambien=a.cambien
and d.nam =a.nam and d.thang = a.thang and d.tuan =a.tuan
LEFT JOIN data_vuotnguong_ngoaigio_doam e on e.kho =a.kho and e.congty=a.congty and e.mamay=a.mamay and e.cambien=a.cambien
and e.nam =a.nam and e.thang = a.thang and e.tuan =a.tuan


 ),

--  select * from mapping_all
unpivot_data as (
 select value,
 Case 
  when items = 'nhietdo_trungbinh' then '1.1 - Trung bình' 
  when items = 'nhietdo_solando' then '1.2 - Số lần đo' 
  when items = 'nhietdo_solanvuotnguong' then '1.3 - Số lần vượt ngưỡng' 
  when items = 'nhietdo_tilevuotnguong' then '1.4 - Tỉ lệ vượt ngưỡng' 
  when items = 'nhietdo_solanvuotnguong_tronggio' then '1.5 - Vượt Ngưỡng 7h30-17h30' 
  when items = 'nhietdo_tilevuotnguong_tronggio' then '1.6 - Tỉ lệ' 
  when items = 'nhietdo_solanvuotnguong_ngoaigio' then '1.7 - Vượt Ngưỡng 17h30-7h30' 
  when items = 'nhietdo_tilevuotnguong_ngoaigio' then '1.8 - Tỉ lệ' 
  when items = 'doam_trungbinh' then '2.1 - Trung bình' 
  when items = 'doam_solando' then '2.2 - Số lần đo' 
  when items = 'doam_solanvuotnguong' then '2.3 - Số lần vượt ngưỡng' 
  when items = 'doam_tilevuotnguong' then '2.4 - Tỉ lệ vượt ngưỡng' 
  when items = 'doam_solanvuotnguong_tronggio' then '2.5 - Vượt Ngưỡng 7h30-17h30' 
  when items = 'doam_tilevuotnguong_tronggio' then '2.6 - Tỉ lệ' 
  when items = 'doam_solanvuotnguong_ngoaigio' then '2.7 - Vượt Ngưỡng 17h30-7h30' 
  when items = 'doam_tilevuotnguong_ngoaigio' then '2.8 - Tỉ lệ' 
  else null end as chi_so1,
items,
 tuan,thang,nam,cambien,
 Case when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM' then 'HỒ CHÍ MINH'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN KHÁNH HÒA' then 'KHÁNH HÒA'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN ĐỒNG NAI' then 'ĐỒNG NAI'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN NGHỆ AN' then 'NGHỆ AN'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN ĐÀ NẴNG' then 'ĐÀ NẴNG'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN CẦN THƠ' then 'CẦN THƠ'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN HÀ NỘI' then 'HÀ NỘI'
else null end as congtycn,
Concat(
Case when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM' then 'HCM'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN KHÁNH HÒA' then 'KHÁNH HÒA'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN ĐỒNG NAI' then 'ĐỒNG NAI'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN NGHỆ AN' then 'NGHỆ AN'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN ĐÀ NẴNG' then 'ĐÀ NẴNG'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN CẦN THƠ' then 'CẦN THƠ'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN HÀ NỘI' then 'HÀ NỘI'
else null end,' - ',kho,' ',mamay) as kho_pivot

from mapping_all 
unpivot(
  value for items in 
 (nhietdo_solando,nhietdo_trungbinh, nhietdo_solanvuotnguong,nhietdo_tilevuotnguong,
 nhietdo_solanvuotnguong_tronggio	,nhietdo_solanvuotnguong_ngoaigio,
 nhietdo_tilevuotnguong_tronggio,nhietdo_tilevuotnguong_ngoaigio,
 doam_solando,doam_trungbinh,doam_solanvuotnguong,doam_tilevuotnguong,
 doam_solanvuotnguong_tronggio,doam_solanvuotnguong_ngoaigio,
 doam_tilevuotnguong_tronggio,doam_tilevuotnguong_ngoaigio)
 )
),
result as (
select value,chi_so1,tuan,thang,nam,congtycn,kho_pivot,cambien from unpivot_data
UNION ALL 
select 
distinct
null as value,
'1. Nhiệt độ' as chi_so1,
-- null as items,
tuan,
thang,
nam,
congtycn,
kho_pivot,
cambien
from unpivot_data
UNION ALL 
select 
distinct
null as value,
'2. Độ ẩm' as chi_so1,
-- null as items,
tuan,
thang,
nam,
congtycn,
kho_pivot,
cambien
from unpivot_data
)

select *,date(nam,thang,01) as date_filter from result

  );
Create or replace table `warehouse.f_nhietdo_doam`

copy `staging_temp.f_nhietdo_doam_temp`;

End;