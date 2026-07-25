CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_quatang_hethu_tp()
BEGIN 
  TRUNCATE TABLE staging_temp.f_chuongtrinh_quatang_hethu_tp_temp;


 INSERT INTO staging_temp.f_chuongtrinh_quatang_hethu_tp_temp(

with 
-- tuyen_dms_realtime as 
-- (
-- with data_tuyen as (
-- SELECT custid,slsperid,crtd_datetime,
-- Case when routetype in ('B','D') then 1 else 2 end as routetype,
-- FROM `spatial-vision-343005.staging.sync_dms_srm`  a 
-- LEFT JOIN `staging.d_users` b on a.slsperid =b.manv

-- where delroutedet is false  --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')

-- )

tuyen_dms_moinhat as 
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
makhdms,
makhcu,
custname as tenkhachhang,
tentinhkh,
khuvucviettat,
hcotypeid as maphanloaihco,
channel as makenhkh,
hcoid as mahco,
b.statedescr,
-- sum(Case when extract(month from ngaychungtu) in(5,6) then doanhsocovat  else 0 end) as ds_covat_t5_6,
sum(Case when extract(month from ngaychungtu) in(7,6) then doanhsocovat else 0 end) as ds_covat_t6_7,
-- sum(Case when extract(month from ngaychungtu) =5 then doanhsocovat else 0 end) as ds_covat_t5,
sum(Case when extract(month from ngaychungtu) =6 then doanhsocovat else 0 end) as ds_covat_t6,
sum(Case when extract(month from ngaychungtu) =7 then doanhsocovat else 0 end) as ds_covat_t7,
-- sum(Case when extract(month from ngaychungtu) =8 then doanhsocovat else 0 end) as ds_covat_t8,
-- sum(Case when extract(month from ngaychungtu) =9 then doanhsocovat else 0 end) as ds_covat_t9,


sum(doanhsocovat) as doanhsocovat
 from `staging.f_sales` a 
 LEFT JOIN `staging.d_master_khachhang` b on a.makhdms =b.custid
 where channel ='TP' and hcoid in ('PMC','CTD') and hcotypeid not in ('SI','NTPP')
and ngaychungtu >='2023-06-01' and ngaychungtu <'2023-08-01' 
and masanpham in ('EH104','EH103','EH093','EH070','EH068','EH069','EH065','EH095','EH124','EH111','EH106','EH109','EH115','EH096','EH100','EH066','EH067','EH072')
/* Danh mục sản phẩm thuộc kháng sinh và nhóm tiêu hóa */
group by 1,2,3,4,5,6,7,8,9
-- having ds_covat_t5_6 >=5000000
 )
 ,
 result as (

select a.* ,

Case

    when ds_covat_t6_7 >=15000000 then '1 Máy massage hồng ngoại 3D Kingsport'
    when ds_covat_t6_7 >= 6000000 and ds_covat_t6_7 < 15000000   then '1 Cân điện tử Lock & Lock'
    when ds_covat_t6_7 >= 3000000 and ds_covat_t6_7 <  6000000   then '1 Máy vắt cam Lebenlang'


else null end as hang_km1,

Case

    when ds_covat_t6_7 >= 30000000 then '1 Máy massage hồng ngoại 3D Kingsport'
    when ds_covat_t6_7 >= 21000000 and ds_covat_t6_7 < 30000000  then '1 Cân điện tử Lock & Lock'
    when ds_covat_t6_7 >= 18000000 and ds_covat_t6_7 < 21000000   then '1 Máy vắt cam Lebenlang'

    when ds_covat_t6_7 >= 12000000 and ds_covat_t6_7 < 15000000   then '1 Cân điện tử Lock & Lock'
    when ds_covat_t6_7 >=  9000000 and ds_covat_t6_7 < 12000000   then '1 Máy vắt cam Lebenlang'

    -- when ds_covat_t6_7 >=  6000000 and ds_covat_t6_7 <  9000000   then '1 Máy vắt cam Lebenlang'


else null end as hang_km2,

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

 from result a 
 LEFT JOIN tuyen_dms_moinhat b on a.makhdms =b.custid
--  LEFT JOIN `staging.d_users` c on c.manv =b.slsperid


  );

Create or replace table `warehouse.f_chuongtrinh_quatang_hethu_tp`

copy `staging_temp.f_chuongtrinh_quatang_hethu_tp_temp`;


End;