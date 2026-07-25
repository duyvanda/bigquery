CREATE VIEW `spatial-vision-343005.warehouse.view_checking_display_criteria_mds_quy32025`
AS with da_di_cham as
(
SELECT 
ma_mds, 
custid, 
displayid, 
visitdate,
result,
img1, 
img2, 
img3, 
inserted_at

FROM `spatial-vision-343005.staging.d_display_criteria_remark` 
where date(visitdate) >= '2025-09-01' and date(visitdate) <= '2025-10-31'
--QUALIFY row_number() over (partition by displayid, custid ) = 1
--Sticker Lá đôi Q3.25	2501-CTTB-CPA10-NT-QT	N06202304	QT Lê Như - Tuy Phong - Bình Thuận	MR2965	Đỗ Văn Huy case này CRS cũng chấm nên lại ưu tiên của CRS

)

SELECT
machuongtrinh as chuongtrinh_code,
chuongtrinh,
madms as custid,
tenkhachhangnoibo,
mamds as ma_mds_di_cham,
tenmdschamtrungbay,

b.inserted_at,
result,
img1,
img2,
img3,
supid,
tenquanlytt,
channel,
statedescr,
hcotypeid,
branchid,
shortterritorydescr,
visitdate,
custname,


case when b.displayid is not null then 1 else 0 end as da_cham,

FROM `spatial-vision-343005.staging.dsdh_chuong_trinh_di_cham_mds` a
LEFT JOIN da_di_cham b
on a.machuongtrinh = b.displayid
and a.madms = b.custid
and a.mamds = b.ma_mds

LEFT JOIN `spatial-vision-343005.staging.d_users` c ON trim(a.mamds) = c.manv
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` d ON a.madms = d.custid
WHERE date(a.inserted_at) >= '2025-09-01' and date(a.inserted_at) <= '2025-09-30'


;