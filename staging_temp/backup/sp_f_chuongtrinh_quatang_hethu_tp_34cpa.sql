CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_quatang_hethu_tp_34cpa()
BEGIN 
  TRUNCATE TABLE staging_temp.f_chuongtrinh_quatang_hethu_tp_temp_34cpa;


INSERT INTO staging_temp.f_chuongtrinh_quatang_hethu_tp_temp_34cpa(

  -- Create or replace table staging_temp.f_chuongtrinh_quatang_hethu_tp_temp_34cpa as 
--data body
with tuyen_dms_moinhat as 
(
    with a as (
select distinct makhdms as custid,manv as slsperid,tenquanlyvung,tencvbh,tenquanlytt,crm,scrm,ncxm,tenquanlykhuvuc,
Case when tenquanlyvung ='Nguyễn Hoàng Viển' then 1
      when tenquanlyvung ='Lương Trịnh Thắng' then 2
      else 3 end as datatype,
    ngaychungtu
      from warehouse.f_sales_crs where ngaychungtu >='2023-04-01' and tenquanlyvung not in ('Nguyễn Thọ Chiến','Lê Thị Hương Sa')
)
select * from a 
qualify row_number() over (partition by custid order by ngaychungtu desc,datatype asc) =1
),

 data_sales_tp  as (
select 
b.branchid as macongtycn,
makhdms,
makhcu,
custname as tenkhachhang,
tentinhkh,
khuvucviettat,
hcotypeid as maphanloaihco,
channel as makenhkh,
hcoid as mahco,
b.statedescr,
sum(Case when extract(month from ngaychungtu) in(8,9) then doanhsocovat else 0 end) as ds_covat_t8_9,
sum(Case when extract(month from ngaychungtu) = 8 then doanhsocovat else 0 end) as ds_covat_t8,
sum(Case when extract(month from ngaychungtu) = 9 then doanhsocovat else 0 end) as ds_covat_t9,
sum(doanhsocovat) as doanhsocovat
 from `staging.f_sales` a 
 LEFT JOIN `staging.d_master_khachhang` b on a.makhdms =b.custid
 where channel ='TP' and hcoid in ('PMC','CTD') and hcotypeid not in ('SI','NTPP')
and ngaychungtu >='2023-08-01' and ngaychungtu <'2023-10-01' 
and masanpham in ('EH104','EH103','EH093','EH070','EH068','EH069','EH065','EH095','EH124','EH111','EH106','EH109','EH115','EH096','EH100','EH066','EH067','EH072','OH047','OH048')
/* Danh mục sản phẩm thuộc kháng sinh và nhóm tiêu hóa, Thêm 2 sản phâm merika */
group by 1,2,3,4,5,6,7,8,9,10
-- having ds_covat_t5_6 >=5000000
 ),

--  unit_test as 
--  (
--   select 
--   'Test' as  makhdms,
--   null makhcu,
--   null tenkhachhang,
--   null tentinhkh,
--   null khuvucviettat,
--   null as maphanloaihco,
--   null as makenhkh,
--   null as mahco,
--   null statedescr,
--   51000000 as ds_covat_t8_9,
--   0 as a,
--   0 as b,
--   0 as c
--  ),

-- data_sales_tp as 

-- (
--   select * from unit_test 
-- )

--  ,
 result as (

select a.* ,

Case

    when ds_covat_t8_9 >=15000000 then '1 Nồi Điện'
    when ds_covat_t8_9 >= 6000000   then '1 Nồi Tay Cầm'
    when ds_covat_t8_9 >= 3000000  then '1 Gối Memory'

else null end as hang_km1,

Case

    when ds_covat_t8_9 - 15000000 >= 15000000 then '1 Nồi Điện'
    when ds_covat_t8_9 - 15000000 >=  6000000 and ds_covat_t8_9 - 15000000 < 15000000 then '1 Nồi Tay Cầm'
    when ds_covat_t8_9 - 15000000 >=  3000000 and ds_covat_t8_9 - 15000000 < 6000000 then '1 Gối Memory'

    when ds_covat_t8_9 - 6000000 >= 6000000 and ds_covat_t8_9  < 15000000 then '1 Nồi Tay Cầm'
    when ds_covat_t8_9 - 6000000 >= 3000000 and ds_covat_t8_9 - 6000000 < 6000000 then '1 Gối Memory'
        
else null end as hang_km2,

Case

    when ds_covat_t8_9 - 15000000*2 >= 15000000 then '1 Nồi Điện'
    when ds_covat_t8_9 - 15000000*2  >=  6000000 and ds_covat_t8_9 - 15000000*2  < 15000000 then '1 Nồi Tay Cầm'
    when ds_covat_t8_9 - 15000000*2  >=  3000000 and ds_covat_t8_9 - 15000000*2  < 6000000 then '1 Gối Memory'

    when ds_covat_t8_9 - 15000000 - 6000000 >=  6000000 and ds_covat_t8_9 - 15000000  < 15000000 then '1 Nồi Tay Cầm'
    when ds_covat_t8_9 - 15000000 - 6000000 >=  3000000 and ds_covat_t8_9 - 15000000 - 6000000 < 6000000 then '1 Gối Memory'
 
    
else null end as hang_km3,

Case

    when ds_covat_t8_9 - 15000000*3 >= 15000000 then '1 Nồi Điện'
    when ds_covat_t8_9 - 15000000*3  >=  6000000 and ds_covat_t8_9 - 15000000*3 < 15000000 then '1 Nồi Tay Cầm'
    when ds_covat_t8_9 - 15000000*3  >=  3000000 and ds_covat_t8_9 - 15000000*3 <  6000000  then '1 Gối Memory'

    when ds_covat_t8_9 - 15000000*2 -6000000 >=  6000000 and ds_covat_t8_9 - 15000000*2  < 15000000  then '1 Nồi Tay Cầm'
    when ds_covat_t8_9 - 15000000*2 -6000000 >=  3000000 and ds_covat_t8_9 - 15000000*2 -6000000 <  6000000  then '1 Gối Memory'


    
else null end as hang_km4,

Case

    when ds_covat_t8_9 - 15000000*4 >= 15000000 then '1 Nồi Điện'
    when ds_covat_t8_9 - 15000000*4  >=  6000000 and ds_covat_t8_9 - 15000000*4 <15000000 then '1 Nồi Tay Cầm'
    when ds_covat_t8_9 - 15000000*4  >=  3000000 and ds_covat_t8_9 - 15000000*4 <6000000  then '1 Gối Memory'

    when ds_covat_t8_9 - 15000000*3 -6000000 >=  6000000 and ds_covat_t8_9 - 15000000*3  < 15000000  then '1 Nồi Tay Cầm'
    when ds_covat_t8_9 - 15000000*3 -6000000 >=  3000000 and ds_covat_t8_9 - 15000000*3 -6000000 <  6000000  then '1 Gối Memory'


else null end as hang_km5,


from data_sales_tp a
 )

select a.*,
b.slsperid manv,
b.tencvbh,
b.crm,
b.tenquanlytt,
b.scrm,
b.tenquanlykhuvuc,
b.ncxm,
b.tenquanlyvung,
(ifnull(length(hang_km1) - LENGTH(REGEXP_REPLACE(hang_km1, '1 Nồi Điện', '')),0)
+
ifnull(length(hang_km2) - LENGTH(REGEXP_REPLACE(hang_km2, '1 Nồi Điện', '')),0)
+
ifnull(length(hang_km3) - LENGTH(REGEXP_REPLACE(hang_km3, '1 Nồi Điện', '')),0)
+
ifnull(length(hang_km4) - LENGTH(REGEXP_REPLACE(hang_km4, '1 Nồi Điện', '')),0)
+
ifnull(length(hang_km5) - LENGTH(REGEXP_REPLACE(hang_km5, '1 Nồi Điện', '')),0) ) /10  as qua_tang1,


(ifnull(length(hang_km1) - LENGTH(REGEXP_REPLACE(hang_km1, '1 Nồi Tay Cầm', '')),0)
+
ifnull(length(hang_km2) - LENGTH(REGEXP_REPLACE(hang_km2, '1 Nồi Tay Cầm', '')),0)
+
ifnull(length(hang_km3) - LENGTH(REGEXP_REPLACE(hang_km3, '1 Nồi Tay Cầm', '')),0)
+
ifnull(length(hang_km4) - LENGTH(REGEXP_REPLACE(hang_km4, '1 Nồi Tay Cầm', '')),0)
+
ifnull(length(hang_km5) - LENGTH(REGEXP_REPLACE(hang_km5, '1 Nồi Tay Cầm', '')),0) ) /13 as qua_tang2,


(ifnull(length(hang_km1) - LENGTH(REGEXP_REPLACE(hang_km1, '1 Gối Memory', '')),0)
+
ifnull(length(hang_km2) - LENGTH(REGEXP_REPLACE(hang_km2, '1 Gối Memory', '')),0)
+
ifnull(length(hang_km3) - LENGTH(REGEXP_REPLACE(hang_km3, '1 Gối Memory', '')),0)
+
ifnull(length(hang_km4) - LENGTH(REGEXP_REPLACE(hang_km4, '1 Gối Memory', '')),0)
+
ifnull(length(hang_km5) - LENGTH(REGEXP_REPLACE(hang_km5, '1 Gối Memory', '')),0) ) /12 as qua_tang3,

 from result a 
 LEFT JOIN tuyen_dms_moinhat b on a.makhdms = b.custid

--end data body
);

Create or replace table `warehouse.f_chuongtrinh_quatang_hethu_tp_34cpa`

copy `staging_temp.f_chuongtrinh_quatang_hethu_tp_temp_34cpa`;


End;