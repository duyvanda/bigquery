-- ==========================================================================
-- Routine Name : sp_f_raw_data_sales_yoy_canhbao
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-07-06 08:48:17.731000+00:00
-- Last Altered : 2026-07-06 08:48:17.731000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_raw_data_sales_yoy_canhbao()
BEGIN
DECLARE partition_date DATE DEFAULT DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH);
Create or replace table staging_temp.f_raw_data_sales_yoy_canhbao_temp
partition by date(ngaychungtu)
cluster by makhdms,makenhkh,makenhphu,hcoid
as
(
WITH tuyen_cvbh_hd_ins AS (
  SELECT
    custid,
    slsperid,
    invtid,
    thang
  FROM `spatial-vision-343005.staging.d_get_contract_det_bytime` a
  LEFT JOIN `staging.d_users` b ON a.slsperid = b.manv
  WHERE
    slsperid NOT IN ('GH001', 'QUYNHPTA', 'MA001', 'MA002')
    AND b.tenquanlyvung in ('Nguyễn Thọ Chiến','Vũ Mừng')
    AND LEFT(invtid, 1) <> 'V'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY custid, invtid, thang ORDER BY CAST(crtd_date AS DATE) DESC) = 1
),
tuyen_cvbh_hd_clc AS (
  SELECT
    custid,
    slsperid,
    thang
  FROM `spatial-vision-343005.staging.d_get_contract_det_bytime` a
  LEFT JOIN `staging.d_users` b ON a.slsperid = b.manv
  WHERE
    slsperid NOT IN ('GH001', 'QUYNHPTA', 'MA001', 'MA002')
    AND b.tenquanlyvung in ('Nguyễn Thọ Chiến','Vũ Mừng')
    AND LEFT(invtid, 1) <> 'V'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY custid ORDER BY thang DESC, CAST(crtd_date AS DATE) DESC) = 1
)

