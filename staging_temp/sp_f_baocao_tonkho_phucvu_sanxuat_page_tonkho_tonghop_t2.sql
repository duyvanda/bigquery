CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t2()
BEGIN 
  TRUNCATE TABLE staging_temp.f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t2_temp;


 INSERT INTO staging_temp.f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t2_temp(
-- Create table `staging_temp.f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t2_temp`
-- as
with 
  base_name as
  ( select *
   from (select masanpham,tensanpham,row_number() over (partition by masanpham order by (toncn+tonhcm+tonao+tonhangdiduong+tonvime+tonnmtp+tonnmhh) desc) as row_
         from `spatial-vision-343005.staging.f_sc_daily_invt` ) b
 where row_=1
    )
    
   


select  a.masanpham,a.created_date,c.tensanpham,a.ton_kho_cn,a.ton_kho_nm


from (select 
	 masanpham
      ,date(created_date) created_date
	--, tensanpham
	,sum(toncn+tonhcm+tonao+tonhangdiduong+tonvime+tonmerap) ton_kho_cn --
	,sum(tonnmtp+tonnmhh) ton_kho_nm
	from `spatial-vision-343005.staging.f_sc_daily_invt`
    
    group by 1,2) a

left join base_name c on a.masanpham =c.masanpham

  );

Create or replace table `warehouse.f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t2`

copy `staging_temp.f_baocao_tonkho_phucvu_sanxuat_page_tonkho_tonghop_t2_temp`;

End;