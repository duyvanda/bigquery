CREATE VIEW `spatial-vision-343005.warehouse.f_tongket_tichluy_nam_mt_2024`
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
where custid in('010401','010553','007569','007568','010550','007213','007449','007447','009424','009727','010983','M0318001','004659','MC013','004677','004802','004718','MC018','009892','P4724-0337','004680','N07102074','MC017','HH10O516','003995','003030','011202','011201','010085','005777','MC007')
or (a.channel ='MT' and shoptype not like '%SI%')

),

data_f_sales as (

  select 
  a.makhdms,
  a.ngaychungtu,
  a.masanpham,
  b.nhomcpa,
  sum(a.doanhsochuavat) as  doanhsochuavat,
  max(updated_at) as inserted_at
  from `warehouse.f_sales_crs`  a 
  LEFT JOIN `staging.d_nhom_sp_trading` b on a.masanpham =b.masanpham
  where ngaychungtu >='2024-10-31'
  -- where ngaychungtu >='2024-10-31' and ngaychungtu <='2025-12-27'
  and (makhdms in('010401','010553','007569','007568','010550','007213','007449','007447','009424','009727','010983','M0318001','004659','MC013','004677','004802','004718','MC018','009892','P4724-0337','004680','N07102074','MC017','HH10O516','003995','003030','011202','011201','010085','005777','MC007') or (a.makenh_moi ='MT'and makenhphu not like '%SI%'))
  group by all
  order by 1,2

),

data_sales as (
select 
a.*,
--Ds xo
sum(Case when b.nhomcpa  in ('XO') and  ngaychungtu >='2025-01-01' then ifnull(doanhsochuavat,0) else 0 end) as doanhsochuavat_xo,

--Ds xp
sum(Case when b.masanpham in ('T302202003','T302202004','T302202005') and ngaychungtu < '2025-11-01' and ngaychungtu >='2024-10-31' then ifnull(doanhsochuavat,0) else 0 end) as doanhsochuavat_xp,

----- Pharma doanh số tính thưởng trừ XP
sum( Case when ngaychungtu >='2025-01-01' and b.masanpham not in ('T302202003','T302202004','T302202005') and phanloai_kh in ('Pharmacity') then ifnull(doanhsochuavat,0) 
          when phanloai_kh in ('Long Châu','An Khang','Dr Win','CSBH MT Chung','Medx','Trung Sơn') and ngaychungtu >='2025-01-01' then ifnull(doanhsochuavat,0) else 0 end) as doanhsochuavat_all,

sum(case when phanloai_kh in ('Long Châu','An Khang','Dr Win','CSBH MT Chung','Medx','Trung Sơn') and ngaychungtu >='2025-01-01' and ngaychungtu <'2025-04-01' then ifnull(doanhsochuavat,0) else 0 end) as doanhsochuavat_q1,
sum(case when phanloai_kh in ('Long Châu','An Khang','Dr Win','CSBH MT Chung','Medx','Trung Sơn') and ngaychungtu >='2025-04-01' and ngaychungtu <'2025-07-01' then ifnull(doanhsochuavat,0) else 0 end) as doanhsochuavat_q2,
sum(case when phanloai_kh in ('Long Châu','An Khang','Dr Win','CSBH MT Chung','Medx','Trung Sơn') and ngaychungtu >='2025-07-01' and ngaychungtu <'2025-10-01' then ifnull(doanhsochuavat,0) else 0 end) as doanhsochuavat_q3,
sum(case when phanloai_kh in ('Long Châu','An Khang','Dr Win','CSBH MT Chung','Medx','Trung Sơn') and ngaychungtu >='2025-10-01' and ngaychungtu <'2026-01-01' then ifnull(doanhsochuavat,0) else 0 end) as doanhsochuavat_q4,

max(b.inserted_at) as inserted_at
from 
data_kh a
LEFT JOIN data_f_sales b on a.makhdms =b.makhdms
where b.makhdms is not null
group by all
)
,

