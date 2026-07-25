CREATE VIEW `spatial-vision-343005.warehouse.mds_thuong_quy`
AS with data_f_thuhoi_bbgh as

(
    SELECT
    manvgh,
    case when sodonhang in ('DL1-1224-00965','DL6-1224-01446','DL6-1224-01945',
    'DL7-1224-02467',
    'DL7-1224-03006',
    'DL7-1224-03354',
    'DL7-1224-03342',
    'DL7-1224-03314'
    ) then '7. Đơn hàng thu tiền ngay đã thanh toán - MDS/SDS đã chụp hình ảnh'
    else pl_thuhoi_bbgh
    end as pl_thuhoi_bbgh,
    sodonhang,
    sohoadon

    FROM `spatial-vision-343005.warehouse.f_thuhoi_bbgh` WHERE TIMESTAMP_TRUNC(ngayhoadon, DAY) >= TIMESTAMP("2024-12-01")
    AND date(ngayhoadon)<= '2024-12-31' and phanloai_giaohang = 'MDS'
)
, nv_cong_no_bbgh as
(

    SELECT
    manvgh as manv,
    count (distinct
    case when
    pl_thuhoi_bbgh in ('5. MDS giữ để thu tiền mặt chưa thanh toán - KT chưa nhận hình ảnh','6.1. Đơn hàng thu tiền ngay chưa thanh toán - MDS/SDS chưa chụp hình ảnh','6. Đơn hàng thu tiền ngay chưa thanh toán - MDS/SDS đã chụp hình ảnh') then 
    CONCAT(sodonhang,"-",sohoadon)
    else null
    end
    ) as so_don_chua_chup_hinh_hoac_thu_no,

    count (distinct
    CONCAT(sodonhang,"-",sohoadon)
    ) as tong_so_don_chup_hinh_hoac_thu_no,

    FROM `data_f_thuhoi_bbgh` 
    -- WHERE TIMESTAMP_TRUNC(ngayhoadon, DAY) >= TIMESTAMP("2024-12-01")
    -- AND date(ngayhoadon)<= '2024-12-31' and phanloai_giaohang = 'MDS'
    group by all

)

, sup_log_kpi_cong_no_bbgh AS

(
    select
    c.supid as manv,
    IFNULL(SUM(so_don_chua_chup_hinh_hoac_thu_no), 0) AS so_don_chua_chup_hinh_hoac_thu_no,
    IFNULL(SUM(tong_so_don_chup_hinh_hoac_thu_no), 0) AS tong_so_don_chup_hinh_hoac_thu_no,
    FROM `nv_cong_no_bbgh` a
    LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` c ON c.manv = a.manv AND c.thang = '2024-12-01'
    group by all
)



, all_nv_kpi_cong_no_bbgh as

(   
    SELECT manv, 
    sum(so_don_chua_chup_hinh_hoac_thu_no) as so_don_chua_chup_hinh_hoac_thu_no,
    sum(tong_so_don_chup_hinh_hoac_thu_no) as tong_so_don_chup_hinh_hoac_thu_no,
    
    FROM (
    SELECT * from nv_cong_no_bbgh
    UNION ALL
    SELECT * from sup_log_kpi_cong_no_bbgh
    )

    GROUP BY ALL
)

, _admin_phu_trach as (
    SELECT
    b.*,
    Case when b.tentinhkh in
    ('Thành phố Hà Nội','Hà Tây','Lào Cai','Lai Châu','Vĩnh Phúc','Bắc Kạn','Điện Biên',
    'Thái Nguyên','Phú Thọ','Hòa Bình','Yên Bái','Cao Bằng','Sơn La','Tuyên Quang',
    'Hà Giang','Hải Phòng','Hưng Yên','Quảng Ninh','Hải Dương','Bắc Ninh','Bắc Giang',
    'Lạng Sơn','Thái Bình','Ninh Bình','Nam Định','Hà Nam','Hà Tĩnh','Nghệ An','Thanh Hóa')
    then 'MR3056'

    when b.tentinhkh in ('Thành phố Hồ Chí Minh','Bà Rịa - Vũng Tàu','Bình Dương','Đồng Nai',
    'Lâm Đồng','Tây Ninh','Đắk Nông','Bình Phước','Tiền Giang','Long An','Trà Vinh','Bến Tre',
    'Vĩnh Long','Đồng Tháp','Kiên Giang','Cà Mau','Thành phố Cần Thơ','An Giang','Bạc Liêu',
    'Sóc Trăng','Hậu Giang')
    then 'MR2662' 
    
    when b.tentinhkh in ('Thành phố Đà Nẵng', 'Quảng Trị', 'Quảng Nam', 'Bình Định', 'Thừa Thiên - Huế', 
    'Thừa Thiên Huế', 'Quảng Ngãi', 'Quảng Bình', 'Gia Lai', 'Khánh Hòa', 'Bình Thuận', 'Ninh Thuận', 
    'Đắk Lắk', 'Kon Tum','Phú Yên')
    then 'MR2514' 
    else null 
    end as manv_admin

    FROM `warehouse.f_baocao_daily_performance_mds_new_v2` b
    WHERE date(ngaychungtu)>= '2024-12-01' and date(ngaychungtu)<= '2024-12-31'
    and b.manv_phu_trach_thu_hoi_bbgh LIKE '%MR%'  and b.manv_phu_trach_thu_hoi_bbgh not in (
    'MR3068',
    'MR2441',
    'MR2902',
    'MR2954',
    'MR3161',
    'MR3909',
    'MR1351',
    'MR3104',
    'MR1221',
    'MR2934'
    )
)

, nv_admin_bbgh_ban_cung
as (

SELECT
manv_admin as manv,
count (distinct case when c.ma_noi_tinh_thu_hoi_bbgh is not null then ma_noi_tinh_thu_hoi_bbgh end) as sl_bb_can_thu_hoi,
count (distinct case when c.ma_noi_tinh_thu_hoi_bbgh is not null and (da_thu_hoi_bbgh = 1) then ma_noi_tinh_thu_hoi_bbgh
end) as sl_bb_da_thu_hoi
FROM `_admin_phu_trach` c
GROUP BY 1

)

, nv_log_kpi_bbgh AS (
  SELECT
    manv_phu_trach_thu_hoi_bbgh AS manv,
    COUNT(DISTINCT CASE WHEN ma_noi_tinh_thu_hoi_bbgh IS NOT NULL THEN ma_noi_tinh_thu_hoi_bbgh END) AS sl_bb_can_thu_hoi, 
    COUNT(DISTINCT CASE WHEN ma_noi_tinh_thu_hoi_bbgh IS NOT NULL AND (da_thu_hoi_bbgh = 1) THEN ma_noi_tinh_thu_hoi_bbgh END) AS sl_bb_da_thu_hoi,
  FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2`
  WHERE 
DATE(ngaychungtu) >= '2024-12-01' AND DATE(ngaychungtu) <= '2024-12-31' and
manv_phu_trach_thu_hoi_bbgh LIKE '%MR%' 
  GROUP BY 1
)

