CREATE VIEW `spatial-vision-343005.warehouse.view_overview_bog_quy2`
AS SELECT 
a.supid,
a.ten_qltt,
a.slsperid,
a.ten_nv,
a.invtid,
a.descr1,
COUNT(DISTINCT a.custid) AS sl_kh_tham_gia,
COUNT(DISTINCT a.custid)-COUNT(DISTINCT CASE WHEN xet_cham_quy IS NOT NULL THEN a.custid ELSE NULL END) AS SLKH_chua_cham_quy,
COUNT(DISTINCT CASE WHEN xet_cham_quy = 'Đạt' THEN a.custid END) AS SLKH_ban_dung_gia,
COUNT(DISTINCT CASE WHEN xet_cham_quy = 'Không đạt' THEN a.custid END) AS SLKH_ban_khong_dung_gia,
COUNT(DISTINCT CASE WHEN xet_cham_quy = 'Đạt' THEN a.custid END) / COUNT(DISTINCT a.custid) AS Ty_le_dung_gia,
1-(COUNT(DISTINCT CASE WHEN xet_cham_quy = 'Đạt' THEN a.custid END)) / COUNT(DISTINCT a.custid) AS Ty_le_khong_dung_gia,
COUNT(DISTINCT CASE WHEN xet_cham_T4  IS NULL THEN a.custid END) AS slkh_chua_cham_t4, 
COUNT(DISTINCT CASE WHEN xet_cham_t5  IS NULL THEN a.custid END) AS slkh_chua_cham_t5,
COUNT(DISTINCT CASE WHEN xet_cham_t6  IS NULL THEN a.custid END) AS slkh_chua_cham_t6,
(COUNT(DISTINCT a.custid) - COUNT(DISTINCT CASE WHEN xet_cham_quy IS NOT NULL THEN a.custid END) ) / COUNT(DISTINCT a.custid) AS Ty_le_chua_cham,
count(distinct CASE WHEN ds_quy >= 1000000 THEN a.custid else null END) AS SLKH_Dat_doanh_so,
SUM(CASE WHEN DS_Quy = 0 THEN 1 ELSE 0 END) AS SLKH_ko_dat_doanh_so,
count(distinct CASE WHEN Xet_dat_quy = 'Đạt' THEN a.custid ELSE null END) AS SLKH_dat_thuong_quy2,
count(distinct CASE WHEN Xet_dat_quy = 'Không đạt' THEN a.custid ELSE null END) AS SLKH_chua_dat_thuong_quy2,
count(distinct CASE WHEN Xet_dat_quy = 'Đạt' THEN a.custid ELSE null END) / COUNT(DISTINCT a.custid)  AS Ty_le_dat,
1 - (COUNT(DISTINCT CASE WHEN Xet_dat_quy = 'Đạt' THEN a.custid ELSE NULL END) / COUNT(DISTINCT a.custid)) AS Ty_le_ko_dat

FROM `spatial-vision-343005.warehouse.Theo_doi_gia_ban_le_TP_Quy2`       a
--where a.slsperid = 'MR1093' 
group by 1,2,3,4,5,6









;