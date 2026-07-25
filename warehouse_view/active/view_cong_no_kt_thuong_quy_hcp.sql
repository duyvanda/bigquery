CREATE VIEW `spatial-vision-343005.warehouse.view_cong_no_kt_thuong_quy_hcp`
AS WITH rawdata_debt_unique AS (
    SELECT 
        Ordnbr,
        InvcNbr,
        custid,
        duedate,
        terms
    FROM `spatial-vision-343005.staging_temp.d_rawdata_debt`
    WHERE Ordnbr IS NOT NULL 
      AND InvcNbr IS NOT NULL
    /* Sắp xếp duedate ASC để ưu tiên lấy ngày đến hạn sớm nhất */
    QUALIFY ROW_NUMBER() OVER(PARTITION BY Ordnbr, InvcNbr ORDER BY duedate ASC) = 1
),

mapping_base AS (
    SELECT
        a.thang,
        a.ma_ge_khnb,
        a.ngay_hoa_don,
        a.du_cuoi_ky_no,
        a.so_don_hang,
        a.so_hd,
        b.duedate,
        b.terms AS terms_id,
        e.descr AS terms_desc,
        e.dueintnv AS day_terms,
        CASE 
        when b1.statedescr in ('Thành phố Hồ Chí Minh', 'Thành phố Đà Nẵng', 'Hưng Yên') then 'VP chi nhánh' Else 'Tỉnh'
        END AS is_diadiem
    FROM `spatial-vision-343005.staging.f_cong_no_kt` a
    LEFT JOIN rawdata_debt_unique b 
        ON a.so_don_hang = b.Ordnbr 
        AND a.so_hd = b.InvcNbr
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` b1 
        ON b.custid = b1.custid
    /* Bổ sung JOIN bảng terms để lấy thông tin điều khoản phục vụ tính các mốc ngày nợ */
    LEFT JOIN `spatial-vision-343005.staging.d_manual_terms_detail` e 
        ON e.termsid = b.terms
    LEFT JOIN `spatial-vision-343005.warehouse.dim_excluded_makhdms` f 
        ON a.ma_ge_khnb = f.makhdms
    WHERE IFNULL(a.ghi_chu,'none') NOT IN ('KH trong danh sách khởi kiện')
      AND (abs(a.du_cuoi_ky_no) > 1000 )
      AND b1.custid not like 'DS%'
      AND f.makhdms is null
      --AND a.thang = '2026-04-01'

)

--select SUM(du_cuoi_ky_no) from mapping_base


, mapping_milestones AS (
    SELECT 
        *,
        /* Tính mốc Nợ Vàng */
        CASE 
            WHEN terms_desc LIKE '%Thu tiền ngay%' AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 1 DAY)
            WHEN terms_desc LIKE '%Thu tiền ngay%' AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 3 DAY)
            WHEN terms_desc IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 2 DAY)
            WHEN terms_desc IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 4 DAY)
            WHEN day_terms <= 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 2 DAY)
            WHEN day_terms <= 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 4 DAY)
            WHEN day_terms > 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 2 DAY)
            WHEN day_terms > 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 4 DAY)
        END AS thoi_diem_no_vang,

        /* Tính mốc Nợ Đỏ */
        CASE 
            WHEN terms_desc LIKE '%Thu tiền ngay%' AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 6 DAY)
            WHEN terms_desc LIKE '%Thu tiền ngay%' AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 8 DAY)
            WHEN terms_desc IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 7 DAY)
            WHEN terms_desc IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 9 DAY)
            WHEN day_terms <= 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 17 DAY)
            WHEN day_terms <= 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 19 DAY)
            WHEN day_terms > 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 32 DAY)
            WHEN day_terms > 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 34 DAY)
        END AS thoi_diem_no_do,

        /* Tính mốc Nợ Đen */
        CASE 
            WHEN terms_desc LIKE '%Thu tiền ngay%' AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 10 DAY)
            WHEN terms_desc LIKE '%Thu tiền ngay%' AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 12 DAY)
            WHEN terms_desc IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 11 DAY)
            WHEN terms_desc IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 13 DAY)
            WHEN day_terms <= 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 32 DAY)
            WHEN day_terms <= 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 34 DAY)
            WHEN day_terms > 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 62 DAY)
            WHEN day_terms > 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 64 DAY)
        END AS thoi_diem_no_den
    FROM mapping_base
)
SELECT 
    a.*,
    b.col.ma_nvbh,
    b.tencvbh,
    IFNULL(b.supid,c.supid) as ma_crm,
    IFNULL(b.tenquanlytt,c.tenquanlytt) as tenquanlytt,
    IFNULL(b.asm,c.asm) as asm,
    IFNULL(b.tenquanlykhuvuc,c.tenquanlykhuvuc) as tenquanlykhuvuc,
   /* Đánh giá màu nợ tại thời điểm ngày cuối cùng của quý */
 CASE
        WHEN LAST_DAY(CAST(a.thang AS DATE)) >= thoi_diem_no_den THEN 'Nợ đen'
        WHEN LAST_DAY(CAST(a.thang AS DATE)) >= thoi_diem_no_do THEN 'Nợ đỏ'
        WHEN LAST_DAY(CAST(a.thang AS DATE)) >= thoi_diem_no_vang THEN 'Nợ vàng'
        ELSE 'Nợ xanh'
    END AS phanloai_no,

/* Cột nợ xấu: Lấy giá trị dư cuối kỳ nếu là nợ đỏ hoặc nợ đen */
    CASE
        WHEN LAST_DAY(CAST(a.thang AS DATE)) >= thoi_diem_no_den 
          OR LAST_DAY(CAST(a.thang AS DATE)) >= thoi_diem_no_do 
        THEN du_cuoi_ky_no 
        ELSE 0 
    END AS no_xau
FROM mapping_milestones a
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs_bytime` b on a.ma_ge_khnb = b.custid and date(b.thang) = date(a.thang)
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` c on a.ma_ge_khnb = c.custid
WHERE EXTRACT(MONTH FROM CAST(a.thang AS DATE)) IN (3,6,9,12)
        AND EXTRACT(YEAR FROM CAST(a.thang AS DATE)) >= 2026 
        --AND IFNULL(b.supid,c.supid) = 'MR0992'


;