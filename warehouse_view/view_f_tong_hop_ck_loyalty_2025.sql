CREATE VIEW `spatial-vision-343005.warehouse.view_f_tong_hop_ck_loyalty_2025`
AS WITH delivery_status AS (
    -- 1. Lấy danh sách đơn hàng giao thành công (theo logic bạn cung cấp)
    SELECT DISTINCT 
        ordernbr
    FROM `spatial-vision-343005.staging.sync_dms_dv`
    WHERE delivery_date IS NOT NULL 
      AND status = 'C'
),

customer_info AS (
    -- 2. Lấy thông tin khách hàng
    SELECT 
        custid, 
        custname
    FROM `spatial-vision-343005.staging.d_master_khachhang`
)

, sales_apply AS (
    SELECT
        custid,
        invcnote,
        invcnbr,
        SUM(IFNULL(docbal, 0)) AS total_docbal,
        
        -- [CẬP NHẬT] Tính tổng các applyamt (Lưu ý cột 4, 5 phải ép kiểu từ STRING sang FLOAT)
        SUM(
            IFNULL(applyamt1, 0) +
            IFNULL(applyamt2, 0) +
            IFNULL(SAFE_CAST(applyamt3 AS FLOAT64), 0) +
            IFNULL(SAFE_CAST(applyamt4 AS FLOAT64), 0) +
            IFNULL(SAFE_CAST(applyamt5 AS FLOAT64), 0)
        ) AS total_applyamt,

        -- [CẬP NHẬT] Nối các mã đơn hàng từ 1 đến 5 (tự động loại bỏ NULL hoặc chuỗi rỗng)
        STRING_AGG(
            ARRAY_TO_STRING(
                ARRAY(
                    SELECT val 
                    FROM UNNEST([ordernbr1, ordernbr2, ordernbr3, ordernbr4, ordernbr5]) AS val 
                    WHERE val IS NOT NULL AND TRIM(val) != ''
                ), 
                ', '
            ),
            ', '
        ) AS applied_orders,

        -- [YÊU CẦU MỚI] Tính số tiền cần lên = currentloyalty - tổng các orderdocbal 1->5
        -- SUM(
        --     IFNULL(currentloyalty, 0) - (
        --         IFNULL(orderdocbal1, 0) +
        --         IFNULL(orderdocbal2, 0) +
        --         IFNULL(orderdocbal3, 0) +
        --         IFNULL(SAFE_CAST(orderdocbal4 AS FLOAT64), 0) +
        --         IFNULL(SAFE_CAST(orderdocbal5 AS FLOAT64), 0)
        --     )
        -- ) AS so_tien_can_phai_len


        -- [CẬP NHẬT CÔNG THỨC] Trả về số tiền thô dựa trên điều kiện hợp lệ của applyamt
        SUM(
            IFNULL(currentloyalty, 0) - (
                (CASE WHEN IFNULL(orderdocbal1, 0) != 0 OR IFNULL(orderdocbal1, 0) >= IFNULL(applyamt1, 0) THEN IFNULL(applyamt1, 0) ELSE 0 END) +
                (CASE WHEN IFNULL(orderdocbal2, 0) != 0 OR IFNULL(orderdocbal2, 0) >= IFNULL(applyamt2, 0) THEN IFNULL(applyamt2, 0) ELSE 0 END) +
                (CASE WHEN IFNULL(SAFE_CAST(orderdocbal3 AS FLOAT64), 0) != 0 OR IFNULL(SAFE_CAST(orderdocbal3 AS FLOAT64), 0) >= IFNULL(SAFE_CAST(applyamt3 AS FLOAT64), 0) THEN IFNULL(SAFE_CAST(applyamt3 AS FLOAT64), 0) ELSE 0 END) +
                (CASE WHEN IFNULL(SAFE_CAST(orderdocbal4 AS FLOAT64), 0) != 0 OR IFNULL(SAFE_CAST(orderdocbal4 AS FLOAT64), 0) >= IFNULL(SAFE_CAST(applyamt4 AS FLOAT64), 0) THEN IFNULL(SAFE_CAST(applyamt4 AS FLOAT64), 0) ELSE 0 END) +
                (CASE WHEN IFNULL(SAFE_CAST(orderdocbal5 AS FLOAT64), 0) != 0 OR IFNULL(SAFE_CAST(orderdocbal5 AS FLOAT64), 0) >= IFNULL(SAFE_CAST(applyamt5 AS FLOAT64), 0) THEN IFNULL(SAFE_CAST(applyamt5 AS FLOAT64), 0) ELSE 0 END)
            )
        ) AS so_tien_can_phai_len


    FROM `spatial-vision-343005.staging.f_tong_hop_ck_loyalty_2025_docbal`
    GROUP BY
        custid,
        invcnote,
        invcnbr
)

