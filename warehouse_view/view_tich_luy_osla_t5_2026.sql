CREATE VIEW `spatial-vision-343005.warehouse.view_tich_luy_osla_t5_2026`
AS WITH data_sales AS (
    SELECT  
        c.branchid as macongtycn,
        a.makhdms,
        c.custname as ten_kh,
        IFNULL(b.col.ma_nvbh,'None') as manv,
        b.tencvbh,
        b.supid,
        b.tenquanlytt,
        a.hcoid,
        a.hcotypeid,
        a.statedescr,
        a.ngaychungtu,
        a.doanhsochuavat,
        date(a.updated_at) as updated_at,
        CASE WHEN DATE(c.legaldate) >= DATE_ADD(CURRENT_DATE(), INTERVAL 7 DAY) THEN 'Còn hiệu lực' ELSE 'Hết hiệu lực' END AS hieu_luc_gpp_gdp,
        c.stocksales AS tinh_trang_mst
    FROM `warehouse.f_raw_data_sales_yoy` a
    LEFT JOIN `warehouse.f_mapping_crs` b ON a.makhdms = b.custid
    LEFT JOIN `staging.d_master_khachhang` c ON a.makhdms = c.custid
    WHERE masanpham in ('OH031','OH059')
      AND a.hcoid in ('PMC','CTD')
      AND DATE(ngaychungtu) >= '2026-05-01'
      AND DATE(ngaychungtu) <= '2026-07-31' --'2026-07-31'
)

, tich_luy_khach_hang AS (
    SELECT
        macongtycn,
        makhdms,
        ten_kh,
        manv,
        tencvbh,
        supid,
        tenquanlytt,
        hcoid,
        hcotypeid,
        statedescr,
        MAX(updated_at) as updated_at,
        hieu_luc_gpp_gdp,
        tinh_trang_mst,
        SUM(doanhsochuavat) as ds_tichluy_thuong_sp,
        SUM(CASE 
            WHEN DATE(ngaychungtu) >= '2026-05-15' 
            THEN doanhsochuavat ELSE 0 
        END) as ds_tichluy_quayso
        
    FROM data_sales
    GROUP BY ALL
)
,tinh_tien_thuong AS (
SELECT 
    *,
    CASE 
        WHEN ds_tichluy_thuong_sp >= 12000000 THEN 0.05   
        WHEN ds_tichluy_thuong_sp >= 6000000 THEN 0.045   
        WHEN ds_tichluy_thuong_sp >= 2000000 THEN 0.04    
        ELSE 0 
    END as ty_le_km,
    
    CASE 
        WHEN ds_tichluy_thuong_sp >= 12000000 THEN ds_tichluy_thuong_sp * 0.05
        WHEN ds_tichluy_thuong_sp >= 6000000 THEN ds_tichluy_thuong_sp * 0.045
        WHEN ds_tichluy_thuong_sp >= 2000000 THEN ds_tichluy_thuong_sp * 0.04
        ELSE 0 
    END as gia_tri_thuong,

    -- THÀNH PHẦN 2: TÍNH MÃ DỰ THƯỞNG QUAY SỐ (Dựa trên ds_tichluy_quayso)
    TRUNC(ds_tichluy_quayso / 2000000) as sl_ma_chinh,                    -- Cứ 2 triệu từ ngày 15/8 = 1 mã
    TRUNC(ds_tichluy_quayso / 12000000) as sl_ma_phu,                    -- Cứ 12 triệu từ ngày 15/8 = 1 mã phụ
    
    (TRUNC(ds_tichluy_quayso / 2000000) + TRUNC(ds_tichluy_quayso / 12000000)) as tong_sl_ma,

FROM tich_luy_khach_hang
)
,tinh_osla AS (
    SELECT 
        *,
        TRUNC(gia_tri_thuong / 21905) as sl_osla_15ml
    FROM tinh_tien_thuong
)

SELECT 
    b.*,
    -- Số lượng Xisat tính bằng số tiền dư còn lại sau khi đã đổi tối đa sang Osla
    TRUNC((gia_tri_thuong - (sl_osla_15ml * 21905)) / 6667) as sl_xisat_15ml

FROM tinh_osla b










;