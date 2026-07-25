CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_tichluy_viplus_c2_2023()
BEGIN 
TRUNCATE TABLE staging_temp.f_tichluy_viplus_c2_2023_temp;

INSERT INTO staging_temp.f_tichluy_viplus_c2_2023_temp(
-- Create or replace table staging_temp.f_tichluy_viplus_c2_2023_temp as
with 
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
)

SELECT 
a.custid as mahcotrendms,
b.custname as tenhco,
b.statedescr as tinhtp,
b.channel,
b.shoptype,
b.hcotypeid,
a.branchid,
b.branchname,
b.shortterritorydescr,
d.tencvbh as crsscrs,
c.slsperid as ma_crs,
d.supid as ma_crm,
d.asm as ma_scrm,
d.rsmid as  ma_ncxm,
d.tenquanlytt as crmacrm,
d.tenquanlykhuvuc as scrm,
d.tenquanlyvung as ncxm,
a.origdocamt as tien_ck_c2_2023,
a.docbal as tien_con_lai,
a.origdocamt - a.docbal as tien_da_tra
 FROM `spatial-vision-343005.staging.f_vipplus_c2_2023` a 
 LEFT JOIN `staging.d_master_khachhang` b on a.custid =b.custid
 LEFT JOIN tuyen_dms_moinhat c on a.custid =c.custid
 LEFT JOIN `staging.d_users` d on d.manv =c.slsperid
);
Create or replace table `warehouse.f_tichluy_viplus_c2_2023`

copy `staging_temp.f_tichluy_viplus_c2_2023_temp`;

End;