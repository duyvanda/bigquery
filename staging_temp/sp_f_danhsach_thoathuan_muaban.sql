CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danhsach_thoathuan_muaban()
BEGIN 
 
 TRUNCATE TABLE staging_temp.f_danhsach_thoathuan_muaban_temp;

 INSERT INTO `staging_temp.f_danhsach_thoathuan_muaban_temp`

(
-- Create or replace table staging_temp.f_danhsach_thoathuan_muaban_temp as 

with 
d_accumulatedregis as (
  select
    a.*
  from
    `spatial-vision-343005.staging.d_accumulatedregis` a
  where
    accumulateid in ( '202401-TL-QD976-PMC-CTD','202401-TL-QD974-PMC-CTD')
qualify row_number() over (partition by custid order by crtd_datetime desc ) = 1
)

select 
a.branchid,
b.branchname,
c.supid,
c.tenquanlytt,
c.rsmid,
c.tenquanlyvung,
a.crtd_user,
c.tencvbh,
a.accumulateid,
'Chương Trình Tích Lũy Quý Kháng Sinh>=9tr CK 12%, >=18tr CK 15%' as accumulatename,
a.custid,
d.custname,
d.attn,
d.phone,
d.address,
d.statedescr,
d.districtdescr,
d.wardname,
a.purchaseagreementid,
a.crtd_datetime,
a.purchaseagreementvalue,
a.levelid,
Case when a.levelid ='1' then 'Tích Lũy Quý Kháng Sinh >=9tr CK 12%'
     when a.levelid ='2' then 'Tích Lũy Quý Kháng Sinh >=18tr CK 15%'
     else null end as level_name,
a.status,
a.inserted_at
 from d_accumulatedregis a 

left join (select distinct branchid, branchname from `staging.d_master_khachhang`) b on a.branchid =b.branchid
left join `staging.d_users` c on c.manv = a.crtd_user
left join `staging.d_master_khachhang` d on d.custid =a.custid


order by crtd_datetime asc
);

Create or replace table `warehouse.f_danhsach_thoathuan_muaban`

copy `staging_temp.f_danhsach_thoathuan_muaban_temp`;

END;