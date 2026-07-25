CREATE FUNCTION `spatial-vision-343005`.staging_temp.fn_phan_loai_no(terms_name STRING, is_diadiem STRING, duedate DATE, day_terms INT64, no_tong_don_hang FLOAT64, orderdate DATE, dateoforder DATE, so_du_chungtu FLOAT64) RETURNS STRUCT<thoi_diem_no_vang DATE, thoi_diem_no_do DATE, thoi_diem_no_den DATE, phan_loai_no STRING, thang_chung_tu DATE, thang_thu DATE, no_xanh FLOAT64, no_vang FLOAT64, no_do FLOAT64, no_den FLOAT64, no_xau FLOAT64, vung_no_kh INT64, thoigian_no INT64, thoigian_noqh INT64, thoigian_noxau INT64>
AS (
(
    SELECT AS STRUCT
      thoi_diem_no_vang,
      thoi_diem_no_do,
      thoi_diem_no_den,
      phan_loai_no,
      DATE_TRUNC(dateoforder, MONTH) AS thang_chung_tu,
      DATE_TRUNC(orderdate, MONTH) AS thang_thu,
      CASE WHEN phan_loai_no = 'Nợ xanh' THEN so_du_chungtu ELSE 0 END AS no_xanh,
      CASE WHEN phan_loai_no = 'Nợ vàng' THEN so_du_chungtu ELSE 0 END AS no_vang,
      CASE WHEN phan_loai_no = 'Nợ đỏ' THEN so_du_chungtu ELSE 0 END AS no_do,
      CASE WHEN phan_loai_no = 'Nợ đen' THEN so_du_chungtu ELSE 0 END AS no_den,
      CASE WHEN phan_loai_no IN ('Nợ đỏ', 'Nợ đen') THEN so_du_chungtu ELSE 0 END AS no_xau,
      CASE
        WHEN phan_loai_no = 'Nợ xanh' THEN 1
        WHEN phan_loai_no = 'Nợ vàng' THEN 2
        WHEN phan_loai_no = 'Nợ đỏ' THEN 3
        WHEN phan_loai_no = 'Nợ đen' THEN 4
        ELSE 1
      END AS vung_no_kh,
      CASE
        WHEN ABS(no_tong_don_hang) > 1000 THEN DATE_DIFF(CURRENT_DATE("+7"), DATE(dateoforder), DAY)
        WHEN ABS(no_tong_don_hang) <= 1000 THEN DATE_DIFF(orderdate, DATE(dateoforder), DAY)
        ELSE 0
      END AS thoigian_no,
      CASE
        WHEN ABS(no_tong_don_hang) > 1000 AND phan_loai_no IN ('Nợ vàng', 'Nợ đỏ', 'Nợ đen') THEN DATE_DIFF(CURRENT_DATE("+7"), DATE(thoi_diem_no_vang), DAY)
        WHEN ABS(no_tong_don_hang) <= 1000 AND phan_loai_no IN ('Nợ vàng', 'Nợ đỏ', 'Nợ đen') THEN DATE_DIFF(orderdate, DATE(thoi_diem_no_vang), DAY)
        ELSE 0
      END AS thoigian_noqh,
      CASE
        WHEN ABS(no_tong_don_hang) > 1000 AND phan_loai_no IN ('Nợ đỏ', 'Nợ đen') THEN DATE_DIFF(CURRENT_DATE("+7"), DATE(thoi_diem_no_do), DAY)
        WHEN ABS(no_tong_don_hang) <= 1000 AND phan_loai_no IN ('Nợ đỏ', 'Nợ đen') THEN DATE_DIFF(orderdate, DATE(thoi_diem_no_do), DAY)
        ELSE 0
      END AS thoigian_noxau
    FROM (
      SELECT
        thoi_diem_no_vang,
        thoi_diem_no_do,
        thoi_diem_no_den,
        CASE
          WHEN CURRENT_DATE("+7") >= thoi_diem_no_den AND ABS(no_tong_don_hang) > 1000 THEN 'Nợ đen'
          WHEN CURRENT_DATE("+7") < thoi_diem_no_den AND ABS(no_tong_don_hang) > 1000 AND CURRENT_DATE("+7") >= thoi_diem_no_do THEN 'Nợ đỏ'
          WHEN CURRENT_DATE("+7") < thoi_diem_no_do AND ABS(no_tong_don_hang) > 1000 AND CURRENT_DATE("+7") >= thoi_diem_no_vang THEN 'Nợ vàng'
          WHEN CURRENT_DATE("+7") < thoi_diem_no_vang AND ABS(no_tong_don_hang) > 1000 THEN 'Nợ xanh'
          WHEN DATE(orderdate) >= thoi_diem_no_den AND ABS(no_tong_don_hang) <= 1000 THEN 'Nợ đen'
          WHEN DATE(orderdate) < thoi_diem_no_den AND ABS(no_tong_don_hang) <= 1000 AND DATE(orderdate) >= thoi_diem_no_do THEN 'Nợ đỏ'
          WHEN DATE(orderdate) < thoi_diem_no_do AND ABS(no_tong_don_hang) <= 1000 AND DATE(orderdate) >= thoi_diem_no_vang THEN 'Nợ vàng'
          WHEN DATE(orderdate) < thoi_diem_no_vang AND ABS(no_tong_don_hang) <= 1000 THEN 'Nợ xanh'
          WHEN DATE(orderdate) IS NULL AND ABS(no_tong_don_hang) <= 1000 THEN 'Nợ xanh'
          WHEN DATE(orderdate) IS NULL AND thoi_diem_no_den <= CURRENT_DATE("+7") THEN 'Nợ đen'
          WHEN DATE(orderdate) IS NULL AND thoi_diem_no_do <= CURRENT_DATE("+7") THEN 'Nợ đỏ'
          WHEN DATE(orderdate) IS NULL AND thoi_diem_no_vang <= CURRENT_DATE("+7") THEN 'Nợ vàng'
          WHEN DATE(orderdate) IS NULL AND thoi_diem_no_vang > CURRENT_DATE("+7") THEN 'Nợ xanh'
          ELSE NULL
        END AS phan_loai_no
      FROM (
        SELECT
          CASE
            WHEN terms_name LIKE '%Thu tiền ngay%' AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 1 DAY)
            WHEN terms_name LIKE '%Thu tiền ngay%' AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 3 DAY)
            WHEN terms_name IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 2 DAY)
            WHEN terms_name IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 4 DAY)
            WHEN day_terms <= 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 2 DAY)
            WHEN day_terms <= 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 4 DAY)
            WHEN day_terms > 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 2 DAY)
            WHEN day_terms > 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 4 DAY)
            ELSE NULL
          END AS thoi_diem_no_vang,
          CASE
            WHEN terms_name LIKE '%Thu tiền ngay%' AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 6 DAY)
            WHEN terms_name LIKE '%Thu tiền ngay%' AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 8 DAY)
            WHEN terms_name IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 7 DAY)
            WHEN terms_name IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 9 DAY)
            WHEN day_terms <= 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 17 DAY)
            WHEN day_terms <= 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 19 DAY)
            WHEN day_terms > 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 32 DAY)
            WHEN day_terms > 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 34 DAY)
            ELSE NULL
          END AS thoi_diem_no_do,
          CASE
            WHEN terms_name LIKE '%Thu tiền ngay%' AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 10 DAY)
            WHEN terms_name LIKE '%Thu tiền ngay%' AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 12 DAY)
            WHEN terms_name IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 11 DAY)
            WHEN terms_name IN ('Gối 1 Đơn Hàng (trong 30 ngày)') AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 13 DAY)
            WHEN day_terms <= 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 32 DAY)
            WHEN day_terms <= 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 34 DAY)
            WHEN day_terms > 15 AND is_diadiem = 'VP chi nhánh' THEN DATE_ADD(DATE(duedate), INTERVAL 62 DAY)
            WHEN day_terms > 15 AND is_diadiem = 'Tỉnh' THEN DATE_ADD(DATE(duedate), INTERVAL 64 DAY)
            ELSE NULL
          END AS thoi_diem_no_den
      )
    )
  )
);