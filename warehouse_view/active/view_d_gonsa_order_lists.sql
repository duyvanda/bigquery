CREATE VIEW `spatial-vision-343005.warehouse.view_d_gonsa_order_lists`
AS SELECT
    t.id AS id_don_hang,
    JSON_VALUE(t.js, "$.accountno") AS ma_kh_dms,
    JSON_VALUE(t.js, "$.created_at") AS ngay_tao,
    JSON_VALUE(t.js, "$.current_status") AS trang_thai_hien_tai,
    JSON_VALUE(t.js, "$.current_status_label") AS ten_trang_thai_hien_tai,
    JSON_VALUE(t.js, "$.date_send_gs") AS ngay_gui_gs,
    JSON_VALUE(t.js, "$.delivery_note") AS ghi_chu_giao_hang,
    JSON_VALUE(t.js, "$.order_date") AS ngay_dat_hang,
    JSON_VALUE(t.js, "$.partner_order_code") AS ma_don_hang_dms,
    JSON_VALUE(t.js, "$.receiver_name") AS ten_nguoi_nhan,
    JSON_VALUE(t.js, "$.receiver_phone") AS so_dien_thoai_nguoi_nhan,
    JSON_VALUE(t.js, "$.sales_employee_name") AS ten_nhan_vien_kinh_doanh,
    JSON_VALUE(t.js, "$.ship_city") AS thanh_pho_giao_hang,
    JSON_VALUE(t.js, "$.ship_country") AS quoc_gia_giao_hang,
    JSON_VALUE(t.js, "$.ship_state") AS tinh_giao_hang,
    JSON_VALUE(t.js, "$.ship_street") AS duong_giao_hang,
    JSON_VALUE(t.js, "$.ship_ward") AS phuong_xa_giao_hang,
    JSON_VALUE(t.js, "$.updated_at") AS ngay_cap_nhat,
    JSON_VALUE(t.js, "$.warehouse_code") AS ma_kho,
    t.part_date AS ngay_tao_du_lieu,
    JSON_VALUE(p, "$.datetime") AS thoi_gian_trang_thai,
    JSON_VALUE(p, "$.label") AS ten_trang_thai_lich_su
FROM
    `staging.d_gonsa_order_lists` AS t,
    UNNEST(JSON_QUERY_ARRAY(t.js, "$.status_history")) AS p
    -- WHERE id = 243
ORDER BY
    thoi_gian_trang_thai DESC;