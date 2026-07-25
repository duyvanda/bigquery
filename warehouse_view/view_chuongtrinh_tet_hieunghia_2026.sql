CREATE VIEW `spatial-vision-343005.warehouse.view_chuongtrinh_tet_hieunghia_2026`
AS with 

hco_moi_nhat as 

(
    select custid,hcoid,hcotypeid,channel 
    from `staging.sync_dms_pda_so` f 
    where channel ='TP' 
    and hcoid in ('PMC','CTD') 
    --and hcotypeid  in ('CTD','QT','NT','CHDCYK','CSDYDL','QTDN')
    and crtd_datetime >='2025-10-01' 
    and crtd_datetime <'2025-12-26 16:00:00' 
    qualify row_number() over (partition by custid order by crtd_datetime desc) = 1
)
,
data_sales_tp  as (
select 
a.makhdms,
ifnull(c.hcoid,e.hcoid) as mahco,
ifnull(c.hcotypeid,e.hcotypeid) as  maphanloai_hco,
ifnull(c.channel,e.channel) as  channel,
sum(Case when extract(month from ngaychungtu) = 10 then doanhsocovat else 0 end) as ds_covat_t10,
sum(Case when extract(month from ngaychungtu) = 11 then doanhsocovat else 0 end) as ds_covat_t11,
sum(Case when extract(month from ngaychungtu) = 12 then doanhsocovat else 0 end) as ds_covat_t12,
sum(doanhsocovat) as doanhsocovat,
max(a.inserted_at) as inserted_at
 from `staging.f_sales` a 
 LEFT JOIN `staging.sync_dms_pda_so` b on a.macongtycn =b.branchid and a.sodondathang =b.ordernbr
 LEFT JOIN hco_moi_nhat c on a.makhdms = c.custid
 LEFT JOIN `staging.d_master_khachhang` e on e.custid =a.makhdms
 where ifnull(c.channel,e.channel) ='TP' 
 and ifnull(c.hcoid,e.hcoid) in ('PMC','CTD') 
 --and ifnull(c.hcotypeid,e.hcotypeid)  in ('CTD','QT','NT','CHDCYK','CSDYDL','QTDN')
and ngaychungtu >='2025-10-01' and ngaychungtu <='2025-12-26' 
group by all

),

hang_km3_cal as (

select 
a.* ,
if(doanhsocovat >= 200000000,200000000,doanhsocovat) as max_doanhsocovat,
Case
    when if(doanhsocovat >= 200000000,200000000,doanhsocovat) >= 40000000 then div(if(doanhsocovat >= 200000000,200000000,cast(doanhsocovat as int)), 40000000)
else 0 end as hang_km3,

from data_sales_tp a
)
,
hang_km2_cal as 

(
select 
*,
Case
    when max_doanhsocovat - 40000000 * hang_km3 >= 25000000
         then div( cast( (max_doanhsocovat - 40000000 * hang_km3) as int), 25000000)    
else 0 end as hang_km2,
 from hang_km3_cal
)
,
result as 

(
select 
*,
Case
    when max_doanhsocovat - 40000000 * hang_km3 - 25000000 * hang_km2 >= 10000000
         then div( cast( (max_doanhsocovat - 40000000 * hang_km3 - 25000000 * hang_km2) as int), 10000000)    
else 0 end as hang_km1,
 from hang_km2_cal
)

select a.*,
Case
    when a.doanhsocovat >= 40000000 then 0.035
    when a.doanhsocovat >= 25000000 then 0.032
    when a.doanhsocovat >= 10000000 then 0.030
    else 0 end as km,
b.col.ma_nvbh as  ma_crs,
c.tencvbh,
c.supid as ma_crm,
c.tenquanlytt,
c.asm as ma_scrm,
c.tenquanlykhuvuc,
c.rsmid,
c.tenquanlyvung,
e.custname,
e.statedescr,
e.districtdescr,
e.shortterritorydescr,
e.branchid,
h.ma_cre,
h.ho_ten_cre
from result a 
LEFT JOIN `warehouse.f_mapping_crs` b on a.makhdms = b.custid
LEFT JOIN `staging.d_users` c on b.col.ma_nvbh = c.manv
LEFT JOIN `staging.d_master_khachhang` e on e.custid =a.makhdms
LEFT JOIN `spatial-vision-343005.staging.d_calendar_cre` h ON b.col.ma_nvbh = h.ma_crs AND date(h.thang) = DATE_TRUNC(DATE(CURRENT_DATE()),MONTH)







;