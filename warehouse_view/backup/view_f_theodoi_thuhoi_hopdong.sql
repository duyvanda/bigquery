CREATE VIEW `spatial-vision-343005.warehouse.view_f_theodoi_thuhoi_hopdong`
AS with

----------------CLC,PCL theo file chị Tú---------------------
hop_dong_clc_pcl as 

(
  with 

cong_no_clc_pcl as 
(
  select a.CustId,a.dateoforder,sum(so_du_chungtu) as so_du_chungtu
   from `staging_temp.d_rawdata_debt` a 
JOIN `staging.d_master_khachhang` c on a.custid = c.custid --and c.channel in('PCL','CLC')
group by 1,2
)
,

hop_dong_clc_pcl as (
SELECT 
a.phap_nhan,
a.ma_kh as custid,
a.ten_kh,
a.so_hop_dong,
date(a.ngay_hl_theo_hop_dong) as ngay_hieu_luc_theo_hd,
Case when a.ngay_het_hl_theo_hop_dong is null then current_date("+7") else date(a.ngay_het_hl_theo_hop_dong) end as ngay_het_hieu_luc_theo_hd ,
date(a.ngay_gia_han_hop_dong) as ngay_gia_han_hd,
a.hl_ket_thuc_hop_dong_sau_gia_han_neu_co,
a.ngay_goi,
a.hinh_thuc_goi,
a.nguoi_nhan,
Case when nam_thu_hoi is not null and a.ngay_thu_hoi is null then 1 else a.ngay_thu_hoi end as ngay_thu_hoi,
a.nam_thu_hoi,
a.thang_thu_hoi,
a.thoi_han_no,
a.ghi_chu,
a.ma_cvbh,
a.ten_cvbh,
a.link_file_scan_hop_dong_da_thu_hoi,

FROM `spatial-vision-343005.staging.d_manual_clc_thu_hoi_hop_dong`  a 
LEFT JOIN `staging.d_master_khachhang` b on a.ma_kh = b.custid
-- where b.channel in ('PCL','CLC')
qualify row_number() over (partition by ma_kh,so_hop_dong,ngay_hl_theo_hop_dong,ngay_het_hl_theo_hop_dong order by ngay_thu_hoi desc) = 1
)
,
don_hang_dau_tien_clc_pcl as
(
  select c.custid,c.so_hop_dong,c.ngay_hieu_luc_theo_hd,c.ngay_het_hieu_luc_theo_hd, min(ngaychungtu) as min_ngaychungtu 
  from hop_dong_clc_pcl c
  JOIN  `staging.f_sales` a   on a.makhdms = c.custid and date(a.ngaychungtu) between c.ngay_hieu_luc_theo_hd and c.ngay_het_hieu_luc_theo_hd
  -- where a.makenhkh ='INS'
  group by 1,2,3,4
)
,

mapping_cong_no_clc_pcl as 
(
select a.* ,sum(b.so_du_chungtu) as so_du_chungtu
from don_hang_dau_tien_clc_pcl a 
JOIN cong_no_clc_pcl b on b.custid = a.custid and date(b.dateoforder) between a.ngay_hieu_luc_theo_hd and a.ngay_het_hieu_luc_theo_hd
group by 1,2,3,4,5
)
,
mapping_all as (
select 
a.phap_nhan,
b.branchid,
b.channel,
b.shoptype,
b.pubcustname,
a.custid,
b.custname,
-- a.ten_kh,
b.statedescr,
b.shortterritorydescr,
b.terms,
cast(null as string) as formname,
a.so_hop_dong,
cast(null as string) as so_hop_dong_chinh,
null as so_hop_dong_bi,
a.ngay_hieu_luc_theo_hd as ngaytao_hd,
a.ngay_hieu_luc_theo_hd,
a.ngay_het_hieu_luc_theo_hd,
a.ngay_gia_han_hd,
date(ifnull(a.ngay_gia_han_hd,a.ngay_het_hieu_luc_theo_hd)) as hieu_luc_hd,
a.link_file_scan_hop_dong_da_thu_hoi as ma_phutrach_chungtu,
hr.hovatenfullname  as phutrach_chungtu,
Case when a.ngay_het_hieu_luc_theo_hd >= current_date("+7") then 1
else 0 end as active,
0 as thanh_tien_ky_hd,
timestamp(current_datetime("+7")) as inserted_at,
a.ngay_goi,
a.hinh_thuc_goi,
a.nguoi_nhan,
date(a.nam_thu_hoi,a.thang_thu_hoi, a.ngay_thu_hoi) as ngay_thu_hoi,
a.nam_thu_hoi,
a.thang_thu_hoi,
c.so_du_chungtu as congno,
Case when c.so_du_chungtu > 0 then 'Còn nợ' else 'Hết nợ' end as hien_trang_no,
Case when a.ngay_thu_hoi is not null or a.thang_thu_hoi is not null or a.nam_thu_hoi  is not null then 'ĐÃ THU'
    ELSE 'CHƯA THU'
end as thu_hoi_hd, 
cast(null as string) as link_file_scan_hop_dong_da_thu_hoi,
Case when date(a.ngay_hieu_luc_theo_hd) < date('2023-01-01') then null else c.min_ngaychungtu end as ngay_dh_dau_tien,
Case when date(a.ngay_hieu_luc_theo_hd) < date('2023-01-01') then null else c.min_ngaychungtu end as ngay_dh_dau_tien_test_ins,

Case 
  when date(a.ngay_hieu_luc_theo_hd) < date('2023-01-01') then null
  when b.shoptype in ('INS1','CLC1') then date(c.min_ngaychungtu) + interval 90 day 
  else date(c.min_ngaychungtu) + interval 60 day
end as ngay_den_han_thu_hoi_hd,

Case 
  when date(a.ngay_hieu_luc_theo_hd) < date('2023-01-01') then null
  when b.shoptype in ('INS1','CLC1') then date(c.min_ngaychungtu) + interval 90 day 
  else date(c.min_ngaychungtu) + interval 60 day
end as ngay_den_han_thu_hoi_hd_test_ins,

b.custidinvoice,
b.custnameinvoice,
Case 
    when d.tenquanlytt like '%Hữu Toàn%' then 'MR1579'
    when d.tenquanlytt is null then 'MR0047' else d.supid end as ma_crm,
Case 
  when d.tenquanlytt is null then 'Phạm Thị Cẩm Tú' 
  when d.tenquanlytt like '%Hữu Toàn%' then 'Nguyễn Toàn'
  else d.tenquanlytt end as tenquanlytt,
Case 
     when a.ma_cvbh is null then 'MR2525' ELSE a.ma_cvbh end as ma_crs,
Case        
      when a.ten_cvbh is null then 'Đào Thị Thúy An' else a.ten_cvbh end as ten_crs,
cast (null as string) as cankhong_thu_hoi_hd

from hop_dong_clc_pcl a
LEFT JOIN `staging.d_master_khachhang` b on a.custid =b.custid 
LEFT JOIN mapping_cong_no_clc_pcl c on a.custid =c.custid and a.so_hop_dong = c.so_hop_dong and a.ngay_hieu_luc_theo_hd=c.ngay_hieu_luc_theo_hd and a.ngay_het_hieu_luc_theo_hd = c.ngay_het_hieu_luc_theo_hd
LEFT JOIN `staging.d_users` d on a.ma_cvbh = d.manv
LEFT JOIN `staging.d_hr_dsns` hr on hr.msnvcsmmoi = a.link_file_scan_hop_dong_da_thu_hoi
)

select 
a.*,
Case 
  when date(ngay_hieu_luc_theo_hd) >= date('2023-01-01') and current_date("+7") >= date(ngay_den_han_thu_hoi_hd) then 'ĐẾN HẠN'
  when date(ngay_hieu_luc_theo_hd) >= date('2023-01-01') and current_date("+7") < date(ngay_den_han_thu_hoi_hd) then 'CHƯA ĐẾN HẠN'
  when date(ngay_hieu_luc_theo_hd) >= date('2023-01-01') and ngay_dh_dau_tien is null then 'CHƯA ĐẾN HẠN'
  when date(ngay_hieu_luc_theo_hd) < date('2023-01-01') then 'ĐẾN HẠN'
  else null
end as den_han_thu_hoi_hd,

Case 
  when date(ngay_hieu_luc_theo_hd) >= date('2023-01-01') and current_date("+7") >= date(ngay_den_han_thu_hoi_hd) then 'ĐẾN HẠN'
  when date(ngay_hieu_luc_theo_hd) >= date('2023-01-01') and current_date("+7") < date(ngay_den_han_thu_hoi_hd) then 'CHƯA ĐẾN HẠN'
  when date(ngay_hieu_luc_theo_hd) >= date('2023-01-01') and ngay_dh_dau_tien is null then 'CHƯA ĐẾN HẠN'

  when date(ngay_hieu_luc_theo_hd) < date('2023-01-01') then 'ĐẾN HẠN'
  else null
end as den_han_thu_hoi_hd_test_ins,

from mapping_all a 

)
,
----------------------------hợp đồng INS theo DMS---------------------

