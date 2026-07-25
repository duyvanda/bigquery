CREATE VIEW `spatial-vision-343005.warehouse.view_f_chuongtrinh_clc123_2025_kt`
AS with
base_date as (
  SELECT
    distinct date_trunc(ngay,month) as thang,
    extract(quarter from ngay) as quy
    FROM
        unnest(
            GENERATE_DATE_ARRAY(
                date_sub(current_date("+7"), INTERVAL 24 MONTH),
                date_add(current_date("+7"), INTERVAL 12 MONTH),
                INTERVAL 1 DAY
            )
        ) AS ngay
),

loc_dh_co_kh as (

  select mahd,sum(case when doanhsochuavat =0 then 1 else 0 end) as is_hangkm
   from `warehouse.f_raw_data_sales_yoy` a
  where   ngaychungtu >='2025-01-01' and ngaychungtu < '2026-01-01' --'2025-05-31'
  and makhdms in (select makhdms from `staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` where ma_chuongtrinh ='CLC3')
  group by 1
  having is_hangkm <>0
),

loc_doanhso as 
(
  select 
  a.makhdms,
  a.thang,
  a.ngaychungtu,
  a.masanpham, 
  Case 
    when date(ngaychungtu) >= PARSE_DATE('%d/%m/%Y',  split(ghichu,'-')[0]) and date(ngaychungtu) <= PARSE_DATE('%d/%m/%Y',  split(ghichu,'-')[1])
    then doanhsocovat 
    else 0 
  end as doanhsocovat 
  from `warehouse.f_raw_data_sales_yoy` a
  JOIN `spatial-vision-343005.staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` b on a.makhdms=b.makhdms and b.ma_chuongtrinh in 
  ('CLC3','CLC2')
  where   ngaychungtu >='2025-01-01' and ngaychungtu <'2026-01-01' and mahd not in (select mahd from loc_dh_co_kh)
),

data_sales as (
select 
makhdms,
thang,
sum(Case when b.nhomcpa ='KS'then doanhsocovat else 0 end) doanhso_ks,
sum(Case when b.nhomcpa ='CL' then doanhsocovat else 0 end) doanhso_cl,
sum(Case when b.nhomcpa ='XO' then doanhsocovat else 0 end) doanhso_xos,
sum(doanhsocovat) as doanhsocovat

 from loc_doanhso a
-- JOIN loc_dh_co_kh c on a.mahd =c.mahd
 LEFT JOIN `staging.d_nhom_sp_trading` b on a.masanpham =b.masanpham
 group by all
 ),

tinh_chietkhau as (
select 
a1.thang,
a1.quy,
c.custidinvoice as invoicecustid,
c.custnameinvoice,
a.makhdms as custid,
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
ifnull(b.doanhso_cl,0) as doanhso_cl,
ifnull(b.doanhso_xos,0) as doanhso_xos,
sum(ifnull(b.doanhsocovat,0)) over (partition by a1.quy,a.makhdms) as acc_ds_quy,
-------Quý 4/2024
Case
    -------------CLC 1 2 ----------
    --  when a.makhdms ='003322' then 0.05
     when ifnull(b.doanhsocovat,0) >=15000000 and ma_chuongtrinh ='CLC2' then 0.1
     when ifnull(b.doanhsocovat,0) <15000000 and ma_chuongtrinh ='CLC2' then 0.05


     else 0 end as chietkhau_clc12,

-- Case
--     -------------CLC 3 ----------
--      when ifnull(b.doanhsocovat,0) >=15000000 and ma_chuongtrinh ='CLC3' 
--             then ifnull(b.doanhso_xos,0) * 0.05 + ifnull(b.doanhso_cl,0) *0.13 + ifnull(b.doanhso_ks,0) * 0.15

--      when ifnull(b.doanhsocovat,0) <15000000 and ma_chuongtrinh ='CLC3' 
--             then ifnull(b.doanhso_xos,0) * 0.05 + ifnull(b.doanhso_cl,0) *0.1 + ifnull(b.doanhso_ks,0) * 0.1 

--      else 0 end as chietkhau_clc3,   

Case 
    -------------CLC 3 ----------
    when ifnull(b.doanhsocovat,0) >= 15000000 and ma_chuongtrinh ='CLC3' then 0.05
    when ifnull(b.doanhsocovat,0) < 15000000 and ma_chuongtrinh ='CLC3' then 0.05
    else 0 end as chietkhau_xos_clc3,

Case 
    -------------CLC 3 ----------
    when ifnull(b.doanhsocovat,0) >= 15000000 and ma_chuongtrinh ='CLC3' then 0.13
    when ifnull(b.doanhsocovat,0) < 15000000 and ma_chuongtrinh ='CLC3' then 0.1  
    else 0 end as chietkhau_cl_clc3,

Case 
    -------------CLC 3 ----------
    when ifnull(b.doanhsocovat,0) >= 15000000 and ma_chuongtrinh ='CLC3' then 0.15
    when ifnull(b.doanhsocovat,0) < 15000000 and ma_chuongtrinh ='CLC3' then 0.1  
    else 0 end as chietkhau_ks_clc3,
    d.col.ma_nvbh as ma_crs,
    e.tencvbh,
    left(e.supid,6) as ma_crm,
    e.tenquanlytt,
    left(e.rsmid,6) as ma_ncxm,
    e.tenquanlyvung,
    '' as tinhtrang_trathuong,
    '' as ngaychuyentien,
    '' as ghichu


 from `staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` a 
 LEFT JOIN base_date a1 on 1 = 1
LEFT JOIN data_sales b on a.makhdms =b.makhdms and a1.thang =date(b.thang)
LEFT JOIN `staging.d_master_khachhang` c on a.makhdms =c.custid
LEFT JOIN `warehouse.f_mapping_crs` d on d.custid = a.makhdms 
LEFT JOIN `staging.d_users` e on d.col.ma_nvbh = e.manv


where ma_chuongtrinh in('CLC2','CLC3')
and a1.thang >='2025-01-01' and a1.thang <'2026-01-01'
)

select a.*,
--CLC2
a.doanhsocovat * a.chietkhau_clc12 as tong_tienthuong_clc12,

--CLC3
a.doanhso_xos * a.chietkhau_xos_clc3 as tienthuong_xos_clc3,
a.doanhso_cl * a.chietkhau_cl_clc3 as tienthuong_cl_clc3,
a.doanhso_ks * a.chietkhau_ks_clc3 as tienthuong_ks_clc3,

a.doanhso_xos * a.chietkhau_xos_clc3 + a.doanhso_cl * a.chietkhau_cl_clc3 + a.doanhso_ks * a.chietkhau_ks_clc3  as tong_tienthuong_clc3,

(select max(updated_at) from `warehouse.f_raw_data_sales_yoy` where ngaychungtu >='2025-01-01') as inserted_at

from tinh_chietkhau a;