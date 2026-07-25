CREATE PROCEDURE `spatial-vision-343005`.warehouse.api_khach_hang_chua_ps_dh_theo_crs(p_ma_crs STRING)
OPTIONS(
  strict_mode=false)
BEGIN
DECLARE set_ma_crs STRING DEFAULT 'None';
SET set_ma_crs = IF (p_ma_crs = '', set_ma_crs, p_ma_crs);

with
tuyen_dms_moinhat as 
(
with data_tuyen as (
SELECT a.custid,a.slsperid,a.crtd_datetime,
Case when routetype in ('B','D') then 1 else 2 end as routetype,
FROM `spatial-vision-343005.staging.sync_dms_srm`  a 

where delroutedet is false 

)

select custid,slsperid 
from data_tuyen
qualify row_number() over (partition by custid order by routetype asc,crtd_datetime desc) =1
),

tuyen_cvbh_hd_moinhat as 
(

select a.custid,a.slsperid
from `spatial-vision-343005.staging.d_get_contract_det`  a

where slsperid not in ('GH001','QUYNHPTA','MA001','MA002') 

),

mapping_mcp_hd as (
select *, date_trunc(current_date("+7"),month) as thang_hien_tai from tuyen_dms_moinhat
UNION distinct
select *, date_trunc(current_date("+7"),month) as thang_hien_tai from tuyen_cvbh_hd_moinhat
),

sales as 
(
select makhdms,max(date(ngaychungtu)) as ngay_dat_don_gan_nhat from `warehouse.f_raw_data_sales_yoy` 
-- where date(ngaychungtu) between date(date_trunc(current_date("+7"),month)) and current_date("+7")  
group by 1
)

select 
a.custid as ma_kh_dms,
c.custname as ten_kh,
a.slsperid as ma_crs,
d.tencvbh as ten_crs,
d.supid as ma_crm,
d.tenquanlytt as ten_crm,
a.thang_hien_tai,
b.ngay_dat_don_gan_nhat,
Case when a.thang_hien_tai =date(date_trunc(b.ngay_dat_don_gan_nhat,month)) then 'Y' else 'N' end is_check_mua_hang_trong_thang,
Case when a.thang_hien_tai =date(date_trunc(b.ngay_dat_don_gan_nhat,month)) then null else a.custid end so_khach_hang_chua_ps_dh,
date_diff(current_date("+7"),ifnull(b.ngay_dat_don_gan_nhat,date('2023-01-01')),day) as so_ngay_dat_don_gan_nhat

 from mapping_mcp_hd a
LEFT JOIN sales b on a.custid=b.makhdms 
LEFT JOIN `staging.d_master_khachhang` c on a.custid =c.custid
LEFT JOIN `staging.d_users` d on a.slsperid = d.manv
where c.active ='Active' 
and  contains_substr(concat(d.supid,a.slsperid ), p_ma_crs) 
order by slsperid,so_ngay_dat_don_gan_nhat desc

;


END;