CREATE VIEW `spatial-vision-343005.warehouse.view_trungbay_ nuocmatnhantao`
AS WITH dskh_thamgia AS(
SELECT
--a.macongtychinhanh
e.col. ma_nvbh as manhanvienphutrach,
a.makhachhang,
a.tenkhachhang,
a.thanhphotinh,
d.stocksales as tinh_trang_ma_so_thue,
1500000 as muc_ds,
15 as muc_sl,
d.businessscope as pham_vi_kinh_doanh,
b.thu_hoi_tttb as thu_hoi_tttb, -- b.thu_hoi_tttb
a.ngaydangky,
if(date(d.legaldate) >= current_date("+7"),'Còn hiệu lực','Hết hiệu lực') as hieu_luc_gdp,
FROM `spatial-vision-343005.staging.d_tdisplay` a
LEFT JOIN `staging.d_master_khachhang` d on d.custid = a.makhachhang
LEFT JOIN `spatial-vision-343005.staging.d_manual_gs_dskh_tham_gia_poster_2025` b ON b.ma_khach_hang = a.makhachhang
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` e on e.custid = a.makhachhang
WHERE 
a.machuongtrinh = '2507-CTTB-CPA46-NT-QT'
and lower(a.trangthaiduyettrungbay) = 'đã duyệt'
and a.macongtychinhanh not in ('KHA014','HNI010')
GROUP BY ALL
)

, data_sales AS (
SELECT
makhdms,
MAX(updated_at) as updated_at,
SUM (
    CASE
    WHEN date(s.ngaychungtu) >= '2025-07-01' AND date(s.ngaychungtu)  <= '2025-09-30' 
    THEN s.doanhsocovat ELSE 0 END
    ) as tong_ds_q3,

SUM (
    CASE
    WHEN date(s.ngaychungtu) >= '2025-10-01' AND date(s.ngaychungtu)  <= '2025-12-26' 
    THEN s.doanhsocovat ELSE 0 END
    ) as tong_ds_q4,


SUM (
    CASE
    WHEN s.masanpham in ('T302203003','T302203014') AND date(s.ngaychungtu) >= '2025-07-01' AND date(s.ngaychungtu)  <= '2025-09-30'
    THEN s.soluong ELSE 0 END
    ) as sl_sp_online_q3,

SUM (
    CASE
    WHEN s.masanpham in ('T302203003','T302203014') AND date(s.ngaychungtu) >= '2025-10-01' AND date(s.ngaychungtu)  <= '2025-12-26'
    THEN s.soluong ELSE 0 END
    ) as sl_sp_online_q4,
FROM `warehouse.f_raw_data_sales_yoy` s
WHERE date(s.ngaychungtu) >= '2025-07-01' AND date(s.ngaychungtu)  <= '2025-12-26'
--AND s.masanpham in ('T302203003','T302203014')
GROUP BY ALL
)

SELECT
a.*,
CASE WHEN a.ngaydangky <= '2025-09-09' THEN '2025-07-01' ELSE '2025-10-01' END AS ngay_ky_hd,
d.tencvbh as tennhanvienphutrach,
e.branchid as macongtychinhanh,
h.ma_cre,
h.ho_ten_cre,
d.supid as ma_crm,
d.tenquanlytt,
s.updated_at,
IFNULL(tong_ds_q3,0) as tong_ds_q3,
IFNULL(tong_ds_q4,0) as tong_ds_q4,
IFNULL(sl_sp_online_q3,0) as sl_sp_online_q3,
IFNULL(sl_sp_online_q4,0) as sl_sp_online_q4,
IF(tong_ds_q3 >= a.muc_ds,'Đạt', 'Không đạt') as xet_ds_q3,
IF(tong_ds_q4 >= a.muc_ds,'Đạt', 'Không đạt') as xet_ds_q4,
IF(sl_sp_online_q3 >= a.muc_sl,'Đạt', 'Không đạt') as xet_sl_q3, 
IF(sl_sp_online_q4 >= a.muc_sl,'Đạt', 'Không đạt') as xet_sl_q4,
IF(IFNULL(tong_ds_q3,0)<a.muc_ds,a.muc_ds-IFNULL(tong_ds_q3,0),0) as ds_q3_thieu,
IF(IFNULL(tong_ds_q4,0)<a.muc_ds,a.muc_ds-IFNULL(tong_ds_q4,0),0) as ds_q4_thieu,
IF(IFNULL(sl_sp_online_q3,0)<a.muc_sl,a.muc_sl-IFNULL(sl_sp_online_q3,0),0) as sl_q3_thieu,
IF(IFNULL(sl_sp_online_q4,0)<a.muc_sl,a.muc_sl-IFNULL(sl_sp_online_q4,0),0) as sl_q4_thieu,

FROM dskh_thamgia a
LEFT JOIN data_sales s ON a.makhachhang = s.makhdms
LEFT JOIN `spatial-vision-343005.staging.d_users` d ON d.manv = a.manhanvienphutrach
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` e ON e.custid = a.makhachhang
LEFT JOIN `spatial-vision-343005.staging.d_calendar_cre` h ON a.manhanvienphutrach = h.ma_crs AND date(h.thang) = DATE_TRUNC(DATE(CURRENT_DATE()),MONTH)



;