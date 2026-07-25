CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_trich_lap_du_phong_du_no_real()
BEGIN 
 
TRUNCATE TABLE `staging_temp.f_trich_lap_du_phong_du_no_real_temp`;
INSERT INTO `staging_temp.f_trich_lap_du_phong_du_no_real_temp`

(
/* 
Create table staging_temp.f_trich_lap_du_phong_du_no_real_temp
partition by thang
cluster by ma_csm,ma_ge_vat,so_don_hang,so_hd
as
*/

/* BƯỚC 1: XÂY DỰNG MAPPING TUYẾN BÁN HÀNG VÀ NHÂN SỰ (CRS MAPPING) */
WITH

/* Mục đích: Xác định danh sách tuyến bán hàng DMS mới nhất cho từng khách hàng.
   
   Điều kiện lọc: 
   - Loại bỏ các tuyến đã bị xóa (delroutedet is false).
   - Chỉ lấy dữ liệu thuộc quản lý vùng 'Nguyễn Thọ Chiến'.
   - Ưu tiên RouteType (B, D -> 1, Khác -> 2) và thời gian tạo mới nhất.
*/
-- tuyen_dms_moinhat AS (
--     WITH data_tuyen AS (
--         SELECT 
--             custid,
--             slsperid,
--             crtd_datetime,
--             CASE WHEN routetype IN ('B', 'D') THEN 1 ELSE 2 END AS routetype
--         FROM `spatial-vision-343005.staging.sync_dms_srm` a
--         LEFT JOIN `staging.d_users` b ON a.slsperid = b.manv
--         WHERE 
--             delroutedet IS FALSE
--             AND b.tenquanlyvung = 'Nguyễn Thọ Chiến'
--     )
--     SELECT 
--         custid,
--         slsperid
--     FROM data_tuyen
--     QUALIFY ROW_NUMBER() OVER (PARTITION BY custid ORDER BY routetype ASC, crtd_datetime DESC) = 1
-- ),

-- /* Mục đích: Lấy lịch sử tuyến bán hàng DMS theo thời gian (Tháng).
   
--    Điều kiện lọc: 
--    - Tương tự như 'tuyen_dms_moinhat' nhưng có thêm yếu tố thời gian (Tháng).
--    - Quản lý vùng: 'Nguyễn Thọ Chiến'.
-- */
-- tuyen_dms_bytime AS (
--     WITH data_tuyen AS (
--         SELECT 
--             custid,
--             slsperid,
--             crtd_datetime,
--             thang,
--             CASE WHEN routetype IN ('B', 'D') THEN 1 ELSE 2 END AS routetype
--         FROM `spatial-vision-343005.staging.sync_dms_srm_bytime` a
--         LEFT JOIN `staging.d_users` b ON a.slsperid = b.manv
--         WHERE 
--             delroutedet IS FALSE
--             AND b.tenquanlyvung = 'Nguyễn Thọ Chiến'
--     )
--     SELECT 
--         custid,
--         slsperid
--     FROM data_tuyen
--     QUALIFY ROW_NUMBER() OVER (PARTITION BY custid ORDER BY thang DESC, routetype ASC, crtd_datetime DESC) = 1
-- ),

-- /* Mục đích: Xác định nhân viên phụ trách hợp đồng mới nhất (Contract Detail).
   
--    Điều kiện lọc: 
--    - Loại trừ các mã nhân viên đặc biệt (GH001, QUYNHPTA, MA001, MA002).
--    - Chỉ lấy quản lý vùng 'Nguyễn Thọ Chiến'.
--    - Loại bỏ hóa đơn bắt đầu bằng 'V'.
-- */
-- tuyen_cvbh_hd_moinhat AS (
--     SELECT 
--         custid,
--         slsperid
--     FROM `spatial-vision-343005.staging.d_get_contract_det` a
--     LEFT JOIN `staging.d_users` b ON a.slsperid = b.manv
--     WHERE 
--         slsperid NOT IN ('GH001', 'QUYNHPTA', 'MA001', 'MA002')
--         AND b.tenquanlyvung = 'Nguyễn Thọ Chiến'
--         AND LEFT(invtid, 1) <> 'V'
--     QUALIFY ROW_NUMBER() OVER (PARTITION BY custid ORDER BY CAST(crtd_date AS DATE) DESC) = 1
-- ),

-- /* Mục đích: Lấy lịch sử phụ trách hợp đồng theo thời gian.
   
--    Điều kiện lọc: 
--    - Tương tự 'tuyen_cvbh_hd_moinhat'.
--    - Ưu tiên sắp xếp theo tháng và ngày tạo giảm dần.
-- */
-- tuyen_cvbh_hd_bytime AS (
--     SELECT 
--         custid,
--         slsperid
--     FROM `spatial-vision-343005.staging.d_get_contract_det_bytime` a
--     LEFT JOIN `staging.d_users` b ON a.slsperid = b.manv
--     WHERE 
--         slsperid NOT IN ('GH001', 'QUYNHPTA', 'MA001', 'MA002')
--         AND b.tenquanlyvung = 'Nguyễn Thọ Chiến'
--         AND LEFT(invtid, 1) <> 'V'
--     QUALIFY ROW_NUMBER() OVER (PARTITION BY custid ORDER BY thang DESC, CAST(crtd_date AS DATE) DESC) = 1
-- ),

-- /* Mục đích: Hợp nhất các nguồn mapping (DMS và Hợp đồng) và gán nhãn loại dữ liệu.
-- */
-- mapping_mcp_hd AS (
--     SELECT *, 1 AS datatype FROM tuyen_dms_moinhat
--     UNION DISTINCT
--     SELECT *, 3 AS datatype FROM tuyen_dms_bytime
--     UNION DISTINCT
--     SELECT *, 2 AS datatype FROM tuyen_cvbh_hd_moinhat
-- ),

-- /* Mục đích: Lấy thông tin lịch sử hợp đồng gốc (Original Contract).
   
--    Điều kiện lọc: 
--    - Join giữa chi tiết hợp đồng và hợp đồng gốc.
--    - Chỉ lấy quản lý vùng 'Nguyễn Thọ Chiến'.
-- */
-- tuyen_cvbh_hd_lichsu AS (
--     SELECT 
--         b.custid,
--         a.slsperid
--     FROM `spatial-vision-343005.staging.d_oricontractdet` a
--     INNER JOIN `spatial-vision-343005.staging.d_oricontract` b ON a.contractid = b.contractid
--     LEFT JOIN `staging.d_users` c ON c.manv = a.slsperid
--     WHERE c.tenquanlyvung = 'Nguyễn Thọ Chiến'
--     QUALIFY ROW_NUMBER() OVER (PARTITION BY custid ORDER BY genlupd_datetime DESC) = 1
-- ),

-- /* Mục đích: Gom nhóm tất cả các nguồn mapping Sales-Customer vào một bảng tạm.
-- */
-- result_mapping_crs0 AS (
--     SELECT custid, slsperid, datatype
--     FROM mapping_mcp_hd
--     UNION ALL
--     SELECT custid, slsperid, 6 AS datatype
--     FROM tuyen_cvbh_hd_lichsu
--     UNION ALL
--     SELECT makhdms, manv, 5 AS datatype
--     FROM `staging.d_phutrachno_hcp_v2`
-- ),

-- /* Mục đích: Chọn ra mapping duy nhất tốt nhất cho mỗi khách hàng (Final Sales Mapping).
   
--    Điều kiện lọc: 
--    - Ưu tiên theo thứ tự datatype (số nhỏ ưu tiên cao hơn).
-- */
-- result_mapping_crs AS (
--     SELECT * FROM result_mapping_crs0
--     QUALIFY ROW_NUMBER() OVER (PARTITION BY custid ORDER BY datatype) = 1
-- ),

-- /* Mục đích: Gắn thông tin cấp quản lý (Supervisor, ASM, RSM) vào mapping đã chọn.
   
--    Điều kiện lọc: 
--    - Xử lý đặc biệt cho SupID chứa 'MR1681' (gán về MR1579 hoặc Nguyễn Toàn).
--    - Ưu tiên bản ghi đầu tiên theo SupID.
-- */
-- mapping_qltt AS (
--     SELECT 
--         custid,
--         slsperid,
--         a.datatype,
--         b.tencvbh,
--         CASE WHEN b.supid LIKE '%MR1681%' THEN 'MR1579' ELSE b.supid END AS supid,
--         CASE WHEN b.supid LIKE '%MR1681%' THEN 'Nguyễn Toàn' ELSE b.tenquanlytt END AS tenquanlytt,
--         b.tenquanlykhuvuc,
--         b.tenquanlyvung,
--         b.asm,
--         b.rsmid
--     FROM result_mapping_crs a
--     LEFT JOIN `staging.d_users` b ON a.slsperid = b.manv
--     QUALIFY ROW_NUMBER() OVER (PARTITION BY custid ORDER BY b.supid) = 1
-- ),

/* BƯỚC 2: XỬ LÝ NGHIỆP VỤ THU HỒI VÀ HỢP ĐỒNG ĐẶC THÙ */

/* Mục đích: Xác định thời điểm thu hồi chứng chỉ hành nghề mới nhất.
   
   Điều kiện lọc: 
   - Sắp xếp giảm dần theo năm và tháng để lấy mốc thời gian gần nhất.
*/
max_thu_hoi_dccn AS (
    SELECT namdccn, thangdccn 
    FROM `spatial-vision-343005.warehouse. view_thuhoi_dccn_kt`
    QUALIFY ROW_NUMBER() OVER(ORDER BY namdccn DESC, thangdccn DESC) = 1
),

/* Mục đích: Danh sách khách hàng bị thu hồi dược chứng chỉ hành nghề.
   
   Điều kiện lọc: 
   - Chỉ lấy các bản ghi có ngày thu hồi (ngaythuhoi is not null).
   - Khớp với mốc thời gian mới nhất từ CTE 'max_thu_hoi_dccn'.
*/
thu_hoi_dccn AS (
    SELECT DISTINCT 
        makhcu,
        phaply,
        makhthue 
    FROM `spatial-vision-343005.warehouse. view_thuhoi_dccn_kt` a
    JOIN max_thu_hoi_dccn b ON b.namdccn = a.namdccn AND a.thangdccn = b.thangdccn
    WHERE ngaythuhoi IS NOT NULL
),

/* Mục đích: Xác định hợp đồng bị thu hồi thủ công kênh CLC/PCL.
   
   Điều kiện lọc: 
   - Có ngày thu hồi (ngay_thu_hoi is not null).
   - Lấy bản ghi mới nhất theo ngày thu hồi cho từng khách hàng và kỳ hợp đồng.
*/
hop_dong_clc_pcl AS (
    SELECT 
        a.ma_kh AS custid,
        so_hop_dong,
        DATE(a.ngay_het_hl_theo_hop_dong) AS ngay_het_hieu_luc_theo_hd,
        DATE(ngay_hl_theo_hop_dong) AS ngay_hl_theo_hop_dong
    FROM `spatial-vision-343005.staging.d_manual_clc_thu_hoi_hop_dong` a
    LEFT JOIN `staging.d_master_khachhang` b ON a.ma_kh = b.custid
    WHERE ngay_thu_hoi IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ma_kh, ngay_hl_theo_hop_dong, ngay_het_hl_theo_hop_dong ORDER BY ngay_thu_hoi DESC) = 1
),

