CREATE VIEW `spatial-vision-343005.warehouse.view_trungbay_poster_binh_on_gia`
AS WITH 
thong_tin_ky_hop_dong as (
SELECT
distinct ma_khach_hang,
trang_thai_ky,
internal_promo_code
FROm `spatial-vision-343005.warehouse.view_data_contract_sign_by_users`
where
internal_promo_code ='2601-CTTB-CPA09-NT-QT'
and trang_thai_ky = 'Đã ký'
)

, dskh_thamgia AS(
    SELECT
        d.branchid as macongtychinhanh,
        e.col.ma_nvbh as manhanvienphutrach,
        c.tencvbh as tennhanvienphutrach,
        a.makhachhang,
        a.tenkhachhang,
        d.channel,
        a.thanhphotinh,
        d.stocksales as tinh_trang_ma_so_thue,
        1500000 as muc_ds,
        d.businessscope as pham_vi_kinh_doanh,
        Case when t.ngay_thu_hoi is not null then 'Đã thu' 
        When f.ma_khach_hang is not null then 'Đã thu'
        else 'Chưa thu' end AS thu_hoi_tttb,
        c.supid as ma_crm,
        c.tenquanlytt,
        c.asm,
        c.tenquanlykhuvuc,
        if(date(d.legaldate) >= current_date("+7"),'Còn hiệu lực','Hết hiệu lực') as hieu_luc_gdp
    FROM `spatial-vision-343005.staging.d_tdisplay` a
    LEFT JOIN `staging.d_master_khachhang` d on d.custid = a.makhachhang
    LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` e ON e.custid = a.makhachhang
    LEFT JOIN `staging.d_users` c on e.col.ma_nvbh = c.manv
    LEFT JOIN `spatial-vision-343005.staging.theo_doi_thu_hoi_chung_tu_ky_ben_ngoai_bog_2026` t ON a.makhachhang = t.ma_kh
    LEFT JOIN thong_tin_ky_hop_dong f ON f.ma_khach_hang = a.makhachhang
    WHERE 
        a.machuongtrinh = '2601-CTTB-CPA09-NT-QT'
        and lower(a.trangthaiduyettrungbay) = 'đã duyệt'
    GROUP BY ALL
)
, data_sales AS (
    SELECT
        makhdms,
        MAX(updated_at) as updated_at,
        SUM(CASE WHEN EXTRACT(QUARTER FROM date(ngaychungtu)) = 1 THEN doanhsochuavat ELSE 0 END) as ds_quy_1,
        SUM(CASE WHEN EXTRACT(QUARTER FROM date(ngaychungtu)) = 2 THEN doanhsochuavat ELSE 0 END) as ds_quy_2,
        SUM(doanhsochuavat) as tong_doanh_so
    FROM `warehouse.f_raw_data_sales_yoy` s
    WHERE date(s.ngaychungtu) >= '2026-01-01' AND date(s.ngaychungtu)  <= '2026-06-30'
    AND masanpham in ('EH086','EH115','EH092','T302204001','T302101005','T302101006','T302101007','T302101008')
    GROUP BY makhdms
)
, so_lan_chup_anh AS (
 SELECT 
    custid,

    COUNT(DISTINCT (
        CASE WHEN EXTRACT(MONTH FROM visitdate) = 4 AND img1 IS NOT NULL 
        THEN date(visitdate) END
    )) as so_lan_chup_t4,

    COUNT(DISTINCT (
        CASE WHEN EXTRACT(MONTH FROM visitdate) = 5 AND img1 IS NOT NULL 
        THEN date(visitdate) END
    )) as so_lan_chup_t5,

    COUNT(DISTINCT (
        CASE WHEN EXTRACT(MONTH FROM visitdate) = 6 AND img1 IS NOT NULL 
        THEN date(visitdate) END
    )) as so_lan_chup_t6,

    COUNT(DISTINCT (
        CASE WHEN EXTRACT(QUARTER FROM visitdate) = 1 AND img1 IS NOT NULL THEN date(visitdate) END
    )) as so_lan_chup_q1,

    COUNT(DISTINCT (
        CASE WHEN EXTRACT(QUARTER FROM visitdate) = 2 AND img1 IS NOT NULL THEN date(visitdate) END
    )) as so_lan_chup_q2

FROM `spatial-vision-343005.staging.d_display_criteria_remark`
WHERE displayid = '2601-CTTB-CPA09-NT-QT'
  AND date(visitdate) BETWEEN '2026-01-01' AND '2026-06-30'
GROUP BY 
    custid
)

, raw_data_anh AS (
    SELECT 
        custid, 
        img1,
        img2,
        img3,
        criteria, 
        result, 
        visitdate,
        EXTRACT(MONTH FROM visitdate) as thang
    FROM `spatial-vision-343005.staging.d_display_criteria_remark`
    WHERE displayid = '2601-CTTB-CPA09-NT-QT'
      AND date(visitdate) BETWEEN '2026-01-01' AND '2026-06-30'
    QUALIFY DENSE_RANK() OVER(PARTITION BY custid,DATE_TRUNC(DATE(visitdate), MONTH) ORDER BY visitdate DESC) = 1
)

, thong_tin_anh AS (
    SELECT 
        custid,
        -- HÌNH ẢNH THÁNG 1
        MAX(CASE WHEN thang = 1 AND criteria = 'Tình trạng dán Poster tại NT' THEN img1 END) as t01_tinhtrang_img1,
        MAX(CASE WHEN thang = 1 AND criteria = 'Tình trạng dán Poster tại NT' THEN img2 END) as t01_tinhtrang_img2,
        MAX(CASE WHEN thang = 1 AND criteria = 'Tình trạng dán Poster tại NT' THEN img3 END) as t01_tinhtrang_img3,
        MAX(CASE WHEN thang = 1 AND criteria = 'Có dán Poster hay không'    THEN img1 END) as t01_codan_img1,
        MAX(CASE WHEN thang = 1 AND criteria = 'Có dán Poster hay không'    THEN img2 END) as t01_codan_img2,
        MAX(CASE WHEN thang = 1 AND criteria = 'Có dán Poster hay không'    THEN img3 END) as t01_codan_img3,

        -- HÌNH ẢNH THÁNG 2
        MAX(CASE WHEN thang = 2 AND criteria = 'Tình trạng dán Poster tại NT' THEN img1 END) as t02_tinhtrang_img1,
        MAX(CASE WHEN thang = 2 AND criteria = 'Tình trạng dán Poster tại NT' THEN img2 END) as t02_tinhtrang_img2,
        MAX(CASE WHEN thang = 2 AND criteria = 'Tình trạng dán Poster tại NT' THEN img3 END) as t02_tinhtrang_img3,
        MAX(CASE WHEN thang = 2 AND criteria = 'Có dán Poster hay không'    THEN img1 END) as t02_codan_img1,
        MAX(CASE WHEN thang = 2 AND criteria = 'Có dán Poster hay không'    THEN img2 END) as t02_codan_img2,
        MAX(CASE WHEN thang = 2 AND criteria = 'Có dán Poster hay không'    THEN img3 END) as t02_codan_img3,

        -- HÌNH ẢNH THÁNG 3
        MAX(CASE WHEN thang = 3 AND criteria = 'Tình trạng dán Poster tại NT' THEN img1 END) as t03_tinhtrang_img1,
        MAX(CASE WHEN thang = 3 AND criteria = 'Tình trạng dán Poster tại NT' THEN img2 END) as t03_tinhtrang_img2,
        MAX(CASE WHEN thang = 3 AND criteria = 'Tình trạng dán Poster tại NT' THEN img3 END) as t03_tinhtrang_img3,
        MAX(CASE WHEN thang = 3 AND criteria = 'Có dán Poster hay không'    THEN img1 END) as t03_codan_img1,
        MAX(CASE WHEN thang = 3 AND criteria = 'Có dán Poster hay không'    THEN img2 END) as t03_codan_img2,
        MAX(CASE WHEN thang = 3 AND criteria = 'Có dán Poster hay không'    THEN img3 END) as t03_codan_img3,

        -- HÌNH ẢNH THÁNG 4
        MAX(CASE WHEN thang = 4 AND criteria = 'Tình trạng dán Poster tại NT' THEN img1 END) as t04_tinhtrang_img1,
        MAX(CASE WHEN thang = 4 AND criteria = 'Tình trạng dán Poster tại NT' THEN img2 END) as t04_tinhtrang_img2,
        MAX(CASE WHEN thang = 4 AND criteria = 'Tình trạng dán Poster tại NT' THEN img3 END) as t04_tinhtrang_img3,
        MAX(CASE WHEN thang = 4 AND criteria = 'Có dán Poster hay không'    THEN img1 END) as t04_codan_img1,
        MAX(CASE WHEN thang = 4 AND criteria = 'Có dán Poster hay không'    THEN img2 END) as t04_codan_img2,
        MAX(CASE WHEN thang = 4 AND criteria = 'Có dán Poster hay không'    THEN img3 END) as t04_codan_img3,

        -- HÌNH ẢNH THÁNG 5
        MAX(CASE WHEN thang = 5 AND criteria = 'Tình trạng dán Poster tại NT' THEN img1 END) as t05_tinhtrang_img1,
        MAX(CASE WHEN thang = 5 AND criteria = 'Tình trạng dán Poster tại NT' THEN img2 END) as t05_tinhtrang_img2,
        MAX(CASE WHEN thang = 5 AND criteria = 'Tình trạng dán Poster tại NT' THEN img3 END) as t05_tinhtrang_img3,
        MAX(CASE WHEN thang = 5 AND criteria = 'Có dán Poster hay không'    THEN img1 END) as t05_codan_img1,
        MAX(CASE WHEN thang = 5 AND criteria = 'Có dán Poster hay không'    THEN img2 END) as t05_codan_img2,
        MAX(CASE WHEN thang = 5 AND criteria = 'Có dán Poster hay không'    THEN img3 END) as t05_codan_img3,

        -- HÌNH ẢNH THÁNG 6
        MAX(CASE WHEN thang = 6 AND criteria = 'Tình trạng dán Poster tại NT' THEN img1 END) as t06_tinhtrang_img1,
        MAX(CASE WHEN thang = 6 AND criteria = 'Tình trạng dán Poster tại NT' THEN img2 END) as t06_tinhtrang_img2,
        MAX(CASE WHEN thang = 6 AND criteria = 'Tình trạng dán Poster tại NT' THEN img3 END) as t06_tinhtrang_img3,
        MAX(CASE WHEN thang = 6 AND criteria = 'Có dán Poster hay không'    THEN img1 END) as t06_codan_img1,
        MAX(CASE WHEN thang = 6 AND criteria = 'Có dán Poster hay không'    THEN img2 END) as t06_codan_img2,
        MAX(CASE WHEN thang = 6 AND criteria = 'Có dán Poster hay không'    THEN img3 END) as t06_codan_img3,

        -- 1. TRẠNG THÁI CHỤP ẢNH (T1 - T6)
        MAX(CASE WHEN thang = 1 AND img1 IS NOT NULL THEN 'Đã chụp' ELSE 'Chưa chụp' END) as chup_anh_t01,
        MAX(CASE WHEN thang = 2 AND img1 IS NOT NULL THEN 'Đã chụp' ELSE 'Chưa chụp' END) as chup_anh_t02,
        MAX(CASE WHEN thang = 3 AND img1 IS NOT NULL THEN 'Đã chụp' ELSE 'Chưa chụp' END) as chup_anh_t03,
        MAX(CASE WHEN thang = 4 AND img1 IS NOT NULL THEN 'Đã chụp' ELSE 'Chưa chụp' END) as chup_anh_t04,
        MAX(CASE WHEN thang = 5 AND img1 IS NOT NULL THEN 'Đã chụp' ELSE 'Chưa chụp' END) as chup_anh_t05,
        MAX(CASE WHEN thang = 6 AND img1 IS NOT NULL THEN 'Đã chụp' ELSE 'Chưa chụp' END) as chup_anh_t06,

        -- 2. KẾT QUẢ XÉT DUYỆT QUÝ (Dựa trên tháng 3 và tháng 6)
        CASE 
            WHEN COUNTIF(thang = 3 AND criteria = 'Tình trạng dán Poster tại NT' AND result = 'Đạt') > 0 
             AND COUNTIF(thang = 3 AND criteria = 'Có dán Poster hay không'    AND result = 'Đạt') > 0 
            THEN 'Đạt' ELSE 'Không Đạt' 
        END AS kq_anh_t3,

        CASE 
            WHEN COUNTIF(thang = 6 AND criteria = 'Tình trạng dán Poster tại NT' AND result = 'Đạt') > 0 
             AND COUNTIF(thang = 6 AND criteria = 'Có dán Poster hay không'    AND result = 'Đạt') > 0 
            THEN 'Đạt' ELSE 'Không Đạt' 
        END AS kq_anh_t6

    FROM raw_data_anh
    GROUP BY custid
)

SELECT
    a.*,
    h.ma_cre,
    h.ho_ten_cre,
    s.updated_at,
    IFNULL(c.so_lan_chup_q1, 0) as so_lan_chup_q1,
    -- --- XÉT DUYỆT QUÝ 1 ---
    IFNULL(s.ds_quy_1, 0) as doanh_so_quy_1,
    IF(IFNULL(s.ds_quy_1,0) >= a.muc_ds, 'Đạt', 'Không đạt') as xet_ds_quy_1,
    IF(IFNULL(s.ds_quy_1,0) >= a.muc_ds, 0, a.muc_ds - IFNULL(s.ds_quy_1,0)) as thieu_ds_quy_1,
    -- Kết quả ảnh Quý 1
    IFNULL(b.kq_anh_t3, 'Không Đạt') as ket_qua_anh_t3,

    -- --- XÉT DUYỆT QUÝ 2 ---
    IFNULL(c.so_lan_chup_q2, 0) as so_lan_chup_q2,
    IFNULL(s.ds_quy_2, 0) as doanh_so_quy_2,
    IF(IFNULL(s.ds_quy_2,0) >= a.muc_ds, 'Đạt', 'Không đạt') as xet_ds_quy_2,
    IF(IFNULL(s.ds_quy_2,0) >= a.muc_ds, 0, a.muc_ds - IFNULL(s.ds_quy_2,0)) as thieu_ds_quy_2,
    IFNULL(b.kq_anh_t6, 'Không Đạt') as ket_qua_anh_t6,
    
    -- Tổng doanh số (tham khảo)
    IFNULL(s.tong_doanh_so, 0) as tong_doanh_so_6_thang,
    
    -- Trạng thái chụp ảnh từng tháng
    IFNULL(b.chup_anh_t01,'Chưa chụp') as chup_anh_t01,
    IFNULL(b.chup_anh_t02,'Chưa chụp') as chup_anh_t02,
    IFNULL(b.chup_anh_t03,'Chưa chụp') as chup_anh_t03,
    IFNULL(b.chup_anh_t04,'Chưa chụp') as chup_anh_t04,
    IFNULL(b.chup_anh_t05,'Chưa chụp') as chup_anh_t05,
    IFNULL(b.chup_anh_t06,'Chưa chụp') as chup_anh_t06,

    -- --- SỐ LẦN CHỤP ẢNH TỪNG THÁNG ---
    IFNULL(c.so_lan_chup_t4, 0) as so_lan_chup_t4,
    IFNULL(c.so_lan_chup_t5, 0) as so_lan_chup_t5,
    IFNULL(c.so_lan_chup_t6, 0) as so_lan_chup_t6,

    -- Link ảnh của các tháng còn lại
    b.t01_tinhtrang_img1, b.t01_tinhtrang_img2, b.t01_tinhtrang_img3,
    b.t01_codan_img1, b.t01_codan_img2, b.t01_codan_img3,

    b.t02_tinhtrang_img1, b.t02_tinhtrang_img2, b.t02_tinhtrang_img3,
    b.t02_codan_img1, b.t02_codan_img2, b.t02_codan_img3,

    b.t03_tinhtrang_img1, b.t03_tinhtrang_img2, b.t03_tinhtrang_img3,
    b.t03_codan_img1, b.t03_codan_img2, b.t03_codan_img3,

    b.t04_tinhtrang_img1, b.t04_tinhtrang_img2, b.t04_tinhtrang_img3,
    b.t04_codan_img1, b.t04_codan_img2, b.t04_codan_img3,

    b.t05_tinhtrang_img1, b.t05_tinhtrang_img2, b.t05_tinhtrang_img3,
    b.t05_codan_img1, b.t05_codan_img2, b.t05_codan_img3,

    b.t06_tinhtrang_img1, b.t06_tinhtrang_img2, b.t06_tinhtrang_img3,
    b.t06_codan_img1, b.t06_codan_img2, b.t06_codan_img3

FROM dskh_thamgia a
LEFT JOIN data_sales s ON a.makhachhang = s.makhdms
LEFT JOIN `spatial-vision-343005.staging.d_calendar_cre` h ON a.manhanvienphutrach = h.ma_crs AND date(h.thang) = DATE_TRUNC(DATE(CURRENT_DATE()),MONTH)
LEFT JOIN thong_tin_anh b ON a.makhachhang = b.custid
LEFT JOIN so_lan_chup_anh c ON a.makhachhang = c.custid









;