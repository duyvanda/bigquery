CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuong_trinh_tich_luy_gold()
BEGIN 
 
 TRUNCATE TABLE staging_temp.f_chuong_trinh_tich_luy_gold_temp;


 INSERT INTO `staging_temp.f_chuong_trinh_tich_luy_gold_temp`

(  

-- Create or replace table staging_temp.f_chuong_trinh_tich_luy_gold_temp as 

with 
tach_pl_sp as (
SELECT 
trim(ma_sp) as ma_sp,
pl_diamon,
parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(1)]) as start_date,
parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(2)]) as end_date,
 FROM `spatial-vision-343005.staging.d_manual_danhsach_khachhang_diamond` 
 where ma_sp is not null
and parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(2)]) >='2024-01-01'
),

base_date as (
    select
    distinct date(date_trunc(day,month)) as thang,'ML1' as pl_diamon
    from
        unnest(
            GENERATE_DATE_ARRAY(
                date_sub(current_date("+7"), interval 2 year),
                date_add(current_date("+7"), interval 2 year)
            )
        ) as day
    UNION ALL
        select
    distinct date(date_trunc(day,month)) as thang,'ML2' as pl_diamon
    from
        unnest(
            GENERATE_DATE_ARRAY(
                date_sub(current_date("+7"), interval 2 year),
                date_add(current_date("+7"), interval 2 year)
            )
        ) as day
    UNION ALL
        select
    distinct date(date_trunc(day,month)) as thang,'ML3' as pl_diamon
    from
        unnest(
            GENERATE_DATE_ARRAY(
                date_sub(current_date("+7"), interval 2 year),
                date_add(current_date("+7"), interval 2 year)
            )
        ) as day
),

tuyen_dms_moinhat as (
    with data_tuyen as (
        SELECT
            custid,
            slsperid,
            crtd_datetime,
            Case
                when routetype in ('B', 'D') then 1
                else 2
            end as routetype,
        FROM
            `spatial-vision-343005.staging.sync_dms_srm`
        where
            delroutedet is false
    )
    select
        *
    from
        data_tuyen 
        qualify row_number() over (
            partition by custid
            order by
                routetype asc,
                crtd_datetime desc
        ) = 1
),

danh_sach_gold_ml1 as 
(
  select 
a.ma_hco_tren_dms, 
cast(a.suat_tham_gia as int) as suat_tham_gia,
cast(a.dk_ml1 as int) * 1000 as dk_ml1,
0 as dk_ml2,
0 as dk_ml3,
cast(a.tong_dk as int) * 1000 as tong_dk,
cast(a.dk_ml1 as int) * 1000 as tong_dk_pl,
a.doanh_so_tinh_tu,
a1.thang as thang,
'Q' ||extract(quarter from a1.thang) || '-' || extract(year from a1.thang) as quy,
extract(month from a1.thang) || '-' || extract(year from a1.thang) as thang_nam,
'diamond' as datatype,
'ML1' as pl_diamon,
0 as doanhso_ml1,
0 as doanhso_ml2,
0 as doanhso_ml3,
0 as doanhso_chua_pl,
0 as doanhsocovat
from 
`staging.d_manual_danh_sach_gold` a
LEFT JOIN base_date a1 on date(a1.thang) = date(a.doanh_so_tinh_tu) and a1.pl_diamon ='ML1'
),

danh_sach_gold_ml2 as 
(
  select 
a.ma_hco_tren_dms, 
0 as suat_tham_gia,
0 dk_ml1,
cast(a.dk_ml2 as int) * 1000 as dk_ml2,
0 dk_ml3,
cast(a.tong_dk as int) * 1000 as tong_dk,
cast(a.dk_ml2 as int) * 1000 as tong_dk_pl,
a.doanh_so_tinh_tu,
a1.thang as thang,
'Q' ||extract(quarter from a1.thang) || '-' || extract(year from a1.thang) as quy,
extract(month from a1.thang) || '-' || extract(year from a1.thang) as thang_nam,
'diamond' as datatype,
'ML2' as pl_diamon,
0 as doanhso_ml1,
0 as doanhso_ml2,
0 as doanhso_ml3,
0 as doanhso_chua_pl,
0 as doanhsocovat
from 
`staging.d_manual_danh_sach_gold` a
LEFT JOIN base_date a1 on date(a1.thang) = date(a.doanh_so_tinh_tu) and a1.pl_diamon ='ML2'
),

danh_sach_gold_ml3 as 
(
  select 
a.ma_hco_tren_dms, 
0 as suat_tham_gia,
0 dk_ml1,
0 dk_ml2,
cast(a.dk_ml3 as int) * 1000 as dk_ml3,
cast(a.tong_dk as int) * 1000 as tong_dk,
cast(a.dk_ml3 as int) * 1000 as tong_dk_pl,
a.doanh_so_tinh_tu,
a1.thang as thang,
'Q' ||extract(quarter from a1.thang) || '-' || extract(year from a1.thang) as quy,
extract(month from a1.thang) || '-' || extract(year from a1.thang) as thang_nam,
'diamond' as datatype,
'ML3' as pl_diamon,
0 as doanhso_ml1,
0 as doanhso_ml2,
0 as doanhso_ml3,
0 as doanhso_chua_pl,
0 as doanhsocovat
from 
`staging.d_manual_danh_sach_gold` a
LEFT JOIN base_date a1 on date(a1.thang) = date(a.doanh_so_tinh_tu) and a1.pl_diamon ='ML3'
),

