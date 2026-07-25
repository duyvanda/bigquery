CREATE VIEW `spatial-vision-343005.warehouse.view_d_manual_theo_doi_hang_gui_kho_hcp`
AS SELECT
a.ngay_goi_kho,
a.so_don_hang,
a.so_hoa_don,
a.ngay_hoa_don,
a.ma_khach_hang,
a.khach_hang,
a.ma_sp,
a.ten_sp,
a.don_vi_tinh_nho_nhat,
a.so_luong_gui_dvt_nho_nhat,
a.don_vi_tinh_hop,
a.so_luong_gui_dvt_hop,
a.so_lo,
a.date,
a.thanh_tien_gui_kho,
a.du_kien_ngay_nhan_het,
a.mr_da_nhan_bbgk,
a.mr_da_nhan_hoa_don_bh,
a.so_luong_kh_nhan_dvt_hop,
a.ngay_nhan_thuc_te,
a.so_luong_con_lai_dvt_hop,
a.ghi_chu,
a.tinh,
a.crm,
a.cx,
a.ngay_update,
a.ma_cx,
b.channel,
b.shoptype,
b.statedescr_unidecode,
b.territorydescr,
-- a.id_user,
-- a.access_key,
-- a.active,
-- a.deleted_at,
a.created_at,
-- a.created_name,
-- a.created_code,
dense_rank() over(partition by ma_cx order by created_at desc) as moi_nhat
FROM `spatial-vision-343005.staging.d_manual_theo_doi_hang_gui_kho_hcp` a
left join `spatial-vision-343005.staging.d_master_khachhang`    b    ON trim(a.ma_khach_hang) = b.custid
-- where ma_khach_hang like '%HH03E017%'










;