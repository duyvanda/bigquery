CREATE VIEW `spatial-vision-343005.warehouse.view_checking_display_criteria_mds_quy3`
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
-- locationdescr,
inserted_at

FROM `spatial-vision-343005.staging.d_display_criteria_remark` 
QUALIFY row_number() over (partition by displayid, custid ) = 1

)

SELECT
CASE

when chuongtrinh = 'Khung Ebysta Q3.24' then '2401-CTTB-CPA02-NT-QT' 
when chuongtrinh = 'Sticker Lá đôi Q3.24' then '2401-CTTB-CPA03-NT-QT'  
when chuongtrinh = 'Decal Xisat Q3.24' then '2401-CTTB-CPA01-NT-QT'
END as chuongtrinh_code,
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


case when b.displayid is not null then 1 else 0 end as da_cham,

FROM `spatial-vision-343005.staging.dsdh_chuong_trinh_di_cham_mds` a
LEFT JOIN da_di_cham b
on 
(
CASE
when chuongtrinh = 'Khung Ebysta Q3.24' then '2401-CTTB-CPA02-NT-QT' 
when chuongtrinh = 'Sticker Lá đôi Q3.24' then '2401-CTTB-CPA03-NT-QT'  
when chuongtrinh = 'Decal Xisat Q3.24' then '2401-CTTB-CPA01-NT-QT'
END
) = b.displayid
and a.madms = b.custid

LEFT JOIN `spatial-vision-343005.staging.d_users` c ON trim(a.mamds) = c.manv
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` d ON a.madms = d.custid
WHERE date(a.inserted_at) >= '2024-07-01' and date(a.inserted_at) <= '2024-11-26'


;