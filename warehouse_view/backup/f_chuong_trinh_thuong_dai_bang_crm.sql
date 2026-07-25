CREATE VIEW `spatial-vision-343005.warehouse.f_chuong_trinh_thuong_dai_bang_crm`
AS with 

chi_tieu_dai_bang as 

(
SELECT left(codecrs,6) as codecrs,chucdanh,diabanphutrach,
sum(nhomdaibang) -sum(xp) as nhomdaibang,
avg(ka) as ka,
avg(rb) as rb 
FROM `spatial-vision-343005.staging.d_manual_chi_tieu_ct_dai_bang_2024` where stt is null
group by all
),

sku_bq as 
(
--      with 
-- data_sales as
-- (
-- select
-- Case when a.manv in ('MR3060','MR1773','MR2012','MR1008','MR1361','MR1612','MR3163','MR1573','MR3078') then 'MR1035_KN' else a.crm end as manv,
-- a.masanpham, makhdms , IFNULL(b.classid,'O') as maphanhanghco, sum(soluong) as soluong

-- from `staging_temp.f_sales_crs_lhq_bytime`  a
-- INNER JOIN `staging.d_master_khachhang` b on a.makhdms = b.custid
-- where 
-- date(ngaychungtu)>= '2024-01-01' and b.channel ='TP'  and IFNULL(b.classid,'O') in ('KA','RB')
-- and date(ngaychungtu) < '2025-01-01'
-- group by all
-- having soluong > 0
-- )
-- select manv,maphanhanghco,count(masanpham) as sl_masp,count(distinct makhdms) as sl_makhdms, 
-- round(safe_divide(count(masanpham) , count(distinct makhdms)),1) as ty_le_sku_tb_1kh, 
--  from data_sales
--  group by all
select crm as manv,maphanhanghco,sum(count_kh_sp) as sl_masp,count(distinct makhdms) as sl_makhdms, 
round(safe_divide(sum(count_kh_sp) , count(distinct makhdms)),1) as ty_le_sku_tb_1kh, 
 from `warehouse.f_phanhang_theo_sku`
  where maphanhanghco is not null
 group by all
)
,

bog_quy3 as 
(
SELECT 
Case when slsperid in ('MR3060','MR1773','MR2012','MR1008','MR1361','MR1612','MR3163','MR1573','MR3078') then 'MR1035_KN' else supid end as supid,
round(count(distinct (CASE WHEN xet_dat_quy = 'Đạt' then custid ELSE NULL END)) / count(distinct custid) *100,1) as ty_le_dung_gia_bog
  FROM `spatial-vision-343005.warehouse.Theo_doi_gia_ban_le_TP_Quy3` group by 1
)
,
data_sales_by_thang as 
( 
select 
-- Case when a.manv in ('MR3060','MR1773','MR2012','MR1008','MR1361','MR1612','MR3163','MR1573','MR3078') then 'MR1035_KN' else a.crm end as ma_crm,
-- Case when a.manv in ('MR3060','MR1773','MR2012','MR1008','MR1361','MR1612','MR3163','MR1573','MR3078') then 'Nguyễn Thanh Tài (KN)' else b.tencvbh end as tenquanlytt,
crm as ma_crm,
b.tencvbh as tenquanlytt,
date(a.thang) as thang,
cast(extract(month from a.thang) as string) as thang_number,
Case 

     when a.tenquanlyvung ='Nguyễn Thọ Chiến' then 'HCP'
     when a.tenquanlyvung ='Nguyễn Hoàng Viển' then 'TP'
     
else a.makenhkh end as makenhkh,
round(safe_divide( sum(doanhsochuavat),sum(kh_total) )*100,1) as th_kpi,
sum(doanhsochuavat) as doanhsochuavat,
sum(kh_total) as kh_total,
sum(Case when masanpham in ('T302203003','T302204004','T302105002','T3044004','T303102009') then doanhsochuavat else 0 end) as ds_sp_moi, --,'T302202003','T302202004','T302202005'

  from `staging_temp.f_sales_crs_lhq_bytime`  a
  LEFT JOIN `staging.d_users_bytime` b on a.crm = b.manv and a.thang = b.thang 
  -- LEFT JOIN data_kenh_phutrach_bh c on a.manv =c.manv and date(a.thang) =c.thang
  where 
  a.ngaychungtu >='2024-07-01'
  and a.ngaychungtu <'2025-01-01'
  and crs_tuyenbanhang_trongmcp not in ('Rural')
  and b.position in ('AM','SS')
  and a.tenquanlyvung ='Nguyễn Hoàng Viển'
  group by all
  order by 3
)
,

group_data_sales as 
(
select ma_crm,string_agg(thang_number,',') as thang_k_dat from data_sales_by_thang 
where th_kpi < 90 and thang >'2024-07-01'
group by 1
)
,
data_sales as 

