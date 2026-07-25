CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_so_sanh_toa_do_longchau_hn()
BEGIN 
 
TRUNCATE TABLE staging_temp.f_so_sanh_toa_do_longchau_hn_temp;

INSERT INTO `staging_temp.f_so_sanh_toa_do_longchau_hn_temp`

(   

-- Create table staging_temp.f_so_sanh_toa_do_longchau_hn_temp
-- cluster by custid,districtdescr,wardname,quan
-- as 

with 
tuyen_dms_moinhat as (
    with data_tuyen as (
        SELECT
            custid,
            slsperid,
            crtd_datetime,
            Case
                when routetype in ('B', 'D') then 1
                else 2
            end as routetype,
        FROM
            `spatial-vision-343005.staging.sync_dms_srm`
        where
            delroutedet is false
    )
    select
        *
    from
        data_tuyen 
        qualify row_number() over (
            partition by custid
            order by
                routetype asc,
                crtd_datetime desc
        ) = 1
),

ds_kh as (
select makhdms,
sum(Case when extract (year from ngaychungtu) =2023 then doanhsochuavat else 0 end) as doanhso_2023,
sum(Case when extract (year from ngaychungtu) =2024 then doanhsochuavat else 0 end) as doanhso_2024,
from `warehouse.f_sales_crs` where ngaychungtu >='2023-01-01'
group by 1
)
,
ds_nt_hcm as 
(
  select custid,custname,address,statedescr,districtdescr,wardname,shortterritorydescr,hcotypeid,lat as lat_nt,lng as lng_nt 
  from `staging.d_master_khachhang` 
  where channel ='TP' and hcotypeid ='NT'and statedescr ='Thành phố Hà Nội'
)
select 
a.*except(lng),
a.lng as lgn,
b.*,
round(ST_DISTANCE(ST_GEOGPOINT(a.lng, a.lat), ST_GEOGPOINT(b.lng_nt, b.lat_nt))/1000,1) as distance_in_kilometers ,
c.doanhso_2023,
c.doanhso_2024,
a.lat || ',' || a.lng as lat_lng_lc,
b.lat_nt || ',' || b.lng_nt as lat_lng_nt_hcm,
current_datetime("+7") as updated_at,
'Mapping' as datatype,
Case when d.custid is not null then 'Trong MCP' else 'Ngoài MCP' end as is_check_mcp

from `staging.d_manual_toa_do_nt_long_chau_hn` a 
LEFT JOIN ds_nt_hcm b on 1 =1 
LEFT JOIN ds_kh c on c.makhdms =b.custid
LEFT JOIN tuyen_dms_moinhat d on b.custid = d.custid

UNION ALL 
select 
a.*except(lng),
a.lng as lgn,
null as custid,
a.tennhathuoc as custname,
a.diachi as address,
a.tinh as statedescr,
a.quan as districtdescr,
null as wardname,
null as shortterritorydescr,
null as hcotypeid,
null  as lat_nt,
null as lng_nt,
0 as distance_in_kilometers,
0 as doanhso_2023,
0 as doanhso_2024,
a.lat || ',' || a.lng as lat_lng_lc,
a.lat || ',' || a.lng as lat_lng_nt_hcm,
current_datetime("+7") as updated_at,
'Long Châu' as datatype,
null as is_check_mcp
from `staging.d_manual_toa_do_nt_long_chau_hn` a 

  );

Create or replace table `warehouse.f_so_sanh_toa_do_longchau_hn`

copy `staging_temp.f_so_sanh_toa_do_longchau_hn_temp`;

END;