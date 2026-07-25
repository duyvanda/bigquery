CREATE VIEW `spatial-vision-343005.warehouse.view_du_tru_gonsa`
AS WITH sell_in as (
SELECT
s.masanpham,
b.kho_gonsa_nhan,
SUM(s.soluongori) as sell_in_ori
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` s 
LEFT JOIN `spatial-vision-343005.staging.d_ds_kho_gonsa` b on s.statedescr = b.tinh
WHERE s.makhdms in ('019739', '019738') and date(s.ngaychungtu) >= '2026-03-16'
GROUP BY ALL
)
,don_hang_gonsa as (
SELECT
a.invtid,
b.kho_gonsa_nhan,
SUM (a.line_qty) as sl_sell_out_tong,
SUM (CASE WHEN a.status = 'C' THEN a.line_qty ELSE 0 END) as sl_sell_out_xuat,
FROM `spatial-vision-343005.staging.d_data_kim_do_final` a
LEFT JOIN `spatial-vision-343005.staging.d_ds_kho_gonsa` b on a.statename = b.tinh
WHERE date(a.crtd_datetime) >= '2026-03-16' and ordernbr not in (
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
/*anh, hình như anh chưa chỉnh khúc đơn treo anh nhỉ, nó đang cộng luôn đơn hủy*/
AND status not in ('V', 'E')
AND parnerid = 'BM'
GROUP BY ALL
)
SELECT
a.ma_kh,
a.kho_gs,
a.ma_sp,
a.ten_sp as ten_sp,
bg.don_gia_sau_vat as don_gia_sau_vat,
bg.ten_nhom_csbh as ten_nhom_csbh,
bg.dtv as dvt,
a.brand_mrln,
a.dinh_muc,
IFNULL(s.sell_in_ori,0) as sell_in_ori,
IFNULL(dvt, 0) as sl_dieu_chuyen,
IFNULL(s.sell_in_ori,0) + IFNULL(dvt, 0) as sell_in,
IFNULL(gs.sl_sell_out_tong,0) as sl_sell_out_tong,
IFNULL(gs.sl_sell_out_xuat,0) as sl_sell_out_xuat
FROM `spatial-vision-343005.staging.d_dinh_muc_ton_kho_gonsa` a
LEFT JOIN sell_in s ON s.masanpham = a.ma_sp AND lower(a.kho_gs) = lower(s.kho_gonsa_nhan)
LEFT JOIN don_hang_gonsa gs ON a.ma_sp = gs.invtid AND a.kho_gs = gs.kho_gonsa_nhan
LEFT JOIN `staging.d_gonsa_bang_gia` bg on bg.ma_sp = a.ma_sp


;