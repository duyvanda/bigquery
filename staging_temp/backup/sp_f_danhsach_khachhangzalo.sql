CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danhsach_khachhangzalo()
BEGIN 
  TRUNCATE TABLE staging_temp.f_danhsach_khachhangzalo_temp;


 INSERT INTO staging_temp.f_danhsach_khachhangzalo_temp (

-- CREATE OR REPLACE table staging_temp.f_danhsach_khachhangzalo_temp
-- as

with bang1 as (
  select 
  distinct date (thoidiemtao) as ngaytao,
  makhdms as makhOA,
  'OA' as source,
  *,
  row_number() over (partition by makhdms order by thoidiemtao asc ) as loc
from `spatial-vision-343005.staging.d_caresoft_customer`
) 

select a.*,
case when makhdms is not null and loc = 1 then 'Y'
WHEN makhdms is null then 'Y' else 'N' end as check,
b.channel,
b.shoptype,
b.taxregnbr

 from bang1 a 
 LEFT JOIN `staging.d_master_khachhang` b on a.makhOA=custid



  );

Create or replace table `warehouse.f_danhsach_khachhangzalo`

copy `staging_temp.f_danhsach_khachhangzalo_temp`;


End;