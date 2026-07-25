CREATE VIEW `spatial-vision-343005.warehouse.f_chuong_trinh_thuong_dai_bang_crs`
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

danhgia_quy_crs as 

(
select manv,xeploai_abc,diem_xeploai_quy,quy,nam,quy_filter from `warehouse.f_tinhthuong_danhgia_quy_all` where quy_filter >='2024-07-01' and nam = 2024 and makenhkh ='TP' and chuc_vu ='CRS/CRSS'
)
,

bog_quy3 as 
(
SELECT slsperid,
round(count(distinct (CASE WHEN xet_dat_quy = 'Đạt' then custid ELSE NULL END)) / count(distinct custid) *100,1) as ty_le_dung_gia_bog
  FROM `spatial-vision-343005.warehouse.Theo_doi_gia_ban_le_TP_Quy3` group by 1
)
,
data_sales as 
( 
select 
left(a.manv,6) as manv,
b.tencvbh,
Case 

     when a.tenquanlyvung ='Nguyễn Thọ Chiến' then 'HCP'
     when a.tenquanlyvung ='Nguyễn Hoàng Viển' then 'TP'
     
else a.makenhkh end as makenhkh,
count(distinct a.thang ) as so_thang_tinh_luong,
round(safe_divide( sum(doanhsochuavat),sum(kh_total) )*100,1) as th_kpi,
sum(doanhsochuavat) as doanhsochuavat,
sum(kh_total) as kh_total,
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
,
mapping_all as (
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
a.makenhkh,
Case when c.crm = 'Nguyễn Thanh Tài KN' then 'MR1035' else b.supid end as ma_crm,
Case when c.crm = 'Nguyễn Thanh Tài KN' then 'Nguyễn Thanh Tài' else b.tenquanlytt end as tenquanlytt,
Case when b.tenquanlytt in ('Lê Duy Chung','Lương Đức Tiến','Huỳnh Văn Huy') then 'Khu vực 2' else 'Khu vực 1' end as phan_cum,
Case when a.manv like '%KN%' then 'CRS' else ifnull(g.chucdanhengtitlesum,g1.chucdanhengtitlesum) end as chucdanh,
coalesce(g.diabanlamviec,g1.diabanlamviec) as diabanphutrach,
a.th_kpi,
a.doanhsochuavat,
a.kh_total,
a.ds_sp_moi,
(ifnull(c.nhomdaibang,0) - ifnull(c.xp,0) ) * 1000 as kh_sp_moi,
round(safe_divide(a.ds_sp_moi,(ifnull(c.nhomdaibang,0) - ifnull(c.xp,0) ) * 1000)*100,1) as th_kpi_sp_moi,
d.sl_masp as ka_sl_masp,
d.sl_makhdms as ka_sl_makhdms,
d.ty_le_sku_tb_1kh as ka_ty_le_sku_tb_1kh,
c.ka as kh_ka,
d1.sl_masp as rb_sl_masp,
d1.sl_makhdms as rb_sl_makhdms,
d1.ty_le_sku_tb_1kh as rb_ty_le_sku_tb_1kh,
c.rb as kh_rb,
round(safe_divide(ifnull(d.ty_le_sku_tb_1kh,0) + ifnull(d1.ty_le_sku_tb_1kh,0),ifnull(c.ka,0) + ifnull(c.rb,0)) *100,1) as th_kpi_sku_bq,
e.xeploai_abc as xeploai_abc_quy3,
e1.xeploai_abc as xeploai_abc_quy4,
ifnull(f.ty_le_dung_gia_bog,0) as ty_le_dung_gia_bog,
Case when ifnull(f.ty_le_dung_gia_bog,0) >= 80 then 'Đạt' else 'Không đạt' end as kq_dung_gia_bog,
so_thang_tinh_luong,
ifnull(cast(g.ngaykyhdldchinhthuc as timestamp),cast(g1.ngaykyhdldchinhthuc as timestamp)) as ngaykyhdldchinhthuc,
cast(g1.ngaynghiviecdieuchuyen as timestamp) as ngaynghiviecdieuchuyen,
from data_sales a 
LEFT JOIN `staging.d_users` b on a.manv =b.manv
LEFT JOIN `staging.d_manual_chi_tieu_ct_dai_bang_2024` c on c.codecrs = a.manv and stt is not null
LEFT JOIN sku_bq d on d.manv = a.manv and d.maphanhanghco ='KA'
LEFT JOIN sku_bq d1 on d1.manv = a.manv and d1.maphanhanghco ='RB'
LEFT JOIN danhgia_quy_crs e on e.manv = a.manv and e.quy = 3 
LEFT JOIN danhgia_quy_crs e1 on e1.manv = a.manv and e1.quy = 4
LEFT JOIN bog_quy3 f on f.slsperid =a.manv
LEFT JOIN `staging.d_hr_dsns` g on g.msnvcsmmoi = a.manv
LEFT JOIN `staging.d_hr_dsns_nghi_viec` g1 on g1.msnvcsmmoi = a.manv


)
,
phanloai_diem as (
select *,
Case when th_kpi >= 120 then 5
     when th_kpi < 120 and th_kpi >= 110 then 4
     when th_kpi < 110 and th_kpi >= 100 then 3
     when th_kpi < 100 and th_kpi >= 90 then 2
else 1 end as a_tieuchi,

Case when th_kpi_sp_moi >= 120 then 5
     when th_kpi_sp_moi < 120 and th_kpi_sp_moi >= 110 then 4
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
     when a.so_thang_tinh_luong < 6 then 'Không xét thưởng do: Do không đủ 6 tháng làm việc'
     when a.ngaykyhdldchinhthuc > '2024-07-05' then 'Không xét thưởng do: Do không đủ 6 tháng làm việc'
     when a.ngaynghiviecdieuchuyen <'2024-12-31' then 'Không xét thưởng do: Do không đủ 6 tháng làm việc'
     when round(a_tieuchi * 0.7 + k_tieuchi * 0.2 + s_tieuchi * 0.1,1) < 3 then 'Không xét thưởng do: Do điểm đánh giá chung cuộc <3'
else null end as ghi_chu
from phanloai_diem a 
),
xep_hang_all as (
select 
*,
Case when ghi_chu is null then rank() over (partition by phan_cum,ghi_chu is null order by diem_danhgia desc,round(th_kpi,1) desc) 
else 0 end as xep_hang,
(select max(updated_at) from `staging_temp.f_sales_crs_lhq_bytime` where ngaychungtu >='2024-07-01') as inserted_at

 from tinh_diem
 order by phan_cum,diem_danhgia desc,th_kpi desc
)

select a.*,
Case when xep_hang < 7 and xep_hang >0 and phan_cum ='Khu vực 1' then '1 chuyến du lịch trị giá 20 triệu'
     when xep_hang < 5 and xep_hang >0 and phan_cum ='Khu vực 2' then '1 chuyến du lịch trị giá 20 triệu'
else null end as thuong_du_lich,
Case when xep_hang < 7 and xep_hang >0 and phan_cum ='Khu vực 1' then 3000000
     when xep_hang < 5 and xep_hang >0 and phan_cum ='Khu vực 2' then 3000000
else null end as thuong_tien,

 from xep_hang_all a;