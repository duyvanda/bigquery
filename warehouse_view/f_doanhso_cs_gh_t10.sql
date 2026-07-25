CREATE VIEW `spatial-vision-343005.warehouse.f_doanhso_cs_gh_t10`
AS with ds as (
SELECT 
'2024-10-01' as thang,
macongtycn,
sodondathang,
makhdms,
tenkhachhang,
tentinhkh,
tenquanhuyen,
phuongxa,
makenhkh,
ngaychungtu,
date(ngaychotso) as ngay,

Case when (ngaychotso >='2024-10-01' and ngaychotso <'2024-11-01') then dschuvat_giaohang else 0 end as ds_chuavat_chotso,
0  as ds_chuavat_gh,
inserted_at,
 FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2` WHERE 
ngaychungtu >='2024-09-01' and ( (ngaychotso >='2024-10-01' and ngaychotso <'2024-11-01')  )
UNION ALL 
SELECT 
'2024-10-01' as thang,
macongtycn,
sodondathang,
makhdms,
tenkhachhang,
tentinhkh,
tenquanhuyen,
phuongxa,
makenhkh,
ngaychungtu,
date(ngaygiaohang_fix) as ngay,
0 as ds_chuavat_chotso,
Case when (ngaygiaohang_fix >='2024-10-01' and ngaygiaohang_fix <'2024-11-01')  then dschuvat_giaohang else 0 end as ds_chuavat_gh,
inserted_at,
 FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2` WHERE 
ngaychungtu >='2024-09-01' and ( (ngaygiaohang_fix >='2024-10-01' and ngaygiaohang_fix <'2024-11-01') )
)

select a.*except(ds_chuavat_chotso,ds_chuavat_gh),
sum(ds_chuavat_gh) as ds_chuavat_gh,
sum(ds_chuavat_chotso) as ds_chuavat_chotso

 from ds a 
 group by all
 order by sodondathang ;