CREATE VIEW `spatial-vision-343005.warehouse.view_dskh_zalo_oa_tham_gia_ambassador`
AS -- Zalo OA
SELECT 
date(a.updated_at) as ngay,
c.manv,
c.tencvbh,
c.supid,
c.tenquanlytt,
a.customer_role_name as vai_tro,
a.classid,
a.customer_code,
NULL as category,
follow_phone as phone,
0 as tong_sl_nguoi_tim_hieu,
'zalo' as type
FROM `spatial-vision-343005.warehouse.f_danhsach_ketnoi_zalo_oa` a
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` b ON b.custid = a.customer_code
LEFT JOIN `spatial-vision-343005.staging.d_users` c ON c.manv = b.col. ma_nvbh
WHERE a.channel = 'TP'
AND c.supid is not null
GROUP BY ALL


---data_tham_gia_ambassador
 UNION ALL
 SELECT
 date(a.inserted_at) as ngay,
 a.ma_nvbh,
 a.tencvbh,
 a.supid,
 a.tenquanlytt,
 a.vai_tro,
 b.classid,
 a.ma_kh_dms,
 a.category,
 a.phone,
 COUNT(DISTINCT a.phone) OVER() as tong_sl_nguoi_tim_hieu,
 'ambassador' as type

FROM `spatial-vision-343005.warehouse.view_nvbc_track_view_by_users` a
LEFT JOIN `staging.d_master_khachhang` b on a.ma_kh_dms = b.custid
WHERE a.category IS NOT NULL
--GROUP By ALL













;