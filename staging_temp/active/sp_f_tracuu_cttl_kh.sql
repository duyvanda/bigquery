CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_tracuu_cttl_kh()
OPTIONS(
  strict_mode=false)
BEGIN 
 
 TRUNCATE TABLE staging_temp.f_tracuu_cttl_kh_temp;

--  INSERT INTO `staging_temp.f_tracuu_cttl_kh_temp`

-- ( 

Create or replace table staging_temp.f_tracuu_cttl_kh_temp as (
with 
tuyen_dms_moinhat as 
(
with data_tuyen as (
SELECT custid,slsperid,crtd_datetime,
Case when routetype in ('B','D') then 1 else 2 end as routetype,
FROM `spatial-vision-343005.staging.sync_dms_srm`  a 

where delroutedet is false 
)

select custid,slsperid,routetype
from data_tuyen
qualify row_number() over (partition by custid order by routetype asc,crtd_datetime desc) =1
),

----Danh sách KH tham gia trưng bày Ebysta,decal,stiker

ct_d_tdisplay as 
(
select 
distinct
makhachhang,
Case 
when machuongtrinh in ('2501-CTTB-CPA10-NT-QT','2401-CTTB-CPA03-NT-QT') then 'Sticker lá đôi'
when machuongtrinh in ('2501-CTTB-CPA08-NT-QT','2401-CTTB-CPA01-NT-QT','2601-CTTB-CPA10-NT-QT') then 'Trưng bày Decal'
when machuongtrinh in ('2501-CTTB-CPA09-NT-QT','2401-CTTB-CPA02-NT-QT','2604-CTTB-26MTP2022-NT-QT') then 'Trưng bày Ebysta'
when machuongtrinh in ('2504-CTTB-CPA28-NT-QT') then 'Trưng bày Benita Xylo'
when machuongtrinh in ('2507-CTTB-CPA46-NT-QT') then 'Trưng bày Poster Online'
when machuongtrinh in ('2509-CTTB-CPA64-NT-QT','2601-CTTB-CPA09-NT-QT') then 'Trưng bày Poster bình ổn giá'


else null end as datatype,
Case
when machuongtrinh in ('2601-CTTB-CPA10-NT-QT','2601-CTTB-CPA09-NT-QT','2604-CTTB-26MTP2022-NT-QT') then 2026
when machuongtrinh in ('2501-CTTB-CPA10-NT-QT', '2501-CTTB-CPA08-NT-QT' ,'2501-CTTB-CPA09-NT-QT','2509-CTTB-CPA64-NT-QT','2507-CTTB-CPA46-NT-QT','2504-CTTB-CPA28-NT-QT') then 2025
when machuongtrinh in ('2401-CTTB-CPA03-NT-QT','2401-CTTB-CPA01-NT-QT','2401-CTTB-CPA02-NT-QT') then 2024

else null end as nam,
from `spatial-vision-343005.staging.d_tdisplay` where 
machuongtrinh in ( '2501-CTTB-CPA10-NT-QT', '2501-CTTB-CPA08-NT-QT' ,'2501-CTTB-CPA09-NT-QT', '2504-CTTB-CPA28-NT-QT','2507-CTTB-CPA46-NT-QT','2509-CTTB-CPA64-NT-QT','2601-CTTB-CPA10-NT-QT','2601-CTTB-CPA09-NT-QT','2604-CTTB-26MTP2022-NT-QT')
and lower(trangthaiduyettrungbay) = 'đã duyệt'
),
kh_vip_tp as 
(
SELECT distinct ma_kh, 'KH VIP TP' as datatype FROM `spatial-vision-343005.staging.form_theo_doi_ds_vip_tp_2025` 
),
loyalty_tp as 
(
SELECT distinct ma_kh, 'Loyalty TP' as datatype FROM `spatial-vision-343005.staging.form_theo_doi_CSBH_loyalty_TP_2025` 
),
loyalty_pcl as 
(
SELECT distinct ma_kh, 'Loyalty PCL' as datatype FROM `spatial-vision-343005.staging.form_theo_doi_CSBH_loyalty_PCL_2025` 
),
loyalty_pcl_2026 as 
(
SELECT distinct ma_kh, 'Loyalty PCL' as datatype FROM `spatial-vision-343005.warehouse.view_theo_doi_loyalty_pcl_2026` 
),
loyalty_tp_2026 as 
(
SELECT distinct ma_kh, 'Loyalty TP' as datatype FROM `spatial-vision-343005.warehouse.view_theo_doi_loyalty_tp_2026` 
),
ct_tl_osla as
(
SELECT makhdms, 'Tích lũy Osla' as datatype  FROM `spatial-vision-343005.warehouse.view_tich_luy_osla_t5_2026`
),

mapping_all_ct as (
SELECT * from ct_d_tdisplay
UNION ALL
SELECT *,2025  as nam  from kh_vip_tp
UNION ALL
SELECT *,2025  as nam  from loyalty_tp
UNION ALL
SELECT *,2025  as nam  from loyalty_pcl
UNION ALL
SELECT *,2026  as nam  from loyalty_pcl_2026
UNION ALL
SELECT *,2026  as nam  from loyalty_tp_2026
UNION ALL
SELECT *,2026  as nam  from ct_tl_osla
),
convert_mapping_all_ct as (
select makhachhang as custid,nam,STRING_AGG(datatype) as datatype from mapping_all_ct
group by 1,2
),

convert_mapping_all_ct2 as (
	select a.custid,a.datatype,b.datatype as loc_datatype,a.nam
	from convert_mapping_all_ct a 
	LEFT JOIN mapping_all_ct b on a.custid =b.makhachhang and a.nam =b.nam
),
mapping0 as (
select
  b.custid,
  b.datatype as check_cttl,
	b.loc_datatype,
	b.nam,
	a.custname,
	a.channel,
	a.shoptype,
	a.hcoid,
	a.hcotypeid,
	a.statedescr,
	a.shortterritorydescr,
	a.branchid,
	a.active,
  l.col.ma_nvbh as ma_crs, 
	
from
	convert_mapping_all_ct2 b
	LEFT JOIN `staging.d_master_khachhang` a on upper(trim(a.custid)) = upper(trim(b.custid))
  LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a.custid 

	)

	select a.*,
	h.ma_cre,
	h.ho_ten_cre,
	Case when a.ma_crs ='CX' then 'CX' else d.tencvbh end as ten_crs,
	Case when a.ma_crs ='CX' then 'MR1682' else d.supid end as ma_crm,
	Case when a.ma_crs ='CX' then 'Đinh Thị Ngọc Mẫn' else d.tenquanlytt end as ten_crm,
	Case when a.ma_crs ='CX' then 'MR0485' else d.rsmid  end as ma_ncxm,
	Case when a.ma_crs ='CX' then 'Nguyễn Hoàng Viển' else d.tenquanlyvung end as ten_ncxm,
	timestamp(current_datetime("+7")) as inserted_at
	 from mapping0 a
	LEFT JOIN `staging.d_users` d on d.manv = a.ma_crs
	LEFT JOIN `spatial-vision-343005.staging.d_calendar_cre` h ON a.ma_crs = h.ma_crs AND date(h.thang) = '2025-09-01'

	
  
);

Create or replace table `warehouse.f_tracuu_cttl_kh`

copy `staging_temp.f_tracuu_cttl_kh_temp`;

END;