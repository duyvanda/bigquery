CREATE PROCEDURE `spatial-vision-343005`.staging_temp.api_tong_quan_ping_me_crs(p_ma_crs STRING)
OPTIONS(
  strict_mode=false)
BEGIN

-- DECLARE p_ma_crs string;
-- set p_ma_crs ='';

with congno as (
  select ma_crs,sum(no_goc) as no_goc,sum(no_xau) as no_xau,round(safe_divide(sum(no_xau), sum(no_goc)) *100,1) as ty_le_no_xau from `staging_temp.api_congno_khach_hang_table` (p_ma_crs)
  group by 1
)
,
doanhso as 
(
  select ma_crs,sum(doanh_so) as doanh_so,sum(ke_hoach) as ke_hoach,round(safe_divide(sum(doanh_so), sum(ke_hoach)) *100,1) as ty_le_th_ds_kh from`staging_temp.api_doanh_so_kh_table` (p_ma_crs)
  group by 1
)
,
tichluy_diamond as 
(
  select ma_crs,count(so_kh_cham_tich_luy) as so_kh_cham_tich_luy,count(ma_kh_dms) as so_kh_tham_gia_diamond,sum(doanh_so_co_vat) as doanh_so_tich_luy from`staging_temp.api_tichluy_diamond_table` (p_ma_crs)
  group by 1
)
,
kh_chua_ps_dh as 
(
  select ma_crs,count(so_khach_hang_chua_ps_dh) as so_khach_hang_chua_ps_dh,count(ma_kh_dms) as sl_kh_mcp from`staging_temp.api_khach_hang_chua_ps_dh_table` (p_ma_crs)
  group by 1
),

checkin as 

(
  select slsperid,tyle_call_checkin,tiendo_viengtham from `spatial-vision-343005.staging_temp.api_checkin_khach_hang_table` (p_ma_crs)
)

select  
coalesce(a.ma_crs,b.ma_crs,c.ma_crs,d.ma_crs,f.slsperid) as ma_crs,
e.tencvbh as ten_crs,
e.tenquanlytt,
b.*except(ma_crs),
f.*except(slsperid),
a.*except(ma_crs),

c.*except(ma_crs),
d.*except(ma_crs)

from congno a 
FULL JOIN doanhso b on a.ma_crs =b.ma_crs
FULL JOIN tichluy_diamond c on coalesce(a.ma_crs,b.ma_crs)= c.ma_crs
FULL JOIN kh_chua_ps_dh d on coalesce(a.ma_crs,b.ma_crs,c.ma_crs) = d.ma_crs
FULL JOIN checkin f on coalesce(a.ma_crs,b.ma_crs,c.ma_crs,d.ma_crs) = f.slsperid
LEFT JOIN `staging.d_users` e on coalesce(a.ma_crs,b.ma_crs,c.ma_crs,d.ma_crs,f.slsperid) =e.manv
order by ty_le_th_ds_kh desc,tiendo_viengtham desc
;
END;