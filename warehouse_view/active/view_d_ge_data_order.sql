CREATE VIEW `spatial-vision-343005.warehouse.view_d_ge_data_order`
AS WITH rt_data as

(
SELECT
a.ngay_don_hang,
a.so_don_hang,
-- a.id_phieu_xuat_tong,
-- a.id_bang_ke_so_xuat_hang,
a.san_ra_le,
a.so_luong_tui,
a.so_luong_thung,
-- a.u_dieu_phoi_dong_tui,
a.t_dieu_phoi_dong_tui,
a.u_nhat_hang,
a.t_nhat_hang,
-- a.u_ket_thuc_nhat_hang,
a.t_ket_thuc_nhat_hang,
-- a.u_dong_goi,
a.t_dong_goi,
-- a.u_ban_giao,
a.t_ban_giao_log,
a.trang_thai_gh,
a.thoi_gian_dms_ge,
a.inserted_at,
a.ma_so_xuat_hang_dms,
a.p_version,
'' as p_manv
FROM `staging.d_ge_data_order_by_users` a
-- WHERE a.p_version = version
-- UNION ALL
-- SELECT
-- a.ngay_don_hang,
-- a.so_don_hang,
-- a.san_ra_le,
-- a.so_luong_tui,
-- a.so_luong_thung,
-- a.t_dieu_phoi_dong_tui,
-- a.u_nhat_hang,
-- a.t_nhat_hang,
-- a.t_ket_thuc_nhat_hang,
-- a.t_dong_goi,
-- a.t_ban_giao_log,
-- a.trang_thai_gh,
-- a.thoi_gian_dms_ge,
-- a.inserted_at,
-- a.ma_so_xuat_hang_dms,
-- version as p_version,
-- '' as p_manv
-- FROM `staging.d_ge_data_order` a
-- where date(a.ngay_don_hang)<= date_add(current_date(), INTERVAL - 15 DAY)

)



SELECT
a.ngay_don_hang,
a.so_don_hang,
b.ordertype as loai_don_hang,
b.branchid,
b.custid,
c.slsperid as nguoi_giao_hang_sxh,

-- a.id_phieu_xuat_tong,
-- a.id_bang_ke_so_xuat_hang,
a.san_ra_le,
a.so_luong_tui,
a.so_luong_thung,
-- a.u_dieu_phoi_dong_tui,
a.t_dieu_phoi_dong_tui,
a.u_nhat_hang,
a.t_nhat_hang,
-- a.u_ket_thuc_nhat_hang,
a.t_ket_thuc_nhat_hang,
-- a.u_dong_goi,
a.t_dong_goi,
-- a.u_ban_giao,
a.t_ban_giao_log,
a.trang_thai_gh,
a.thoi_gian_dms_ge,
case when b.status = 'C' then b.lupd_datetime else null end AS gio_duyet_don,
a.inserted_at,
a.ma_so_xuat_hang_dms,
'' as p_version,
'' as p_manv,
d.custname,
d.channel,
d.shoptype,
d.statedescr,
d.territorydescr,
e.tencvbh,
h.nhom,
CASE 
    WHEN TIME(a.t_ban_giao_log) BETWEEN PARSE_TIME('%H:%M', h.dot_1_ban_giao_tu) AND PARSE_TIME('%H:%M', h.dot_1_ban_giao_den) 
      THEN 'Đợt 1'
    WHEN TIME(a.t_ban_giao_log) BETWEEN PARSE_TIME('%H:%M', h.dot_2_ban_giao_tu) AND PARSE_TIME('%H:%M', h.dot_2_ban_giao_den) 
      THEN 'Đợt 2'
    WHEN TIME(a.t_ban_giao_log) BETWEEN PARSE_TIME('%H:%M', h.dot_3_ban_giao_tu) AND PARSE_TIME('%H:%M', h.dot_3_ban_giao_den) 
      THEN 'Đợt 3'
    ELSE 'Ngoài đợt / Không xác định'
  END AS dot_ban_giao

FROM rt_data a
LEFT JOIN `staging.sync_dms_pda_so` b on a.so_don_hang = b.ordernbr
LEFT JOIN `staging.sync_dms_ib` c on c.branchid = b.branchid and c.batnbr = a.ma_so_xuat_hang_dms
left join `spatial-vision-343005.staging.d_master_khachhang`  d on b.custid = d.custid
left join `spatial-vision-343005.staging.d_users`    e on c.slsperid = e.manv
LEFT JOIN `spatial-vision-343005.staging.d_manual_gs_mds_cutoff` AS h
  ON d.statedescr = h.tinh;