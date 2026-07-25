CREATE VIEW `spatial-vision-343005.warehouse.view_data_mds_tra_thuong_cmm_2025_da_tra_by_users`
AS SELECT
    -- Select all existing columns from the table
    t.p_manv,
    t.p_version,
    a.tencvbh,
    a.supid,
    a.tenquanlytt,
    -- Extract specific fields from the JSON column 'js'
    JSON_VALUE(t.js, "$.inserted_at") AS inserted_at,
    JSON_VALUE(t.js, "$.ma_kh_dms") AS ma_kh_dms,
    JSON_VALUE(t.js, "$.manv") AS manv,
    JSON_VALUE(t.js, "$.ten_kh") AS ten_kh,

    -- Tạo cột link_hinh_1
    CONCAT(
        'https://bi.meraplion.com/DMS/data_mds_tra_thuong_cmm_q32025/0_',
        JSON_VALUE(t.js, "$.ma_kh_dms"),
        '.jpeg'
    ) AS link_hinh_1,

    -- Tạo cột link_hinh_2
    CONCAT(
        'https://bi.meraplion.com/DMS/data_mds_tra_thuong_cmm_q32025/1_',
        JSON_VALUE(t.js, "$.ma_kh_dms"),
        '.jpeg'
    ) AS link_hinh_2
FROM
  `staging.get_data_mds_tra_thuong_cmm_2025_da_tra_by_users` AS t
LEFT JOIN `spatial-vision-343005.staging.d_users` AS a ON JSON_VALUE(t.js, "$.manv") = a.manv;