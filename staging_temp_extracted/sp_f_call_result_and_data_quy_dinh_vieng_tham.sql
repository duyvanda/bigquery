-- ==========================================================================
-- Routine Name : sp_f_call_result_and_data_quy_dinh_vieng_tham
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-08-03 02:54:56.179000+00:00
-- Last Altered : 2026-08-03 02:54:56.179000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_call_result_and_data_quy_dinh_vieng_tham()
BEGIN

DECLARE partition_date DATE DEFAULT DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH), MONTH);
CREATE TEMP TABLE `nghiphep` AS
(
    SELECT
    DISTINCT
    manv as manvcsm,
    DATE(leave_date) AS ngay,
    type AS loainghiphep
    FROM
        `spatial-vision-343005.staging.view_d_dang_ky_nghi_phep_co_ly_do_pkh_by_user`

);

CREATE TEMP TABLE `tuyen_dms_moinhat` AS

(
    SELECT
        a.custid,
        slsperid,
        a.crtd_datetime,
        DATE(a.thang) AS thang,
        CASE
            WHEN routetype IN ('B', 'D') THEN 1
            ELSE 2
        END AS routetype,
        slsfreq
    FROM
        `spatial-vision-343005.staging.sync_dms_srm_bytime` a
        LEFT JOIN `staging.d_master_khachhang_bytime` b
            ON a.custid = b.custid
            AND a.thang = b.thang
            AND DATE(b.thang) >= DATE(partition_date)
    WHERE
        DATE(a.thang) >= DATE(partition_date) --'2024-01-01'
        AND delroutedet IS FALSE
        AND b.active = 'Active'
        -- Bỏ ngày chủ nhật
        AND a.weekdate NOT LIKE '%1'
        AND (
            CASE
                WHEN b.channel IN ('MT', 'PCL','GT') THEN TRUE
                WHEN b.channel = 'TP'
                    AND b.statedescr NOT IN ('Lạng Sơn')
                    AND CONCAT(IFNULL(b.statedescr, ''), IFNULL(b.districtdescr, '')) NOT IN (
                        'Quảng NinhThành phố Móng Cái',
                        'Quảng NinhHuyện Hải Hà',
                        'Quảng NinhHuyện Ba Chẽ',
                        'Quảng Ninh Huyện Tiên Yên',
                        'Quảng NinhHuyện Đầm Hà'
                    )
                THEN TRUE
                ELSE FALSE
            END
        )
    QUALIFY ROW_NUMBER() OVER (PARTITION BY custid, thang ORDER BY routetype ASC, crtd_datetime DESC) = 1
);

CREATE TEMP TABLE `data_quy_dinh_vieng_tham_new` AS

(
    SELECT
        date(visitdate) as visitdate,
        a.slsperid,
        a.custid,
        b.channel
    FROM
    `spatial-vision-343005.staging.sync_dms_salesroutedet` a
    JOIN tuyen_dms_moinhat c on date_trunc(date(a.visitdate), month) = c.thang and a.custid = c.custid and a.slsperid = c.slsperid
    left join `staging.d_master_khachhang_bytime` b on a.custid = b.custid and date_trunc(a.visitdate,month) =b.thang and DATE(b.thang) >= DATE(partition_date)
    where
        -- Update 22/04/2025 không bỏ tuyến tạm
        -- extendroute is false
        true
        -- Loại bỏ nếu a.visitdate là ngày CN
        AND EXTRACT(DAYOFWEEK FROM date(a.visitdate)) != 1
        and date(a.visitdate) >= DATE(partition_date)
        -- Bỏ nghỉ phép
        and concat(a.slsperid,date(a.visitdate)) not in (select concat(manvcsm,ngay) from nghiphep)
        -- Bỏ các KH đặc biệt
        and a.custid not in ('013079','013452','013458','013469','013472','007441','007442','014342','016279','010227','016137','017273','019615')
        -- Bỏ các ngày hệ thống lỗi
        and concat(a.slsperid,concat(a.custid,date(a.visitdate))) not in
        (SELECT concat(slsperid,concat(custid,date(visitdate))) FROM `spatial-vision-343005.staging.d_manual_loai_tru_call`)
        -- bỏ KH đặc biệt: Ngung kho Ha Noi => chuyen sang kho Hung Yen
        /* Tháng 01.2026 và 2.2026 loại ra KH có a.branchid = DL0001  */
        AND NOT (
            a.branchid = 'DL0001'
            AND date_trunc(date(a.visitdate), month) IN ('2026-01-01', '2026-02-01','2026-03-01')
        )
);

CREATE TEMP TABLE `f_call_result_new` PARTITION BY DATE(visitdate) AS

