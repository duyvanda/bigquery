CREATE VIEW `spatial-vision-343005.warehouse.view_tong_hop_thu_hoi_bang_ke_loyalty_2026`
AS WITH  chiet_khau_da_thanh_toan_fix AS (
SELECT
*EXCEPT(paidamt),
CASE WHEN ordernbr like 'IR%' THEN paidamt * -1
      ELSE paidamt
  END AS paidamt
FROM
  `staging.f_paidso_acculate`
WHERE
  accumulateid in ('202601-TL-QD785-PMC-CTD-BK-Q1-2026', '202601-TL-QD785-PMC-CTD')
)

, chiet_khau_da_thanh_toan as (
SELECT
  custid,
  SUM(Case when EXTRACT(QUARTER FROM CAST(todate AS DATE)) = 1 Then paidamt else 0 end ) as da_tra_q1,
  SUM(Case when EXTRACT(QUARTER FROM CAST(todate AS DATE)) = 2 Then paidamt else 0 end ) as da_tra_q2,
  SUM(Case when EXTRACT(QUARTER FROM CAST(todate AS DATE)) = 3 Then paidamt else 0 end ) as da_tra_q3,
  SUM(Case when EXTRACT(QUARTER FROM CAST(todate AS DATE)) = 4 Then paidamt else 0 end ) as da_tra_q4
FROM
  chiet_khau_da_thanh_toan_fix
GROUP BY ALL
)

, thong_tin_ky_bang_ke as (
SELECT
distinct ma_khach_hang,
date(thoi_gian_ky) as thoi_gian_ky_bk_pingme
FROm `spatial-vision-343005.warehouse.view_data_contract_sign_by_users`
where
internal_promo_code in ('202601-TL-QD785-PMC-CTD-BK-Q1-2026','202601-TL-QD785-PMC-CTD-BK-Q1-2026')
and trang_thai_ky = 'Đã ký'
)

SELECT  
a.*,
IFNULL(b.da_tra_q1,0) as da_tra_q1,
so_tien_chiet_khau_vat - IFNULL(b.da_tra_q1,0) as so_tien_con_lai,
thoi_gian_ky_bk_pingme
FROM `spatial-vision-343005.staging.theo_doi_thu_hoi_chung_tu_ky_ben_ngoai_bang_ke_loyaty_tp_pcl_q12026` a
LEFT JOIN chiet_khau_da_thanh_toan b on a.ma_kh = b.custid
LEFT JOIn thong_tin_ky_bang_ke c on a.ma_kh = c.ma_khach_hang




;