CREATE PROCEDURE `spatial-vision-343005`.staging_temp.api_ds_kh_diamond(p_makhdms STRING, p_startdate STRING, p_enddate STRING, p_ma_crs STRING)
OPTIONS(
  strict_mode=false)
BEGIN

-- Default values
DECLARE current_dt DATE DEFAULT CURRENT_DATE("+7");
-- SET PARAMS
DECLARE set_enddate, set_startdate DATE;

SET set_startdate = IF (p_startdate = '', Date('2023-10-01'), DATE(p_startdate) );
SET set_enddate = IF (p_enddate = '', current_dt, DATE(p_enddate) );

with 

ds_tb as 
(
  with data_sales as (
select
makhdms,
'2023-10-01' as ds_tinh_tu,
date(date_trunc(current_date("+7"),month) - interval 1 day) as ds_tinh_den,
date_diff(date_trunc(current_date("+7"),month),date('2023-10-01'),month) as so_thang,
sum(doanhsocovat) as ds
from `warehouse.f_sales_crs` 
where ngaychungtu >='2023-10-01'  and ngaychungtu < '2024-12-26'
group by 1,2,3 
)

select *, ds / so_thang as ds_tb 
from data_sales
order by 6 desc
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
-- c.pl_diamon,
-- date(date_trunc(ngaychungtu,month)) as thang,
sum(Case when ifnull(c.pl_diamon,d.pl_diamon) = 'ML1' and date(ngaychungtu) >= date( e.doanh_so_tinh_tu) then b.doanhsocovat else 0 end) as doanhso_xpl_ml1,
sum(Case when ifnull(c.pl_diamon,d.pl_diamon) = 'ML2' and date(ngaychungtu) >= date( e.doanh_so_tinh_tu) then b.doanhsocovat else 0 end) as doanhso_xpl_ml2,
sum(Case when ifnull(c.pl_diamon,d.pl_diamon) = 'ML3' and date(ngaychungtu) >= date( e.doanh_so_tinh_tu) then b.doanhsocovat else 0 end) as doanhso_xpl_ml3,
from ctkm_xit_phan_lieu a 
LEFT JOIN `warehouse.f_sales_crs` b on b.mahd =a.ordernbr and b.macongtycn=a.branchid and a.groupreflineref =b.lineref and ngaychungtu >='2023-10-01'and b.makenhkh <> 'OTH_LAB'  and ngaychungtu < '2024-12-26' 
and date(ngaychungtu) <= date(set_enddate) and date(ngaychungtu) >= date(set_startdate)
LEFT JOIN tach_pl_theonam_2023 c on b.masanpham = trim(c.ma_sp) and c.ma_sp is not null and date(b.ngaychungtu) >= c.start_date and date(b.ngaychungtu) <=c.end_date
LEFT JOIN tach_pl_theonam_2024 d on b.masanpham = trim(d.ma_sp) and d.ma_sp is not null and date(b.ngaychungtu) >= d.start_date and date(b.ngaychungtu) <=d.end_date
LEFT JOIN `staging.d_manual_danhsach_khachhang_diamond` e on b.makhdms =e.ma_kh_dms

group by 1

),

