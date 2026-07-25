CREATE VIEW `spatial-vision-343005.warehouse.view_ct_thuong_do_phu_meseca_tp_032026`
AS /* Bước 1: Tìm danh sách khách hàng đã mua Meseca Advanced trong giai đoạn loại trừ (01/09/2025 - 24/02/2026) */
WITH cte_kh_loai_tru AS (
    SELECT DISTINCT 
        makhdms
    FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy`
    WHERE date(ngaychungtu) >= '2025-09-01' 
      AND date(ngaychungtu) <= '2026-02-24'
      AND masanpham in ('T303102010', 'T303102011')
      AND is_hang_km = 'Hàng bán'
)

/* Bước 2: Lấy dữ liệu bán hàng Meseca Advanced trong thời gian diễn ra chương trình (01/03/2026 - 31/03/2026) trên Kênh TP */
, cte_sales_t3 AS (
    SELECT 
        makhdms, 
        tenkhachhang,
        hcoid,
        manv,
        tencvbh,
        ma_crm,
        tenquanlytt,
        scrm,
        tenquanlykhuvuc,
        sodondathang,
        ngaychungtu,
        macongtycn,
        masanpham,
        tensanphamnb,
        soluong,
        doanhsochuavat,
        SUM(soluong) OVER(PARTITION BY sodondathang) AS tong_sl_don_hang
    FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy`
   WHERE date(ngaychungtu) >= '2026-03-01' 
      AND date(ngaychungtu) <= '2026-03-31'
      AND masanpham in ('T303102010', 'T303102011')
      AND is_hang_km = 'Hàng bán'
      AND makenhkh = 'TP' 
      AND hcoid NOT IN ('DLPP', 'PKNK')
    GROUP BY ALL
)

/* Bước 3: Lọc ra các khách hàng hợp lệ (Khách hàng mới hoàn toàn hoặc chưa mua trong giai đoạn loại trừ) và đạt điều kiện tối thiểu 3 hộp */
SELECT 
t3.*,
CASE 
  WHEN lt.makhdms IS NULL AND t3.tong_sl_don_hang >= 3 THEN t3.makhdms 
  ELSE NULL 
  END AS makh_dat

FROM cte_sales_t3 AS t3
LEFT JOIN cte_kh_loai_tru AS lt 
    ON t3.makhdms = lt.makhdms





;