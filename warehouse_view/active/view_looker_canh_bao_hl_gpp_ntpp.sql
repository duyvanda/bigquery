CREATE VIEW `spatial-vision-343005.warehouse.view_looker_canh_bao_hl_gpp_ntpp`
AS SELECT clmn1_, clmn2_, clmn3_, clmn11_ AS t0_qt_27sykvm2ld, clmn8_ AS t0_qt_cph2ien2ld, clmn5_ AS t0_qt_o4x1awo2ld, clmn13_ AS t0_qt_u19q5zm2ld FROM (
SELECT CASE WHEN (SAFE_CAST(clmn0_ AS DATETIME) >= clmn10_) THEN 'Y' ELSE 'N' END AS clmn12_, CASE WHEN (SAFE_CAST(clmn0_ AS DATETIME) >= clmn10_) THEN 'Y' ELSE 'N' END AS clmn13_, clmn1_, clmn2_, clmn3_, clmn11_, clmn8_, clmn5_ FROM (
SELECT DATETIME_TRUNC(clmn9_, SECOND) AS clmn10_, DATETIME_TRUNC(clmn9_, SECOND) AS clmn11_, clmn0_, clmn1_, clmn2_, clmn3_, clmn8_, clmn5_ FROM (
SELECT DATETIME_SUB(SAFE_CAST(clmn7_ AS DATETIME), INTERVAL 14 DAY) AS clmn9_, clmn0_, clmn1_, clmn2_, clmn3_, clmn8_, clmn5_ FROM (
SELECT PARSE_DATE('%Y-%m-%d', clmn6_) AS clmn7_, PARSE_DATE('%Y-%m-%d', clmn6_) AS clmn8_, clmn0_, clmn1_, clmn2_, clmn3_, clmn5_ FROM (
SELECT FORMAT_TIMESTAMP('%Y-%m-%d', SAFE_CAST(clmn4_ AS TIMESTAMP)) AS clmn6_, clmn0_, clmn1_, clmn2_, clmn3_, clmn5_ FROM (
SELECT DATE(CURRENT_TIMESTAMP()) AS clmn0_, t0.custid AS clmn1_, t0.custname AS clmn2_, t0.hcotypeid AS clmn3_, t0.legaldate AS clmn4_, 'export_sql' AS clmn5_ FROM `spatial-vision-343005.staging.d_master_khachhang` AS t0
)
)
)
)
)
) WHERE (STRPOS(clmn3_, 'NTPP') > 0 AND clmn12_ IN ('Y')) AND clmn8_ > '1900-01-01' GROUP BY clmn1_, clmn2_, clmn3_, t0_qt_27sykvm2ld, t0_qt_cph2ien2ld, t0_qt_o4x1awo2ld, t0_qt_u19q5zm2ld ORDER BY clmn1_ DESC LIMIT 2000001;;