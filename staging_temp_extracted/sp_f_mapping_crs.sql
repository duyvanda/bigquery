-- ==========================================================================
-- Routine Name : sp_f_mapping_crs
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-07-23 10:40:14.482000+00:00
-- Last Altered : 2026-07-23 10:40:14.482000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_mapping_crs()
BEGIN

DECLARE state_list ARRAY <STRING> DEFAULT
['Bắc Kạn','Cao Bằng'
];

DECLARE cs_list ARRAY<STRING> DEFAULT [
  'MR1682KN', 'MR2504', 'MR1232', 'MR0806', 'MR2608', 'MR2111', 'MR1682', 'MR2504KN', 'MR1232KN',
  'MR0806KN', 'MR2608KN', 'MR2111KN', 'MR2993', 'MR2993KN', 'MR3038', 'MR3038KN', 'MR2608KN',
  'MR2948', 'MR2948KN', 'MR2608','MR3196','MR3196KN'
];
TRUNCATE TABLE staging_temp.f_mapping_crs_temp;
INSERT INTO `staging_temp.f_mapping_crs_temp`
(
-- Create or replace table `staging_temp.f_mapping_crs_temp`
-- cluster by custid,channel
-- as
-- (
WITH bang_doanhso_2022 AS (
  SELECT
    a.makhdms,
    SUM(a.doanhsochuavat) AS doanhsochuavat,
    MAX(ngaychungtu) as max_ngay_chung_tu
  FROM `staging.f_sales` a
  WHERE ngaychungtu >= '2022-01-01'
  GROUP BY 1
  HAVING doanhsochuavat > 0
),
tuyenban AS (
  WITH data_tuyen AS (
    SELECT
      a.custid,
      a.slsperid,
      SAFE_CAST(a.enddate AS TIMESTAMP) as crtd_datetime,
      CASE
        WHEN routetype IN ('B', 'D') THEN 1
        ELSE 2
      END AS routetype
    FROM `staging.sync_dms_srm` a
    LEFT JOIN `staging.d_master_khachhang` c ON a.custid = c.custid
    WHERE c.channel IN ('TP', 'PCL')
      AND delroutedet IS FALSE
      AND routetype IN ('B', 'D')
      AND ifnull(salesrouteid,'') != ('CS_CTO1')
  )
  SELECT
    a.*,
    b.tencvbh,
    CASE
      WHEN a.slsperid IN UNNEST(cs_list) THEN 'CX'
      ELSE b.tenquanlytt
    END AS tenquanlytt,
    b.tenquanlyvung
  FROM data_tuyen a
  LEFT JOIN `staging.d_users` b ON a.slsperid = b.manv
  WHERE tenquanlyvung NOT IN ('Lương Trịnh Thắng') OR tenquanlyvung IS NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY custid ORDER BY routetype ASC, crtd_datetime DESC) = 1
),
tuyen_cvbh_hd AS (
  SELECT
    a.contractid,
    b.custid,
    b.gentodate,
    a.genslsperid as slsperid,
    c.supid AS macrm,
    c.tenquanlytt
  FROM `staging.d_oricontractdet` a
  INNER JOIN `staging.d_oricontract` b ON a.contractid = b.contractid
  LEFT JOIN `staging.d_users` c ON a.genslsperid = c.manv
  WHERE c.tenquanlyvung in ('Nguyễn Thọ Chiến','Vũ Mừng') AND LEFT(invtid, 1) <> 'V'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY custid ORDER BY b.gentodate DESC,a.crtd_datetime DESC, a.genslsperid ASC) = 1

)
,final_logic AS (
SELECT
  d.custid,
  d.statedescr,
  Case
      when d.districtdescr in ('Quận 2', 'Quận 9') then 'Thành phố Thủ Đức'
      else d.districtdescr
  end as districtdescr,
  d.wardname,
  d.channel,
  d.shoptype,
  d.active,
  CASE
    when d.custid ='007015' then STRUCT ('MR2366' as ma_nvbh,'CRS (Trong MCP)' as phan_loai_mcp)
    WHEN d.statedescr IN UNNEST(state_list)  AND d.channel = 'TP' THEN  ('CX' , 'Rural' )
    WHEN d.channel IN ('INS', 'CLC') THEN (k.slsperid, 'CRS (Trong MCP)')
    WHEN j.slsperid NOT IN UNNEST(cs_list)
      AND j.tenquanlytt != 'Nguyễn Văn Tiến'
      AND d.channel IN ('TP', 'PCL')
      AND j.slsperid IS NOT NULL THEN (j.slsperid, 'CRS (Trong MCP)' )
    WHEN d.channel IN ('PCL') AND k.slsperid IS NOT NULL THEN (k.slsperid, 'CRS (Trong MCP)')
    ELSE (NULL, 'Chưa xác định')
  END AS col,
  CASE
    WHEN l.makhdms IS NOT NULL THEN 'Y'
    ELSE 'N'
  END AS is_co_ds_2022,
  c1.doanhsochuavat,
  CAST(DATE(c1.max_ngay_chung_tu) AS STRING) as  max_ngay_chung_tu
FROM staging.d_master_khachhang d
LEFT JOIN bang_doanhso_2022 c1 ON d.custid = c1.makhdms
LEFT JOIN `staging.d_dms_master_users` m ON d.crtd_user = m.username
LEFT JOIN tuyenban j ON d.custid = j.custid
LEFT JOIN tuyen_cvbh_hd k ON k.custid = d.custid
LEFT JOIN bang_doanhso_2022 l ON l.makhdms = d.custid
WHERE d.channel NOT IN ('OTH_LAB', 'NB')
)

SELECT
    a.*,
    u.tencvbh,
    u.supid,
    u.tenquanlytt,
    u.asm,
    u.tenquanlykhuvuc,
    u.rsmid,
    u.tenquanlyvung
FROM final_logic a
LEFT JOIN `staging.d_users` u ON a.col.ma_nvbh = u.manv

)
;

Create or replace table `warehouse.f_mapping_crs`

copy `staging_temp.f_mapping_crs_temp`;
END;
