CREATE VIEW `spatial-vision-343005.warehouse.view_f_chat_pingme_ai`
AS SELECT
    a.id,
    a.message,
    a.src,
    a.user_id,
    a.user_code,
    a.user_name,
    a.datetime,
    a.created_at,
    a.updated_at,
    a.inserted_at,
    b.phongdeptsummary
FROM
    `staging.f_chat_pingme_ai` a
LEFT JOIN spatial-vision-343005.staging.d_hr_dsns b on a.user_code = b.msnvcsmmoi;