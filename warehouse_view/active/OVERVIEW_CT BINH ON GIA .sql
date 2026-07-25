CREATE VIEW `spatial-vision-343005.warehouse.OVERVIEW_CT BINH ON GIA `
AS WITH q AS 
(
  select *  from
  (
  SELECT 
      slsperid,
      invtid,
      custid,
      visitdate,
      case when result = 'Đạt' then 1 else 0 end as SLKH_Ban_dung_gia,
      ROW_NUMBER() OVER (PARTITION BY slsperid, invtid,custid ORDER BY visitdate desc) AS sap_xep_stt
  FROM `spatial-vision-343005.staging.f_theo_doi_binh_on_gia_tp` t1
  )
  where sap_xep_stt = 1 and visitdate >= '2024-01-01' and visitdate <= '2024-03-31' 
)

SELECT 
    v.supid,
    v.tenquanlytt as ten_qltt,
    s.Ma_NV,
    v.tencvbh as ten_nv,
    s.Ma_SP,
    x.descr1, --ten SP
    CONCAT(s.Ma_SP, ' - ', x.descr1) AS masp_tensp,
    COUNT(DISTINCT s.Ma_KH) AS sl_kh_tham_gia,
    COUNT(DISTINCT CASE WHEN s.Result_Di_Cham IS NOT NULL THEN s.Ma_KH END) AS sl_kh_da_di_cham,
  
    COUNT(DISTINCT s.Ma_KH)-COUNT(DISTINCT CASE WHEN s.Result_Di_Cham IS NOT NULL THEN s.Ma_KH END) AS SLKH_chua_di_cham,

    sum(SLKH_Ban_dung_gia) AS SLKH_Ban_dung_gia,
    COUNT(DISTINCT CASE WHEN s.Result_Di_Cham IS NOT NULL THEN s.Ma_KH END) - sum(SLKH_Ban_dung_gia) as SLKH_Ban_khong_dung_gia,


    sum(SLKH_Ban_dung_gia) / COUNT(DISTINCT s.Ma_KH) AS Ty_le_dung_gia,
    (COUNT(DISTINCT CASE WHEN s.Result_Di_Cham IS NOT NULL THEN s.Ma_KH END) - SUM(SLKH_Ban_dung_gia)) / COUNT(DISTINCT s.Ma_KH) 
    AS Ty_le_khong_dung_gia,
    ( COUNT(DISTINCT s.Ma_KH) - COUNT(DISTINCT CASE WHEN s.Result_Di_Cham IS NOT NULL THEN s.Ma_KH END) ) / COUNT(DISTINCT s.Ma_KH) 
    AS Ty_le_chua_cham,
    SUM(CASE WHEN s.DS_Quy_1 > 0 THEN 1 ELSE 0 END) AS SLKH_Dat_doanh_so,
    SUM(CASE WHEN s.DS_Quy_1 = 0 THEN 1 ELSE 0 END) AS SLKH_ko_dat_doanh_so,
    SUM(CASE WHEN s.Xet_dat_Q1 = 'Đạt' THEN 1 ELSE 0 END) AS SLKH_Dat,
    SUM(CASE WHEN s.Xet_dat_Q1 = 'Chưa đạt' THEN 1 ELSE 0 END) AS SLKH_Ko_Dat,
    ROUND((SUM(CASE WHEN s.Xet_dat_Q1 = 'Đạt' THEN 1 ELSE 0 END) / IFNULL(COUNT(DISTINCT s.Ma_KH), 0)) * 100, 2) AS Ty_le_dat,
    ROUND((SUM(CASE WHEN s.Xet_dat_Q1 = 'Chưa đạt' THEN 1 ELSE 0 END) / IFNULL(COUNT(DISTINCT s.Ma_KH), 0)) * 100, 2) AS Ty_le_ko_dat
FROM 
(
    SELECT 
        a.slsperid AS Ma_NV,
        a.invtid AS Ma_SP,
        a.custid AS Ma_KH,
        IFNULL(q.SLKH_Ban_dung_gia,0) as SLKH_Ban_dung_gia,
        Xet_dat_quy AS Result_Di_Cham,
        IFNULL(Xet_dat_quy, 'Chưa đạt') AS Result,
        IFNULL(b.DS_Quy, 0) AS DS_Quy_1,
        IFNULL(Xet_dat_quy, 'Chưa đạt') AS Xet_dat_Q1
    FROM `spatial-vision-343005.staging.d_posm_regis` a
    LEFT JOIN `spatial-vision-343005.warehouse.Theo_doi_gia_ban_le_TP` b
    ON a.custid = b.custid  
        AND a.invtid = b.invtid
        AND a.slsperid = b.slsperid
    LEFT JOIN q ON a.slsperid = q.slsperid AND a.invtid = q.invtid AND a.custid = q.custid
    -- where a.custid = 'HH10O099'
) s
LEFT JOIN `spatial-vision-343005.staging.d_users` v ON s.Ma_NV = v.manv
LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid` x ON s.Ma_SP = x.invtid
--where Ma_NV = 'MR2910'
GROUP BY 1, 2, 3, 4, 5,6;