raw_sales as (
  select 
  makhdms,
  date(date_trunc(date(b.ngaychungtu),month)) as thang,
  c.pl_diamon, 
  sum(Case when date(ngaychungtu) >= date(a.doanh_so_tinh_tu) and c.pl_diamon = 'ML1' then b.doanhsocovat else 0 end) as doanhso_ml1,
  sum(Case when date(ngaychungtu) >= date(a.doanh_so_tinh_tu) and c.pl_diamon = 'ML2' then b.doanhsocovat else 0 end) as doanhso_ml2,
  sum(Case when date(ngaychungtu) >= date(a.doanh_so_tinh_tu) and c.pl_diamon = 'ML3' then b.doanhsocovat else 0 end) as doanhso_ml3,
  sum(Case when date(ngaychungtu) >= date(a.doanh_so_tinh_tu) and c.pl_diamon is null then b.doanhsocovat else 0 end) as doanhso_chua_pl,

  sum(Case when date(ngaychungtu) >= date(a.doanh_so_tinh_tu) then b.doanhsocovat else 0 end) as doanhsocovat
  
  from `warehouse.f_sales_crs` b
  JOIN `staging.d_manual_danh_sach_gold` a on b.makhdms =a.ma_hco_tren_dms and date(b.ngaychungtu) >= date(a.doanh_so_tinh_tu)
  LEFT JOIN tach_pl_sp c on b.masanpham = trim(c.ma_sp) 
  where ngaychungtu >='2024-01-01' and makenhkh <> 'OTH_LAB'
   and ngaychungtu < '2025-01-01'
  group by 1,2,3
),

result0 as (
select 
a.ma_hco_tren_dms as ma_kh_dms, 
0 as suat_tham_gia,
0 as dk_ml1,
0 as dk_ml2,
0 as dk_ml3,
0 as tong_dk,
0 as tong_dk_pl,
a.doanh_so_tinh_tu,
a1.thang as thang,
'Q' ||extract(quarter from date(a1.thang)) || '-' || extract(year from a1.thang) as quy,
extract(month from date(a1.thang)) || '-' || extract(year from date(a1.thang)) as thang_nam,
'sales' as datatype,
a1.pl_diamon,
ifnull(doanhso_ml1,0) as doanhso_ml1,
ifnull(doanhso_ml2,0) as doanhso_ml2,
ifnull(doanhso_ml3,0) as doanhso_ml3,
ifnull(doanhso_chua_pl,0) as doanhso_chua_pl,
ifnull(doanhsocovat,0) as doanhsocovat

from 
`staging.d_manual_danh_sach_gold` a
LEFT JOIN base_date a1 on 1=1 and a1.thang >='2023-10-01'  and a1.thang < current_date("+7")
LEFT JOIN raw_sales b on a.ma_hco_tren_dms =b.makhdms  and a1.thang = b.thang and a1.pl_diamon = b.pl_diamon

),

union_all as  
(

select * from result0
union all
select * from danh_sach_gold_ml1
union all
select * from danh_sach_gold_ml2
union all
select * from danh_sach_gold_ml3
)


select 
a.*,
round(cast(doanhso_ml1 as int) / 1000000 *10,4) as diemtichluy_ml1,
round(cast(doanhso_ml2 as int) / 1000000 *4,4) as diemtichluy_ml2,
round(cast(doanhso_ml3 as int) / 1000000 *7,4) as diemtichluy_ml3,
b.custname,
b.channel,
b.shoptype,
b.statedescr,
b.shortterritorydescr,
b.hcoid,
b.hcotypeid,
b.branchid,
b.branchname,
c.col.ma_nvbh as slsperid,
d.tencvbh,
d.supid,
d.tenquanlytt,
d.asm,
d.tenquanlykhuvuc,
d.rsmid,
d.tenquanlyvung,
current_timestamp() + interval 7 hour as inserted_at

 from union_all a 
 LEFT JOIN `staging.d_master_khachhang`b on a.ma_kh_dms =b.custid
 LEFT JOIN `warehouse.f_mapping_crs` c on c.custid = a.ma_kh_dms
--  LEFT JOIN tuyen_dms_moinhat c on a.ma_kh_dms = c.custid
--  LEFT JOIN `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` g1 on g1.phuongxa is not null
--         and trim(upper(concat(concat(g1.tinhtp, g1.quanhuyen), g1.phuongxa))) = trim(  upper( concat(concat(b.statedescr, b.districtdescr), b.wardname) ) ) and g1.ncrm like '%Viển%'
--  LEFT JOIN `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` g2 on g2.phuongxa is null
--         and trim(upper(concat(g2.tinhtp, g2.quanhuyen))) = trim(upper(concat(b.statedescr, b.districtdescr))) and g2.ncrm like '%Viển%'
 LEFT JOIN `staging.d_users` d on c.col.ma_nvbh  = d.manv

);

Create or replace table `warehouse.f_chuong_trinh_tich_luy_gold`

copy `staging_temp.f_chuong_trinh_tich_luy_gold_temp`;


END;