CREATE VIEW `spatial-vision-343005.warehouse.view_qua_tri_an_tet_2024`
AS SELECT
a.ma_crm,
a.ten_crm,
a.ma_crs,
a.ten_crs,
a.ma_nt,
a.ten_nt,
case when b.ma_kh is not null then 'Da_trao_qua' else 'Chua_trao_qua'  end as trang_thai_tra_thuong,
b.inserted_at as gio_check_in,
b.lat,
b.lng,
b.checkin_img_0 as link_hinh_check_in,
b.quatang_img_0 as link_hinh_qua_tang,
c.address,
c.channel,
c.shoptypedescr,
c.territorydescr,
c.statedescr
FROM `spatial-vision-343005.staging.d_danhsach_nha_thuoc_nhan_qua_tet_2024` a
LEFT JOIN `spatial-vision-343005.staging.d_qua_tri_an_tet_2024` b on a.ma_nt = b.ma_kh
left join `staging.d_master_khachhang`   c on a.ma_nt = c.custid
;