SELECT
  a.* EXCEPT (inserted_at),
  CASE
    WHEN a.tenquanlyvung IS NULL OR a.tenquanlyvung = 'Chưa xác định' THEN 'Thiếu thông tin NCXM'
    ELSE NULL
  END AS is_rule1,
  CASE
    WHEN a.tenquanlykhuvuc IS NULL OR a.tenquanlykhuvuc = 'Chưa xác định' THEN 'Thiếu thông tin SCRM'
    WHEN (
      (CONCAT(a.tenquanlykhuvuc, DATE(a.thang)) NOT IN (
        SELECT DISTINCT CONCAT(tenquanlykhuvuc, DATE(thang))
        FROM `staging.d_users_bytime`
        WHERE LEFT(rsmid, 6) = 'MR0485'
      ) AND makenhkh_cu = 'TP')
      OR
      (CONCAT(a.tenquanlykhuvuc, DATE(a.thang)) NOT IN (
        SELECT DISTINCT CONCAT(tenquanlykhuvuc, DATE(thang))
        FROM `staging.d_users_bytime`
        WHERE LEFT(rsmid, 6) in ('MR0081','MR1137')
      ) AND makenhkh_cu IN ('INS', 'CLC', 'PCL'))
      OR
      (CONCAT(a.tenquanlykhuvuc, DATE(a.thang)) NOT IN (
        SELECT DISTINCT CONCAT(tenquanlykhuvuc, DATE(thang))
        FROM `staging.d_users_bytime`
        WHERE LEFT(rsmid, 6) = 'MR2685'
      ) AND makenhkh_cu = 'MT')
    ) THEN 'Sai thông tin SCRM'
    ELSE NULL
  END AS is_rule2,
  CASE
    WHEN a.tenquanlytt IS NULL OR a.tenquanlytt = 'Chưa xác định' THEN 'Thiếu thông tin A.CRM'
    WHEN (
      (CONCAT(a.tenquanlytt, DATE(a.thang)) NOT IN (
        SELECT DISTINCT CONCAT(tenquanlytt, DATE(thang))
        FROM `staging.d_users_bytime`
        WHERE LEFT(rsmid, 6) = 'MR0485'
      ) AND makenhkh_cu = 'TP')
      OR
      (CONCAT(a.tenquanlytt, DATE(a.thang)) NOT IN (
        SELECT DISTINCT CONCAT(tenquanlytt, DATE(thang))
        FROM `staging.d_users_bytime`
        WHERE LEFT(rsmid, 6) in ('MR0081','MR1137')
      ) AND makenhkh_cu IN ('INS', 'CLC', 'PCL'))
      OR
      (CONCAT(a.tenquanlytt, DATE(a.thang)) NOT IN (
        SELECT DISTINCT CONCAT(tenquanlytt, DATE(thang))
        FROM `staging.d_users_bytime`
        WHERE LEFT(rsmid, 6) = 'MR2685'
      ) AND makenhkh_cu = 'MT')
    ) THEN 'Sai thông tin A.CRM'
    ELSE NULL
  END AS is_rule3,
  CASE
    WHEN manv IS NULL OR (manv NOT LIKE 'MR%' AND manv NOT LIKE 'KN%') THEN 'Thiếu thông tin Code CRS'
    WHEN (
      (CONCAT(LEFT(manv, 6), DATE(a.thang)) NOT IN (
        SELECT DISTINCT CONCAT(LEFT(manv, 6), DATE(thang))
        FROM `staging.d_users_bytime`
        WHERE LEFT(rsmid, 6) = 'MR0485'
      ) AND makenhkh_cu = 'TP')
      OR
      (CONCAT(LEFT(manv, 6), DATE(a.thang)) NOT IN (
        SELECT DISTINCT CONCAT(LEFT(manv, 6), DATE(thang))
        FROM `staging.d_users_bytime`
        WHERE LEFT(rsmid, 6) in ('MR0081','MR1137')
      ) AND makenhkh_cu IN ('INS', 'CLC', 'PCL'))
      OR
      (CONCAT(LEFT(manv, 6), DATE(a.thang)) NOT IN (
        SELECT DISTINCT CONCAT(LEFT(manv, 6), DATE(thang))
        FROM `staging.d_users_bytime`
        WHERE LEFT(rsmid, 6) = 'MR2685'
      ) AND makenhkh_cu = 'MT')
    ) THEN 'Sai Kênh CRS'
    WHEN CONCAT(CASE WHEN manv like 'KN%' then CONCAT('MR',right(manv,4)) ELSE LEFT(manv, 6) END, DATE(a.thang)) NOT IN (
      SELECT CONCAT(msnvcsmmoi, DATE(thang))
      FROM `staging.d_hr_dsns_bytime`
      WHERE msnvcsmmoi IS NOT NULL
    ) THEN 'CRS đã nghỉ việc'
    ELSE NULL
  END AS is_rule4,
  CASE
    WHEN LEFT(manv, 6) IN (
      SELECT msnvcsmmoi
      FROM `staging.d_hr_dsns`
      WHERE ngaynghiviecdieuchuyen = 'TS'
    ) THEN 'Nhân viên nghỉ TS'
    ELSE NULL
  END AS is_rule5,
  CASE
    WHEN LEFT(manv, 6) != b.col.ma_nvbh AND makenhkh_cu = 'TP' THEN 'Đổi nhân viên TP'
    WHEN LEFT(manv, 6) != c.slsperid AND makenhkh_cu = 'INS' THEN 'Đổi nhân viên INS'
    WHEN LEFT(manv, 6) != c.slsperid AND makenhkh_cu = 'CLC' THEN 'Đổi nhân viên CLC'
    WHEN LEFT(manv, 6) != b.col.ma_nvbh AND makenhkh_cu = 'MT' THEN 'Đổi nhân viên MT'
    ELSE NULL
  END AS is_rule6,
  CURRENT_DATETIME("+7") AS inserted_at
FROM `warehouse.f_raw_data_sales_yoy` a
LEFT JOIN `warehouse.f_mapping_crs_bytime` b
  ON a.makhdms = b.custid AND DATE(a.thang) = DATE(b.thang)
LEFT JOIN tuyen_cvbh_hd_ins c
  ON a.makhdms = c.custid
  AND makenhkh_cu IN ('INS', 'CLC')
  AND DATE(a.thang) = DATE(c.thang)
  AND a.masanpham = c.invtid
LEFT JOIN `warehouse.dim_excluded_makhdms` d ON a.makhdms = d.makhdms
WHERE date(a.ngaychungtu) >= date(partition_date)
AND d.makhdms is null
AND a.makenhkh_cu in ('MT','TP', 'INS', 'CLC', 'PCL')
)

;

Create or replace table `warehouse.f_raw_data_sales_yoy_canhbao`

copy `staging_temp.f_raw_data_sales_yoy_canhbao_temp`;
END;
