CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_tichluy_ntpp()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_chuongtrinh_tichluy_ntpp_temp`;

 INSERT INTO `staging_temp.f_chuongtrinh_tichluy_ntpp_temp`

(   

-- Create or replace table staging_temp.f_chuongtrinh_tichluy_ntpp_temp as

with
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

tuyen_dms_bytime as 
(
with data_tuyen as (
SELECT custid,slsperid,crtd_datetime,thang,
Case when routetype in ('B','D') then 1 else 2 end as routetype,
FROM `spatial-vision-343005.staging.sync_dms_srm_bytime`  a 
LEFT JOIN `staging.d_users` b on a.slsperid =b.manv

where delroutedet is false and routetype in ('B','D') --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
and custid not in (select custid from tuyen_dms_moinhat)
)

select custid,slsperid
from data_tuyen
qualify row_number() over (partition by custid order by thang desc,routetype asc,crtd_datetime desc) =1
),

loc_doanhso as 
(
  select 
  a.macongtycn,
  a.makhdms,
  a.ngaychungtu,
  a.mahd,
  a.maphanloaihco,
  c.invoicecustid,
  Case 
    when date(ngaychungtu) >= PARSE_DATE('%d/%m/%Y',  split(ghichu,'-')[0]) and date(ngaychungtu) <= PARSE_DATE('%d/%m/%Y',  split(ghichu,'-')[1])
    then doanhsocovat 
    else 0 
  end as doanhsocovat 
  from `staging.f_sales` a
  LEFT JOIN `staging.sync_dms_so` c on a.mahd =c.ordernbr and a.macongtycn =c.branchid
  LEFT JOIN `spatial-vision-343005.staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` b on c.invoicecustid=b.ma_kh_thue and b.ma_chuongtrinh in ('NTPP')
  -- START Duy add new 28 12 2023 filter only NTXQPK
  INNER JOIN staging.d_master_khachhang d on a.makhdms = d.custid and d.hcotypeid = 'NTXQPK'
  -- END
  where   ngaychungtu >='2023-07-01' and ngaychungtu <'2024-01-01'
),


data_sales as (
select 
makhdms,
invoicecustid,
-- sum(Case when extract(month from ngaychungtu) in(7,8,9) then doanhsocovat else 0 end) as ds_covat_t7_8_9,
sum(Case when extract(month from ngaychungtu) =7 then doanhsocovat else 0 end) as ds_covat_t7,
sum(Case when extract(month from ngaychungtu) =8 then doanhsocovat else 0 end) as ds_covat_t8,
sum(Case when extract(month from ngaychungtu) =9 then doanhsocovat else 0 end) as ds_covat_t9,
sum(Case when extract(month from ngaychungtu) =10 then doanhsocovat else 0 end) as ds_covat_t10,
sum(Case when extract(month from ngaychungtu) =11 then doanhsocovat else 0 end) as ds_covat_t11,
sum(Case when extract(month from ngaychungtu) =12 then doanhsocovat else 0 end) as ds_covat_t12,

sum(Case when extract(month from ngaychungtu) in(7,8,9) then doanhsocovat else 0 end) as ds_covat_q3,
sum(Case when extract(month from ngaychungtu) in(10,11,12) then doanhsocovat else 0 end) as ds_covat_q4,

sum(doanhsocovat) as doanhsocovat
from loc_doanhso
 
 where   ngaychungtu >='2023-07-01' and ngaychungtu <'2024-01-01' and maphanloaihco='NTXQPK'
 group by 1,2
 ),

---E cứ lấy dso mà xuất theo ttin thuế của dsach c gửi là tính,nhớ trừ dso xuất cho chính nó là được
data_sales_inv  as (
 select 
 --a.*,b.channel,b.shoptype,b.hcoid,b.hcotypeid,c.ma_chuongtrinh
 invoicecustid,
 sum(doanhsocovat) as doanhsocovat,
 sum(ds_covat_t7) as ds_covat_t7,
 sum(ds_covat_t8) as ds_covat_t8,
 sum(ds_covat_t9) as ds_covat_t9,
 sum(ds_covat_t10) as ds_covat_t10,
 sum(ds_covat_t11) as ds_covat_t11,
 sum(ds_covat_t12) as ds_covat_t12,
 sum(ds_covat_q3) as ds_covat_q3,
 sum(ds_covat_q4) as ds_covat_q4
--  sum(doanhsocovat) - sum(doanhso_ebm) - sum(doanhso_ks) - sum(doanhso_xos) as doanhso_conlai

  from data_sales a
 LEFT JOIN `staging.d_master_khachhang` b on a.makhdms =b.custid
 LEFT JOIN staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp c on a.makhdms =c.makhdms and a.invoicecustid =c.ma_kh_thue and c.ma_chuongtrinh ='NTPP'

 where invoicecustid in (select ma_kh_thue from staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp where ma_chuongtrinh ='NTPP') and
  ma_chuongtrinh is null --không tính doanh số chính nó
group by 1

),

thanhtoan_q2 as 
(
  SELECT makhthue, ngaythanhtoantienck,ghichu
FROM `spatial-vision-343005.staging.d_manual_gs_ntpp` 
qualify row_number() over (partition by makhthue order by ngaythanhtoantienck desc) =1
),

thanhtoan_q3 as 
(
    SELECT makhthue,ngaychuyentien as ngaythanhtoantienck,ghichu
FROM `spatial-vision-343005.staging.d_manual_gs_ntpp_quy032023` 
qualify row_number() over (partition by makhthue order by ngaychuyentien desc) =1
)

select 
a.*,
b.statedescr,
b.branchid,
b.branchname,
b.channel,
b.shoptype,
b.shortterritorydescr,
ifnull(c.doanhsocovat,0) as doanhsocovat,
ifnull(c.ds_covat_t7,0) as ds_covat_t7,
ifnull(c.ds_covat_t8,0) as ds_covat_t8,
ifnull(c.ds_covat_t9,0) as ds_covat_t9,
ifnull(c.ds_covat_t10,0) as ds_covat_t10,
ifnull(c.ds_covat_t11,0) as ds_covat_t11,
ifnull(c.ds_covat_t12,0) as ds_covat_t12,

ifnull(c.ds_covat_q3,0) as ds_covat_q3,
ifnull(c.ds_covat_q4,0) as ds_covat_q4,
-- c.doanhso_conlai,
ifnull(c.ds_covat_q3,0) * 5/100 as tong_tienthuong,
ifnull(c.ds_covat_q4,0) * 5/100 as tong_tienthuong_q4,
  ifnull (d.slsperid,d1.slsperid) as manv,
  d2.tencvbh,
  d2.supid as crm,
  d2.tenquanlytt,
  d2.asm as scrm,
  d2.rsmid as ncxm,
  d2.tenquanlyvung,
  Case when e.ngaythanhtoantienck is not null then 'Đã trả' else 'Chưa trả' end as tinhtrang_thanhtoan,
  Case when e.ngaythanhtoantienck is null then e.ghichu else null end as ghichu_thanhtoan,
  e.ngaythanhtoantienck,
  Case when f.ngaythanhtoantienck is not null then 'Đã trả' else 'Chưa trả' end as tinhtrang_thanhtoan_q3,
  Case when f.ngaythanhtoantienck is null then f.ghichu else null end as ghichu_thanhtoan_q3,
  f.ngaythanhtoantienck as ngaythanhtoantienck_q3
 from 
`staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` a
 LEFT JOIN `staging.d_master_khachhang` b on a.makhdms =b.custid
 LEFT JOIN data_sales_inv c on c.invoicecustid = a.ma_kh_thue
 LEFT JOIN tuyen_dms_moinhat d on a.makhdms =d.custid
 LEFT JOIN tuyen_dms_bytime d1 on a.makhdms =d1.custid
 LEFT JOIN `staging.d_users` d2 on ifnull (d.slsperid,d1.slsperid)=d2.manv
 LEFT JOIN thanhtoan_q2 e on e.makhthue = a.ma_kh_thue
 LEFT JOIN thanhtoan_q3 f on f.makhthue = a.ma_kh_thue

where ma_chuongtrinh ='NTPP' and makhdms not in ('002224','003362') -- THeo email ngày 15/8 bỏ 2 KH này ra: Cap nhat danh sach NTPP

);

Create or replace table `warehouse.f_chuongtrinh_tichluy_ntpp`

copy `staging_temp.f_chuongtrinh_tichluy_ntpp_temp`;


END;