(
select 
ma_crm,
tenquanlytt,
round(safe_divide( sum(doanhsochuavat),sum(kh_total) )*100,1) as th_kpi,
sum(doanhsochuavat) as doanhsochuavat,
sum(kh_total) as kh_total,
sum(ds_sp_moi) as ds_sp_moi
from data_sales_by_thang 
group by all
)
,
mapping_all as (
select 
'x' as manv,
'x' as tencvbh,
a.ma_crm,
a.tenquanlytt,
c.chucdanh,
c.diabanphutrach,
a.th_kpi,
a.doanhsochuavat,
a.kh_total,
a.ds_sp_moi,
ifnull(c.nhomdaibang,0) * 1000 as kh_sp_moi,
round(safe_divide(a.ds_sp_moi,ifnull(c.nhomdaibang,0) * 1000)*100,1) as th_kpi_sp_moi,
d.sl_masp as ka_sl_masp,
d.sl_makhdms as ka_sl_makhdms,
d.ty_le_sku_tb_1kh as ka_ty_le_sku_tb_1kh,
c.ka as kh_ka,
d1.sl_masp as rb_sl_masp,
d1.sl_makhdms as rb_sl_makhdms,
d1.ty_le_sku_tb_1kh as rb_ty_le_sku_tb_1kh,
c.rb as kh_rb,
round(safe_divide(ifnull(d.ty_le_sku_tb_1kh,0) + ifnull(d1.ty_le_sku_tb_1kh,0),ifnull(c.ka,0) + ifnull(c.rb,0)) *100,1) as th_kpi_sku_bq,
ifnull(f.ty_le_dung_gia_bog,0) as ty_le_dung_gia_bog,
Case when ifnull(f.ty_le_dung_gia_bog,0) >= 80 then 'Đạt' else 'Không đạt' end as kq_dung_gia_bog,
ifnull(g.th_kpi,0) as th_kpi_t8,
ifnull(g1.th_kpi,0) as th_kpi_t9,
ifnull(g2.th_kpi,0) as th_kpi_t10,
ifnull(g3.th_kpi,0) as th_kpi_t11,
ifnull(g4.th_kpi,0) as th_kpi_t12,
e.thang_k_dat,

from data_sales a 
LEFT JOIN chi_tieu_dai_bang c on c.codecrs = a.ma_crm
LEFT JOIN sku_bq d on d.manv = a.ma_crm and d.maphanhanghco ='KA'
LEFT JOIN sku_bq d1 on d1.manv = a.ma_crm and d1.maphanhanghco ='RB'
LEFT JOIN bog_quy3 f on f.supid =a.ma_crm
LEFT JOIN group_data_sales e on e.ma_crm = a.ma_crm 
LEFT JOIN data_sales_by_thang g on g.ma_crm =a.ma_crm and g.thang = '2024-08-01'
LEFT JOIN data_sales_by_thang g1 on g1.ma_crm =a.ma_crm and g1.thang = '2024-09-01'
LEFT JOIN data_sales_by_thang g2 on g2.ma_crm =a.ma_crm and g2.thang = '2024-10-01'
LEFT JOIN data_sales_by_thang g3 on g3.ma_crm =a.ma_crm and g3.thang = '2024-11-01'
LEFT JOIN data_sales_by_thang g4 on g4.ma_crm =a.ma_crm and g4.thang = '2024-12-01'
)
,
phanloai_diem as (
select *,
Case when th_kpi >= 115 then 5
     when th_kpi < 115 and th_kpi >= 110 then 4
     when th_kpi < 110 and th_kpi >= 100 then 3
     when th_kpi < 100 and th_kpi >= 90 then 2
else 1 end as a_tieuchi,

Case when th_kpi_sp_moi >= 115 then 5
     when th_kpi_sp_moi < 115 and th_kpi_sp_moi >= 110 then 4
     when th_kpi_sp_moi < 110 and th_kpi_sp_moi >= 100 then 3
     when th_kpi_sp_moi < 100 and th_kpi_sp_moi >= 90 then 2
else 1 end as k_tieuchi,

Case when th_kpi_sku_bq >= 110 then 5
     when th_kpi_sku_bq < 110 and th_kpi_sku_bq >= 105 then 4
     when th_kpi_sku_bq < 105 and th_kpi_sku_bq >= 100 then 3
     when th_kpi_sku_bq < 100 and th_kpi_sku_bq >= 90 then 2
else 1 end as s_tieuchi

 from mapping_all
)
,
tinh_diem as (
select a.*,
round(a_tieuchi * 0.7 + k_tieuchi * 0.2 + s_tieuchi * 0.1,1) as diem_danhgia,
Case 
     -- when thang_k_dat is not null then 'Không xét thưởng do: Không đạt DS tháng ' || thang_k_dat
     -- when ty_le_dung_gia_bog < 80 then 'Không xét thưởng do: Không đạt Chấm BOG Q3'
     when round(a_tieuchi * 0.7 + k_tieuchi * 0.2 + s_tieuchi * 0.1,1) < 3 then 'Không xét thưởng do: Do điểm đánh giá chung cuộc <3'
else null end as ghi_chu
from phanloai_diem a 
)
,
xep_hang_all as (
select 
*,
Case when ghi_chu is null then rank() over (order by diem_danhgia desc,round(th_kpi,0) desc) 
else 0 end as xep_hang,

 from tinh_diem
 order by diem_danhgia desc,th_kpi desc
)

select 
*,
Case when xep_hang < 3  and xep_hang >0 then '1 chuyến du lịch trị giá 20 triệu'
else null end as thuong_du_lich,
Case when xep_hang < 3  and xep_hang >0 then 3000000
else null end as thuong_tien,
from xep_hang_all 

;