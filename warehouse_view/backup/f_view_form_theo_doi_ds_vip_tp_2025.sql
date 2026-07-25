CREATE VIEW `spatial-vision-343005.warehouse.f_view_form_theo_doi_ds_vip_tp_2025`
AS WITH
    ds_kh AS (
        SELECT
            ma_kh,
            DATE(thoi_diem_tinh_tich_luy_doanh_so) AS thoi_diem_tinh_tich_luy_doanh_so,
            muc_doanh_so_hd_all_san_pham,
            muc_doanh_so_hd_danh_muc_f,
            dk_doanh_so_tich_luy_6_thang_all_san_pham,
            dk_doanh_so_tich_luy_6_thang_danh_muc_f
        FROM
            `spatial-vision-343005.staging.form_theo_doi_ds_vip_tp_2025`
        QUALIFY
            row_number() OVER (PARTITION BY ma_kh ORDER BY created_at DESC) = 1
    )
    ,
    thuhoi_ttmb AS (
        SELECT
            ma_kh,
            thu_hoi_ttmb,
            ghi_chu
        FROM
            `spatial-vision-343005.staging.d_manual_gs_dskh_vip_tp_da_duyet_2025`
        QUALIFY
            row_number() OVER (PARTITION BY ma_kh ORDER BY thu_hoi_ttmb DESC) = 1
    )
    ,
    sales AS (
        SELECT
            makhdms,
            DATE(ngaychungtu) AS ngaychungtu,
            SUM(CASE WHEN b.ma_sp IS NOT NULL THEN doanhsocovat ELSE 0 END) AS ds_dm_f,
            SUM(doanhsocovat) AS ds
        FROM
            `warehouse.f_raw_data_sales_yoy` a
        LEFT JOIN
            `spatial-vision-343005.staging.form_theo_doi_ds_vip_tp_2025` b
            ON a.masanpham = TRIM(b.ma_sp)
            AND b.ma_sp IS NOT NULL
        WHERE
            ngaychungtu >= '2025-01-02'
            AND ngaychungtu <= '2025-05-31' --<= '2025-12-27'
            AND a.masanpham not in ('T4040101001','T4040101002')
        GROUP BY
            ALL
    )

, mapping_sales AS (
    SELECT
        a.*,
        SUM(
            CASE
                WHEN b.ngaychungtu BETWEEN a.thoi_diem_tinh_tich_luy_doanh_so AND DATE('2025-06-30')
                    AND a.thoi_diem_tinh_tich_luy_doanh_so <= DATE('2025-06-30')
                THEN ds_dm_f
                ELSE 0
            END
        ) AS ds_dm_f_c1,
        SUM(
            CASE
                WHEN b.ngaychungtu BETWEEN a.thoi_diem_tinh_tich_luy_doanh_so AND DATE('2025-06-30')
                    AND a.thoi_diem_tinh_tich_luy_doanh_so <= DATE('2025-06-30')
                THEN ds
                ELSE 0
            END
        ) AS ds_c1,
        SUM(
            CASE
                WHEN a.thoi_diem_tinh_tich_luy_doanh_so > DATE('2025-06-30')
                    AND a.thoi_diem_tinh_tich_luy_doanh_so <= b.ngaychungtu
                THEN ds_dm_f
                WHEN a.thoi_diem_tinh_tich_luy_doanh_so <= DATE('2025-06-30')
                    AND DATE('2025-06-30') < b.ngaychungtu
                THEN ds_dm_f
                ELSE 0
            END
        ) AS ds_dm_f_c2,
        SUM(
            CASE
                WHEN a.thoi_diem_tinh_tich_luy_doanh_so > DATE('2025-06-30')
                    AND a.thoi_diem_tinh_tich_luy_doanh_so <= b.ngaychungtu
                THEN ds
                WHEN a.thoi_diem_tinh_tich_luy_doanh_so <= DATE('2025-06-30')
                    AND DATE('2025-06-30') < b.ngaychungtu
                THEN ds
                ELSE 0
            END
        ) AS ds_c2,
        SUM(
            CASE
                WHEN a.thoi_diem_tinh_tich_luy_doanh_so <= b.ngaychungtu
                THEN ds_dm_f
                ELSE 0
            END
        ) AS ds_dm_f,
        SUM(
            CASE
                WHEN a.thoi_diem_tinh_tich_luy_doanh_so <= b.ngaychungtu
                THEN ds
                ELSE 0
            END
        ) AS ds
    FROM ds_kh a
    LEFT JOIN sales b ON a.ma_kh = b.makhdms
    GROUP BY ALL
)


