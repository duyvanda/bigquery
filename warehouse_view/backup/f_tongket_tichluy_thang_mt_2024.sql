CREATE VIEW `spatial-vision-343005.warehouse.f_tongket_tichluy_thang_mt_2024`
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
where custid in('010401','010553','007569','007568','010550','007213','007449','007447','009424','009727','010983','M0318001','004659','MC013','004677','004802','004718','MC018','009892','P4724-0337','004680','N07102074','MC017','HH10O516','003995','003030','011202','011201','010085','005777','MC007') or a.channel ='MT'
),

data_f_sales as (

  select 
  makhdms,
  date(thang) as thang,
  a.masanpham,
  b.nhomcpa,
  sum(doanhsochuavat) as  doanhsochuavat
  from `warehouse.f_sales_crs`  a 
  LEFT JOIN `staging.d_nhom_sp_trading` b on a.masanpham =b.masanpham
  where ngaychungtu >='2025-01-01'
  and (makhdms in('010401','010553','007569','007568','010550','007213','007449','007447','009424','009727','010983','M0318001','004659','MC013','004677','004802','004718','MC018','009892','P4724-0337','004680','N07102074','MC017','HH10O516','003995','003030','011202','011201','010085','005777','MC007') or (a.makenh_moi ='MT' and makenhphu not like '%SI%'))
  
  group by all
  order by 1,2

),

data_sales as (
select 
a.*,
b.thang,
--Ds Ebysta
sum(Case when b.masanpham ='EH115' then ifnull(doanhsochuavat,0) else 0 end) as doanhsochuavat_ebysta,
--Ds Diobysta
sum(Case when b.masanpham ='T3044004' then ifnull(doanhsochuavat,0) else 0 end) as doanhsochuavat_diobysta,

--Ds Adacast
sum(Case when b.masanpham in ('T303102005','T303102006') then ifnull(doanhsochuavat,0) else 0 end) as doanhsochuavat_adacast,

--Ds XO
sum(Case when b.nhomcpa  in ('XO') then ifnull(doanhsochuavat,0) else 0 end) as doanhsochuavat_xo,

--Ds KS+/CL
sum(Case when b.nhomcpa not in ('XO') then ifnull(doanhsochuavat,0) else 0 end) as doanhsochuavat_ks_cl,

-----

sum(ifnull(doanhsochuavat,0)) as doanhsochuavat_all,

from 
data_kh a
LEFT JOIN data_f_sales b on a.makhdms =b.makhdms
where b.makhdms is not null
group by all
order by phanloai_kh,thang
)
,

