CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_dulich_2023()
BEGIN 
  TRUNCATE TABLE staging_temp.f_chuongtrinh_dulich_2023_temp;


 INSERT INTO staging_temp.f_chuongtrinh_dulich_2023_temp(

-- Create or replace table staging_temp.f_chuongtrinh_dulich_2023_temp as
with 

tuyen_dms_moinhat_ori as 
(
with data_tuyen as (
SELECT custid,slsperid,crtd_datetime,
Case when routetype in ('B','D') then 1 else 2 end as routetype,
FROM `spatial-vision-343005.staging.sync_dms_srm` 
where delroutedet is false --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
)

select *, row_number() over (partition by custid order by routetype asc,crtd_datetime desc) as loc  from data_tuyen
QUALIFY loc = 1
),

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
  data_sales as (

  select 
  makhdms, 
  sum(Case when extract(month from ngaychungtu) =5 then doanhsocovat else 0 end) as ds_t5,
  sum(Case when extract(month from ngaychungtu) =6 then doanhsocovat else 0 end) as ds_t6,
  sum(Case when extract(month from ngaychungtu) =7 then doanhsocovat else 0 end) as ds_t7,
  sum(Case when extract(month from ngaychungtu) =8 then doanhsocovat else 0 end) as ds_t8,
  sum(Case when extract(month from ngaychungtu) =9 then doanhsocovat else 0 end) as ds_t9,

  sum(doanhsocovat) as doanhsocovat from `staging.f_sales`
  where makenhkh not in ('OTH_LAB') and ngaychungtu >='2023-05-04' and ngaychungtu <'2023-10-01' 
  group by 1
)

select 
c.branchid,
a.mahcotrendms as custid,custname,statedescr as tinhtp,territorydescr,channel, hcotypeid,hcoid,shoptype,
b.ds_t5,b.ds_t6,b.ds_t7,b.ds_t8,b.ds_t9,
b.doanhsocovat,
Case 
  when b.doanhsocovat >=150000000 *5 then '5 chuyến du lịch Hạ Long hoặc Nha Trang hoặc Đà Nẵng'
  when b.doanhsocovat >=150000000 *4 then '4 chuyến du lịch Hạ Long hoặc Nha Trang hoặc Đà Nẵng'
  when b.doanhsocovat >=150000000 *3 then '3 chuyến du lịch Hạ Long hoặc Nha Trang hoặc Đà Nẵng'
  when b.doanhsocovat >=150000000 *2 then '2 chuyến du lịch Hạ Long hoặc Nha Trang hoặc Đà Nẵng'
  when b.doanhsocovat >=150000000 then '1 chuyến du lịch Hạ Long hoặc Nha Trang hoặc Đà Nẵng'
else null end as qua_km,
IFNULL(f0.slsperid, d.slsperid) as crs,
e.tencvbh as tencvbh,
Case when e.tenquanlyvung ='Lương Trịnh Thắng' then e.supid_bh else e.supid end as crm,
Case when e.tenquanlyvung ='Lương Trịnh Thắng' then e.tenquanlytt_bh else e.tenquanlytt end as tenquanlytt,
e.rsmid,
e.tenquanlyvung,
e.asm,
e.tenquanlykhuvuc
 from `staging.d_manual_chuongtrinh_dulich_2023` a 
LEFT JOIN data_sales b on a.mahcotrendms =b.makhdms
LEFT JOIN `staging.d_master_khachhang` c on a.mahcotrendms =c.custid
LEFT JOIN tuyen_dms_moinhat d on a.mahcotrendms = d.custid
-- LEFT JOIN `staging.d_users` e on d.slsperid = e.manv
LEFT JOIN tuyen_dms_moinhat_ori f0 on a.mahcotrendms = f0.custid --16/08/2023 duyvq add
LEFT JOIN `staging.d_users` e on IFNULL(f0.slsperid, d.slsperid) = e.manv
where a.mahcotrendms not in ('TD31O195','M1301039','M1201332') --1/7/2023 chị Cúc nói bỏ 3 thằng NTPP ra


 );

Create or replace table `warehouse.f_chuongtrinh_dulich_2023`

copy `staging_temp.f_chuongtrinh_dulich_2023_temp`;


End;