CREATE PROCEDURE `spatial-vision-343005`.staging_temp.api_ds_theo_khach_example(p_makhdms STRING, p_startdate STRING, p_enddate STRING, p_page STRING, p_limit STRING)
OPTIONS(
  strict_mode=false)
BEGIN
-- Default values
DECLARE current_dt DATE DEFAULT CURRENT_DATE();
-- SET PARAMS
DECLARE set_makhdms STRING DEFAULT 'None';
DECLARE set_enddate, set_startdate DATE;
DECLARE set_page NUMERIC DEFAULT 1;
DECLARE set_limit NUMERIC DEFAULT 10000;


SET set_makhdms = IF (p_makhdms = '', set_makhdms, p_makhdms);
SET set_startdate = IF (p_startdate = '', current_dt, DATE(p_startdate) );
SET set_enddate = IF (p_enddate = '', current_dt, DATE(p_enddate) );
SET set_page = IF (p_page = '', set_page, PARSE_NUMERIC(p_page) );
SET set_limit = IF (p_limit = '', set_limit, PARSE_NUMERIC(p_limit) );


-- GET ALL MDS, Vì không có mã KH
IF set_makhdms = 'None'
THEN
  select makhdms, sum(doanhsochuavat) as ds_chua_vat,
  cast (max(inserted_at) as STRING FORMAT 'YYYY-MM-DD HH:MM:SS') as last_sync_time,
  ROW_NUMBER() OVER (ORDER BY COUNT(*) ASC) ac,
  CEIL(ROW_NUMBER() OVER (ORDER BY COUNT(*) ASC)/set_limit) as page
  from `staging.f_sales`
  where
  date(ngaychungtu) >= set_startdate
  and date(ngaychungtu) <= set_enddate
  group by 1
  ;
  --
  ELSE
  select makhdms, sum(doanhsochuavat) as ds_chua_vat, cast (max(inserted_at) as STRING FORMAT 'YYYY-MM-DD HH:MM:SS') as last_sync_time,
  ROW_NUMBER() OVER (ORDER BY COUNT(*) ASC) ac,
  CEIL(ROW_NUMBER() OVER (ORDER BY COUNT(*) ASC)/set_limit) as page
  from `staging.f_sales`
  where
  makhdms = set_makhdms and
  date(ngaychungtu) >= set_startdate
  and date(ngaychungtu) <= set_enddate
  group by 1
  ;
END IF;
END;