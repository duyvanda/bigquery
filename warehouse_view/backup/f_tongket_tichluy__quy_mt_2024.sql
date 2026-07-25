CREATE VIEW `spatial-vision-343005.warehouse.f_tongket_tichluy__quy_mt_2024`
AS with 

data_kh as 
(
select 
custid as makhdms,
Case 
    when a.custid in ('010401','010553','007569','007568','010550','007213','007449','007447') then 'Wincommerce'--
    when a.custid in ('009424') then 'Dr Win'--
    when a.custid in ('009727','010983') then 'Con Cưng'
    when a.custid in ('M0318001','004659') then 'Long Châu'--
    when a.custid in ('MC013','004677') then 'Pharmacity'--
    when a.custid in ('004802','004718','MC018') then 'An Khang'--
    when a.custid in ('009892','P4724-0337','004680') then 'Medx'--
    when a.custid in ('N07102074') then 'Trung Sơn'--
    when a.custid in ('MC017') then 'Guardian'--
    when a.custid in ('HH10O516','003995','003030','011202','011201','010085','005777','MC007') then 'CSBH MT Chung'
    when a.channel ='MT' then 'CSBH MT Chung'
    else 'CSBH MT Chung' 
end as phanloai_kh,

Case 
    when a.custid in ('010401','010553','007569','007568','010550','007213','007449','007447') then 'MR3066'--
    when a.custid in ('009424') then 'MR0868'--
    when a.custid in ('009727','010983') then 'MR3066'
    when a.custid in ('M0318001','004659') then 'MR0868'--
    when a.custid in ('MC013','004677') then 'MR3066'--
    when a.custid in ('004802','004718','MC018') then 'MR0868'--
    when a.custid in ('009892','P4724-0337','004680') then 'MR3066'--
    when a.custid in ('N07102074') then 'MR0868'--
    when a.custid in ('MC017') then 'MR3066'--
    when pubcustname like '%UPHARMA%' then 'MR0868'
    when pubcustname like '%PHARMADI%' then 'MR3066'
    when pubcustname like '%DP ECO%' then 'MR0868'
    when pubcustname like '%DP GLEE%' then 'MR0868'
    when pubcustname like '%SEN ĐỎ%' then 'MR3066'
    when pubcustname like '%VIETPOM%' then 'MR0868'
    when custnameinvoice like '%Nhật Minh%' then 'MR3066'
    when pubcustname like '%BRIGHTON CARE%' then 'MR0868'
    when custnameinvoice like '%CareAce%' then 'MR0868'
    -- when a.custid in ('HH10O516','003995','003030','011202','011201','010085','005777','MC007') then 'CSBH MT Chung'
    -- when a.channel ='MT' then 'CSBH MT Chung'
    -- else 'CSBH MT Chung' 
    else null
end as ma_crm,

a.branchid,
a.statedescr,
a.custname,
a.custidinvoice,
a.custnameinvoice,
a.hcoid
From `staging.d_master_khachhang` a
where custid in('010401','010553','007569','007568','010550','007213','007449','007447','009424','009727','010983','M0318001','004659','MC013','004677','004802','004718','MC018','009892','P4724-0337','004680','N07102074','MC017','HH10O516','003995','003030','011202','011201','010085','005777','MC007') or (a.channel ='MT' and shoptype not like '%SI%')
),

data_f_sales as (

  select * from (

  select 
  makhdms,
  extract(quarter from thang) as quy,
  Case when extract(month from thang) in (1,4,7,10) then 'thang_thu_1'
       when extract(month from thang) in (2,5,8,11) then 'thang_thu_2'
       when extract(month from thang) in (3,6,9,12) then 'thang_thu_3'
  else null end as thang_trong_quy,
  a.masanpham,
  b.nhomcpa,
  doanhsochuavat 
  from `warehouse.f_sales_crs`  a 
  LEFT JOIN `staging.d_nhom_sp_trading` b on a.masanpham =b.masanpham
  where ngaychungtu >='2025-01-01' --'2025-12-27' 
  and ( makhdms in('010401','010553','007569','007568','010550','007213','007449','007447','009424','009727','010983','M0318001','004659','MC013','004677','004802','004718','MC018','009892','P4724-0337','004680','N07102074','MC017','HH10O516','003995','003030','011202','011201','010085','005777','MC007') or a.makenh_moi ='MT')
  )
  PIVOT(SUM(doanhsochuavat) FOR thang_trong_quy IN ('thang_thu_1', 'thang_thu_2', 'thang_thu_3'))
  order by 1,2

),

