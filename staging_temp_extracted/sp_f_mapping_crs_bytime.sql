-- ==========================================================================
-- Routine Name : sp_f_mapping_crs_bytime
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-04-26 03:24:05.994000+00:00
-- Last Altered : 2026-04-26 03:24:05.994000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_mapping_crs_bytime()
BEGIN
 DECLARE cs_list ARRAY<STRING> DEFAULT [
  'MR1682KN', 'MR2504', 'MR1232', 'MR0806', 'MR2608', 'MR2111', 'MR1682', 'MR2504KN', 'MR1232KN',
  'MR0806KN', 'MR2608KN', 'MR2111KN', 'MR2993', 'MR2993KN', 'MR3038', 'MR3038KN', 'MR2608KN',
  'MR2948', 'MR2948KN', 'MR2608','MR3196','MR3196KN'
];

TRUNCATE TABLE staging_temp.f_mapping_crs_bytime_temp;

INSERT INTO `staging_temp.f_mapping_crs_bytime_temp`

(
-- Create or replace table `staging_temp.f_mapping_crs_bytime_temp`
-- partition by date(thang)
-- cluster by custid,channel
-- as
-- (
WITH bang_doanhso_2022 AS (
  SELECT
    a.makhdms,
    SUM(a.doanhsochuavat) AS doanhsochuavat,
    MAX(ngaychungtu) as max_ngay_chung_tu
  FROM `spatial-vision-343005.staging.f_sales` a
  WHERE ngaychungtu >= '2022-01-01'
  GROUP BY 1
  HAVING doanhsochuavat > 0
),
tuyenban AS (
  WITH data_tuyen AS (
    SELECT
      a.thang,
      a.custid,
      a.slsperid,
      a.enddate as crtd_datetime,
      CASE
        WHEN routetype IN ('B', 'D') THEN 1
        ELSE 2
      END AS routetype
    FROM `spatial-vision-343005.staging.sync_dms_srm_bytime` a
    LEFT JOIN `staging.d_master_khachhang_bytime` c ON a.custid = c.custid
    WHERE c.channel IN ('TP', 'PCL','MT')
      AND delroutedet IS FALSE
      AND routetype IN ('B', 'D')
      AND (
            case when date (a.thang) >= '2025-06-01'  and ifnull(salesrouteid,'') = ('CS_CTO1') then false else true end
        )
  )
  SELECT
    a.*,
    b.tencvbh,
    CASE
      WHEN a.slsperid IN unnest(cs_list) THEN 'CX'
      ELSE b.tenquanlytt
    END AS tenquanlytt,
    b.tenquanlyvung
  FROM data_tuyen a
  LEFT JOIN `staging.d_users_bytime` b ON a.slsperid = b.manv and a.thang =b.thang
  WHERE tenquanlyvung NOT IN ('Lương Trịnh Thắng') OR tenquanlyvung IS NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY custid,a.thang ORDER BY routetype ASC, crtd_datetime DESC) = 1
),
tuyen_cvbh_hd_bytime as (
  select
    a.thang,
    a.custid,
    a.custname,
    a.slsperid
from `spatial-vision-343005.staging.d_get_contract_det_bytime` a
LEFT JOIN `staging.d_users_bytime` c ON a.slsperid = c.manv and a.thang =c.thang
  WHERE c.tenquanlyvung in ('Nguyễn Thọ Chiến','Vũ Mừng') AND LEFT(invtid, 1) <> 'V'
qualify row_number() over(partition by a.custid, a.thang order by a.gentodate desc, a.crtd_datetime desc, a.slsperid asc ) = 1
),
tuyen_cvbh_hd AS (
  SELECT
    a.contractid,
    b.custid,
    b.gentodate,
    a.genslsperid as slsperid,
    c.supid AS macrm,
    c.tenquanlytt,
    a.crtd_datetime
  FROM `spatial-vision-343005.staging.d_oricontractdet` a
  INNER JOIN `spatial-vision-343005.staging.d_oricontract` b ON a.contractid = b.contractid
  LEFT JOIN `staging.d_users` c ON a.genslsperid = c.manv
  WHERE c.tenquanlyvung in ('Nguyễn Thọ Chiến','Vũ Mừng') AND LEFT(invtid, 1) <> 'V'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY custid ORDER BY a.genlupd_datetime DESC,a.crtd_datetime DESC, a.genslsperid ASC) = 1
)
,final_prep AS (
SELECT
  d.thang,
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
    when d.custid ='007015' and d.thang >='2024-08-01' then STRUCT('MR2366' as ma_nvbh,'CRS (Trong MCP)' as phan_loai_mcp)

    when d.statedescr in (
                'Bắc Kạn',
                'Cao Bằng'
            )
            and d.channel = 'TP' and d.thang >='2025-11-01'
            then ('CX', 'Rural')

    when d.statedescr in (
                'Bắc Kạn',
                'Cao Bằng',
                'Điện Biên',
                'Lai Châu'
            )
            and d.channel = 'TP' and d.thang >='2024-07-01' and d.thang <='2025-10-31'
            then ('CX', 'Rural')
            when d.statedescr in (
                'Lào Cai',
                'Hà Giang'
            )
            and d.channel = 'TP' and d.thang >='2024-06-01'and d.thang <'2024-07-01' then ('MR0738KN' , 'CRS (Trong MCP)')
            when d.statedescr in (
                'Lào Cai',
                'Bắc Kạn',
                'Hà Giang',
                'Cao Bằng',
                'Điện Biên',
                'Lai Châu'
            )
            and d.channel = 'TP' and d.thang >='2024-04-01'and d.thang <'2024-06-01'  then ('CX' , 'Rural' )
            when d.statedescr in (
                'Lào Cai',
                'Sơn La',
                'Hòa Bình',
                'Bắc Kạn',
                'Hà Giang',
                'Cao Bằng',
                'Điện Biên',
                'Lai Châu'
            )
            and d.channel = 'TP' and d.thang >='2024-01-01' and d.thang <'2024-04-01' then ('CX' , 'Rural' )

    -- 010815 KH này lên đơn DL5-0425-01792 => Lấy theo tuyến
    WHEN ifnull(tb.slsperid,'none') NOT IN unnest(cs_list) -- ví dụ KH 002001
    AND ifnull(tb.tenquanlytt,'none') != 'Nguyễn Văn Tiến' -- không cần nhớ
    AND d.channel IN ('TP', 'PCL','MT')
    AND tb.slsperid IS NOT NULL THEN (tb.slsperid ,'CRS (Trong MCP)')
    WHEN d.channel IN ('TP') THEN (IFNULL(o.macrs, o1.macrs),'CRS (Ngoài MCP)') -- ví dụ KH 005943 tháng 4 năm 2025
    WHEN d.channel IN ('PCL') THEN  (IF (o1.ncrm like '%Chiến%' OR o1.ncrm LIKE '%Mừng%' , IFNULL(o.macrs, o1.macrs), NULL),'CRS (Ngoài MCP)')
    WHEN d.channel IN ('PCL') AND ifnull(k0.slsperid, k.slsperid) IS NOT NULL THEN (ifnull(k0.slsperid, k.slsperid),'CRS (Trong MCP)' )
    WHEN d.channel IN ('INS', 'CLC') THEN (ifnull(k0.slsperid, k.slsperid),'CRS (Trong MCP)')
    ELSE (NULL,'Chưa xác định' )
  END AS col,
  CASE
    WHEN c1.makhdms IS NOT NULL THEN 'Y'
    ELSE 'N'
  END AS is_co_ds_2022,
  c1.doanhsochuavat,
  CAST(DATE(c1.max_ngay_chung_tu) AS STRING) as  max_ngay_chung_tu
FROM `staging.d_master_khachhang_bytime` d
LEFT JOIN bang_doanhso_2022 c1 ON d.custid = c1.makhdms
LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` m ON d.crtd_user = m.username
LEFT JOIN tuyenban tb ON d.custid = tb.custid  and d.thang = tb.thang

-- mapping quận huyện với tỉnh + phường xã
LEFT JOIN `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs_bytime` o ON o.phuongxa IS NOT NULL
  AND TRIM(UPPER(d.statedescr)) = TRIM(UPPER(o.tinhtp))
  AND TRIM(UPPER(  Case
      when d.districtdescr in ('Quận 2', 'Quận 9') then 'Thành phố Thủ Đức'
      else d.districtdescr end )) = TRIM(UPPER(o.quanhuyen))
  AND TRIM(UPPER(d.wardname)) = TRIM(UPPER(o.phuongxa))
  and o.thang = date(d.thang)
  AND date(o.thang) <= '2025-05-31'
-- mapping quận huyện, tỉnh
LEFT JOIN `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs_bytime` o1 ON o1.phuongxa IS NULL
  AND TRIM(UPPER(d.statedescr)) = TRIM(UPPER(o1.tinhtp))
  AND TRIM(UPPER(  Case
      when d.districtdescr in ('Quận 2', 'Quận 9') then 'Thành phố Thủ Đức'
      else d.districtdescr end )) = TRIM(UPPER(o1.quanhuyen))
  and o1.thang = date(d.thang)
  and date (o1.thang) <= '2025-05-31'

LEFT JOIN tuyen_cvbh_hd_bytime k0 on k0.custid = d.custid and k0.thang = d.thang
LEFT JOIN tuyen_cvbh_hd k ON k.custid = d.custid and d.thang >= date_trunc(k.crtd_datetime,month)
WHERE d.channel NOT IN ('OTH_LAB', 'NB')
)
SELECT
f.*,
u.tencvbh,
u.supid,
u.tenquanlytt,
u.asm,
u.tenquanlykhuvuc,
u.rsmid,
u.tenquanlyvung,
FROM final_prep f
LEFT JOIN `staging.d_users_bytime` u ON f.col.ma_nvbh = u.manv AND f.thang = u.thang

);

Create or replace table `warehouse.f_mapping_crs_bytime`

copy `staging_temp.f_mapping_crs_bytime_temp`;
END;