crs_phutrach_hd as 

(
  select contractid,genslsperid from `staging.d_oricontractdet`
qualify row_number() over (partition by contractid order by genlupd_datetime desc) =1

)
,
-- thanhtien_hd as 

-- (
--   select 
--     custid,
--     contractid,
--     sum(thanhtien_hopdong) as thanhtien_hopdong,
--     max(timestamp(current_datetime("+7"))) as inserted_at
--     from `warehouse.f_danhmuchopdong` group by 1,2
-- ),

don_hang_dau_tien as 
(
  select b.contractid,b.custid,min(ngaychungtu) as min_ngaychungtu 
  from `staging.f_sales` a 
  JOIN `staging.sync_dms_so` b on a.mahd = b.ordernbr and a.macongtycn = b.branchid 
  group by 1,2
)
,

cong_no_theo_hd as 
(
  select a.CustId,b.contractid,sum(so_du_chungtu) as so_du_chungtu 
  from `staging_temp.d_rawdata_debt` a 
LEFT JOIN `staging.sync_dms_so` b on a.branchid = b.branchid and a.mahd_so = b.ordernbr
group by 1,2
)
,

ngay_thu_hoi_ins as 
(
  select * from `spatial-vision-343005.staging.d_manual_ins_thu_hoi_hop_dong` 
  qualify row_number() over (partition by ma_kh,so_hop_dong order by ngay_thu_hoi desc) = 1
)
,

