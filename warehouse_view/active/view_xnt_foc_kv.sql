CREATE VIEW `spatial-vision-343005.warehouse.view_xnt_foc_kv`
AS WITH sell_in as (
SELECT
s.masanpham,
SUM(s.soluongori) as sell_in_ori
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` s 
WHERE s.makhdms in ('021400') and date(s.ngaychungtu) >= '2026-07-01'
AND is_hang_km = 'Hàng KM'
GROUP BY ALL
)
, don_hang_kv as (
SELECT
a.invtid,
SUM (a.line_qty) as sl_sell_out_tong,
SUM (CASE WHEN a.status = 'C' THEN a.line_qty ELSE 0 END) as sl_sell_out_xuat,
FROM `spatial-vision-343005.staging.d_data_kim_do_final` a
WHERE date(a.crtd_datetime) >= '2026-07-01' 
AND status not in ('V', 'E')
AND parnerid = 'KV'
AND free_item = 1
GROUP BY ALL
)
SELECT
a.ma_kh,
a.ma_sp,
a.ten_sp as ten_sp,
a.min_stock as dinh_muc,
a.safety_stock as dinh_muc_an_toan,
a.reorder_point_rop as nguong_dat_don_hang,
IFNULL(s.sell_in_ori,0) as sell_in_ori,
IFNULL(s.sell_in_ori,0) as sell_in,
IFNULL(gs.sl_sell_out_tong,0) as sl_sell_out_tong,
IFNULL(gs.sl_sell_out_xuat,0) as sl_sell_out_xuat,

/* ================= XỬ LÝ CỘT CẢNH BÁO ================= */
  -- CASE 
  --   WHEN (IFNULL(s.sell_in_ori, 0) - IFNULL(gs.sl_sell_out_xuat, 0)) <= a.safety_stock THEN 'Nguy hiểm'
  --   WHEN (IFNULL(s.sell_in_ori, 0) - IFNULL(gs.sl_sell_out_xuat, 0)) <= a.reorder_point_rop THEN 'Cảnh báo'
  --   ELSE 'Bình thường'
  -- END as muc_canh_bao,

  -- CASE 
  --   WHEN (IFNULL(s.sell_in_ori, 0) - IFNULL(gs.sl_sell_out_xuat, 0)) <= a.safety_stock THEN 'Ưu tiên nhập hàng'
  --   WHEN (IFNULL(s.sell_in_ori, 0) - IFNULL(gs.sl_sell_out_xuat, 0)) <= a.reorder_point_rop THEN 'Lập PO hoặc chuẩn bị đặt hàng'
  --   ELSE 'Không cần làm gì'
  -- END as hanh_dong

FROM `spatial-vision-343005.staging.d_dinh_muc_ton_kho_kv` a
LEFT JOIN sell_in s ON s.masanpham = a.ma_sp 
LEFT JOIN don_hang_kv gs ON a.ma_sp = gs.invtid


;