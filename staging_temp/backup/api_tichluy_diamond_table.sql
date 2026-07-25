CREATE TABLE FUNCTION `spatial-vision-343005`.staging_temp.api_tichluy_diamond_table(p_ma_crs STRING)
AS
with 
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
sum(Case when ifnull(c.pl_diamon,d.pl_diamon) = 'ML1' then b.doanhsocovat else 0 end) as doanhso_xpl_ml1,
sum(Case when ifnull(c.pl_diamon,d.pl_diamon) = 'ML2' then b.doanhsocovat else 0 end) as doanhso_xpl_ml2,
sum(Case when ifnull(c.pl_diamon,d.pl_diamon) = 'ML3' then b.doanhsocovat else 0 end) as doanhso_xpl_ml3,
from ctkm_xit_phan_lieu a 
LEFT JOIN `warehouse.f_sales_crs` b on b.mahd =a.ordernbr and b.macongtycn=a.branchid and a.groupreflineref =b.lineref and ngaychungtu >='2023-09-01'and b.makenhkh <> 'OTH_LAB' 

LEFT JOIN tach_pl_theonam_2023 c on b.masanpham = trim(c.ma_sp) and c.ma_sp is not null and date(b.ngaychungtu) >= c.start_date and date(b.ngaychungtu) <=c.end_date
LEFT JOIN tach_pl_theonam_2024 d on b.masanpham = trim(d.ma_sp) and d.ma_sp is not null and date(b.ngaychungtu) >= d.start_date and date(b.ngaychungtu) <=d.end_date

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
    accumulateid = '202301-TL-QD01-NT-QT-PKN-PKQ' and date(todate) >='2023-10-01'  
  group by
    1
),

base_date as (
    select
    distinct date(date_trunc(day,month)) as thang
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

result0 as (
select 
a.ma_kh_dms, 
cast (a.suat_tham_gia as int) as suat_tham_gia,
cast(a.dk_ml1 as int) as dk_ml1,
cast(a.dk_ml2 as int) as dk_ml2,
cast(a.dk_ml3 as int) as dk_ml3,
cast(a.tong_dk as int) as tong_dk, 
cast(a.tong_dk as int) as tong_dk_pl,
date( a.doanh_so_tinh_tu) as doanh_so_tinh_tu,

sum(Case when date(ngaychungtu) >= date( a.doanh_so_tinh_tu) and ifnull(c.pl_diamon,d.pl_diamon) = 'ML1' then b.doanhsocovat else 0 end) as doanhso_ml1,
sum(Case when date(ngaychungtu) >= date( a.doanh_so_tinh_tu) and ifnull(c.pl_diamon,d.pl_diamon) = 'ML2' then b.doanhsocovat else 0 end) as doanhso_ml2,
sum(Case when date(ngaychungtu) >= date( a.doanh_so_tinh_tu) and ifnull(c.pl_diamon,d.pl_diamon) = 'ML3' then b.doanhsocovat else 0 end) as doanhso_ml3,
sum(Case when date(ngaychungtu) >= date( a.doanh_so_tinh_tu) then b.doanhsocovat else 0 end) as doanhsocovat

from 
`staging.d_manual_danhsach_khachhang_diamond` a
-- LEFT JOIN base_date a1 on 1=1 and a1.thang >='2023-10-01' and a1.thang <'2025-01-01'
LEFT JOIN `warehouse.f_sales_crs` b on a.ma_kh_dms =b.makhdms and ngaychungtu >='2023-10-01' and b.makenhkh <> 'OTH_LAB'
LEFT JOIN tach_pl_theonam_2023 c on b.masanpham = trim(c.ma_sp) and c.ma_sp is not null and date(b.ngaychungtu) >= c.start_date and date(b.ngaychungtu) <=c.end_date
LEFT JOIN tach_pl_theonam_2024 d on b.masanpham = trim(d.ma_sp) and d.ma_sp is not null and date(b.ngaychungtu) >= d.start_date and date(b.ngaychungtu) <=d.end_date

group by 1,2,3,4,5,6,7,8 
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
ifnull(d.doanhso_xpl_ml1,0) + ifnull(d.doanhso_xpl_ml2,0) + ifnull(d.doanhso_xpl_ml3,0) as doanhso_xpl,
ifnull(e.doanhso_ttmb_ml1,0) + ifnull(e.doanhso_ttmb_ml2,0) + ifnull(e.doanhso_ttmb_ml3,0)  as doanhso_ttmb
  from result0 a 
LEFT JOIN ds_ctkm_xit_phan_lieu d on a.ma_kh_dms =d.makhdms --and a.datatype ='sales' --and a.pl_diamon = d.pl_diamon
LEFT JOIN tichluy_datra_ttmb e on a.ma_kh_dms =e.custid --and a.datatype ='sales'--and a.pl_diamon = e.pl_diamon

),

tinh_diem_tl as (
select 
a.ma_kh_dms,
b.custname as ten_kh,
c.slsperid as ma_crs,
d.tencvbh as ten_crs,
d.supid as ma_crm,
d.tenquanlytt as ten_crm,
doanhsocovat -doanhso_xpl_ml1 -doanhso_xpl_ml2 -doanhso_xpl_ml3 as doanh_so_co_vat,
div(cast (doanhso_ml1-doanhso_xpl_ml1 as int) , 1000000) *4 as diem_tl_ml1,
div(cast (doanhso_ml2-doanhso_xpl_ml2 as int) , 1000000) *1 as diem_tl_ml2,
div(cast (doanhso_ml3-doanhso_xpl_ml3 as int) , 1000000) *2 as diem_tl_ml3,
div(cast (doanhso_ml1-doanhso_xpl_ml1 as int) , 1000000) *4 + div(cast (doanhso_ml2-doanhso_xpl_ml2 as int) , 1000000) *1 + div(cast (doanhso_ml3-doanhso_xpl_ml3 as int) , 1000000) *2 as tong_diem_tl,
-- a.tong_dk as tong_ds_dk,
div(dk_ml1,1000000) * 4 as diem_dk_ml1,
div(dk_ml2 ,1000000) * 1 as diem_dk_ml2,
div(dk_ml3 ,1000000) * 2  as diem_dk_ml3,
div(dk_ml1,1000000) * 4 + div(dk_ml2 , 1000000) * 1 + div(dk_ml3 , 1000000) * 2  as tong_diem_dk,

 from result a 
 LEFT JOIN `staging.d_master_khachhang`b on a.ma_kh_dms =b.custid
 LEFT JOIN tuyen_dms_moinhat c on a.ma_kh_dms = c.custid
 LEFT JOIN `staging.d_users` d on c.slsperid = d.manv
 where starts_with(manv,p_ma_crs)
)

select a.*, 
Case when tong_diem_tl >= tong_diem_dk then 1 else 0 end as is_check_dat_diem_tl,
Case when tong_diem_tl < tong_diem_dk then ma_kh_dms else null end as so_kh_cham_tich_luy,
from tinh_diem_tl a

order by is_check_dat_diem_tl,tong_diem_tl;