SELECT
    -- Thông tin khách hàng
    t.custid AS ma_kh,
    c.custname AS ten_kh,
    e.col.ma_nvbh,
    e.tencvbh,
    e.supid,
    e.tenquanlytt,

    -- Thông tin hóa đơn nguồn
    t.invcnbr AS so_hoa_don,
    t.invcnote AS so_seri, -- Mapping theo yêu cầu (invcnote -> so_seri)


-- [BỔ SUNG] Thông tin từ bảng sales_apply theo schema mới
    sa.total_docbal,
    sa.total_applyamt,
    sa.applied_orders,
    GREATEST(IFNULL(sa.so_tien_can_phai_len, 0), 0) AS so_tien_can_phai_len,

        -- Các cột yêu cầu để NULL
    NULL AS thu_hoi_bbgh,
    m.thu_hoi_bang_ke AS kt_thu_hoi_bang_ke_ck,
    m.chuyen_khoan,
    m.ghi_chu,
    m.kt_nhan_hinh_anh,

    -- Số tiền chiết khấu (Tổng adjust)
    AVG(t.origdocamt) AS so_tien_ck,

    -- Số tiền còn lại cần trừ công nợ (Logic: Ban đầu chính là số tiền CK)
    null AS so_tien_con_lai_can_tru_cong_no,

    -- Trạng thái giao hàng (Check trong CTE delivery_status)
    MIN(
    CASE 
        WHEN d.ordernbr IS NOT NULL THEN 'Giao hàng thành công' 
        ELSE 'Chưa giao/Không thành công' 
    END 
    )
    AS giao_hang_thanh_cong,



    -- Thông tin cấn trừ (Đã trừ)
    -- Nếu có adjinvcnbr thì coi như đã cấn trừ số tiền adjust đó
    SUM(t.adjust) AS so_tien_da_can_tru,
    
    -- Danh sách hóa đơn đã cấn trừ (Gộp nhiều hóa đơn cách nhau dấu phẩy)
    STRING_AGG(DISTINCT t.adjinvcnbr, ', ') AS hoa_don_da_can_tru,

    -- Số tiền còn lại (Tổng CK - Đã cấn trừ)
    AVG(t.origdocamt) - SUM(t.adjust) - SUM( ifnull(m.chuyen_khoan,0)) AS so_tien_con_lai

FROM `spatial-vision-343005.staging.f_tong_hop_ck_loyalty_2025` AS t
LEFT JOIN customer_info AS c
    ON t.custid = c.custid
LEFT JOIN delivery_status AS d 
    ON t.origordernbr = d.ordernbr -- Join theo Original Order Number
LEFT JOIN `warehouse.f_mapping_crs` e ON t.custid = e.custid

-- [CẬP NHẬT] Join bảng manual kiểm tra thu hồi bảng kê
LEFT JOIN `spatial-vision-343005.staging.d_manual_kt_thu_hoi_bang_ke_ck_2025_loyalty` AS m
    ON t.invcnbr = m.so_hd
    AND t.custid = m.ma_kh -- Join thêm mã KH để đảm bảo unique

-- [BỔ SUNG MỚI] Join bảng sales_apply dựa trên 3 keys
LEFT JOIN sales_apply AS sa
    ON t.custid = sa.custid
    AND t.invcnote = sa.invcnote
    AND t.invcnbr = sa.invcnbr

GROUP BY ALL
    ;