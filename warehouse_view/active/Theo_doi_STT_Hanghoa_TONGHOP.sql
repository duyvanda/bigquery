CREATE VIEW `spatial-vision-343005.warehouse.Theo_doi_STT_Hanghoa_TONGHOP`
AS WITH q AS 
(
  SELECT DISTINCT
    created_code,
    created_name,
    ma_dh_full,
    sl_stt,
    access_key,
    created_at,
    ngay,
    DENSE_RANK() OVER (PARTITION BY created_code ORDER BY created_at DESC) AS ngay_tao_gan_nhat,
    CONCAT(created_code, ' - ' ,created_name) AS Maten_nguoitao,
    IFNULL(so_lo,"0") AS So_lo,
    IFNULL(diem_dau,"0") AS Diem_dau,
    IFNULL(diem_cuoi,"0") AS Diem_cuoi,
    IFNULL(sl_don_hang,"0") AS Soluong_donhang,
    IFNULL(ten_vt,' ') AS TenSP_viet_tat

FROM `spatial-vision-343005.staging.stt_hanghoa`
),

q2 AS 
(
  SELECT * 
  FROM q 
  WHERE ngay_tao_gan_nhat = 1
),

s AS 
(
  SELECT DISTINCT 
    sodondathang,
    makhdms,
    tenkhachhang,
    ngaychungtu
  FROM `spatial-vision-343005.staging.f_sales`    s
)

SELECT 
  q2.*,
  s.makhdms,
  IFNULL(s.tenkhachhang,' ') AS Tenkh,
  s.ngaychungtu,
  IFNULL(k.shoptype,' ') AS Kenh_phu,
  IFNULL(k.statedescr,' ') AS Tinh
FROM q2
LEFT JOIN s ON q2.ma_dh_full = s.sodondathang
LEFT JOIN staging.d_master_khachhang      k      ON s.makhdms = k.custid
;