, ty_le_th as (
SELECT
    *,
    SAFE_DIVIDE(ds_c1, dk_doanh_so_tich_luy_6_thang_all_san_pham) AS th_kpi_c1,
    SAFE_DIVIDE(ds_dm_f_c1, dk_doanh_so_tich_luy_6_thang_danh_muc_f) AS th_kpi_dm_f_c1,
    SAFE_DIVIDE(ds_c2, dk_doanh_so_tich_luy_6_thang_all_san_pham) AS th_kpi_c2,
    SAFE_DIVIDE(ds_dm_f_c2, dk_doanh_so_tich_luy_6_thang_danh_muc_f) AS th_kpi_dm_f_c2,
    SAFE_DIVIDE(ds, muc_doanh_so_hd_all_san_pham) AS th_kpi,
    SAFE_DIVIDE(ds_dm_f, muc_doanh_so_hd_danh_muc_f) AS th_kpi_dm_f
FROM
    mapping_sales
),

thanh_tien_c1 as (
SELECT
    *,
    IF(
        th_kpi_c1 >= 1 AND th_kpi_dm_f_c1 >= 1,
        ds_dm_f_c1 * 0.1,
        0
    ) AS thanh_tien_dm_f_c1,

    CASE WHEN ds_c1 >= 0.8* dk_doanh_so_tich_luy_6_thang_all_san_pham/6*4 
    AND ds_dm_f_c1 >= 0.8* dk_doanh_so_tich_luy_6_thang_danh_muc_f/6*4 
    then ds_dm_f_c1 * 0.1 else 0 end as du_kien_thanh_tien_dm_f_c1,

    -- CASE WHEN (ds_c1 + ds_dm_f_c1) >= 0.8*(dk_doanh_so_tich_luy_6_thang_all_san_pham+dk_doanh_so_tich_luy_6_thang_danh_muc_f)/6*4 then ds_dm_f_c1 * 0.1 else 0 end as du_kien_thanh_tien_dm_f_c1,

    IF(
        th_kpi_c1 < 1 OR th_kpi_dm_f_c1 < 1,
        ds_c1,
        0
    ) AS ds_c1_bao_luu,
    IF(
        th_kpi_c1 < 1 OR th_kpi_dm_f_c1 < 1,
        ds_dm_f_c1,
        0
    ) AS ds_dm_f_c1_bao_luu,
    IF(
        th_kpi_c1 < 1,
        dk_doanh_so_tich_luy_6_thang_all_san_pham - ds_c1,
        0
    ) AS ds_c1_thieu_luy_ke,
    IF(
        th_kpi_dm_f_c1 < 1,
        dk_doanh_so_tich_luy_6_thang_danh_muc_f - ds_dm_f_c1,
        0
    ) AS ds_dm_f_c1_thieu_luy_ke
FROM
    ty_le_th
)
SELECT
    a.*,
    CASE 
        WHEN th_kpi >= 1 AND th_kpi_dm_f >= 1 THEN ds_dm_f * 0.1 - thanh_tien_dm_f_c1
        WHEN th_kpi_c2 >= 1 AND th_kpi_dm_f_c2 >= 1 THEN ds_dm_f_c2 * 0.1
        ELSE 0
    END AS thanh_tien_dm_f_c2,

    ds_dm_f * 0.1 - du_kien_thanh_tien_dm_f_c1 AS du_kien_thanh_tien_dm_f_c2,
    b.custname,
    b.channel,
    b.hcotypeid,
    b.branchid,
    b.statedescr,
    b.shortterritorydescr,
    b.shoptype,
    IF(
        DATE(b.legaldate) >= CURRENT_DATE("+7"),
        'Còn hiệu lực',
        'Hết hiệu lực'
    ) AS hieu_luc_gdp,
    b.stocksales AS tinh_trang_ma_so_thue,
    b.businessscope AS pham_vi_kinh_doanh,
    d.manv AS ma_crs,
    d.tencvbh AS ten_crs,
    d.supid AS ma_crm,
    d.tenquanlytt AS ten_crm,
    d.rsmid AS ma_ncxm,
    d.tenquanlyvung AS ten_ncxm,
    e.thu_hoi_ttmb,
    e.ghi_chu,
    (
        SELECT MAX(inserted_at)
        FROM warehouse.f_raw_data_sales_yoy
        WHERE ngaychungtu >= '2025-01-01'
    ) AS inserted_at
FROM
    thanh_tien_c1 a
LEFT JOIN
    `staging.d_master_khachhang` b ON a.ma_kh = b.custid
LEFT JOIN
    `warehouse.f_mapping_crs` c ON a.ma_kh = c.custid
LEFT JOIN
    `staging.d_users` d ON c.col.ma_nvbh = d.manv
LEFT JOIN
    thuhoi_ttmb e ON a.ma_kh = e.ma_kh

;