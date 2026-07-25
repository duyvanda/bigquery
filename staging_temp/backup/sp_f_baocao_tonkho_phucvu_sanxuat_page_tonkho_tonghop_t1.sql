CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t1()
BEGIN 
  TRUNCATE TABLE staging_temp.f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t1_temp;


 INSERT INTO staging_temp.f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t1_temp(

-- Create table staging_temp.f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t1_temp
-- as

select * from `staging_temp.f_tonkhotonghop_daily` 
where inserted_at = (select max(inserted_at) from `staging_temp.f_tonkhotonghop_daily` )
  );

Create or replace table `warehouse.f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t1`

copy `staging_temp.f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t1_temp`;

End;