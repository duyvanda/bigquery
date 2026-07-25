CREATE VIEW `spatial-vision-343005.warehouse.view_f_chuongtrinh_vip_hcp_2025_pbh`
AS WITH 
    data_sales AS 
    (
        SELECT 
            a.makhdms,
            SUM(doanhsocovat) AS doanhsocovat
        FROM `warehouse.f_raw_data_sales_yoy` a
        WHERE ngaychungtu >= '2025-01-01' 
            AND ngaychungtu < '2026-01-01'
        GROUP BY a.makhdms
    )

SELECT
    a1.custidinvoice AS invoicecustid,
    a1.custid,
    a1.custname,
    a1.hcotypeid,
    a1.shoptype,
    a1.hcoid,
    a1.channel,
    a1.branchid,
    a1.shortterritorydescr AS territorydescr,
    a1.statedescr,
    IFNULL(b.doanhsocovat, 0) AS doanhsocovat,
    CASE 
        WHEN IFNULL(b.doanhsocovat, 0) >= 600000000 
            AND IFNULL(b.doanhsocovat, 0) < 2000000000 THEN 0.03
        WHEN IFNULL(b.doanhsocovat, 0) >= 2000000000 THEN 0.05
        ELSE 0 
    END AS muc_chiet_khau,
    IFNULL(b.doanhsocovat, 0) * 
        (CASE 
            WHEN IFNULL(b.doanhsocovat, 0) >= 600000000 
                AND IFNULL(b.doanhsocovat, 0) < 2000000000 THEN 0.03
            WHEN IFNULL(b.doanhsocovat, 0) >= 2000000000 THEN 0.05
            ELSE 0 
        END) AS tong_tien_chiet_khau,
    l.col.ma_nvbh AS ma_crs,
    e.tencvbh,
    LEFT(e.supid, 6) AS ma_crm,
    e.tenquanlytt,
    LEFT(e.rsmid, 6) AS ma_ncxm,
    e.tenquanlyvung,
    '' AS ngaythanhtoantienck_q1,
    '' AS tinhtrang_thanhtoan_q1,
    '' AS ghichu_thanhtoan_q1
FROM
    `staging.d_master_khachhang` a1
    LEFT JOIN data_sales b ON a1.custid = b.makhdms
    LEFT JOIN `warehouse.f_mapping_crs` l ON l.custid = a1.custid
    LEFT JOIN `staging.d_users` e ON l.col.ma_nvbh = e.manv
-- WHERE
--     a1.custid = 'MSPC0033';