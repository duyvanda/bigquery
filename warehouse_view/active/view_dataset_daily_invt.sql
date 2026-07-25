CREATE VIEW `spatial-vision-343005.warehouse.view_dataset_daily_invt`
AS SELECT
  a.branchid as chi_nhanh,
  a.branchname as ten_chi_nhanh,
  a.siteid as ma_kho,
  a.tenkho as tenkho,
  ifnull(b.phanloaicn, 'CXD') as phan_loai_cn,
  b.chinhanh as chi_nhanh_gop,
  a.class as phan_loai_sp,
  a.invtid as ma_san_pham,
  a.tensanpham as ten_san_pham,
  a.tenspviettat as ten_san_pham_viet_tat,
  a.stkunit as unit,
  a.lotsernbr as so_lo,
  a.expdate as ngay_het_han,
  a.toncuoi as ton_cuoi,
  a.sltreohoadonao as sl_treo_hoa_don_ao,
  a.sltreochuataohoadon as sl_treo_chua_tao_hoa_don,
  a.created_date as ngay_ton_kho,
  a.manufacturedate as ngay_san_xuat
FROM `spatial-vision-343005.staging.f_sc_daily_raw_invt` a
LEFT JOIN `staging.d_sc_kho_chi_nhanh`  b on a.siteid = b.makho
where date(created_date) between date(datetime_sub(current_datetime("+7"),interval 1 month)) and current_date("+7")
QUALIFY DENSE_RANK() OVER (PARTITION BY date(created_date) ORDER BY created_date DESC) = 1;