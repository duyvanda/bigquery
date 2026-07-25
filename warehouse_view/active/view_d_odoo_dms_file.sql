CREATE VIEW `spatial-vision-343005.warehouse.view_d_odoo_dms_file`
AS SELECT 
    t.name as doc_name,
    t.id as fid,
    pic,
    amount,
    en_subject,
    JSON_VALUE(t.js, '$.danh_muc') AS category,--
    JSON_VALUE(t.js, '$.phong_ban') AS department,--
    JSON_VALUE(t.js, '$.tag_name') AS tag,--
    REGEXP_EXTRACT(JSON_VALUE(t.js, '$.thu_muc'), r'([^/]+)$') AS directory,--
    JSON_VALUE(t.js, '$.thu_muc') AS directory_ori,--
    JSON_VALUE(t.js, '$.start_date') AS start_date, --
    CONCAT(JSON_VALUE(t.js, '$.thu_muc'),'/',t.name) as directory_complete_name,
    CONCAT( 'https://bi.meraplion.com/DMS/odoo_dms_file/',t.name) as full_url,


FROM `spatial-vision-343005.staging.d_odoo_dms_file` t
;