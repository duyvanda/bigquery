CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_thuongdoanhthu_hcp_detail()
BEGIN

TRUNCATE TABLE staging_temp.f_thuongdoanhthu_hcp_detail_temp;
INSERT INTO staging_temp.f_thuongdoanhthu_hcp_detail_temp(

WITH duedate AS (
        SELECT
            --branchid,
            ordnbr,
            InvcNbr,
            custid,
            terms,
            (dateoforder) AS dateoforder,
            (duedate) AS duedate
        FROM
            `staging_temp.d_rawdata_debt`
        WHERE
            invcnbr IS NOT NULL
            --GROUP BY ALL
        QUALIFY 
    ROW_NUMBER() OVER (
        PARTITION BY ordnbr, InvcNbr, custid -- Gom nhóm theo Đơn hàng, Hóa đơn và Khách hàng
        ORDER BY duedate ASC -- Sắp xếp để lấy ngày hạn thanh toán nhỏ nhất đưa lên đầu
    ) = 1
        
    ),

    data_doanhthu_ge AS (
        SELECT
            a.* EXCEPT(adjgdocdate),
            b.duedate,
            d.descr AS terms,
            DATE(adjgdocdate) AS ngaythu_ge,
            --b.branchid,
            d.dueintnv AS songay_thanhtoan,
            CASE
                WHEN c.statedescr IN ('Thành phố Hồ Chí Minh', 'Thành phố Đà Nẵng', 'Hưng Yên') then 'VP chi nhánh' 
                --('Thành phố Cần Thơ', 'Đồng Nai', 'Khánh Hòa', 'Nghệ An', 'Thành phố Đà Nẵng', 'Thành phố Hà Nội', 'Thành phố Hồ Chí Minh') 
                ELSE 'Tỉnh'
            END AS is_diadiem,
        FROM
            `staging.kt_adjust` AS a
        LEFT JOIN
            duedate AS b
            ON a.custid = b.custid
            AND a.invcnbr = b.InvcNbr
            AND b.ordnbr = a.ordernbr
        LEFT JOIN
            `staging.d_master_khachhang_bytime` AS c
            ON a.custid = c.custid
            AND DATE(c.thang) = DATE(DATE_TRUNC(adjgdocdate, MONTH))
        LEFT JOIN
            `staging.d_manual_terms_detail` AS d
            ON d.termsid = b.terms
        WHERE
            adjgdocdate >= '2024-01-01'
            AND c.channel IN ('INS', 'CLC')
            AND a.invcnbr IS NOT NULL

    ),

    mapping_mau_no AS (
        SELECT
            *,
            CASE
                WHEN terms LIKE '%Thu tiền ngay%'
                    AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 1 DAY)
                WHEN terms LIKE '%Thu tiền ngay%'
                    AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 3 DAY)
                WHEN terms IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 2 DAY)
                WHEN terms IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 4 DAY)
                WHEN songay_thanhtoan <= 15
                    AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 2 DAY)
                WHEN songay_thanhtoan <= 15
                    AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 4 DAY)
                WHEN songay_thanhtoan > 15
                    AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 2 DAY)
                WHEN songay_thanhtoan > 15
                    AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 4 DAY)
                ELSE NULL
            END AS thoi_diem_no_vang,

            CASE
                WHEN terms LIKE '%Thu tiền ngay%'
                    AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 6 DAY)
                WHEN terms LIKE '%Thu tiền ngay%'
                    AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 8 DAY)
                WHEN terms IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 7 DAY)
                WHEN terms IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 9 DAY)
                WHEN songay_thanhtoan <= 15
                    AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 17 DAY)
                WHEN songay_thanhtoan <= 15
                    AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 19 DAY)
                WHEN songay_thanhtoan > 15
                    AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 32 DAY)
                WHEN songay_thanhtoan > 15
                    AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 34 DAY)
                ELSE NULL
            END AS thoi_diem_no_do,

            CASE
                WHEN terms LIKE '%Thu tiền ngay%'
                    AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 10 DAY)
                WHEN terms LIKE '%Thu tiền ngay%'
                    AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 12 DAY)
                WHEN terms IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 11 DAY)
                WHEN terms IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 13 DAY)
                WHEN songay_thanhtoan <= 15
                    AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 32 DAY)
                WHEN songay_thanhtoan <= 15
                    AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 34 DAY)
                WHEN songay_thanhtoan > 15
                    AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 62 DAY)
                WHEN songay_thanhtoan > 15
                    AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 64 DAY)
                ELSE NULL
            END AS thoi_diem_no_den
        FROM
            data_doanhthu_ge
    ),

    result_0 AS (
        SELECT
            *,
            CASE
                WHEN DATE(ngaythu_ge) >= thoi_diem_no_den THEN 'Nợ đen'
                WHEN DATE(ngaythu_ge) < thoi_diem_no_den AND DATE(ngaythu_ge) >= thoi_diem_no_do THEN 'Nợ đỏ'
                WHEN DATE(ngaythu_ge) < thoi_diem_no_do AND DATE(ngaythu_ge) >= thoi_diem_no_vang THEN 'Nợ vàng'
                WHEN DATE(ngaythu_ge) < thoi_diem_no_vang THEN 'Nợ xanh'
                ELSE 'Nợ xanh'
            END AS phanloai_no,
            (SELECT MAX(inserted_at) FROM `staging_temp.d_rawdata_debt_detail` WHERE inserted_at IS NOT NULL) AS updated_at
        FROM
            mapping_mau_no AS b
    ),

    result1 AS (
        SELECT
            e.branchid,
            a.ordernbr,
            a.invcnbr,
            a.ngaythu_ge,
            a.docdate AS ngaychungtu,
            duedate,
            a.thoi_diem_no_vang,
            a.thoi_diem_no_do,
            a.thoi_diem_no_den,
            is_diadiem,
            a.custid,
            e.custname,
            e.channel,
            e.shoptype,
            e.statedescr,
            e.districtdescr,
            e.wardname,
            phanloai_no,
            cast(adjamt as INT64) AS doanhthu,
            a.terms,
            --b.supid as macrm,
            --b.tenquanlytt
            Case when b.supid is null then 'MR1137' 
            else  IFNULL(f.msnvcsmmoi, b.supid)
            end as macrm,
    Case when b.supid is null then 'Vũ Mừng' 
    else IFNULL(g.crm, b.tenquanlytt)
    end as tenquanlytt
            -- CASE
            --     WHEN e.statedescr = 'Đồng Nai' AND e.districtdescr IN ('Thành phố Biên Hòa', 'Huyện Vĩnh Cửu', 'Huyện Nhơn Trạch', 'Huyện Trảng Bom', 'Huyện Long Thành', 'Huyện Thống Nhất') THEN 'MR1650'
            --     WHEN e.statedescr = 'Đồng Nai' AND e.districtdescr IN ('Huyện Tân Phú', 'Thành phố Long Khánh', 'Huyện Định Quán', 'Huyện Xuân Lộc', 'Huyện Cẩm Mỹ') THEN 'MR0294'
            --     ELSE IFNULL(b.supid, b1.macrm)
            -- END AS macrm
        FROM
            result_0 AS a
        LEFT JOIN
            `staging.d_master_khachhang_bytime` AS e
            ON e.custid = a.custid
            AND DATE(DATE_TRUNC(ngaythu_ge, MONTH)) = DATE(e.thang)
        -- LEFT JOIN /*fix: không dùng bảng này nữa*/
        --     `staging.d_phutrachno_hcp_crm_v2_bytime` AS b1
        --     ON b1.tinh = e.statedescr
        --     AND b1.tinh NOT IN ('Đồng Nai', 'Thành phố Hồ Chí Minh')
        --     AND b1.thang = '2025-04-01'
        LEFT JOIN
            `spatial-vision-343005.warehouse.f_mapping_crs_bytime` AS b
            ON a.custid = b.custid
            AND DATE(DATE_TRUNC(a.ngaythu_ge, MONTH)) = date(b.thang)
            /*fix: join dữ liệu theo quý + kh => ra crm */
        LEFT JOIN `spatial-vision-343005.staging.d_manual_dia_ban_cong_no_hcp` g on g.ma_kh = e.custid
        LEFT JOIN (
    SELECT msnvcsmmoi, hovatenfullname
    FROM `spatial-vision-343005.staging.d_hr_dsns`
    WHERE phongdeptsummary = 'HCP'
        ) f ON f.hovatenfullname = g.crm
    ),
    result3 AS (
        SELECT
            *,
        CASE 
            WHEN macrm in ('MR0081_KN','MR1137_KN','MR1137','MR0081','KN1137') THEN 0

            -- 1. Áp dụng cho giai đoạn MỚI (Từ ngày 01/03/2026 trở đi)
            WHEN ngaythu_ge >= '2026-03-01' AND phanloai_no IN ('Nợ xanh', 'Nợ vàng') 
            THEN ROUND(doanhthu * 0.6 / 100, 1)
            WHEN ngaythu_ge >= '2026-03-01' AND phanloai_no IN ('Nợ đỏ', 'Nợ đen') 
            THEN ROUND(doanhthu * 0.5 / 100, 1)

            -- 2. Áp dụng cho giai đoạn CŨ (Trước ngày 01/03/2026)
            WHEN ngaythu_ge < '2026-03-01' AND phanloai_no = 'Nợ xanh' THEN ROUND(doanhthu * 0.7 / 100, 1)
            WHEN ngaythu_ge < '2026-03-01' AND phanloai_no = 'Nợ vàng' THEN ROUND(doanhthu * 0.6 / 100, 1)
            WHEN ngaythu_ge < '2026-03-01' AND phanloai_no = 'Nợ đỏ' THEN ROUND(doanhthu * 0.5 / 100, 1)
            WHEN ngaythu_ge < '2026-03-01' AND phanloai_no = 'Nợ đen' THEN ROUND(doanhthu * 0.4 / 100, 1)

            ELSE 0 
        END AS dinhmuc_thuong_crm,
           CASE
            -- 1. Áp dụng cho giai đoạn MỚI (Từ ngày 01/03/2026 trở đi)
            WHEN ngaythu_ge >= '2026-03-01' 
            --AND phanloai_no IN ('Nợ xanh', 'Nợ vàng', 'Nợ đỏ', 'Nợ đen') 
            THEN ROUND(doanhthu * 0.15 / 100, 1)

            -- 2. Áp dụng cho giai đoạn CŨ (Trước ngày 01/03/2026)
            WHEN ngaythu_ge < '2026-03-01' AND phanloai_no = 'Nợ xanh' THEN ROUND(doanhthu * 0.25 / 100, 1)
            WHEN ngaythu_ge < '2026-03-01' AND phanloai_no = 'Nợ vàng' THEN ROUND(doanhthu * 0.15 / 100, 1)
            WHEN ngaythu_ge < '2026-03-01' AND phanloai_no IN ('Nợ đỏ', 'Nợ đen') THEN ROUND(doanhthu * 0.1 / 100, 1)
            
            ELSE 0
        END AS dinhmuc_thuong_ncrd,
            TIMESTAMP(CURRENT_DATETIME("+7")) AS updated_at
        FROM
            result1
    )
SELECT
    *

FROM
    result3
--WHERE macrm IS NOT NULL

  );
Create or replace table `warehouse.f_thuongdoanhthu_hcp_detail`

copy `staging_temp.f_thuongdoanhthu_hcp_detail_temp`;

End;