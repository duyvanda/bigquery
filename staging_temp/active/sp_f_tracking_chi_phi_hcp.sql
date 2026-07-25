CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_tracking_chi_phi_hcp()
BEGIN 
 
TRUNCATE TABLE staging_temp.f_tracking_chi_phi_hcp_temp;

INSERT INTO `staging_temp.f_tracking_chi_phi_hcp_temp`

(   
-- Create or replace table staging_temp.f_tracking_chi_phi_hcp_temp as

with 
doanhso as 
(
select 
  'Data_DS' as datatype,
  cast(null as string) as ma_nv,
  cast(null as string) as ten_nv,
  trim(upper(tenquanlytt)) as quan_ly,
  b.pubcustid as makhc,
  trim(upper(b.pubcustname)) as ten_hco,
  trim(upper(b.statedescr)) as tinh,
  cast(null as string) as ct,
  cast(null as string) as khoa_phong,
  extract(month from ngaychungtu) as thang,
  cast(null as string) as ma_hcp,
  cast(null as string) as ten_hcp,
  cast(null as string) as nganh,
  cast(null as string) as chuyen_khoa,
  cast(null as string) as cxm,
  cast(null as string) as note,
  extract(year from b.inserted_at) as year,
  0 as  phan_bo_tai_tro_khac,
  0 as phan_bo_smnsms,
  0 as cost,
  sum(doanhsochuavat) as doanhsochuavat
from `warehouse.f_raw_data_sales_yoy` a
LEFT JOIN `staging.d_master_khachhang` b on a.makhdms =b.custid
where ngaychungtu >='2024-01-01' and ngaychungtu <'2024-12-31' and tenquanlyvung ='Nguyễn Thọ Chiến'
group by all
having doanhsochuavat <>0
),

tracking_hco as (
SELECT 
'Tracking_HCO' as datatype,
cast(null as string) as ma_nv,
cast(null as string) as ten_nv,
trim(upper(quan_ly)) as quan_ly,
trim(makhc) as makhc,
trim(upper(ten_hco)) as ten_hco,
trim(upper(tinh)) as tinh,
trim(upper(ct)) as ct,
trim(upper(khoa_phong)) as khoa_phong,
cast(thang as int) as thang,
cast(null as string) as ma_hcp,
cast(null as string) as ten_hcp,
cast(null as string) as nganh,
cast(null as string) as chuyen_khoa,
trim(upper(cxm)) as cxm,
note,
extract(year from inserted_at) year,
0 as phan_bo_tai_tro_khac,
0 as phan_bo_smnsms,
sum(cost) as cost,
0 as doanhsochuavat
FROM `spatial-vision-343005.staging.d_tracking_cost_hco` 
group by all 
),

tracking_hcp as 
(
  SELECT 
'Tracking_HCP' as datatype,
ma_nv,
trim(upper(ten_nv)) as ten_nv,
trim(upper(ten_ql)) as ten_ql,
ma_kh_chung,
trim(upper(ten_kh_chung)) as ten_kh_chung,
trim(upper(tinh)) as tinh,
trim(upper(ct)) as ct,
trim(upper(khoa_phong)) as khoa_phong,
cast(thang_thuc_hien as int) as thang_thuc_hien,
ma_hcp,
trim(upper(ten_hcp)) as ten_hcp,
trim(upper(nganh))  as nganh,
trim(upper(chuyen_khoa)) as chuyen_khoa,
cast(null as string) as cxm,
cast(null as string) as note,
extract(year from inserted_at) as year,
0 as phan_bo_tai_tro_khac,
0 as phan_bo_smnsms,
sum(cost) as cost,
0 as doanhsochuavat
 FROM `spatial-vision-343005.staging.d_tracking_cost_hcp`
 group by all
),

tracking_cost_year as (
  SELECT
'Tracking_Cost' as datatype,
cast(null as string) as ma_nv,
cast(null as string) as ten_nv,
trim(upper(quan_ly)) as quan_ly,
cast(null as string) as makhc,
cast(null as string) as ten_hco,
cast(null as string) as tinh,
cast(null as string) as ct,
cast(null as string) as khoa_phong,
null as thang,
cast(null as string) as ma_hcp,
cast(null as string) as ten_hcp,
cast(null as string) as nganh,
cast(null as string) as chuyen_khoa,
cast(null as string) as cxm,
cast(null as string) as note,
extract(year from inserted_at) year,
cast(phan_bo_tai_tro_khac as float64) phan_bo_tai_tro_khac,
cast(phan_bo_smnsms as float64) as phan_bo_smnsms,
0 as cost,
0 as doanhsochuavat
from  `staging.d_tracking_cost_yearly`
),
union_all as (
select * from tracking_hco
UNION ALL 
SELECT * from tracking_hcp
UNION ALL
SELECT * from tracking_cost_year
UNION ALL
select * from doanhso

),

d_user as (
  select distinct supid,upper(tenquanlytt) as tenquanlytt  from `staging.d_users`  where tenquanlytt not like '%KN%' and supid not like '%KN%'
),

result as (
select 
a.*,
b.supid as ma_quan_ly,
Case when datatype ='Tracking_Cost' then date(2024,01,01) else  date(year,thang,01) end as thang_filter,
current_datetime("+7") as inserted_at

from union_all a 
LEFT JOIN d_user b  on a.quan_ly = b.tenquanlytt
)

select * from result 


);

Create or replace table `warehouse.f_tracking_chi_phi_hcp`

copy `staging_temp.f_tracking_chi_phi_hcp_temp`;

END;