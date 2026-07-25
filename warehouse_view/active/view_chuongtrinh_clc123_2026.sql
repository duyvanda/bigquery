CREATE VIEW `spatial-vision-343005.warehouse.view_chuongtrinh_clc123_2026`
AS with loc_doanhso as 

/* Lọc doanh số hợp lệ (Có VAT > 0 và nằm trong thời gian chương trình) */
(
SELECT 
    a.makhdms,
    a.ngaychungtu,
    a.masanpham,
    CASE 
        WHEN DATE(ngaychungtu) BETWEEN PARSE_DATE('%d/%m/%Y', SPLIT(ghichu, '-')[OFFSET(0)])
                                 AND PARSE_DATE('%d/%m/%Y', SPLIT(ghichu, '-')[OFFSET(1)])
        AND a.makenhphu in ('CLC2','CLC3')
        THEN doanhsochuavat_ori 
        ELSE 0 
    END AS doanhsochuavat

FROM `warehouse.f_raw_data_sales_yoy` a
JOIN `spatial-vision-343005.staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` b 
    ON a.makhdms = b.makhdms AND b.ma_chuongtrinh IN ('CLC3', 'CLC2')

WHERE 
    ngaychungtu >= '2026-01-01'
    AND ngaychungtu <= '2026-06-30' --'2026-12-26'
    AND is_hang_km = 'Hàng bán'

)

,
/* Aggregation: Tính doanh số theo Tháng/Quý và theo Nhóm (KS/EBM/XOS) */
data_sales as (
SELECT 
    makhdms,
    /* Doanh số chi tiết từng tháng */
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  1 THEN doanhsochuavat ELSE 0 END) AS ds_chuavat_t1,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  2 THEN doanhsochuavat ELSE 0 END) AS ds_chuavat_t2,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  3 THEN doanhsochuavat ELSE 0 END) AS ds_chuavat_t3,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  4 THEN doanhsochuavat ELSE 0 END) AS ds_chuavat_t4,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  5 THEN doanhsochuavat ELSE 0 END) AS ds_chuavat_t5,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  6 THEN doanhsochuavat ELSE 0 END) AS ds_chuavat_t6,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  7 THEN doanhsochuavat ELSE 0 END) AS ds_chuavat_t7,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  8 THEN doanhsochuavat ELSE 0 END) AS ds_chuavat_t8,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  9 THEN doanhsochuavat ELSE 0 END) AS ds_chuavat_t9,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) = 10 THEN doanhsochuavat ELSE 0 END) AS ds_chuavat_t10,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) = 11 THEN doanhsochuavat ELSE 0 END) AS ds_chuavat_t11,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) = 12 THEN doanhsochuavat ELSE 0 END) AS ds_chuavat_t12,

    /* Doanh số theo nhóm CPA từng quý */
