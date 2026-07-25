CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_clc123_2024()
BEGIN

TRUNCATE TABLE `staging_temp.f_chuongtrinh_clc123_2024_temp`;

INSERT INTO `staging_temp.f_chuongtrinh_clc123_2024_temp`

(   

with

loc_dh_co_kh AS (

    SELECT 
        mahd,
        SUM(CASE WHEN doanhsochuavat = 0 THEN 1 ELSE 0 END) AS is_hangkm
    FROM `warehouse.f_raw_data_sales_yoy` a
    WHERE 
        ngaychungtu >= '2025-01-01'
        AND ngaychungtu < '2026-01-01'
        AND makhdms IN (
            SELECT makhdms 
            FROM `staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp`
            WHERE ma_chuongtrinh = 'CLC3'
        )
    GROUP BY mahd
    HAVING is_hangkm <> 0
),

loc_doanhso as 
(
SELECT 
    a.makhdms,
    a.ngaychungtu,
    a.masanpham,
    CASE 
        WHEN DATE(ngaychungtu) BETWEEN PARSE_DATE('%d/%m/%Y', SPLIT(ghichu, '-')[OFFSET(0)])
                                 AND PARSE_DATE('%d/%m/%Y', SPLIT(ghichu, '-')[OFFSET(1)])
        THEN doanhsocovat 
        ELSE 0 
    END AS doanhsocovat

FROM `warehouse.f_raw_data_sales_yoy` a
JOIN `spatial-vision-343005.staging.d_manual_danhsach_chuongtrinh_tichluy_clc123_ntpp` b 
    ON a.makhdms = b.makhdms AND b.ma_chuongtrinh IN ('CLC3', 'CLC2')

WHERE 
    ngaychungtu >= '2025-01-01'
    AND ngaychungtu < '2026-01-01'
    AND mahd NOT IN (SELECT mahd FROM loc_dh_co_kh)
),

data_sales as (
SELECT 
    makhdms,
    -- Doanh số theo từng tháng
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  1 THEN doanhsocovat ELSE 0 END) AS ds_covat_t1,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  2 THEN doanhsocovat ELSE 0 END) AS ds_covat_t2,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  3 THEN doanhsocovat ELSE 0 END) AS ds_covat_t3,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  4 THEN doanhsocovat ELSE 0 END) AS ds_covat_t4,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  5 THEN doanhsocovat ELSE 0 END) AS ds_covat_t5,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  6 THEN doanhsocovat ELSE 0 END) AS ds_covat_t6,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  7 THEN doanhsocovat ELSE 0 END) AS ds_covat_t7,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  8 THEN doanhsocovat ELSE 0 END) AS ds_covat_t8,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) =  9 THEN doanhsocovat ELSE 0 END) AS ds_covat_t9,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) = 10 THEN doanhsocovat ELSE 0 END) AS ds_covat_t10,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) = 11 THEN doanhsocovat ELSE 0 END) AS ds_covat_t11,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) = 12 THEN doanhsocovat ELSE 0 END) AS ds_covat_t12,

    -- Doanh số theo nhóm CPA từng quý
    SUM(CASE WHEN b.nhomcpa = 'KS' AND EXTRACT(MONTH FROM ngaychungtu) IN (10,11,12) THEN doanhsocovat ELSE 0 END) AS doanhso_ks,
    SUM(CASE 
        WHEN a.masanpham in ('T4040101001','T4040101002')  AND EXTRACT(MONTH FROM ngaychungtu) IN (10,11,12) THEN doanhsocovat
        WHEN b.nhomcpa = 'CL'  AND EXTRACT(MONTH FROM ngaychungtu) IN (10,11,12) THEN doanhsocovat 
        ELSE 0 END) AS doanhso_ebm,
    SUM(CASE WHEN b.nhomcpa = 'XO'  AND EXTRACT(MONTH FROM ngaychungtu) IN (10,11,12) THEN doanhsocovat ELSE 0 END) AS doanhso_xos,

    SUM(CASE WHEN b.nhomcpa = 'KS' AND EXTRACT(MONTH FROM ngaychungtu) IN (7,8,9) THEN doanhsocovat ELSE 0 END) AS doanhso_ks_q3,
    SUM(CASE 
        WHEN a.masanpham in ('T4040101001','T4040101002')  AND EXTRACT(MONTH FROM ngaychungtu) IN (7,8,9) THEN doanhsocovat
        WHEN b.nhomcpa = 'CL'  AND EXTRACT(MONTH FROM ngaychungtu) IN (7,8,9) THEN doanhsocovat 
        ELSE 0 END) AS doanhso_ebm_q3,
    SUM(CASE WHEN b.nhomcpa = 'XO'  AND EXTRACT(MONTH FROM ngaychungtu) IN (7,8,9) THEN doanhsocovat ELSE 0 END) AS doanhso_xos_q3,

    SUM(CASE WHEN b.nhomcpa = 'KS' AND EXTRACT(MONTH FROM ngaychungtu) IN (4,5,6) THEN doanhsocovat ELSE 0 END) AS doanhso_ks_q2,
    SUM(CASE 
        WHEN a.masanpham in ('T4040101001','T4040101002')  AND EXTRACT(MONTH FROM ngaychungtu) IN (4,5,6) THEN doanhsocovat
        WHEN b.nhomcpa = 'CL' AND EXTRACT(MONTH FROM ngaychungtu) IN (4,5,6) THEN doanhsocovat 
        ELSE 0 END) AS doanhso_ebm_q2,
    SUM(CASE WHEN b.nhomcpa = 'XO'  AND EXTRACT(MONTH FROM ngaychungtu) IN (4,5,6) THEN doanhsocovat ELSE 0 END) AS doanhso_xos_q2,

    SUM(CASE WHEN b.nhomcpa = 'KS' AND EXTRACT(MONTH FROM ngaychungtu) IN (1,2,3) THEN doanhsocovat ELSE 0 END) AS doanhso_ks_q1,
    SUM(CASE 
        WHEN a.masanpham in ('T4040101001','T4040101002')  AND EXTRACT(MONTH FROM ngaychungtu) IN (1,2,3) THEN doanhsocovat
        WHEN b.nhomcpa = 'CL'  AND EXTRACT(MONTH FROM ngaychungtu) IN (1,2,3) THEN doanhsocovat 
        ELSE 0 END) AS doanhso_ebm_q1,
    SUM(CASE WHEN b.nhomcpa = 'XO'  AND EXTRACT(MONTH FROM ngaychungtu) IN (1,2,3) THEN doanhsocovat ELSE 0 END) AS doanhso_xos_q1,

    -- Tổng doanh số theo quý
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) IN (10,11,12) THEN doanhsocovat ELSE 0 END) AS doanhsocovat,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) IN (7,8,9)  THEN doanhsocovat ELSE 0 END) AS doanhsocovat_q3,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) IN (4,5,6)  THEN doanhsocovat ELSE 0 END) AS doanhsocovat_q2,
    SUM(CASE WHEN EXTRACT(MONTH FROM ngaychungtu) IN (1,2,3)  THEN doanhsocovat ELSE 0 END) AS doanhsocovat_q1

