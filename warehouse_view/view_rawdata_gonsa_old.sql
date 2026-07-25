CREATE VIEW `spatial-vision-343005.warehouse.view_rawdata_gonsa_old`
AS WITH raw_data as (
SELECT
    a.branchid,
    a.ordernbr,
    a.status,
    a.remark,
    a.custid,
    a.custname,
    a.phone,
    a.addres,
    a.statename,
    a.districtname,
    a.chargereceive,
    a.ordamt,
    a.crtd_datetime,
    a.item_type,
    a.invtid,
    a.invtname,
    a.lineref,
    a.free_item,
    a.sls_price,
    a.line_qty,
    a.line_amt,
    --a.slspername,
    c.col. ma_nvbh as manv, 
    a.ordertype,
    a.descr,
    -- a.inserted_at,
    -- a.discseq,
    a.discidpn,
    b.kho_gonsa_nhan,
    a.discname
    -- a.discbreakname
FROM
    `staging.d_data_kim_do_final` a
LEFT JOIN `staging.d_ds_kho_gonsa` b on a.statename = b.tinh
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` c on a.custid = c.custid
WHERE date(a.crtd_datetime) >= '2025-06-01'
AND a.ordernbr not in
(
    'KD0-0625-00208', 'KD0-0625-00198', 'KD0-0625-00201', 'KD0-0625-00191',
    'KD0-0625-00202', 'KD0-0625-00200', 'KD0-0625-00199', 'KD0-0625-00192',
    'KD0-0625-00171', 'KD0-0625-00176', 'KD0-0625-00189', 'KD0-0625-00174',
    'KD0-0625-00166', 'KD0-0625-00181', 'KD0-0625-00177', 'KD0-0625-00178',
    'KD0-0625-00185', 'KD0-0625-00172', 'KD0-0625-00188', 'KD0-0625-00169',
    'KD0-0625-00173', 'KD0-0625-00159', 'KD0-0625-00155', 'KD0-0625-00156',
    'KD0-0625-00142', 'KD0-0625-00137', 'KD0-0625-00082', 'KD0-0625-00076',
    'KD0-0625-00101', 'KD0-0625-00122', 'KD0-0625-00102', 'KD0-0625-00124',
    'KD0-0625-00083', 'KD0-0625-00074', 'KD0-0625-00078', 'KD0-0625-00077',
    'KD0-0625-00079', 'KD0-0625-00120', 'KD0-0625-00094', 'KD0-0625-00050',
    'KD0-0525-01135', 'KD0-0625-00012', 'KD0-0625-00013', 'KD0-0625-00061',
    'KD0-0625-00040', 'KD0-0625-00062', 'KD0-0625-00064', 'KD0-0625-00065',
    'KD0-0625-00066', 'KD0-0625-00068', 'KD0-0625-00067', 'KD0-0625-00019',
    'KD0-0625-00009', 'KD0-0625-00024', 'KD0-0625-00069', 'KD0-0625-00054',
    'KD0-0625-00051', 'KD0-0525-01139', 'KD0-0625-00030', 'KD0-0625-00023',
    'KD0-0625-00036', 'KD0-0625-00053', 'KD0-0625-00017', 'KD0-0525-01138',
    'KD0-0625-00044', 'KD0-0625-00038', 'KD0-0625-00045', 'KD0-0625-00034',
    'KD0-0625-00046', 'KD0-0625-00052', 'KD0-0625-00004', 'KD0-0625-00005',
    'KD0-0625-00006', 'KD0-0625-00011', 'KD0-0625-00028', 'KD0-0625-00032',
    'KD0-0625-00029', 'KD0-0625-00063', 'KD0-0625-00037', 'KD0-0625-00047',
    'KD0-0625-00048', 'KD0-0625-00021', 'KD0-0625-00026', 'KD0-0625-00027',
    'KD0-0625-00033', 'KD0-0625-00041', 'KD0-0625-00042', 'KD0-0625-00057',
    'KD0-0625-00058', 'KD0-0625-00059', 'KD0-0625-00001', 'KD0-0625-00010',
    'KD0-0625-00035', 'KD0-0525-01136', 'KD0-0625-00031', 'KD0-0625-00025',
    'KD0-0625-00018'
)
)

,don_hang_tra_oo AS (
SELECT
DISTINCT ordernbr,
remark,
crtd_datetime,
ordertype,
descr,
LEFT(remark,14) as so_don_hang_tra
FROM raw_data
WHERE ordertype = 'OO'
)

,don_hang_tra AS (
SELECT
    a.branchid,
    b.ordernbr,
    a.status,
    b.remark,
    a.custid,
    a.custname,
    a.phone,
    a.addres,
    a.statename,
    a.districtname,
    a.chargereceive,
    a.ordamt*-1 as ordamt,
    b.crtd_datetime,
    a.item_type,
    a.invtid,
    a.invtname,
    a.lineref,
    a.free_item,
    a.sls_price,
    a.line_qty *-1 as line_qty,
    a.line_amt*-1 as line_amt,
    a.manv,
    b.ordertype,
    b.descr,
    a.discidpn,
    a.kho_gonsa_nhan,
    a.discname,
    f.dongiachuavat,
    f.doanhsochuavat * -1 as doanhsochuavat
FROM don_hang_tra_oo b
LEFT JOIN raw_data a ON b.so_don_hang_tra = a.ordernbr
LEFT JOIN `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` f ON a.branchid = f.macongtycn AND b.so_don_hang_tra = f.sodondathang AND a.lineref = f.lineref

--where a.item_type != 'Disccount'
)
,result as (
SELECT
a.*,
f.dongiachuavat,
f.doanhsochuavat
FROM raw_data a
LEFT JOIN `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` f ON a.branchid = f.macongtycn AND a.ordernbr = f.sodondathang AND a.lineref = f.lineref

WHERE ordertype != 'OO'

UNION ALL
SELECT
a.*,
FROM don_hang_tra a
)

SELECT
a.*,
d.tencvbh,
d.supid,
d.tenquanlytt,
e.brand,
e.brandnew2023,
e.tenviettat
FROM result a
LEFT JOIN `spatial-vision-343005.staging.d_users` d ON a.manv = d.manv
LEFT JOIN `staging.d_nhom_sp_trading` e ON e.masanpham = a.invtid




















;