CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_d_donhang_ecom()
BEGIN 
  TRUNCATE TABLE staging_temp.f_d_donhang_ecom_temp;


 INSERT INTO staging_temp.f_d_donhang_ecom_temp(

-- Create or replace table staging_temp.f_d_donhang_ecom_temp
-- partition by date(ngaychungtu)
-- as

with data_leadtime as 
(
  select distinct ordernbr, status_dv as trangthaigiaohang,ngaygiaohang from `warehouse.f_leadtime_new_detail1` 
  where ngaytaodon >='2023-01-01'
)

select 
macongtycn,
congtycn,
mahco,
maphanloaihco,
makhcu,
makhdms,
tenkhachhang,
tentinhkh,
statedescr,
territorydescr,
districtdescr,
wardname,
khuvucviettat,
vungmien,
sodondathang,
ngaychungtu,
mahd,
month,
a.thang,
masanpham,
tensanphamnb,
tensanphamviettat,
lineref,
soluong,
dongiachuavat,
dongiacovat,
doanhsocovat,
doanhsochuavat,
manv_mds,
manv_original,
manvghreal,
pda_crtd_user,
pda_slsperid,
tenkenhkh,
makenhphu,
tenkenhphu,
is_ecom,
thuchien_spmoi,
kh_spmoi,
thuchien_yttn,
kh_yttn,
a.datatype,
team,
datatype1,
slpp_ebysta,
slpp_medoral,
kpi_ds_pcl,
th_slpp_ebysta,
th_slpp_medoral,
th_ds_pcl,
th_ds_fmcg,
kpi_ds_fmcg,
th_ds_sptt,
kpi_ds_sptt,
kieudonhang,
makenh_moi,
brandnew2023,
cluster_state,
crs_tuyenbanhang_trongmcp,
phanloai,
makenhkh,
is_mrtd,
b1.tenquanlytt,
b1.tenquanlykhuvuc,
b1.tenquanlyvung,
ds_sp_thang,
ten_nguoi_taodon,
tencvbh_header,
tencvbh_ori,
doanhso_gh_crs,
hoadon as sohoadon,
a.manv as macrs,
a.manv_mds as slsperid_md,
a.tencvbh as tencvbhcrs,
crm as ma_crm,
scrm as ma_scrm,
ncxm as ma_ncxm,
b.trangthaigiaohang,
b.ngaygiaohang,
b1.tencvbh as tencvbh_md,
c.kh_total,
c.kh_don,
c.kh_nt,
 from `warehouse.f_sales_crs` a 
 LEFT JOIN data_leadtime b on a.sodondathang = b.ordernbr
 LEFT JOIN `staging.d_users` b1 on a.manv_mds =b1.manv
 LEFT JOIN `staging.d_calendar_ecom` c on date(c.thang) = date_trunc(date(a.ngaychungtu),month)

where is_ecom ='Ecom' and ngaychungtu >='2023-01-01' --and a.manv is not null
);

Create or replace table `warehouse.f_d_donhang_ecom`

copy `staging_temp.f_d_donhang_ecom_temp`;


End;