/* Mục đích: Liên kết đơn hàng bán với các hợp đồng bị thu hồi kênh CLC. 
    Điều kiện lọc: 
   - Lấy bản ghi mới nhất theo ngày thu hồi
*/
don_hang_thu_hoi_clc AS (
    SELECT 
        a.sodondathang,
        a.hoadon,
        c.custid,
        c.so_hop_dong,
        d.contractnbr AS so_hop_dong_dms
    FROM hop_dong_clc_pcl c
    JOIN `staging.f_sales` a ON a.makhdms = c.custid AND DATE(a.ngaychungtu) BETWEEN c.ngay_hl_theo_hop_dong AND c.ngay_het_hieu_luc_theo_hd
    JOIN `staging.sync_dms_so` b ON b.ordernbr = a.mahd AND b.branchid = a.macongtycn
    JOIN `spatial-vision-343005.staging.d_oricontract` d ON CAST(d.contractid AS STRING) = b.contractid
    QUALIFY ROW_NUMBER() OVER (PARTITION BY sodondathang, hoadon, c.custid ORDER BY ngay_hl_theo_hop_dong, ngay_het_hieu_luc_theo_hd) = 1
),

/* Mục đích: Xác định hợp đồng bị thu hồi kênh INS (Bảo hiểm/Viện).
   
   Điều kiện lọc: 
   - Lấy bản ghi mới nhất theo ngày thu hồi.
*/
thu_hoi_ins AS (
    SELECT 
        ma_kh,
        so_hop_dong
    FROM `spatial-vision-343005.staging.d_manual_ins_thu_hoi_hop_dong` a
    WHERE ngay_thu_hoi IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ma_kh, so_hop_dong ORDER BY ngay_thu_hoi DESC) = 1
),

