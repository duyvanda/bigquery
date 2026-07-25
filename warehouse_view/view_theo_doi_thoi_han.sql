CREATE VIEW `spatial-vision-343005.warehouse.view_theo_doi_thoi_han`
AS SELECT 
  created_date,
  TIMESTAMP_DIFF(expdate, CURRENT_TIMESTAMP(), DAY) AS Songayconlai,
  CONCAT(invtid, ' - ', tensanpham) AS combined_name,
  branchid,
  branchname,
  siteid,
  tenkho,
  invtid,
  tensanpham,
  tenspviettat,
  lotsernbr,
  expdate,
  toncuoi,
  CASE WHEN TIMESTAMP_DIFF(expdate, CURRENT_TIMESTAMP(), DAY) < 0 THEN 'Hết Hạn' ELSE 'Còn Hạn' END AS Songayconlaireal,
  CASE WHEN tenkho LIKE '%chờ hủy%' OR tenkho LIKE '%chờ xử lý%' THEN 'Chờ hủy' ELSE 'Khác' END AS Nhom_kho

FROM `spatial-vision-343005.staging.f_sc_daily_raw_invt` 
WHERE created_date = (SELECT created_date FROM `spatial-vision-343005.staging.f_sc_daily_raw_invt` ORDER BY created_date DESC LIMIT 1)
ORDER BY Songayconlai;