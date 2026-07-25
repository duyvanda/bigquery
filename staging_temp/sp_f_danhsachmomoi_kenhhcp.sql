CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danhsachmomoi_kenhhcp()
BEGIN

TRUNCATE TABLE staging_temp.f_danhsachmomoi_kenhhcp_temp;
INSERT INTO staging_temp.f_danhsachmomoi_kenhhcp_temp(

WITH
    data_kh_momoi_hcp AS (
        WITH
            data_kh_co_ds_trc_t4 AS (
                SELECT
                    makhdms,
                    SUM(doanhsochuavat) AS doanhsochuavat
                FROM
                    `warehouse.f_raw_data_sales_yoy` AS a
                WHERE
                    ngaychungtu < '2023-04-01'
                GROUP BY
                    1
                HAVING
                    doanhsochuavat <> 0
            ),
            data_kh_tao_saut4 AS (
                SELECT
                    custid
                FROM
                    `staging.d_master_khachhang`
                WHERE
                    channel IN ('INS', 'CLC', 'PCL')
                    AND active = 'Active'
                    AND crtd_datetime >= '2023-04-01'
            ),
            data_sales_kenh_pcl AS (
                SELECT
                    makhdms,
                    SUM(doanhsochuavat) AS doanhsochuavat,
                    MAX(thang) AS thang_datdoncuoicung,
                    MIN(thang) AS thang_datdondautien
                FROM
                    `warehouse.f_raw_data_sales_yoy` AS a
                LEFT JOIN
                    `staging.d_master_khachhang` AS b
                    ON a.makhdms = b.custid
                WHERE
                    b.channel IN ('INS', 'CLC', 'PCL')
                GROUP BY
                    1
            ),
            mapping_phanloai AS (
                SELECT
                    a.*,
                    CASE
                        WHEN b.custid IS NOT NULL THEN 'Y'
                        ELSE 'N'
                    END AS is_kh_moi_saut4_2023,
                    CASE
                        WHEN c.makhdms IS NOT NULL THEN 'Y'
                        ELSE 'N'
                    END AS is_kh_co_ds_trct4_2023
                FROM
                    data_sales_kenh_pcl AS a
                LEFT JOIN
                    data_kh_tao_saut4 AS b
                    ON a.makhdms = b.custid
                LEFT JOIN
                    data_kh_co_ds_trc_t4 AS c
                    ON c.makhdms = a.makhdms
            ),
            result AS (
                SELECT
                    *,
                    CASE
                        WHEN is_kh_moi_saut4_2023 = 'Y' THEN 'Y'
                        WHEN is_kh_moi_saut4_2023 = 'N'
                        AND is_kh_co_ds_trct4_2023 = 'N' THEN 'Y'
                        ELSE 'N'
                    END AS kh_momoi_pcl
                FROM
                    mapping_phanloai
            )
        SELECT
            *
        FROM
            result
        WHERE
            kh_momoi_pcl = 'Y'
    ),
    ds_detail AS (
        SELECT
            ngaychungtu,
            makhdms,
            SUM(doanhsochuavat) AS ds_chuavat,
            MIN(ngaychungtu) AS ngay_ps_dh_dautien,
            MAX(ngaychungtu) AS ngay_ps_dh_cuoicung
        FROM
            `warehouse.f_sales_crs`
        WHERE
            makhdms IN (
                SELECT
                    makhdms
                FROM
                    data_kh_momoi_hcp
            )
        GROUP BY
            1,
            2
        ORDER BY
            2,
            1
    )
    ,
    bang_taikoanecom1 AS (
        SELECT DISTINCT
            DATE(created_at) AS ngayactive,
            customer_phone AS sdtEO,
            customer_code AS makhEO,
            follow_phone,
            ROW_NUMBER() OVER (PARTITION BY customer_code ORDER BY created_at ASC) AS loc
        FROM
            `spatial-vision-343005.staging.f_crawl_activate_ecom`
    )
    ,
    bang_taikoanecom AS (
        SELECT
            *
        FROM
            bang_taikoanecom1
        WHERE
            loc = 1
    ),
    tuyen_dms_moinhat AS (
        WITH
            data_tuyen AS (
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
                    delroutedet IS FALSE
            )
        SELECT
            *
        FROM
            (
                SELECT
                    *,
                    ROW_NUMBER() OVER (PARTITION BY custid ORDER BY routetype ASC, crtd_datetime DESC) AS loc
                FROM
                    data_tuyen
            )
        WHERE
            loc = 1
    ),
    tuyen_cvbh_hd AS (
        WITH
            data_crs_theohopdong AS (
                SELECT
                    *,
                    ROW_NUMBER() OVER (PARTITION BY custid ORDER BY crtd_date DESC) AS loc
                FROM
                    `spatial-vision-343005.staging.d_get_contract_det`
            )
        SELECT
            *
        FROM
            data_crs_theohopdong
        WHERE
            loc = 1
    ),
    danhsachkhachhang AS (
        SELECT
            a.custid,
            a.custname,
            a.address,
            a.wardname,
            a.districtdescr,
            a.statedescr,
            a.territorydescr,
            a.hcoid,
            a.hcotypeid,
            a.channel,
            a.shoptype,
            cast(null as date) as ngaytaoOA,
            cast (null as string) as sdtOA,
            d.ngayactive,
            d.sdtEO,
            d.follow_phone,
            a.crtd_user AS ma_nguoitao,
            e.firstname AS ten_nguoitao,
            a.crtd_datetime AS ngaytao,
            a.inserted_at,
            CASE
                WHEN a.crtd_datetime >= '2023-04-01' THEN a.custid
                WHEN a.crtd_datetime < '2023-04-01'
                AND b.makhdms IS NOT NULL THEN a.custid
                ELSE NULL
            END AS kh_momoi,
            CASE
                WHEN
                    (
                        CASE
                            WHEN a.crtd_datetime >= '2023-04-01' THEN a.custid
                            WHEN a.crtd_datetime < '2023-04-01'
                            AND b.makhdms IS NOT NULL THEN a.custid
                            ELSE NULL
                        END
                    ) IS NOT NULL
                    AND (d.ngayactive IS NOT NULL) THEN a.custid
                ELSE NULL
            END AS kh_momoi_active,
            IFNULL(b.ds_chuavat, 0) AS doanhsochuavat,
            b.ngaychungtu,
            IFNULL(f.slsperid, f1.slsperid) AS slsperid,
            g.tencvbh AS tencvbh,
            g.supid AS crm,
            g.tenquanlytt AS tenquanlytt,
            g.rsmid AS ncxm,
            g.tenquanlyvung AS tenquanlyvung,
            MIN(a.crtd_datetime) OVER (PARTITION BY a.custid) AS ngay_ps_dh_dautien,
            CASE
                WHEN EXTRACT(MONTH FROM ngaychungtu) = 4 THEN ds_chuavat
                ELSE 0
            END AS ds_t4,
            CASE
                WHEN EXTRACT(MONTH FROM ngaychungtu) = 5 THEN ds_chuavat
                ELSE 0
            END AS ds_t5,
            CASE
                WHEN EXTRACT(MONTH FROM ngaychungtu) = 6 THEN ds_chuavat
                ELSE 0
            END AS ds_t6,
            CASE
                WHEN EXTRACT(MONTH FROM ngaychungtu) = 7 THEN ds_chuavat
                ELSE 0
            END AS ds_t7,
            CASE
                WHEN EXTRACT(MONTH FROM ngaychungtu) = 8 THEN ds_chuavat
                ELSE 0
            END AS ds_t8,
            CASE
                WHEN EXTRACT(MONTH FROM ngaychungtu) = 9 THEN ds_chuavat
                ELSE 0
            END AS ds_t9,
            CASE
                WHEN EXTRACT(MONTH FROM ngaychungtu) = 10 THEN ds_chuavat
                ELSE 0
            END AS ds_t10,
            CASE
                WHEN EXTRACT(MONTH FROM ngaychungtu) = 11 THEN ds_chuavat
                ELSE 0
            END AS ds_t11,
            CASE
                WHEN EXTRACT(MONTH FROM ngaychungtu) = 12 THEN ds_chuavat
                ELSE 0
            END AS ds_t12
        FROM
            `spatial-vision-343005.staging.d_master_khachhang` AS a
        LEFT JOIN
            ds_detail AS b
            ON a.custid = b.makhdms
        LEFT JOIN
            bang_taikoanecom AS d
            ON a.custid = d.makhEO
        LEFT JOIN
            `spatial-vision-343005.staging.d_dms_master_users` AS e
            ON a.crtd_user = e.username
        LEFT JOIN
            tuyen_dms_moinhat AS f
            ON f.custid = a.custid
        LEFT JOIN
            tuyen_cvbh_hd AS f1
            ON f1.custid = a.custid
        LEFT JOIN
            `staging.d_users` AS g
            ON IFNULL(f.slsperid, f1.slsperid) = g.manv
        WHERE
            a.channel IN ('CLC', 'INS', 'PCL')
            AND a.active = 'Active'
            AND a.custid NOT LIKE 'DS%'
    )
SELECT
    *
FROM
    danhsachkhachhang
WHERE
    kh_momoi IS NOT NULL

);

Create or replace table `warehouse.f_danhsachmomoi_kenhhcp`

copy `staging_temp.f_danhsachmomoi_kenhhcp_temp`;


End;