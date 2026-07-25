CREATE VIEW `spatial-vision-343005.warehouse.view_f_sc_daily_raw_invt_by_users`
AS SELECT 
a.branchid,
a.branchname,
a.siteid,
a.tenkho,
a.class,
a.invtid,
a.tensanpham,
a.tenspviettat,
a.stkunit,
a.quycachdonggoi,
a.quycachthung,
a.lotsernbr,
a.expdate,
a.sothangconlai,
a.tondau,
a.nhapmuahang,
a.nhapkhacnhapchuyendieuchinh,
a.xuatban,
a.nhaptra,
a.xuatkhacxuatchuyendieuchinh,
a.dcbbxuat,
a.dcbbnhap,
a.toncuoi,
a.sltreohoadonao,
a.sltreochuataohoadon,
a.toncuoisosach,
a.giaban,
a.tttoncuoi,
a.manv,
a.version,
a.inserted_at,
a.manufacturedate,
b.sohopthung,
c.vitri

FROM `spatial-vision-343005.staging.f_sc_daily_raw_invt_by_users` a
left join `spatial-vision-343005.staging.d_dms_master_invtid` b on a.invtid = b.invtid
LEFT JOIN `spatial-vision-343005.staging.d_manual_danh_muc_vi_tri_sp` c on a.branchid = c.sanrale and a.invtid = c.masp





;