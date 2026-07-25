CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_lichsuthaydoithongtinkhachhang()
BEGIN 
  TRUNCATE TABLE staging_temp.f_lichsuthaydoithongtinkhachhang_temp;

 INSERT INTO staging_temp.f_lichsuthaydoithongtinkhachhang_temp(
-- Create table staging_temp.f_lichsuthaydoithongtinkhachhang_temp
-- partition by date(lupd_datetime)
-- as
SELECT 
a.*,
b.firstname,
c.branchid,
c.channel,
c.shoptype,
c.territorydescr, 
c.statedescr,
c.custname
FROM `spatial-vision-343005.staging.d_tracking_cust_changes`  a
left join `staging.d_dms_master_users` b on a.lupd_user = b.username
left join `staging.d_master_khachhang` c on a.custid =  c.custid
where changetype != 'custidpublic'

  );

Create or replace table `warehouse.f_lichsuthaydoithongtinkhachhang`

copy `staging_temp.f_lichsuthaydoithongtinkhachhang_temp`;

End;