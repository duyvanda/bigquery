CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_dulich_pcl_2023_v2()
BEGIN 
TRUNCATE TABLE staging_temp.f_chuongtrinh_dulich_pcl_2023_temp;


INSERT INTO staging_temp.f_chuongtrinh_dulich_pcl_2023_temp(


-- Create or replace table staging_temp.f_chuongtrinh_dulich_pcl_2023_temp
-- as


/*
27/6/2023 - Chị Linh note
MSPC0112	NT Phúc Minh - Huỳnh Thị Tố Hảo - Hóc Môn - HCM
KH này xin rút khỏi CT du lịch nên e chuyển về CT hè thu giúp c nhe
*/



with
manual_pcl_2023 as
(
--maping manual
select
stt as stt,
crm as crm,
crs as crs,
tinh as tinh,
mapcl as mapcl,
tenpcl as tenpcl,
ds14309 as ds14309,
tgapdung as tgapdung,
sosuatdangky as sosuatdangky,
dsdangky as dsdangky,
dstichluyupt523 as dstichluyupt523,
dsconlai as dsconlai,
sothangconlai as sothangconlai,
dsconlaisothangconlai as dsconlaisothangconlai,
mapcl as makhdms,
current_datetime() as inserted_at
from `staging.d_manual_chuongtrinh_dulich_pcl_2023`
),
--end map

tuyen_dms_moinhat as (
    with data_tuyen as (
    SELECT
    custid,
    slsperid,
    crtd_datetime,
    Case when routetype in ('B','D') then 1 else 2 end as routetype,
    FROM `spatial-vision-343005.staging.sync_dms_srm` 
    where delroutedet is false --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
    )
    select * from (
    select *,row_number() over (partition by custid order by routetype asc,crtd_datetime desc) as loc  from data_tuyen
    )
    where loc =1
),

mapping_tinhthuong as
(
    SELECT
    '1/4 - 30/9' as tgapdung, DATE('2023-04-01') as valid_from, DATE('2023-09-30') as valid_to
    UNION ALL
    SELECT
    '1/5 - 31/10' as tgapdung, DATE('2023-05-01') as valid_from, DATE('2023-10-31') as valid_to
    UNION ALL
    SELECT
    '1/2 - 31/7' as tgapdung, DATE('2023-02-01') as valid_from, DATE('2023-07-31') as valid_to
),

data_sales_pcl as (
select
a.makhdms,
sum(Case when extract(month from ngaychungtu) = 2 and DATE(ngaychungtu) BETWEEN c.valid_from AND c.valid_to then doanhsocovat else 0 end) as ds_covat_t2,
sum(Case when extract(month from ngaychungtu) = 3 and DATE(ngaychungtu) BETWEEN c.valid_from AND c.valid_to then doanhsocovat else 0 end) as ds_covat_t3,
sum(Case when extract(month from ngaychungtu) = 4 and DATE(ngaychungtu) BETWEEN c.valid_from AND c.valid_to then doanhsocovat else 0 end) as ds_covat_t4,
sum(Case when extract(month from ngaychungtu) = 5 and DATE(ngaychungtu) BETWEEN c.valid_from AND c.valid_to then doanhsocovat else 0 end) as ds_covat_t5,
sum(Case when extract(month from ngaychungtu) = 6 and DATE(ngaychungtu) BETWEEN c.valid_from AND c.valid_to then doanhsocovat else 0 end) as ds_covat_t6,
sum(Case when extract(month from ngaychungtu) = 7 and DATE(ngaychungtu) BETWEEN c.valid_from AND c.valid_to then doanhsocovat else 0 end) as ds_covat_t7,
sum(Case when extract(month from ngaychungtu) = 8 and DATE(ngaychungtu) BETWEEN c.valid_from AND c.valid_to then doanhsocovat else 0 end) as ds_covat_t8,
sum(Case when extract(month from ngaychungtu) = 9 and DATE(ngaychungtu) BETWEEN c.valid_from AND c.valid_to then doanhsocovat else 0 end) as ds_covat_t9,
sum(Case when extract(month from ngaychungtu) = 10 and DATE(ngaychungtu) BETWEEN c.valid_from AND c.valid_to then doanhsocovat else 0 end) as ds_covat_t10,
sum(case when DATE(ngaychungtu) BETWEEN c.valid_from AND c.valid_to then doanhsocovat else 0 end) as doanhsocovat
from `staging.f_sales` a
INNER JOIN manual_pcl_2023 b on a.makhdms = b.makhdms
LEFT JOIN mapping_tinhthuong c on b.tgapdung = c.tgapdung
where ngaychungtu >='2023-02-01' and ngaychungtu < '2023-11-01'
group by 1
),

mapping_sales as (
select 
a.*,
b.branchid,
b.branchname,
b.channel,
b.statedescr,
b.shortterritorydescr as territorydescr,
b.active,
b.custname,
b.shoptype,
b.hcotypeid,
b.hcoid,

ifnull(ds_covat_t2,0) as ds_covat_t2,
ifnull(ds_covat_t3,0) as ds_covat_t3,
ifnull(ds_covat_t5,0) as ds_covat_t5,
ifnull(ds_covat_t6,0) as ds_covat_t6,
ifnull(ds_covat_t7,0) as ds_covat_t7,
ifnull(ds_covat_t8,0) as ds_covat_t8,
ifnull(ds_covat_t9,0) as ds_covat_t9,
ifnull(doanhsocovat,0) as doanhsocovat,
ifnull(ds_covat_t10,0) as ds_covat_t10,
ifnull(ds_covat_t4,0) as ds_covat_t4,
doanhsocovat as ds_tinhthuong,
d.slsperid as ma_crs,
e.tencvbh,
e.supid as ma_crm,
e.tenquanlytt,
e.asm as ma_scrm,
e.tenquanlykhuvuc,
e.rsmid as ma_ncxm,
e.tenquanlyvung
from manual_pcl_2023 a 
LEFT JOIN `staging.d_master_khachhang` b on a.makhdms =b.custid 
LEFT JOIN data_sales_pcl c on a.makhdms = c.makhdms
LEFT JOIN tuyen_dms_moinhat d on a.makhdms = d.custid
LEFT JOIN `staging.d_users` e on d.slsperid = e.manv
) -- END WITH

select *,
div(cast(ds_tinhthuong as int),135000000) as phanloai
from mapping_sales

);

Create or replace table `warehouse.f_chuongtrinh_dulich_pcl_2023`

copy `staging_temp.f_chuongtrinh_dulich_pcl_2023_temp`;


End;