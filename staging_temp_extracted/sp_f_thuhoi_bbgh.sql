-- ==========================================================================
-- Routine Name : sp_f_thuhoi_bbgh
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-07-31 10:13:26.661000+00:00
-- Last Altered : 2026-07-31 10:13:26.661000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_thuhoi_bbgh()
BEGIN

TRUNCATE TABLE staging_temp.f_thuhoi_bbgh_temp;

-- INSERT INTO `staging_temp.f_thuhoi_bbgh_temp`
-- (
Create or replace table staging_temp.f_thuhoi_bbgh_temp
partition by date(ngayhoadon)
cluster by sodonhang,sohoadon,macsm
as
(
/* =====================================================================================
DESCRIPTION: Truy vấn tổng hợp trạng thái đơn hàng, công nợ và biên bản thu hồi.
========================================================================================
*/

WITH

/* BƯỚC 1: LÀM SẠCH VÀ CHUẨN HÓA DỮ LIỆU NGUỒN (SOURCE DATA PREPARATION) */

/* Mục đích: Tổng hợp số dư công nợ và chuẩn hóa mã hóa đơn (InvcNbr) cho các trường hợp ngoại lệ.
   Điều kiện lọc: Chỉ lấy dữ liệu đơn hàng có ngày đặt (dateoforder) từ 01/01/2023 trở về sau. */
d_rawdata_debt as (
  select
  b.Ordnbr,
  terms,
  paymentsform,
  SUM(so_du_chungtu) as so_du_chungtu,
  Case
        when mahd_so ='HL0-0524-03555' then '00100860'
        when Ordnbr ='DL0-0124-03346' then '00045231'
        when Ordnbr ='DL0-0124-03345' then '00045229'
        when Ordnbr ='DL7-0624-01077' then '00135480'
        else ori_invcnbr
    end as InvcNbr,
  --dateoforder,so_du_chungtu,terms,orderdate,paymentsform
  from `spatial-vision-343005.staging_temp.d_rawdata_debt` b where dateoforder >= '2023-01-01'
  group by all
)

/*
dạ anh ơi , nhờ anh móc dùm e cái BBGH này với ạ: DL0-0626-01603-00087945 ( đã chụp NVC) vào DL0-0626-06105-00095304 ( trên BI đang có ạ) do Hóa đơn điều chỉnh cho hóa đơn gốc ạ
SELECT * FROM `spatial-vision-343005.staging.sync_dms_rd`
WHERE TIMESTAMP_TRUNC(crtd_datetime, DAY) >= TIMESTAMP("2026-06-01") and ordernbr = 'DL0-0626-01603'
SELECT này có data đơn DL0-0626-01603 có trong mã biên bản PBNH06202600043, nhưng đơn giao lại thì không có.
*/
, fix_sync_dms_rd as

(
SELECT reportid, branchid, ordernbr
FROM `spatial-vision-343005.staging.sync_dms_rd`
UNION ALL
SELECT 'PBNH06202600043' AS reportid, 'HCM001' AS branchid, ' DL0-0626-06105' AS ordernbr
)

/* Bảng tạm 1: Gộp dữ liệu từ 2 nguồn và gán độ ưu tiên */
, raw_upload_orc AS (
    SELECT
    DISTINCT
    b.custid,
    ifnull(b1.origordernbr, b.origordernbr) as origordernbr,
    b.invcnbr,
    b.branchid,
    a.manv,
    a.inserted_at,
    'x' AS ketoandanhan,
    CONCAT('https://bi.meraplion.com/DMS/kt_bbgh_proof/0_', b.invcnbr, '.jpeg') AS ocr_url,
    1 AS source_priority
    FROM
        `spatial-vision-343005.staging.sync_ocr_delivery_record` AS a
    LEFT JOIN
        `staging.sync_dms_so` AS b
        ON a.invoice_number = b.invcnbr
        AND a.invoice_symbol = b.invcnote
    /*invoice_number = '00025305' trong bảng SO sẽ ra mã HLxxx => phải lấy mã HL này lấy ra mã đơn thực tế tiếp*/
    LEFT JOIN
        `staging.sync_dms_so` AS b1
        ON b.origordernbr = b1.ordernbr
        AND b.branchid = b1.branchid
    UNION DISTINCT
    SELECT
    DISTINCT
    c.makhdms as custid,
    b.ordernbr as origordernbr,
    c.hoadon as invcnbr,
    a.ma_chi_nhanh as branchid,
    a.manv,
    a.inserted_at,
    'x' AS ketoandanhan,
    CONCAT('https://bi.meraplion.com/DMS/kt_bbgh_proof_nvc/0_', b.ordernbr, a.ma_chi_nhanh, '.jpeg') AS ocr_url,
    2 AS source_priority
    FROM `spatial-vision-343005.staging.sync_ocr_delivery_record_nvc` a
    LEFT JOIN `fix_sync_dms_rd` b on a.ma_chung_tu = b.reportid and a.ma_chi_nhanh = b.branchid
    LEFT JOIN `staging.f_sales` c on b.ordernbr = c.sodondathang and c.ngaychungtu>= '2026-03-01'
)
/* Bảng tạm 2: Lọc trùng, giữ nguyên tên upload_orc để các bước sau không bị lỗi */
, upload_orc AS (
    SELECT * EXCEPT(source_priority)
    FROM raw_upload_orc
    QUALIFY ROW_NUMBER() OVER(
        PARTITION BY origordernbr, invcnbr, branchid
        ORDER BY source_priority ASC, inserted_at DESC
    ) = 1
)

/* Mục đích: Truy xuất thông tin đơn hàng gốc (Original Order) từ hệ thống DMS và PDA để tham chiếu chéo.
   Điều kiện lọc: Đơn loại 'IR', ngày tạo từ 01/06/2025 (dự kiến/future date) và loại bỏ SalesOrderType rỗng. */
, hoa_don_goc as (
select
c.branchid,
c.OrigOrderNbr as Ir_OrigOrderNbr,
c.SalesOrderType,
c.InvcNbr,
c.InvcNote,
o.OrderNbr,
o.OrigOrderNbr,
sod.OrigOrderNbr as Ori_OrigOrderNbr,
sod.InvcNbr as ori_InvcNbr
FROM `staging.sync_dms_so` c
LEFT JOIN `staging.sync_dms_pda_so` o  on o.OrderNbr = c.OrigOrderNbr and o.BranchID = c.BranchID and cast (o.crtd_datetime as Date) >= '2025-06-01'
LEFT JOIN `staging.sync_dms_so` sod ON sod.OrderNbr=o.OrigOrderNbr AND sod.BranchID=o.BranchID and cast (sod.crtd_datetime as Date) >= '2025-06-01'
where c.SalesOrderType <> '' and c.OrderType = 'IR' and cast (c.crtd_datetime as Date) >= '2025-06-01'
)

/* BƯỚC 2: XÁC ĐỊNH ĐƠN HÀNG HỦY VÀ THÔNG TIN BỔ TRỢ */

/* Mục đích: Xác định danh sách các đơn hàng bị hủy hoặc trả lại dựa trên tổng doanh số <= 0.
   Điều kiện lọc: Ngày chứng từ >= 01/01/2024, có logic loại trừ riêng cho hàng Khuyến Mãi sau 11/2025. */
,donhuy as
(
SELECT
IFNULL(sodontrahang, sodondathang) as ma_dh_chung,
macongtycn,
IFNULL(hd.ori_InvcNbr,a.hoadon) as hoadon,
sum(doanhsochuavat) as ds_tong_hoa_don
FROM `spatial-vision-343005.staging.f_sales` a
LEFT JOIN hoa_don_goc hd on a.sodondathang = hd.Ir_OrigOrderNbr and a.macongtycn = hd.branchid and hd.InvcNbr = a.hoadon
where
true
AND date(ngaychungtu) >= '2024-01-01'
-- Loại ra các HD xuất riêng cho hàng KM
AND (Case
when a.doanhsochuavat = 0 and date(ngaychungtu) >= '2025-11-01' then FALSE else TRUE end)
group by 1,2,3
HAVING ds_tong_hoa_don <= 0
)

/* Mục đích: Lấy dữ liệu kiểm tra thông tin thu hồi biên bản từ form nhập liệu của nhân viên cụ thể.
   Điều kiện lọc: Chỉ lấy dữ liệu của user 'MR2662' và version '085839'. */
,thuhoi_bienban as
(
  select
    sodondathang,
    kt_da_nhan ,
    kh_ki_nhan_theo_mau_bb_giao_hang ,
    kh_ki_nhan_hang_tren_hoa_don ,
    p_manv ,
    p_version ,
    mds_da_ban_giao ,
    mds_phan_hoi ,
    mds_ghi_chu ,
    kt_ghi_chu
  from `spatial-vision-343005.staging.d_form_kt_thong_tin_thu_hoi_bb_theo_user`
  where p_manv ='MR2662' and p_version = '085839'
  -- p_manv = manv_p and p_version = version_p
)

/* Mục đích: Xác định ngày giao hàng thực tế và chuẩn hóa trạng thái giao hàng từ hệ thống Delivery (DV).
   Điều kiện lọc: Chỉ lấy đơn đã hoàn tất (Status = 'C'), fix cứng ngày giao cho đơn đặc thù 'DL7-1025-03343'.
*/
, NGAYGIAOHANG as
(
  select
  dv.crtd_datetime as crtd_datetime_dv,
  dv.branchid,
  dv.ordernbr,
  dv.status as status_dv,
  case when dv.ordernbr = 'DL7-1025-03343' then timestamp('2025-10-30 15:39:11')
  else dv.delivery_date end as delivery_date
  FROM `spatial-vision-343005.staging.sync_dms_dv` dv
  where dv.delivery_date IS NOT NULL AND dv.status = 'C'
)

/* BƯỚC 3: TỔNG HỢP DỮ LIỆU BÁN HÀNG CHI TIẾT (SALES CONSOLIDATION) */

/* Mục đích: Tổng hợp dữ liệu từ các nguồn thủ công (Manual) và bảng kê thu hồi biên bản cũ.
   Điều kiện lọc: Ngày chứng từ >= 01/01/2024, loại trừ chi nhánh 'DL0001'.
*/
,manual as
(
SELECT
    distinct
    a.macongtycn,
    cast(null as string) as magekhnb,
    makhdms as macsm,
    cast(null as string) as magevat,
    sodondathang as sodonhang,
    a.hoadon as sohoadon,
    ngaychungtu as ngayhoadon,
    null as ducuoikyno,
    ngaydatdon as ngaydonhang,
    cast(null as string) as pnql,
    null as chenhlech,
    manv as macsmbh,
    tencvbh as tennvbh,
    ifnull(a.manvghreal,a.manvgh) as macsmgh,
    concat(makenhphu,maphanloaihco) as kenhphanphoi,
    makenhphu as kenhphu,
    cast(null as string) as ktdanhan,
    cast(null as string) as nhan_bbgh,
    cast(null as string) as nhan_hdgh,
    mahd,
    a.kieudonhang,
    a.donvigiaohang,
    case

      when makenhkh = 'EXP' then 'Đã giao hàng'
      when kieudonhang in ('CO', 'IR') then 'Đã giao hàng'
      when IFNULL(c.delivery_date, b2.thoi_gian_xac_nhan_giao_hang) is null --abs(ds_tong_dh) > 0 and
      then 'Chưa giao hàng'
      else 'Đã giao hàng'
      end as trangthaigiaohang,
    SUM(a.doanhsocovat) OVER (PARTITION BY IFNULL(a.sodontrahang, a.sodondathang),a.hoadon) as doanhsocovat,
    a.masanpham,
    a.tensanphamnb,
    a.soluong
  FROM `spatial-vision-343005.staging.f_sales` a
  join `staging.d_kt_thuhoi_bbgh_2023` b on concat (trim(a.sodondathang),'-',a.hoadon) = b.noimadhsohoadon
  LEFT JOIN NGAYGIAOHANG c on a.sodondathang = c.ordernbr and a.macongtycn = c.branchid
  LEFT JOIN `staging.view_d_manual_data_nvc` b2 on b2.ma_dh = a.sodondathang
  where a.ngaychungtu >= '2024-01-01'--and concat (trim(a.sodondathang),'-',a.hoadon) in  (select noimadhsohoadon from `staging.d_kt_thuhoi_bbgh_2023`)
  and macongtycn not in ('DL0001')
)

/* Mục đích: Tạo danh sách đơn hủy phụ trợ (Secondary Cancelled List) để lọc kỹ hơn ở bước sau.
   Điều kiện lọc: Tổng doanh số đơn hàng <= 0, từ năm 2024.
*/
,
don_huy_2 as

(
select
IFNULL(a.sodontrahang, a.sodondathang) as ma_dh_chung,
macongtycn,
sum(doanhsochuavat) as ds_tong_dh
from staging.f_sales a
where date(ngaychungtu) >= '2024-01-01'
group by 1,2
having ds_tong_dh <= 0
)

/* Mục đích: Truy vấn dữ liệu bán hàng chính (Main Sales Flow), xử lý các trường hợp lệch hóa đơn và loại trừ đơn hủy.
   Điều kiện lọc: Kiểu đơn 'IN', loại trừ các đơn hủy (từ 2 nguồn donhuy & don_huy_2), loại trừ chi nhánh 'DL001'. */
,f_sale as
(
  SELECT
    distinct
    a.macongtycn,
    cast(null as string) as magekhnb,
    makhdms as macsm,
    cast(null as string) as magevat,
    a.sodondathang as sodonhang,
    Case
        when mahd ='HL0-0524-03555' then '00100860'
        when a.sodondathang ='DL0-0124-03346' then '00045231'
        when a.sodondathang ='DL0-0124-03345' then '00045229'
        when a.sodondathang ='DL7-0624-01077' then '00135480'
        else a.hoadon
    end as sohoadon, -- Hóa đơn điều chuyển do bảng sales k thay đổi hóa đơn, bị lệch vs GE
    Case
        when a.sodondathang ='DL0-0124-03346' then timestamp'2024-03-06'
        when a.sodondathang ='DL0-0124-03345' then timestamp'2024-03-06'
        when a.sodondathang ='DL7-0624-01077' then timestamp'2024-07-26'
        else a.ngaychungtu
    end as ngayhoadon,
    -- ngaychungtu as ngayhoadon,
    null as ducuoikyno,
    ngaydatdon as ngaydonhang,
    cast(null as string) as pnql,
    null as chenhlech,
    manv as macsmbh,
    tencvbh as tennvbh,
    coalesce(dc.manvghreal,a.manvghreal,a.manvgh) as macsmgh,
    concat(makenhphu,maphanloaihco) as kenhphanphoi,
    makenhphu as kenhphu,
    cast(null as string) as ktdanhan,
    cast(null as string) as nhan_bbgh,
    cast(null as string) as nhan_hdgh,
    mahd,
    a.kieudonhang,
    IFNULL(dc.donvigiaohang, a.donvigiaohang) as donvigiaohang,
    case

      when makenhkh = 'EXP' then 'Đã giao hàng'
      when kieudonhang in ('CO', 'IR') then 'Đã giao hàng'
      when IFNULL(e.delivery_date, b2.thoi_gian_xac_nhan_giao_hang) is null --abs(ds_tong_dh) > 0 and
      then 'Chưa giao hàng'
      else 'Đã giao hàng'
      end as trangthaigiaohang,
    SUM(a.doanhsocovat) OVER (PARTITION BY IFNULL(a.sodontrahang, a.sodondathang),a.hoadon) as doanhsocovat,
    masanpham,
    tensanphamnb,
    soluong
  FROM `spatial-vision-343005.staging.f_sales` a
  LEFT JOIN donhuy b on IFNULL(a.sodontrahang, a.sodondathang) = b.ma_dh_chung and a.hoadon = b.hoadon  and a.macongtycn = b.macongtycn
  LEFT JOIN don_huy_2 c on IFNULL(a.sodontrahang, a.sodondathang) = c.ma_dh_chung  and a.macongtycn = c.macongtycn
  LEFT JOIN `spatial-vision-343005.staging.d_dieuchinhmds` dc on IFNULL(a.sodontrahang, a.sodondathang) = dc.sodondathang
  LEFT JOIN NGAYGIAOHANG e on a.sodondathang = e.ordernbr and a.macongtycn = e.branchid
  LEFT JOIN `staging.view_d_manual_data_nvc` b2 on b2.ma_dh = a.sodondathang
  where
  b.hoadon is null
  and c.macongtycn is null
  and a.kieudonhang = 'IN'
  and a.macongtycn not in ('DL001')
)

/* Mục đích: Hợp nhất (Union) toàn bộ dữ liệu từ nguồn Manual và Sales chính thống.
   Điều kiện lọc: Không có (Union All). */
,total_data as
(
  SELECT * FROM manual
  union all
  SELECT * FROM f_sale
)

/* BƯỚC 4: XỬ LÝ SỔ XUẤT HÀNG & THÔNG TIN VẬN CHUYỂN (LOGISTICS PROCESSING) */

/* Mục đích: Xây dựng sổ xuất hàng chi tiết từ các bảng IB/IBD và thông tin xe.
   Điều kiện lọc: Các đơn xuất hàng đã hoàn tất (Status = 'C') từ năm 2024. */
,
SOXUATHANG as
(
  -- Tạo sổ
  with dms_ib AS
  (
    SELECT
      distinct branchid,
      truckid,
      batnbr,
      deliveryunit,
      slsperid as slsperid_ib,
      status as status_ib,
      issuedate as issuedate_ib,
      crtd_datetime as crtd_datetime_ib,
      crtd_user as crtd_user_ib,
      lupd_datetime as lupd_datetime_ib1,
      Case when date(approvedate) ='1900-01-01' then null else
      approvedate end as lupd_datetime_ib
      -- approvedate as lupd_datetime_ib
      -- đổi qua cột approvedate ngày 9/1/2023
    FROM `spatial-vision-343005.staging.sync_dms_ib`
    WHERE DATE(crtd_datetime) >= "2024-01-01"
  )
  ,
  -- Chốt sổ
  dms_ibd AS
  (
    SELECT
      distinct branchid,
      batnbr,
      ordernbr,
      status as status_ibd,
      deliverytime as deliverytime_ibd,
      crtd_datetime crtd_datetime_ibd,
      crtd_user as crtd_user_ibd,
      lupd_datetime as lupd_datetime_ibd,
      transporters,
    FROM`spatial-vision-343005.staging.sync_dms_ibd`
    WHERE DATE(crtd_datetime) >= "2024-01-01"
  )
  ,
  soxuathang_final as
  (
    SELECT
      a.*,
      b.ordernbr,
      b.status_ibd,
      b.deliverytime_ibd,
      b.crtd_user_ibd,
      b.crtd_datetime_ibd,
      b.lupd_datetime_ibd,
      b.transporters,
      c.descr as thongtinxe_sxh,
      row_number() over (partition by a.batnbr,b.ordernbr order by crtd_datetime_ib desc) as loc
    FROM dms_ib a
    LEFT JOIN dms_ibd b on a.branchid = b.branchid and a.batnbr = b.batnbr
    LEFT JOIN `spatial-vision-343005.staging.sync_dms_ot` c on a.branchid = c.branchid
                                                              and a.truckid = c.code
    WHERE status_ib = 'C'
  )

  select * from soxuathang_final
  -- where loc = 1
)
-- END SO XUAT HANG
/* BƯỚC 5: TÍCH HỢP DỮ LIỆU & TÍNH TOÁN NGHIỆP VỤ (CORE BUSINESS LOGIC JOIN) */

/* Mục đích: Bảng Master kết hợp Sales, Công nợ, Khách hàng, Nhân viên, Sổ xuất hàng và Phân loại người lưu trữ.
   Điều kiện lọc: Loại bỏ các kênh nội bộ/thử nghiệm (OTH_LAB, NB, EXP), chọn dòng dữ liệu mới nhất (Loc=1). */
,result as
(
SELECT
    a.*,
    k.termsid,
    IFNULL(b.terms, ar.terms) AS terms,
    k.descr AS thoihanthanhtoan,
    NULL AS ngaythanhtoan,
    CASE COALESCE(b.paymentsform, so.paymentsform)
        WHEN 'A' THEN 'Chuyển Khoản'
        WHEN 'B' THEN 'Tiền Mặt'
        WHEN 'C' THEN 'Tiền Mặt/Chuyển Khoản'
        WHEN 'D' THEN 'Ghi Nợ'
        WHEN 'E' THEN 'TM/CK/CTH'
        WHEN 'F' THEN 'Cấn Trừ Nợ'
        ELSE COALESCE(b.paymentsform, so.paymentsform, c.paymentsform)
    END AS hinhthucthanhtoan,
    c.custname AS dtcn_noi_bo,
    so.invoicecustid AS custidinvoice,
    so.custinvcname AS ten_khach_hang_thue,
    c.territorydescr AS khu_vuc,
    c.channel,
    a.macsmgh AS manvgh, -- 1 số k có thông tin -> map theo theo thông tin tính lương
    e.tencvbh AS ten_nvgh,
    e.supid AS sup_mds,
    e.tenquanlytt AS tensup_mds,
    f.mds_da_ban_giao,
    f.mds_phan_hoi,
    f.mds_ghi_chu,
    f.kt_ghi_chu,
    IFNULL(a.ktdanhan, CASE WHEN f.kt_da_nhan IS NOT NULL THEN 'X' ELSE f.kt_da_nhan END) AS kt_da_nhan,
    IFNULL(a.nhan_bbgh, f.kh_ki_nhan_theo_mau_bb_giao_hang) AS kh_ki_nhan_theo_mau_bb_giao_hang,
    IFNULL(a.nhan_hdgh, f.kh_ki_nhan_hang_tren_hoa_don) AS kh_ki_nhan_hang_tren_hoa_don,
    f1.kt_phan_hoi,
    f1.inserted_at,
    CURRENT_DATETIME("+7") AS updated_at,
    -- Map mã người lưu trữ theo danh sách chị Quỳnh
    CASE
        WHEN IFNULL(b.terms, ar.terms) IN ('01', '03') THEN NULL
        WHEN c.territorydescr IN ('Miền Đông 2') THEN 'MR2931'
        WHEN c.territorydescr IN ('Mê Kông 1', 'Mê Kông 2') THEN 'MR0654'
        WHEN c.territorydescr IN ('Hồ Chí Minh 1', 'Hồ Chí Minh 2') THEN 'MR2917'
        WHEN c.territorydescr IN ('Đông Bắc 1', 'Đông Bắc 2', 'Đông Nam 1', 'Hà Nội 1', 'Hà Nội 2', 'Tây Bắc HN', 'Đông Nam 2') THEN 'MR2280'
        WHEN c.territorydescr IN ('Nam Trung Bộ') THEN 'MR0781'
        WHEN c.territorydescr IN ('Miền Đông 1') THEN 'MR0027'
        WHEN c.territorydescr IN ('Bắc Trung Bộ') THEN 'MR0338'
        ELSE NULL
    END AS ma_nguoiluutru,
    -- Map tên người lưu trữ theo danh sách chị Quỳnh
    CASE
        WHEN IFNULL(b.terms, ar.terms) IN ('01', '03') THEN NULL
        WHEN c.territorydescr IN ('Miền Đông 2') THEN 'Ánh Hồng'
        WHEN c.territorydescr IN ('Mê Kông 1', 'Mê Kông 2') THEN 'Mỹ Nga'
        WHEN c.territorydescr IN ('Hồ Chí Minh 1', 'Hồ Chí Minh 2') THEN 'Ngọc Nhi'
        WHEN c.territorydescr IN ('Đông Bắc 1', 'Đông Bắc 2', 'Đông Nam 1', 'Hà Nội 1', 'Hà Nội 2', 'Tây Bắc HN', 'Đông Nam 2') THEN 'Phạm Nga'
        WHEN c.territorydescr IN ('Nam Trung Bộ') THEN 'Phương Thúy'
        WHEN c.territorydescr IN ('Miền Đông 1') THEN 'Thu Hằng'
        WHEN c.territorydescr IN ('Bắc Trung Bộ') THEN 'Thương - Đà Nẵng'
        ELSE NULL
    END AS nguoiluutru,
    CASE
        WHEN rd.ordernbr = a.sodonhang AND a.macongtycn = rd.branchid AND rd.custid = a.macsm THEN rd.deliveryunit
        WHEN dr.ordernbr = a.sodonhang AND a.macongtycn = dr.branchid AND dr.custid = a.macsm THEN dr.deliveryunit
        ELSE NULL
    END AS deliveryunit_code,
    ard.deliveryunitname,
    sxh.thongtinxe_sxh,
    SUM(IFNULL(b.so_du_chungtu, ar.docbal)) AS so_du_chungtu,
    CASE
        WHEN SUM(b.so_du_chungtu) = 0 THEN 'Đã thanh toán'
        WHEN SUM(b.so_du_chungtu) IS NULL THEN ''
        ELSE 'Chưa thanh toán'
    END AS tinhtrang_thanhtoan,
    ROW_NUMBER() OVER (
        PARTITION BY CONCAT(TRIM(a.sodonhang), '-', a.sohoadon)
        ORDER BY f1.inserted_at DESC
    ) AS loc
FROM total_data a
LEFT JOIN `staging.sync_dms_ardoc` ar
    ON ar.branchid = a.macongtycn
    AND a.mahd = ar.ordnbr
LEFT JOIN d_rawdata_debt b
    ON TRIM(a.sodonhang) = b.Ordnbr
    AND TRIM(b.InvcNbr) = TRIM(a.sohoadon)
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` c
    ON TRIM(a.macsm) = c.custid
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang_bytime` c1
    ON TRIM(a.macsm) = c1.custid
    AND TIMESTAMP_TRUNC(a.ngayhoadon, MONTH) = c1.thang
LEFT JOIN `spatial-vision-343005.staging.d_users` e
    ON a.macsmgh = e.manv
LEFT JOIN thuhoi_bienban f
    ON CONCAT(TRIM(a.sodonhang), '-', a.sohoadon) = f.sodondathang
LEFT JOIN `spatial-vision-343005.staging.view_form_ktttthbb_phan_hoi` f1
    ON CONCAT(TRIM(a.sodonhang), '-', a.sohoadon) = f1.sodondathang
LEFT JOIN `spatial-vision-343005.staging.sync_dms_rd` rd
    ON a.sodonhang = rd.ordernbr
    AND a.macongtycn = rd.branchid
    AND a.macsm = rd.custid
LEFT JOIN `spatial-vision-343005.staging.sync_dms_dr` dr
    ON a.sodonhang = dr.ordernbr
    AND a.macongtycn = dr.branchid
    AND a.macsm = dr.custid
LEFT JOIN `spatial-vision-343005.staging.sync_dms_ard` ard
    ON ard.branchid = a.macongtycn
    AND ard.deliveryunitid = (
        CASE
            WHEN rd.ordernbr = a.sodonhang AND a.macongtycn = rd.branchid AND rd.custid = a.macsm THEN rd.deliveryunit
            WHEN dr.ordernbr = a.sodonhang AND a.macongtycn = dr.branchid AND dr.custid = a.macsm THEN dr.deliveryunit
            ELSE NULL
        END
    )
LEFT JOIN SOXUATHANG sxh
    ON a.sodonhang = sxh.ordernbr
LEFT JOIN `staging.sync_dms_so` so
    ON so.ordernbr = a.mahd
    AND a.macongtycn = so.branchid
LEFT JOIN staging.d_manual_terms_detail k
    ON k.termsid = IFNULL(b.terms, ar.terms)
WHERE c.channel NOT IN ('OTH_LAB', 'NB', 'EXP')
GROUP BY ALL
QUALIFY ROW_NUMBER() OVER(
    PARTITION BY TRIM(a.sodonhang) || '-' || a.sohoadon
    ORDER BY
        -- ƯU TIÊN: Nếu mã sản phẩm chứa 'V1' thì đưa lên đầu (gán giá trị 0), ngược lại gán 1
        CASE WHEN a.masanpham LIKE '%V1HML%' THEN 0 ELSE 1 END ASC,
        -- Sau đó mới xét đến ngày cập nhật mới nhất
        f1.inserted_at DESC
) = 1
)

/* BƯỚC 6: PHÂN LOẠI & ĐẦU RA CUỐI CÙNG (CLASSIFICATION & FINAL OUTPUT) */

/* Mục đích: Xử lý logic nghiệp vụ về trách nhiệm thu hồi (Nhóm phụ trách) và trạng thái bằng chứng (Hình ảnh).
   Điều kiện lọc: Ưu tiên dữ liệu từ form KT, sau đó đến Google Sheet MDS. */
, mapping_all as (
SELECT
    a.* EXCEPT(
        kt_da_nhan,
        kh_ki_nhan_theo_mau_bb_giao_hang,
        kh_ki_nhan_hang_tren_hoa_don,
        kt_phan_hoi,
        kt_ghi_chu,
        mds_da_ban_giao,
        mds_phan_hoi,
        mds_ghi_chu
    ),
    -- Phân loại nhóm phụ trách thu hồi dựa trên thời hạn và hình thức thanh toán
    CASE
        WHEN IFNULL(thoihanthanhtoan, '') IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
            THEN 'MDS phụ trách'
        WHEN IFNULL(thoihanthanhtoan, '') NOT IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
             AND hinhthucthanhtoan = 'Tiền Mặt'
            THEN 'MDS phụ trách'
        WHEN IFNULL(thoihanthanhtoan, '') NOT IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
             AND hinhthucthanhtoan <> 'Tiền Mặt'
            THEN 'KT phụ trách'
        ELSE ''
    END AS nhomphutrach_thuhoi,
    -- Phân loại hình thức thanh toán
    CASE
        WHEN IFNULL(thoihanthanhtoan, '') IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
            THEN 'Thanh toán ngay'
        ELSE 'Có thời hạn nợ'
    END AS pl_hinhthuc_tt,
    -- Logic xác định trạng thái kế toán đã nhận
    CASE
        WHEN (e.img1 IS NOT NULL OR e.img2 IS NOT NULL OR e.img3 IS NOT NULL)
             AND IFNULL(thoihanthanhtoan, '') IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
            THEN "MDS đã chụp hình ảnh"
        WHEN (e.img1 IS NOT NULL OR e.img2 IS NOT NULL OR e.img3 IS NOT NULL)
             AND hinhthucthanhtoan = 'Tiền Mặt'
             AND IFNULL(thoihanthanhtoan, '') NOT IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
            THEN 'KT đã nhận hình ảnh'
        ELSE IFNULL(a.kt_da_nhan, NULLIF(IFNULL(b.ketoandanhan, b1.ketoandanhan), '-'))
    END AS kt_da_nhan,
    -- Các trường thông tin phản hồi và ghi chú từ KT/MDS
    IFNULL(a.kh_ki_nhan_theo_mau_bb_giao_hang, NULLIF( b.khkinhantheomaubbgh , '-')) AS kh_ki_nhan_theo_mau_bb_giao_hang,
    IFNULL(a.kh_ki_nhan_hang_tren_hoa_don, NULLIF( b.khkinhanhangtrenhdon , '-')) AS kh_ki_nhan_hang_tren_hoa_don,
    IFNULL(a.kt_phan_hoi, NULLIF( b.ketoanphanhoi , '-')) AS kt_phan_hoi,
    IFNULL(a.kt_ghi_chu, NULLIF( b.ketoanghichu, '-')) AS kt_ghi_chu,
    a.mds_da_ban_giao AS mds_da_ban_giao,
    a.mds_phan_hoi AS mds_phan_hoi,
    mds_ghi_chu AS mds_ghi_chu,
    -- Phân loại bộ phận giao hàng theo quản lý vùng
    CASE
        WHEN d.tenquanlyvung = 'Lương Trịnh Thắng' THEN 'MDS'
        WHEN d.tenquanlyvung = 'Nguyễn Hoàng Viển' THEN 'SDS'
        ELSE NULL
    END AS phanloai_giaohang,
    e.note,
    e.img1,
    e.img2,
    e.img3,
    b1.ocr_url
    FROM result a
    LEFT JOIN `spatial-vision-343005.staging.d_kt_thuhoi_bbgh` b
        ON CONCAT(TRIM(a.sodonhang), '-', a.sohoadon) = b.noimadhsohoadon -- KQ từ GSheet KT nhập

    LEFT JOIN `upload_orc` b1 on CONCAT(TRIM(a.sodonhang), '-', a.sohoadon) = CONCAT(TRIM(b1.origordernbr), '-', b1.invcnbr)

    /* comments lại các rules cũ không xài nữa
    LEFT JOIN `spatial-vision-343005.staging.d_kt_thuhoi_bbgh_2023` b1
        ON CONCAT(TRIM(a.sodonhang), '-', a.sohoadon) = b1.noimadhsohoadon -- KQ từ GSheet KT nhập năm 2023
    LEFT JOIN `spatial-vision-343005.staging.d_mds_thuhoi_bbgh` c
        ON CONCAT(TRIM(a.sodonhang), '-', a.sohoadon) = c.noimadhsohoadon -- KQ từ GSheet MDS nhập
    */
    LEFT JOIN `spatial-vision-343005.staging.d_users` d
        ON a.manvgh = d.manv
    LEFT JOIN `staging.view_sync_dms_bbgh_checkin` e
        ON e.ordernbr = a.sodonhang
        AND e.branchid = a.macongtycn
  )

/*
Mục đích: Tạo báo cáo cuối cùng, gán nhãn chi tiết từng trường hợp (case 1 -> 7.1) phục vụ Dashboard.
Điều kiện lọc: Chỉ lấy các hóa đơn từ ngày 01/01/2024.
*/
, result_1 AS (
SELECT
    a.*,
    /* Cột mới 19/12/2025: Link Upload Chứng Từ */
    CASE
        /* Nếu đơn vị giao hàng là Nhà vận chuyển -> Không cần link upload */
        WHEN UPPER(donvigiaohang) = 'NHÀ VẬN CHUYỂN'
        THEN CONCAT(
            'https://ds.meraplion.com/formcontrol/mds_bbgh_bo_sung?so_don_hang_hoa_don=',
            TRIM(sodonhang),
            "&chi_nhanh=",macongtycn,
            "&ma_kh=", a.macsm,
            "&slsperid=",IFNULL(manvgh, ''),
            'so_hoa_don=', TRIM(sohoadon)
                    )
        ELSE CONCAT(
            'https://ds.meraplion.com/formcontrol/mds_bbgh_bo_sung?',
            'so_don_hang_hoa_don=', TRIM(sodonhang),
            '&chi_nhanh=', macongtycn,
            '&ma_kh=', macsm,
            '&slsperid=', IFNULL(manvgh, ''),
            'so_hoa_don=', TRIM(sohoadon)
        )
    END AS url_upload_chung_tu,
    CASE
        WHEN so_du_chungtu != 0 OR so_du_chungtu IS NULL THEN CONCAT(sohoadon, macsm)
        ELSE NULL
    END AS sl_hd_dh_chua_thanh_toan,
    CASE
        WHEN so_du_chungtu = 0 THEN CONCAT(sohoadon, macsm)
        ELSE NULL
    END AS sl_hd_dh_da_thanh_toan,
    -- Phân loại chi tiết trạng thái thu hồi BBGH
    CASE
        -- 1. Đơn hàng thu tiền ngay
        WHEN nhomphutrach_thuhoi = 'MDS phụ trách'
             AND so_du_chungtu = 0
             AND kt_da_nhan IS NULL
             AND IFNULL(thoihanthanhtoan, '') IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
            THEN '7.1. Đơn hàng thu tiền ngay đã thanh toán - MDS/SDS chưa chụp hình ảnh'
        WHEN nhomphutrach_thuhoi = 'MDS phụ trách'
             AND so_du_chungtu = 0
             AND kt_da_nhan IS NOT NULL
             AND IFNULL(thoihanthanhtoan, '') IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
            THEN '7. Đơn hàng thu tiền ngay đã thanh toán - MDS/SDS đã chụp hình ảnh'
        WHEN nhomphutrach_thuhoi = 'MDS phụ trách'
             AND (so_du_chungtu != 0 OR so_du_chungtu IS NULL)
             AND kt_da_nhan IS NULL
             AND IFNULL(thoihanthanhtoan, '') IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
            THEN '6.1. Đơn hàng thu tiền ngay chưa thanh toán - MDS/SDS chưa chụp hình ảnh'
        WHEN nhomphutrach_thuhoi = 'MDS phụ trách'
             AND (so_du_chungtu != 0 OR so_du_chungtu IS NULL)
             AND kt_da_nhan IS NOT NULL
             AND IFNULL(thoihanthanhtoan, '') IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
            THEN '6. Đơn hàng thu tiền ngay chưa thanh toán - MDS/SDS đã chụp hình ảnh'
        -- 2. MDS thu tiền mặt (không phải tiền ngay)
        WHEN nhomphutrach_thuhoi = 'MDS phụ trách'
             AND (so_du_chungtu != 0 OR so_du_chungtu IS NULL)
             AND kt_da_nhan IS NOT NULL
             AND IFNULL(thoihanthanhtoan, '') NOT IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
            THEN '5.1. MDS giữ để thu tiền mặt chưa thanh toán - KT đã nhận hình ảnh'
        WHEN nhomphutrach_thuhoi = 'MDS phụ trách'
             AND (so_du_chungtu != 0 OR so_du_chungtu IS NULL)
             AND kt_da_nhan IS NULL
             AND IFNULL(thoihanthanhtoan, '') NOT IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
            THEN '5. MDS giữ để thu tiền mặt chưa thanh toán - KT chưa nhận hình ảnh'
        WHEN nhomphutrach_thuhoi = 'MDS phụ trách'
             AND so_du_chungtu = 0
             AND IFNULL(thoihanthanhtoan, '') NOT IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
             AND kt_da_nhan IS NOT NULL
            THEN '4.1. MDS giữ để thu tiền mặt đã thanh toán - KT đã nhận hình ảnh'
        WHEN nhomphutrach_thuhoi = 'MDS phụ trách'
             AND so_du_chungtu = 0
             AND IFNULL(thoihanthanhtoan, '') NOT IN ('Thu tiền ngay có VP PN', 'Thu tiền ngay không có VP PN')
             AND kt_da_nhan IS NULL
            THEN '4. MDS giữ để thu tiền mặt đã thanh toán - KT chưa nhận hình ảnh'
        -- 3. KT phụ trách
        WHEN nhomphutrach_thuhoi = 'KT phụ trách' AND kt_da_nhan IS NOT NULL
            THEN '1. KT đã thu'
        WHEN nhomphutrach_thuhoi = 'KT phụ trách' AND kt_da_nhan IS NULL AND (so_du_chungtu != 0 OR so_du_chungtu IS NULL)
            THEN '2. KT chưa thu + còn nợ'
        WHEN nhomphutrach_thuhoi = 'KT phụ trách' AND kt_da_nhan IS NULL AND so_du_chungtu = 0
            THEN '3. KT chưa thu + hết nợ'
        ELSE NULL
    END AS pl_thuhoi_bbgh
FROM mapping_all a
WHERE DATE(ngayhoadon) >= '2024-01-01'
and IFNULL(sohoadon, 'none') not in ('00007788')
)
SELECT
* EXCEPT(kt_da_nhan),
Case when UPPER(kt_da_nhan) = 'X' Then 'Kế toán đã nhận bản gốc' else kt_da_nhan end as kt_da_nhan
FROM result_1
);

Create or replace table `warehouse.f_thuhoi_bbgh`

copy `staging_temp.f_thuhoi_bbgh_temp`;
END;