danh_muc_hd_ins as (
select
  case
    when branchid in( 'NAN012','KHA014','HYN017','HNI010','HCM001', 'DNI015','DNG013', 'CTO016') then 'MERAP'
    when branchid = 'PHA NAM' then 'PHA NAM'
    when branchid = 'MERAP' then 'MERAP'
  ELSE 'PHA NAM'
  END as phap_nhan,
  branchid,
  channel,
  shoptype,
  pubcustname,
  custid,
  custname,
  statedescr,
  shortterritorydescr,
  terms,
  formname,
  contractnbr as so_hop_dong,
  contractmain as so_hop_dong_chinh,
  a.contractid as so_hop_dong_bi,
  date(ngaytao_hd) as ngaytao_hd,
  date(signeddate) as ngay_hieu_luc_theo_hd,
  date(todate) as ngay_het_hieu_luc_theo_hd,
  date(gentodate) as ngay_gia_han_hd,
  date(ifnull(gentodate,todate)) as hieu_luc_hd,
  ma_phutrach_chungtu,
  phutrach_chungtu,
  active,
  sum(thanhtien_hopdong) as thanh_tien_ky_hd,
  max(timestamp(current_datetime("+7"))) as inserted_at
 from `warehouse.f_danhmuchopdong` a 

where  branchid not in ('PHA NAM','MERAP')
and a.channel ='INS'
-- and total_qty_le <> 0
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22
),

