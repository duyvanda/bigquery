CREATE VIEW `spatial-vision-343005.warehouse.view_bao_cao_tong_quan_crs_khach_hang_hcp`
AS WITH dskh_tham_gia AS (
        SELECT
            manv,
            tencvbh,
            supid,
            tenquanlytt,
            ma_khachhang AS ma_kh,
            tenkhachhang,
            thu,
            tinh,
            kenh,
            kenhphu
            --STRING_AGG(DISTINCT CAST(thu AS STRING), ', ' ORDER BY CAST(thu AS STRING)) AS thu_kh
        FROM
            `warehouse.f_thongtin_tuyen_mcp_tp_pcl` a
        WHERE
            active = 'Active'
            AND kenh in ('CLC','PCL','INS')
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
  tinh,
  kenh,
  kenhphu,
  STRING_AGG(DISTINCT CAST(thu AS STRING), ', ' ORDER BY CAST(thu AS STRING)) AS thu_kh
  FROM dskh_tham_gia
  GROUP BY  manv,
            tencvbh,
            supid,
            tenquanlytt,
            ma_kh,
            tenkhachhang,
            tinh,
            kenh,
            kenhphu

)
,raw_sales AS (
 SELECT
    makhdms AS ma_kh,
    -- 1. Doanh số tháng hiện tại
    SUM(CASE 
        WHEN DATE_TRUNC(DATE(ngaychungtu), MONTH) = DATE_TRUNC(CURRENT_DATE('Asia/Ho_Chi_Minh'), MONTH) 
        THEN doanhsochuavat 
        ELSE 0 
      END) AS doanh_so_thang_hien_tai,

    -- 2. Doanh số tháng trước
    SUM(CASE 
        WHEN DATE_TRUNC(DATE(ngaychungtu), MONTH) = DATE_TRUNC(DATE_SUB(CURRENT_DATE('Asia/Ho_Chi_Minh'), INTERVAL 1 MONTH), MONTH)
        THEN doanhsochuavat 
        ELSE 0 
      END) AS doanh_so_thang_truoc,
    'https://ds.merapgroup.com/reportscreen/21' as link_ls_mua_hang
FROM
    `staging_temp.f_sales_crs_lhq_bytime` a
WHERE
    a.crs_tuyenbanhang_trongmcp NOT IN ('Rural')
    AND makhdms IS NOT NULL
    AND makenhkh IN ('CLC','PCL','INS')
    -- ĐIỀU KIỆN WHERE MỚI: Lấy dữ liệu từ đầu tháng trước cho đến hết tháng hiện tại
    AND DATE(thang) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE('Asia/Ho_Chi_Minh'), INTERVAL 1 MONTH), MONTH)
    AND DATE(thang) < DATE_ADD(DATE_TRUNC(CURRENT_DATE('Asia/Ho_Chi_Minh'), MONTH), INTERVAL 1 MONTH)