FROM loc_doanhso a
LEFT JOIN `staging.d_nhom_sp_trading` b ON a.masanpham = b.masanpham

GROUP BY makhdms
 ),


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
    c.branchname, 
    c.shortterritorydescr, 
    IFNULL(b.doanhso_ks, 0) AS doanhso_ks, 
    IFNULL(b.doanhso_ebm, 0) AS doanhso_ebm, 
    IFNULL(b.doanhso_xos, 0) AS doanhso_xos, 
    IFNULL(b.doanhso_ks_q3, 0) AS doanhso_ks_q3, 
    IFNULL(b.doanhso_ebm_q3, 0) AS doanhso_ebm_q3, 
    IFNULL(b.doanhso_xos_q3, 0) AS doanhso_xos_q3, 
    IFNULL(b.doanhso_ks_q2, 0) AS doanhso_ks_q2, 
    IFNULL(b.doanhso_ebm_q2, 0) AS doanhso_ebm_q2, 
    IFNULL(b.doanhso_xos_q2, 0) AS doanhso_xos_q2, 
    IFNULL(b.doanhso_ks_q1, 0) AS doanhso_ks_q1, 
    IFNULL(b.doanhso_ebm_q1, 0) AS doanhso_ebm_q1, 
    IFNULL(b.doanhso_xos_q1, 0) AS doanhso_xos_q1, 
    IFNULL(b.ds_covat_t1, 0) AS ds_covat_t1, 
    IFNULL(b.ds_covat_t2, 0) AS ds_covat_t2, 
    IFNULL(b.ds_covat_t3, 0) AS ds_covat_t3, 
    IFNULL(b.ds_covat_t4, 0) AS ds_covat_t4, 
    IFNULL(b.ds_covat_t5, 0) AS ds_covat_t5, 
    IFNULL(b.ds_covat_t6, 0) AS ds_covat_t6, 
    IFNULL(b.ds_covat_t7, 0) AS ds_covat_t7, 
    IFNULL(b.ds_covat_t8, 0) AS ds_covat_t8, 
    IFNULL(b.ds_covat_t9, 0) AS ds_covat_t9, 
    IFNULL(b.ds_covat_t10, 0) AS ds_covat_t10, 
    IFNULL(b.ds_covat_t11, 0) AS ds_covat_t11, 
    IFNULL(b.ds_covat_t12, 0) AS ds_covat_t12, 
    IFNULL(b.doanhsocovat, 0) AS doanhsocovat, 
    IFNULL(b.doanhsocovat_q3, 0) AS doanhsocovat_q3, 
    IFNULL(b.doanhsocovat_q2, 0) AS doanhsocovat_q2, 
    IFNULL(b.doanhsocovat_q1, 0) AS doanhsocovat_q1, 
    CASE 
        WHEN a.makhdms = '003322' THEN 0.05
        WHEN IFNULL(b.doanhsocovat, 0) >= 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.1
        WHEN IFNULL(b.doanhsocovat, 0) < 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.05
        ELSE 0 
    END AS chietkhau_clc12, 
    CASE 
        WHEN IFNULL(b.doanhsocovat, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 
            IFNULL(b.doanhso_xos, 0) * 0.05 + IFNULL(b.doanhso_ebm, 0) * 0.13 + IFNULL(b.doanhso_ks, 0) * 0.15
        WHEN IFNULL(b.doanhsocovat, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 
            IFNULL(b.doanhso_xos, 0) * 0.05 + IFNULL(b.doanhso_ebm, 0) * 0.10 + IFNULL(b.doanhso_ks, 0) * 0.10
        ELSE 0 
    END AS chietkhau_clc3, 
    CASE 
        WHEN IFNULL(b.doanhsocovat, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.05
        WHEN IFNULL(b.doanhsocovat, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.05
        ELSE 0 
    END AS chietkhau_xos_clc3, 
    CASE 
        WHEN IFNULL(b.doanhsocovat, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.13
        WHEN IFNULL(b.doanhsocovat, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.10
        ELSE 0 
    END AS chietkhau_ebm_clc3, 
    CASE 
        WHEN IFNULL(b.doanhsocovat, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.15
        WHEN IFNULL(b.doanhsocovat, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.10
        ELSE 0 
    END AS chietkhau_ks_clc3, 
    CASE 
        WHEN a.makhdms = '003322' THEN 0.05
        WHEN IFNULL(b.doanhsocovat_q3, 0) >= 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.1
        WHEN IFNULL(b.doanhsocovat_q3, 0) < 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.05
        ELSE 0 
    END AS chietkhau_clc12_q3, 
    CASE 
        WHEN IFNULL(b.doanhsocovat_q3, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 
            IFNULL(b.doanhso_xos_q3, 0) * 0.05 + IFNULL(b.doanhso_ebm_q3, 0) * 0.13 + IFNULL(b.doanhso_ks_q3, 0) * 0.15
        WHEN IFNULL(b.doanhsocovat_q3, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 
            IFNULL(b.doanhso_xos_q3, 0) * 0.05 + IFNULL(b.doanhso_ebm_q3, 0) * 0.10 + IFNULL(b.doanhso_ks_q3, 0) * 0.10
        ELSE 0 
    END AS chietkhau_clc3_q3,

    CASE
        WHEN IFNULL(b.doanhsocovat_q3, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.05
        WHEN IFNULL(b.doanhsocovat_q3, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.05
        ELSE 0
    END AS chietkhau_xos_clc3_q3,

    CASE
        WHEN IFNULL(b.doanhsocovat_q3, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.13
        WHEN IFNULL(b.doanhsocovat_q3, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.1
        ELSE 0
    END AS chietkhau_ebm_clc3_q3,

    CASE
        WHEN IFNULL(b.doanhsocovat_q3, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.15
        WHEN IFNULL(b.doanhsocovat_q3, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.1
        ELSE 0
    END AS chietkhau_ks_clc3_q3,

    CASE
        WHEN a.makhdms = '003322' THEN 0.05
        WHEN IFNULL(b.doanhsocovat_q2, 0) >= 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.1
        WHEN IFNULL(b.doanhsocovat_q2, 0) < 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.05
        ELSE 0
    
    END AS chietkhau_clc12_q2,

    CASE
        WHEN IFNULL(b.doanhsocovat_q2, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3'
            THEN IFNULL(b.doanhso_xos_q2, 0) * 0.05 + IFNULL(b.doanhso_ebm_q2, 0) * 0.13 + IFNULL(b.doanhso_ks_q2, 0) * 0.15
        WHEN IFNULL(b.doanhsocovat_q2, 0) < 15000000 AND ma_chuongtrinh = 'CLC3'
            THEN IFNULL(b.doanhso_xos_q2, 0) * 0.05 + IFNULL(b.doanhso_ebm_q2, 0) * 0.1 + IFNULL(b.doanhso_ks_q2, 0) * 0.1
        ELSE 0
    END AS chietkhau_clc3_q2,

    CASE
        WHEN IFNULL(b.doanhsocovat_q2, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.05
        WHEN IFNULL(b.doanhsocovat_q2, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.05
        ELSE 0
    END AS chietkhau_xos_clc3_q2,

    CASE
        WHEN IFNULL(b.doanhsocovat_q2, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.13
        WHEN IFNULL(b.doanhsocovat_q2, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.1
        ELSE 0
    END AS chietkhau_ebm_clc3_q2,

    CASE
        WHEN IFNULL(b.doanhsocovat_q2, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.15
        WHEN IFNULL(b.doanhsocovat_q2, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.1
        ELSE 0
    END AS chietkhau_ks_clc3_q2,

    CASE
        WHEN a.makhdms = '003322' THEN 0.05
        WHEN IFNULL(b.doanhsocovat_q1, 0) >= 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.1
        WHEN IFNULL(b.doanhsocovat_q1, 0) < 15000000 AND ma_chuongtrinh = 'CLC2' THEN 0.05
        ELSE 0
    END AS chietkhau_clc12_q1,

    CASE
        WHEN IFNULL(b.doanhsocovat_q1, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3'
            THEN IFNULL(b.doanhso_xos_q1, 0) * 0.05 + IFNULL(b.doanhso_ebm_q1, 0) * 0.13 + IFNULL(b.doanhso_ks_q1, 0) * 0.15
        WHEN IFNULL(b.doanhsocovat_q1, 0) < 15000000 AND ma_chuongtrinh = 'CLC3'
            THEN IFNULL(b.doanhso_xos_q1, 0) * 0.05 + IFNULL(b.doanhso_ebm_q1, 0) * 0.1 + IFNULL(b.doanhso_ks_q1, 0) * 0.1
        ELSE 0
    END AS chietkhau_clc3_q1,

    CASE
        WHEN IFNULL(b.doanhsocovat_q1, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.05
        WHEN IFNULL(b.doanhsocovat_q1, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.05
        ELSE 0
    END AS chietkhau_xos_clc3_q1,

    CASE
        WHEN IFNULL(b.doanhsocovat_q1, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.13
        WHEN IFNULL(b.doanhsocovat_q1, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.1
        ELSE 0
    END AS chietkhau_ebm_clc3_q1,

    CASE
        WHEN IFNULL(b.doanhsocovat_q1, 0) >= 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.15
        WHEN IFNULL(b.doanhsocovat_q1, 0) < 15000000 AND ma_chuongtrinh = 'CLC3' THEN 0.1
        ELSE 0
    END AS chietkhau_ks_clc3_q1,

    d.col.ma_nvbh AS manv,
    e.tencvbh,
    LEFT(e.supid, 6) AS ma_crm,
    e.tenquanlytt,
    LEFT(e.rsmid, 6) AS ma_ncxm,
    e.tenquanlyvung,
    '' AS tinhtrang_trathuong,
    '' AS ngaychuyentien,
    '' AS ghichu
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
SELECT 
    a.*, 
    -- CLC2
    a.doanhsocovat * a.chietkhau_clc12 AS tong_tienthuong_clc12,
    a.doanhsocovat_q3 * a.chietkhau_clc12_q3 AS tong_tienthuong_clc12_q3,
    a.doanhsocovat_q2 * a.chietkhau_clc12_q2 AS tong_tienthuong_clc12_q2,
    a.doanhsocovat_q1 * a.chietkhau_clc12_q1 AS tong_tienthuong_clc12_q1,
    -- CLC3
    a.doanhso_xos * a.chietkhau_xos_clc3 AS tienthuong_xos_cls3, 
    a.doanhso_ebm * a.chietkhau_ebm_clc3 AS tienthuong_ebm_cls3,
    a.doanhso_ks * a.chietkhau_ks_clc3 AS tienthuong_ks_cls3,
    a.doanhso_xos_q3 * a.chietkhau_xos_clc3_q3 AS tienthuong_xos_cls3_q3,
    a.doanhso_ebm_q3 * a.chietkhau_ebm_clc3_q3 AS tienthuong_ebm_cls3_q3,
    a.doanhso_ks_q3 * a.chietkhau_ks_clc3_q3 AS tienthuong_ks_cls3_q3,
    a.doanhso_xos_q2 * a.chietkhau_xos_clc3_q2 AS tienthuong_xos_cls3_q2,
    a.doanhso_ebm_q2 * a.chietkhau_ebm_clc3_q2 AS tienthuong_ebm_cls3_q2,
    a.doanhso_ks_q2 * a.chietkhau_ks_clc3_q2 AS tienthuong_ks_cls3_q2,
    a.doanhso_xos_q1 * a.chietkhau_xos_clc3_q1 AS tienthuong_xos_cls3_q1,
    a.doanhso_ebm_q1 * a.chietkhau_ebm_clc3_q1 AS tienthuong_ebm_cls3_q1,
    a.doanhso_ks_q1 * a.chietkhau_ks_clc3_q1 AS tienthuong_ks_cls3_q1,
    a.doanhso_xos * a.chietkhau_xos_clc3 + a.doanhso_ebm * a.chietkhau_ebm_clc3 + a.doanhso_ks * a.chietkhau_ks_clc3 AS tong_tienthuong_clc3,
    a.doanhso_xos_q3 * a.chietkhau_xos_clc3_q3 + a.doanhso_ebm_q3 * a.chietkhau_ebm_clc3_q3 + a.doanhso_ks_q3 * a.chietkhau_ks_clc3_q3 AS tong_tienthuong_clc3_q3,
    a.doanhso_xos_q2 * a.chietkhau_xos_clc3_q2 + a.doanhso_ebm_q2 * a.chietkhau_ebm_clc3_q2 + a.doanhso_ks_q2 * a.chietkhau_ks_clc3_q2 AS tong_tienthuong_clc3_q2,
    a.doanhso_xos_q1 * a.chietkhau_xos_clc3_q1 + a.doanhso_ebm_q1 * a.chietkhau_ebm_clc3_q1 + a.doanhso_ks_q1 * a.chietkhau_ks_clc3_q1 AS tong_tienthuong_clc3_q1,
    (SELECT MAX(updated_at) FROM `warehouse.f_raw_data_sales_yoy` WHERE ngaychungtu >= '2025-01-01') AS inserted_at
FROM 
    tinh_chietkhau a

);

Create or replace table `warehouse.f_chuongtrinh_clc123_2024`

copy `staging_temp.f_chuongtrinh_clc123_2024_temp`;


END;