mapping_ngay_den_han_ins as (
select 
a.*,

cast(d.ngay_goi as string)as ngay_goi,
d.hinh_thuc_goi as hinh_thuc_goi,
d.nguoi_nhan as nguoi_nhan,
date(d.ngay_thu_hoi)  as ngay_thu_hoi,
extract(year from d.ngay_thu_hoi)as nam_thu_hoi,
extract(month from d.ngay_thu_hoi) as thang_thu_hoi,

c.so_du_chungtu as congno,
Case when c.so_du_chungtu > 0 then 'Còn nợ' else 'Hết nợ' end as hien_trang_no,
Case when date(d.ngay_thu_hoi)  is not null then 'ĐÃ THU'
    ELSE 'CHƯA THU'
end as thu_hoi_hd, 
cast (null as string) as link_file_scan_hop_dong_da_thu_hoi,

-- Case when date(ngay_hieu_luc_theo_hd) < date('2023-12-01') then null else b.min_ngaychungtu end as ngay_dh_dau_tien,
b.min_ngaychungtu  as ngay_dh_dau_tien,

Case when date(ngay_hieu_luc_theo_hd) < date('2023-12-01') then b.min_ngaychungtu else b.min_ngaychungtu end as ngay_dh_dau_tien_test_ins,

Case
  when e.statedescr in ('Ninh Thuận','Bình Phước') and date(ngay_hieu_luc_theo_hd) >= date('2023-12-01')  then date('2024-06-01')
  
  when a.shoptype in ('INS1','CLC1') and date(ngay_hieu_luc_theo_hd) >= date('2023-12-01')  then date(b.min_ngaychungtu) + interval 90 day 
  when a.shoptype not in ('INS1','CLC1') and date(ngay_hieu_luc_theo_hd) >= date('2023-12-01') then date(b.min_ngaychungtu) + interval 60 day
  when b.min_ngaychungtu is null then null
  when a.shoptype in ('INS1','CLC1') and date(ngay_hieu_luc_theo_hd) < date('2023-12-01') --and extract( year from date(b.min_ngaychungtu)) =2024
          and (date(b.min_ngaychungtu) + interval 90 day) > '2024-07-01'
          then date(b.min_ngaychungtu) + interval 90 day 
  when a.shoptype not in ('INS1','CLC1') and date(ngay_hieu_luc_theo_hd) < date('2023-12-01') --and extract( year from date(b.min_ngaychungtu)) =2024
          and (date(b.min_ngaychungtu) + interval 60 day) >'2024-07-01'
          then date(b.min_ngaychungtu) + interval 60 day
  when date(ngay_hieu_luc_theo_hd) < date('2023-12-01') then date('2024-07-01')
  else null
end as ngay_den_han_thu_hoi_hd,

Case
  -- when e.statedescr in ('Ninh Thuận','Bình Phước') and date(ngay_hieu_luc_theo_hd) < date('2023-12-01') then date('2024-06-01')
  when date(ngay_hieu_luc_theo_hd) >= date('2023-12-01') or b.min_ngaychungtu is null then null
  when a.shoptype in ('INS1','CLC1') and date(ngay_hieu_luc_theo_hd) < date('2023-12-01') --and extract( year from date(b.min_ngaychungtu)) =2024
          and (date(b.min_ngaychungtu) + interval 90 day) > '2024-07-01'
          then date(b.min_ngaychungtu) + interval 90 day 
  when a.shoptype not in ('INS1','CLC1') and date(ngay_hieu_luc_theo_hd) < date('2023-12-01') --and extract( year from date(b.min_ngaychungtu)) =2024
          and (date(b.min_ngaychungtu) + interval 60 day) >'2024-07-01'
          then date(b.min_ngaychungtu) + interval 60 day
  else date('2024-07-01')
end as ngay_den_han_thu_hoi_hd_test_ins,

e.custidinvoice,
e.custnameinvoice,
Case when g.tenquanlytt like '%Hữu Toàn%' then 'MR1579' else g.supid end as ma_crm,
Case when g.tenquanlytt like '%Hữu Toàn%' then 'Nguyễn Toàn' else g.tenquanlytt end as tenquanlytt,
ifnull(d.link_file_scan_hop_dong_da_thu_hoi,f.genslsperid) as ma_crs,
g.tencvbh as ten_crs,
d.cankhong_thu_hoi_hd

from danh_muc_hd_ins a
LEFT JOIN don_hang_dau_tien b on a.custid = b.custid and a.so_hop_dong_bi =cast(b.contractid as int64) and a.channel  in ('INS')
-- LEFT JOIN don_hang_dau_tien_clc b1 on a.custid = b1.custid and a.so_hop_dong_bi =cast(b1.contractid as int64) and a.channel  in ('CLC')
LEFT JOIN cong_no_theo_hd c on a.custid = c.custid and a.so_hop_dong_bi =cast(c.contractid as int64)
LEFT JOIN ngay_thu_hoi_ins d on trim(upper(a.custid)) = trim(upper(d.ma_kh)) and trim(upper(a.so_hop_dong)) = trim(upper(d.so_hop_dong)) and a.channel in ('INS')
-- LEFT JOIN ngay_thu_hoi_clc d1 on trim(upper(a.custid)) = trim(upper(d1.ma_kh)) and trim(upper(a.so_hop_dong)) = trim(upper(d1.so_hop_dong)) and a.channel  in ('CLC')
LEFT JOIN `staging.d_master_khachhang` e on a.custid =e.custid
LEFT JOIN crs_phutrach_hd f on a.so_hop_dong_bi = f.contractid
LEFT JOIN `staging.d_users` g on g.manv = ifnull(d.link_file_scan_hop_dong_da_thu_hoi,f.genslsperid)

),
union_all as (
select 
a.*,
Case
  when date(ngay_hieu_luc_theo_hd) >= date('2023-12-01') and  ngay_dh_dau_tien is null then 'CHƯA ĐẾN HẠN'
  when date(ngay_hieu_luc_theo_hd) >= date('2023-12-01') and current_date("+7") >= date(ngay_den_han_thu_hoi_hd) then 'ĐẾN HẠN'
  when date(ngay_hieu_luc_theo_hd) >= date('2023-12-01') and current_date("+7") < date(ngay_den_han_thu_hoi_hd) then 'CHƯA ĐẾN HẠN'
  
  -- when date(ngay_hieu_luc_theo_hd) < date('2023-12-01') then 'ĐẾN HẠN'

  when date(ngay_hieu_luc_theo_hd) < date('2023-12-01') and  ngay_dh_dau_tien is null then 'CHƯA ĐẾN HẠN'
  when date(ngay_hieu_luc_theo_hd) < date('2023-12-01') and current_date("+7") >= date(ngay_den_han_thu_hoi_hd)  then 'ĐẾN HẠN'
  when date(ngay_hieu_luc_theo_hd) < date('2023-12-01') and current_date("+7") < date(ngay_den_han_thu_hoi_hd) then 'CHƯA ĐẾN HẠN'

  else null
end as den_han_thu_hoi_hd,

Case
  -- when date(ngay_den_han_thu_hoi_hd_test_ins) = '2024-07-01'  then 'ĐẾN HẠN'
  when date(ngay_hieu_luc_theo_hd) <= date('2023-12-01') and  ngay_dh_dau_tien_test_ins is null then 'CHƯA ĐẾN HẠN'
  when date(ngay_hieu_luc_theo_hd) <= date('2023-12-01') and current_date("+7") >= date(ngay_den_han_thu_hoi_hd_test_ins)  then 'ĐẾN HẠN'
  when date(ngay_hieu_luc_theo_hd) <= date('2023-12-01') and current_date("+7") < date(ngay_den_han_thu_hoi_hd_test_ins) then 'CHƯA ĐẾN HẠN'

  -- when date(ngay_hieu_luc_theo_hd) < date('2023-12-01') then 'ĐẾN HẠN'
  else null
end as den_han_thu_hoi_hd_test_ins,


from mapping_ngay_den_han_ins a
UNION ALL
SELECT * from hop_dong_clc_pcl
),