/* Mục đích: Xác định hợp đồng bị thu hồi kênh MT/TP (Modern Trade).
   
   Điều kiện lọc: 
   - Xử lý ngày kết thúc: nếu NULL thì lấy ngày bắt đầu (logic nghiệp vụ đặc thù).
*/
thu_hoi_mt_tp AS (
    SELECT 
        makhnbcsm,
        sohopdongsophuluc,
        tungayddmmyyyy,
        CASE WHEN denngayddmmyyyy IS NULL THEN tungayddmmyyyy ELSE denngayddmmyyyy END AS denngayddmmyyyy
    FROM staging.d_manual_tp_mt_thu_hoi_hop_dong
    WHERE ngaynhanddmmyyyy IS NOT NULL
    QUALIFY ROW_NUMBER() OVER(PARTITION BY makhnbcsm, tungayddmmyyyy ORDER BY ngaynhanddmmyyyy DESC) = 1
),

/* BƯỚC 3: CHUẨN BỊ DỮ LIỆU CÔNG NỢ VÀ HẠN THANH TOÁN */

/* Mục đích: Tính toán số dư chứng từ theo hợp đồng (Dữ liệu thô).
*/
lay_ra_so_hd AS (
    SELECT 
        a.ordnbr,
        a.invcnbr,
        a.custid,
        d.contractnbr,
        SUM(so_du_chungtu) AS so_du_chungtu
    FROM `staging_temp.d_rawdata_debt` a
    LEFT JOIN `staging.sync_dms_so` b ON a.branchid = b.branchid AND a.mahd_so = b.ordernbr
    JOIN `staging.d_master_khachhang` c ON a.custid = c.custid AND c.channel = 'INS'
    JOIN `spatial-vision-343005.staging.d_oricontract` d ON CAST(d.contractid AS STRING) = b.contractid
    GROUP BY 1, 2, 3, 4
),

