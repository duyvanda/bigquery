CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_boloc_tichluy()
BEGIN 
  TRUNCATE TABLE staging_temp.f_boloc_tichluy_temp;


 INSERT INTO staging_temp.f_boloc_tichluy_temp(
  
--   Create table `staging_temp.f_boloc_tichluy_temp`
-- as

select distinct custid,custname,tinhtp,tencvbh,tenquanlytt,channel from `warehouse.f_hanam_ninhbinh_ct_tichluy`
UNION DISTINCT
select distinct custid,custname,tinhtp,tencvbh,tenquanlytt,channel from `warehouse.f_chuongtrinh_dulich_2023` where tinhtp in('Hà Nam','Nam Định','Ninh Bình')
UNION DISTINCT
select distinct makhdms,tenkhachhang,statedescr,tencvbh,tenquanlytt,makenhkh from `warehouse.f_chuongtrinh_quatang_hethu_tp` where statedescr in('Hà Nam','Nam Định','Ninh Bình')

	 );

Create or replace table `warehouse.f_boloc_tichluy`

copy `staging_temp.f_boloc_tichluy_temp`;


End;