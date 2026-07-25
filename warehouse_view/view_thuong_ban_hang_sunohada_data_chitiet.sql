CREATE VIEW `spatial-vision-343005.warehouse.view_thuong_ban_hang_sunohada_data_chitiet`
AS WITH data_raw as (
  select 
a.ngaychungtu,
a.inserted_at,
a.macongtycn,
c.supid as ma_crm,
c.tenquanlytt,
c.col.ma_nvbh as manv,
c.tencvbh,
c.asm as ma_ncxm,
c.tenquanlykhuvuc,
a.territorydescr,--khu vực
a.statedescr, -- tỉnh
a.sodondathang,
a.makhdms,
a.tenkhachhang,
a.makenhkh_cu,
a.makenhphu_cu,
a.hcoid,
a.maphanloaihco_cu,
a.masanpham,
a.tensanphamnb ,
a.tensanphamviettat,
a.soluong,
a.doanhsocovat,
a.doanhsochuavat,
0 as target,
NULL as target_clc,
NULL as target_pcl,
b.crtd_datetime as ngay_ky_hd,
a.pubcustid,
a.pubcustname,
MIN(ngaychungtu) OVER (PARTITION BY a.makhdms ) AS ngay_don_hang_dau_tien
/*update: bổ sung cột soanh số của năm trước */
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` b on b.custid = a.makhdms
LEFT JOIN `warehouse.f_mapping_crs` c ON a.makhdms = c.custid
LEFT JOIN `warehouse.dim_excluded_makhdms` d ON a.makhdms = d.makhdms

where date(ngaychungtu) >='2025-01-01'
AND makenhkh_cu in ('PCL','CLC')
AND a.masanpham in ('T4040101001','T4040101002')
AND a.is_hang_km != 'Hàng KM'
AND IFNULL(a.maphanloaihco_cu,'none') not in ('DLPP')
AND d.makhdms IS NULL
)

,target_sp AS (
SELECT
*
FROM data_raw

UNION ALL
SELECT
  '2026-01-01' AS ngaychungtu,
  NULL AS inserted_at,
  NULL AS macongtycn,
  NULL AS ma_crm,
  NULL AS tenquanlytt,
  NULL AS manv,
  NULL AS tencvbh,
  NULl as ma_ncxm,
  NULL as tenquanlykhuvuc,
  NULL AS territorydescr,
  NULL AS statedescr,
  NULL AS sodondathang,
  NULL AS makhdms,
  NULL AS tenkhachhang,
  NULL AS makenhkh_cu,
  NULL AS makenhphu_cu,
  NULL AS hcoid,
  NULL AS maphanloaihco_cu,
  'T4040101002' AS masanpham,
  'SunoHada Mist 100ml' AS tensanphamnb,
  'SHQRIMM100' AS tensanphamviettat,
  NULL AS soluong,
  NULL AS doanhsocovat,
  NULL AS doanhsochuavat,
  2100000000 AS target,
  NULL as target_clc,
  NULL as target_pcl,
NULL as ngay_ky_hd,
NULL as pubcustid,
NULL as pubcustname,
NULL AS ngay_don_hang_dau_tien

UNION ALL
SELECT
  '2026-01-01' AS ngaychungtu,
  NULL AS inserted_at,
  NULL AS macongtycn,
  NULL AS ma_crm,
  NULL AS tenquanlytt,
  NULL AS manv,
  NULL AS tencvbh,
  NULl as ma_ncxm,
  NULL as tenquanlykhuvuc,
  NULL AS territorydescr,
  NULL AS statedescr,
  NULL AS sodondathang,
  NULL AS makhdms,
  NULL AS tenkhachhang,
  NULL AS makenhkh_cu,
  NULL AS makenhphu_cu,
  NULL AS hcoid,
  NULL AS maphanloaihco_cu,
  'T4040101001' AS masanpham,
  'SunoHada Lotion 100ml' AS tensanphamnb,
  'SHSL100' AS tensanphamviettat,
  NULL AS soluong,
  NULL AS doanhsocovat,
  NULL AS doanhsochuavat,
  2400000000 AS target,
  NULL as target_clc,
NULL as target_pcl,
NULL as ngay_ky_hd,
NULL as pubcustid,
NULL as pubcustname,
NULL AS ngay_don_hang_dau_tien
)
,ten_quan_ly_target as (
SELECT 'Hồ Thị Hồng Gấm' AS tenquanlytt, 'MR0673' AS ma_crm, 396160336 AS target_clc, 210196458 AS target_pcl UNION ALL
SELECT 'Nguyễn Hồng Hà', 'MR0992', 183932906, 185105127 UNION ALL
SELECT 'Nguyễn Ngọc Thiên Trang', 'MR0683', 109945466, 206936536 UNION ALL
SELECT 'Nguyễn Thị Dung', 'MR0253', 339181990, 46727300 UNION ALL
SELECT 'Nguyễn Thị Lan Anh', 'MR1427', 131856353, 102767300 UNION ALL
SELECT 'Phan Thị Bình Khê', 'MR0055', 208895041, 85494705 UNION ALL
SELECT 'Lâm Văn Cảnh', 'MR0538', 108008397, 236018463 UNION ALL
SELECT 'Phạm Tuân', 'MR1250', 76638208, 110063710 UNION ALL
SELECT 'Lê Văn Tùng', 'MR1391', 270536000, 271880000 UNION ALL
SELECT 'Ngô Tiến Vũ', 'MR0123', 200605000, 205089000 UNION ALL
SELECT 'Nguyễn Toàn', 'MR1579', 216562000, 118400000 UNION ALL
SELECT 'Nguyễn Văn Đôn', 'MR2355', 175698000, 105182000 UNION ALL
SELECT 'Trần Thanh Quang', 'MR1555', 87850000, 110393000
)
, union_all as (
SELECT * FROM target_sp
UNION ALL
SELECT
  '2026-01-01' AS ngaychungtu,
  NULL AS inserted_at,
  NULL AS macongtycn,
  t.ma_crm,
  t.tenquanlytt AS tenquanlytt,
  NULL AS manv,
  NULL AS tencvbh,
  d.asm as ma_ncxm,
  d.tenquanlykhuvuc,
  NULL AS territorydescr,
  NULL AS statedescr,
  NULL AS sodondathang,
  NULL AS makhdms,
  NULL AS tenkhachhang,
  NULL AS makenhkh_cu,
  NULL AS makenhphu_cu,
  NULL AS hcoid,
  NULL AS maphanloaihco_cu,
  NULL AS tensanphamnb,
  NULL AS masanpham,
  NULL AS tensanphamviettat,
  NULL AS soluong,
  NULL AS doanhsocovat,
  NULL AS doanhsochuavat,
  NULL AS target,
  t.target_clc,
  t.target_pcl,
NULL as ngay_ky_hd,
NULL as pubcustid,
NULL as pubcustname,
NULL AS ngay_don_hang_dau_tien
FROM ten_quan_ly_target t
LEFT JOIN `spatial-vision-343005.staging.d_users` d ON d.manv = t.ma_crm
)

SELECT
a.*,
CASE
    WHEN EXTRACT(YEAR FROM CAST(a.ngaychungtu AS DATE)) = EXTRACT(YEAR FROM CURRENT_DATE()) 
      THEN CAST(a.ngaychungtu AS DATE)
    ELSE 
      DATE_ADD(CAST(a.ngaychungtu AS DATE), INTERVAL (EXTRACT(YEAR FROM CURRENT_DATE()) - EXTRACT(YEAR FROM CAST(a.ngaychungtu AS DATE))) YEAR)
  END AS thang_filter,
CASE
  WHEN a.tenquanlykhuvuc = 'Ngô Tiến Vũ' THEN 'ZONE 1'
  WHEN a.tenquanlykhuvuc = 'Hoàng Trung Thành' THEN 'ZONE 2'
  WHEN a.tenquanlykhuvuc = 'Lâm Văn Cảnh' THEN 'ZONE 3'
  ELSE null
  END AS zone

FROM union_all a


;