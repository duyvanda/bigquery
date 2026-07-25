CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_tichluy_clc123_q42023()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_chuongtrinh_tichluy_clc123_q42023_temp`;

 INSERT INTO `staging_temp.f_chuongtrinh_tichluy_clc123_q42023_temp`

(   
--  Create or replace table staging_temp.f_chuongtrinh_tichluy_clc123_q42023_temp as

with

tuyen_dms_moinhat 
as 
(
        with a as (
select distinct makhdms as custid,manv,tenquanlyvung,tencvbh,tenquanlytt,crm,scrm,ncxm,
Case when tenquanlyvung ='Nguyễn Thọ Chiến' then 1
            else 3 end as datatype,
    -- date_trunc(ngaychungtu,month) as thang,
    ngaychungtu,
      from warehouse.f_sales_crs where ngaychungtu >='2023-04-01' and tenquanlyvung  in ('Nguyễn Thọ Chiến')
)
select * from a 

qualify row_number() over (partition by custid order by ngaychungtu desc,datatype asc) =1
),

tuyen_dms_moinhat_mcp as (
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

loc_dh_co_kh as (

  select mahd,sum(case when doanhsochuavat =0 then 1 else 0 end) as is_hangkm
   from `staging.f_sales` a
  where   ngaychungtu >='2023-07-01' and ngaychungtu <'2023-10-01' 
  and makhdms in (select makhdms from `staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` where ma_chuongtrinh ='CLC3')
  group by 1
  having is_hangkm <>0
),

loc_doanhso as 
(
  select a.makhdms,
  a.ngaychungtu,
  a.masanpham, 
  Case 
    when date(ngaychungtu) >= PARSE_DATE('%d/%m/%Y',  split(ghichu,'-')[0]) and date(ngaychungtu) <= PARSE_DATE('%d/%m/%Y',  split(ghichu,'-')[1])
    then doanhsocovat 
    else 0 
  end as doanhsocovat 
  from `staging.f_sales` a
  JOIN `spatial-vision-343005.staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` b on a.makhdms=b.makhdms and b.ma_chuongtrinh in 
  ('CLC3','CLC1_2')
  where   ngaychungtu >='2023-07-01' and ngaychungtu <'2024-01-01' and mahd not in (select mahd from loc_dh_co_kh)
),

data_sales as (
select 
makhdms,
-- invoicecustid,
-- sum(Case when extract(month from ngaychungtu) in(7,8,9) then doanhsocovat else 0 end) as ds_covat_t7_8_9,
sum(Case when extract(month from ngaychungtu) =7 then doanhsocovat else 0 end) as ds_covat_t7,
sum(Case when extract(month from ngaychungtu) =8 then doanhsocovat else 0 end) as ds_covat_t8,
sum(Case when extract(month from ngaychungtu) =9 then doanhsocovat else 0 end) as ds_covat_t9,

sum(Case when extract(month from ngaychungtu) =10 then doanhsocovat else 0 end) as ds_covat_t10,
sum(Case when extract(month from ngaychungtu) =11 then doanhsocovat else 0 end) as ds_covat_t11,
sum(Case when extract(month from ngaychungtu) =12 then doanhsocovat else 0 end) as ds_covat_t12,

sum(Case when b.nhomcpa ='KS&STO' and extract(month from ngaychungtu) in (10,11,12) then doanhsocovat else 0 end) doanhso_ks,
sum(Case when b.nhomcpa ='EBM' and extract(month from ngaychungtu) in (10,11,12)  then doanhsocovat else 0 end) doanhso_ebm,
sum(Case when b.nhomcpa ='XOS' and extract(month from ngaychungtu) in (10,11,12)  then doanhsocovat else 0 end) doanhso_xos,

sum(Case when b.nhomcpa ='KS&STO' and extract(month from ngaychungtu) in (7,8,9) then doanhsocovat else 0 end) doanhso_ks_q3,
sum(Case when b.nhomcpa ='EBM' and extract(month from ngaychungtu) in (7,8,9)  then doanhsocovat else 0 end) doanhso_ebm_q3,
sum(Case when b.nhomcpa ='XOS' and extract(month from ngaychungtu) in (7,8,9)  then doanhsocovat else 0 end) doanhso_xos_q3,

sum(Case when extract(month from ngaychungtu) in (10,11,12) then doanhsocovat else 0 end) as doanhsocovat,
sum(Case when extract(month from ngaychungtu) in (7,8,9) then doanhsocovat else 0 end) as doanhsocovat_q3

 from loc_doanhso a
-- JOIN loc_dh_co_kh c on a.mahd =c.mahd
 LEFT JOIN `staging.d_nhom_sp_trading` b on a.masanpham =b.masanpham
--  LEFT JOIN `staging.sync_dms_so` b on a.mahd =b.ordernbr and a.macongtycn =b.branchid
 group by 1
 ),

 thanhtoan_q3_clc12 as 
 (

SELECT madms,ngaychuyentien,ghichu,lienhekhq0223 as lienhekh,sohoadonck as sohdonck,ngayhdon FROM `spatial-vision-343005.staging.d_manual_gs_clc1clc2_quy032023` 
qualify row_number() over (partition by madms order by ngaychuyentien desc)=1
)
,

thanhtoan_q3_clc3 as 
(
    SELECT madms,ngaychuyentien,ghichu,lienhekh,sohdonck,ngayhdonck as ngayhdon FROM `spatial-vision-343005.staging.d_manual_gs_clc3_quy032023` 
qualify row_number() over (partition by madms order by ngaychuyentien desc)=1
),

tinh_chietkhau as (
select 
a.makhdms,
a.ma_chuongtrinh,
c.custname,
c.channel,
c.shoptype,
c.statedescr,
c.districtdescr,
c.wardname,
c.hcotypeid,
c.branchid,
c.branchname,
c.shortterritorydescr,
ifnull(b.doanhsocovat,0) as doanhsocovat,
ifnull(b.doanhso_ks,0) as doanhso_ks,
ifnull(b.doanhso_ebm,0) as doanhso_ebm,
ifnull(b.doanhso_xos,0) as doanhso_xos,
ifnull(b.doanhsocovat,0) - ifnull(b.doanhso_ks,0) - ifnull(b.doanhso_ebm,0) - ifnull(b.doanhso_xos,0) as doanhso_conlai,
ifnull(b.ds_covat_t10,0) as ds_covat_t10,
ifnull(b.ds_covat_t11,0) as ds_covat_t11,
ifnull(b.ds_covat_t12,0) as ds_covat_t12,

ifnull(b.doanhsocovat_q3,0) as doanhsocovat_q3,
ifnull(b.doanhso_ks_q3,0) as doanhso_ks_q3,
ifnull(b.doanhso_ebm_q3,0) as doanhso_ebm_q3,
ifnull(b.doanhso_xos_q3,0) as doanhso_xos_q3,
ifnull(b.doanhsocovat_q3,0) - ifnull(b.doanhso_ks_q3,0) - ifnull(b.doanhso_ebm_q3,0) - ifnull(b.doanhso_xos_q3,0) as doanhso_conlai_q3,
ifnull(b.ds_covat_t7,0) as ds_covat_t7,
ifnull(b.ds_covat_t8,0) as ds_covat_t8,
ifnull(b.ds_covat_t9,0) as ds_covat_t9,

-------Quý 4/2023
Case
    -------------CLC 1 2 ----------
     when ifnull(b.doanhsocovat,0) >=15000000 and ma_chuongtrinh ='CLC1_2' then 0.1
     when ifnull(b.doanhsocovat,0) <15000000 and ma_chuongtrinh ='CLC1_2' then 0.05


     else 0 end as chietkhau_clc12,

Case
    -------------CLC 3 ----------
     when ifnull(b.doanhsocovat,0) >=15000000 and ma_chuongtrinh ='CLC3' 
            then ifnull(b.doanhso_xos,0) * 0.05 + ifnull(b.doanhso_ebm,0) *0.1 + ifnull(b.doanhso_ks,0) * 0.15 + 
            (ifnull(b.doanhsocovat,0) - ifnull(b.doanhso_ks,0) - ifnull(b.doanhso_ebm,0) - ifnull(b.doanhso_xos,0)) *0.13

     when ifnull(b.doanhsocovat,0) <15000000 and ma_chuongtrinh ='CLC3' 
            then ifnull(b.doanhso_xos,0) * 0.05 + ifnull(b.doanhso_ebm,0) *0.1 + ifnull(b.doanhso_ks,0) * 0.1 + 
            (ifnull(b.doanhsocovat,0) - ifnull(b.doanhso_ks,0) - ifnull(b.doanhso_ebm,0) - ifnull(b.doanhso_xos,0)) *0.1
     else 0 end as chietkhau_clc3,   

Case 
    -------------CLC 3 ----------
    when ifnull(b.doanhsocovat,0) >= 15000000 and ma_chuongtrinh ='CLC3' then 0.05
    when ifnull(b.doanhsocovat,0) < 15000000 and ma_chuongtrinh ='CLC3' then 0.05
    else 0 end as chietkhau_xos_clc3,

Case 
    -------------CLC 3 ----------
    when ifnull(b.doanhsocovat,0) >= 15000000 and ma_chuongtrinh ='CLC3' then 0.1
    when ifnull(b.doanhsocovat,0) < 15000000 and ma_chuongtrinh ='CLC3' then 0.1  
    else 0 end as chietkhau_ebm_clc3,

Case 
    -------------CLC 3 ----------
    when ifnull(b.doanhsocovat,0) >= 15000000 and ma_chuongtrinh ='CLC3' then 0.15
    when ifnull(b.doanhsocovat,0) < 15000000 and ma_chuongtrinh ='CLC3' then 0.1  
    else 0 end as chietkhau_ks_clc3,

Case 
    -------------CLC 3 ----------
    when ifnull(b.doanhsocovat,0) >= 15000000 and ma_chuongtrinh ='CLC3' then 0.13
    when ifnull(b.doanhsocovat,0) < 15000000 and ma_chuongtrinh ='CLC3' then 0.1  
  else 0 end as chietkhau_cl_clc3,

  ----Quý 3/2023

Case
    -------------CLC 1 2 ----------
     when ifnull(b.doanhsocovat_q3,0) >=15000000 and ma_chuongtrinh ='CLC1_2' then 0.1
     when ifnull(b.doanhsocovat_q3,0) <15000000 and ma_chuongtrinh ='CLC1_2' then 0.05


     else 0 end as chietkhau_clc12_q3,

Case
    -------------CLC 3 ----------
     when ifnull(b.doanhsocovat_q3,0) >=15000000 and ma_chuongtrinh ='CLC3' 
            then ifnull(b.doanhso_xos_q3,0) * 0.05 + ifnull(b.doanhso_ebm_q3,0) *0.1 + ifnull(b.doanhso_ks_q3,0) * 0.15 + 
            (ifnull(b.doanhsocovat_q3,0) - ifnull(b.doanhso_ks_q3,0) - ifnull(b.doanhso_ebm_q3,0) - ifnull(b.doanhso_xos_q3,0)) *0.13

     when ifnull(b.doanhsocovat_q3,0) <15000000 and ma_chuongtrinh ='CLC3' 
            then ifnull(b.doanhso_xos_q3,0) * 0.05 + ifnull(b.doanhso_ebm_q3,0) *0.1 + ifnull(b.doanhso_ks_q3,0) * 0.1 + 
            (ifnull(b.doanhsocovat_q3,0) - ifnull(b.doanhso_ks_q3,0) - ifnull(b.doanhso_ebm_q3,0) - ifnull(b.doanhso_xos_q3,0)) *0.1
     else 0 end as chietkhau_clc3_q3,   

Case 
    -------------CLC 3 ----------
    when ifnull(b.doanhsocovat_q3,0) >= 15000000 and ma_chuongtrinh ='CLC3' then 0.05
    when ifnull(b.doanhsocovat_q3,0) < 15000000 and ma_chuongtrinh ='CLC3' then 0.05
    else 0 end as chietkhau_xos_clc3_q3,

Case 
    -------------CLC 3 ----------
    when ifnull(b.doanhsocovat_q3,0) >= 15000000 and ma_chuongtrinh ='CLC3' then 0.1
    when ifnull(b.doanhsocovat_q3,0) < 15000000 and ma_chuongtrinh ='CLC3' then 0.1  
    else 0 end as chietkhau_ebm_clc3_q3,

Case 
    -------------CLC 3 ----------
    when ifnull(b.doanhsocovat_q3,0) >= 15000000 and ma_chuongtrinh ='CLC3' then 0.15
    when ifnull(b.doanhsocovat_q3,0) < 15000000 and ma_chuongtrinh ='CLC3' then 0.1  
    else 0 end as chietkhau_ks_clc3_q3,

Case 
    -------------CLC 3 ----------
    when ifnull(b.doanhsocovat_q3,0) >= 15000000 and ma_chuongtrinh ='CLC3' then 0.13
    when ifnull(b.doanhsocovat_q3,0) < 15000000 and ma_chuongtrinh ='CLC3' then 0.1  
  else 0 end as chietkhau_cl_clc3_q3,

  ifnull (d1.slsperid,d.manv) as manv,
  d2.tencvbh,
  d2.supid as crm,
  d2.tenquanlytt,
  d2.asm as scrm,
  d2.rsmid as ncxm,
  d2.tenquanlyvung,
  Case when e.ngaychuyentien is not null then 'Đã trả'  
       when e1.ngaychuyentien is not null then 'Đã trả'
      else'Chưa trả' end as tinhtrang_trathuong,
  ifnull(e.ngaychuyentien,e1.ngaychuyentien) as ngaychuyentien,
  Case when e.ngaychuyentien is  null then e.lienhekh 
      when e1.ngaychuyentien is  null then e1.lienhekh 
      else null
  end as ghichu,
  Case when f.ngaychuyentien is not null then 'Đã trả'  
       when f1.ngaychuyentien is not null then 'Đã trả'
      else'Chưa trả' end as tinhtrang_trathuong_q3,
  ifnull(f.ngaychuyentien,f1.ngaychuyentien) as ngaychuyentien_q3,
  Case when f.ngaychuyentien is  null then f.lienhekh 
      when f1.ngaychuyentien is  null then f1.lienhekh 
      else null
  end as ghichu_q3,

  ifnull(f.sohdonck,f1.sohdonck) as sohdonck,
  ifnull(f.ngayhdon,f1.ngayhdon) as ngayhdon,
  ifnull(e.sohdonck,e1.sohdonck) as sohdonck_q2,
  ifnull(e.ngayhdonck,e1.ngayhdonck) as ngayhdon_q2

 from `staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` a 
LEFT JOIN data_sales b on a.makhdms =b.makhdms
LEFT JOIN `staging.d_master_khachhang` c on a.makhdms =c.custid
LEFT JOIN tuyen_dms_moinhat d on a.makhdms =d.custid
LEFT JOIN tuyen_dms_moinhat_mcp d1 on a.makhdms =d1.custid
LEFT JOIN `staging.d_users` d2 on ifnull(d1.slsperid,d.manv)= d2.manv
LEFT JOIN `staging.d_manual_gs_clc1clc2` e on e.madms = a.makhdms and ma_chuongtrinh ='CLC1_2'
LEFT JOIN `staging.d_manual_gs_clc3` e1 on e1.madms = a.makhdms and ma_chuongtrinh ='CLC3'
LEFT JOIN thanhtoan_q3_clc12 f on f.madms = a.makhdms and ma_chuongtrinh ='CLC1_2'
LEFT JOIN thanhtoan_q3_clc3 f1 on f1.madms = a.makhdms and ma_chuongtrinh ='CLC3'
where ma_chuongtrinh in('CLC1_2','CLC3')
)

select a.*,
a.doanhsocovat * a.chietkhau_clc12 as tong_tienthuong_clc12,
a.doanhsocovat_q3 * a.chietkhau_clc12_q3 as tong_tienthuong_clc12_q3,
a.doanhso_xos * a.chietkhau_xos_clc3 as tienthuong_xos_cls3,
a.doanhso_ebm * a.chietkhau_ebm_clc3 as tienthuong_ebm_cls3,
a.doanhso_ks * a.chietkhau_ks_clc3 as tienthuong_ks_cls3,
a.doanhso_conlai * a.chietkhau_cl_clc3 as tienthuong_cl_cls3,

a.doanhso_xos_q3 * a.chietkhau_xos_clc3_q3 as tienthuong_xos_cls3_q3,
a.doanhso_ebm_q3 * a.chietkhau_ebm_clc3_q3 as tienthuong_ebm_cls3_q3,
a.doanhso_ks_q3 * a.chietkhau_ks_clc3_q3 as tienthuong_ks_cls3_q3,
a.doanhso_conlai_q3 * a.chietkhau_cl_clc3_q3 as tienthuong_cl_cls3_q3,

a.doanhso_xos * a.chietkhau_xos_clc3 + a.doanhso_ebm * a.chietkhau_ebm_clc3 + a.doanhso_ks * a.chietkhau_ks_clc3 + a.doanhso_conlai * a.chietkhau_cl_clc3 as tong_tienthuong_clc3,

a.doanhso_xos_q3 * a.chietkhau_xos_clc3_q3 + a.doanhso_ebm_q3 * a.chietkhau_ebm_clc3_q3 + a.doanhso_ks_q3 * a.chietkhau_ks_clc3_q3 + a.doanhso_conlai_q3 * a.chietkhau_cl_clc3_q3  as tong_tienthuong_clc3_q3,


current_datetime("+7") as inserted_at

from tinh_chietkhau a
-- left join `warehouse.f_chuongtrinh_tichluy_clc123` b on a.ma_chuongtrinh =b.ma_chuongtrinh and a.makhdms =b.makhdms
where a.makhdms not in ('M1005003','TN90E015') --- Theo email báo hủy ngày 14/8 : CSBH nhom khach hang CLC1&CLC2
);

Create or replace table `warehouse.f_chuongtrinh_tichluy_clc123_q42023`

copy `staging_temp.f_chuongtrinh_tichluy_clc123_q42023_temp`;


END;