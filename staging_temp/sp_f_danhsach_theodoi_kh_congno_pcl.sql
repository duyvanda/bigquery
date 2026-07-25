CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danhsach_theodoi_kh_congno_pcl()
BEGIN 
  TRUNCATE TABLE staging_temp.f_danhsach_theodoi_kh_congno_pcl_temp;


 INSERT INTO staging_temp.f_danhsach_theodoi_kh_congno_pcl_temp(

-- CREATE OR REPLACE table staging_temp.f_danhsach_theodoi_kh_congno_pcl_temp
-- as

with 
leadtime as ( select distinct branchid,ordernbr,custid,ngaygiaohang,deliveryunit,trangthaidon from `warehouse.f_leadtime_new_detail1` where ngaytaodon >='2023-02-01'),

congno as (select 
branchid,
ordernbr,
custid,
refcustid,
InvcNbr,
orderdate,
sotien_nogoc,
sotien_da_thanhtoan,
duedate,
paymentsform,
day_terms,
terms,
doctype,
docdesc,
channel,
tinh,
khuvuc,
custname,
thongtinthanhtoan,
thoigiangoi,
is_diadiem,
so_du_dh,
mahd_so,
thoi_diem_no_vang,
thoi_diem_no_do,
thoi_diem_no_den,
thang_chungtu,
thang_thu,
thoigian_no,
thoigian_noqh,
thoigian_noxau,
no_xanh,
no_vang,
no_do,
no_den,
no_xau,
vungno_kh,
ngay_dh_xa_nhat,
max_thoigian_nqh,
min_ngaydatdon,
tiennocongty,
phanloai_no,
kenhphu,
ngaydatdon,
ngaychungtu,
duyet_donhang,
canhbao_duyetdon,
phap_nhan,
manv,
tencvbh,
macrm,
tenquanlytt,
hcoid,
hcotypeid,
updated_at,

 from `warehouse.f_congno_hcp_crm` where --custid in (select makh from `staging.d_manual_ds_kh_theodoi_pcl`) and
 ngaychungtu <= date_trunc(current_datetime("+7"),month) or ngaychungtu is null),

a as (
select a.*except(sotien_nogoc,custid,custname,tinh,khuvuc,macrm,tencvbh,terms),

Case when a.terms ='Gối 1 Đơn Hàng (trong 30 ngày)' then 'Gối 1 Đơn Hàng (cuối tháng)'
else a.terms end as terms,
ifnull(b.macrm,a.macrm) as macrm,
c.tencvbh,
b.makh as custid,
d.custname,
d.statedescr as tinh,
d.territorydescr as khuvuc,
ifnull(tiennocongty,0) as sotien_nogoc ,
e.ngaygiaohang,
e.deliveryunit,
e.trangthaidon,
case when date_trunc(ngaychungtu,month) = date_trunc(current_datetime("+7"),month)
then 'Y' else 'N' end as is_current_month
from `staging.d_manual_ds_kh_theodoi_pcl` b  
LEFT JOIN congno a  on a.custid =b.makh
LEFT JOIN `staging.d_master_khachhang` d on d.custid =b.makh
LEFT JOIN `staging.d_users` c on c.manv =ifnull(b.macrm,a.macrm)
LEFT JOIN leadtime e on e.custid =a.custid and e.branchid =a.branchid and e.ordernbr =a.ordernbr
-- where --custid in (select makh from `staging.d_manual_ds_kh_theodoi_pcl`) and
--  ngaychungtu < date_trunc(current_datetime("+7"),month) or ngaychungtu is null
)

select * from a  

 );

Create or replace table `warehouse.f_danhsach_theodoi_kh_congno_pcl`

copy `staging_temp.f_danhsach_theodoi_kh_congno_pcl_temp`;


End;