CREATE VIEW `spatial-vision-343005.warehouse.view_tong_hop_gui_c1_c2_c3`
AS SELECT  
a.*,
b.channel,
b.custname,
b.custnameinvoice,
b.statedescr,
b.territorydescr,

FROM `spatial-vision-343005.staging_temp.d_bang_tong_hop_gui_c123` a
LEFT JOIN `staging.d_master_khach_hang` b ON b.custid = a.ma_kh
;