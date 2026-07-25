CREATE VIEW `spatial-vision-343005.warehouse.view_dskh_dinh_danh_pingme`
AS WITH dskh as (

SELECT
DISTINCT
custid as ma_kh_dms,
custname as ten_kh,
statedescr,
hcoid,
hcotypeid,
channel
FROM `spatial-vision-343005.staging.d_master_khachhang`
where hcoid = 'PMC' and channel = 'TP' and active = 'Active'

UNION ALL
SELECT
DISTINCT
custid as ma_kh_dms,
a.custname as ten_kh,
a.statedescr,
a.hcoid,
a.hcotypeid,
a.channel
FROM `spatial-vision-343005.staging.d_master_khachhang` a
Where channel = 'PCL' and active = 'Active' and branchid not in ('DL0001')
)
,ds_dk_dai_dien as (
  SELECT
  DISTINCT
  customer_code,
  follow_name,
  follow_phone,
  citizenIdentity_number
  FROM `spatial-vision-343005.warehouse.view_ds_ket_noi_zalo_oa` 
  WHERE customer_role_name in( 'Đại diện ký HĐ', 'Người đại diện ký hợp đồng')
)

SELECT
a.*,
c.col.ma_nvbh as ma_crs,
d.tencvbh as ten_crs,
d.supid as ma_crm,
d.tenquanlytt as ten_crm,
b.follow_name as nguoi_dai_dien_ky_hop_dong,
b.citizenIdentity_number as citizenid,
b.follow_phone as phone

FROM dskh a 
LEFT JOIN ds_dk_dai_dien b ON b.customer_code = a.ma_kh_dms
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` c ON a.ma_kh_dms = c.custid
LEFT JOIN `spatial-vision-343005.staging.d_users` d ON d.manv = c.col.ma_nvbh 





;