result as (
select *,
Case 
  when cankhong_thu_hoi_hd is not null then 'Không cần thu hồi HĐ'
  when hieu_luc_hd < '2023-01-01' then 'Không cần thu hồi HĐ'

else 'Cần thu hồi HĐ' end as is_check_thu_hoi_hd,

Case 
  when active = 1 and hien_trang_no ='Còn nợ' then 'UT1'
  when active = 0 and hien_trang_no ='Còn nợ' then 'UT2'
  when active = 1 and hien_trang_no ='Hết nợ' then 'UT3a'
  when active = 0 and hien_trang_no ='Hết nợ' then 'UT3'

else null end as pl_capdo_thuhoi

from union_all
)
select 
a.*,
Case 
  when is_check_thu_hoi_hd = 'Cần thu hồi HĐ' 
  and den_han_thu_hoi_hd = 'ĐẾN HẠN' and thu_hoi_hd='CHƯA THU'
  and hien_trang_no ='Còn nợ'
  and ngay_hieu_luc_theo_hd >='2023-12-01' and channel ='INS' then 'Ngưng'

  when is_check_thu_hoi_hd = 'Cần thu hồi HĐ' 
  and den_han_thu_hoi_hd = 'ĐẾN HẠN' and thu_hoi_hd='CHƯA THU'
  and hien_trang_no ='Còn nợ'
  and ngay_hieu_luc_theo_hd >='2023-01-01' and channel <> 'INS' then 'Ngưng'
