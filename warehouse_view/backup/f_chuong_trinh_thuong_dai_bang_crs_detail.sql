CREATE VIEW `spatial-vision-343005.warehouse.f_chuong_trinh_thuong_dai_bang_crs_detail`
AS with 
sku_bq as 
(
select 
slsperid as manv,maphanhanghco,sum(count_kh_sp) as sl_masp,count(distinct makhdms) as sl_makhdms, 
round(safe_divide(sum(count_kh_sp) , count(distinct makhdms)),1) as ty_le_sku_tb_1kh, 
 from `warehouse.f_phanhang_theo_sku`
 where maphanhanghco is not null
 group by all
)
,
data_sales as (
select 
left(a.manv,6) as manv,
b.tencvbh,
a.crm as ma_crm,
a.tenquanlytt,
-- date(a.thang) as thang,
-- Case 
--      when a.tenquanlyvung ='Nguyễn Thọ Chiến' then 'HCP'
--      when a.tenquanlyvung ='Nguyễn Hoàng Viển' then 'TP'
     
-- else a.makenhkh end as makenhkh,
-- round(safe_divide( sum(doanhsochuavat),sum(kh_total) )*100,1) as th_kpi,
sum(doanhsochuavat) as doanhsochuavat,
-- sum(kh_total) as kh_total,
sum(Case when masanpham in ('T302203003','T302204004','T302105002','T3044004','T303102009') then doanhsochuavat else 0 end) as ds_sp_moi, --,'T302202003','T302202004','T302202005'

  from `staging_temp.f_sales_crs_lhq_bytime`  a
  LEFT JOIN `staging.d_users_bytime` b on left(a.manv,6) = b.manv and a.thang = b.thang 
  where 
  a.ngaychungtu >='2024-07-01'
  and a.ngaychungtu <'2025-01-01'
  and crs_tuyenbanhang_trongmcp not in ('Rural')
  and a.tenquanlyvung ='Nguyễn Hoàng Viển'
  group by all
)

select 
Case when a.manv ='MR1168'  then 'MR1168_KN' 
     when a.manv = 'MR3057'  then 'MR3057_KN'
     when a.manv = 'MR0849'  then 'MR0849_KN'
     when a.manv = 'MR0738'  then 'MR0738_KN'
     when a.manv = 'MR0319'  then 'MR0319_KN'
     when a.manv = 'MR1035'  then 'MR1035_KN'
     when a.manv = 'MR2146'  then 'MR2146_KN'
else a.manv end as manv,
Case when a.manv ='MR1168'  then 'Trần Thị Bích Tiền(KN)'
     when a.manv = 'MR0849'  then 'Nguyễn Anh Dũng(KN)'
     when a.manv = 'MR0738'  then 'Lê Duy Chung(KN)'
     when a.manv = 'MR0319'  then 'Lê Đức Châu(KN)'
     when a.manv = 'MR1035'  then 'Nguyễn Thanh Tài(KN)'
     when a.manv = 'MR2146'  then 'Lương Đức Tiến(KN)'
else a.tencvbh end as tencvbh,
a.*except(manv,tencvbh) ,
ifnull(d.ty_le_sku_tb_1kh,0) + ifnull(d1.ty_le_sku_tb_1kh,0) as th_ka_rb,
Case when a.manv like '%KN%' then 'CRS' else ifnull(g.chucdanhengtitlesum,g1.chucdanhengtitlesum) end as chucdanh,
coalesce(g.diabanlamviec,g1.diabanlamviec) as diabanphutrach,

from data_sales a
LEFT JOIN sku_bq d on d.manv = a.manv and d.maphanhanghco ='KA'
LEFT JOIN sku_bq d1 on d1.manv = a.manv and d1.maphanhanghco ='RB'
-- LEFT JOIN `staging.d_manual_chi_tieu_ct_dai_bang_2024` c on c.codecrs = a.manv and stt is not null
LEFT JOIN `staging.d_hr_dsns` g on g.msnvcsmmoi = a.manv
LEFT JOIN `staging.d_hr_dsns_nghi_viec` g1 on g1.msnvcsmmoi = a.manv;