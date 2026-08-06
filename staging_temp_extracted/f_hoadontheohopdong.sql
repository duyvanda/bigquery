-- ==========================================================================
-- Routine Name : f_hoadontheohopdong
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-08-04 06:04:07.558000+00:00
-- Last Altered : 2026-08-04 06:04:07.558000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_hoadontheohopdong()
BEGIN

DECLARE partition_date DATE DEFAULT '2023-01-01';
-- TRUNCATE TABLE staging_temp.f_hoadontheohopdong_temp;
-- INSERT INTO staging_temp.f_hoadontheohopdong_temp
CREATE TEMP TABLE `f_hoadontheohopdong_temp`

PARTITION BY DATE(orderdate)

AS

(

WITH xuly_sohopdong_trung AS (
    SELECT DISTINCT
        a.*,
        b.contractid AS contractid_fix
    FROM
        `spatial-vision-343005.staging.xuly_sohopdong_trung` a
    LEFT JOIN
        `staging.d_oricontract` b
        ON TRIM(a.nhophongthaudiensohopdongdunggiup) = b.contractnbr
)
SELECT
    (SELECT FORMAT_TIMESTAMP("%Y-%m-%d %H:%M:%S", CURRENT_TIMESTAMP(), "Asia/Bangkok")) AS inserted_at,
    a.crtd_datetime,
    a.orderdate,
    a.origordernbr,
    a.ordertype,
    IFNULL(l.contractid_fix, CAST(a.contractid AS INT)) AS contractid_fix,
    IFNULL(TRIM(l.nhophongthaudiensohopdongdunggiup), IFNULL(b.contractnbr, TRIM(h.sohopdongdms))) AS contractnbr_fix,
    a.invcnote,
    a.invcnbr,
    a.status,
    a.custid,
    d.refcustid,
    d.custname,
    a.branchid,
    d.channel,
    d.shoptype,
    d.statedescr,
    d.shortterritorydescr,
    c.invtid,
    b.formname,
    CASE
        WHEN b.formname = 'Áp Thầu Không Phân Bổ Số Lượng' THEN 'Áp thầu'
        WHEN b.formname = 'Áp Thầu Phân Bổ Số Lượng' THEN 'Thầu'
        WHEN b.formname = 'Chào Giá Cạnh Tranh' THEN 'Thầu'
        WHEN b.formname = 'Chỉ Định Thầu Rút Gọn' THEN 'Thầu'
        WHEN b.formname = 'Đấu Thầu Trực Tiếp' THEN 'Thầu'
        WHEN b.formname = 'Mua Sắm Trực Tiếp' THEN 'Thầu'
        ELSE ''
    END AS pl_hinhthucthau,
    e.descr,
    CASE
        WHEN IFNULL(l.contractid_fix, CAST((CASE WHEN a.contractid = '0' THEN NULL ELSE a.contractid END) AS INT)) IS NOT NULL
             AND a.ordertype IN ('CO', 'IR', 'DP')
        THEN (- c.lineqty * (CASE WHEN c.invtid = 'EH126' THEN 20 ELSE e.donvitinhle END))
        WHEN IFNULL(l.contractid_fix, CAST((CASE WHEN a.contractid = '0' THEN NULL ELSE a.contractid END) AS INT)) IS NOT NULL
             AND a.ordertype NOT IN ('CO', 'IR', 'DP')
        THEN (c.lineqty * (CASE WHEN c.invtid = 'EH126' THEN 20 ELSE e.donvitinhle END))
        ELSE c.lineqty
    END AS lineqty,
    CASE
        WHEN IFNULL(l.contractid_fix, CAST((CASE WHEN a.contractid = '0' THEN NULL ELSE a.contractid END) AS INT)) IS NOT NULL
             AND a.ordertype IN ('CO', 'IR', 'DP')
        THEN (- c.beforevatprice / (CASE WHEN c.invtid = 'EH126' THEN 20 ELSE e.donvitinhle END))
        WHEN IFNULL(l.contractid_fix, CAST((CASE WHEN a.contractid = '0' THEN NULL ELSE a.contractid END) AS INT)) IS NOT NULL
             AND a.ordertype NOT IN ('CO', 'IR', 'DP')
        THEN (c.beforevatprice / (CASE WHEN c.invtid = 'EH126' THEN 20 ELSE e.donvitinhle END))
        ELSE c.beforevatprice
    END AS beforevatprice,
    CASE
        WHEN IFNULL(l.contractid_fix, CAST((CASE WHEN a.contractid = '0' THEN NULL ELSE a.contractid END) AS INT)) IS NOT NULL
             AND a.ordertype IN ('CO', 'IR', 'DP')
        THEN (- c.aftervatprice / (CASE WHEN c.invtid = 'EH126' THEN 20 ELSE e.donvitinhle END))
        WHEN IFNULL(l.contractid_fix, CAST((CASE WHEN a.contractid = '0' THEN NULL ELSE a.contractid END) AS INT)) IS NOT NULL
             AND a.ordertype NOT IN ('CO', 'IR', 'DP')
        THEN (c.aftervatprice / (CASE WHEN c.invtid = 'EH126' THEN 20 ELSE e.donvitinhle END))
        ELSE c.aftervatprice
    END AS aftervatprice,
    CASE
        WHEN a.ordertype IN ('CO', 'IR', 'DP', 'OO', 'LO')
        THEN (- c.aftervatamount * IF(freeitem, 0, 1) )
        ELSE c.aftervatamount * IF(freeitem, 0, 1)
    END AS aftervatamount,
    CASE
        WHEN a.ordertype IN ('CO', 'IR', 'DP', 'OO', 'LO')
        THEN (- c.beforevatamount * IF(freeitem, 0, 1) )
        ELSE c.beforevatamount * IF(freeitem, 0, 1)
    END AS beforevatamount,
    CASE
        WHEN a.ordertype IN ('CO', 'IR', 'DP', 'OO', 'LO')
        THEN (c.discamt + c.docdiscamt + c.groupdiscamt1) * -1
        ELSE (c.discamt + c.docdiscamt + c.groupdiscamt1)
    END AS disamt,
    c.lineqty AS ori_lineqty,
    CASE
        WHEN d.channel = 'INS' THEN hr.hovatenfullname
        ELSE ''
    END AS phutrach_chungtu,
    c.slsperid AS crs,
    IFNULL(f.orderunit, 'HOP') AS orderunit,
    g.tencvbh AS tencrs,
    g.supid,
    g.tenquanlytt,
    g.tenquanlytt AS qlkv,
    k.lotsernbr,
    k.expdate,
    b.noticenbr,
    IFNULL(m.so_du_chungtu,0) AS so_du_chungtu,
    Case when m.so_du_chungtu <= 0 Then 'Hết nợ'
    when m.so_du_chungtu > 0 Then 'Còn nợ'
    ELSE NULL END AS is_no
FROM
    `staging.sync_dms_so` a
LEFT JOIN
    `staging.sync_dms_sod1` c
    ON a.ordernbr = c.ordernbr
    AND a.branchid = c.branchid
    AND DATE(c.crtd_datetime) >= partition_date
LEFT JOIN
    xuly_sohopdong_trung l
    ON a.branchid = l.machinhanh
    AND a.custid = l.makh
    AND a.origordernbr = l.madonhang
    AND a.invcnote = l.mahoadon
    AND a.invcnbr = l.sohoadon
    AND c.invtid = l.masp
LEFT JOIN
    `staging.d_oricontract` b ON IFNULL(l.contractid_fix, CAST((CASE WHEN a.contractid = '0' THEN NULL ELSE a.contractid END) AS INT)) = b.contractid
INNER JOIN
    `staging.d_master_khachhang` d ON d.custid = a.custid
LEFT JOIN
    `staging.d_hr_dsns` hr ON staging.map_phu_trach_chung_tu_team_thau(d.shortterritorydescr) = hr.msnvcsmmoi
LEFT JOIN
    `staging.d_dms_master_invtid` e ON e.invtid = c.invtid
LEFT JOIN
    `staging.d_oricontractdet` f ON b.contractid = f.contractid
                                   AND c.invtid = f.invtid
LEFT JOIN
    `spatial-vision-343005.staging.d_users` g ON c.slsperid = g.manv
LEFT JOIN
    `spatial-vision-343005.staging.d_manual_gs_xnt_cap_nhat_thong_tin_don_hang` h
    ON a.custid = h.makhachhangdms
    AND a.origordernbr = h.sodonhang
    AND a.invcnbr = h.sohoadon
    AND c.invtid = h.masp
LEFT JOIN
    `spatial-vision-343005.staging.d_oricontract` i
    ON a.custid = h.makhachhangdms
    AND IFNULL(b.contractnbr, TRIM(h.sohopdongdms)) = i.contractnbr
LEFT JOIN
    `staging.sync_dms_lt` k
    ON c.branchid = k.branchid
    AND c.ordernbr = k.ordernbr
    AND c.invtid = k.invtid
    AND c.lineref = k.omlineref
    AND DATE(k.crtd_datetime) >= partition_date
LEFT JOIN `spatial-vision-343005.staging_temp.d_rawdata_debt` m
    ON  m.Ordnbr = a.origordernbr
    AND m.InvcNbr = a.invcnbr
    AND m.BranchID = a.branchid
WHERE
    TRUE
    AND DATE(c.crtd_datetime) >= partition_date
    AND DATE(a.orderdate) >= partition_date
    AND a.status = 'C'
    AND a.ordertype IN ('CO', 'IR', 'IN', 'DP', 'UP', 'OO', 'LO')
    AND c.invtid NOT LIKE 'V%'
-- ORDER BY
--     a.crtd_datetime DESC
);
Create or replace table `warehouse.f_hoadontheohopdong` COPY `f_hoadontheohopdong_temp`;

End;
