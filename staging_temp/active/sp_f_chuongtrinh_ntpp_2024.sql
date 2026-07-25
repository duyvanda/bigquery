CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_ntpp_2024()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_chuongtrinh_ntpp_2024_temp`;

 INSERT INTO `staging_temp.f_chuongtrinh_ntpp_2024_temp`

(  
-- Create or replace table staging_temp.f_chuongtrinh_ntpp_2024_temp as

WITH ds_kh_thaydoi_kh_thue as (

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

loc_doanhso as 
(
  select 
  a.macongtycn,
  a.makhdms,
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
  makhdms,
  invoicecustid,
  ghichu,
  sum(Case when extract(month from ngaychungtu) =1 then doanhsocovat else 0 end) as ds_covat_t1,
  sum(Case when extract(month from ngaychungtu) =2 then doanhsocovat else 0 end) as ds_covat_t2,
  sum(Case when extract(month from ngaychungtu) =3 then doanhsocovat else 0 end) as ds_covat_t3,
  sum(Case when extract(month from ngaychungtu) =4 then doanhsocovat else 0 end) as ds_covat_t4,
  sum(Case when extract(month from ngaychungtu) =5 then doanhsocovat else 0 end) as ds_covat_t5,
  sum(Case when extract(month from ngaychungtu) =6 then doanhsocovat else 0 end) as ds_covat_t6,

  sum(Case when extract(month from ngaychungtu) =7 then doanhsocovat else 0 end) as ds_covat_t7,
  sum(Case when extract(month from ngaychungtu) =8 then doanhsocovat else 0 end) as ds_covat_t8,
  sum(Case when extract(month from ngaychungtu) =9 then doanhsocovat else 0 end) as ds_covat_t9,
  sum(Case when extract(month from ngaychungtu) =10 then doanhsocovat else 0 end) as ds_covat_t10,
  sum(Case when extract(month from ngaychungtu) =11 then doanhsocovat else 0 end) as ds_covat_t11,
  sum(Case when extract(month from ngaychungtu) =12 then doanhsocovat else 0 end) as ds_covat_t12,

  sum(Case when extract(month from ngaychungtu) in(1,2,3) then doanhsocovat else 0 end) as ds_covat_q1,
  sum(Case when extract(month from ngaychungtu) in(4,5,6) then doanhsocovat else 0 end) as ds_covat_q2,

  sum(Case when extract(month from ngaychungtu) in(7,8,9) then doanhsocovat else 0 end) as ds_covat_q3,
  sum(Case when extract(month from ngaychungtu) in(10,11,12) then doanhsocovat else 0 end) as ds_covat_q4,

  sum(doanhsocovat) as doanhsocovat,
  max(updated_at) as inserted_at
from loc_doanhso

 group by all
 )
 ,

 data_sales_inv  as (
 select 
 a.invoicecustid,
 a.ghichu,
 sum(ds_covat_t1) as ds_covat_t1,
 sum(ds_covat_t2) as ds_covat_t2,
 sum(ds_covat_t3) as ds_covat_t3,
 sum(ds_covat_t4) as ds_covat_t4,
 sum(ds_covat_t5) as ds_covat_t5,
 sum(ds_covat_t6) as ds_covat_t6,
 sum(ds_covat_q1) as ds_covat_q1,
 sum(ds_covat_q2) as ds_covat_q2,

 sum(doanhsocovat) as doanhsocovat,
 sum(ds_covat_t7) as ds_covat_t7,
 sum(ds_covat_t8) as ds_covat_t8,
 sum(ds_covat_t9) as ds_covat_t9,
 sum(ds_covat_t10) as ds_covat_t10,
 sum(ds_covat_t11) as ds_covat_t11,
 sum(ds_covat_t12) as ds_covat_t12,
 sum(ds_covat_q3) as ds_covat_q3,
 sum(ds_covat_q4) as ds_covat_q4,
 max(inserted_at) as inserted_at
--  sum(doanhsocovat) - sum(doanhso_ebm) - sum(doanhso_ks) - sum(doanhso_xos) as doanhso_conlai

  from data_sales a
 LEFT JOIN union_all c on a.makhdms =c.makhdms and a.invoicecustid =c.ma_kh_thue and c.ma_chuongtrinh ='NTPP' and a.ghichu = c.ghichu
--  JOIN invoicecustid in (select ma_kh_thue from union_all) and
  where ma_chuongtrinh is null --không tính doanh số chính nó
group by all

)
-- ,

-- thanhtoan_q1 as 
-- (
--   SELECT e as makhthue, ngaychuyentien as ngaythanhtoantienck,ghichu
-- FROM `spatial-vision-343005.staging.d_manual_gs_ntpp` 
-- qualify row_number() over (partition by e order by ngaychuyentien desc) =1
-- )

SELECT
    a.ma_kh_thue as invoicecustid,
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
    b.*except(invoicecustid,ghichu),
    
    0.05 as muc_chiet_khau,
    ifnull(b.ds_covat_q1,0) * 5 / 100 as tong_tien_chiet_khau_q1,
    ifnull(b.ds_covat_q2,0) * 5 / 100 as tong_tien_chiet_khau_q2,
    ifnull(b.ds_covat_q3,0) * 5 / 100 as tong_tien_chiet_khau_q3,
    ifnull(b.ds_covat_q4,0) * 5 / 100 as tong_tien_chiet_khau_q4,
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
    LEFT JOIN `staging.d_master_khachhang` a1 on a.makhdms =a1.custid
    LEFT JOIN data_sales_inv b on b.invoicecustid = a.ma_kh_thue and a.ghichu = b.ghichu
    LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a.makhdms 
    LEFT JOIN `staging.d_users` e on l.col.ma_nvbh = e.manv
    -- LEFT JOIN thanhtoan_q1 f on f.makhthue = a.ma_kh_thue
-- WHERE
--      ma_chuongtrinh ='NTPP'
);

Create or replace table `warehouse.f_chuongtrinh_ntpp_2024`

copy `staging_temp.f_chuongtrinh_ntpp_2024_temp`;


END;