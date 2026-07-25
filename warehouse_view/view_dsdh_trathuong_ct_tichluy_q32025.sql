CREATE VIEW `spatial-vision-343005.warehouse.view_dsdh_trathuong_ct_tichluy_q32025`
AS WITH 
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
    ifnull(so.origordernbr,so.ordernbr) as origordernbr, 
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
    -- lên báo cáo trả thưởng giúp chị nhé, thời gian 16.04-14.05
    AND oc.visitdate >= '2025-10-01'
WHERE 
    ordertype in ('NP', 'NI') 
    AND status = 'C'
    AND 
    (
    CASE
    WHEN remark LIKE '%MKT@25MTP2006%' AND remark LIKE '%Q3/25%' then true
    WHEN remark LIKE '%MKT@25MTP2007%' AND remark LIKE '%Q3/25%' then true
    WHEN remark LIKE '%MKT@25MTP3087%' AND remark LIKE '%T9/25%' then true
    else false
    END
    )
)



, manual_input as(

SELECT
machuongtrinh as idchuongtrinh,
chuongtrinh,
madms,
tenkhachhangnoibo,
mamds,
tenmdstrathuong,
sodondathang,
inserted_at
FROM `spatial-vision-343005.staging.dsdh_chuong_trinh_tra_thuong`  a

where 
true
AND a.inserted_at >= '2025-10-01 00:00:00 UTC'
-- AND a.inserted_at <= '2025-04-21 00:00:00 UTC'
-- and a.inserted_at <= '2024-11-24 00:00:00 UTC'

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
-- where date(inserted_at) >='2025-01-01'

)

, approve_date as

(
  select a.ordernbr, max(approvedate) as approvedate from staging.sync_dms_ibd a
  INNER JOIN staging.sync_dms_ib b on a.branchid = b.branchid and a.batnbr = b.batnbr
  where date(a.crtd_datetime)>= '2025-01-01'
  GROUP BY ALL
)

,   mapping as (
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
c.lupd_datetime_dv,
CURRENT_DATETIME("Asia/Bangkok") as inserted_at,
status_dv,
Case 
    when sodondathang like '%NI%'then 0
    when sodondathang is not null and c.status_dv ='C' then 0 else 1 
end as da_giao

from final_manual_input a
LEFT JOIN NGAYGIAOHANG c on a.sodondathang = c.ordernbr
LEFT JOIN `staging.d_users` d on (Case when c.status_dv ='C' then c.slsperid_dv else a.mamds end)=d.manv
LEFT JOIN `staging.d_master_khachhang` f on a.madms = f.custid
left join approve_date g on a.sodondathang = g.ordernbr
)

select a.*,
Case when a.sodondathang is null and count(custid) over (partition  by custid,chuongtrinh ) = 1 then a.custid else null end as dh_chua_tao,
Case when sum(da_giao) over(partition by custid,chuongtrinh) =  0 then a.custid else null end as kh_da_giao,
Case when sum(da_giao) over(partition by custid,chuongtrinh) >  0 then a.custid else null end as kh_chua_giao
-- Case when status_dv <>'C' then a.custid else null end as kh_chua_giao
from mapping a;