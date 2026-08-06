-- ==========================================================================
-- Routine Name : f_tongquat_ctkm
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-06-26 09:32:50.810000+00:00
-- Last Altered : 2026-06-26 09:32:50.810000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_tongquat_ctkm()
BEGIN

DECLARE partition_date DATE DEFAULT DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH), MONTH);
-- TRUNCATE TABLE staging_temp.f_tongquat_ctkm_temp;
-- INSERT INTO `staging_temp.f_tongquat_ctkm_temp`
CREATE TEMP TABLE `f_tongquat_ctkm_new` PARTITION BY DATE(ngaychungtu)  AS

(

-- DECLARE partition_date DATE DEFAULT '2023-01-01';
-- Create or replace table `staging_temp.f_tongquat_ctkm_temp`
-- partition by date(ngaychungtu)
-- cluster by discseq,mahd,makhdms,manv
-- as
WITH _ctkm AS
(
    SELECT
        discidpn,
        descr,
        branchid,
        discid,
        lineref,
        discseq,
        ordernbr,
        discamt,
        disctblamt AS disctblamt_ori,
        SPLIT(
            CASE
                WHEN groupreflineref IS NULL THEN solineref
                WHEN solineref = '' OR solineref IS NULL OR freeitemqty < 1 THEN groupreflineref
                ELSE CONCAT(groupreflineref, ",", solineref)
            END
        ) AS groupreflineref
    FROM `staging.f_orddisc_all`
    WHERE DATE(crtd_datetime) >= partition_date
),
__ctkm AS
(
    SELECT
        -- distinct
        discidpn,
        lineref,
        descr,
        branchid,
        discid,
        discseq,
        ordernbr,
        groupreflineref,
        discamt,
        disctblamt_ori
    FROM _ctkm, _ctkm.groupreflineref AS groupreflineref
),
disctblamt AS
(
    SELECT
        branchid,
        ordernbr,
        lineref,
        SUM(lineqty * aftervatprice * (CASE WHEN freeitem IS TRUE THEN 0 ELSE 1 END)) AS disctblamt
    FROM `staging.sync_dms_sod1`
    WHERE DATE(crtd_datetime) >= partition_date
    GROUP BY branchid, ordernbr, lineref
),
___ctkm AS
(
    SELECT
        a.*,
        b.disctblamt AS lineamt,
        SUM(b.disctblamt) OVER (PARTITION BY a.branchid, a.ordernbr, a.discseq, a.discid, a.lineref) AS disctblamt
    FROM __ctkm a
    LEFT JOIN disctblamt b
        ON a.branchid = b.branchid AND a.ordernbr = b.ordernbr AND a.groupreflineref = b.lineref
    -- WHERE a.ordernbr = 'HL5-0124-02366'
),
ctkm AS
(
    SELECT
        DISTINCT
        discidpn,
        -- lineref,
        descr,
        branchid,
        discid,
        discseq,
        ordernbr,
        groupreflineref,
        discamt,
        disctblamt
    FROM ___ctkm
),
discamt AS
(
    SELECT
        branchid,
        ordernbr,
        lineref,
        SUM(discamt + groupdiscamt1 + docdiscamt) AS discamt
    FROM `spatial-vision-343005.staging.sync_dms_sod1`
    WHERE (discamt + groupdiscamt1 + docdiscamt) > 0
    AND DATE(crtd_datetime) >= partition_date
    GROUP BY branchid, ordernbr, lineref
),
group_p AS
(
    SELECT
        a.discidpn,
        a.ordernbr,
        a.branchid,
        groupreflineref AS group_split,
        SUM(discamt) AS discamt,
        SUM(disctblamt) AS disctblamt,
        MAX(a.discseq) AS discseq,
        MAX(b.discounttype) AS discounttype,
        MAX(b.discountdescr) AS discountdescr,
        MAX(a.descr) AS descr,
        MAX(b.startdate) AS startdate,
        MAX(b.enddate) AS enddate,
        MAX(b.statusname) AS statusname
    FROM ctkm a
    LEFT JOIN `spatial-vision-343005.staging.d_discseq` b
        ON a.discseq = b.discseq
    GROUP BY a.discidpn, a.ordernbr, a.branchid, groupreflineref
),
tuyenban AS
(
    WITH data_tuyen AS
    (
        SELECT
            -- thang,
            a.custid,
            a.slsperid,
            a.crtd_datetime,
            CASE
                WHEN a.routetype IN ('B', 'D') THEN 1
                ELSE 2
            END AS routetype,
            b.tenquanlytt_bh
        FROM `spatial-vision-343005.staging.sync_dms_srm` a
        LEFT JOIN `spatial-vision-343005.staging.d_users` b
            ON a.slsperid = b.manv
        WHERE a.delroutedet IS FALSE
            -- AND slsperid NOT IN ('MR1008', 'MR1705', 'MR2610', 'MR1225', 'MR2596', 'MR2594', 'MR2611')
    )
    SELECT *
    FROM
    (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY custid ORDER BY routetype ASC, crtd_datetime DESC) AS loc
        FROM data_tuyen
    )
    WHERE loc = 1
    -- AND custid  = '008817'
),
result AS
(
    SELECT
        b.discseq,
        b.discidpn,
        -- CASE
        --     WHEN b.loai_ctkm = 'L' THEN 'Dòng Sản phẩm'
        --     WHEN b.loai_ctkm = 'D' THEN 'Chứng từ'
        --     WHEN b.loai_ctkm = 'G' THEN 'Nhóm sản phẩm'
        --     ELSE b.loai_ctkm
        -- END AS loai_ctkm,
        b.descr,
        b.startdate,
        b.enddate,
        b.discounttype AS loai_ct,
        b.discountdescr AS apdung,
        a.macongtycn,
        a.congtycn,
        a.ngaychungtu,
        a.sodondathang,
        a.mahd,
        a.makhdms,
        a.tenkhachhang,
        a.hoadon,
        a.makenhkh,
        a.makenhphu,
        a.tentinhkh,
        a.tenquanhuyen,
        a.masanpham,
        a.tensanphamviettat,
        a.tensanphamnb,
        a.lineref,
        a.soluong,
        a.dongiachuavat,
        a.dongiacovat,
        a.doanhsochuavat,
        a.doanhsocovat,
        a.manv,
        a.tencvbh,
        a.tenquanlytt,
        a.tenquanlykhuvuc,
        a.tenquanlyvung,
        CASE
            WHEN statusname = 'Đang hoạt động' AND DATE(b.enddate) >= CURRENT_DATE() THEN 1
            ELSE 0
        END AS active,
        CASE
            WHEN a.doanhsochuavat = 0 THEN 1
            ELSE 0
        END AS sp_kmai,
        Case
        when l.col.phan_loai_mcp = 'Rural'
        or a.manv = 'TMDT_001'
        or a.manv in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
        "MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608")
        or (a.makenhphu not in ('SI23', 'SI', 'CTD') and k1.tenquanlytt = 'Nguyễn Văn Tiến' and ngaychungtu < '2024-01-01')
        then l.col.ma_nvbh
      else a.manv
      end as ma_nvbh,
        -- dis.discamt AS total_discamt,
        SAFE_DIVIDE(a.soluong * a.dongiacovat * b.discamt, b.disctblamt) AS discamt,
        Case
        when masanpham in ('VT80307','VT80098') then 160000 * soluong
        when doanhsocovat = 0 then soluong * dongiacovat
        else 0 end  as chi_phi_hang_km,
        dis.discamt AS lineref_total_discamt,
        kh.hcoid,
        kh.hcotypeid,
        kh.shortterritorydescr
    FROM `spatial-vision-343005.staging.f_sales` a
    LEFT JOIN discamt dis
        ON a.mahd = dis.ordernbr
        AND a.macongtycn = dis.branchid
        AND a.lineref = dis.lineref
    INNER JOIN group_p b
        ON a.mahd = b.ordernbr
        AND a.macongtycn = b.branchid
        AND group_split = a.lineref
    LEFT JOIN `warehouse.f_mapping_crs_bytime` l on l.custid = a.makhdms and date_trunc(ngaychungtu,month) = l.thang
    LEFT JOIN `spatial-vision-343005.staging.d_users` k1
        ON l.col.ma_nvbh = k1.manv
    LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` kh
        ON a.makhdms = kh.custid
    WHERE DATE(ngaychungtu) >= partition_date and macongtycn != 'DL0001'
)

SELECT
    a.*,
    Case
    when a.manv = 'CX' then 'MR1682'
    else left(b.supid,6)
    end as crm,
    Case
    when a.manv = 'CX' then 'CX'
    else b.tencvbh
    end as ten_nvbh,
    -- b.tencvbh as ten_nvbh,
    Case
    when a.manv = 'CX' then 'Đinh Thị Ngọc Mẫn'
    else b.tenquanlytt
    end as tenquanlytt_bh,
    COALESCE(SAFE_DIVIDE(discamt, 1 + (thuesuat/100)), 0) as discamt_chuavat
    -- b.tenquanlytt_bh,
FROM result a
LEFT JOIN `spatial-vision-343005.staging.d_users` b
    ON CASE WHEN RIGHT(a.ma_nvbh,2)= 'KN' THEN LEFT(a.ma_nvbh,6) ELSE a.ma_nvbh END = b.manv
LEFT JOIN `staging.d_dms_master_invtid` i on a.masanpham = i.invtid

);

-- Create or replace table `warehouse.f_tongquat_ctkm` COPY `f_tongquat_ctkm`;
BEGIN TRANSACTION;
DELETE FROM
    `warehouse.f_tongquat_ctkm`
WHERE
    DATE(ngaychungtu) >= DATE(partition_date);
INSERT INTO
    warehouse.f_tongquat_ctkm
SELECT
    *
FROM
    f_tongquat_ctkm_new;
COMMIT TRANSACTION;
END;
