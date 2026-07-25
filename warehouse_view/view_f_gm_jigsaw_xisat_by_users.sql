CREATE VIEW `spatial-vision-343005.warehouse.view_f_gm_jigsaw_xisat_by_users`
AS SELECT

a.id_user,
a.id_customer_oa,
a.id_customer,
a.avatar,
a.customer_code,
a.customer_name,
a.pharmacy_name,
a.phone,
a.full_name,
a.zalo_name,
a.customer_role_name,
a.card_code,
a.card_seri,
a.card_price,
a.lucky_code,
a.card_type_name,
a.times,
a.is_win,
a.is_rewarded,
a.is_finished,
a.active,
a.created_at,
a.updated_at,
a.status_reward,
a.tong_card,
a.datatype,
p_version,
a.p_manv,
a.inserted_at,
b.channel,
b.shoptypedescr,
b.territorydescr,
b.districtdescr,

ifnull(mcrs.col.ma_nvbh, 'CX') as ma_crs,
ifnull(d.tencvbh, 'CX') as tencvbh,
ifnull(d.supid, 'CX') as supid,
ifnull(d.tenquanlytt, 'CX') as tenquanlytt,

FROM `spatial-vision-343005.staging.f_gm_jigsaw_xisat_by_users` a
left join `spatial-vision-343005.staging.d_master_khachhang` b on a.customer_code = b.custid

left join `warehouse.f_mapping_crs` mcrs on a.customer_code = mcrs.custid
left join `spatial-vision-343005.staging.d_users` d on mcrs.col.ma_nvbh = d.manv
where a.p_version = 'T103124218'





;