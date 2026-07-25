CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_quatang_hethu_pcl()
BEGIN 
  TRUNCATE TABLE staging_temp.f_chuongtrinh_quatang_hethu_pcl_temp;


 INSERT INTO staging_temp.f_chuongtrinh_quatang_hethu_pcl_temp(

-- Create or replace table staging_temp.f_chuongtrinh_quatang_hethu_pcl_temp
-- as
with 
tuyen_dms_moinhat_mcp as 
(
with data_tuyen as (
SELECT custid,slsperid,crtd_datetime,
Case when routetype in ('B','D') then 1 else 2 end as routetype,
FROM `spatial-vision-343005.staging.sync_dms_srm` 
where delroutedet is false --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
)
select * from (
select *,row_number() over (partition by custid order by routetype asc,crtd_datetime desc) as loc  from data_tuyen
)
where loc =1


),
tuyen_dms_moinhat 
as 
(
        with a as (
select distinct makhdms as custid,manv,tenquanlyvung,tencvbh,tenquanlytt,crm,scrm,ncxm,
Case when tenquanlyvung ='Nguyễn Thọ Chiến' then 1
            else 3 end as datatype,
    ngaychungtu
      from warehouse.f_sales_crs where ngaychungtu >='2023-04-01' and tenquanlyvung  in ('Nguyễn Thọ Chiến')
)
select * from a 

qualify row_number() over (partition by custid order by ngaychungtu desc,datatype asc) =1
),

data_sales_pcl as (
select 
b.branchid as macongtycn,
makhdms,
b.refcustid as makhcu,
custname as tenkhachhang,
tentinhkh,
khuvucviettat,

hcotypeid as maphanloaihco,
channel as makenhkh,
sum(Case when extract(month from ngaychungtu) in(5,6) and makhdms not in ('TN73E006','TN70O089','NSPC0670028','MSPC0717','MSPC0578','HH11O1065','HH18O138','HH16O315','004748','005557','004713','HH01O305','HH05E006','HH03O439','006734','TT51O1002','TT51O1003','TT51O991','MSPC0753','TB52O983','TB52O956','TN60O982','MSPC0516','MSPC0097') then doanhsocovat  else 0 end) as ds_covat_t5_6,
sum(Case when extract(month from ngaychungtu) in(7,8,9) then doanhsocovat else 0 end) as ds_covat_t7_8_9,
sum(Case when extract(month from ngaychungtu) =5 and makhdms not in ('TN73E006','TN70O089','NSPC0670028','MSPC0717','MSPC0578','HH11O1065','HH18O138','HH16O315','004748','005557','004713','HH01O305','HH05E006','HH03O439','006734','TT51O1002','TT51O1003','TT51O991','MSPC0753','TB52O983','TB52O956','TN60O982','MSPC0516','MSPC0097') then doanhsocovat else 0 end) as ds_covat_t5,
sum(Case when extract(month from ngaychungtu) =6 and makhdms not in ('TN73E006','TN70O089','NSPC0670028','MSPC0717','MSPC0578','HH11O1065','HH18O138','HH16O315','004748','005557','004713','HH01O305','HH05E006','HH03O439','006734','TT51O1002','TT51O1003','TT51O991','MSPC0753','TB52O983','TB52O956','TN60O982','MSPC0516','MSPC0097') then doanhsocovat else 0 end) as ds_covat_t6,
sum(Case when extract(month from ngaychungtu) =7 then doanhsocovat else 0 end) as ds_covat_t7,
sum(Case when extract(month from ngaychungtu) =8 then doanhsocovat else 0 end) as ds_covat_t8,
sum(Case when extract(month from ngaychungtu) =9 then doanhsocovat else 0 end) as ds_covat_t9,


sum(doanhsocovat) as doanhsocovat
 from `staging.f_sales` a
 LEFT JOIN `staging.d_master_khachhang` b on a.makhdms =b.custid
 where   ngaychungtu >'2023-05-03' and ngaychungtu <'2023-10-01' and  --Thời gian áp dụng từ 4/5 đến 30/9
 b.channel ='PCL' and b.hcotypeid in ('PKN','PKQ','NTXQPK') and b.active ='Active'
and trim(upper(makhdms)) not in (select trim(upper(mapcl)) from `staging.d_manual_chuongtrinh_dulich_pcl_2023`)
group by 1,2,3,4,5,6,7,8
-- having ds_covat_t5_6 >=5000000
 ),


--  unit_test as 
--  (
-- select 'N_test' as makhdms,
--         'a',
--         'a',
--         'a',
--         'a',
--         'PKN',
--         'a',  
--         0 as    ds_covat_t5_6,
--         11000000 as   ds_covat_t7_8_9,
--         0 as t5,
--         0 as t6,
--         0 as t7,
--         0 as t8,
--         0 as t9,
--         0 as t_10
--  ),

-- data_sales_pcl as 
-- (

-- select * from data_sales_pcl_ori
-- UNION ALL
-- select * from unit_test

-- ),


 result as (

select *,

-------------------------------Tháng 5,6--------------
-----------Duy ơi, CT hè thu bên NTXQPK chỉ áp dụng mức 1 và 2 thôi nhe (kg áp dụng mức >40tr)  18/5/2023

Case  
    -- when ds_covat_t5_6 >=40000000 and maphanloaihco in ('NTXQPK') then 'Không áp dụng NTXQPK > 40 triệu'
    when ds_covat_t5_6 >=40000000 and maphanloaihco not in ('NTXQPK') then 'Mức 40 triệu'
    when ds_covat_t5_6 >= 15000000 then 'Mức 15 triệu'
    when ds_covat_t5_6 >= 5000000 then 'Mức 5 triệu'

else 'Không đạt mức' end as muctichluy_56,

-------------------------------Tháng 7,8, 9--------------


Case 
    -- when ds_covat_t7_8_9 >=40000000 and maphanloaihco in ('NTXQPK') then 'Không áp dụng NTXQPK >40 triệu'
    when ds_covat_t7_8_9 >=50000000 and maphanloaihco in ('NTXQPK') then 'Mức 50 triệu'
    when ds_covat_t7_8_9 >= 23000000 then 'Mức 23 triệu'
    when ds_covat_t7_8_9 >= 9000000 then 'Mức 9 triệu'

else 'Không đạt mức' end as muc_tichluy_789,
20000 as chiphi_vanchuyen,

--makhdms in ('TN70O089')
Case
    -- when ds_covat_t5_6 >=40000000 and maphanloaihco in ('NTXQPK') then null
    when ds_covat_t5_6 >=80000000  and maphanloaihco not in ('NTXQPK')  then '1 Máy ép chậm EIMICH'
    when ds_covat_t5_6 >= 55000000 and ds_covat_t5_6 < 80000000  and maphanloaihco not in ('NTXQPK') then '1 Máy ép chậm EIMICH'
    when ds_covat_t5_6 >= 40000000 and ds_covat_t5_6 < 55000000  and maphanloaihco not in ('NTXQPK') then '1 Máy ép chậm EIMICH'

    when ds_covat_t5_6 >= 15000000 and maphanloaihco in ('NTXQPK') then '1 Bộ đựng thực phẩm Tupperware'
    when ds_covat_t5_6 >= 30000000 and ds_covat_t5_6 < 40000000 then '1 Bộ đựng thực phẩm Tupperware'
    when ds_covat_t5_6 >= 20000000 and ds_covat_t5_6 < 30000000 then '1 Bộ đựng thực phẩm Tupperware'
    when ds_covat_t5_6 >= 15000000 and ds_covat_t5_6 < 20000000 then '1 Bộ đựng thực phẩm Tupperware'

    when ds_covat_t5_6 >= 10000000 and ds_covat_t5_6 < 15000000 then '1 Bình giữ nhiệt ClocknClock 475ml'
    when ds_covat_t5_6 >= 5000000 and ds_covat_t5_6 < 10000000 then '1 Bình giữ nhiệt ClocknClock 475ml'


else null end as hang_km1,

Case 
    -- when ds_covat_t5_6 >=40000000 and maphanloaihco in ('NTXQPK') then null
    when ds_covat_t5_6 >=80000000  and maphanloaihco not in ('NTXQPK') then '1 Máy ép chậm EIMICH'
    when ds_covat_t5_6 >= 55000000 and ds_covat_t5_6 < 80000000  and maphanloaihco not in ('NTXQPK') then '1 Bộ đựng thực phẩm Tupperware'
    when ds_covat_t5_6 >= 40000000 and ds_covat_t5_6 < 55000000  and maphanloaihco not in ('NTXQPK') then null

    when ds_covat_t5_6 >= 30000000 and maphanloaihco in ('NTXQPK') then '1 Bộ đựng thực phẩm Tupperware'
    when ds_covat_t5_6 >= 30000000 and ds_covat_t5_6 < 40000000 then '1 Bộ đựng thực phẩm Tupperware'
    when ds_covat_t5_6 >= 20000000 and ds_covat_t5_6 < 30000000 then '1 Bình giữ nhiệt ClocknClock 475ml'
    when ds_covat_t5_6 >= 15000000 and ds_covat_t5_6 < 20000000 then null

    when ds_covat_t5_6 >= 10000000 and ds_covat_t5_6 < 15000000 then '1 Bình giữ nhiệt ClocknClock 475ml'
    when ds_covat_t5_6 >= 5000000 and ds_covat_t5_6 < 10000000 then null


else null end as hang_km2,

Case
    when ds_covat_t7_8_9 >=50000000  and maphanloaihco not in ('NTXQPK') then '1 Bộ nồi inox ELMICH HERA'
    when ds_covat_t7_8_9 >= 23000000 and maphanloaihco not in ('NTXQPK') then '1 Máy hút bụi cầm tay Deema'
    when ds_covat_t7_8_9 >= 9000000  and maphanloaihco not in ('NTXQPK') then '1 Nồi điện đa năng Lock&Lock'

    when ds_covat_t7_8_9 >= 23000000 and maphanloaihco  in ('NTXQPK') then '1 Máy hút bụi cầm tay Deema'
    when ds_covat_t7_8_9 >= 9000000  and maphanloaihco  in ('NTXQPK') then '1 Nồi điện đa năng Lock&Lock'

else null end as hang_km3,
Case
    when ds_covat_t7_8_9 >= 100000000  and maphanloaihco not in ('NTXQPK') then '1 Bộ nồi inox ELMICH HERA'
    when ds_covat_t7_8_9  - 50000000 >= 23000000 and ds_covat_t7_8_9 - 50000000 < 50000000  and maphanloaihco not in ('NTXQPK') then '1 Máy hút bụi cầm tay Deema'
    when ds_covat_t7_8_9 - 50000000 >= 9000000 and ds_covat_t7_8_9 - 50000000 < 23000000  and maphanloaihco not in ('NTXQPK') then '1 Nồi điện đa năng Lock&Lock'
    when ds_covat_t7_8_9  >= 50000000 and ds_covat_t7_8_9 - 50000000 < 9000000  and maphanloaihco not in ('NTXQPK') then null

    when ds_covat_t7_8_9 - 23000000 >= 23000000 and maphanloaihco  in ('NTXQPK') then '1 Máy hút bụi cầm tay Deema'
    when ds_covat_t7_8_9 - 23000000 >= 9000000 and ds_covat_t7_8_9 - 23000000 < 23000000 and maphanloaihco  in ('NTXQPK') then '1 Nồi điện đa năng Lock&Lock'
    when ds_covat_t7_8_9  >= 23000000 and ds_covat_t7_8_9 - 23000000 < 9000000 and maphanloaihco  in ('NTXQPK') then null

    when ds_covat_t7_8_9 - 9000000 >= 9000000 and ds_covat_t7_8_9 < 23000000 and maphanloaihco  in ('NTXQPK') then '1 Nồi điện đa năng Lock&Lock'


    when ds_covat_t7_8_9 - 23000000 >= 23000000 and ds_covat_t7_8_9  < 50000000 and maphanloaihco not in ('NTXQPK') then '1 Máy hút bụi cầm tay Deema'
    when ds_covat_t7_8_9 - 23000000 >= 9000000 and ds_covat_t7_8_9 - 23000000 < 23000000 and maphanloaihco not in ('NTXQPK') then '1 Nồi điện đa năng Lock&Lock'
    when ds_covat_t7_8_9 >= 23000000 and ds_covat_t7_8_9 - 23000000 < 9000000 and maphanloaihco not in ('NTXQPK') then null
    when ds_covat_t7_8_9 - 9000000 >= 9000000 and ds_covat_t7_8_9 < 23000000 and maphanloaihco not in ('NTXQPK')  then '1 Nồi điện đa năng Lock&Lock'

else null end as hang_km4,



from data_sales_pcl )

select a.*,
ifnull(c.slsperid,b.manv) manv,
d.tencvbh,
d.supid as crm,
d.tenquanlytt,
d.rsmid as ncxm,
d.tenquanlyvung ,
 (select max(inserted_at) from `staging.f_sales`) as inserted_at,
 Case when makhdms in ('TN73E006','TN70O089','NSPC0670028','MSPC0717','MSPC0578','HH11O1065','HH18O138','HH16O315','004748','005557','004713','HH01O305','HH05E006','HH03O439','006734','TT51O1002','TT51O1003','TT51O991','MSPC0753','TB52O983','TB52O956','TN60O982','MSPC0516','MSPC0097') then 'Y' else 'N' end as is_lockh_quy2 --- theo email RE: Update DS HN khách hàng PCL 12.6.23 18/8/2023
 from result a 
 LEFT JOIN tuyen_dms_moinhat b on a.makhdms =b.custid
 LEFT JOIN tuyen_dms_moinhat_mcp c on a.makhdms =c.custid
 LEFT JOIN `staging.d_users` d on d.manv = ifnull(c.slsperid,b.manv)
--  where a.makhdms ='MSPC0589'
--  LEFT JOIN `staging.d_users` c on c.manv =b.slsperid
--  where makhdms ='N_test'

  );

Create or replace table `warehouse.f_chuongtrinh_quatang_hethu_pcl`

copy `staging_temp.f_chuongtrinh_quatang_hethu_pcl_temp`;


End;