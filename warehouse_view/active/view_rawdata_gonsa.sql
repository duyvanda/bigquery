CREATE VIEW `spatial-vision-343005.warehouse.view_rawdata_gonsa`
AS SELECT
a.*,
CASE 
    WHEN a.status = 'H' THEN 'Chờ xử lý'
    WHEN a.status = 'E' THEN 'Hủy'
    WHEN a.status = 'C' THEN ' Hoàn Tất (Ghi nhận ds)'
    ELSE null
  END AS ten_trang_thai_MR,

  CASE a.trangthaidonhangdoitac
    WHEN 'WAIT_TO_CONFIRM' THEN 'Chờ xác nhận'
    WHEN 'CONFIRMED'       THEN 'Đơn hàng Buymed đã nhận từ đối tác'
    WHEN 'PROCESSING'      THEN 'Đang xử lý'
    WHEN 'WAIT_TO_DELIVER' THEN 'Chờ giao'
    WHEN 'DELIVERING'      THEN 'Đang giao'
    WHEN 'DELIVERED'       THEN 'Đã giao'
    WHEN 'COMPLETED'       THEN 'Hoàn tất (đã đối soát)'
    WHEN 'CANCEL'          THEN 'Đã hủy'
    ELSE null
  END AS ten_trang_thai_BM,

  b.kho_gonsa_nhan as kho_gonsa


FROM
    `staging.d_data_kim_do_final` a

LEFT JOIN `staging.d_ds_kho_gonsa` b on a.statename = b.tinh 

WHERE date(a.crtd_datetime) >= '2026-03-16'
-- WHERE date(a.crtd_datetime) >= '2026-01-01';