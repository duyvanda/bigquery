CREATE VIEW `spatial-vision-343005.warehouse.view_bao_cao_tong_quan_crs_khach_hang`
AS WITH dskh_tham_gia AS (
        SELECT
            manv,
            tencvbh,
            supid,
            tenquanlytt,
            ma_khachhang AS ma_kh,
            tenkhachhang,
            thu,
            --STRING_AGG(DISTINCT CAST(thu AS STRING), ', ' ORDER BY CAST(thu AS STRING)) AS thu_kh
        FROM
            `warehouse.f_thongtin_tuyen_mcp_tp_pcl` a
        WHERE
            active = 'Active'
            AND kenh = 'TP'
           AND DATE(thang) >= DATE_TRUNC(CURRENT_DATE('Asia/Ho_Chi_Minh'), QUARTER)
           AND DATE(thang) < DATE_ADD(DATE_TRUNC(CURRENT_DATE('Asia/Ho_Chi_Minh'), QUARTER), INTERVAL 1 QUARTER)
        --GROUP BY ALL
        QUALIFY ROW_NUMBER() OVER(PARTITION BY ma_khachhang ORDER BY thang DESC) = 1

)
,dskh_tham_gia_final AS (
  SELECT
  manv,
  tencvbh,
  supid,
  tenquanlytt,
  ma_kh,
  tenkhachhang,
  STRING_AGG(DISTINCT CAST(thu AS STRING), ', ' ORDER BY CAST(thu AS STRING)) AS thu_kh
  FROM dskh_tham_gia
  GROUP BY  manv,
            tencvbh,
            supid,
            tenquanlytt,
            ma_kh,
            tenkhachhang

)
,raw_sales AS (
  SELECT
    makhdms AS ma_kh,
    SUM(CASE 
        WHEN DATE_TRUNC(DATE(ngaychungtu), QUARTER) = DATE_TRUNC(CURRENT_DATE(), QUARTER) 
        THEN doanhsochuavat 
        ELSE 0 
      END) AS doanh_so_quy,

    SUM(CASE 
        WHEN DATE_TRUNC(DATE(ngaychungtu), MONTH) = DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH)
        THEN doanhsochuavat 
        ELSE 0 
      END) AS doanh_so_thang_truoc

  FROM
    `staging_temp.f_sales_crs_lhq_bytime` a
  WHERE
    a.crs_tuyenbanhang_trongmcp NOT IN ('Rural')
    AND makhdms IS NOT NULL
    AND makenhkh = 'TP'
    AND DATE(thang) >= DATE_TRUNC(CURRENT_DATE('Asia/Ho_Chi_Minh'), QUARTER)
    AND DATE(thang) < DATE_ADD(DATE_TRUNC(CURRENT_DATE('Asia/Ho_Chi_Minh'), QUARTER), INTERVAL 1 QUARTER)
  GROUP BY
    makhdms
)
, loyalty_tp AS (
SELECT 
  ma_kh,
  dk_doanh_so_quy,
  -- Lấy Doanh số thực hiện theo quý hiện tại
  CASE EXTRACT(QUARTER FROM CURRENT_DATE())
    WHEN 1 THEN tong_ds_q1 
    WHEN 2 THEN tong_dsth_q2
    WHEN 3 THEN tong_dsth_q3
    WHEN 4 THEN tong_dsth_q4
  END AS tong_dsth_hien_tai,

  -- Lấy Doanh số lũy kế theo quý hiện tại
  CASE EXTRACT(QUARTER FROM CURRENT_DATE())
    WHEN 1 THEN ds_luy_ke_q1
    WHEN 2 THEN ds_luy_ke_q2
    WHEN 3 THEN ds_luy_ke_q3
    WHEN 4 THEN ds_luy_ke_q4
  END AS ds_luy_ke_hien_tai,
  'Loyalty TP' as ten_chuong_trinh
FROM `spatial-vision-343005.warehouse.view_theo_doi_loyalty_tp_2026`
WHERE hieu_luc_hd_ket_thuc >= CURRENT_DATE('Asia/Ho_Chi_Minh')
),
trung_bay_ebysta AS (
SELECT  
  makh AS ma_kh,
  muc_dk_sl as muc_dk_sl_ebysta,
  
  -- Lấy số lượng tự động theo Quý hiện tại
  CASE EXTRACT(QUARTER FROM CURRENT_DATE())
    WHEN 2 THEN soluong_quy2
    WHEN 3 THEN soluong_quy3
    WHEN 4 THEN soluong_quy4
  END AS soluong_quy_hien_tai_ebysta,
  
  -- Lấy kết quả xét duyệt tự động theo Quý hiện tại
  CASE EXTRACT(QUARTER FROM CURRENT_DATE())
    WHEN 2 THEN xet_sl_q2
    WHEN 3 THEN xet_sl_q3
    WHEN 4 THEN xet_sl_q4
  END AS xet_sl_quy_hien_tai_ebysta,
  'Trưng bày Ebysta' as ten_chuong_trinh

FROM `spatial-vision-343005.warehouse.view_trung_bay_ebysta`
),
trung_bay_decal as (
  SELECT 
  makhachhang AS ma_kh,
  
  -- Lấy doanh số tự động theo Quý hiện tại
  CASE EXTRACT(QUARTER FROM CURRENT_DATE())
    WHEN 1 THEN ds_q1
    WHEN 2 THEN ds_q2
    WHEN 3 THEN ds_q3
    WHEN 4 THEN ds_q4
  END AS ds_quy_hien_tai,
  
  -- Lấy kết quả xét duyệt tự động theo Quý hiện tại
  CASE EXTRACT(QUARTER FROM CURRENT_DATE())
    WHEN 1 THEN xet_sl_q1
    WHEN 2 THEN xet_sl_q2
    WHEN 3 THEN xet_sl_q3
    WHEN 4 THEN xet_sl_q4
  END AS xet_sl_quy_hien_tai,
  'Trưng bày Decal' as ten_chuong_trinh

FROM `spatial-vision-343005.warehouse.view_trung_bay_decal`
),
tich_luy_osla AS (
  SELECT 
makhdms as ma_kh,
ds_tichluy_thuong_sp,
gia_tri_thuong,
'Tích lũy Osla' AS ten_chuong_trinh
FROM `spatial-vision-343005.warehouse.view_tich_luy_osla_t5_2026`
)

