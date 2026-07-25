CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_theodoi_danhsach_diamond()
BEGIN
 
TRUNCATE TABLE staging_temp.f_theodoi_danhsach_diamond_temp;

INSERT INTO `staging_temp.f_theodoi_danhsach_diamond_temp`

(   
-- Create or replace table staging_temp.f_theodoi_danhsach_diamond_temp as

with 

da_tra_diamond as (
  select custid,date(date_trunc(date(todate),month)) as thang,sum(paidamt) as da_tra
 from staging.f_paidso_acculate 
 where AccumulateID = '202310-TL-QD786-NT-QT-PKN-PKQ'
 group by 1,2
)
,
tach_pl_theonam_2023 as (
SELECT ma_sp,
pl_diamon,
parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(1)]) as start_date,
parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(2)]) as end_date,
 FROM `spatial-vision-343005.staging.d_manual_danhsach_khachhang_diamond` where ma_sp is not null
and parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(2)]) <'2024-01-01'
),

tach_pl_theonam_2024 as (
SELECT ma_sp,
pl_diamon,
parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(1)]) as start_date,
parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(2)]) as end_date,
 FROM `spatial-vision-343005.staging.d_manual_danhsach_khachhang_diamond` where ma_sp is not null
and parse_date("%d/%m/%Y" ,split(ten_san_pham,"&&")[OFFSET(2)]) >='2024-01-01'
),

_ctkm_xit_phan_lieu as
(
  select 
  branchid, 
  ordernbr, 
  split(
  case
  when groupreflineref is null then solineref
  when solineref = '' or solineref is null or freeitemqty < 1 then groupreflineref
  else concat(groupreflineref,",",solineref) end
  ) as groupreflineref
  from `staging.f_orddisc_all`  
  where discidpn in ('202311-DH-CPA54-PMC-CTD-SI-PCL','202403-DH-CPA11-PMC-CTD','202401-DH-CPA04-PMC-PCL')
),

ctkm_xit_phan_lieu as
(
  select 
  distinct
  branchid,
  ordernbr,
  groupreflineref 
  FROM _ctkm_xit_phan_lieu, _ctkm_xit_phan_lieu.groupreflineref AS groupreflineref
),

ds_ctkm_xit_phan_lieu as (
select 
b.makhdms,
ifnull(c.pl_diamon,d.pl_diamon) as pl_diamon,
date(date_trunc(ngaychungtu,month)) as thang,
sum(Case when ifnull(c.pl_diamon,d.pl_diamon) = 'ML1' and date(ngaychungtu) >= date( e.doanh_so_tinh_tu) then b.doanhsocovat else 0 end) as doanhso_xpl_ml1,
sum(Case when ifnull(c.pl_diamon,d.pl_diamon) = 'ML2' and date(ngaychungtu) >= date( e.doanh_so_tinh_tu) then b.doanhsocovat else 0 end) as doanhso_xpl_ml2,
sum(Case when ifnull(c.pl_diamon,d.pl_diamon) = 'ML3' and date(ngaychungtu) >= date( e.doanh_so_tinh_tu) then b.doanhsocovat else 0 end) as doanhso_xpl_ml3,
sum(Case when ifnull(c.pl_diamon,d.pl_diamon) = 'ML1' and date(ngaychungtu) >= date( e.doanh_so_tinh_tu) then b.doanhsochuavat else 0 end) as doanhso_xpl_ml1_chuavat,
sum(Case when ifnull(c.pl_diamon,d.pl_diamon) = 'ML2' and date(ngaychungtu) >= date( e.doanh_so_tinh_tu) then b.doanhsochuavat else 0 end) as doanhso_xpl_ml2_chuavat,
sum(Case when ifnull(c.pl_diamon,d.pl_diamon) = 'ML3' and date(ngaychungtu) >= date( e.doanh_so_tinh_tu) then b.doanhsochuavat else 0 end) as doanhso_xpl_ml3_chuavat,
from ctkm_xit_phan_lieu a 
LEFT JOIN `warehouse.f_raw_data_sales_yoy` b on b.mahd =a.ordernbr and b.macongtycn=a.branchid and a.groupreflineref =b.lineref and ngaychungtu >='2023-10-01'and b.makenhkh <> 'OTH_LAB' and ngaychungtu < '2024-12-26'
LEFT JOIN tach_pl_theonam_2023 c on b.masanpham = trim(c.ma_sp) and c.ma_sp is not null and date(b.ngaychungtu) >= c.start_date and date(b.ngaychungtu) <=c.end_date
LEFT JOIN tach_pl_theonam_2024 d on b.masanpham = trim(d.ma_sp) and d.ma_sp is not null and date(b.ngaychungtu) >= d.start_date and date(b.ngaychungtu) <=d.end_date
LEFT JOIN `staging.d_manual_danhsach_khachhang_diamond` e on b.makhdms =e.ma_kh_dms
group by 1,2,3
),

