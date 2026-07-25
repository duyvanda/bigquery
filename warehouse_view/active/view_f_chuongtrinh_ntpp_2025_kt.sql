CREATE VIEW `spatial-vision-343005.warehouse.view_f_chuongtrinh_ntpp_2025_kt`
AS WITH 
base_date as (
  SELECT
    distinct date_trunc(ngay,month) as thang
    FROM
        unnest(
            GENERATE_DATE_ARRAY(
                date_sub(current_date("+7"), INTERVAL 24 MONTH),
                date_add(current_date("+7"), INTERVAL 12 MONTH),
                INTERVAL 1 DAY
            )
        ) AS ngay
),

ds_kh_thaydoi_kh_thue as (

select makhdms,ma_kh_thue,ghichu,ma_chuongtrinh,b.custidinvoice,if(b.custidinvoice<>a.ma_kh_thue,'Y','N') as is_diff,b.hcotypeid,custname,b.active
from staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp a
LEFT JOIN `staging.d_master_khachhang` b on a.makhdms =b.custid

where ma_chuongtrinh ='NTPP' and b.custidinvoice<>a.ma_kh_thue
and makhdms not in ('N06503232','006734','006737')
)
,

union_all as 
(
select makhdms,ma_kh_thue,ghichu,ma_chuongtrinh,'Excel' as datatype,
  FROM `staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` a   
WHERE ma_chuongtrinh ='NTPP'

  UNION ALL

select makhdms,custidinvoice,ghichu,ma_chuongtrinh,'Auto' as datatype
  from ds_kh_thaydoi_kh_thue
)
,

-- union_all as 

-- (
--   select b.*,a.*
--   from base_date  a 
--   JOIN union_all_0 b on 1=1
--   where thang >='2025-01-01' and thang <'2026-01-01'
-- ),


loc_doanhso as 
(
  select 
  a.macongtycn,
  a.makhdms,
  date(a.thang) as thang,
  a.ngaychungtu,
  a.mahd,
  ifnull(f.hcotypeid,d.hcotypeid) as maphanloaihco,
  c.invoicecustid,
  Case 
    when date(ngaychungtu) >= PARSE_DATE('%d/%m/%Y',  split(ghichu,'-')[0]) and date(ngaychungtu) <= PARSE_DATE('%d/%m/%Y',  split(ghichu,'-')[1])
    then doanhsocovat 
    else 0 
  end as doanhsocovat,
  b.ghichu,
  updated_at
  from `warehouse.f_raw_data_sales_yoy` a
  LEFT JOIN `staging.sync_dms_so` c on a.mahd =c.ordernbr and a.macongtycn =c.branchid
  LEFT JOIN `staging.sync_dms_pda_so` f on a.macongtycn =f.branchid and a.sodondathang =f.ordernbr
  LEFT JOIN `staging.d_master_khachhang` d on d.custid =a.makhdms
  LEFT JOIN union_all b on c.invoicecustid = b.ma_kh_thue 
  -- INNER JOIN staging.d_master_khachhang d on a.makhdms = d.custid and d.hcotypeid = 'NTXQPK'
  where ngaychungtu >='2025-01-01' and ngaychungtu <'2026-01-01' and ifnull(f.hcotypeid,d.hcotypeid) = 'NTXQPK'
),

data_sales as (
select 
  thang,
  makhdms,
  invoicecustid,
  ghichu,
  sum(doanhsocovat) as doanhsocovat,
  max(updated_at) as inserted_at
from loc_doanhso

 group by all
 )
 ,

 data_sales_inv  as (
 select 
 a.thang,
 a.invoicecustid,
 a.ghichu,
 sum(doanhsocovat) as doanhsocovat,
 max(inserted_at) as inserted_at

from data_sales a
 LEFT JOIN union_all c on a.makhdms =c.makhdms and a.invoicecustid =c.ma_kh_thue and c.ma_chuongtrinh ='NTPP' and a.ghichu = c.ghichu
 where 
  ma_chuongtrinh is null --không tính doanh số chính nó
group by all

),

thanhtoan_q1 as 
(
  SELECT e as makhthue, ngaychuyentien as ngaythanhtoantienck,ghichu
FROM `spatial-vision-343005.staging.d_manual_gs_ntpp` 
qualify row_number() over (partition by e order by ngaychuyentien desc) =1
)
SELECT
    a2.thang,
    a.ma_kh_thue as invoicecustid,
    a1.custnameinvoice,
    a.makhdms as custid,
    a.ghichu,
    a.datatype,
    a1.custname,
    a1.hcotypeid,
    a1.shoptype,
    a1.hcoid,
    a1.channel,
    a1.branchid,
    a1.shortterritorydescr as territorydescr,
    a1.statedescr,
    ifnull(b.doanhsocovat,0) as doanhsocovat,
    0.05 as muc_chiet_khau,
    ifnull(b.doanhsocovat,0) * 5 / 100 as tong_tien_chiet_khau,
    l.col.ma_nvbh as ma_crs,
    e.tencvbh,
    left(e.supid,6) as ma_crm,
    e.tenquanlytt,
    left(e.rsmid,6) as ma_ncxm,
    e.tenquanlyvung,
    -- f.ngaythanhtoantienck as ngaythanhtoantienck_q1,
    -- -- f.ghichu,
    -- Case when f.ngaythanhtoantienck is not null then 'Đã trả' else 'Chưa trả' end as tinhtrang_thanhtoan_q1,
    -- Case when f.ngaythanhtoantienck is null then f.ghichu else null end as ghichu_thanhtoan_q1,
    '' as ngaythanhtoantienck_q1,
    '' as tinhtrang_thanhtoan_q1,
    '' as ghichu_thanhtoan_q1

FROM
    union_all a
    LEFT JOIN base_date a2 on 1 = 1
    LEFT JOIN `staging.d_master_khachhang` a1 on a.makhdms =a1.custid
    LEFT JOIN data_sales_inv b on b.invoicecustid = a.ma_kh_thue and a.ghichu = b.ghichu and a2.thang =b.thang
    LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a.makhdms 
    LEFT JOIN `staging.d_users` e on l.col.ma_nvbh = e.manv
;