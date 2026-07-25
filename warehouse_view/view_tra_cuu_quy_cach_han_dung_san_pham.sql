CREATE VIEW `spatial-vision-343005.warehouse.view_tra_cuu_quy_cach_han_dung_san_pham`
AS WITH quy_cach_sp AS (
  SELECT 
    *
  FROM `spatial-vision-343005.staging.d_dms_master_invtid`
  WHERE danhmucsanpham = 'Sản Phẩm Bán'
)
, han_su_dung_sp AS (
  SELECT 
    t.invtid,
    t.tensanpham,
    MAX(t.expdate) as han_su_dung_xa_nhat,
    MIN(t.expdate) as han_su_dung_gan_nhat
  FROM `spatial-vision-343005.warehouse.f_rawdata_tonkho_daily` t
  -- Thực hiện INNER JOIN với bảng d_dms_master_siteid thay vì nhập tay mã kho
  INNER JOIN `spatial-vision-343005.staging.d_dms_master_siteid` s
    ON t.makho = s.siteid -- Bạn lưu ý đổi tên cột 'siteid' này nếu trong bảng master nó tên là mã khác (ví dụ: makho, site_id,...)
  WHERE t.branchid not in ('DL0001')
    AND LEFT(t.invtid,1) not in ('V')
    AND LOWER(s.sitetypedescr) LIKE '%hàng bán%' -- Điều kiện lọc sitetypedescr chứa chữ 'hàng bán' viết thường
  GROUP BY ALL
)

SELECT 
  q.quycachdonggoi,
  q.sohopthung,
  IFNULL(q.invtid, h.invtid) as invtid,
  IFNULL(q.descr, h.tensanpham) as descr,
  NULLIF(h.han_su_dung_xa_nhat, '1900-01-01') as han_su_dung_xa_nhat,
  NULLIF(h.han_su_dung_gan_nhat, '1900-01-01') as han_su_dung_gan_nhat
FROM quy_cach_sp q
FULL JOIN han_su_dung_sp h 
  ON q.invtid = h.invtid;;