CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_quantridichvugiaohang_page_leadtime()
BEGIN 
TRUNCATE TABLE staging_temp.f_quantridichvugiaohang_page_leadtime_temp;


INSERT INTO staging_temp.f_quantridichvugiaohang_page_leadtime_temp
(

-- CREATE OR REPLACE table staging_temp.f_quantridichvugiaohang_page_leadtime_temp

-- partition by date(ngayphathanhhd)
-- as

with cum as
(
  select distinct
    statedescr,
    districtdescr,
    wardname,
    cluster_state
  from `spatial-vision-343005.staging.d_leadtimekpi`
)
,

cum1 as
(
  select distinct
    statedescr,
    districtdescr,
    cluster_state
  from `spatial-vision-343005.staging.d_leadtimekpi`
  where districtdescr != 'Huyện Bình Chánh'
)

select 
  a.*,
  extract(dayofweek from a.ngaytaodon) as thutaodon,
  extract (hour from a.ngaytaodon) as giotaodon,
  c.supid,
  d.chinhanh as chinhanh_dialy,
  case when e.cluster_state is null then f.cluster_state else e.cluster_state end as cluster_state,
  trim(a.thongtinxe) as thongtinxe_fix,
  case when role = 'LOG' and deliveryunit = 'Pha Nam' and (thongtinxe is null or thongtinxe like 'NVC%') then 'thongtinxe_sai'
       when role in ('LOG','MDS') and deliveryunit = 'Chành Xe' and (thongtinxe is null or thongtinxe like 'NVC%') then 'thongtinxe_sai'
       when role in ('LOG') and deliveryunit = 'NVC' and thongtinxe is null then 'thongtinxe_sai'
       else null end as check_ttxe

from `spatial-vision-343005.warehouse.f_overview_mds_hanh1` a
left join `spatial-vision-343005.staging.d_users`  c on a.slsperid_dv = c.manv
left join `spatial-vision-343005.staging.d_tinh` d on a.tinh = d.tinh
LEFT JOIN cum e on a.tinh = e.statedescr 
                and (case when a.districtdescr in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' else a.districtdescr end) 
                    = (case when e.districtdescr in ('Thị xã Tịnh Biên') then 'Huyện Tịnh Biên' else e.districtdescr end)
                and a.wardname = e.wardname
LEFT JOIN cum1 f on a.tinh = f.statedescr 
                 and (case when a.districtdescr in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' else a.districtdescr end) 
                     = (case when f.districtdescr in ('Huyện Tịnh Biên') then 'Thị xã Tịnh Biên' else f.districtdescr end)
where date(ngayphathanhhd) between  date(datetime_sub(current_datetime("+7"),interval 6 month)) and  date(current_datetime("+7"))

);

Create or replace table `warehouse.f_quantridichvugiaohang_page_leadtime`

copy `staging_temp.f_quantridichvugiaohang_page_leadtime_temp`;

End;