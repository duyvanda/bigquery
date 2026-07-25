CREATE VIEW `spatial-vision-343005.warehouse.view_f_mua_hang_sp_online_detail_hang_huy`
AS with 

sales as (
  select sodondathang,macongtycn,manv from `staging.f_sales` where masanpham ='T302203003' and ngaychungtu >='2024-10-10' and makenhkh ='TP' group by all
),

phanphoi_hientai as (
  select 
  a.custid as makhdms, 
  a.ordernbr,
  ifnull(a.origordernbr,c.origordernbr) as origordernbr,
  a.crtd_datetime,
  date(date_trunc(a.crtd_datetime,month)) as thang,
  Case 
      when a.status = 'X' then 'Đóng đơn hàng tạm' 
      when a.status = 'V' then 'Hủy hóa đơn'
      when a.status = 'E' then 'Đóng đơn hàng'
      when a.ordertype in ('CO','IR','LO') then 'Đơn hàng trả'
  else null end as status,
  Case 
      when l.col.phan_loai_mcp = 'Rural' 
            or ifnull(d.manv,b.slsperid) = 'TMDT_001' then l.col.ma_nvbh
      when ifnull(d.manv,b.slsperid) in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
        "MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608") then l.col.ma_nvbh
  else ifnull(d.manv,b.slsperid) end as manv,
  sum(Case when a.ordertype in ('CO','IR','LO') then -1*b.lineqty else b.lineqty end) as soluong,
  sum(
    case 
        when a.ordertype in ('CO','IR','LO') and aftervatamount <> 0 then -1 * aftervatamount
        when aftervatamount = 0 and a.ordertype in ('CO','IR','LO') then - 1 * b.lineqty * slsprice
        when aftervatamount = 0 and a.ordertype not in ('CO','IR','LO') then lineqty * slsprice else aftervatamount end
    ) as ds,
  -- min(a.crtd_datetime) as crtd_datetime_min,
    from `staging.sync_dms_pda_so` a
  LEFT JOIN `staging.sync_dms_pda_sod` b on a.ordernbr =b.ordernbr and a.branchid =b.branchid
  LEFT JOIN `staging.sync_dms_so` c on a.oriordernbrup =c.ordernbr and a.branchid =c.branchid and a.ordertype in ('CO','IR','LO')
  LEFT JOIN `warehouse.f_mapping_crs_bytime` l on l.custid = a.custid and date(l.thang) = date(date_trunc(a.crtd_datetime,month))
  LEFT JOIN sales d on d.sodondathang = a.ordernbr and d.macongtycn = a.branchid
  where 
  a.ordertype in ('CO','IR','LO') and b.freeitem is false and b.invtid ='T302203003' and date(a.crtd_datetime) >='2025-02-03' and a.crtd_datetime <'2025-03-31 16:00:00' and a.status not in ('E','V','X')
  group by all
),

mapping_phanphoi as (
select 
b.*,
d.tencvbh,
d.supid as ma_crm,
d.tenquanlytt as ten_crm,
d.rsmid as ma_ncrm,
d.tenquanlyvung as ten_ncrm,
c.custname,
c.channel,
c.shoptype,
c.hcoid,
c.hcotypeid,
c.classid,
c.statedescr,
c.shortterritorydescr,
d.position,
Case 
     when d.tenquanlytt ='Trần Thị Bích Tiền' then 6
     when d.tenquanlytt ='Nguyễn Thanh Tài' then 9
     when d.tenquanlytt ='Lê Đức Châu' then 9
     when d.tenquanlytt ='Nguyễn Văn Án' then 10
     when d.tenquanlytt ='Nguyễn Anh Dũng' then 8
     when d.tenquanlytt ='Trần Quang Luân' then 8.5
     when d.tenquanlytt ='Huỳnh Văn Huy' then 10
     when d.tenquanlytt ='Lương Đức Tiến' then 11
     when d.tenquanlytt ='Lê Duy Chung' then 12.5
else null end as he_so_nhom,
Case 
     when d.tenquanlytt in ('Lê Duy Chung','Lương Đức Tiến','Huỳnh Văn Huy') then 'MB'
     when d.tenquanlytt in ('Nguyễn Văn Án','Nguyễn Anh Dũng','Trần Quang Luân') then 'MT'
else 'MN' end as khu_vuc,

FROM phanphoi_hientai b 
-- LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = b.makhdms
LEFT JOIN `staging.d_master_khachhang` c on b.makhdms =c.custid
LEFT JOIN `staging.d_users_bytime` d on  b.manv  = d.manv and b.thang = date(d.thang)
where d.tenquanlyvung ='Nguyễn Hoàng Viển'
)

select * from mapping_phanphoi;