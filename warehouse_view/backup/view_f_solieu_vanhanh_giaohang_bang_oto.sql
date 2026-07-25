CREATE VIEW `spatial-vision-343005.warehouse.view_f_solieu_vanhanh_giaohang_bang_oto`
AS select a.*except(thongtinxe),
  b.tram,
  c.gtype,
  trim(a.thongtinxe) as thongtinxe

from `spatial-vision-343005.warehouse.f_overview_mds_hanh1` a 
left join `spatial-vision-343005.staging.d_tinh` b  on b.tinh = a.tinh 
left join  `staging.d_master_khachhang`c on a.custid = c.custid
where date(ngayphathanhhd) between date(datetime_sub(current_datetime("+7"), INTERVAL 3 month)) and current_date("+7");