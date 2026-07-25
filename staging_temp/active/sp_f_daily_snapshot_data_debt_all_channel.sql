CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_daily_snapshot_data_debt_all_channel()
BEGIN
CREATE TEMP TABLE `f_daily_snapshot_data_debt_all_channel_temp` AS
  WITH data_debt AS
     (SELECT CASE
                 WHEN a.channel = 'OTC'
                      AND a.hcotypeid ='PKC' THEN 'PKC'
                 WHEN a.channel = 'OTC'
                      AND a.hcotypeid ='PKK' THEN 'PKK'
                 WHEN a.channel= 'OTC' THEN 'OTC'
                 ELSE a.channel
             END AS channel,
             a.no_xanh,
             a.no_vang,
             a.no_do,
             a.no_den,
             a.thoigian_no,
             CASE
                 WHEN a.so_du_dh > 1000
                      OR a.so_du_dh < -1000 THEN date_diff(
                               (SELECT *
                                                              FROM `staging.d_current_table`), date(a.dateoforder), MONTH)
                 WHEN (a.so_du_dh <= 1000
                       AND a.so_du_dh >= -1000) THEN date_diff(a.orderdate, date(a.dateoforder), MONTH)
                 ELSE 0
             END AS thoigian_no_thang,
             a.no_qua_han AS no_qh
      FROM `staging_temp.d_rawdata_debt` a
      WHERE a.channel NOT IN ('NB',
                              'OTH_LAB')
        AND a.custid NOT IN ('DSOTC-HN-001',
                             'DSOTC-HN--002')
        AND date(a.dateoforder) <= date_sub(
                               (SELECT *
                                               FROM `staging.d_current_table`),interval 1 DAY)),
        result_congno AS
     (SELECT channel,
             sum(no_xanh) AS no_xanh,
             sum(no_vang) AS no_vang,
             sum(no_do) AS no_do,
             sum(no_den) AS no_den,
             sum(no_qh) AS no_qh,
             sum(no_xanh) AS no_tronghan,
             sum(no_qh) + sum(no_xanh) AS du_no_hientai,
             round(avg(thoigian_no), 1) AS songayno_bq,
             round(avg(thoigian_no_thang), 1) AS songayno_bq_thang,
             round(safe_divide((sum(no_do) + sum(no_den)) , (sum(no_qh) + sum(no_xanh)))*100, 1) AS tile_noxau
      FROM data_debt
      GROUP BY 1),
        doanhso_hientai AS
     (SELECT --ifnull(b1.channel,b.channel) as channel,
 CASE
     WHEN b.channel = 'OTC'
          AND b.hcotypeid ='PKC' THEN 'PKC'
     WHEN b.channel = 'OTC'
          AND b.hcotypeid ='PKK' THEN 'PKK'
     WHEN b.channel = 'OTC'
          AND b.shoptype IS NOT NULL THEN b.shoptype --when b.channel = 'CLC' and b.hcotypeid is  null then 'CLC'

     WHEN b.channel= 'OTC' THEN 'OTC'
     ELSE ifnull(b.channel, b1.channel)
 END AS channel,
 count(DISTINCT thang) AS sothang_bh,
 sum(doanhsochuavat) AS doanhso
      FROM `staging.f_sales` a
      LEFT JOIN `staging.d_master_khachhang2022` b ON b.custid =a.makhdms
      AND a.thang <'2023-01-01'
      LEFT JOIN `staging.d_master_khachhang` b1 ON b1.custid =a.makhdms
      AND a.thang >='2023-01-01'
      WHERE date(thang) = date_trunc(date_sub(
                               (SELECT *
                                                 FROM `staging.d_current_table`),interval 1 DAY), MONTH)
        AND a.ngaychungtu >= '2022-01-01'
        AND left(a.masanpham, 1) != 'V'
        AND a.manv NOT IN ('GH001',
                           'MA001',
                           'MA002',
                           'QUYNHPTA')
      GROUP BY 1),
        doanhso_bq AS
     (SELECT --ifnull(b1.channel,b.channel) as channel,
 CASE
     WHEN b.channel = 'OTC'
          AND b.hcotypeid ='PKC' THEN 'PKC'
     WHEN b.channel = 'OTC'
          AND b.hcotypeid ='PKK' THEN 'PKK'
     WHEN b.channel = 'OTC'
          AND b.shoptype IS NOT NULL THEN b.shoptype --when b.channel = 'CLC' and b.hcotypeid is  null then 'CLC'

     WHEN b.channel= 'OTC' THEN 'OTC'
     ELSE ifnull(b.channel, b1.channel)
 END AS channel,
 round(safe_divide(sum(doanhsochuavat), count(DISTINCT thang)), 0) AS doanhso_bq
      FROM `staging.f_sales` a
      LEFT JOIN `staging.d_master_khachhang2022` b ON b.custid =a.makhdms
      AND a.thang <'2023-01-01'
      LEFT JOIN `staging.d_master_khachhang` b1 ON b1.custid =a.makhdms
      AND a.thang >='2023-01-01'
      WHERE --date(thang)  = date_trunc( (select * from `staging.d_current_table`),month) and
 a.ngaychungtu >= '2022-01-01'
        AND date(thang) = date_trunc(date_sub(
                               (SELECT *
                                                 FROM `staging.d_current_table`),interval 1 DAY), MONTH)
        AND left(a.masanpham, 1) != 'V'
        AND a.manv NOT IN ('GH001',
                           'MA001',
                           'MA002',
                           'QUYNHPTA')
      GROUP BY 1),
        doanhthu_hientai AS
     (SELECT --ifnull(b1.channel,b.channel) as channel,
CASE
    WHEN b.channel = 'OTC'
         AND b.hcotypeid ='PKC' THEN 'PKC'
    WHEN b.channel = 'OTC'
         AND b.hcotypeid ='PKK' THEN 'PKK'
    WHEN b.channel = 'OTC'
         AND b.shoptype IS NOT NULL THEN b.shoptype --when b.channel = 'CLC' and b.hcotypeid is  null then 'CLC'

    WHEN b.channel= 'OTC' THEN 'OTC'
    ELSE ifnull(b.channel, b1.channel)
       END AS channel,
       count(DISTINCT date_trunc(orderdate, MONTH)) AS sothang_bh,
       sum(sotien_da_thanhtoan) AS sotien_da_thanhtoan
      FROM `staging_temp.d_rawdata_debt_detail` a
      LEFT JOIN `staging.d_master_khachhang2022` b ON b.custid =a.custid
      AND a.dateoforder <'2023-01-01'
      LEFT JOIN `staging.d_master_khachhang` b1 ON b1.custid =a.custid
      AND a.dateoforder >='2023-01-01'
      WHERE --a.orderdate >='2022-01-01' and
date_trunc(orderdate, MONTH) = date_trunc(date_sub(
                               (SELECT *
                                                      FROM `staging.d_current_table`),interval 1 DAY), MONTH)
      GROUP BY 1),
        doanhthu_bq AS
     (SELECT CASE
                 WHEN b.channel = 'OTC'
                      AND b.hcotypeid ='PKC' THEN 'PKC'
                 WHEN b.channel = 'OTC'
                      AND b.hcotypeid ='PKK' THEN 'PKK'
                 WHEN b.channel = 'OTC'
                      AND b.shoptype IS NOT NULL THEN b.shoptype --when b.channel = 'CLC' and b.hcotypeid is  null then 'CLC'

                 WHEN b.channel= 'OTC' THEN 'OTC'
                 ELSE ifnull(b.channel, b1.channel)
             END AS channel, --ifnull(b1.channel,b.channel) as channel,
count(DISTINCT date_trunc(orderdate, MONTH)) AS sothang_bh,
       round(safe_divide (sum(sotien_da_thanhtoan), count(DISTINCT date_trunc(orderdate, MONTH))), 0) AS sotien_da_thanhtoan_bq
      FROM `staging_temp.d_rawdata_debt_detail` a
      LEFT JOIN `staging.d_master_khachhang2022` b ON b.custid =a.custid
      AND a.dateoforder <'2023-01-01'
      LEFT JOIN `staging.d_master_khachhang` b1 ON b1.custid =a.custid
      AND a.dateoforder >='2023-01-01'
      WHERE a.orderdate >='2022-01-01'
        AND date_trunc(orderdate, MONTH) = date_trunc(date_sub(
                               (SELECT *
                                                                  FROM `staging.d_current_table`),interval 1 DAY), MONTH)
      GROUP BY 1) SELECT a.*,
       ifnull(b.sotien_da_thanhtoan, 0) AS doanhthu_ht,
       ifnull(b1.sotien_da_thanhtoan_bq, 0) AS doanhthu_bq,
       ifnull(c.doanhso, 0) AS doanhso_ht,
       ifnull(c1.doanhso_bq, 0) AS doanhso_bq,
       round(safe_divide(a.du_no_hientai, ifnull(c1.doanhso_bq, 0)), 1) AS he_so_duno,

     (SELECT max(inserted_at)
      FROM `staging_temp.d_rawdata_debt`
      WHERE inserted_at IS NOT NULL) AS inserted_at
   FROM result_congno a
   LEFT JOIN doanhthu_hientai b ON a.channel =b.channel
   LEFT JOIN doanhthu_bq b1 ON a.channel =b1.channel
   LEFT JOIN doanhso_hientai c ON a.channel =c.channel
   LEFT JOIN doanhso_bq c1 ON a.channel =c1.channel
   WHERE du_no_hientai <> 0;
CREATE OR REPLACE TABLE `warehouse.f_daily_snapshot_data_debt_all_channel` COPY `f_daily_snapshot_data_debt_all_channel_temp`; END;