tichluy_datra_ttmb as (
 select
    custid,
    sum(paidamt) as doanhso_ttmb_ml1,
    0 as doanhso_ttmb_ml2,
    0 as doanhso_ttmb_ml3,

  from
    `staging.f_paidso_acculate` a 
  where
    accumulateid in('202301-TL-QD01-NT-QT-PKN-PKQ','202401-TL-QD976-PMC-CTD','202401-TL-QD974-PMC-CTD') and todate >='2023-10-01' and todate <'2024-12-26'  
    group by
    1
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

union_all as (
select 
a.ma_kh_dms, 
cast (a.suat_tham_gia as int) as suat_tham_gia,
cast(a.dk_ml1 as int) as dk_ml1,
cast(a.dk_ml2 as int) as dk_ml2,
cast(a.dk_ml3 as int) as dk_ml3,
cast(a.tong_dk as int) as tong_dk, 
cast(a.tong_dk as int) as tong_dk_pl,
date(a.doanh_so_tinh_tu) as doanh_so_tinh_tu,
date('2024-12-31') as doanh_so_tinh_den,


sum(Case when date(ngaychungtu) >= date(a.doanh_so_tinh_tu) and ifnull(c.pl_diamon,d.pl_diamon)  = 'ML1' then b.doanhsocovat else 0 end) as doanhso_ml1,
sum(Case when date(ngaychungtu) >= date(a.doanh_so_tinh_tu) and ifnull(c.pl_diamon,d.pl_diamon)  = 'ML2' then b.doanhsocovat else 0 end) as doanhso_ml2,
sum(Case when date(ngaychungtu) >= date(a.doanh_so_tinh_tu) and ifnull(c.pl_diamon,d.pl_diamon)  = 'ML3' then b.doanhsocovat else 0 end) as doanhso_ml3,
sum(Case when date(ngaychungtu) >= date(a.doanh_so_tinh_tu) then b.doanhsocovat else 0 end) as doanhsocovat

from 
`staging.d_manual_danhsach_khachhang_diamond` a
LEFT JOIN `warehouse.f_sales_crs` b on a.ma_kh_dms =b.makhdms and ngaychungtu >='2023-10-01' and b.makenhkh not in ('OTH_LAB')  and ngaychungtu < '2024-12-26'
LEFT JOIN tach_pl_theonam_2023 c on b.masanpham = trim(c.ma_sp) and c.ma_sp is not null and date(b.ngaychungtu) >= c.start_date and date(b.ngaychungtu) <=c.end_date
LEFT JOIN tach_pl_theonam_2024 d on b.masanpham = trim(d.ma_sp) and d.ma_sp is not null and date(b.ngaychungtu) >= d.start_date and date(b.ngaychungtu) <=d.end_date

group by 1,2,3,4,5,6,7,8 ,9
),

-- union_all as  
-- (

-- select * from result0

-- ),

result as 

(
  select a.*,
ifnull(d.doanhso_xpl_ml1,0) as doanhso_xpl_ml1,
ifnull(d.doanhso_xpl_ml2,0) as doanhso_xpl_ml2,
ifnull(d.doanhso_xpl_ml3,0) as doanhso_xpl_ml3,
ifnull(e.doanhso_ttmb_ml1,0) as doanhso_ttmb_ml1,
ifnull(e.doanhso_ttmb_ml2,0) as doanhso_ttmb_ml2,
ifnull(e.doanhso_ttmb_ml3,0) as doanhso_ttmb_ml3,
ifnull(d.doanhso_xpl_ml1,0) + ifnull(d.doanhso_xpl_ml2,0) + ifnull(d.doanhso_xpl_ml3,0) as doanhso_xpl,
ifnull(e.doanhso_ttmb_ml1,0) + ifnull(e.doanhso_ttmb_ml2,0) + ifnull(e.doanhso_ttmb_ml3,0)  as doanhso_ttmb
  from union_all a 
LEFT JOIN ds_ctkm_xit_phan_lieu d on a.ma_kh_dms =d.makhdms 
LEFT JOIN tichluy_datra_ttmb e on a.ma_kh_dms =e.custid  

),


result1 as (
select 
a.*except(doanhso_ml1,doanhso_ml2,doanhso_ml3,doanhsocovat),
date_diff(date('2024-12-26'),date(a.doanh_so_tinh_tu),month) as so_thang_tham_gia,
doanhso_ml1-doanhso_xpl_ml1 as doanhso_ml1,
doanhso_ml2-doanhso_xpl_ml2 as doanhso_ml2,
doanhso_ml3-doanhso_xpl_ml3 as doanhso_ml3,
doanhsocovat -doanhso_xpl_ml1 -doanhso_xpl_ml2 -doanhso_xpl_ml3 as doanhsocovat,
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
d.tenquanlyvung
 from result a 
 LEFT JOIN `staging.d_master_khachhang`b on a.ma_kh_dms =b.custid
--  LEFT JOIN tuyen_dms_moinhat c on a.ma_kh_dms = c.custid
LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a.ma_kh_dms 
 LEFT JOIN `staging.d_users` d on l.col.ma_nvbh = d.manv
  where contains_substr(concat(ifnull(d.supid,''),ifnull(l.col.ma_nvbh,'')),p_ma_crs)
 and  contains_substr(a.ma_kh_dms,p_makhdms)

),

result2 as (
select 
'202310-TL-QD786-NT-QT-PKN-PKQ' as ma_chuong_trinh,
branchid as ma_cn,
slsperid as ma_cvbh, 
tencvbh as ten_cvbh,
supid as ma_ql_tt,
tenquanlytt as ten_ql_tt,
ma_kh_dms,
custname as ten_khach_hang,
statedescr as tinh,
shortterritorydescr as khu_vuc,
hcoid as ma_hco,
hcotypeid as ma_pl_hco,
doanh_so_tinh_tu  as ngay_tham_gia,
doanh_so_tinh_den as ngay_ket_thuc,
so_thang_tham_gia,
tong_dk / so_thang_tham_gia as ds_dk_tb,
suat_tham_gia as suat_tham_gia,
-- suat_tham_gia * 1300 as tong_diem_dk,
dk_ml1 as ds_dk_ml1,
dk_ml2 as ds_dk_ml2,
dk_ml3 as ds_dk_ml3,
tong_dk as tong_ds_dk,
div(dk_ml1,1000000) * 4 as diem_dk_ml1,
div(dk_ml2 ,1000000) * 1 as diem_dk_ml2,
div(dk_ml3 ,1000000) * 2  as diem_dk_ml3,
div(dk_ml1,1000000) * 4 + div(dk_ml2 , 1000000) * 1 + div(dk_ml3 , 1000000) * 2  as tong_diem_dk,
sum(doanhso_ml1) as ds_thuc_hien_ml1,
sum(doanhso_ml2) as ds_thuc_hien_ml2,
sum(doanhso_ml3) as ds_thuc_hien_ml3,
sum(doanhso_xpl) as ds_loai_tru,
sum(doanhso_ttmb) as ds_ttmb,
sum(doanhso_ml1 + doanhso_ml2 + doanhso_ml3) as tong_ds_thuchien,
div(cast(sum(doanhso_ml1) as int),1000000) * 4 as diem_tich_luy_ml1,
div(cast(sum(doanhso_ml2) as int),1000000) * 1 as diem_tich_luy_ml2,
div(cast(sum(doanhso_ml3) as int),1000000) * 2 as diem_tich_luy_ml3,
div(cast(sum(doanhso_ml1) as int),1000000) * 4 + div(cast(sum(doanhso_ml2)as int),1000000) * 1 + div(cast(sum(doanhso_ml3)as int),1000000) * 2 as tong_diem_tich_luy,

from result1

group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25

)

select a.*, 
-- b.ds_tb,
Case when ifnull(b.ds_tb,0) < a.ds_dk_tb then 1 else 0 end as is_check_kh_cham_ds,
Case when tong_diem_tich_luy >= tong_diem_dk then 1 else 0 end as is_check_dat_diem_tl,
Case when tong_diem_tich_luy < tong_diem_dk then ma_kh_dms else null end as so_kh_cham_tich_luy,
round(safe_divide(tong_ds_thuchien,tong_ds_dk),3) as ti_le_hoan_thanh,
Case when current_date("+7") <=date(ngay_ket_thuc) then
round(date_diff(current_date("+7"),date(ngay_tham_gia),day) / date_diff(date(ngay_ket_thuc),date(ngay_tham_gia),day) ,3) 
else 1.000 end as thoi_gian_thuc_hien
from result2 a 
LEFT JOIN ds_tb b on a.ma_kh_dms =b.makhdms
;
END;