chietkhau as (
select *,
Case 
    -- Khách hàng FPT Long Châu
    when phanloai_kh ='Long Châu' and sum(doanhsochuavat_xo) over (partition by phanloai_kh,thang )  >= 30000000 then 0.05

    -- Khách hàng Wincommerce
    when phanloai_kh ='Dr Win' and sum(doanhsochuavat_xo) over (partition by phanloai_kh,thang )  >= 30000000 then 0.05

     -- Khách hàng An Khang
    when phanloai_kh ='An Khang' and sum(doanhsochuavat_xo) over (partition by phanloai_kh,thang ) >= 3000000 then 0.05 
  else 0 end as chietkhau_datthuong_xo,
Case 
    -- Khách hàng FPT Long Châu
    when phanloai_kh ='Long Châu' and sum(doanhsochuavat_ks_cl) over (partition by phanloai_kh,thang )  >= 20000000 then 0.1

    -- Khách hàng Wincommerce
    when phanloai_kh ='Dr Win' and sum(doanhsochuavat_ks_cl) over (partition by phanloai_kh,thang )  >= 20000000 then 0.1

     -- Khách hàng An Khang
    when phanloai_kh ='An Khang' and sum(doanhsochuavat_ks_cl) over (partition by phanloai_kh,thang ) >= 2000000 then 0.1
  else 0 end as chietkhau_datthuong_ks_cl,

Case 
    -- Khách hàng FPT Long Châu
    when phanloai_kh ='Long Châu' then 0.05

    -- Khách hàng Wincommerce
    when phanloai_kh ='Dr Win' then 0.05

     -- Khách hàng An Khang
    when phanloai_kh ='An Khang'  then 0.05 
  else 0 end as chietkhau_datthuong_xo_dukien,
Case 
    -- Khách hàng FPT Long Châu
    when phanloai_kh ='Long Châu'  then 0.1

    -- Khách hàng Wincommerce
    when phanloai_kh ='Dr Win'  then 0.1

     -- Khách hàng An Khang
    when phanloai_kh ='An Khang'  then 0.1
  else 0 end as chietkhau_datthuong_ks_cl_dukien,

   -- Chiết khấu 1
Case 

    -- Khách hàng Guardian (hỗ trợ trưng bày sản phẩm)
    when phanloai_kh ='Guardian'  then doanhsochuavat_all * 0.02 

     -- Khách hàng Con Cưng (hỗ trợ hệ thống vận hành)
    when phanloai_kh ='Con Cưng' then doanhsochuavat_all * 0.03
    -- Khách hàng Wincommerce (hỗ trợ khai trương)
    when phanloai_kh ='Wincommerce' then doanhsochuavat_all * 0.04
  else 0 end as chietkhau_hotro_1,
   -- Chiết khấu 2
Case 
    -- Khách hàng Guardian (hỗ trợ sinh nhật)
    when phanloai_kh ='Guardian'  then doanhsochuavat_all * 0.01

     -- Khách hàng Con Cưng (hỗ trợ khách hàng thành viên)
    when phanloai_kh ='Con Cưng' then doanhsochuavat_all * 0.03
     -- Khách hàng Wincommerce (hỗ trợ listing)
    when phanloai_kh ='Wincommerce' then doanhsochuavat_all * 0.05
  else 0 end as chietkhau_hotro_2,

   -- Chiết khấu 3
Case 
    -- Khách hàng Guardian (hỗ trợ quảng cáo lên cẩm nang)
    when phanloai_kh ='Guardian'  then doanhsochuavat_all * 0.1

     -- Khách hàng Con Cưng (hỗ trợ training nv)
    when phanloai_kh ='Con Cưng' then doanhsochuavat_all * 0.04
     -- Khách hàng Wincommerce (Hỗ trợ phí trưng bày hàng hóa trên kệ)
    when phanloai_kh ='Wincommerce' then doanhsochuavat_all * 0.03
  else 0 end as chietkhau_hotro_3,

    -- Chiết khấu 4
Case 
    -- Khách hàng Guardian (hỗ trợ khai trương cửa hàng mới)
    when phanloai_kh ='Guardian'  then doanhsochuavat_all * 0.01

     -- Khách hàng Con Cưng (hỗ trợ bán hàng)
    when phanloai_kh ='Con Cưng' then doanhsochuavat_all * 0.08
     -- Khách hàng Wincommerce (Hỗ trợ Online campaign)
    when phanloai_kh ='Wincommerce' then doanhsochuavat_all * 0.05
  else 0 end as chietkhau_hotro_4, 
    -- Chiết khấu 5
Case 
    -- Khách hàng Guardian (hỗ trợ chi phí vận hành online)
    when phanloai_kh ='Guardian'  then doanhsochuavat_all * 0.02

     -- Khách hàng Con Cưng (hỗ trợ mở rộng điểm bán)
    when phanloai_kh ='Con Cưng' then doanhsochuavat_all * 0.02
    -- Khách hàng Wincommerce (Hỗ trợ chi phí vận chuyển)
    when phanloai_kh ='Wincommerce' then doanhsochuavat_all * 0.05
  else 0 end as chietkhau_hotro_5, 
    -- Chiết khấu 6
Case 
    -- Khách hàng Guardian (hỗ trợ kiểm tra hàng tồn)
    when phanloai_kh ='Guardian'  then doanhsochuavat_all * 0.02

     -- Khách hàng Con Cưng (hỗ trợ chi phí vận chuyển)
    when phanloai_kh ='Con Cưng' then doanhsochuavat_all * 0.03
  else 0 end as chietkhau_hotro_6,   
  -- Chiết khấu 7
Case 
    -- Khách hàng Guardian (hỗ trợ chi phí vận chuyển)
    when phanloai_kh ='Guardian'  then doanhsochuavat_all * 0.03

     -- Khách hàng Con Cưng (hỗ trợ trung bày 1 sku)
    when phanloai_kh ='Con Cưng' then doanhsochuavat_all * 0.02
  else 0 end as chietkhau_hotro_7, 
  -- Chiết khấu 8
Case 
    -- Khách hàng Con Cưng (hỗ trợ marketing)
    when phanloai_kh ='Con Cưng' then doanhsochuavat_all * 0.05
  else 0 end as chietkhau_hotro_8,   
 from data_sales

)

select a.*,
chietkhau_datthuong_xo * doanhsochuavat_xo as tien_ck_xo,
chietkhau_datthuong_ks_cl * doanhsochuavat_ks_cl as tien_ck_ks_cl,
chietkhau_datthuong_xo * doanhsochuavat_xo + chietkhau_datthuong_ks_cl * doanhsochuavat_ks_cl as tong_ck_sp,

chietkhau_datthuong_xo_dukien * doanhsochuavat_xo as tien_ck_xo_dukien,
chietkhau_datthuong_ks_cl_dukien * doanhsochuavat_ks_cl as tien_ck_ks_cl_dukien,
chietkhau_datthuong_xo_dukien * doanhsochuavat_xo + chietkhau_datthuong_ks_cl_dukien * doanhsochuavat_ks_cl as tong_ck_sp_dukien,

chietkhau_hotro_1 + chietkhau_hotro_2 + chietkhau_hotro_3 + chietkhau_hotro_4 + chietkhau_hotro_5 + chietkhau_hotro_6 + chietkhau_hotro_7 + chietkhau_hotro_8 as tong_ck_hotro,
(select max(updated_at) from `warehouse.f_sales_crs` where ngaychungtu >='2025-01-01') as inserted_at,
'' as ma_crs,
'' as ten_crs,
b.tencvbh as ten_crm,
b.rsmid as ma_ncxm,
b.tenquanlyvung as ten_ncxm

from chietkhau a 
LEFT JOIN `staging.d_users` b on a.ma_crm = b.manv;