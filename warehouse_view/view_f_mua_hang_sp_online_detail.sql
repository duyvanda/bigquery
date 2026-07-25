CREATE VIEW `spatial-vision-343005.warehouse.view_f_mua_hang_sp_online_detail`
AS with 

sales as (
  select 
  makhdms,
  sodondathang as ordernbr,
  ngaychungtu as crtd_datetime,
  date(date_trunc(a.ngaychungtu,month)) as thang,
  macongtycn,
  manv,
  tencvbh,
  a.ma_crm,
  a.tenquanlytt as ten_crm,
  a.ma_ncxm as ma_ncrm,
  a.tenquanlyvung as ten_ncrm,
  tenkhachhang as custname,
  makenhkh_cu as channel,
  makenhphu_cu as shoptype,
  mahco_cu as hcoid,
  maphanloaihco_cu as  hcotypeid,
  a.phan_hang_c1_2024 as classid,
  a.statedescr,
  a.territorydescr as shortterritorydescr,
  sum(soluong) as soluong,
  sum(doanhsochuavat) as ds,
  max(a.inserted_at) as inserted_at
  from `warehouse.f_raw_data_sales_yoy` a
  where masanpham ='T302203003' and ngaychungtu >='2025-03-01' and ngaychungtu <'2025-04-01' and makenhkh_cu ='TP'  group by all
),

-- phanphoi_hientai as (
--   select 
--   a.custid as makhdms, 
--   a.ordernbr,
--   a.crtd_datetime,
--   date(date_trunc(a.crtd_datetime,month)) as thang,
--   Case 
--       when l.col.phan_loai_mcp = 'Rural' 
--             or ifnull(c.manv,b.slsperid) = 'TMDT_001' then l.col.ma_nvbh
--       when ifnull(c.manv,b.slsperid) in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
--         "MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608") then l.col.ma_nvbh
--   else ifnull(c.manv,b.slsperid) end as manv,
--   sum(Case when a.ordertype in ('CO','IR','LO') then -1*b.lineqty else b.lineqty end) as soluong,
--   sum(
--     case 
--         when a.ordertype in ('CO','IR','LO') and aftervatamount <> 0 then -1 * aftervatamount
--         when aftervatamount = 0 and a.ordertype in ('CO','IR','LO') then - 1 * b.lineqty * slsprice
--         when aftervatamount = 0 and a.ordertype not in ('CO','IR','LO') then lineqty * slsprice else aftervatamount end
--     ) as ds,
--   max(a.inserted_at) as inserted_at,
--     from `staging.sync_dms_pda_so` a
--   LEFT JOIN `staging.sync_dms_pda_sod` b on a.ordernbr =b.ordernbr and a.branchid =b.branchid
--   LEFT JOIN `warehouse.f_mapping_crs_bytime` l on l.custid = a.custid and date(l.thang) = date(date_trunc(a.crtd_datetime,month))
--   LEFT JOIN sales c on c.sodondathang = a.ordernbr and c.macongtycn = a.branchid
--   where 
--    date(a.crtd_datetime) >='2025-02-03' and a.crtd_datetime <'2025-02-28 16:00:00'
--   and a.ordertype in ('IN','CO','IR','LO') 
--   and a.status not in ('E','V','X')
--   and b.freeitem is false and b.invtid ='T302203003'  --T303102009
--   and a.ordernbr not in (select origordernbr from `warehouse.view_f_mua_hang_sp_online_detail_hang_huy`  )
--   -- or (a.ordertype ='CO' and b.freeitem is false and b.invtid ='T3041008' and date(a.crtd_datetime) >='2024-10-01' and a.crtd_datetime <'2024-11-12' and a.status not in ('E','V','X')) 
--   group by all
-- -- having soluong >=5
-- ),

mapping_phanphoi as (
select 
a.*,
d.position,
Case 
     when a.ten_crm ='Trần Thị Bích Tiền' then 6
     when a.ten_crm ='Nguyễn Thanh Tài' then 9
     when a.ten_crm ='Lê Đức Châu' then 9
     when a.ten_crm ='Nguyễn Văn Án' then 10
     when a.ten_crm ='Nguyễn Anh Dũng' then 8
     when a.ten_crm ='Trần Quang Luân' then 8.5
     when a.ten_crm ='Huỳnh Văn Huy' then 10
     when a.ten_crm ='Lương Đức Tiến' then 11
     when a.ten_crm ='Lê Duy Chung' then 12.5
else null end as he_so_nhom,

Case 
     when a.ten_crm in ('Lê Duy Chung','Lương Đức Tiến','Huỳnh Văn Huy') then 'MB'
     when a.ten_crm in ('Nguyễn Văn Án','Nguyễn Anh Dũng','Trần Quang Luân') then 'MT'
else 'MN' end as khu_vuc,
sum(soluong) over (partition by a.manv) as soluong_tong

FROM sales a 
-- LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = b.makhdms
-- LEFT JOIN `staging.d_master_khachhang` c on b.makhdms =c.custid
LEFT JOIN `staging.d_users_bytime` d on  a.manv  = d.manv and a.thang = date(d.thang)
-- where d.tenquanlyvung ='Nguyễn Hoàng Viển'
)

select *,
if(soluong_tong >=200,5000,3000) as thuong_theo_chai,
if(soluong_tong >=200,soluong * 5000,soluong * 3000) as tien_thuong,
 from mapping_phanphoi;