CREATE VIEW `spatial-vision-343005.warehouse.view_f_listing_hcp`
AS with hop_dong_ins as 
(
SELECT 
    a.contractid, 
    b.contractnbr,
    b.contractmain,
    b.custid, 
    a.invtid,
    b.gentodate, 
    b.todate,
    a.genslsperid as slsperid, 
    c.supid AS macrm, 
    c.tenquanlytt
  FROM `spatial-vision-343005.staging.d_oricontractdet` a 
  INNER JOIN `spatial-vision-343005.staging.d_oricontract` b ON a.contractid = b.contractid
  LEFT JOIN `staging.d_users` c ON a.genslsperid = c.manv
  LEFT JOIN `staging.d_master_khachhang` d on d.custid =b.custid
  WHERE d.channel ='INS' and datetime(b.gentodate) >= current_datetime("+7")
  QUALIFY ROW_NUMBER() OVER (PARTITION BY custid,invtid ORDER BY ifnull(b.gentodate,b.todate) DESC) = 1

),

ds_kh_ins as (
select 
date(nam_thuc_hien,thang_thuc_hien,1) as thang,
ma_kh,
ma_sp
FROM `spatial-vision-343005.staging.d_listing_hcp` a
-- where a.kenh ='INS'
),

doanh_so as (
select ngaychungtu,makhdms,masanpham,sum(doanhsochuavat) as ds from `warehouse.f_sales_crs`
where ngaychungtu >='2024-04-01'
group by all having ds >0
)
,

so_luong_thang as 
(
  select date(thang) as thang,makhdms,masanpham,sum(soluong) as soluong from `warehouse.f_sales_crs`
where ngaychungtu >='2025-01-01'
group by all
),

mapping_check_kh_mua_sp as 

(
  select a.*,b.ngaychungtu from ds_kh_ins a 
  LEFT JOIN doanh_so b on a.ma_kh = b.makhdms and b.masanpham =a.ma_sp and date(a.thang) - interval 6 month < date(b.ngaychungtu) and date(b.ngaychungtu) < date(a.thang)
  where b.ngaychungtu is null
),
mapping_all as (
SELECT 
a.khu_vuc,
INITCAP(a.tinh) as  tinh,
a.manv,
INITCAP(a.ten_nv) ten_nv,
a.ma_ql,
INITCAP(a.ten_ql) ten_ql,
a.ma_kh,
a2.custname as ten_kh,
a.kenh,
a.ma_sp,
a1.descr1 as  ten_sp,
a.ke_hoach_nhap,
a.noi_dung_qui_dinh,
a.de_xuat_thuong,
a.ghi_chu,
a.nam_thuc_hien,
a.thang_thuc_hien,
ifnull(b.gentodate,b.todate) as gentodate,
b.contractnbr,
date(a.nam_thuc_hien,a.thang_thuc_hien,1) as thang,
Case when c.ma_sp is not null then 'Chưa' else 'Có' end as da_mua_trong_6thang,
ifnull(d.soluong,0) as soluong,
FROM `spatial-vision-343005.staging.d_listing_hcp` a
LEFT JOIN `staging.d_dms_master_invtid` a1 on a.ma_sp = a1.invtid
LEFT JOIN `staging.d_master_khachhang` a2 on a.ma_kh =a2.custid
LEFT JOIN hop_dong_ins b on a.kenh ='INS' and b.custid =a.ma_kh and a.ma_sp =b.invtid
LEFT JOIN mapping_check_kh_mua_sp c on c.ma_kh =a.ma_kh and a.ma_sp =c.ma_sp and date(a.nam_thuc_hien,a.thang_thuc_hien,1) = date(c.thang)
LEFT JOIN so_luong_thang d on d.makhdms =a.ma_kh and a.ma_sp =d.masanpham and date(a.nam_thuc_hien,a.thang_thuc_hien,1) = date(d.thang)
)

select *,
if(soluong>5 and da_mua_trong_6thang='Chưa','Đạt','Không đạt') as  ket_qua,
if(soluong>5 and da_mua_trong_6thang='Chưa',de_xuat_thuong,0) as  tien_thuong,
(select max(updated_at)  from `warehouse.f_sales_crs` where ngaychungtu >='2025-01-01') as inserted_at
from mapping_all;