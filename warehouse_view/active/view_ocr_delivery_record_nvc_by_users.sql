CREATE VIEW `spatial-vision-343005.warehouse.view_ocr_delivery_record_nvc_by_users`
AS  
  select
  a.*,
  c.makhdms as custid,
  b.ordernbr as origordernbr,
  c.hoadon as invcnbr,
  CONCAT('https://bi.meraplion.com/DMS/kt_bbgh_proof_nvc/0_', a.ma_chung_tu, a.ma_chi_nhanh, '.jpeg') AS ocr_url
  FROM `spatial-vision-343005.staging.sync_ocr_delivery_record_nvc` a
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_rd` b on a.ma_chung_tu = b.reportid and a.ma_chi_nhanh = b.branchid
  LEFT JOIN `staging.f_sales` c on b.ordernbr = c.sodondathang and c.ngaychungtu>= '2026-03-01';