-- ==========================================================================
-- Routine Name : f_all_sanpham_post
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2025-08-07 03:21:12.925000+00:00
-- Last Altered : 2025-08-07 03:21:12.925000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_all_sanpham_post()
BEGIN
DECLARE partition_date DATE DEFAULT '2023-01-01';
TRUNCATE TABLE staging_temp.f_all_sanpham_post_temp;
INSERT INTO `staging_temp.f_all_sanpham_post_temp`

(
--Create or replace table `staging_temp.f_all_sanpham_post_temp`
--as (
with cum as
(
  select
    distinct statedescr,
    districtdescr,
    wardname,
    cluster_state
  from `spatial-vision-343005.staging.d_leadtimekpi`
)
,
cum1 as
(
  select
    distinct statedescr,
    districtdescr,
    cluster_state
  from `spatial-vision-343005.staging.d_leadtimekpi`
  where districtdescr <> 'Huyện Bình Chánh'
)

SELECT
  a.crtd_datetime,
  a.inserted_at,
  a.invtid,
  b.descr as tensp,
  c.custid,
  c.status,
  d.custname,
  d.channel,
  d.shoptypedescr,
  d.statedescr,
  d.branchid,
  d.branchname,
  c.custid as makhdms,
  d.cluster_state,
  case when a.branchid like 'MR%' then 'Pha Nam' else 'Merap' end as phaply,
  case when a.slsperid ='TMDT_001' then 'Y' else 'N' end as dh_ecom,
  case when lower(d.custname) like '%fpt long châu%' and d.channel = 'MT' then '1.Long Châu'
       when lower(d.custname) like '%pharmacity%' and d.channel = 'MT' then '2.Phamacity'
       when lower(d.custname) like '%trung sơn%' and d.channel = 'MT' then '3.Trung Sơn'
       when lower(d.custname) like '%medx%' and d.channel = 'MT' then '4.MedX'
       when lower(d.custname) like '%guardian%' and d.channel = 'MT' then '5.Guardian'
       when lower(d.custname) like '%an khang%' and d.channel = 'MT' then '6.An Khang'
       when c.custid = '003589' and d.channel = 'MT' then '9.ECE - Ecommerce enable'
       when lower(d.custname) like '%wincommerce%' and d.channel ='MT' then '7.WinMart'
       when lower(d.custname) like '%meraki%' and d.channel ='MT' then '8.Meraki'
       else 'others' end as group_khach_hang,
  case when d.shoptypedescr like '%Clinic Chanel%'  then 'Clinic'
       when  d.shoptypedescr like '%Đại Lý Phân Phối%' then 'Đại Lý Phân Phối'
       when  d.shoptypedescr like '%Insurance%' then 'Kênh Bảo hiểm'
       else d.shoptypedescr end as kenh_khach_hang,
"N" iscaresoft_customer,
SUM(Case when a.ordertype in ('IR','CO','OO') then -1*lineqty else lineqty end) as lineqty
FROM `spatial-vision-343005.staging.sync_dms_pda_sod` a
left join `spatial-vision-343005.staging.d_dms_master_invtid` b on a.invtid = b.invtid
left join `spatial-vision-343005.staging.sync_dms_pda_so` c on a.ordernbr = c.ordernbr and a.branchid = c.branchid
left join `spatial-vision-343005.staging.d_master_khachhang` d on c.custid = d.custid
WHERE a.ordertype in ('IN','IR','CO','OO') and a.invtid not like 'V%' and date(a.crtd_datetime) >= partition_date
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19
order by  a.crtd_datetime desc

);

Create or replace table `warehouse.f_all_sanpham_post`

copy `staging_temp.f_all_sanpham_post_temp`;
END;
