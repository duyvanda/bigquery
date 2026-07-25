CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_tracuu_sp_ctkm()
OPTIONS(
  strict_mode=false)
BEGIN 
 
 TRUNCATE TABLE staging_temp.f_tracuu_sp_ctkm_temp;

 INSERT INTO `staging_temp.f_tracuu_sp_ctkm_temp`

(

-- Create or replace table `staging_temp.f_tracuu_sp_ctkm_temp`
-- as

SELECT
    a.discseq,
    a.discidpn,
    a.discounttype,
    a.discountdescr,
    a.descr, 
    a.startdate,
    a.enddate,
    case when (cast(a.enddate as datetime)) >= current_datetime() then 1 else 0 end as active,
    a.statusname,
    b.invtid, 
    b.descr as tensp
  FROM `spatial-vision-343005.staging.d_discseq` a
  left join `spatial-vision-343005.staging.d_discitem` b on a.discid = b.discid and a.discseq = b.discseq

);

Create or replace table `warehouse.f_tracuu_sp_ctkm`

copy `staging_temp.f_tracuu_sp_ctkm_temp`;

END;