else null end as is_check_ngung_dh,

Case 
  when is_check_thu_hoi_hd = 'Cần thu hồi HĐ' 
  and den_han_thu_hoi_hd = 'CHƯA ĐẾN HẠN' and thu_hoi_hd='CHƯA THU'
  and hien_trang_no ='Còn nợ'
  and ngay_hieu_luc_theo_hd >='2023-12-01' and channel ='INS' then 'Ngưng'

  when is_check_thu_hoi_hd = 'Cần thu hồi HĐ' 
  and den_han_thu_hoi_hd = 'CHƯA ĐẾN HẠN' and thu_hoi_hd='CHƯA THU'
  and hien_trang_no ='Còn nợ'
  and ngay_hieu_luc_theo_hd >='2023-01-01' and channel <> 'INS' then 'Ngưng'
else null end as is_check_sap_ngung_dh,

Case 
  when is_check_thu_hoi_hd = 'Cần thu hồi HĐ' 
  -- and den_han_thu_hoi_hd_test_ins = 'ĐẾN HẠN' 
  and thu_hoi_hd ='CHƯA THU'
  and hien_trang_no ='Còn nợ'
  and ngay_hieu_luc_theo_hd <= '2023-12-01' and channel ='INS' then 'Ngưng'

  -- when is_check_thu_hoi_hd = 'Cần thu hồi HĐ' 
  -- and den_han_thu_hoi_hd = 'ĐẾN HẠN'
  --  and thu_hoi_hd='CHƯA THU'
  -- and hien_trang_no ='Còn nợ'
  -- and ngay_hieu_luc_theo_hd >='2023-01-01' and channel <> 'INS' then 'Ngưng'
else null end as is_check_ngung_dh_test_ins,

Case when ngay_hieu_luc_theo_hd >= date('2023-12-02') then 'HĐ PS 2024' else 'HD PS trước 2024' end as pl_hd_truoc_01122023,
'null' as manual_hop_dong_truoc_2024_a_kha

from result a;