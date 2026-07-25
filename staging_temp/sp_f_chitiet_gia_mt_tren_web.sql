CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chitiet_gia_mt_tren_web()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_chitiet_gia_mt_tren_web_temp`;


 INSERT INTO `staging_temp.f_chitiet_gia_mt_tren_web_temp`

(   
-- Create or replace table staging_temp.f_chitiet_gia_mt_tren_web_temp as

with raw_data as (
SELECT 
parse_date("%d-%m-%Y",created_at) as created_at,
manhanvien,
tennhanvien,
tenkhachhang,

Case 
  when trim(lower(name)) like '%trẻ em%' and trim(lower(name)) like '%xisat%' then 'T302201018'
  when (trim(lower(name)) like '%hằng ngày%' and trim(lower(name)) like '%xisat%') 
      or (trim(lower(name)) like '%người lớn%' and trim(lower(name)) like '%xisat%')
  then 'T302201014'
  when trim(lower(name)) like '%osla%' then 'OH031'
else null end as ma_sp,
name,
price,
( select max(updated_at) from `spatial-vision-343005.staging.crawler_products_binh_on_gia` ) as updated_at
 FROM `spatial-vision-343005.staging.crawler_products_binh_on_gia` 
)

select a.*,b.descr,b.descr1 from raw_data a 
LEFT JOIN `staging.d_dms_master_invtid` b on a.ma_sp = b.invtid
);

Create or replace table `warehouse.f_chitiet_gia_mt_tren_web`

copy `staging_temp.f_chitiet_gia_mt_tren_web_temp`;




END;