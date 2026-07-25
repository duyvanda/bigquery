CREATE VIEW `spatial-vision-343005.warehouse.f_crs_mcp_thap`
AS WITH base_date as (
SELECT
    ngay,
    EXTRACT(DAYOFWEEK FROM ngay) AS thu_ngay,
    ROW_NUMBER() OVER (
        PARTITION BY
            EXTRACT(MONTH FROM ngay),
            EXTRACT(DAYOFWEEK FROM ngay),
            EXTRACT(YEAR FROM ngay)
        ORDER BY
            ngay
    ) AS tuan
FROM
    UNNEST(
        GENERATE_DATE_ARRAY(
            DATE_TRUNC(CURRENT_DATE(), YEAR),
            DATE(EXTRACT(YEAR FROM CURRENT_DATE()), 12, 31)
        )
    ) AS ngay
WHERE
    EXTRACT(DAYOFWEEK FROM ngay) NOT IN (1, 7)
ORDER BY
    1
)

, cal_distance as (
SELECT
    DATE(a.visitdate) AS visitdate,
    a.slsperid,
    a.custid,
    CASE WHEN c.classid = 'KA' THEN c.custid ELSE NULL END AS custid_ka,
    CASE WHEN c.classid = 'RB' THEN c.custid ELSE NULL END AS custid_rb,
    CASE WHEN c.classid = 'RC' THEN c.custid ELSE NULL END AS custid_rc,
    b.lat AS latvido,
    b.lng AS lngkinhdo,
    c.lat,
    c.lng,
    ROUND(
        ST_DISTANCE(
            ST_GEOGPOINT(b.lng, b.lat),
            ST_GEOGPOINT(c.lng, c.lat)
        ),
        0
    ) AS distance_in_meters
FROM
    `staging.sync_dms_salesroutedet` a
LEFT JOIN
    `staging.d_crs_location` b
    ON a.slsperid = b.manv
LEFT JOIN
    `staging.d_master_khachhang` c
    ON a.custid = c.custid
WHERE
    c.active = 'Active'
GROUP BY
    ALL
ORDER BY
    1
)

, min_distance as (
SELECT
    visitdate,
    slsperid,
    COUNT(DISTINCT custid)     AS sl_kh,
    COUNT(DISTINCT custid_ka)  AS sl_kh_ka,
    COUNT(DISTINCT custid_rb)  AS sl_kh_rb,
    COUNT(DISTINCT custid_rc)  AS sl_kh_rc,
    MIN(distance_in_meters)    AS min_distance_in_meters,
    MAX(distance_in_meters)    AS max_distance_in_meters
FROM
    cal_distance
GROUP BY
    visitdate,
    slsperid
ORDER BY
    1
)

, mapping_min_max as (
SELECT
    a.*,
    b.custid AS min_custid,
    b.lat    AS min_lat,
    b.lng    AS min_lng,
    c.custid AS max_custid,
    c.lat    AS max_lat,
    c.lng    AS max_lng
FROM
    min_distance a
LEFT JOIN
    cal_distance b
    ON a.visitdate = b.visitdate
    AND a.slsperid = b.slsperid
    AND a.min_distance_in_meters = b.distance_in_meters
LEFT JOIN
    cal_distance c
    ON a.visitdate = c.visitdate
    AND a.slsperid = c.slsperid
    AND a.max_distance_in_meters = c.distance_in_meters
)

, result_distance as (
SELECT
    a.*,
    ROUND(
        ST_DISTANCE(
            ST_GEOGPOINT(a.min_lng, a.min_lat),
            ST_GEOGPOINT(a.max_lng, a.max_lat)
        ),
        0
    ) AS distance_in_meters_min_max
FROM
    mapping_min_max a
QUALIFY
    ROW_NUMBER() OVER (
        PARTITION BY visitdate, slsperid
        ORDER BY distance_in_meters_min_max DESC
    ) = 1
)

, all_nv as (
    select 
    distinct a.slsperid,
    date(a.visitdate) as visitdate,
    FROM `staging.sync_dms_salesroutedet` a
    LEFT JOIN  `spatial-vision-343005.staging.d_master_khachhang` d ON d.custid = a.custid  
    where d.active = 'Active'
    AND a.slsperid is not null and slsperid not like '%GH%' --and slsperid not like '%KN%'
)

SELECT
    a.*,
    al.slsperid AS manv,
    d.tencvbh AS nhanvien,
    --b.lat AS latvido,
    --b.lng AS lngkinhdo,
    hr.diabanlamviec as province,
    --b.district,
    c.sl_kh,
    c.sl_kh_ka,
    c.sl_kh_rb,
    c.sl_kh_rc,
    c.min_distance_in_meters,
    c.max_distance_in_meters,
    c.distance_in_meters_min_max,
    d.supid,
    d.tenquanlytt,
    d.tenquanlyvung,
    CASE
        WHEN d.tenquanlyvung LIKE '%Viển%' THEN 'TP'
        WHEN d.tenquanlyvung LIKE '%Chiến%' THEN 'HCP'
        WHEN d.tenquanlyvung LIKE '%Sa%' THEN 'MT'
        ELSE NULL
    END AS kenh,
    (SELECT MAX(inserted_at) FROM `warehouse.view_f_data_checkin_pbh_v3`) AS inserted_at
FROM
    base_date a
LEFT JOIN
    `all_nv` al ON a.ngay = al.visitdate
-- LEFT JOIN
--     `staging.d_crs_location` b ON al.slsperid = b.manv
LEFT JOIN
    `result_distance` c ON a.ngay = c.visitdate AND al.slsperid = c.slsperid
LEFT JOIN
    `staging.d_users` d ON al.slsperid = d.manv
LEFT JOIN
    `spatial-vision-343005.staging.d_hr_dsns` hr ON d.manv = hr.msnvcsmmoi
WHERE
    d.position IN ('S', 'D')
    AND (IFNULL(d.tenquanlyvung,'') LIKE '%Viển%' OR IFNULL(d.tenquanlyvung,'') LIKE '%Sa%')
    --AND tuan <= 4
ORDER BY
    al.slsperid,
    ngay

;