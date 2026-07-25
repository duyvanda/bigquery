CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_dsdh_trathuong_ct_tichluy()
BEGIN 
 
-- TRUNCATE TABLE staging_temp.f_dsdh_trathuong_ct_tichluy_temp;

CREATE TEMP TABLE `f_dsdh_trathuong_ct_tichluy_temp`

AS

( 
-- Create or replace table staging_temp.f_dsdh_trathuong_ct_tichluy_temp as

WITH 
NGAYGIAOHANG as
(
  select 
  crtd_datetime as crtd_datetime_dv, 
  branchid,
  ordernbr,
  status as status_dv,
  delivery_date as lupd_datetime_dv,
  slsperid as slsperid_dv
  FROM `spatial-vision-343005.staging.sync_dms_dv` dv
  qualify row_number() over (partition by branchid,ordernbr order by crtd_datetime desc) = 1
)

, fix_sync_dms_decheckin as

(
    select numbercico, deordernbr from `staging.sync_dms_decheckin` QUALIFY ROW_NUMBER() OVER (PARTITION BY deordernbr) = 1
)

, np_dh_tra_thuong as
(
SELECT 
    so.origordernbr, 
    so.custid, 
    so.remark, 
    d.numbercico AS de_numbercico,
    oc.imagefilename
FROM 
    `staging.sync_dms_so` so
LEFT JOIN 
    fix_sync_dms_decheckin d 
    ON so.origordernbr = d.deordernbr
LEFT JOIN 
    `staging.sync_dms_oc` oc
    ON d.numbercico = oc.salesid
    AND oc.visitdate >= '2024-07-01'
WHERE 
    ordertype = 'NP' 
    AND date(crtd_datetime) >= '2024-07-01'
    AND date(crtd_datetime) <= '2024-09-30'
    AND status = 'C'
    AND (
        remark LIKE '%MKT@24MTP2031%' OR
        remark LIKE '%MKT@24MTP2029%' OR
        remark LIKE '%MKT@24MTP2030%' OR
        remark LIKE '%MKT@24MTP3018%' OR
        remark LIKE '%MKT@24MTP3046%'
    )
    OR origordernbr in (
    'NP0-1024-02378',
    'NP0-1024-02377',
    'NP3-1024-00945',
    'NP7-1024-01772',
    'NP7-1024-01771'
)
)

, manual_input as(

SELECT case
when chuongtrinh = 'Decal Q2/24' then 'MKT@24MTP2031'
when chuongtrinh = 'Ebysta Q2/24' then 'MKT@24MTP2029'
when chuongtrinh = 'Sticker Lá Đôi Q2/24' then 'MKT@24MTP2030'
when chuongtrinh = 'Bình Ổn Giá Q2/24' then 'MKT@24MTP3018'
when chuongtrinh = 'Tích lũy XO T5-6/24' then 'MKT@24MTP3046'
else '' end as idchuongtrinh,
chuongtrinh,
-- STRPOS( chuongtrinh, madms ) as abc,
madms,
tenkhachhangnoibo,
mamds,
tenmdstrathuong,
sodondathang,
inserted_at
FROM `spatial-vision-343005.staging.dsdh_chuong_trinh_tra_thuong`  a

where a.inserted_at < '2024-10-16 15:25:58 UTC'

)

, final_manual_input as (

select
DISTINCT
chuongtrinh,
madms,
tenkhachhangnoibo,
mamds,
tenmdstrathuong,
b.origordernbr as sodondathang,
imagefilename,
inserted_at,
from manual_input a
LEFT JOIN np_dh_tra_thuong b on a.madms = b.custid 
and STRPOS( remark, idchuongtrinh ) >=1
where date(inserted_at) >='2024-07-01'

)

, approve_date as

(
  select a.ordernbr, max(approvedate) as approvedate from staging.sync_dms_ibd a
  INNER JOIN staging.sync_dms_ib b on a.branchid = b.branchid and a.batnbr = b.batnbr
  where date(a.crtd_datetime)>= '2024-07-01'
  GROUP BY ALL
)

, mapping as (
select 
a.chuongtrinh, 
a.sodondathang,
a.imagefilename,
Case when c.status_dv ='C' then c.slsperid_dv
else a.mamds end as incharge_slsperid,
d.tencvbh as ten_mds,
d.supid as ma_sup_mds,
d.tenquanlytt as ten_sup_mds,
a.madms as custid,
f.branchid,
f.custname,
f.channel,
f.shoptype,
f.statedescr,
f.shortterritorydescr,
f.hcotypeid,
lupd_datetime_dv,
datetime(g.approvedate) as inserted_at,
status_dv,
Case when sodondathang is not null and c.status_dv ='C' then 0 else 1 end as da_giao
from final_manual_input a
LEFT JOIN NGAYGIAOHANG c on a.sodondathang = c.ordernbr
LEFT JOIN `staging.d_users` d on (Case when c.status_dv ='C' then c.slsperid_dv else a.mamds end)=d.manv
LEFT JOIN `staging.d_master_khachhang` f on a.madms = f.custid
left join approve_date g on a.sodondathang = g.ordernbr
)

select a.*,
Case when a.sodondathang is null and count(custid) over (partition  by custid,chuongtrinh ) = 1 then a.custid else null end as dh_chua_tao,
Case when sum(da_giao) over(partition by custid,chuongtrinh) =  0 then a.custid else null end as kh_da_giao,
Case when status_dv <>'C' then a.custid else null end as kh_chua_giao
from mapping a


);

Create or replace table `warehouse.f_dsdh_trathuong_ct_tichluy`

copy `f_dsdh_trathuong_ct_tichluy_temp`;

END;