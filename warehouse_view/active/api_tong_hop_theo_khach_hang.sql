CREATE VIEW `spatial-vision-343005.warehouse.api_tong_hop_theo_khach_hang`
AS WITH ma_kh_ct as (

  SELECT distinct custid, check_cttl as ten_ct  FROM `spatial-vision-343005.warehouse.f_tracuu_cttl_kh`  where nam = 2025

)

, last_success_call_date as

(
SELECT
custid,
MAX(visitdate) AS ngay_call_dat_gan_nhat
FROM `warehouse.f_call_result`
where ma_call_kh_dat is not null
GROUP BY custid
)

, data_sales_kh as
(
SELECT
a.makhdms,
IFNULL(sodontrahang, sodondathang) as ma_dh_chung,
ngaychungtu,
SUM(a.doanhsochuavat) AS doanhsochuavat,
'Đã giao hàng' as trang_thai_don
FROM `spatial-vision-343005.staging.f_sales` a
WHERE ngaychungtu >= '2024-01-01'
GROUP BY ALL
)

, api_tong_hop_theo_khach_hang_dh_gan_nhat as (
select * from data_sales_kh QUALIFY ROW_NUMBER() OVER (PARTITION BY makhdms ORDER BY ngaychungtu DESC) = 1
)

, sales_data as (

SELECT
a.makhdms,
IFNULL(sodontrahang, sodondathang) as ma_dh_chung,
ngaychungtu,
doanhsochuavat,
EXTRACT(MONTH FROM TIMESTAMP(ngaychungtu)) AS month,
EXTRACT(YEAR FROM TIMESTAMP(ngaychungtu)) AS year
FROM `spatial-vision-343005.staging.f_sales` a
WHERE ngaychungtu >= '2025-01-01'
)

, api_tong_hop_theo_khach_hang_ds_dh_nam_thang as (

SELECT
  makhdms,
  -- Doanh số tháng hiện tại
  SUM(CASE WHEN EXTRACT(MONTH FROM CURRENT_DATE()) = month AND EXTRACT(YEAR FROM CURRENT_DATE()) = year THEN doanhsochuavat ELSE 0 END) AS doanh_so_thang_hien_tai,
  -- Doanh số năm hiện tại
  SUM(CASE WHEN EXTRACT(YEAR FROM CURRENT_DATE()) = year THEN doanhsochuavat ELSE 0 END) AS doanh_so_nam_hien_tai,
  -- Đơn hàng tháng hiện tại
  COUNT(CASE WHEN EXTRACT(MONTH FROM CURRENT_DATE()) = month AND EXTRACT(YEAR FROM CURRENT_DATE()) = year THEN ma_dh_chung END) AS don_hang_thang_hien_tai,
  -- Tổng đơn hàng năm hiện tại
  COUNT(CASE WHEN EXTRACT(YEAR FROM CURRENT_DATE()) = year THEN ma_dh_chung END) AS tong_don_hang_nam_hien_tai
FROM sales_data
GROUP BY ALL

)

, data_sales_sp as
(
SELECT
a.makhdms,
a.masanpham,
c.descr as tensanpham,
current_timestamp() as ngay_dat_don,
-- a.tensanphamnb,
SUM(a.doanhsochuavat) AS doanhsochuavat,
sum(soluong) as soluong
FROM `spatial-vision-343005.staging.f_sales` a
LEFT JOIN `staging.d_dms_master_invtid` c on a.masanpham = c.invtid
WHERE ngaychungtu >= '2024-01-01'
GROUP BY ALL
)

, api_tong_hop_theo_khach_hang_top_san_pham as (
select * from data_sales_sp
order by doanhsochuavat desc
)


, combined
as
(
SELECT
a.custid as ma_kh_dms,
d.custname as ten_kh,
d.businessname as ten_chu_nt,
d.taxregnbr as ma_so_thue,
a.statedescr as tinh,
a.districtdescr as quan_huyen,
a.wardname as phuong_xa,
d.shortterritorydescr as khu_vuc,
d.address as dia_chi,
a.channel as kenh,
a.shoptype as kenh_phu,
CASE 
        WHEN u.manv IS NULL THEN 'inactive'
        ELSE a.active -- Giả sử a.active đã là 'active'/'inactive'
    END AS trang_thai,
d.hcoid as ma_hco,
d.hcotypeid as ma_phan_loai_hco,
a.col.ma_nvbh as ma_crs,
u.tencvbh as ten_crs,
u.supid as ma_crm,
u.tenquanlytt as ten_crm,

d.businessscope as pham_vi_kd,
CAST (legaldate as DATE) as ngay_het_han_gpp,
DATE_DIFF( CAST (legaldate as DATE) , CURRENT_DATE(), DAY) AS so_ngay_het_han_gpp,

cn.hinh_thuc_thanh_toan,
cn.no_goc,
cn.no_xau,

dhg.ngaychungtu as ngay_don_hang_gan_nhat,
dhg.ma_dh_chung as don_hang_gan_nhat,
dhg.doanhsochuavat as doanh_so_don_hang_gan_nhat,
dhg.trang_thai_don as trang_thai_don_hang_gan_nhat,

dhnt.doanh_so_thang_hien_tai,
dhnt.doanh_so_nam_hien_tai,
dhnt.don_hang_thang_hien_tai,
dhnt.tong_don_hang_nam_hien_tai,

lc.ngay_call_dat_gan_nhat,

f3.ten_ct as ten_ct_tich_luy,

f2.masanpham,
f2.tensanpham,
f2.soluong,



FROM `spatial-vision-343005.warehouse.f_mapping_crs` a
LEFT JOIN `spatial-vision-343005.staging.d_users` u on a.col.ma_nvbh = u.manv
LEFT JOIN `staging.d_master_khachhang` d on a.custid = d.custid
LEFT JOIN `staging_temp.api_tong_hop_theo_khach_hang_cong_no` cn on cn.ma_kh_dms = a.custid
LEFT JOIN `api_tong_hop_theo_khach_hang_dh_gan_nhat` dhg on dhg.makhdms = a.custid
LEFT JOIN `api_tong_hop_theo_khach_hang_ds_dh_nam_thang` dhnt on dhnt.makhdms = a.custid
LEFT JOIN last_success_call_date lc on lc.custid = a.custid
LEFT JOIN 
`api_tong_hop_theo_khach_hang_top_san_pham` f2 ON a.custid = f2.makhdms  
LEFT JOIN ma_kh_ct f3 ON a.custid = f3.custid 


WHERE a.channel in ('INS', 'CLC', 'PCL', 'TP')


)

SELECT
* except (masanpham, tensanpham, soluong),
ARRAY_AGG(STRUCT(masanpham, tensanpham, soluong) ORDER BY soluong DESC) AS top_san_pham,
FROM 
combined
GROUP BY ALL;