CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_data_tracking_chi_phi_hco(p_manv1 STRING, p_version1 STRING)
BEGIN 
 
--  TRUNCATE TABLE staging_temp.f_sales_crs_temp;


 INSERT INTO `warehouse.f_data_tracking_chi_phi_hco_by_users_realtime`

(   

-- Create or replace table warehouse.f_data_tracking_chi_phi_hco_by_users_realtime as

with 
master_khachhang as 
(
select 
  pubcustid, 
  pubcustname,
  statedescr,
  shortterritorydescr 
from `staging.d_master_khachhang`
where active ='Active' and channel in ('CLC','INS','PCL')
qualify row_number() over (partition by pubcustid order by  crtd_datetime desc) = 1
)
,
data_hco as (
select
  uuid,
  'SMN' as datatype,
  a.ma_kh_chung,
  a.manv,
  a.chon_khoa_phong_smn as khoa_phong,
  a.chon_thang_smn as thang,
  a.gia_tri_smn as gia_tri,
  Case when a.status ='H' then 'Chưa duyệt'
       when a.status ='C' then 'Đã duyệt'
       when a.status ='R' then 'Từ chối'
  else null end as crm_duyet,
  'Chưa duyệt'as  ncxm_duyet,
  a.approved_time,
  a.inserted,
  a.current_date as ngay_nhap,
  a.p_manv,
  a.p_version
from `staging.f_data_tracking_chi_phi_hco_by_users` a
where a.p_manv = p_manv1 and a.p_version = p_version1
UNION ALL 
select
  uuid,
  'SMS' as datatype,
  a.ma_kh_chung,
  a.manv,
  null as khoa_phong,
  a.chon_thang_sms as thang,
  a.gia_tri_sms as gia_tri,
  Case when a.status ='H' then 'Chưa duyệt'
       when a.status ='C' then 'Đã duyệt'
       when a.status ='R' then 'Từ chối'
  else null end as crm_duyet,
  'Chưa duyệt'as  ncxm_duyet,
  a.approved_time,
  a.inserted,
  a.current_date as ngay_nhap,
    a.p_manv,
  a.p_version
from `staging.f_data_tracking_chi_phi_hco_by_users` a
where a.p_manv = p_manv1 and a.p_version = p_version1
UNION ALL 
select
  uuid,
  'TTK' as datatype,
  a.ma_kh_chung,
  a.manv,
  null as  khoa_phong,
  a.chon_thang_ttk as thang,
  a.gia_tri_ttk as gia_tri,
  Case when a.status ='H' then 'Chưa duyệt'
       when a.status ='C' then 'Đã duyệt'
       when a.status ='R' then 'Từ chối'
  else null end as crm_duyet,
  'Chưa duyệt'as  ncxm_duyet,
  a.approved_time,
  a.inserted,
  a.current_date as ngay_nhap,
  a.p_manv,
  a.p_version

from `staging.f_data_tracking_chi_phi_hco_by_users` a
where a.p_manv = p_manv1 and a.p_version = p_version1
)

select 
a.uuid,
a.datatype,
a.ma_kh_chung,
a.manv,
a.khoa_phong,
a.thang,
a.gia_tri,
a.crm_duyet,
case
when a.crm_duyet = 'Từ chối' then 'Từ chối'
when d.cxm_duyet is not null then d.cxm_duyet
else 'Chưa duyệt' end as ncxm_duyet,
a.approved_time,
a.inserted,
a.ngay_nhap,
a.p_manv,
a.p_version,
b.pubcustname,
b.statedescr,
b.shortterritorydescr,
c.tencvbh,
c.tenquanlytt,
c.tenquanlyvung,
0 as gia_tri_thuc_te
from data_hco a 
LEFT JOIN master_khachhang b on a.ma_kh_chung = b.pubcustid
LEFT JOIN `staging.d_users` c on a.manv =c.manv
LEFT JOIN staging.d_manual_duyet_cxm_tracking_chi_phi d on a.uuid = d.id
where ifnull(cast (gia_tri as int), 0) > 0 and a.manv != 'AM0000'
);


END;