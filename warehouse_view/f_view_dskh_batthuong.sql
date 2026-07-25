CREATE VIEW `spatial-vision-343005.warehouse.f_view_dskh_batthuong`
AS WITH base_date AS (
  SELECT DISTINCT
    DATE_TRUNC(ngay, MONTH) AS thang
  FROM UNNEST(
    GENERATE_DATE_ARRAY(
      DATE(DATE_TRUNC(CURRENT_DATE("+7"), MONTH) - INTERVAL 6 MONTH),
      CURRENT_DATE("+7"),
      INTERVAL 1 DAY
    )
  ) AS ngay
),

sales AS (
  SELECT
    makhdms,
    thang,
    SUM(doanhsochuavat) AS doanhso
  FROM `warehouse.f_sales_crs`
  WHERE DATE(ngaychungtu) BETWEEN DATE_TRUNC(CURRENT_DATE("+7"), MONTH) - INTERVAL 6 MONTH
                                 AND CURRENT_DATE("+7")
    AND makenh_moi = 'TP'
    AND makhdms IS NOT NULL
  GROUP BY ALL
  ORDER BY 1, 2
),

mapping_sales_his AS (
  SELECT
    a.thang,
    b.makhdms,
    IFNULL(c.doanhso, 0) AS ds
  FROM base_date a
  LEFT JOIN (
    SELECT DISTINCT makhdms FROM sales
  ) b ON 1 = 1
  LEFT JOIN sales c ON a.thang = DATE(c.thang) AND b.makhdms = c.makhdms
  WHERE a.thang != DATE_TRUNC(CURRENT_DATE("+7"), MONTH)
  ORDER BY 2, 1
)

,

tb_avg_ds_6m AS (
  SELECT
    a.*,
    ROUND(AVG(ds) OVER (PARTITION BY makhdms), 1) AS avg_ds_6m
  FROM mapping_sales_his a
)

,

cal_delta AS (
  SELECT
    a.*,
    ABS(IFNULL(a.ds - LAG(ds) OVER (PARTITION BY makhdms ORDER BY thang), 0)) AS delta
  FROM tb_avg_ds_6m a
)


,

cal_r_del AS (
  SELECT
    *,
    ROUND(SAFE_DIVIDE(delta, avg_ds_6m), 2) AS rate_del
  FROM cal_delta
)


,

sales_cur AS (
  SELECT
    a.thang,
    b.makhdms,
    IFNULL(c.doanhso, 0) AS ds,
    0.0 as avg_ds_6m,
    0.0 as delta,
    0.0 as rate_del,
  FROM base_date a
  LEFT JOIN (
    SELECT DISTINCT makhdms FROM sales
  ) b ON 1 = 1
  LEFT JOIN sales c ON a.thang = DATE(c.thang) AND b.makhdms = c.makhdms
  WHERE a.thang = DATE_TRUNC(CURRENT_DATE("+7"), MONTH)
  ORDER BY 2, 1
)

-- select * from sales_cur where makhdms = 'HH02O044'

, combined as

(
  select * from cal_r_del
  UNION ALL
  select * from sales_cur
)



SELECT
  a.thang,
  a.makhdms,
  a.ds,
  a.avg_ds_6m,
  a.delta,
  a.rate_del,
  nv.col.ma_nvbh,
  q.tencvbh,
  q.supid,
  q.tenquanlytt,
  ROW_NUMBER() OVER (PARTITION BY a.makhdms ORDER BY a.thang) AS stt,
  MAX(delta) OVER (PARTITION BY a.makhdms) AS max_delta,
  MAX(rate_del) OVER (PARTITION BY a.makhdms) AS max_del,
  (
    SELECT MAX(updated_at)
    FROM `warehouse.f_sales_crs`
    WHERE ngaychungtu >= '2025-01-01'
  ) AS inserted_at,
  c.custname,
  c.channel,
  c.shoptype,
  c.statedescr,
  c.districtdescr,
  c.shortterritorydescr
FROM combined a
  LEFT JOIN `staging.d_master_khachhang` c on a.makhdms = c.custid
  LEFT JOIN `warehouse.f_mapping_crs` nv on a.makhdms = nv.custid
  left join `staging.d_users` q on nv.col.ma_nvbh = q.manv
  -- where  a.makhdms = 'HH02O044'

ORDER BY 2, 1;