GROUP BY
    makhdms
),
cong_no_kh AS (
SELECT  
    custid,
    --branchid,
    SUM(no_xau + no_xanh + no_vang) as tong_no,
    SUM(no_xau) as no_xau,
    'https://ds.merapgroup.com/reportscreen/13' as link_cong_no
FROM `spatial-vision-343005.warehouse.f_congno_hcp_crm`
GROUP BY ALL
),
ct_clc23 AS (
SELECT  
  makhdms,
  SUM(
    CASE EXTRACT(QUARTER FROM CURRENT_DATE())
      WHEN 1 THEN COALESCE(doanhsochuavat_q1, 0)
      WHEN 2 THEN COALESCE(doanhsochuavat_q2, 0)
      WHEN 3 THEN COALESCE(doanhsochuavat_q3, 0)
      WHEN 4 THEN COALESCE(doanhsochuavat, 0)
    END
  ) AS doanhsochuavat_quy_hientai,
  SUM(
    CASE EXTRACT(QUARTER FROM CURRENT_DATE())
      WHEN 1 THEN COALESCE(tong_tienthuong_clc12_q1, 0) + COALESCE(tong_tienthuong_clc3_q1, 0)
      WHEN 2 THEN COALESCE(tong_tienthuong_clc12_q2, 0) + COALESCE(tong_tienthuong_clc3_q2, 0)
      WHEN 3 THEN COALESCE(tong_tienthuong_clc12_q3, 0) + COALESCE(tong_tienthuong_clc3_q3, 0)
      WHEN 4 THEN COALESCE(tong_tienthuong_clc12, 0) + COALESCE(tong_tienthuong_clc3, 0)
    END
  ) AS tong_tienthuong_quy_hientai,
  'https://ds.merapgroup.com/reportscreen/2' as link_tich_luy_clc,
  'CLC 2 3' as ten_chuong_trinh

FROM `spatial-vision-343005.warehouse.view_chuongtrinh_clc123_2026`
GROUP BY ALL
),
tich_luy_pcl AS (
    SELECT  
ma_kh,
MAX(dk_doanh_so_quy) AS dk_doanh_so_quy,
SUM (CASE EXTRACT(QUARTER FROM CURRENT_DATE())
    WHEN 1 THEN tong_dsth_q1 
    WHEN 2 THEN tong_dsth_q2
    WHEN 3 THEN tong_dsth_q3
    WHEN 4 THEN tong_dsth_q4
    END
) AS tong_dsth_hien_tai,
SUM(    
CASE EXTRACT(QUARTER FROM CURRENT_DATE())
    WHEN 1 THEN ds_luy_ke_q1
    WHEN 2 THEN ds_luy_ke_q2
    WHEN 3 THEN ds_luy_ke_q3
    WHEN 4 THEN ds_luy_ke_q4
  END 
) AS ds_luy_ke_hien_tai,
SUM(
CASE EXTRACT(QUARTER FROM CURRENT_DATE())
    WHEN 1 THEN doanh_so_thieu_luy_ke_q1
    WHEN 2 THEN doanh_so_thieu_luy_ke_q2
    WHEN 3 THEN doanh_so_thieu_luy_ke_q3
    WHEN 4 THEN doanh_so_thieu_luy_ke_q4
  END 
) AS ds_thieu_luy_ke_hien_tai,
'https://ds.merapgroup.com/reportscreen/2' as link_tich_luy_pcl,
'Loyalty PCL' as ten_chuong_trinh
FROM `spatial-vision-343005.warehouse.view_theo_doi_loyalty_pcl_2026`
WHERE DATE(hieu_luc_hd_ket_thuc) >= CURRENT_DATE('Asia/Ho_Chi_Minh')
GROUP BY ALL
),
ct_commitment AS (
SELECT  
ma_kh,
SUM(tong_dso_cmm_2026) as tong_dso_cmm_2026,
MAX(hang_thanh_vien) as hang_thanh_vien,
MAX(phan_tram_thuong) AS phan_tram_thuong,
SUM(gia_tri_thuong) AS gia_tri_thuong,
'https://ds.merapgroup.com/reportscreen/73' AS link_ct_commitment,
'CT Commitment 2026' as ten_chuong_trinh
FROM `spatial-vision-343005.warehouse.view_ct_thuong_commitment_2026_by_users`
GROUP BY ALL
)
-- Thêm đoạn này vào cuối cùng đoạn code của bạn để hoàn thiện câu lệnh SELECT chính
SELECT 
    -- 1. Thông tin khách hàng và nhân viên (từ dskh_tham_gia_final)
    kh.*,
    NULLIF(
      ARRAY_TO_STRING(
        [clc.ten_chuong_trinh, pcl.ten_chuong_trinh, cmm.ten_chuong_trinh], 
        ', '
      ), 
      ''
    ) AS cac_chuong_trinh_tham_gia,

    -- 2. Dữ liệu Doanh số (từ raw_sales)
    COALESCE(sa.doanh_so_thang_hien_tai, 0) AS doanh_so_thang_hien_tai,
    COALESCE(sa.doanh_so_thang_truoc, 0) AS doanh_so_thang_truoc,
    sa.link_ls_mua_hang,

    -- 3. Dữ liệu Công nợ (từ cong_no_kh)
    COALESCE(cn.tong_no, 0) AS tong_no,
    COALESCE(cn.no_xau, 0) AS no_xau,
    cn.link_cong_no,

    -- 4. Chương trình CLC 2 3 (từ ct_clc23)
    COALESCE(clc.doanhsochuavat_quy_hientai, 0) AS clc_doanhsochuavat_quy_hientai,
    COALESCE(clc.tong_tienthuong_quy_hientai, 0) AS clc_tong_tienthuong_quy_hientai,
    clc.link_tich_luy_clc,

    -- 5. Chương trình Loyalty PCL (từ tich_luy_pcl)
    pcl.dk_doanh_so_quy AS pcl_dk_doanh_so_quy,
    COALESCE(pcl.tong_dsth_hien_tai, 0) AS pcl_tong_dsth_hien_tai,
    COALESCE(pcl.ds_luy_ke_hien_tai, 0) AS pcl_ds_luy_ke_hien_tai,
    COALESCE(pcl.ds_thieu_luy_ke_hien_tai, 0) AS pcl_ds_thieu_luy_ke_hien_tai,
    pcl.link_tich_luy_pcl,

    -- 6. Chương trình Commitment (từ ct_commitment)
    COALESCE(cmm.tong_dso_cmm_2026, 0) AS cmm_tong_dso_cmm_2026,
    cmm.hang_thanh_vien AS cmm_hang_thanh_vien,
    COALESCE(cmm.phan_tram_thuong, 0) AS cmm_phan_tram_thuong,
    COALESCE(cmm.gia_tri_thuong, 0) AS cmm_gia_tri_thuong,
    cmm.link_ct_commitment

FROM dskh_tham_gia_final kh

LEFT JOIN raw_sales sa 
    ON kh.ma_kh = sa.ma_kh

LEFT JOIN cong_no_kh cn 
    ON kh.ma_kh = cn.custid

LEFT JOIN ct_clc23 clc 
    ON kh.ma_kh = clc.makhdms

LEFT JOIN tich_luy_pcl pcl 
    ON kh.ma_kh = pcl.ma_kh

LEFT JOIN ct_commitment cmm 
    ON kh.ma_kh = cmm.ma_kh;




;