(

WITH data_checkin as (
    select
        slsperid,
        custid,
        branchid,
        lat,
        lng,
        typ,
        checktype,
        updatetime,
        numbercico
    from
        `spatial-vision-343005.staging.d_checkin`
    where
        DATE(updatetime) >= DATE(partition_date) --'2025-01-01'
        QUALIFY ROW_NUMBER() OVER (PARTITION BY slsperid, numbercico, checktype ORDER BY branchid) = 1
),
checkin_note as (
    select
        a.custid,
        a.visitdate,
        concat(date(a.visitdate),'_',a.custid) as ma_call_kh,
        date(date_trunc(date(a.visitdate), month)) as thang_visitdate,
        a.noteid,
        a.slsperid,
        a.note,
        a.descr,
        a.salesid,
        a.distance,
        a.checkintype,
        a.imagefilename,
        b.channel
    from
        `spatial-vision-343005.staging.sync_dms_oc` a
        left join `staging.d_master_khachhang_bytime` b on a.custid = b.custid and date_trunc(a.visitdate,month) = b.thang and DATE(b.thang) >= DATE(partition_date)
    where

        date(a.visitdate) >= DATE(partition_date) --'2025-01-01'
        and a.checkintype = 'Bán Hàng'
        -- and b.channel != 'GT'
)

/*
 CL = Close
 IO= In outlet
 PS= Program Sales
 SO= Sales ord vào step ghi nhận đơn hàng
 PA= Thanh toán công nợ
 OO= Out outlet
 DP= trưng bày
 SA= Có đơn hàng
 FC= Feedback customer
 PO = POSM/Gimmick
 SK= Stock keeping
 */
, data_quy_dinh_vieng_tham_thang as
(
select
slsperid,
custid,
date(date_trunc(date(visitdate), month)) as thang
from `data_quy_dinh_vieng_tham_new` group by 1,2,3
)
, check_dung_ngay as
(
select
DISTINCT
slsperid,
custid,
date(visitdate) as visitdate
from `data_quy_dinh_vieng_tham_new`
)
, so_call_qd as

(

SELECT
    slsperid,
    custid,
    date(date_trunc(date(visitdate), month)) as thang,
    COUNT(DISTINCT CONCAT(DATE(visitdate), custid)) AS solan_call_qd
FROM
    data_quy_dinh_vieng_tham_new
GROUP BY
    slsperid, custid, thang
)
, result_checkin as (
    SELECT
        b.*,
        a.typ as checkin,
        Case
            when a.updatetime is null then b.visitdate
            else a.updatetime
        end as time_checkin,
        a.lat,
        a.lng,
        c.typ as checkout,
        c.updatetime as time_checkout,
        f.saordernbr as ordernbr,
        f.saordernbr,
        f.ordamt
    FROM
        checkin_note b
        LEFT JOIN data_checkin a on a.slsperid = b.slsperid
        and a.custid = b.custid
        and b.salesid = a.numbercico
        and a.checktype = 'IO'
        LEFT JOIN data_checkin c on c.slsperid = b.slsperid
        and c.custid = b.custid
        and b.salesid = c.numbercico
        and c.checktype = 'OO'
        LEFT JOIN `spatial-vision-343005.staging.sync_dms_sacheckin` f on f.numbercico = b.salesid and date(f.sa_updatetime) >= DATE(partition_date)
        and f.slsperid = b.slsperid

)
, result_call_1 as (
    select
        b.*,
        g.role,
        count(b.ma_call_kh) over (partition by b.custid, date(b.visitdate), b.slsperid) as so_lan_call_1kh_trong_ngay,
        count(b.ma_call_kh) over (partition by b.thang_visitdate, b.slsperid, b.custid) as so_lan_call_1kh_trong_thang,
        Case
            when b.saordernbr is not null  then b.ma_call_kh
            else null
        end as ma_call_kh_co_dh,
        Case
            when vtt.custid is not null then 'Trong'
            else 'Ngoài'
        end as is_mcp,
        Case
            when dn.custid is not null then 'Dung'
            else 'Sai'
        end as is_dung_ngay,
        Case when  c.manvcsm is not null then 'Y' else 'N' end as is_nghi_phep,
        Case when b.descr ='Sai tọa độ khách hàng' then 'Có' else 'Không' end as is_check_mds_checkin_gh_saitoado,
        CASE
        WHEN date(b.visitdate) >= '2025-10-01' THEN
            (
             CASE
            WHEN b.channel = 'PCL' AND vtt.custid IS NOT NULL AND b.distance <  200 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL
                THEN 'Đạt'
            WHEN b.channel = 'PCL' AND vtt.custid IS NOT NULL AND b.distance >= 200 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL AND b.descr = 'Sai tọa độ khách hàng'
                THEN 'Đạt'
            WHEN b.channel IN ('TP','GT') AND vtt.custid IS NOT NULL AND b.distance < 400 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL
                THEN 'Đạt'
            WHEN b.channel IN ('TP','GT') AND vtt.custid IS NOT NULL AND b.distance >= 400 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL AND b.descr = 'Sai tọa độ khách hàng'
                THEN 'Đạt'
            -- bổ sung MT tháng 10/2025
            WHEN b.channel IN ('MT') AND e.shoptype = 'FMCG' AND vtt.custid IS NOT NULL AND b.distance < 400 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL AND r.img1 IS NOT NULL
                THEN 'Đạt'
            WHEN b.channel IN ('MT') AND e.shoptype = 'FMCG' AND vtt.custid IS NOT NULL AND b.distance >= 400 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL AND b.descr = 'Sai tọa độ khách hàng' AND r.img1 IS NOT NULL
            THEN 'Đạt'
            WHEN b.channel IN ('MT') AND e.shoptype != 'FMCG' AND vtt.custid IS NOT NULL AND b.distance < 400 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL
                THEN 'Đạt'
            WHEN b.channel IN ('MT') AND e.shoptype != 'FMCG' AND vtt.custid IS NOT NULL AND b.distance >= 400 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL AND b.descr = 'Sai tọa độ khách hàng'
                THEN 'Đạt'
            ELSE 'Không đạt' END
             )
        WHEN date(b.visitdate) >= '2025-06-01' THEN
            (

            CASE
            WHEN b.channel = 'PCL' AND vtt.custid IS NOT NULL AND b.distance <  200 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL
                THEN 'Đạt'
            WHEN b.channel = 'PCL' AND vtt.custid IS NOT NULL AND b.distance >= 200 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL AND b.descr = 'Sai tọa độ khách hàng'
                THEN 'Đạt'
            WHEN b.channel IN ('TP', 'MT','GT') AND vtt.custid IS NOT NULL AND b.distance < 400 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL
                THEN 'Đạt'
            WHEN b.channel IN ('TP', 'MT','GT') AND vtt.custid IS NOT NULL AND b.distance >= 400 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL AND b.descr = 'Sai tọa độ khách hàng'
                THEN 'Đạt'
            ELSE 'Không đạt' END
            )
        WHEN date(b.visitdate) <= '2025-05-31' THEN
            (

            CASE
            WHEN b.channel = 'PCL' AND vtt.custid IS NOT NULL AND b.distance <  200 AND c.manvcsm IS NULL
                THEN 'Đạt'
            WHEN b.channel = 'PCL' AND vtt.custid IS NOT NULL AND b.distance >= 200 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL AND b.descr = 'Sai tọa độ khách hàng'
                THEN 'Đạt'
            WHEN b.channel IN ('TP', 'MT','GT') AND vtt.custid IS NOT NULL AND b.distance < 400 AND c.manvcsm IS NULL
                THEN 'Đạt'
            WHEN b.channel IN ('TP', 'MT','GT') AND vtt.custid IS NOT NULL AND b.distance >= 400 AND c.manvcsm IS NULL AND b.imagefilename IS NOT NULL AND b.descr = 'Sai tọa độ khách hàng'
                THEN 'Đạt'
            ELSE 'Không đạt' END
            )
        ELSE NULL END AS is_call_dat,
        Case
            when vtt.custid is  null then b.custid
            else null
        end as ma_kh_checkin_ngoai_mcp,
        Case
            when b.saordernbr is not null then b.custid
            else null
        end as ma_kh_phat_sinh_dh,
        vtt.custid as ma_kh_mcp,
        d.slsfreq

    from
        result_checkin b
        LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` g on g.username = b.slsperid
        LEFT JOIN data_quy_dinh_vieng_tham_thang vtt on date_trunc(date(b.visitdate), month) =vtt.thang
                                 and vtt.custid = b.custid and vtt.slsperid = b.slsperid
        LEFT JOIN check_dung_ngay dn on dn.custid = b.custid and dn.slsperid = b.slsperid and dn.visitdate = date(b.visitdate)
        LEFT JOIN nghiphep c on date(b.visitdate) = c.ngay and b.slsperid = c.manvcsm
        LEFT JOIN  tuyen_dms_moinhat  d on date_trunc(date(b.visitdate), month) = d.thang
                                 and b.custid = d.custid and b.slsperid = d.slsperid

        LEFT JOIN `staging.d_master_khachhang` e on e.custid = b.custid
        LEFT JOIN
                (SELECT *
                FROM `spatial-vision-343005.staging.d_display_criteria_remark`
                WHERE displayid = '2509-QD-CI-FMCG' and DATE(visitdate) >= DATE(partition_date)) r
        ON r.salesid = b.salesid
)
, result_call_2 as (
    select r.*,
    case when is_call_dat = 'Đạt' then ma_call_kh else null end as ma_call_kh_dat,
    case when is_call_dat = 'Đạt' then custid else null end as ma_kh_dat
    from result_call_1 r
)

/*
05fbcd56-ac61-46de-b0fc-0fbcd9c1ebbd
f600371d-6db6-4e47-8542-b567daf131e1
slsperid = 'MR1612' and date(visitdate)>= '2025-03-01' and date(visitdate)<= '2025-03-31'
Ví dụ 2 call này đều đạt => Chỉ tính 1 call đầu tiên trong ngày => Xử lý lại ma_call_kh_dat
*/
, result_call_3 as (
select
r.* except (ma_call_kh_dat),
    dense_rank() over (partition by r.custid, date(r.visitdate), r.slsperid, r.ma_call_kh_dat is not null order by r.visitdate ) as stt_di_call_1kh_trong_ngay,
    case
    when ma_call_kh_dat is not null and
    dense_rank() over (partition by r.custid, date(r.visitdate), r.slsperid, r.ma_call_kh_dat is not null order by r.visitdate ) = 1
    then ma_call_kh_dat else null end as ma_call_kh_dat,
    ma_call_kh_dat as ma_call_kh_dat_ban_dau
from
    result_call_2 r
)

/*
4a2195fb-0243-4bfe-9a12-f16a6d6bbdb0
da4d1286-cc89-4932-a039-f2b9954db7cc
cddab519-1851-4ed9-9378-b43f21c032b4
de159b12-f39f-4820-9987-f33a8efd71e3
061c87ac-a2e8-4cb3-a6ca-9a5f7df675ba

slsperid = 'MR1612' and date(visitdate)>= '2025-03-01' and date(visitdate)<= '2025-03-31' and custid = 'N0320605'
Ví dụ 5 call này đều đạt => Chỉ tính 4 call đầu tiên trong tháng, do số quy định đi trong tháng chỉ có 4 calls => Xử lý lại ma_call_kh_dat
*/
, result_call_4 as (
select
r.* except (ma_call_kh_dat),
    dense_rank() over (partition by r.custid, thang_visitdate, r.slsperid, r.ma_call_kh_dat is not null order by r.visitdate ) as stt_di_call_1kh_trong_thang,
    qd.solan_call_qd,
    case
    when ma_call_kh_dat is not null and
    dense_rank() over (partition by r.custid, thang_visitdate, r.slsperid, r.ma_call_kh_dat is not null order by r.visitdate ) <= qd.solan_call_qd
    then ma_call_kh_dat else null end as ma_call_kh_dat,
from
    result_call_3 r
    LEFT JOIN so_call_qd qd on qd.thang = r.thang_visitdate and qd.slsperid = r.slsperid and qd.custid = r.custid
)

select r.*,
case
when ma_call_kh_dat_ban_dau is not null and ma_call_kh_dat is null and stt_di_call_1kh_trong_ngay > 1 then 'Vượt số call trong ngày'
when ma_call_kh_dat_ban_dau is not null and ma_call_kh_dat is null then 'Vượt số call trong tháng'
else null end as phan_loai_vuot_gioi_han_call,
case when ma_call_kh_dat is not null then 'Đạt' else 'Không đạt' end as is_call_dat_v2
from result_call_4 r

);

-- Create or replace table `warehouse.f_call_result`
-- copy `f_call_result`;
-- Create or replace table `warehouse.data_quy_dinh_vieng_tham`
-- copy `data_quy_dinh_vieng_tham`;
BEGIN TRANSACTION;
DELETE FROM
    `warehouse.f_call_result`
WHERE
    DATE(visitdate) >= DATE(partition_date);
INSERT INTO
    `warehouse.f_call_result`
SELECT
    *
FROM
    `f_call_result_new`;
COMMIT TRANSACTION;

BEGIN TRANSACTION;
DELETE FROM
    `warehouse.data_quy_dinh_vieng_tham`
WHERE
    DATE(visitdate) >= DATE(partition_date);
INSERT INTO
    `warehouse.data_quy_dinh_vieng_tham`
SELECT
    *
FROM
    `data_quy_dinh_vieng_tham_new`;
COMMIT TRANSACTION;
END;
