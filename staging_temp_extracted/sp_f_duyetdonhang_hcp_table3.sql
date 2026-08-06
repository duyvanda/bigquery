-- ==========================================================================
-- Routine Name : sp_f_duyetdonhang_hcp_table3
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2024-03-07 07:23:47.251000+00:00
-- Last Altered : 2024-03-07 07:23:47.251000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_duyetdonhang_hcp_table3()
BEGIN
  TRUNCATE TABLE staging_temp.f_duyetdonhang_hcp_table3_temp;

 INSERT INTO staging_temp.f_duyetdonhang_hcp_table3_temp(

-- Create or replace table staging_temp.f_duyetdonhang_hcp_table3_temp
-- as
with data_duyetdonhang as (
SELECT
  thang,
  tenquanlytt,
  macrm,
  SUM(doanhsochuavat) AS doanhsochuavat,
  avg(dinhmuc_duyetdon) as dinhmuc_duyetdon,
  avg(dinhmuc_duyetdon_conlai) as dinhmuc_duyetdon_conlai,
  sum(sl_dh) as sl_dh
FROM
  `warehouse.f_duyetdonhang_hcp`
  group by 1,2,3
  order by thang
  )
select
  extract(quarter from thang) quarter,
  extract(year from thang) as nam,
  date(extract(year from thang),extract(quarter from thang) *3,1) as thang,
  tenquanlytt,
  macrm,
  SUM(doanhsochuavat) AS doanhsochuavat,
  sum(dinhmuc_duyetdon) as dinhmuc_duyetdon,
  sum(dinhmuc_duyetdon_conlai) as dinhmuc_duyetdon_conlai,
  sum(sl_dh) as sl_dh
  from data_duyetdonhang
  where thang >='2023-04-01'
  group by 1,2,3,4,5

  );

Create or replace table `warehouse.f_duyetdonhang_hcp_table3`

copy `staging_temp.f_duyetdonhang_hcp_table3_temp`;

End;
