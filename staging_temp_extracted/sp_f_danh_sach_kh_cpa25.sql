-- ==========================================================================
-- Routine Name : sp_f_danh_sach_kh_cpa25
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2025-11-06 03:27:41.334000+00:00
-- Last Altered : 2025-11-06 03:27:41.334000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danh_sach_kh_cpa25()
BEGIN

 TRUNCATE TABLE `staging_temp.f_danh_sach_kh_cpa25_temp`;

 INSERT INTO `staging_temp.f_danh_sach_kh_cpa25_temp`

(
-- Create or replace table staging_temp.f_danh_sach_kh_cpa25_temp as
with data_sales as (
select
makhdms,
sum(Case when extract(month from ngaychungtu)=4 and a.ngaychungtu >= b.doanhsotinhtu then doanhsocovat else 0 end ) as doanhsocovat_t4,
sum(Case when extract(month from ngaychungtu)=5 and a.ngaychungtu >= b.doanhsotinhtu then doanhsocovat else 0 end ) as doanhsocovat_t5,
sum(Case when extract(month from ngaychungtu)=6 and a.ngaychungtu >= b.doanhsotinhtu then doanhsocovat else 0 end ) as doanhsocovat_t6,
sum(Case when extract(month from ngaychungtu)=7 and a.ngaychungtu >= b.doanhsotinhtu then doanhsocovat else 0 end ) as doanhsocovat_t7,
sum(Case when extract(month from ngaychungtu)=8 and a.ngaychungtu >= b.doanhsotinhtu then doanhsocovat else 0 end ) as doanhsocovat_t8,
sum(Case when extract(month from ngaychungtu)=9 and a.ngaychungtu >= b.doanhsotinhtu then doanhsocovat else 0 end ) as doanhsocovat_t9,
sum(Case when extract(month from ngaychungtu)=10 and a.ngaychungtu >= b.doanhsotinhtu then doanhsocovat else 0 end ) as doanhsocovat_t10,
sum(Case when extract(month from ngaychungtu)=11 and a.ngaychungtu >= b.doanhsotinhtu then doanhsocovat else 0 end ) as doanhsocovat_t11,
sum(Case when extract(month from ngaychungtu)=12 and a.ngaychungtu >= b.doanhsotinhtu then doanhsocovat else 0 end ) as doanhsocovat_t12,
sum(Case when a.ngaychungtu >= b.doanhsotinhtu  then doanhsocovat else 0 end) as doanhsocovat
 from `warehouse.f_raw_data_sales_yoy` a
 LEFT JOIN `staging.d_manual_danh_sach_kh_cpa25` b on a.makhdms =b.mahcotrendms
 where ngaychungtu >='2024-04-01' and ngaychungtu <'2024-12-26'
group by 1
)

select
a.stt,
a.crmacrm,
a.crs,
a.mahcotrendms,
a.tenhco,
a.phanloaihco,
a.tinhthanh,
a.doanhsotinhtu,
a.manv,
ifnull(doanhsocovat_t4,0) as doanhsocovat_t4,
ifnull(doanhsocovat_t5,0) as doanhsocovat_t5,
ifnull(doanhsocovat_t6,0) as doanhsocovat_t6,
ifnull(doanhsocovat_t7,0) as doanhsocovat_t7,
ifnull(doanhsocovat_t8,0) as doanhsocovat_t8,
ifnull(doanhsocovat_t9,0) as doanhsocovat_t9,
ifnull(doanhsocovat_t10,0) as doanhsocovat_t10,
ifnull(doanhsocovat_t11,0) as doanhsocovat_t11,
ifnull(doanhsocovat_t12,0) as doanhsocovat_t12,
ifnull(doanhsocovat,0) as doanhsocovat,
Case when ifnull(doanhsocovat,0) >=135000000 then ifnull(doanhsocovat,0) * 1.5/100 else 0 end as tien_km,
timestamp(current_datetime("+7")) as updated_at,
c.supid as ma_crm,
c.rsmid as ma_ncxm,
c.tenquanlyvung,
d.channel,
d.shoptype,
d.shortterritorydescr,
d.branchid
 from `staging.d_manual_danh_sach_kh_cpa25` a
LEFT JOIN data_sales b on a.mahcotrendms =b.makhdms
LEFT JOIN `staging.d_users` c on a.manv =c.manv
LEFT JOIN `staging.d_master_khachhang` d on d.custid = a.mahcotrendms

);

Create or replace table `warehouse.f_danh_sach_kh_cpa25`

copy `staging_temp.f_danh_sach_kh_cpa25_temp`;
END;
