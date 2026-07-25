CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_canhbaoruiro_congno_mds()
BEGIN 
  TRUNCATE TABLE staging_temp.f_canhbaoruiro_congno_mds_temp;


 INSERT INTO staging_temp.f_canhbaoruiro_congno_mds_temp(

-- Create table staging_temp.f_canhbaoruiro_congno_mds_temp
-- as
with a as 
( 
  SELECT *,
    case when tiennocongty < 20000000 then 0 else 1 end as ngaycongno

  from ( SELECT 
          slsperid,
          slspername,
          tenquanlytt,
          tenquanlyvung,
          tenquanlykhuvuc,
          sum(tiennocongty) as tiennocongty,
          date(updated_at)  as updated_at
          FROM `spatial-vision-343005.staging.f_daily_capture_notoihan_taixe_hanh`
        --where terms not in ('Gối 1 Đơn Hàng (trong 30 ngày)')
          GROUP BY slsperid,slspername,tenquanlytt,tenquanlyvung,tenquanlykhuvuc,date(updated_at) 
       ) a 
)
,

b as
(  
  SELECT *,
    row_number() over (ORDER BY updated_at desc, tiennocongty desc) as row_ 
  from a 
  where updated_at = ( SELECT max(updated_at)  
                       from a) 
)

SELECT a.* ,
  case when b.row_ is null then ( SELECT max(b.row_) 
                                  from b 
                                  where b.row_ is not null
                                ) + 1 
                           else b.row_ end as row_ 
from a
LEFT JOIN b on a.slsperid = b.slsperid
ORDER BY b.row_

);

Create or replace table `warehouse.f_canhbaoruiro_congno_mds`

copy `staging_temp.f_canhbaoruiro_congno_mds_temp`;


End;