, sup_log_kpi_bbgh AS

(
    select
    c.supid as manv,
    IFNULL(SUM(sl_bb_can_thu_hoi), 0) AS sl_bb_can_thu_hoi,
    IFNULL(SUM(sl_bb_da_thu_hoi), 0) AS sl_bb_da_thu_hoi,
    FROM `nv_log_kpi_bbgh` a
    LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` c ON c.manv = a.manv AND c.thang = '2024-12-01'
    group by all
)

-- , all_nv_kpi_bbgh as

-- (
--     select * from nv_admin_bbgh_ban_cung
--     UNION ALL
--     select * from nv_log_kpi_bbgh
--     UNION ALL
--     select * from sup_log_kpi_bbgh
-- )

, all_nv_kpi_bbgh as

(   
    SELECT manv, 
    sum(sl_bb_can_thu_hoi) as sl_bb_can_thu_hoi,
    sum(sl_bb_da_thu_hoi) as sl_bb_da_thu_hoi,
    
    FROM (
    select * from nv_admin_bbgh_ban_cung
    UNION ALL
    select * from nv_log_kpi_bbgh
    UNION ALL
    select * from sup_log_kpi_bbgh
    )

    GROUP BY ALL
)

SELECT
'4/2024' as quy,
h.phaply,
h.loaihdld,
h.msnvcsmmoi,
h.hovatenfullname,
TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour) as inserted_at,
h.cumphucvu,
case when h.msnvcsmmoi = 'MR2662' then 'DIEU_PHOI_LOG' else b.role_luong_mds_phanloai end as role_luong_mds_phanloai,
IFNULL(nv1.tong_so_don_chup_hinh_hoac_thu_no,0) - IFNULL(nv1.so_don_chua_chup_hinh_hoac_thu_no,0) as sl_bb_da_chup_hinh_hoac_thu_no ,
IFNULL(nv1.tong_so_don_chup_hinh_hoac_thu_no,0) as sl_bb_can_chup_hinh_hoac_thu_no,
IFNULL(nv2.sl_bb_da_thu_hoi,0) as sl_bb_da_thu_hoi,
IFNULL(nv2.sl_bb_can_thu_hoi,0) as sl_bb_can_thu_hoi,
ifnull(du_dieu_kien,0) as thuc_hien_cac_chuong_trinh_thuong,
b.supid,
b.tenquanlytt
FROM `spatial-vision-343005.staging.d_hr_dsns_bytime` h
LEFT JOIN `staging.d_users_bytime` b on h.thang = b.thang and h.msnvcsmmoi = b.manv
LEFT JOIN all_nv_kpi_cong_no_bbgh nv1 on h.msnvcsmmoi = nv1.manv
LEFT JOIN all_nv_kpi_bbgh nv2 on h.msnvcsmmoi = nv2.manv
LEFT JOIN `spatial-vision-343005.staging.d_mds_thuong_quy_dk_tra_thuong` dk on h.msnvcsmmoi = dk.manv
WHERE h.thang = '2024-12-01'
AND h.phongdeptsummary = 'MDS' 
AND h.hovatenfullname NOT IN ('Lương Trịnh Thắng')
and h.msnvcsmmoi is not null
UNION ALL
SELECT
'4/2024' as quy,
h.phaply,
h.loaihdld,
h.msnvcsmmoi,
h.hovatenfullname,
TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour) as inserted_at,
h.cumphucvu,
'MDS_DIRECTOR' as role_luong_mds_phanloai,
15363 as sl_bb_da_chup_hinh_hoac_thu_no ,
15363 as sl_bb_can_chup_hinh_hoac_thu_no,
3252 as sl_bb_da_thu_hoi,
3252 as sl_bb_can_thu_hoi,
0 as thuc_hien_cac_chuong_trinh_thuong,
b.supid,
b.tenquanlytt
FROM `spatial-vision-343005.staging.d_hr_dsns_bytime` h
LEFT JOIN `staging.d_users_bytime` b on h.thang = b.thang and h.msnvcsmmoi = b.manv
LEFT JOIN `spatial-vision-343005.staging.d_users` q on h.msnvcsmmoi = q.manv
LEFT JOIN `spatial-vision-343005.staging.d_mds_thuong_quy_dk_tra_thuong` dk on h.msnvcsmmoi = dk.manv
WHERE h.thang = '2024-12-01'
AND h.phongdeptsummary = 'MDS' 
AND h.hovatenfullname IN ('Lương Trịnh Thắng')
;