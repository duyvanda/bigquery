CREATE VIEW `spatial-vision-343005.warehouse.view_rawdata_bbgh_mds`
AS WITH don_da_upload_ben_dms as (
  select distinct ordernbr from `staging.sync_dms_bbgh_checkin`
)

, bbgh as
(
SELECT 
a.imageid,
a.imagename,
a.branchid,
a.custid,
a.salesid,
a.crtd_datetime,
a.crtd_user,
a.lupd_datetime,
a.lupd_user,
a.type,
a.ordernbr,
a.reason,
a.note,
a.visitdate,
a.inserted_at
FROM `spatial-vision-343005.staging.sync_dms_bbgh_checkin` a
UNION ALL

SELECT '1' as imageid, imagename,chi_nhanh, ma_kh, '' as salesid,
inserted_at as crtd_datetime,
manv as crtd_user,
inserted_at as lupd_datetime,
manv as lupd_user,
'' as type,
thong_tin_don_hang_upload as ordernbr,
'' as reason,
'' as note,
inserted_at as visitdate,
inserted_at



FROM
(
  SELECT 
  slsperid as manv, chi_nhanh, thong_tin_don_hang_upload, ma_kh, inserted_at,
  concat("https://bi.meraplion.com/DMS/", chi_nhanh,"/",manv, "/",FORMAT_DATE( "%Y%m", date(inserted_at)),"/%200_",thong_tin_don_hang_upload,".jpeg"     ) as imagename,
  FROM `spatial-vision-343005.staging.d_mds_upload_hinh_anh_bbgh` a
  LEFT JOIN don_da_upload_ben_dms b on b.ordernbr = a.thong_tin_don_hang_upload
  where b.ordernbr is null
  UNION ALL
  SELECT 
  slsperid as manv, chi_nhanh, thong_tin_don_hang_upload, ma_kh, inserted_at,
  case when a.so_luong_anh_upload = 2 then 
  concat("https://bi.meraplion.com/DMS/", chi_nhanh,"/",manv, "/",FORMAT_DATE( "%Y%m", date(inserted_at)),"/%201_",thong_tin_don_hang_upload,".jpeg"     ) 
  else null end as imagename
  FROM `spatial-vision-343005.staging.d_mds_upload_hinh_anh_bbgh` a
  LEFT JOIN don_da_upload_ben_dms b on b.ordernbr = a.thong_tin_don_hang_upload
  where b.ordernbr is null and a.so_luong_anh_upload = 2
)

)

-- SELECT * from bbgh where ordernbr = 'DL7-1124-00386'

SELECT 

a.imageid,
a.imagename,
a.branchid,
a.custid,
c.custname,
c.address,
c.wardname,
c.districtdescr,
c.statedescr,
c.territorydescr,
a.salesid,
a.crtd_datetime,
a.crtd_user,
b.tencvbh as mds_name,
b.supid,
b.tenquanlytt as sup_name,
a.lupd_datetime,
a.lupd_user,
a.type,
a.ordernbr,
a.reason,
a.note,
a.visitdate,
a.inserted_at,
concat(a.custid, ' - ', c.custname) as makh_tenkh,
concat(a.crtd_user, ' - ', b.tencvbh) as manv_tennv,
concat(b.supid, ' - ', b.tenquanlytt) as maql_tenql,
c.shoptype,
c.channel

FROM bbgh a
LEFT JOIN staging.d_users b on a.crtd_user = b.manv
LEFT JOIN staging.d_master_khachhang c on a.custid = c.custid
;