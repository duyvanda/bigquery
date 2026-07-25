CREATE VIEW `spatial-vision-343005.warehouse.f_overview_mds_hanh1`
AS SELECT
branchid,
ordernbr,
ordernbr_co,
truckid,
ng_taoso,
ten_taoso,
ordertype,
origordernbr,
custid,
status_pda_so,
slsperid_pda_so,
ngaytaodon,
status_iv,
ngayphathanhhd,
status_ib,
ngaychotso,
deliveryunit,
status_dv,
slsperid_dv,
ngaygiaohang,
inserted_at,
trangthaidon,
nguoibanhang,
t4,
full_leadtime,
role,
mds_sxh,
mds,
sup_mds,
mng_mds,
channel as kenh,
terms,
tenkhachhang as custname,
statedescr as tinh,
shoptype as kenhphu,
paymentsform as hinhthucthanhtoan,
chinhanh,
districtdescr,
wardname,
invtid,
lineqty,
freeitem,
siteid,
beforevatprice,
beforevatamount,
aftervatprice,
aftervatamount,
vatamount,
lotsernbr,
expdate,
tensp_viettat,
tensp_daydu,
thongtinxe,
thongtinxe_sxh,
donghang_tinh,
nguoidonghang_tinh,
deliveryunit_code,
tao_bbght,
vptt,
deliveryunitname,
ngaygiaohang as ngay_xacnhan_nhanhang,
cast (null as TIMESTAMP	) as ngay_kh_k_nhanhang

FROM `spatial-vision-343005.warehouse.f_leadtime_new_detail1`
where channel not in ( 'OTH', 'NB' );