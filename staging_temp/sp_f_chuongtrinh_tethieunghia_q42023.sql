CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_tethieunghia_q42023()
BEGIN 
TRUNCATE TABLE staging_temp.f_chuongtrinh_tethieunghia_q42023_temp;


INSERT INTO staging_temp.f_chuongtrinh_tethieunghia_q42023_temp(

-- Create or replace table staging_temp.f_chuongtrinh_tethieunghia_q42023_temp as

WITH tuyen_dms_moinhat_bytime AS (
    WITH a AS (
        SELECT
            DISTINCT makhdms AS custid,tencvbh,tenquanlytt,
            manv AS slsperid,
            tenquanlyvung,
            CASE
                WHEN tenquanlyvung = 'Nguyễn Hoàng Viển' THEN 1
                WHEN tenquanlyvung = 'Lương Trịnh Thắng' THEN 2
                WHEN tenquanlyvung = 'Nguyễn Thọ Chiến' THEN 3
                ELSE 4
            END AS datatype,
            ngaychungtu
        FROM
            warehouse.f_sales_crs
        WHERE
            ngaychungtu >= '2023-04-01'
            AND tenquanlyvung NOT IN ('Lê Thị Hương Sa')
    )
    SELECT
        *
    FROM
        a qualify row_number() over (
            PARTITION by custid
            ORDER BY
                ngaychungtu DESC,
                datatype ASC
        ) = 1
),
tuyen_dms_moinhat AS (
    WITH data_tuyen AS (
        SELECT
            custid,
            slsperid,
            crtd_datetime,
            CASE
                WHEN routetype IN ('B', 'D') THEN 1
                ELSE 2
            END AS routetype,
        FROM
            `spatial-vision-343005.staging.sync_dms_srm`
        WHERE
            delroutedet IS false 
            and slsperid not in (
                'MR1682KN',
                'MR2504',
                'MR1232',
                'MR0806',
                'MR2608',
                'MR2111',
                'MR1682',
                'MR2504KN',
                'MR1232KN',
                'MR0806KN',
                'MR2608KN',
                'MR2111KN',
                'MR2993',
                'MR2993KN'
            )
    )
    SELECT
        *
    FROM
        data_tuyen qualify row_number() over (
            PARTITION by custid
            ORDER BY
                routetype ASC,
                crtd_datetime DESC
        ) = 1
),
data_sales AS (
    SELECT
        makhdms,
        10000000 AS thn1,
        25000000 AS thn2,
        40000000 AS thn3,
        200000000 AS dk_ds,
        sum(
            CASE
                WHEN extract(
                    MONTH
                    FROM
                        ngaychungtu
                ) = 10 THEN doanhsocovat
                ELSE 0
            END
        ) AS doanhsocovat_t10,
        sum(
            CASE
                WHEN extract(
                    MONTH
                    FROM
                        ngaychungtu
                ) = 11 THEN doanhsocovat
                ELSE 0
            END
        ) AS doanhsocovat_t11,
        sum(
            CASE
                WHEN extract(
                    MONTH
                    FROM
                        ngaychungtu
                ) = 12 THEN doanhsocovat
                ELSE 0
            END
        ) AS doanhsocovat_t12,
        sum(doanhsocovat) AS doanhsocovat,
        max(updated_at) as inserted_at
    FROM
        warehouse.f_sales_crs
    WHERE
        ngaychungtu >= '2023-10-01'
        AND ngaychungtu < '2023-12-30'
        AND makhdms IS NOT NULL
    GROUP BY
        1
),
phanqua_thn3 AS (
    SELECT
        a.*,
        DIV(
            cast(
                (
                    CASE
                        WHEN doanhsocovat > dk_ds THEN dk_ds
                        ELSE doanhsocovat
                    END
                ) AS int
            ),
            thn3
        ) AS phanqua_thn3,
    FROM
        data_sales a
),
phanqua_thn2 AS (
    SELECT
        a.*,
        DIV(
            cast(
                (
                    CASE
                        WHEN doanhsocovat > dk_ds THEN dk_ds
                        ELSE doanhsocovat
                    END
                ) AS int
            ) - phanqua_thn3 * thn3,
            thn2
        ) AS phanqua_thn2,
    FROM
        phanqua_thn3 a
),
phanqua_thn1 AS (
    SELECT
        a.*,
        DIV(
            cast(
                (
                    CASE
                        WHEN doanhsocovat > dk_ds THEN dk_ds
                        ELSE doanhsocovat
                    END
                ) AS int
            ) - phanqua_thn3 * thn3 - phanqua_thn2 * thn2,
            thn1
        ) AS phanqua_thn1,
    FROM
        phanqua_thn2 a
)
SELECT
    a.*,
    phanqua_thn3 + phanqua_thn2 + phanqua_thn1 as tong_phanqua,
    b.custname,
    b.shoptype,
    b.hcoid,
    b.hcotypeid,
    b.channel,
    b.statedescr,
    b.shortterritorydescr,
    b.branchid,
    b.branchname,
    IFNULL(c.slsperid, c1.slsperid) AS ma_crs,
    ifnull(d.tencvbh,c1.tencvbh) as tencvbh,
    d.supid AS ma_crm,
    ifnull(d.tenquanlytt,c1.tenquanlytt) as tenquanlytt,
    d.asm AS ma_scrm,
    d.tenquanlykhuvuc,
    d.rsmid AS ma_ncxm,
    d.tenquanlyvung,
    row_number() over (order by d.supid ,d.manv,b.statedescr,b.shoptype,a.doanhsocovat desc) as stt
    
FROM
    phanqua_thn1 a
    LEFT JOIN `staging.d_master_khachhang` b ON a.makhdms = b.custid
    LEFT JOIN tuyen_dms_moinhat c ON c.custid = a.makhdms 
    LEFT JOIN tuyen_dms_moinhat_bytime c1 ON c1.custid = a.makhdms
    LEFT JOIN `staging.d_users` d ON d.manv = IFNULL(c.slsperid, c1.slsperid)
WHERE
    b.shoptype IN ('PMC', 'CTD', 'PCL')
    AND b.hcotypeid NOT IN('DLPP', 'DLPP3', 'PKNK', 'NTPP', 'NTXQPK', 'SI')
    and b.hcoid not in ('DLPP3')

    AND b.active = 'Active'
);

Create or replace table `warehouse.f_chuongtrinh_tethieunghia_q42023`

copy `staging_temp.f_chuongtrinh_tethieunghia_q42023_temp`;


End;