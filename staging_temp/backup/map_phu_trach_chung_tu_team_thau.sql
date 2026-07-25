CREATE FUNCTION `spatial-vision-343005`.staging.map_phu_trach_chung_tu_team_thau(shortterritorydescr STRING) RETURNS STRING
AS (
(
  select 
  case when shortterritorydescr in ('BTB','NTB') then 'MR1432'
  when shortterritorydescr in ('DB1','DB2','DN1','DN2','HN','TB') then 'MR1132'
  when shortterritorydescr in ('HCM','MK2') then 'MR2643'
  when shortterritorydescr in ('MD1','MD2','MK1') then 'MR2956'
  else '' end
)
);