data_sales as (
select 
a.*,
b.quy,
--Ds Ebysta
sum(Case when b.masanpham ='EH115' then ifnull(thang_thu_1,0) + ifnull(thang_thu_2,0) + ifnull(thang_thu_3,0) else 0 end) as doanhsochuavat_ebysta,
--Ds Diobysta
-- sum(Case when b.masanpham ='T3044004' then ifnull(thang_thu_1,0) + ifnull(thang_thu_2,0) + ifnull(thang_thu_3,0) else 0 end) as doanhsochuavat_diobysta,

--Ds medoral 250ml
sum(Case when b.masanpham ='EH092' then ifnull(thang_thu_1,0) + ifnull(thang_thu_2,0) + ifnull(thang_thu_3,0) else 0 end) as doanhsochuavat_medoral,

-- --Ds Adacast
-- sum(Case when b.masanpham in ('T303102005','T303102006') then ifnull(thang_thu_1,0) + ifnull(thang_thu_2,0) + ifnull(thang_thu_3,0) else 0 end) as doanhsochuavat_adacast,

--Ds XP
sum(Case when b.masanpham in ('T302202003','T302202004','T302202005') then ifnull(thang_thu_1,0) + ifnull(thang_thu_2,0) + ifnull(thang_thu_3,0) else 0 end) as doanhsochuavat_xp,

--Ds all trừ XP
sum(Case when b.masanpham not in ('T302202003','T302202004','T302202005') then ifnull(thang_thu_1,0) + ifnull(thang_thu_2,0) + ifnull(thang_thu_3,0) else 0 end) as doanhsochuavat_tru_xp,

--Ds KS+/CL
sum(Case when b.nhomcpa not in ('XO') then ifnull(thang_thu_1,0) + ifnull(thang_thu_2,0) + ifnull(thang_thu_3,0) else 0 end) as doanhsochuavat_ks_cl,

sum(Case when b.nhomcpa not in ('XO') then ifnull(thang_thu_1,0) else 0 end) as thang_thu_1_ks_cl,
sum(Case when b.nhomcpa not in ('XO') then ifnull(thang_thu_2,0) else 0 end) as thang_thu_2_ks_cl,
sum(Case when b.nhomcpa not in ('XO') then ifnull(thang_thu_3,0) else 0 end) as thang_thu_3_ks_cl,
-----
sum(ifnull(thang_thu_1,0)) as thang_thu_1_all,
sum(ifnull(thang_thu_2,0)) as thang_thu_2_all,
sum(ifnull(thang_thu_3,0)) as thang_thu_3_all,

sum( ifnull(thang_thu_1,0) + ifnull(thang_thu_2,0) + ifnull(thang_thu_3,0) )as doanhsochuavat_all,

from 
data_kh a
LEFT JOIN data_f_sales b on a.makhdms =b.makhdms
where b.makhdms is not null
group by all
order by phanloai_kh,quy
)
,