tichluy_datra_ttmb as (
 select
    -- branchid,
    -- ordernbr,
    -- lineref,
    custid,
    'ML1' as pl_diamon,
    date(date_trunc(cast(todate as date),month)) as thang,
    sum(paidamt) as doanhso_ttmb_ml1,
    0 as doanhso_ttmb_ml2,
    0 as doanhso_ttmb_ml3,
  from
    `staging.f_paidso_acculate` a 

  where
    accumulateid in('202301-TL-QD01-NT-QT-PKN-PKQ','202401-TL-QD976-PMC-CTD','202401-TL-QD974-PMC-CTD') and todate >='2023-10-01' and todate <'2024-12-26'
  group by
    1,
    2,
    3
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

danh_sach_diamond_ml1 as 
(
  select 
a.ma_kh_dms, 
cast(a.suat_tham_gia as int) as suat_tham_gia,
cast(a.dk_ml1 as int) as dk_ml1,
0 as dk_ml2,
0 as dk_ml3,
cast(a.tong_dk as int) as tong_dk,
cast(a.dk_ml1 as int) as tong_dk_pl,
date( a.doanh_so_tinh_tu) as doanh_so_tinh_tu,
a1.thang as thang,
'Q' ||extract(quarter from a1.thang) || '-' || extract(year from a1.thang) as quy,
extract(month from a1.thang) || '-' || extract(year from a1.thang) as thang_nam,
'diamond' as datatype,
'ML1' as pl_diamon,
0 as doanhso_ml1,
0 as doanhso_ml2,
0 as doanhso_ml3,
0 as doanhsocovat,
0 as doanhso_ml1_chuavat,
0 as doanhso_ml2_chuavat,
0 as doanhso_ml3_chuavat,
0 as doanhsochuavat
from 
`staging.d_manual_danhsach_khachhang_diamond` a
LEFT JOIN base_date a1 on date(a1.thang) = date( a.doanh_so_tinh_tu) and a1.pl_diamon ='ML1'
),

danh_sach_diamond_ml2 as 
(
  select 
a.ma_kh_dms, 
0 as suat_tham_gia,
0 dk_ml1,
cast(a.dk_ml2 as int) as dk_ml2,
0 dk_ml3,
cast(a.tong_dk as int) as tong_dk,
cast(a.dk_ml2 as int) as tong_dk_pl,
date( a.doanh_so_tinh_tu) as doanh_so_tinh_tu,
a1.thang as thang,
'Q' ||extract(quarter from a1.thang) || '-' || extract(year from a1.thang) as quy,
extract(month from a1.thang) || '-' || extract(year from a1.thang) as thang_nam,
'diamond' as datatype,
'ML2' as pl_diamon,
0 as doanhso_ml1,
0 as doanhso_ml2,
0 as doanhso_ml3,
0 as doanhsocovat,
0 as doanhso_ml1_chuavat,
0 as doanhso_ml2_chuavat,
0 as doanhso_ml3_chuavat,
0 as doanhsochuavat
from 
`staging.d_manual_danhsach_khachhang_diamond` a
LEFT JOIN base_date a1 on date(a1.thang) = date( a.doanh_so_tinh_tu) and a1.pl_diamon ='ML2'
),

danh_sach_diamond_ml3 as 
(
  select 
a.ma_kh_dms, 
0 as suat_tham_gia,
0 dk_ml1,
0 dk_ml2,
cast(a.dk_ml3 as int) as dk_ml3,
cast(a.tong_dk as int) as tong_dk,
cast(a.dk_ml3 as int) as tong_dk_pl,
date( a.doanh_so_tinh_tu) as doanh_so_tinh_tu,
a1.thang as thang,
'Q' ||extract(quarter from a1.thang) || '-' || extract(year from a1.thang) as quy,
extract(month from a1.thang) || '-' || extract(year from a1.thang) as thang_nam,
'diamond' as datatype,
'ML3' as pl_diamon,
0 as doanhso_ml1,
0 as doanhso_ml2,
0 as doanhso_ml3,
0 as doanhsocovat,
0 as doanhso_ml1_chuavat,
0 as doanhso_ml2_chuavat,
0 as doanhso_ml3_chuavat,
0 as doanhsochuavat
from 
`staging.d_manual_danhsach_khachhang_diamond` a
LEFT JOIN base_date a1 on date(a1.thang) = date( a.doanh_so_tinh_tu) and a1.pl_diamon ='ML3'
),

raw_sales as
(
  select makhdms,date(date_trunc(date(b.ngaychungtu),month)) as thang,ifnull(c.pl_diamon,d.pl_diamon) as pl_diamon, 
  sum(Case when date(ngaychungtu) >= date( a.doanh_so_tinh_tu) and ifnull(c.pl_diamon,d.pl_diamon) = 'ML1' then b.doanhsocovat else 0 end) as doanhso_ml1,
  sum(Case when date(ngaychungtu) >= date( a.doanh_so_tinh_tu) and ifnull(c.pl_diamon,d.pl_diamon) = 'ML2' then b.doanhsocovat else 0 end) as doanhso_ml2,
  sum(Case when date(ngaychungtu) >= date( a.doanh_so_tinh_tu) and ifnull(c.pl_diamon,d.pl_diamon) = 'ML3' then b.doanhsocovat else 0 end) as doanhso_ml3,
  sum(Case when date(ngaychungtu) >= date( a.doanh_so_tinh_tu) then b.doanhsocovat else 0 end) as doanhsocovat,

    sum(Case when date(ngaychungtu) >= date( a.doanh_so_tinh_tu) and ifnull(c.pl_diamon,d.pl_diamon) = 'ML1' then b.doanhsochuavat else 0 end) as doanhso_ml1_chuavat,
  sum(Case when date(ngaychungtu) >= date( a.doanh_so_tinh_tu) and ifnull(c.pl_diamon,d.pl_diamon) = 'ML2' then b.doanhsochuavat else 0 end) as doanhso_ml2_chuavat,
  sum(Case when date(ngaychungtu) >= date( a.doanh_so_tinh_tu) and ifnull(c.pl_diamon,d.pl_diamon) = 'ML3' then b.doanhsochuavat else 0 end) as doanhso_ml3_chuavat,
  sum(Case when date(ngaychungtu) >= date( a.doanh_so_tinh_tu) then b.doanhsochuavat else 0 end) as doanhsochuavat
  
  from `warehouse.f_raw_data_sales_yoy` b
  LEFT JOIN tach_pl_theonam_2023 c on b.masanpham = trim(c.ma_sp) and c.ma_sp is not null and date(b.ngaychungtu) >= c.start_date and date(b.ngaychungtu) <=c.end_date
  LEFT JOIN tach_pl_theonam_2024 d on b.masanpham = trim(d.ma_sp) and d.ma_sp is not null and date(b.ngaychungtu) >= d.start_date and date(b.ngaychungtu) <=d.end_date
  LEFT JOIN `staging.d_manual_danhsach_khachhang_diamond` a on b.makhdms =a.ma_kh_dms
  where ngaychungtu >='2023-10-01' and makenhkh <> 'OTH_LAB'
   and ngaychungtu < '2024-12-26'
  group by 1,2,3
),

result0 as (
select 
a.ma_kh_dms, 
0 as suat_tham_gia,
0 as dk_ml1,
0 as dk_ml2,
0 as dk_ml3,
0 as tong_dk,
0 as tong_dk_pl,
date( a.doanh_so_tinh_tu) as doanh_so_tinh_tu,
a1.thang as thang,
'Q' ||extract(quarter from date(a1.thang)) || '-' || extract(year from a1.thang) as quy,
extract(month from date(a1.thang)) || '-' || extract(year from date(a1.thang)) as thang_nam,
'sales' as datatype,
a1.pl_diamon,
ifnull(doanhso_ml1,0) as doanhso_ml1,
ifnull(doanhso_ml2,0) as doanhso_ml2,
ifnull(doanhso_ml3,0) as doanhso_ml3,
ifnull(doanhsocovat,0) as doanhsocovat,
ifnull(doanhso_ml1_chuavat,0) as doanhso_ml1_chuavat,
ifnull(doanhso_ml2_chuavat,0) as doanhso_ml2_chuavat,
ifnull(doanhso_ml3_chuavat,0) as doanhso_ml3_chuavat,
ifnull(doanhsochuavat,0) as doanhsochuavat,

from 
`staging.d_manual_danhsach_khachhang_diamond` a
LEFT JOIN base_date a1 on 1=1 and a1.thang >='2023-10-01'  and a1.thang < current_date("+7")
LEFT JOIN raw_sales b on a.ma_kh_dms =b.makhdms  and a1.thang = b.thang and a1.pl_diamon = b.pl_diamon

-- group by 1,2,3,4,5,6,7,8,9,10,11,12,13
-- having doanhsocovat <> 0
),

union_all as  
(

select * from result0
union all
select * from danh_sach_diamond_ml1
union all
select * from danh_sach_diamond_ml2
union all
select * from danh_sach_diamond_ml3
),


result as 

(
  select a.*,
ifnull(d.doanhso_xpl_ml1,0) as doanhso_xpl_ml1,
ifnull(d.doanhso_xpl_ml2,0) as doanhso_xpl_ml2,
ifnull(d.doanhso_xpl_ml3,0) as doanhso_xpl_ml3,
ifnull(e.doanhso_ttmb_ml1,0) as doanhso_ttmb_ml1,
ifnull(e.doanhso_ttmb_ml2,0) as doanhso_ttmb_ml2,
ifnull(e.doanhso_ttmb_ml3,0) as doanhso_ttmb_ml3,

ifnull(d.doanhso_xpl_ml1_chuavat,0) as doanhso_xpl_ml1_chuavat,
ifnull(d.doanhso_xpl_ml2_chuavat,0) as doanhso_xpl_ml2_chuavat,
ifnull(d.doanhso_xpl_ml3_chuavat,0) as doanhso_xpl_ml3_chuavat,

ifnull(d.doanhso_xpl_ml1,0) + ifnull(d.doanhso_xpl_ml2,0) + ifnull(d.doanhso_xpl_ml3,0) as doanhso_xpl,
ifnull(e.doanhso_ttmb_ml1,0) + ifnull(e.doanhso_ttmb_ml2,0) + ifnull(e.doanhso_ttmb_ml3,0)  as doanhso_ttmb
  from union_all a 
LEFT JOIN ds_ctkm_xit_phan_lieu d on a.ma_kh_dms =d.makhdms and a.thang =d.thang and a.datatype ='sales' and a.pl_diamon = d.pl_diamon
LEFT JOIN tichluy_datra_ttmb e on a.ma_kh_dms =e.custid and a.thang = e.thang and a.datatype ='sales'and a.pl_diamon = e.pl_diamon

)

-- select * from result where ma_kh_dms ='P4723-0286'and thang ='2023-10-01'


select 
a.* except(doanhso_ml1,doanhso_ml2,doanhso_ml3,doanhsocovat,doanhsochuavat),

doanhso_ml1-doanhso_xpl_ml1 as doanhso_ml1,
doanhso_ml2-doanhso_xpl_ml2 as doanhso_ml2,
doanhso_ml3-doanhso_xpl_ml3 as doanhso_ml3,

doanhsocovat -doanhso_xpl_ml1 -doanhso_xpl_ml2 -doanhso_xpl_ml3 as doanhsocovat,
a.doanhsochuavat -doanhso_xpl_ml1_chuavat -doanhso_xpl_ml2_chuavat -doanhso_xpl_ml3_chuavat as doanhsochuavat,

round(cast((doanhso_ml1-doanhso_xpl_ml1) as int) / 1000000 *4,4) as diemtichluy_ml1,
round(cast((doanhso_ml2-doanhso_xpl_ml2) as int) / 1000000 *1,4) as diemtichluy_ml2,
round(cast((doanhso_ml3-doanhso_xpl_ml3) as int) / 1000000 *2,4) as diemtichluy_ml3,
b.custname,
b.channel,
b.shoptype,
b.statedescr,
b.shortterritorydescr,
b.hcoid,
b.hcotypeid,
b.branchid,
b.branchname,
l.col.ma_nvbh as slsperid,
d.tencvbh,
d.supid,
d.tenquanlytt,
d.asm,
d.tenquanlykhuvuc,
d.rsmid,
d.tenquanlyvung,
( select max(inserted_at) from `staging.f_sales` where ngaychungtu >='2023-10-01' ) as inserted_at,
e.da_tra as da_tra_ori,
e.da_tra / 3 as da_tra

from result a
LEFT JOIN `staging.d_master_khachhang`b on a.ma_kh_dms = b.custid
-- LEFT JOIN tuyen_dms_moinhat c on a.ma_kh_dms = c.custid
LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a.ma_kh_dms 
LEFT JOIN `staging.d_users` d on l.col.ma_nvbh = d.manv
LEFT JOIN da_tra_diamond e on a.ma_kh_dms =e.custid and a.thang = e.thang

);

Create or replace table `warehouse.f_theodoi_danhsach_diamond`

copy `staging_temp.f_theodoi_danhsach_diamond_temp`;


END;