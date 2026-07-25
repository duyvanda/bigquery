CREATE VIEW `spatial-vision-343005.warehouse.view_f_data_checkin_pbh_v2`
AS SELECT
attn,
branchid,
channel,
check_viengtham_thang,
checkin,
checkintype,
checkout,
classid,
custid,
custname,
descr,
distance,
districtdescr,
imagefilename,
inserted_at,
is_bosung_crs,
is_check_mds_checkin_gh_saitoado,
is_checkin_bh as is_call_dat,
is_checkin_bh_v2 as is_call_dat_v2,
is_checkin_onl,
is_daviengtham,
is_hetthoihanhieuluc,
is_hspl,
is_lich_call as dtype,
is_mcp,
is_nghi_phep,
is_saphetthoihanhieuluc,
is_ttkh,
ischeck_vuot_gioihancall as phan_loai_vuot_gioi_han_call,
lat,
lng,
ma_crm,
ma_ncxm,
ma_scrm,
mds,
note,
noteid,
ordamt,
ordernbr,
phan_loai_call,
phone,
pl_kh_checkin,
pl_solan_call,
role,
salesid,
saordernbr,
shoptype,
sl_checkin_ka,
sl_checkin_kb,
sl_checkin_kc,
sl_checkin_khac,
sl_dh_thucte,
-- sl_kh_checkin,
sl_kh_checkin as ma_kh_dat,
-- sl_kh_checkin_ngoaimcp,
sl_kh_checkin_ngoaimcp as ma_kh_checkin_ngoai_mcp,
sl_kh_checkin_thucte_ka,
sl_kh_checkin_thucte_kb,
sl_kh_checkin_thucte_kc,
sl_kh_checkin_thucte_khac,
sl_kh_phatsinhdh,
-- sl_quydinh,
sl_quydinh as ma_kh_can_vieng_tham,
sl_quydinh_ka,
sl_quydinh_kb,
sl_quydinh_kc,
sl_quydinh_khac,
slsfreq,
slsperid,
so_kh_viengtham_tt,
-- so_lan_call_trong_ngay,
so_lan_call_trong_ngay as so_lan_call_1kh_trong_ngay,
-- so_lan_call_trong_thang,
so_lan_call_trong_thang as so_lan_call_1kh_trong_thang,
so_ngay_chua_mua_hang,
solan_call_qd,
-- soluong_checkin_thucte,
soluong_checkin_thucte as ma_call_kh_dat,
-- soluong_checkin_thucte_ori,
soluong_checkin_thucte_ori as ma_call_kh_dat_ban_dau,
soluong_checkin_thucte_vuot,
soluong_dh_ngoaituyen,
soluong_dh_trongtuyen,
-- soluong_ngoaituyen,
soluong_ngoaituyen as ma_call_kh_dat_ngoai_tuyen,
-- soluong_trongtuyen,
soluong_trongtuyen as ma_call_kh_dat_trong_tuyen,
statedescr,
taxregnbr,
tenquanlykhuvuc,
tenquanlytt,
tenquanlyvung,
territorydescr,
thoi_gian_checkin,
thoihanhieulucgdpgpp,
time_checkin,
time_checkout,
visitdate,
visitdate_mapping,
-- xephang,
xephang as stt_di_call_1kh_trong_thang
FROM `spatial-vision-343005.warehouse.f_data_checkin_pbh_v2`;