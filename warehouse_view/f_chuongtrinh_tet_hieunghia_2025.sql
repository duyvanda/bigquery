CREATE VIEW `spatial-vision-343005.warehouse.f_chuongtrinh_tet_hieunghia_2025`
AS with 

hco_moi_nhat as 

(
    select custid,hcoid,hcotypeid,channel from `staging.sync_dms_pda_so` f where channel ='TP' and hcoid in ('PMC','CTD') and hcotypeid  in ('CTD','QT','NT','CHDCYK','CSDYDL','QTDN')
    and crtd_datetime >='2024-10-01' and crtd_datetime <'2025-12-31 16:00:00' 
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
 where ifnull(c.channel,e.channel) ='TP' and ifnull(c.hcoid,e.hcoid) in ('PMC','CTD') and ifnull(c.hcotypeid,e.hcotypeid)  in ('CTD','QT','NT','CHDCYK','CSDYDL','QTDN')
and ngaychungtu >='2024-10-01' and ngaychungtu <'2025-01-01' 
group by all

),

hang_km1_cal as (

select 
a.* ,
if(doanhsocovat >= 200000000,200000000,doanhsocovat) as max_doanhsocovat,
Case
    when if(doanhsocovat >= 200000000,200000000,doanhsocovat) >= 40000000 then div(if(doanhsocovat >= 200000000,200000000,cast(doanhsocovat as int)), 40000000)
else 0 end as hang_km1,

from data_sales_tp a
)
,
hang_km2_cal as 

(
select 
*,
Case
    when max_doanhsocovat - 40000000 * hang_km1 >= 25000000
         then div( cast( (max_doanhsocovat - 40000000 * hang_km1) as int), 25000000)    
else 0 end as hang_km2,
 from hang_km1_cal
)
,
result as 

(
select 
*,
Case
    when max_doanhsocovat - 40000000 * hang_km1 - 25000000 * hang_km2 >= 10000000
         then div( cast( (max_doanhsocovat - 40000000 * hang_km1 - 25000000 * hang_km2) as int), 10000000)    
else 0 end as hang_km3,
 from hang_km2_cal
)

select a.*,
b.col.ma_nvbh as  ma_crs,
Case when b.col.ma_nvbh ='CX' then 'CX' else c.tencvbh end as tencvbh,
c.supid as ma_crm,
Case when b.col.ma_nvbh ='CX' then 'Đinh Thị Ngọc Mẫn' else c.tenquanlytt end as tenquanlytt,
c.asm as ma_scrm,
c.tenquanlykhuvuc,
Case when b.col.ma_nvbh ='CX' then 'MR0485' else c.rsmid end as ma_ncxm,
Case when b.col.ma_nvbh ='CX' then 'Nguyễn Hoàng Viển' else c.tenquanlyvung end as tenquanlyvung,
e.custname,
e.statedescr,
e.districtdescr,
e.shortterritorydescr,
e.branchid,

from result a 
LEFT JOIN `warehouse.f_mapping_crs` b on a.makhdms = b.custid
LEFT JOIN `staging.d_users` c on b.col.ma_nvbh = c.manv
LEFT JOIN `staging.d_master_khachhang` e on e.custid =a.makhdms;