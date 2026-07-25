CREATE VIEW `spatial-vision-343005.warehouse.view_chitiet_gia_mt_tai_cuahang`
AS with raw_data as (
select 
date(timestamp) created_at,
chonkhachhang as tenkhachhang,
sanpham,
Case when trim(lower(sanpham)) like '%xisat%' and trim(lower(sanpham)) like '%xanh%'  then 'T302201014'
     when trim(lower(sanpham)) like '%xisat%' and trim(lower(sanpham)) like '%hồng%' then 'T302201018'
     when trim(lower(sanpham)) like '%osla%'then 'OH031'
     else null end as ma_sp,
tenstoreghicuthediachistore,
giabanletaistoreghicuthegiavidu20000,
hinhanhsanphamcokemgia,
chonmanv as tennhanvien
 from `staging.d_form_theo_doi_gia_mt_2024`
)

select a.*,
b.manv as manhanvien,
c.descr,
c.descr1
 from raw_data a 
LEFT JOIN `staging.d_users` b on a.tennhanvien = b.tencvbh
LEFT JOIN `staging.d_dms_master_invtid` c on a.ma_sp = c.invtid;