doanhso_all_pl_kh as (
select 
*,
sum(doanhsochuavat_all) over (partition by phanloai_kh order by doanhsochuavat_all desc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as doanhsochuavat_all_congdon,
sum(doanhsochuavat_all) over (partition by phanloai_kh  ) as doanhsochuavat_all_pl_kh,
sum(doanhsochuavat_xp) over (partition by phanloai_kh  ) as doanhsochuavat_all_pl_kh_xp,
-- sum(doanhsochuavat_all) over (partition by phanloai_kh  ) as doanhsochuavat_all_pl_kh,
1000000000 as moc_1ty,
2000000000 as moc_2ty,
4500000000 as moc_4_5ty,
8000000000 as moc_8ty,
9600000000 as moc_9_6ty,
15000000000 as moc_15ty,
20000000000 as moc_20ty,
23000000000 as moc_23ty,
28000000000 as moc_28ty,
36000000000 as moc_36ty,
40000000000 as moc_40ty,
90000000000 as moc_90ty,
100000000000 as moc_100ty,

from data_sales
-- where phanloai_kh ='Wincommerce'
)
,
chietkhau as (
select 
*,
Case 
---Long Châu
  when doanhsochuavat_all_pl_kh >= moc_100ty and phanloai_kh ='Long Châu' then 'PL1'
  when doanhsochuavat_all_pl_kh >= moc_90ty  and phanloai_kh ='Long Châu' then 'PL2'

---Pharma
  when doanhsochuavat_all_pl_kh >= moc_40ty and phanloai_kh ='Pharmacity' then 'PL1'
  when doanhsochuavat_all_pl_kh >= moc_36ty  and phanloai_kh ='Pharmacity' then 'PL2'

  ---Medx
  when doanhsochuavat_all_pl_kh >= moc_28ty and phanloai_kh ='Medx' then 'PL1'
  when doanhsochuavat_all_pl_kh >= moc_23ty  and phanloai_kh ='Medx' then 'PL2'
  ---Trung Sơn
  when doanhsochuavat_all_pl_kh >= moc_9_6ty and phanloai_kh ='Trung Sơn' then 'PL1'
  when doanhsochuavat_all_pl_kh >= moc_8ty  and phanloai_kh ='Trung Sơn' then 'PL2'

---An Khang
  when doanhsochuavat_all_pl_kh < moc_15ty and phanloai_kh ='An Khang' then 'PL1'
  when doanhsochuavat_all_pl_kh >= moc_15ty and doanhsochuavat_all_pl_kh <= moc_20ty and phanloai_kh ='An Khang' then 'PL2'
  when doanhsochuavat_all_pl_kh > moc_20ty  and phanloai_kh ='An Khang' then 'PL3'

---Dr Win
  when doanhsochuavat_all_pl_kh >= moc_2ty and phanloai_kh ='Dr Win' then 'PL1'
  when doanhsochuavat_all_pl_kh >= moc_1ty and phanloai_kh ='Dr Win' then 'PL2'
else null end as chiet_khau_nam,

-- Case 
--     ---Pharma
--   when doanhsochuavat_all_pl_kh_xp > moc_4_5ty and phanloai_kh ='Pharmacity' then 'PL1'
--   when doanhsochuavat_all_pl_kh_xp <= moc_4_5ty  and phanloai_kh ='Pharmacity' then 'PL2'
-- else null end as chiet_khau_nam_xp

from doanhso_all_pl_kh

)
,

tyle as (
select 
*,
Case 
    when chiet_khau_nam in ('PL1') and phanloai_kh ='Long Châu' then 0.018
    when chiet_khau_nam in ('PL2') and phanloai_kh ='Long Châu' then 0.015

   when chiet_khau_nam in ('PL1') and phanloai_kh ='Pharmacity' then 0.0125
    when chiet_khau_nam in ('PL2') and phanloai_kh ='Pharmacity' then 0.01

    when chiet_khau_nam in ('PL1') and phanloai_kh ='Medx' then 0.015
    when chiet_khau_nam in ('PL2') and phanloai_kh ='Medx' then 0.0125

     when chiet_khau_nam in ('PL1') and phanloai_kh ='Trung Sơn' then 0.015
    when chiet_khau_nam in ('PL2') and phanloai_kh ='Trung Sơn' then 0.01

    when chiet_khau_nam in ('PL3','PL2','PL1') and phanloai_kh ='An Khang'then 0.02
    when chiet_khau_nam in ('PL1') and phanloai_kh ='Dr Win'then 0.015
    when chiet_khau_nam in ('PL2') and phanloai_kh ='Dr Win'then 0.01
else 0 end as ty_le_chietkhau1,

Case 
    when phanloai_kh ='Long Châu' then 0.015
    when phanloai_kh ='Pharmacity' then 0.0125
    when phanloai_kh ='Medx' then 0.0125
    when phanloai_kh ='Trung Sơn' then 0.010
    when phanloai_kh ='An Khang'then 0.02
    when phanloai_kh ='Dr Win'then 0.010
    
else 0 end as ty_le_chietkhau1_dukien,

Case 

    when chiet_khau_nam in ('PL3','PL2','PL1') and phanloai_kh ='An Khang'then 0.03
    -- when chiet_khau_nam in ('PL3','PL2','PL1') and phanloai_kh ='Trung Sơn'then 0.025
else 0 end as ty_le_chietkhau_vuot2,

Case 

    when phanloai_kh ='An Khang'then 0.03
else 0 end as ty_le_chietkhau_vuot2_dukien,

Case 

    when chiet_khau_nam in ('PL3','PL2','PL1') and phanloai_kh ='An Khang'then 0.05
else 0 end as ty_le_chietkhau_vuot3,

Case 

    when phanloai_kh ='An Khang'then 0.05
else 0 end as ty_le_chietkhau_vuot3_dukien,
--Chiết khấu theo sp 
Case 
    when  phanloai_kh ='Pharmacity' and sum(doanhsochuavat_xp) over (partition by phanloai_kh  ) <= 4500000000 then 0.01
    when  phanloai_kh ='Pharmacity' and sum(doanhsochuavat_xp) over (partition by phanloai_kh  ) > 4500000000 then 0.015
    when  phanloai_kh = 'CSBH MT Chung' and hcoid in('NTC','ECOM') and sum(doanhsochuavat_all) over (partition by custidinvoice  ) >= 500000000 then 0.01
    when  phanloai_kh = 'CSBH MT Chung' and hcoid in('FMCG') and sum(doanhsochuavat_all) over (partition by custidinvoice  ) >= 500000000 then 0.02

    -- when  phanloai_kh = 'Dr Win' and doanhsochuavat_all_pl_kh >= 2000000000 then 0.015
    -- when  phanloai_kh = 'Dr Win' and doanhsochuavat_all_pl_kh >= 1000000000 then 0.01
    -- when  phanloai_kh = 'Wincommerce' and doanhsochuavat_all_pl_kh >= 2500000000 then 0.02
else 0 end as ty_le_chietkhau_sp,

Case 
    when  phanloai_kh ='Pharmacity' and doanhsochuavat_xp >= 4500000000 then 0.015 
    when  phanloai_kh ='Pharmacity' and doanhsochuavat_xp < 4500000000 then 0.010
    when  phanloai_kh = 'CSBH MT Chung' and hcoid in('NTC','ECOM')  then 0.01
    when  phanloai_kh = 'CSBH MT Chung' and hcoid in('FMCG') then 0.02
    -- when  phanloai_kh = 'Dr Win' and doanhsochuavat_all_pl_kh >= 2000000000 then 0.015
    -- when  phanloai_kh = 'Dr Win' and doanhsochuavat_all_pl_kh >= 1000000000 then 0.01
    -- when  phanloai_kh = 'Wincommerce' and doanhsochuavat_all_pl_kh >= 2500000000 then 0.02
else 0 end as ty_le_chietkhau_sp_dukien,

from chietkhau
)
 
select 
a.*,
Case 
  when phanloai_kh in ('CSBH MT Chung') then doanhsochuavat_all * ty_le_chietkhau_sp 
  when phanloai_kh in ('Pharmacity') then doanhsochuavat_xp * ty_le_chietkhau_sp 
else 0 end as so_tien_chietkhau_sp,

Case 
  when phanloai_kh in ('CSBH MT Chung') then doanhsochuavat_all * ty_le_chietkhau_sp_dukien
  when phanloai_kh in ('Pharmacity') then doanhsochuavat_xp * ty_le_chietkhau_sp_dukien 
else 0 end as so_tien_chietkhau_sp_dukien,

Case 
  when phanloai_kh ='Long Châu' then doanhsochuavat_all * ty_le_chietkhau1
  when phanloai_kh ='Dr Win' then doanhsochuavat_all * ty_le_chietkhau1
  when phanloai_kh ='Pharmacity' then doanhsochuavat_all * ty_le_chietkhau1
  when phanloai_kh ='Medx' then doanhsochuavat_all * ty_le_chietkhau1
  when phanloai_kh ='Trung Sơn' then doanhsochuavat_all * ty_le_chietkhau1

  when chiet_khau_nam ='PL1' and phanloai_kh ='An Khang' then doanhsochuavat_all * ty_le_chietkhau1

  when chiet_khau_nam ='PL2' and phanloai_kh ='An Khang' and doanhsochuavat_all_congdon <= moc_15ty then doanhsochuavat_all * ty_le_chietkhau1
  when chiet_khau_nam ='PL2' and phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_15ty and doanhsochuavat_all_congdon - doanhsochuavat_all <= moc_15ty then (moc_15ty - doanhsochuavat_all_congdon + doanhsochuavat_all ) * ty_le_chietkhau1

  when chiet_khau_nam ='PL3' and phanloai_kh ='An Khang' and doanhsochuavat_all_congdon <= moc_15ty then doanhsochuavat_all * ty_le_chietkhau1
  when chiet_khau_nam ='PL3' and phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_15ty and doanhsochuavat_all_congdon - doanhsochuavat_all <= moc_15ty then (moc_15ty - doanhsochuavat_all_congdon + doanhsochuavat_all ) * ty_le_chietkhau1 

else 0 end as so_tien_chietkhau1,

Case 
  when phanloai_kh ='Long Châu' then doanhsochuavat_all * ty_le_chietkhau1_dukien
  when phanloai_kh ='Dr Win' then doanhsochuavat_all * ty_le_chietkhau1_dukien
  -- when phanloai_kh ='Pharmacity' then doanhsochuavat_all * ty_le_chietkhau1_dukien
  when phanloai_kh ='Pharmacity' then doanhsochuavat_all * 0.01
  when phanloai_kh ='Medx' then doanhsochuavat_all * ty_le_chietkhau1_dukien
  when phanloai_kh ='Trung Sơn' then doanhsochuavat_all * ty_le_chietkhau1_dukien

  when phanloai_kh ='An Khang' and doanhsochuavat_all_congdon <= moc_15ty then doanhsochuavat_all * ty_le_chietkhau1_dukien
  when phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_15ty and doanhsochuavat_all_congdon - doanhsochuavat_all <= moc_15ty then (moc_15ty - doanhsochuavat_all_congdon + doanhsochuavat_all ) * ty_le_chietkhau1_dukien 

else 0 end as so_tien_chietkhau1_dukien,

Case 
------------An khang

  when chiet_khau_nam ='PL2' and phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_15ty and doanhsochuavat_all_congdon  <= moc_20ty and doanhsochuavat_all_congdon  - doanhsochuavat_all <= moc_15ty  
                             then (doanhsochuavat_all_congdon - moc_15ty )  * ty_le_chietkhau_vuot2
  
  when chiet_khau_nam ='PL2' and phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_15ty  and doanhsochuavat_all_congdon  - doanhsochuavat_all > moc_15ty  then doanhsochuavat_all  * ty_le_chietkhau_vuot2

  when chiet_khau_nam ='PL3' and phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_15ty and doanhsochuavat_all_congdon  <= moc_20ty and doanhsochuavat_all_congdon  - doanhsochuavat_all <= moc_15ty  
                             then (doanhsochuavat_all_congdon - moc_15ty )  * ty_le_chietkhau_vuot2

  when chiet_khau_nam ='PL3' and phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_15ty and doanhsochuavat_all_congdon  <= moc_20ty and doanhsochuavat_all_congdon  - doanhsochuavat_all > moc_15ty 
                             and doanhsochuavat_all_congdon  - doanhsochuavat_all <=  moc_20ty then doanhsochuavat_all  * ty_le_chietkhau_vuot2

  when chiet_khau_nam ='PL3' and phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_20ty and doanhsochuavat_all_congdon  - doanhsochuavat_all <= moc_15ty   
                             then (moc_20ty - moc_15ty)  * ty_le_chietkhau_vuot2

  when chiet_khau_nam ='PL3' and phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_20ty and doanhsochuavat_all_congdon  - doanhsochuavat_all > moc_15ty  
                             and doanhsochuavat_all_congdon - doanhsochuavat_all <= moc_20ty 
                             then (moc_20ty - doanhsochuavat_all_congdon + doanhsochuavat_all) * ty_le_chietkhau_vuot2

else 0 end as so_tien_chietkhau2,

Case 
------------An khang

  when phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_15ty and doanhsochuavat_all_congdon  <= moc_20ty and doanhsochuavat_all_congdon  - doanhsochuavat_all > moc_15ty 
                             and doanhsochuavat_all_congdon  - doanhsochuavat_all <=  moc_20ty then doanhsochuavat_all  * ty_le_chietkhau_vuot2_dukien

  when phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_20ty and doanhsochuavat_all_congdon  - doanhsochuavat_all <= moc_15ty   
                             then (moc_20ty - moc_15ty)  * ty_le_chietkhau_vuot2_dukien

  when phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_20ty and doanhsochuavat_all_congdon  - doanhsochuavat_all > moc_15ty  
                              and doanhsochuavat_all_congdon - doanhsochuavat_all <= moc_20ty 
                             then (moc_20ty - doanhsochuavat_all_congdon + doanhsochuavat_all) * ty_le_chietkhau_vuot2_dukien

else 0 end as so_tien_chietkhau2_dukien,

Case 
------------An Khang
  when chiet_khau_nam ='PL3' and phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_20ty and doanhsochuavat_all_congdon - doanhsochuavat_all <= moc_20ty 
                              then (doanhsochuavat_all_congdon - moc_20ty ) * ty_le_chietkhau_vuot3
  when chiet_khau_nam ='PL3' and phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_20ty and doanhsochuavat_all_congdon - doanhsochuavat_all > moc_20ty 
                              then doanhsochuavat_all * ty_le_chietkhau_vuot3 
else 0 end as so_tien_chietkhau3,

Case 
------------An Khang
  when phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_20ty and doanhsochuavat_all_congdon - doanhsochuavat_all <= moc_20ty 
                              then (doanhsochuavat_all_congdon - moc_20ty ) * ty_le_chietkhau_vuot3_dukien
  when phanloai_kh ='An Khang' and doanhsochuavat_all_congdon > moc_20ty and doanhsochuavat_all_congdon - doanhsochuavat_all > moc_20ty 
                              then doanhsochuavat_all * ty_le_chietkhau_vuot3_dukien 
else 0 end as so_tien_chietkhau3_dukien,
'' as ma_crs,
'' as ten_crs,
b.tencvbh as ten_crm,
b.rsmid as ma_ncxm,
b.tenquanlyvung as ten_ncxm

from 
tyle a 
-- where phanloai_kh ='An Khang'
LEFT JOIN `staging.d_users` b on a.ma_crm = b.manv
order by phanloai_kh

;