CREATE VIEW `spatial-vision-343005.warehouse.view_d_data_don_hang_san_shopee`
AS SELECT
a.* EXCEPT(
        ma_giam_gia_cua_shop, 
        phi_co_dinh, 
        phi_dich_vu, 
        phi_thanh_toan,
        tong_so_tien_duoc_nguoi_ban_tro_gia
    ),
-- Chia đều mã giảm giá, các loại phí và trợ giá
    a.ma_giam_gia_cua_shop / COUNT(a.ma_don_hang) OVER (PARTITION BY a.ma_don_hang) AS ma_giam_gia_cua_shop,
    a.phi_co_dinh / COUNT(a.ma_don_hang) OVER (PARTITION BY a.ma_don_hang) AS phi_co_dinh,
    a.phi_dich_vu / COUNT(a.ma_don_hang) OVER (PARTITION BY a.ma_don_hang) AS phi_dich_vu,
    a.phi_thanh_toan / COUNT(a.ma_don_hang) OVER (PARTITION BY a.ma_don_hang) AS phi_thanh_toan,
    a.tong_so_tien_duoc_nguoi_ban_tro_gia / COUNT(a.ma_don_hang) OVER (PARTITION BY a.ma_don_hang) AS tong_so_tien_duoc_nguoi_ban_tro_gia,
b.ma_san_pham_merap,
b.so_luong as sl_1DVT,
c.don_gia_nhap_hang_tu_merap_chua_vat,
c.don_gia_ban_tren_shopee_chua_vat,
c.don_gia_nhap_hang_tu_merap_da_co_vat,
c.don_gia_ban_tren_shopee_vat,
c.chenh_lech_tien_loima_sp_chua_vat,
IFNULL(don_gia_nhap_hang_tu_merap_chua_vat, 0) * (
    (IFNULL(a.so_luong, 0) - IFNULL(so_luong_san_pham_duoc_hoan_tra, 0)) * IFNULL(b.so_luong, 0)
) AS tong_doanh_thu_gia_ban_buon_chua_vat,
FROM `spatial-vision-343005.staging.d_data_don_hang_san_shopee` a
LEFT JOIN `spatial-vision-343005.staging.d_data_bundle_san_shopee` b 
  ON b.sku_phan_loai_hang = a.sku_phan_loai_hang
LEFT JOIN `spatial-vision-343005.staging.d_data_san_pham_san_shopee` c
  ON c.ma_sp = b.ma_san_pham_merap
  AND DATE(a.ngay_dat_hang) BETWEEN DATE(c.thoi_gian_apply_tu) AND DATE(c.thoi_gian_apply_den)
--where ma_don_hang = '260601W2E59807'

;