CREATE VIEW `spatial-vision-343005.warehouse.view_tong_hop_chinh_sach`
AS SELECT  
loaivanbancap1,
nhomnoidung,
phongban,
phongbanlienquan,
sovanban,
tenvanban,
ngaybatdauhieuluc,
ngayketthuchieuluc,
sovanbanthaythe,
thaythechovanban,
phanquyen,
linkvanban,
bosungchovanban,

b.msnvcsmmoi,
b.hovatenfullname,
b.chucdanhvntitle,
b.chucdanhengtitle,
b.chucdanhengtitlesum,

CASE 
    WHEN ngayketthuchieuluc IS NULL OR ngayketthuchieuluc >= TIMESTAMP(CURRENT_DATE()) THEN 'Còn hiệu lực'
    ELSE 'Hết hiệu lực'
END AS conhieuluc_hethieuluc


FROM `spatial-vision-343005.staging.d_manual_tong_hop_quy_dinh_cs_mai_phuong`  a
LEFT JOIN `spatial-vision-343005.staging.d_hr_dsns`   b ON a.phanquyen = b.chucdanhengtitlesum
--where msnvcsmmoi = 'MR0771'	





;