-- QUÝ 4 (T10-T12): Cut-off 26/12/2026
    SUM(CASE WHEN b.nhomcpa = 'N1' AND EXTRACT(MONTH FROM ngaychungtu) IN (10,11,12) AND ngaychungtu <= '2026-12-26' THEN doanhsochuavat ELSE 0 END) AS doanhso_n1,
    SUM(CASE WHEN b.nhomcpa = 'N2' AND EXTRACT(MONTH FROM ngaychungtu) IN (10,11,12) AND ngaychungtu <= '2026-12-26' THEN doanhsochuavat ELSE 0 END) AS doanhso_n2,
    SUM(CASE WHEN b.nhomcpa = 'N3' AND EXTRACT(MONTH FROM ngaychungtu) IN (10,11,12) AND ngaychungtu <= '2026-12-26' THEN doanhsochuavat ELSE 0 END) AS doanhso_n3,
    SUM(CASE WHEN b.nhomcpa = 'N4' AND EXTRACT(MONTH FROM ngaychungtu) IN (10,11,12) AND ngaychungtu <= '2026-12-26' THEN doanhsochuavat ELSE 0 END) AS doanhso_n4,

    -- QUÝ 3 (T7-T9)
    SUM(CASE WHEN b.nhomcpa = 'N1' AND EXTRACT(MONTH FROM ngaychungtu) IN (7,8,9) THEN doanhsochuavat ELSE 0 END) AS doanhso_n1_q3,
    SUM(CASE WHEN b.nhomcpa = 'N2' AND EXTRACT(MONTH FROM ngaychungtu) IN (7,8,9) THEN doanhsochuavat ELSE 0 END) AS doanhso_n2_q3,
    SUM(CASE WHEN b.nhomcpa = 'N3' AND EXTRACT(MONTH FROM ngaychungtu) IN (7,8,9) THEN doanhsochuavat ELSE 0 END) AS doanhso_n3_q3,
    SUM(CASE WHEN b.nhomcpa = 'N4' AND EXTRACT(MONTH FROM ngaychungtu) IN (7,8,9) THEN doanhsochuavat ELSE 0 END) AS doanhso_n4_q3,

    -- QUÝ 2 (T4-T6)
    SUM(CASE WHEN b.nhomcpa = 'N1' AND EXTRACT(MONTH FROM ngaychungtu) IN (4,5,6) THEN doanhsochuavat ELSE 0 END) AS doanhso_n1_q2,
    SUM(CASE WHEN b.nhomcpa = 'N2' AND EXTRACT(MONTH FROM ngaychungtu) IN (4,5,6) THEN doanhsochuavat ELSE 0 END) AS doanhso_n2_q2,
    SUM(CASE WHEN b.nhomcpa = 'N3' AND EXTRACT(MONTH FROM ngaychungtu) IN (4,5,6) THEN doanhsochuavat ELSE 0 END) AS doanhso_n3_q2,
    SUM(CASE WHEN b.nhomcpa = 'N4' AND EXTRACT(MONTH FROM ngaychungtu) IN (4,5,6) THEN doanhsochuavat ELSE 0 END) AS doanhso_n4_q2,

    -- QUÝ 1 (T1-T3)
    SUM(CASE WHEN b.nhomcpa = 'N1' AND EXTRACT(MONTH FROM ngaychungtu) IN (1,2,3) THEN doanhsochuavat ELSE 0 END) AS doanhso_n1_q1,
    SUM(CASE WHEN b.nhomcpa = 'N2' AND EXTRACT(MONTH FROM ngaychungtu) IN (1,2,3) THEN doanhsochuavat ELSE 0 END) AS doanhso_n2_q1,
    SUM(CASE WHEN b.nhomcpa = 'N3' AND EXTRACT(MONTH FROM ngaychungtu) IN (1,2,3) THEN doanhsochuavat ELSE 0 END) AS doanhso_n3_q1,
    SUM(CASE WHEN b.nhomcpa = 'N4' AND EXTRACT(MONTH FROM ngaychungtu) IN (1,2,3) THEN doanhsochuavat ELSE 0 END) AS doanhso_n4_q1,

    -- Tổng doanh số theo quý
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) IN (10,11,12) THEN doanhsochuavat ELSE 0 END) AS doanhsochuavat,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) IN (7,8,9)  THEN doanhsochuavat ELSE 0 END) AS doanhsochuavat_q3,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) IN (4,5,6)  THEN doanhsochuavat ELSE 0 END) AS doanhsochuavat_q2,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) IN (1,2,3)  THEN doanhsochuavat ELSE 0 END) AS doanhsochuavat_q1

FROM loc_doanhso a
LEFT JOIN `staging.d_nhom_sp_trading` b ON a.masanpham = b.masanpham
GROUP BY makhdms
 ),