SELECT
a.*,
b.custname,
b.statedescr,
b.districtdescr,
b.wardname,
b.channel,
b.shoptype,
b.classid,
b.businessscope,
EXTRACT(MONTH FROM crtd_datetime) as thang_mo_code,
EXTRACT(YEAR FROM crtd_datetime) as nam_mo_code,
s.doanh_so_quy,
s.doanh_so_thang_truoc,
concat(
    "https://ds.merapgroup.com/reportscreen/142?params=%7B%22df50%22:%22include%25EE%2580%25800%25EE%2580%2580IN%25EE%2580%2580MR0000%22,%22df26%22:%22include%25EE%2580%25800%25EE%2580%2580IN%25EE%2580%2580", 
    a.ma_kh, 
    "%257C", 
    -- Tự động chuyển đổi khoảng trắng thành %2520 theo chuẩn double encode của hệ thống
    REGEXP_REPLACE(b.custname, r' ', '%2520'), 
    "%22%7D"
) as link_cong_no,
'https://ds.merapgroup.com/reportscreen/38' AS link_lich_su_mua_hang,

NULLIF(
    ARRAY_TO_STRING(
      [l.ten_chuong_trinh, e.ten_chuong_trinh, d.ten_chuong_trinh, o.ten_chuong_trinh], 
      ', '
    ), 
    ''
  ) AS cac_chuong_trinh_tham_gia,
-- 1. THÔNG TIN LOYALTY TP
  l.dk_doanh_so_quy AS lty_muc_dk_quy,
  l.tong_dsth_hien_tai AS lty_dsth_quy,
  l.ds_luy_ke_hien_tai AS lty_ds_luy_ke,
  IF(l.ma_kh IS NOT NULL, 'https://ds.merapgroup.com/reportscreen/2', NULL) AS link_chi_tiet_loyalty,

  -- 2. THÔNG TIN TRƯNG BÀY EBYSTA
  e.muc_dk_sl_ebysta AS ebysta_muc_dk,
  e.soluong_quy_hien_tai_ebysta AS ebysta_soluong_quy,
  e.xet_sl_quy_hien_tai_ebysta AS ebysta_ket_qua_quy,
  IF(e.ma_kh IS NOT NULL, 'https://ds.merapgroup.com/reportscreen/2', NULL) AS link_chi_tiet_ebysta,

  -- 3. THÔNG TIN TRƯNG BÀY DECAL
  d.ds_quy_hien_tai AS decal_ds_quy,
  d.xet_sl_quy_hien_tai AS decal_ket_qua_quy,
  IF(d.ma_kh IS NOT NULL, 'https://ds.merapgroup.com/reportscreen/2', NULL) AS link_chi_tiet_decal,

  -- 4. THÔNG TIN TÍCH LŨY OSLA
  o.ds_tichluy_thuong_sp AS osla_total_doanh_so,
  o.gia_tri_thuong AS osla_thanh_tien_km,
  IF(o.ma_kh IS NOT NULL, 'https://ds.merapgroup.com/reportscreen/2', NULL) AS link_chi_tiet_osla
FROM dskh_tham_gia_final a
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` b ON b.custid = a.ma_kh
LEFT JOIN raw_sales s ON a.ma_kh = s.ma_kh
LEFT JOIN loyalty_tp l ON a.ma_kh = l.ma_kh
LEFT JOIN trung_bay_ebysta e ON a.ma_kh = e.ma_kh
LEFT JOIN trung_bay_decal d ON a.ma_kh = d.ma_kh
LEFT JOIN tich_luy_osla o ON a.ma_kh = o.ma_kh
--WHERE COALESCE(l.ma_kh, e.ma_kh, d.ma_kh, o.ma_kh) IS NOT NULL;





;