diobysta_adacast as (
select 
*,
if(quy >2,"C2","C1") as c_6thang,
-- sum(doanhsochuavat_diobysta) over (partition by phanloai_kh,quy order by makhdms ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as ds_diobysta_congdon,
-- sum(doanhsochuavat_adacast) over (partition by phanloai_kh,quy order by makhdms ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as ds_adacast_congdon,

from data_sales
)
,
chietkhau as (
select 
*,

-- Case when phanloai_kh in('Long Châu','An Khang') then
--   If(ds_diobysta_congdon <= 500000000,doanhsochuavat_diobysta,if(ds_diobysta_congdon > 500000000 and ds_diobysta_congdon - doanhsochuavat_diobysta > 500000000,0,500000000 - ds_diobysta_congdon + doanhsochuavat_diobysta ) ) 
--      when phanloai_kh ='Pharmacity' then
--   If(ds_diobysta_congdon <= 450000000,doanhsochuavat_diobysta,if(ds_diobysta_congdon > 450000000 and ds_diobysta_congdon - doanhsochuavat_diobysta > 450000000,0,450000000 - ds_diobysta_congdon + doanhsochuavat_diobysta ) ) 
-- else 0 end as ds_diobysta_tinhthuong,

-- Case when phanloai_kh ='Long Châu' then
--   If(ds_adacast_congdon <= 500000000,doanhsochuavat_adacast,if(ds_adacast_congdon > 500000000 and ds_adacast_congdon - doanhsochuavat_adacast > 500000000,0,500000000 - ds_adacast_congdon + doanhsochuavat_adacast ) ) 
--      when phanloai_kh in ('Pharmacity','An Khang') then
--   If(ds_adacast_congdon <= 450000000,doanhsochuavat_adacast,if(ds_adacast_congdon > 450000000 and ds_adacast_congdon - doanhsochuavat_adacast > 450000000,0,450000000 - ds_adacast_congdon + doanhsochuavat_adacast ) ) 
-- else 0 end as ds_adacast_tinhthuong,


Case 
    -- Khách hàng Trung Sơn
    when phanloai_kh ='Trung Sơn' and sum(doanhsochuavat_ebysta) over (partition by phanloai_kh,quy )  >= 600000000 then 0.1
    -- Khách hàng Pharmacity
    when phanloai_kh = 'Pharmacity' and sum(doanhsochuavat_ebysta) over (partition by phanloai_kh,quy ) >= 1500000000 then 0.11
     -- Khách hàng An Khang
    when phanloai_kh ='An Khang' and sum(doanhsochuavat_ebysta) over (partition by phanloai_kh,quy ) >= 25000000 then 0.11  
  else 0 end as chietkhau_datthuong_ebysta,

Case 
    -- Khách hàng FPT Trung Sơn
    when phanloai_kh ='Trung Sơn'  then 0.1
    -- Khách hàng Pharmacity
    when phanloai_kh = 'Pharmacity'  then 0.11
     -- Khách hàng An Khang
    when phanloai_kh ='An Khang'  then 0.11  
  else 0 end as chietkhau_datthuong_ebysta_dukien,

Case 
    -- Khách hàng FPT Long Châu , Pharmacity, An Khang
    when phanloai_kh in ('Pharmacity') and sum(doanhsochuavat_medoral) over (partition by phanloai_kh,quy ) >= 2000000000 then 0.1
  else 0 end as chietkhau_datthuong_medoral,

Case 
    -- Khách hàng FPT Long Châu , Pharmacity, An Khang
    when phanloai_kh in ('Pharmacity') then 0.1
  else 0 end as chietkhau_datthuong_medoral_dukien,
 
Case 
    -- Khách hàng FPT Long Châu , Pharmacity, An Khang
    when phanloai_kh in ('Pharmacity')  then 0.02
  else 0 end as chietkhau_datthuong_xp,


Case 
    -- Khách hàng FPT Long Châu
    when phanloai_kh ='Long Châu' and sum(doanhsochuavat_all) over (partition by phanloai_kh,quy ) >= 20000000000 then 0.01 
    -- -- Khách hàng Pharmacity ( đối vs pharma là all sản phẩm trừ XP)
    when phanloai_kh = 'Pharmacity' and sum(doanhsochuavat_tru_xp) over (partition by phanloai_kh,quy ) >= 2500000000 then 0.01
    -- Khách hàng An Khang
    when phanloai_kh ='An Khang' then 0.01
    -- -- Khách hàng Medx ( đối vs medx là all sản phẩm tính chung cho chi phí vận chuyển và chiết khấu)
    when phanloai_kh = 'Medx' and sum(doanhsochuavat_all) over (partition by phanloai_kh,quy ) >= 2000000000 then 0.01
    -- -- Khách hàng Trung Sơn
    when phanloai_kh = 'Trung Sơn' then 0.01
    -- -- Khách hàng Dr Win 
    -- when phanloai_kh = 'Dr Win' then 0.03
    -- Khách hàng Wincommerce
    when phanloai_kh = 'Dr Win' then 0.01
  else 0 end as chietkhau_datthuong_ks_cl,

Case 
    -- Khách hàng FPT Long Châu
    when phanloai_kh ='Long Châu'  then 0.01 
    -- -- Khách hàng Pharmacity ( đối vs pharma là all sản phẩm)
    when phanloai_kh = 'Pharmacity' then 0.01
    -- Khách hàng An Khang
    when phanloai_kh ='An Khang' then 0.01
    -- -- Khách hàng Medx ( đối vs medx là all sản phẩm)
    when phanloai_kh = 'Medx'  then 0.01
    -- Khách hàng Trung Sơn
    when phanloai_kh = 'Trung Sơn' then 0.01
    -- -- Khách hàng Dr Win 
    -- when phanloai_kh = 'Dr Win' then 0.03
    -- Khách hàng Wincommerce
    when phanloai_kh = 'Dr Win' then 0.01
  else 0 end as chietkhau_datthuong_ks_cl_dukien,

Case 
    -- Khách hàng FPT Long Châu
    when phanloai_kh ='Long Châu'  then 0.02
    -- -- Khách hàng Pharmacity
    when phanloai_kh = 'Pharmacity'  then 0.03
    --  -- Khách hàng An Khang
    when phanloai_kh ='An Khang' then 0.02
    --  -- Khách hàng Medx (hỗ trợ bán hàng trên mall)
    when phanloai_kh = 'Medx' then 0.01
    -- -- Khách hàng Trung Sơn
    when phanloai_kh = 'Trung Sơn' then 0.02
    -- Khách hàng Dr Win
    when phanloai_kh = 'Dr Win' then 0.02
    -- Khách hàng CSBH MT Chung
    when phanloai_kh = 'CSBH MT Chung' then 0.02
  else 0 end as chietkhau_van_chuyen,

     -- Khách hàng Medx quyết toán 6 tháng
-- Case 
--    when phanloai_kh = 'Medx' and  c_6thang ='C1' and sum(doanhsochuavat_all) over (partition by phanloai_kh,c_6thang ='C1' )  >= 12600000000 then 0.015
--    when phanloai_kh = 'Medx' and  c_6thang ='C1' and sum(doanhsochuavat_all) over (partition by phanloai_kh,c_6thang ='C1' ) >= 8100000000 then 0.01
--    when phanloai_kh = 'Medx' and  c_6thang ='C1' and sum(doanhsochuavat_all) over (partition by phanloai_kh,c_6thang ='C1' ) < 8100000000 then 0.005

--    when phanloai_kh = 'Medx' and  c_6thang ='C2' and sum(doanhsochuavat_all) over (partition by phanloai_kh,c_6thang ='C2' )  >= 15400000000 then 0.015
--    when phanloai_kh = 'Medx' and  c_6thang ='C2' and sum(doanhsochuavat_all) over (partition by phanloai_kh,c_6thang ='C2' ) >= 9900000000 then 0.01
--    when phanloai_kh = 'Medx' and  c_6thang ='C2' and sum(doanhsochuavat_all) over (partition by phanloai_kh,c_6thang ='C2' ) < 9900000000 then 0.005
-- else 0 end as chiet_khau_thuong_6thang

from diobysta_adacast

)
,
tien_ck as (
select
*,
--  doanhsochuavat_xp * 0.02 as sotien_ck_xp,
 doanhsochuavat_ebysta * chietkhau_datthuong_ebysta  as sotien_ck_ebysta,
 doanhsochuavat_ebysta * chietkhau_datthuong_ebysta_dukien  as sotien_ck_ebysta_dukien,
 doanhsochuavat_medoral * chietkhau_datthuong_medoral as sotien_ck_medoral,
 doanhsochuavat_medoral * chietkhau_datthuong_medoral_dukien as sotien_ck_medoral_dukien,
 doanhsochuavat_xp * chietkhau_datthuong_xp as sotien_ck_xp,
 
--  doanhsochuavat_medoral * chietkhau_datthuong_medoral_dukien as sotien_ck_medoral_dukien,

 doanhsochuavat_all  * chietkhau_van_chuyen  as sotien_ck_van_chuyen,

 Case when phanloai_kh in( 'Dr Win','Long Châu','Trung Sơn') then doanhsochuavat_all * chietkhau_datthuong_ks_cl 
      when phanloai_kh = 'Pharmacity' then doanhsochuavat_tru_xp * chietkhau_datthuong_ks_cl
      when phanloai_kh = 'Medx' then doanhsochuavat_all * chietkhau_datthuong_ks_cl * 2
      when phanloai_kh = 'An Khang' then doanhsochuavat_ks_cl *  chietkhau_datthuong_ks_cl 
      else 0
 end as sotien_ck_ks_cl,

  Case when phanloai_kh in( 'Dr Win','Long Châu','Trung Sơn') then doanhsochuavat_all * chietkhau_datthuong_ks_cl_dukien 
      when phanloai_kh = 'Pharmacity' then doanhsochuavat_tru_xp * chietkhau_datthuong_ks_cl_dukien
      when phanloai_kh = 'Medx' then doanhsochuavat_all * chietkhau_datthuong_ks_cl_dukien * 2
      when phanloai_kh = 'An Khang' then doanhsochuavat_ks_cl *  chietkhau_datthuong_ks_cl_dukien 
      else 0
 end as sotien_ck_ks_cl_dukien 

from chietkhau
order by 2,quy,makhdms

)

select 
a.*,
safe_divide(cast(sotien_ck_ebysta as numeric),76190.4761904762) as sl_sp_ebysta,
safe_divide(cast(sotien_ck_ebysta_dukien as numeric),76190.4761904762) as sl_sp_ebysta_dukien,
safe_divide(cast(sotien_ck_medoral as numeric),51428.5714285714) as sl_sp_medoral,
safe_divide(cast(sotien_ck_medoral_dukien as numeric),51428.5714285714) as sl_sp_medoral_dukien,

sotien_ck_van_chuyen + sotien_ck_ks_cl + sotien_ck_xp as tong_tien_ck,
sotien_ck_van_chuyen + sotien_ck_ks_cl_dukien + sotien_ck_xp as tong_tien_ck_dukien,
date(2025,quy * 3,01) as quy_filter,
(select max(updated_at) from `warehouse.f_sales_crs` where ngaychungtu >'2025-01-01') as inserted_at,
'' as ma_crs,
'' as ten_crs,
b.tencvbh as ten_crm,
b.rsmid as ma_ncxm,
b.tenquanlyvung as ten_ncxm
from tien_ck a
LEFT JOIN `staging.d_users` b on a.ma_crm = b.manv
;