CREATE VIEW `spatial-vision-343005.warehouse.view_f_in_congno_xacnhan`
AS with 
khuvuc_mds as ( 
SELECT ma_nv, khu_vuc
FROM `spatial-vision-343005.staging.d_mds_location`
qualify row_number() over (partition by ma_nv order by thang desc ) = 1
),

ngay_den_han as  
(
select  
  branchid,
  custid,
  ordnbr,
  InvcNbr,
  case when a.paymentsform = 'A' then	'Chuyển Khoản'
      when a.paymentsform = 'B' then 'Tiền Mặt'
      when a.paymentsform = 'C' then 'Tiền Mặt/Chuyển Khoản'
      when a.paymentsform = 'D'	then 'Ghi Nợ'
      when a.paymentsform = 'E'	then 'TM/CK/CTH'
      when a.paymentsform = 'F' then	'Cấn Trừ Nợ' 
    else a.paymentsform end as hinhthucthanhtoan,
terms,
min(dateoforder) as dateoforder,
min(duedate) as duedate,
sum(so_du_chungtu) as so_du_chungtu

from `spatial-vision-343005.staging_temp.d_rawdata_debt` a
where invcnbr is not null 
group by 1,2,3,4,5,6
)
,
nv_gh_thuc as (
  select branchid,ordernbr,slsperid from `staging.sync_dms_dv` 
qualify row_number() over (partition by branchid,ordernbr order by sequence desc,crtd_datetime desc) = 1

),
mapping_all as  (
SELECT
  a.thang,
  a.ma_ge_khnb,
  a.ma_csm,
  a.dtcn_noi_bo as dtcn_noi_bo_ori,
  a.ma_ge_vat,
  a.ten_khach_hang_thue as ten_khach_hang_thue_ori,
  b.statedescr,
  b.shortterritorydescr,
  b.channel,
  b.shoptype,
  b.hcotypeid,
  b.branchid,
  a.so_don_hang,
  a.so_hd,
  concat(ifnull(a.so_don_hang,''),'-',a.so_hd) as ma_dh_hd,
  date(a.ngay_hoa_don) as ngay_hoa_don,
  Case when a.du_dau_ky_no is null or a.du_dau_ky_no = 0 then ifnull(du_cuoi_ky_no,0) + ifnull(phat_sinh_trong_ky_co,0) else du_dau_ky_no end as du_dau_ky_no,
  -- a.du_dau_ky_co,
  a.phat_sinh_trong_ky_no,
  nullif(a.phat_sinh_trong_ky_co,0) as phat_sinh_trong_ky_co,
  a.du_cuoi_ky_no as du_cuoi_ky_no,
  a.du_cuoi_ky_co as du_cuoi_ky_co,
  a.pnql,
  a.kenh_phu,
  c.descr as terms,
  d.hinhthucthanhtoan,
  c.dueintnv as thoi_han_no,
  d.duedate as ngay_den_han,
  ifnull(h.slsperid,f.slsperid) as ma_mds,
  g.tencvbh as ten_mds,
  k.khu_vuc,
  Case when g.tenquanlyvung ='Lương Trịnh Thắng' then 'MDS' else 'SDS' end as role_gh


FROM
  `spatial-vision-343005.staging.f_cong_no_kt` a 
  LEFT JOIN `staging.d_master_khachhang` b on a.ma_csm = b.custid
  LEFT JOIN ngay_den_han d on d.custid = a.ma_csm and a.so_don_hang = d.ordnbr and a.so_hd = d.InvcNbr
  LEFT JOIN `staging.d_manual_terms_detail` c on d.terms = c.termsid
  LEFT JOIN `staging.sync_dms_ibd` e on e.branchid = d.branchid and e.ordernbr =d.ordnbr
  LEFT JOIN `staging.sync_dms_ib` f on f.batnbr =e.batnbr and f.branchid =e.branchid
  LEFT JOIN nv_gh_thuc h on h.branchid = d.branchid and h.ordernbr = d.ordnbr
  LEFT JOIN `staging.d_users` g on g.manv =ifnull(h.slsperid,f.slsperid)
  LEFT JOIN khuvuc_mds k on k.ma_nv = ifnull(h.slsperid,f.slsperid)
  where du_cuoi_ky_no > 0
  AND
  (
    case
    when d.hinhthucthanhtoan in ('Tiền Mặt') then true
    when d.hinhthucthanhtoan in ('Tiền Mặt/Chuyển Khoản')
      AND c.descr IN (
          'Thu tiền ngay có VP PN', 
          'Thu tiền ngay không có VP PN'
      ) 
      then true
    when c.descr IN (
          'Thu tiền ngay có VP PN', 
          'Thu tiền ngay không có VP PN'
      ) then true
    else false end
  )
  and a.ma_csm not in ('N01101423','011157','011164') -- 15/7/24 Khách hàng này đã khởi kiện nên bên PBH chuyển hình thức thanh toán sang Tiền Mặt
),
page_ as (
select *,
row_number() over (partition by ma_mds,thang order by ngay_hoa_don ) as stt

from mapping_all  --and ma_mds ='MR3068'
)
select *,
Case when stt <=20 then 1 
     when stt > 20 then div(stt - 20 ,30) + 2 
  else null end as so_trang
from page_
where channel != 'OTH_LAB';