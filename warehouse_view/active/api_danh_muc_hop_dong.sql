CREATE VIEW `spatial-vision-343005.warehouse.api_danh_muc_hop_dong`
AS SELECT 
  districtdescr AS tinh,
  custid AS ma_kh,
  custname AS ten_kh,
  channel AS kenh,
  pubcustname AS ten_kh_chung,
  pubcustid AS ma_kh_chung,
  genslsperid AS ma_cvbh,
  firstname AS ten_cvbh,
  supid AS supid,
  tenquanlytt AS ten_ql_tt,
  contractnbr AS so_hop_dong,
  signeddate AS ngay_hl_theo_hd,
  gentodate AS ngay_het_hl_theo_hd_final,
  invtid AS ma_sp,
  tensp AS ten_sp,
  price_le AS gia_trung_thau,
  orderunit AS dvt,
  thanhtien_hopdong AS thanh_tien_hop_dong
FROM `spatial-vision-343005.warehouse.f_danhmuchopdong`
WHERE 
  CAST(active AS INT64) = 1 
  AND channel IN ('INS', 'CLC')
  AND invtid IS NOT NULL;;