/* 4. Tính toán mức chiết khấu (Rate) */
tinh_chietkhau as (
SELECT 
    a.makhdms, 
    a.ma_chuongtrinh, 
    c.custname, 
    c.channel, 
    c.shoptype, 
    c.statedescr, 
    c.districtdescr, 
    c.wardname, 
    c.hcotypeid,
    c.branchid, 
    IFNULL(b.doanhso_n1, 0) AS doanhso_n1, 
    IFNULL(b.doanhso_n2, 0) AS doanhso_n2, 
    IFNULL(b.doanhso_n3, 0) AS doanhso_n3, 
    IFNULL(b.doanhso_n4, 0) AS doanhso_n4,
    -- (Include other sales columns as needed for Q1-Q3)
    IFNULL(b.doanhso_n1_q3, 0) AS doanhso_n1_q3, 
    IFNULL(b.doanhso_n2_q3, 0) AS doanhso_n2_q3, 
    IFNULL(b.doanhso_n3_q3, 0) AS doanhso_n3_q3, 
    IFNULL(b.doanhso_n4_q3, 0) AS doanhso_n4_q3,
    -- (Include Q2, Q1...)
    IFNULL(b.doanhso_n1_q2, 0) AS doanhso_n1_q2,
    IFNULL(b.doanhso_n2_q2, 0) AS doanhso_n2_q2,
    IFNULL(b.doanhso_n3_q2, 0) AS doanhso_n3_q2,
    IFNULL(b.doanhso_n4_q2, 0) AS doanhso_n4_q2,

    IFNULL(b.doanhso_n1_q1, 0) AS doanhso_n1_q1, 
    IFNULL(b.doanhso_n2_q1, 0) AS doanhso_n2_q1, 
    IFNULL(b.doanhso_n3_q1, 0) AS doanhso_n3_q1, 
    IFNULL(b.doanhso_n4_q1, 0) AS doanhso_n4_q1,

    IFNULL(b.ds_chuavat_t1, 0) AS ds_chuavat_t1, 
    IFNULL(b.ds_chuavat_t2, 0) AS ds_chuavat_t2, 
    IFNULL(b.ds_chuavat_t3, 0) AS ds_chuavat_t3,
    IFNULL(b.ds_chuavat_t4, 0) AS ds_chuavat_t4,
    IFNULL(b.ds_chuavat_t5, 0) AS ds_chuavat_t5,
    IFNULL(b.ds_chuavat_t6, 0) AS ds_chuavat_t6,
    IFNULL(b.ds_chuavat_t7, 0) AS ds_chuavat_t7,
    IFNULL(b.ds_chuavat_t8, 0) AS ds_chuavat_t8,
    IFNULL(b.ds_chuavat_t9, 0) AS ds_chuavat_t9,
    IFNULL(b.ds_chuavat_t10, 0) AS ds_chuavat_t10,
    IFNULL(b.ds_chuavat_t11, 0) AS ds_chuavat_t11,
    IFNULL(b.ds_chuavat_t12, 0) AS ds_chuavat_t12, 

    IFNULL(b.doanhsochuavat, 0) AS doanhsochuavat, 
    IFNULL(b.doanhsochuavat_q3, 0) AS doanhsochuavat_q3, 
    IFNULL(b.doanhsochuavat_q2, 0) AS doanhsochuavat_q2, 
    IFNULL(b.doanhsochuavat_q1, 0) AS doanhsochuavat_q1, 

    /* --- RATE Q4 --- */
    -- CLC2: Tổng <15M (5%), >=15M (10%)
    CASE 
        WHEN IFNULL(b.doanhsochuavat, 0) >= 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.1
        WHEN IFNULL(b.doanhsochuavat, 0) < 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.05
        ELSE 0 
    END AS rate_clc2,
    
    -- CLC3: N1 (Luôn 5%)
    CASE WHEN ma_chuongtrinh = 'CLC3' THEN 0.05 ELSE 0 END AS rate_n1_clc3,
    
    -- CLC3: N2 (<15M: 10%, >=15M: 15%)
    CASE 
        WHEN IFNULL(b.doanhsochuavat, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.15
        WHEN IFNULL(b.doanhsochuavat, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.10
        ELSE 0 
    END AS rate_n2_clc3,

    -- CLC3: N3, N4 (<15M: 10%, >=15M: 13%)
    CASE 
        WHEN IFNULL(b.doanhsochuavat, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.13
        WHEN IFNULL(b.doanhsochuavat, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.10
        ELSE 0 
    END AS rate_n3n4_clc3,

    /* --- RATE Q3 (Tương tự Q4) --- */
    CASE 
        WHEN IFNULL(b.doanhsochuavat_q3, 0) >= 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.1
        WHEN IFNULL(b.doanhsochuavat_q3, 0) < 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.05
        ELSE 0 
    END AS rate_clc2_q3,
    CASE WHEN ma_chuongtrinh = 'CLC3' THEN 0.05 ELSE 0 END AS rate_n1_clc3_q3,
    CASE 
        WHEN IFNULL(b.doanhsochuavat_q3, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.15
        WHEN IFNULL(b.doanhsochuavat_q3, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.10
        ELSE 0 
    END AS rate_n2_clc3_q3,
    CASE 
        WHEN IFNULL(b.doanhsochuavat_q3, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.13
        WHEN IFNULL(b.doanhsochuavat_q3, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.10
        ELSE 0 
    END AS rate_n3n4_clc3_q3,

    /* --- RATE Q2 (Tương tự) --- */
    CASE 
        WHEN IFNULL(b.doanhsochuavat_q2, 0) >= 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.1
        WHEN IFNULL(b.doanhsochuavat_q2, 0) < 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.05
        ELSE 0 
    END AS rate_clc2_q2,
    CASE WHEN ma_chuongtrinh = 'CLC3' THEN 0.05 ELSE 0 END AS rate_n1_clc3_q2,
    CASE 
        WHEN IFNULL(b.doanhsochuavat_q2, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.15
        WHEN IFNULL(b.doanhsochuavat_q2, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.10
        ELSE 0 
    END AS rate_n2_clc3_q2,
    CASE 
        WHEN IFNULL(b.doanhsochuavat_q2, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.13
        WHEN IFNULL(b.doanhsochuavat_q2, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.10
        ELSE 0 
    END AS rate_n3n4_clc3_q2,

    /* --- RATE Q1 (Tương tự) --- */
    CASE 
        WHEN IFNULL(b.doanhsochuavat_q1, 0) >= 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.1
        WHEN IFNULL(b.doanhsochuavat_q1, 0) < 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.05
        ELSE 0 
    END AS rate_clc2_q1,
    CASE WHEN ma_chuongtrinh = 'CLC3' THEN 0.05 ELSE 0 END AS rate_n1_clc3_q1,
    CASE 
        WHEN IFNULL(b.doanhsochuavat_q1, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.15
        WHEN IFNULL(b.doanhsochuavat_q1, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.10
        ELSE 0 
    END AS rate_n2_clc3_q1,
    CASE 
        WHEN IFNULL(b.doanhsochuavat_q1, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.13
        WHEN IFNULL(b.doanhsochuavat_q1, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.10
        ELSE 0 
    END AS rate_n3n4_clc3_q1,

    d.col.ma_nvbh AS manv,
    e.tencvbh,
    LEFT(e.supid, 6) AS ma_crm,
    e.tenquanlytt,
    LEFT(e.rsmid, 6) AS ma_ncxm,
    e.tenquanlyvung
FROM 
    `staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` a
LEFT JOIN 
    data_sales b ON a.makhdms = b.makhdms
LEFT JOIN 
    `staging.d_master_khachhang` c ON a.makhdms = c.custid
LEFT JOIN 
    `warehouse.f_mapping_crs` d ON d.custid = a.makhdms
LEFT JOIN 
    `staging.d_users` e ON d.col.ma_nvbh = e.manv
WHERE 
    ma_chuongtrinh IN ('CLC2', 'CLC3')
)

, theo_doi_thu_hoi_hd AS (
SELECT
ma_dms,
hd_da_thuchua_thu as thu_hoi_hd,
plhd_da_thuchua_thu
FROM `spatial-vision-343005.staging.theo_doi_thu_hoi_chung_tu_ky_ben_ngoai_clc2_clc3`
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY ma_dms
    ORDER BY 
      hd_da_thuchua_thu DESC,
      plhd_da_thuchua_thu DESC
  ) = 1
)

, theo_doi_bang_ke_clc23 AS (
SELECT 
    ma_dms,
    'CLC2' as ma_chuongtrinh,
    xuat_hoa_don,
    ngay_thanh_toancan_tru_ck_can_tru_ as tt_tra_thuong_q1 ,
    ngay_thu_bang_ke,
  FROM 
    `spatial-vision-343005.staging.theo_doi_thu_hoi_chung_tu_ky_ben_ngoai_bang_ke_clc2_q12026`
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY ma_dms
    ORDER BY 
      plhd_da_thuchua_thu DESC, 
      xuat_hoa_don DESC, 
      ngay_thanh_toancan_tru_ck_can_tru_ DESC, 
      ngay_thu_bang_ke DESC
  ) = 1
UNION ALL

  SELECT 
    ma_dms,
    'CLC3' as ma_chuongtrinh,   
    xuat_hoa_don,                 
    ngay_thanh_toancan_tru,      
    ngay_thu_bang_ke,      
  FROM 
    `spatial-vision-343005.staging.theo_doi_thu_hoi_chung_tu_ky_ben_ngoai_bang_ke_clc3_q12026`
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY ma_dms 
    ORDER BY 
      plhd_da_thuchua_thu DESC, 
      xuat_hoa_don DESC, 
      ngay_thanh_toancan_tru DESC, 
      ngay_thu_bang_ke DESC
  ) = 1
)

SELECT 
    a.*,
    c.plhd_da_thuchua_thu,     
    b.xuat_hoa_don,                 
    b.tt_tra_thuong_q1,    
    b.ngay_thu_bang_ke,
    c.thu_hoi_hd,
    -- TIỀN THƯỞNG CLC2 (Total Sales * Rate)
    a.doanhsochuavat * a.rate_clc2 AS tong_tienthuong_clc12,
    a.doanhsochuavat_q3 * a.rate_clc2_q3 AS tong_tienthuong_clc12_q3,
    a.doanhsochuavat_q2 * a.rate_clc2_q2 AS tong_tienthuong_clc12_q2,
    a.doanhsochuavat_q1 * a.rate_clc2_q1 AS tong_tienthuong_clc12_q1,

    -- TIỀN THƯỞNG CLC3 (Sum of Group Sales * Group Rate)
    (a.doanhso_n1 * a.rate_n1_clc3) + (a.doanhso_n2 * a.rate_n2_clc3) + (a.doanhso_n3 * a.rate_n3n4_clc3) + (a.doanhso_n4 * a.rate_n3n4_clc3) AS tong_tienthuong_clc3,

    (a.doanhso_n1_q3 * a.rate_n1_clc3_q3) + (a.doanhso_n2_q3 * a.rate_n2_clc3_q3) + (a.doanhso_n3_q3 * a.rate_n3n4_clc3_q3) + (a.doanhso_n4_q3 * a.rate_n3n4_clc3_q3) AS tong_tienthuong_clc3_q3,

    (a.doanhso_n1_q2 * a.rate_n1_clc3_q2) + (a.doanhso_n2_q2 * a.rate_n2_clc3_q2) + (a.doanhso_n3_q2 * a.rate_n3n4_clc3_q2) + (a.doanhso_n4_q2 * a.rate_n3n4_clc3_q2) AS tong_tienthuong_clc3_q2,

    (a.doanhso_n1_q1 * a.rate_n1_clc3_q1) + (a.doanhso_n2_q1 * a.rate_n2_clc3_q1) + (a.doanhso_n3_q1 * a.rate_n3n4_clc3_q1) + (a.doanhso_n4_q1 * a.rate_n3n4_clc3_q1) AS tong_tienthuong_clc3_q1,

    /* Breakdown Chi Tiết Tiền Thưởng CLC3 */
    a.doanhso_n1 * a.rate_n1_clc3 AS tienthuong_n1_clc3,
    a.doanhso_n2 * a.rate_n2_clc3 AS tienthuong_n2_clc3,
    (a.doanhso_n3 + a.doanhso_n4) * a.rate_n3n4_clc3 AS tienthuong_n3n4_clc3,
    /*  Breakdown Chi Tiết Tiền Thưởng CLC3 theo quý */
    -- Quý 4 (Current)
    a.doanhso_n1 * a.rate_n1_clc3 AS tienthuong_n1_clc3_q4,
    a.doanhso_n2 * a.rate_n2_clc3 AS tienthuong_n2_clc3_q4,
    a.doanhso_n3 * a.rate_n3n4_clc3 AS tienthuong_n3_clc3_q4,
    a.doanhso_n4 * a.rate_n3n4_clc3 AS tienthuong_n4_clc3_q4,
    
    -- Quý 3
    a.doanhso_n1_q3 * a.rate_n1_clc3_q3 AS tienthuong_n1_clc3_q3,
    a.doanhso_n2_q3 * a.rate_n2_clc3_q3 AS tienthuong_n2_clc3_q3,
    a.doanhso_n3_q3 * a.rate_n3n4_clc3_q3 AS tienthuong_n3_clc3_q3,
    a.doanhso_n4_q3 * a.rate_n3n4_clc3_q3 AS tienthuong_n4_clc3_q3,
    -- Quý 2
    a.doanhso_n1_q2 * a.rate_n1_clc3_q2 AS tienthuong_n1_clc3_q2,
    a.doanhso_n2_q2 * a.rate_n2_clc3_q2 AS tienthuong_n2_clc3_q2,
   a.doanhso_n3_q2 * a.rate_n3n4_clc3_q2 AS tienthuong_n3_clc3_q2,
    a.doanhso_n4_q2 * a.rate_n3n4_clc3_q2 AS tienthuong_n4_clc3_q2,

    -- Quý 1
    a.doanhso_n1_q1 * a.rate_n1_clc3_q1 AS tienthuong_n1_clc3_q1,
    a.doanhso_n2_q1 * a.rate_n2_clc3_q1 AS tienthuong_n2_clc3_q1,
    a.doanhso_n3_q1 * a.rate_n3n4_clc3_q1 AS tienthuong_n3_clc3_q1,
    a.doanhso_n4_q1 * a.rate_n3n4_clc3_q1 AS tienthuong_n4_clc3_q1,
    (SELECT MAX(updated_at) FROM `warehouse.f_raw_data_sales_yoy` WHERE ngaychungtu >= '2026-01-01') AS inserted_at
FROM 
    tinh_chietkhau a
LEFT JOIN theo_doi_bang_ke_clc23 b ON a.makhdms = b.ma_dms AND a.ma_chuongtrinh = b.ma_chuongtrinh
LEFT JOIN theo_doi_thu_hoi_hd c ON a.makhdms = c.ma_dms


;