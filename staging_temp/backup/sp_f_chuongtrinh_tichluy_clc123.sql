CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_tichluy_clc123()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_chuongtrinh_tichluy_clc123_temp`;

 INSERT INTO `staging_temp.f_chuongtrinh_tichluy_clc123_temp`

(   


--  Create or replace table staging_temp.f_chuongtrinh_tichluy_clc123_temp as
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

loc_dh_co_kh as (

  select mahd,sum(case when doanhsochuavat =0 then 1 else 0 end) as is_hangkm
   from `staging.f_sales` a
  where   ngaychungtu >='2023-07-01' and ngaychungtu <'2023-10-01' 
  and makhdms in (select makhdms from `staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` where ma_chuongtrinh ='CLC3')
  group by 1
  having is_hangkm <>0
),

data_sales as (
select 
makhdms,
-- invoicecustid,
-- sum(Case when extract(month from ngaychungtu) in(7,8,9) then doanhsocovat else 0 end) as ds_covat_t7_8_9,
sum(Case when extract(month from ngaychungtu) =7 then doanhsocovat else 0 end) as ds_covat_t7,
sum(Case when extract(month from ngaychungtu) =8 then doanhsocovat else 0 end) as ds_covat_t8,
sum(Case when extract(month from ngaychungtu) =9 then doanhsocovat else 0 end) as ds_covat_t9,
sum(Case when b.nhomcpa ='KS&STO' then doanhsocovat else 0 end) doanhso_ks,
sum(Case when b.nhomcpa ='EBM' then doanhsocovat else 0 end) doanhso_ebm,
sum(Case when b.nhomcpa ='XOS' then doanhsocovat else 0 end) doanhso_xos,

sum(doanhsocovat) as doanhsocovat
 from `staging.f_sales` a
-- JOIN loc_dh_co_kh c on a.mahd =c.mahd
 LEFT JOIN `staging.d_nhom_sp_trading` b on a.masanpham =b.masanpham
--  LEFT JOIN `staging.sync_dms_so` b on a.mahd =b.ordernbr and a.macongtycn =b.branchid
 where   ngaychungtu >='2023-07-01' and ngaychungtu <'2023-10-01' and mahd not in (select mahd from loc_dh_co_kh)
 group by 1
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
ifnull(b.doanhsocovat,0) as doanhsocovat,
ifnull(b.doanhso_ks,0) as doanhso_ks,
ifnull(b.doanhso_ebm,0) as doanhso_ebm,
ifnull(b.doanhso_xos,0) as doanhso_xos,
ifnull(b.doanhsocovat,0) - ifnull(b.doanhso_ks,0) - ifnull(b.doanhso_ebm,0) - ifnull(b.doanhso_xos,0) as doanhso_conlai,
ifnull(b.ds_covat_t7,0) as ds_covat_t7,
ifnull(b.ds_covat_t8,0) as ds_covat_t8,
ifnull(b.ds_covat_t9,0) as ds_covat_t9,


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
  d.manv,
  d.tencvbh,
  d.crm,
  d.tenquanlytt,
  d.scrm,
  d.ncxm,
  d.tenquanlyvung,
  Case when e.ngaychuyentien is not null then 'Đã trả'  
       when e1.ngaychuyentien is not null then 'Đã trả'
      else'Chưa trả' end as tinhtrang_trathuong,
  ifnull(e.ngaychuyentien,e1.ngaychuyentien) as ngaychuyentien,
  Case when e.ngaychuyentien is  null then e.lienhekh 
      when e1.ngaychuyentien is  null then e1.lienhekh 
      else null
  end as ghichu

 from `staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` a 
LEFT JOIN data_sales b on a.makhdms =b.makhdms
LEFT JOIN `staging.d_master_khachhang` c on a.makhdms =c.custid
LEFT JOIN tuyen_dms_moinhat d on a.makhdms =d.custid
LEFT JOIN `staging.d_manual_gs_clc1clc2` e on e.madms = a.makhdms and ma_chuongtrinh ='CLC1_2'
LEFT JOIN `staging.d_manual_gs_clc3` e1 on e1.madms = a.makhdms and ma_chuongtrinh ='CLC3'
where ma_chuongtrinh in('CLC1_2','CLC3')
)

select *,
doanhsocovat * chietkhau_clc12 as tong_tienthuong_clc12,
doanhso_xos * chietkhau_xos_clc3 as tienthuong_xos_cls3,
doanhso_ebm * chietkhau_ebm_clc3 as tienthuong_ebm_cls3,
doanhso_ks * chietkhau_ks_clc3 as tienthuong_ks_cls3,
doanhso_conlai * chietkhau_cl_clc3 as tienthuong_cl_cls3,

doanhso_xos * chietkhau_xos_clc3 + doanhso_ebm * chietkhau_ebm_clc3 + doanhso_ks * chietkhau_ks_clc3 + doanhso_conlai * chietkhau_cl_clc3 as tong_tienthuong_clc3

from tinh_chietkhau
where makhdms not in ('M1005003','TN90E015') --- Theo email báo hủy ngày 14/8 : CSBH nhom khach hang CLC1&CLC2

);

Create or replace table `warehouse.f_chuongtrinh_tichluy_clc123`

copy `staging_temp.f_chuongtrinh_tichluy_clc123_temp`;


END;