CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_d_nhietdo_doam_detail()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.d_nhietdo_doam_detail_temp`;


 INSERT INTO `staging_temp.d_nhietdo_doam_detail_temp`

(   


select congty,cambien,ngay,gio,h,nhietdo,doam,trong_gio,vuot_nhietdo,vuot_doam,
concat('Tuần ',tuan,"/Tháng ",thang,"/Năm ",nam) as tuan,
Case when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM' then 'HỒ CHÍ MINH'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN KHÁNH HÒA' then 'KHÁNH HÒA'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN ĐỒNG NAI' then 'ĐỒNG NAI'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN NGHỆ AN' then 'NGHỆ AN'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN ĐÀ NẴNG' then 'ĐÀ NẴNG'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN CẦN THƠ' then 'CẦN THƠ'
 when congty=
'CÔNG TY CỔ PHẦN DƯỢC PHA NAM - CN HÀ NỘI' then 'HÀ NỘI' else null end as chinhanh
 from `staging.f_nhietdo_doam`

 );

Create or replace table `warehouse.d_nhietdo_doam_detail`

copy `staging_temp.d_nhietdo_doam_detail_temp`;




END;