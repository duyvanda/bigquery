CREATE VIEW `spatial-vision-343005.warehouse.view_mrtt_2025`
AS WITH data_sale as (
SELECT
a.* EXCEPT (dinh_muc,da_thanh_toan,nam,ma_crs),
CAST (a.dinh_muc AS FLOAT64) as dinh_muc ,
IFNULL(a.da_thanh_toan,0) as da_thanh_toan,
CAST(a.nam AS INT64) as nam,
e.channel,
b.statedescr,
a.ma_crs as manv,
d2.msnvcsmmoi as supid,
SUM(CASE WHEN thang_number in (1,2,3) AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_q1,
SUM(CASE WHEN thang_number in (4,5,6) AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_q2,
SUM(CASE WHEN thang_number in (7,8,9) AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_q3,
SUM(CASE WHEN thang_number in (10,11,12) AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_q4,
SUM(CASE WHEN thang_number = 1 AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_t1,
SUM(CASE WHEN thang_number = 2 AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_t2,
SUM(CASE WHEN thang_number = 3 AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_t3,
SUM(CASE WHEN thang_number = 4 AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_t4,
SUM(CASE WHEN thang_number = 5 AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_t5,
SUM(CASE WHEN thang_number = 6 AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_t6,
SUM(CASE WHEN thang_number = 7 AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_t7,
SUM(CASE WHEN thang_number = 8 AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_t8,
SUM(CASE WHEN thang_number = 9 AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_t9,
SUM(CASE WHEN thang_number = 10 AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_t10,
SUM(CASE WHEN thang_number = 11 AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_t11,
SUM(CASE WHEN thang_number = 12 AND ngaychungtu  >= tu_ngay AND ngaychungtu <= den_ngay THEN doanhsochuavat ELSE 0 END) AS ds_t12,

FROM `spatial-vision-343005.staging.d_mrtt_2025` a
LEFT JOIN `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` b ON b.makhdms = a.ma_kh_noi_bo
-- LEFT JOIN (
--     SELECT tencvbh, tenquanlytt, manv, supid
--     FROM (
--       SELECT 
--         tencvbh, 
--         tenquanlytt, 
--         manv, 
--         supid,
--         ROW_NUMBER() OVER(
--           PARTITION BY tencvbh, tenquanlytt 
--           ORDER BY CASE WHEN manv LIKE '%KN%' THEN 2 ELSE 1 END ASC
--         ) as rn
--       FROM `spatial-vision-343005.staging.d_users`
--     )
--     WHERE rn = 1
--   ) d ON d.tencvbh = a.crs AND d.tenquanlytt = a.crm
LEFT JOIN `spatial-vision-343005.staging.d_hr_dsns` d1 ON d1.msnvcsmmoi = a.ma_crs
LEFT JOIN `spatial-vision-343005.staging.d_hr_dsns` d2 ON d2.hovatenfullname = a.crm
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` e ON e.custid = a.ma_kh_noi_bo
WHERE d1.phongdeptsummary = 'HCP'
GROUP BY ALL

)
,tinh_ttyt as (
SELECT
*,
ROUND(ds_t1*dinh_muc/100,-5) as ttyt_t1,
ROUND(ds_t2*dinh_muc/100,-5) as ttyt_t2,
ROUND(ds_t3*dinh_muc/100,-5) as ttyt_t3,
ROUND(ds_t4*dinh_muc/100,-5) as ttyt_t4,
ROUND(ds_t5*dinh_muc/100,-5) as ttyt_t5,
ROUND(ds_t6*dinh_muc/100,-5) as ttyt_t6,
ROUND(ds_t7*dinh_muc/100,-5) as ttyt_t7,
ROUND(ds_t8*dinh_muc/100,-5) as ttyt_t8,
ROUND(ds_t9*dinh_muc/100,-5) as ttyt_t9,
ROUND(ds_t10*dinh_muc/100,-5) as ttyt_t10,
ROUND(ds_t11*dinh_muc/100,-5) as ttyt_t11,
ROUND(ds_t12*dinh_muc/100,-5) as ttyt_t12,

ds_q1*dinh_muc/100 as ttyt_q1,
ds_q2*dinh_muc/100 as ttyt_q2,
ds_q3*dinh_muc/100 as ttyt_q3,
ds_q4*dinh_muc/100 as ttyt_q4,
ds_q1 + ds_q2 + ds_q3 + ds_q4 as tong_ds_nam,
(ds_q1 + ds_q2 + ds_q3 + ds_q4)*dinh_muc/100 + chi_phi_dieu_chinh as tong_ttyt_nam,
ROW_NUMBER() OVER (PARTITION BY ten_don_vi,nam ORDER BY ma_kh_noi_bo) as stt
FROM data_sale
)
SELECT
*,
--SUM rồi mới làm tròn
CASE
  WHEN stt = 1 THEN ROUND(SUM(ttyt_q1) OVER (PARTITION BY ten_don_vi,nam),-5)
  ELSE 0 END AS ttyt_q1_lamtron,
CASE
  WHEN stt = 1 THEN ROUND(SUM(ttyt_q2) OVER (PARTITION BY ten_don_vi,nam),-5)
  ELSE 0 END AS ttyt_q2_lamtron,
CASE
  WHEN stt = 1 THEN ROUND(SUM(ttyt_q3) OVER (PARTITION BY ten_don_vi,nam),-5)
  ELSE 0 END AS ttyt_q3_lamtron,
CASE
  WHEN stt = 1 THEN ROUND(SUM(ttyt_q4) OVER (PARTITION BY ten_don_vi,nam),-5)
  ELSE 0 END AS ttyt_q4_lamtron,
CASE
  WHEN stt = 1 THEN ROUND(SUM(tong_ttyt_nam) OVER (PARTITION BY ten_don_vi,nam),-5)
  ELSE 0 END AS tong_ttyt_nam_lamtron,
FROM tinh_ttyt





























;