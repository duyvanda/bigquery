CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_hub()
BEGIN 
  TRUNCATE TABLE staging_temp.f_hub_temp;

 INSERT INTO staging_temp.f_hub_temp(

-- Create or replace table staging_temp.f_hub_temp
-- as

-- WITH danhsach_kh22 as
-- (
--   SELECT 
--     statedescr as tentinhkh,
--     date_trunc(date(crtd_datetime),month) as crtd_datetime ,
--     count(distinct custid) as slkh
--   FROM `spatial-vision-343005.staging.d_master_khachhang`
--   where channel not in ('NB','OTH_LAB')
--         and statedescr in ('Nam Định','Ninh Bình', 'Hà Nam')
--         -- and crtd_datetime <= '2022-01-31'
--   group by 1,2
-- )
-- select 
--   slkh,tentinhkh,crtd_datetime,
--   sum(slkh) OVER (PARTITION BY tentinhkh ORDER BY crtd_datetime asc ROWS UNBOUNDED PRECEDING) AS running_sum

-- from danhsach_kh22

WITH thang as
(
  select distinct date(thang) as thang
  from `spatial-vision-343005.staging.f_sales` 
  where date(thang) >= '2022-01-01'
)
,

slkh_22 as
(
  SELECT 
    b.thang,
    a.statedescr as tentinhkh,
    custid,
    date_trunc(date(a.crtd_datetime),month) as crtd_datetime ,
    case when date_trunc(date(a.crtd_datetime),month) < '2022-01-01' then '2022-01-01' else date_trunc(date(a.crtd_datetime),month) end as crtd_datetime_1,
    count(distinct a.custid) as slkh
  FROM thang b 
  left join `spatial-vision-343005.staging.d_master_khachhang` a on (case when date_trunc(date(a.crtd_datetime),month) < '2022-01-01' then '2022-01-01' else date_trunc(date(a.crtd_datetime),month) end) = b.thang
  where a.channel not in ('NB','OTH_LAB')
        and a.statedescr in ('Nam Định','Ninh Bình', 'Hà Nam','Thái Bình')
        -- and crtd_datetime <= '2022-01-31'
  group by 1,2,3,4,5
)
select *,
case when tentinhkh = 'Hà Nam' then count(distinct custid) else 0 end as hanam,
case when tentinhkh = 'Ninh Bình' then count(distinct custid) else 0 end as ninhbinh,
case when tentinhkh = 'Nam Định' then count(distinct custid) else 0 end as namdinh,
case when tentinhkh = 'Thái Bình' then count(distinct custid) else 0 end as thaibinh,



from slkh_22
group by 1,2,3,4,5,6
  );

Create or replace table `warehouse.f_hub`

copy `staging_temp.f_hub_temp`;

End;