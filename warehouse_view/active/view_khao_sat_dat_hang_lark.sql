CREATE VIEW `spatial-vision-343005.warehouse.view_khao_sat_dat_hang_lark`
AS SELECT
a.stt,
a.dich_vu_giao_hang,
a.trinh_duoc_vien_tdv,
a.cham_soc_khach_hang_tai_nha_thuoc,
a.xu_ly_khieu_nai,
a.chat_luong_san_pham,
a.cham_soc_khach_hang_online_zalo_dien_thoai,
a.trai_nghiem_dat_hang_online,
null as trung_binh_ratong,
null as tong_da_gui,
a.gop_y_khac,
a0.customer_code as ma_khach_hang,
case when a.ma_khach_hang is not null then 'da_phan_hoi' else 'chua_phan_hoi' end as trang_thai_phan_hoi,
a0.created_at as ngay_gui,
a.ngay_phan_hoii,
FORMAT_TIMESTAMP('%Y-%m', a.ngay_phan_hoii) as thang_phan_hoi,
a.created_at,
a.created_name,
a.created_code,
b.col.ma_nvbh,
b.wardname,
c.custname,
d.tencvbh,
d.supid,
d.tenquanlytt
FROM `spatial-vision-343005.staging.d_tracking_survey_order` a0
LEFT JOIN `spatial-vision-343005.staging.d_khao_sat_dat_hang_lark` a on a0.customer_code = a.ma_khach_hang
LEFT JOIN `warehouse.f_mapping_crs` b on a.ma_khach_hang = b.custid
LEFT JOIN `staging.d_master_khachhang` c on a0.customer_code = c.custid
LEFT JOIN `staging.d_users` d on b.col.ma_nvbh = d.manv


;