/* Mục đích: Chuẩn hóa hình thức thanh toán và xác định ngày đến hạn.
   
   Điều kiện lọc: 
   - Chỉ lấy các bản ghi có số hóa đơn (invcnbr is not null).
*/
ngay_den_han AS (
    SELECT 
        custid,
        ordnbr,
        InvcNbr,
        CASE 
            WHEN a.paymentsform = 'A' THEN 'Chuyển Khoản'
            WHEN a.paymentsform = 'B' THEN 'Tiền Mặt'
            WHEN a.paymentsform = 'C' THEN 'Tiền Mặt/Chuyển Khoản'
            WHEN a.paymentsform = 'D' THEN 'Ghi Nợ'
            WHEN a.paymentsform = 'E' THEN 'TM/CK/CTH'
            WHEN a.paymentsform = 'F' THEN 'Cấn Trừ Nợ'
            ELSE a.paymentsform 
        END AS hinhthucthanhtoan,
        terms,
        MIN(dateoforder) AS dateoforder,
        MIN(duedate) AS duedate,
        SUM(so_du_chungtu) AS so_du_chungtu
    FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` a
    WHERE invcnbr IS NOT NULL
    GROUP BY 1, 2, 3, 4, 5
),

/* BƯỚC 4: HỢP NHẤT DỮ LIỆU CÔNG NỢ VÀ THÔNG TIN KHÁCH HÀNG */

/* Mục đích: Bảng tổng hợp chính (Master) chứa thông tin nợ, khách hàng, nhân viên và các chỉ số tuổi nợ.
   
   Điều kiện lọc: 
   - Kênh bán hàng: INS, PCL, CLC.
   - Chỉ lấy khoản nợ dương (so_du_chungtu > 0).
   - Loại bỏ các khách hàng nội bộ/xuất quà biếu qua tên khách hàng.
*/
mapping_all AS (
    SELECT
        DATE(DATE_TRUNC(CURRENT_DATE("+7"), MONTH)) AS thang,
        a.custid AS ma_ge_khnb,
        a.custid AS ma_csm,
        b.custname AS dtcn_noi_bo,
        b.custname AS dtcn_noi_bo_ori,
        b.custidinvoice AS ma_ge_vat,
        b.custnameinvoice AS ten_khach_hang_thue,
        b.custnameinvoice AS ten_khach_hang_thue_ori,
        b.statedescr,
        b.shortterritorydescr,
        b.channel,
        b.shoptype,
        b.hcotypeid,
        b.branchid,
        a.ordnbr AS so_don_hang,
        a.invcnbr AS so_hd,
        CONCAT(IFNULL(a.ordnbr, ''), '-', a.invcnbr) AS ma_dh_hd,
        DATE(a.dateoforder) AS ngay_hoa_don,
        a.so_du_chungtu AS du_cuoi_ky_no,
        0 AS du_cuoi_ky_co,
        a.branchid AS pnql,
        b.shoptype AS kenh_phu,
        c.descr AS terms,
        b.paymentsform AS hinhthucthanhtoan,
        c.dueintnv AS thoi_han_no,
        a.duedate AS ngay_den_han,
        DATE_DIFF(DATE(CURRENT_DATE("+7")), DATE(a.dateoforder), DAY) - c.dueintnv AS ngay_tinh_tldp,
        DATE_DIFF(DATE(DATE(DATE_TRUNC(CURRENT_DATE("+7"), MONTH)) + INTERVAL 1 MONTH - INTERVAL 1 DAY), DATE(a.dateoforder), DAY) - c.dueintnv AS ngay_tinh_tldp_2,
        DATE_DIFF(DATE(DATE(DATE_TRUNC(CURRENT_DATE("+7"), MONTH)) + INTERVAL 2 MONTH - INTERVAL 1 DAY), DATE(a.dateoforder), DAY) - c.dueintnv AS ngay_tinh_tldp_3,
        DATE_DIFF(DATE(DATE(DATE_TRUNC(CURRENT_DATE("+7"), MONTH)) + INTERVAL 3 MONTH - INTERVAL 1 DAY), DATE(a.dateoforder), DAY) - c.dueintnv AS ngay_tinh_tldp_4,
        e.tongtrich2023,
        NULL AS tinh_trang_thu_hoi_bbgh,
        NULL AS tinh_trang_thu_hoi_hd,
        NULL AS tinh_trang_thu_hoi_dccn,
        NULL AS phan_loai_trich_lap,
        NULL AS so_hop_dong,
        NULL AS so_hop_dong_dms,
        NULL AS check_khoi_kien,
        CASE 
            WHEN b.statedescr IN ('Thành phố Cần Thơ', 'Đồng Nai', 'Khánh Hòa', 'Nghệ An', 'Thành phố Đà Nẵng', 'Thành phố Hà Nội', 'Thành phố Hồ Chí Minh') THEN 'VP chi nhánh'
            ELSE 'Tỉnh' 
        END AS is_diadiem,
        -- CASE 
        --     WHEN b.channel IN ('CLC', 'PCL', 'INS') AND b.statedescr = 'Đồng Nai' AND b.districtdescr IN ('Thành phố Biên Hòa', 'Huyện Vĩnh Cửu', 'Huyện Nhơn Trạch', 'Huyện Trảng Bom', 'Huyện Long Thành', 'Huyện Thống Nhất') THEN 'MR1650'
        --     WHEN b.channel IN ('CLC', 'PCL', 'INS') AND b.statedescr = 'Đồng Nai' AND b.districtdescr IN ('Huyện Tân Phú', 'Thành phố Long Khánh', 'Huyện Định Quán', 'Huyện Xuân Lộc', 'Huyện Cẩm Mỹ') THEN 'MR0294'
        --     WHEN b.channel IN ('CLC', 'PCL', 'INS') AND b.statedescr NOT IN ('Đồng Nai', 'Thành phố Hồ Chí Minh') THEN o.macrm
        --     ELSE p.supid 
        -- END AS macrm
        o.supid as macrm
    FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` a
    LEFT JOIN `staging.d_master_khachhang` b ON a.custid = b.custid
    LEFT JOIN `staging.d_manual_terms_detail` c ON a.terms = c.termsid
    LEFT JOIN `spatial-vision-343005.staging.f_trich_lap_kt_2023` e ON a.InvcNbr = e.so_hd AND IFNULL(a.ordnbr, '') = IFNULL(e.so_don_hang, '') AND a.custid = e.ma_csm
    --LEFT JOIN `staging.d_phutrachno_hcp_crm_v2` o ON b.statedescr = o.tinh AND o.tinh NOT IN ('Đồng Nai', 'Thành phố Hồ Chí Minh')
    LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` o ON a.custid = o.custid
    --LEFT JOIN mapping_qltt p ON p.custid = a.custid
    WHERE 
        b.channel IN ('INS', 'PCL', 'CLC')
        AND so_du_chungtu > 0
        AND (LEFT(LOWER(b.custname), 5) <> 'xuất ' OR LOWER(b.custname) NOT LIKE '%anh sách%' OR LOWER(b.custname) NOT LIKE '%quà%')
),

/* BƯỚC 5: TÍNH TOÁN TRÍCH LẬP DỰ PHÒNG VÀ PHÂN LOẠI NHÓM NỢ */

/* Mục đích: Xác định các mốc thời gian cảnh báo nợ (Vàng, Đỏ, Đen) và tính toán giá trị trích lập.
*/
tinh_trich_lap_dp AS (
    SELECT 
        a.*,
        b.tencvbh AS ten_crm,
        CASE 
            WHEN thoi_han_no <= 3 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 1 DAY)
            WHEN thoi_han_no <= 3 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 3 DAY)
            WHEN terms IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 2 DAY)
            WHEN terms IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 4 DAY)
            WHEN thoi_han_no <= 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 2 DAY)
            WHEN thoi_han_no <= 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 4 DAY)
            WHEN thoi_han_no > 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 2 DAY)
            WHEN thoi_han_no > 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 4 DAY)
            ELSE NULL
        END AS thoi_diem_no_vang,

        CASE 
            WHEN thoi_han_no <= 3 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 6 DAY)
            WHEN thoi_han_no <= 3 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 8 DAY)
            WHEN terms IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 7 DAY)
            WHEN terms IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 9 DAY)
            WHEN thoi_han_no <= 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 17 DAY)
            WHEN thoi_han_no <= 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 19 DAY)
            WHEN thoi_han_no > 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 32 DAY)
            WHEN thoi_han_no > 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 34 DAY)
            ELSE NULL
        END AS thoi_diem_no_do,

        CASE 
            WHEN thoi_han_no <= 3 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 10 DAY)
            WHEN thoi_han_no <= 3 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 12 DAY)
            WHEN terms IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 11 DAY)
            WHEN terms IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 13 DAY)
            WHEN thoi_han_no <= 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 32 DAY)
            WHEN thoi_han_no <= 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 34 DAY)
            WHEN thoi_han_no > 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 62 DAY)
            WHEN thoi_han_no > 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(ngay_den_han), INTERVAL 64 DAY)
            ELSE NULL
        END AS thoi_diem_no_den,

        /*Thay đổi logic cho sales*/
        CASE WHEN ngay_tinh_tldp >= 181 AND ngay_tinh_tldp < 365 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS from_6_month_to_1_year_crm,
        CASE WHEN ngay_tinh_tldp >= 365 AND ngay_tinh_tldp < 365*2 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS from_1_year_to_2_year_crm,
        CASE WHEN ngay_tinh_tldp >= 365*2 AND ngay_tinh_tldp < 365*3 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS from_2_year_to_3_year_crm,
        CASE WHEN ngay_tinh_tldp >= 365*3 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS over_3_year_crm,

        CASE WHEN ngay_tinh_tldp_2 >= 181 AND ngay_tinh_tldp_2 < 365 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS from_6_month_to_1_year_2,
        CASE WHEN ngay_tinh_tldp_2 >= 365 AND ngay_tinh_tldp_2 < 365*2 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS from_1_year_to_2_year_2,
        CASE WHEN ngay_tinh_tldp_2 >= 365*2 AND ngay_tinh_tldp_2 < 365*3 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS from_2_year_to_3_year_2,
        CASE WHEN ngay_tinh_tldp_2 >= 365*3 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS over_3_year_2,

        CASE WHEN ngay_tinh_tldp_3 >= 181 AND ngay_tinh_tldp_3 < 365 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS from_6_month_to_1_year_3,
        CASE WHEN ngay_tinh_tldp_3 >= 365 AND ngay_tinh_tldp_3 < 365*2 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS from_1_year_to_2_year_3,
        CASE WHEN ngay_tinh_tldp_3 >= 365*2 AND ngay_tinh_tldp_3 < 365*3 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS from_2_year_to_3_year_3,
        CASE WHEN ngay_tinh_tldp_3 >= 365*3 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS over_3_year_3,

        CASE WHEN ngay_tinh_tldp_4 >= 181 AND ngay_tinh_tldp_4 < 365 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS from_6_month_to_1_year_4,
        CASE WHEN ngay_tinh_tldp_4 >= 365 AND ngay_tinh_tldp_4 < 365*2 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS from_1_year_to_2_year_4,
        CASE WHEN ngay_tinh_tldp_4 >= 365*2 AND ngay_tinh_tldp_4 < 365*3 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS from_2_year_to_3_year_4,
        CASE WHEN ngay_tinh_tldp_4 >= 365*3 THEN 100/100 * du_cuoi_ky_no ELSE 0 END AS over_3_year_4
    FROM mapping_all a
    LEFT JOIN `staging.d_users` b ON b.manv = a.macrm
),

/* Mục đích: Tổng hợp số liệu trích lập và gắn nhãn phân loại nợ (Xanh/Vàng/Đỏ/Đen).
*/
phan_loai_no AS (
    SELECT *,
        from_6_month_to_1_year_crm + from_1_year_to_2_year_crm + from_2_year_to_3_year_crm + over_3_year_crm AS tong_trich_hientai_crm,
        from_6_month_to_1_year_2 + from_1_year_to_2_year_2 + from_2_year_to_3_year_2 + over_3_year_2 AS tong_trich_hientai_2,
        from_6_month_to_1_year_3 + from_1_year_to_2_year_3 + from_2_year_to_3_year_3 + over_3_year_3 AS tong_trich_hientai_3,
        from_6_month_to_1_year_4 + from_1_year_to_2_year_4 + from_2_year_to_3_year_4 + over_3_year_4 AS tong_trich_hientai_4,
        CASE 
            WHEN DATE(CURRENT_DATE("+7")) >= thoi_diem_no_den AND du_cuoi_ky_no > 0 THEN 'Nợ đen'
            WHEN DATE(CURRENT_DATE("+7")) >= thoi_diem_no_do AND du_cuoi_ky_no > 0 THEN 'Nợ đỏ'
            WHEN DATE(CURRENT_DATE("+7")) >= thoi_diem_no_vang AND du_cuoi_ky_no > 0 THEN 'Nợ vàng'
            WHEN DATE(CURRENT_DATE("+7")) < thoi_diem_no_vang AND du_cuoi_ky_no > 0 THEN 'Nợ xanh'
            ELSE NULL 
        END AS phanloai_no
    FROM tinh_trich_lap_dp
),

/* Mục đích: Chia nhỏ dư nợ vào từng cột phân loại cụ thể (Bucketing).
*/
tinh_du_no AS (
    SELECT *,
        CASE WHEN phanloai_no = 'Nợ xanh' THEN du_cuoi_ky_no ELSE 0 END AS no_xanh,
        CASE WHEN phanloai_no = 'Nợ vàng' THEN du_cuoi_ky_no ELSE 0 END AS no_vang,
        CASE WHEN phanloai_no = 'Nợ đỏ' THEN du_cuoi_ky_no ELSE 0 END AS no_do,
        CASE WHEN phanloai_no = 'Nợ đen' THEN du_cuoi_ky_no ELSE 0 END AS no_den,
        CASE WHEN phanloai_no IN ('Nợ đỏ', 'Nợ đen') THEN du_cuoi_ky_no ELSE 0 END AS no_xau
    FROM phan_loai_no
),

/* BƯỚC 6: KẾT XUẤT DỮ LIỆU CUỐI CÙNG */

/* Mục đích: Hợp nhất dữ liệu tính toán tự động với dữ liệu nợ xấu trích lập thủ công.
*/
result AS (
    SELECT 
        *,
        0 AS noxautrichlap,
        CURRENT_DATETIME("+7") AS updated_at
    FROM tinh_du_no

    UNION ALL 

    SELECT
        DATE(thang) AS thang,
        NULL AS ma_ge_khnb,
        NULL AS custid,
        NULL AS dtcn_noi_bo,
        NULL AS dtcn_noi_bo_ori,
        NULL AS ma_ge_vat,
        NULL AS ten_khach_hang_thue,
        NULL AS ten_khach_hang_thue_ori,
        NULL AS statedescr,
        NULL AS shortterritorydescr,
        NULL AS channel,
        NULL AS shoptype,
        NULL AS hcotypeid,
        NULL AS branchid,
        NULL AS so_don_hang,
        NULL AS so_hd,
        NULL AS ma_dh_hd,
        NULL AS dateoforder,
        0 AS du_cuoi_ky_no,
        NULL AS du_cuoi_ky_co,
        NULL AS pnql,
        NULL AS kenh_phu,
        NULL AS terms,
        NULL AS hinhthucthanhtoan,
        NULL AS thoi_han_no,
        NULL AS ngay_den_han,
        NULL AS ngay_tinh_tldp,
        NULL AS ngay_tinh_tldp_2,
        NULL AS ngay_tinh_tldp_3,
        NULL AS ngay_tinh_tldp_4,
        0 AS tongtrich2023,
        NULL AS tinh_trang_thu_hoi_bbgh,
        NULL AS tinh_trang_thu_hoi_hd,
        NULL AS tinh_trang_thu_hoi_dccn,
        NULL AS phan_loai_trich_lap,
        NULL AS so_hop_dong,
        NULL AS so_hop_dong_dms,
        NULL AS check_khoi_kien,
        NULL AS is_diadiem,
        a.manv AS macrm,
        b.tencvbh AS ten_crm,
        NULL AS thoi_diem_no_vang,
        NULL AS thoi_diem_no_do,
        NULL AS thoi_diem_no_den,
        0 AS from_6_month_to_1_year_crm,
        0 AS from_1_year_to_2_year_crm,
        0 AS from_2_year_to_3_year_crm,
        0 AS over_3_year_crm,
        0 AS from_6_month_to_1_year_2,
        0 AS from_1_year_to_2_year_2,
        0 AS from_2_year_to_3_year_2,
        0 AS over_3_year_2,
        0 AS from_6_month_to_1_year_3,
        0 AS from_1_year_to_2_year_3,
        0 AS from_2_year_to_3_year_3,
        0 AS over_3_year_3,
        0 AS from_6_month_to_1_year_4,
        0 AS from_1_year_to_2_year_4,
        0 AS from_2_year_to_3_year_4,
        0 AS over_3_year_4,
        0 AS tong_trich_hientai_crm,
        0 AS tong_trich_hientai_2,
        0 AS tong_trich_hientai_3,
        0 AS tong_trich_hientai_4,
        NULL AS phanloai_no,
        0 AS no_xanh,
        0 AS no_vang,
        0 AS no_do,
        0 AS no_den,
        0 AS no_xau,
        noxautrichlap,
        CURRENT_DATETIME("+7") AS updated_at
    FROM `staging.d_no_xau_trich_lap_hcp` a 
    LEFT JOIN `staging.d_users` b ON a.manv = b.manv
)

SELECT * FROM result
);

Create or replace table `warehouse.f_trich_lap_du_phong_du_no_real`

copy `staging_temp.f_trich_lap_du_phong_du_no_real_temp`;

END;