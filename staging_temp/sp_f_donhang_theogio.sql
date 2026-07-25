CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_donhang_theogio()
BEGIN 
  TRUNCATE TABLE staging_temp.f_donhang_theogio_temp;


 INSERT INTO staging_temp.f_donhang_theogio_temp(

-- Create or replace table staging_temp.f_donhang_theogio_temp
-- partition by date(crtd_datetime)
-- as

select 
  distinct a.*except(phuongxa), b.crtd_datetime,--b.*except(inserted_at),  
  c.supid as masup_bh,
  extract(hour from b.crtd_datetime) thoigian,
  d.cluster_state 
from staging.f_sales a 
left join staging.sync_dms_pda_so b ON a.macongtycn = b.branchid
                                   AND a.sodondathang = b.ordernbr
left join `spatial-vision-343005.staging.d_users` c on a.manv = c.manv
left join `staging.d_master_khachhang` d on a.makhdms = d.custid
WHERE
kieudonhang = 'IN'
and date(ngaychungtu) >= "2023-01-01"

  );

Create or replace table `warehouse.f_donhang_theogio`

copy `staging_temp.f_donhang_theogio_temp`;

End;