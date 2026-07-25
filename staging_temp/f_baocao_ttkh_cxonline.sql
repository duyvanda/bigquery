CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_baocao_ttkh_cxonline()
BEGIN 
 
 TRUNCATE TABLE staging_temp.f_baocao_ttkh_cxonline_temp;

 INSERT INTO `staging_temp.f_baocao_ttkh_cxonline_temp`

(   

-- Create or replace table `staging_temp.f_baocao_ttkh_cxonline_temp` as

SELECT 
  a.*,
  b.shoptype, 
  c.supid
FROM `spatial-vision-343005.staging.d_cx_ttkh` a
left join `spatial-vision-343005.staging.d_master_khachhang` b on a.ma_kh = b.custid
left join `spatial-vision-343005.staging.d_users` c on a.ma_nv_crs = c.manv




);

Create or replace table `warehouse.f_baocao_ttkh_cxonline`

copy `staging_temp.f_baocao_ttkh_cxonline_temp`;

END;