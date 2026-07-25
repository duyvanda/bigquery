CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danhsach_chitiet_donhang_all()
BEGIN 
  TRUNCATE TABLE staging_temp.f_danhsach_chitiet_donhang_all_temp;


 INSERT INTO staging_temp.f_danhsach_chitiet_donhang_all_temp(
-- Create table staging_temp.f_danhsach_chitiet_donhang_all_temp
-- partition by date(ngaytaodon)
-- as

select t1.*,t2.custidinvoice,t2.custnameinvoice
from warehouse.f_leadtime_new_detail1 t1
left join staging.d_master_khachhang t2 on t1.custid=t2.custid

  );

Create or replace table `warehouse.f_danhsach_chitiet_donhang_all`

copy `staging_temp.f_danhsach_chitiet_donhang_all_temp`;

End;