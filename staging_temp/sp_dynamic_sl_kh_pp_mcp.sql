CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_dynamic_sl_kh_pp_mcp(col1 STRING, col2 STRING)
BEGIN

DECLARE sql_string STRING;
DECLARE view_name STRING;

--CALL `spatial-vision-343005.staging_temp.sp_dynamic_sl_kh_pp_mcp`('manv', 'manv');
--CALL `spatial-vision-343005.staging_temp.sp_dynamic_sl_kh_pp_mcp`('supid', 'crm');

SET view_name = 'staging_temp.view_dynamic_sl_kh_pp_mcp_' || col1;

SET sql_string = '''

CREATE OR REPLACE VIEW `''' || view_name || '''` AS

WITH sl_kh_pp_mcp AS (
    SELECT
    DISTINCT
    EXTRACT(QUARTER FROM a.thang) AS quy,
    EXTRACT(YEAR FROM a.thang) AS nam,
    ''' || col1 || ''' as manv,
    ma_khachhang as custid,
    FROM
    `warehouse.f_thongtin_tuyen_mcp_tp_pcl` a
    WHERE a.active = 'Active'
    AND a.thang >= '2025-01-01'
    and a.tuyen_cn = 0
)

, data_sales_pp_kh AS (
    SELECT
        ''' || col2 || ''' as manv,
        makhdms,
        sodondathang,
        EXTRACT(QUARTER FROM a.thang) AS quy,
        EXTRACT(YEAR FROM a.thang) AS nam,
        SUM(soluong * dongiacovat) AS ds
    FROM
    `staging_temp.f_sales_crs_lhq_bytime` a
    WHERE
        ngaychungtu >= '2025-01-01'
        AND a.makenhkh IN ('TP', 'PCL')
        AND a.doanhsochuavat <> 0
        AND datatype1 = 'f_sales'
    GROUP BY ALL
)

, result_data_sales_pp_kh AS (
    SELECT DISTINCT
        manv,
        quy,
        makhdms,
        nam
    FROM
        data_sales_pp_kh
    WHERE
        ds >= 250000
)


SELECT
    a.manv,
    a.quy,
    a.nam,
    COUNT(DISTINCT b.makhdms) AS th_kh_pp,
    COUNT(DISTINCT a.custid) AS sl_kh_mcp,
    COUNT(DISTINCT a.custid) AS tong_sl_pp_mcp,        
    FROM
    sl_kh_pp_mcp a
    LEFT JOIN result_data_sales_pp_kh b
    ON a.manv = b.manv
    AND a.custid = b.makhdms
    AND a.quy = b.quy
    AND a.nam = b.nam
GROUP BY ALL

''';

EXECUTE IMMEDIATE sql_string;

END;