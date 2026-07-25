CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_tonkho_phucvu_sanxuat_page_capture_t1()
BEGIN 

-- INSERT INTO `staging.f_check_table_dup_tonkho` 

-- select 'd_manual_danhsach_banggia_sanpham2023',current_datetime("+7"),count(1) from(
-- select masp,count(1) as dem from `spatial-vision-343005.staging.d_manual_danhsach_banggia_sanpham2023` group by 1 having dem >1)
-- UNION ALL

-- select 'd_nm_quycachdh',current_datetime("+7"),count(1) from (
-- select ma_san_pham_pha_nam,count(1) as dem from `spatial-vision-343005.staging.d_nm_quycachdh` group by 1 having dem >1)
-- UNION ALL

-- select 'd_nhom_sp_trading',current_datetime("+7"),count(1) from (
-- select masanpham,count(1) as dem from `spatial-vision-343005.staging.d_nhom_sp_trading` group by 1 having dem >1);

TRUNCATE TABLE staging_temp.f_baocao_tonkho_phucvu_sanxuat_page_capture_t1_temp;
INSERT INTO staging_temp.f_baocao_tonkho_phucvu_sanxuat_page_capture_t1_temp(
-- Create or replace table staging_temp.f_baocao_tonkho_phucvu_sanxuat_page_capture_t1_temp
-- as
with 
so_lo_nam as 

(
SELECT date_trunc(created_date,year) as nam, masanpham,so_lo_trong_nam FROM `spatial-vision-343005.staging.f_sc_daily_invt` 
qualify row_number() over (partition by masanpham,date_trunc(created_date,year) order by so_lo_trong_nam desc ) = 1
)

select t1.*,
t2.phannhomsp,
t4.dongiatruocvat as gia_kd,
t3.nhomcpa,t3.nhomcpa2,t3.brand2023,t4.dangbaoche,
t5.so_lo_trong_nam,
current_datetime("+7") as updated_at
from `staging.f_kehoachsx_capture_t3` t1
join `staging.d_nm_quycachdh` t2 on t1.masanpham = trim(t2.ma_san_pham_pha_nam)
left join `staging.d_nhom_sp_trading` t3 on t3.masanpham =t1.masanpham and t3.masanpham is not null --and t3.masanpham <> 'New'
LEFT JOIN `staging.d_manual_danhsach_banggia_sanpham2023` t4 on t4.masp = t1.masanpham
left join so_lo_nam t5 on t5.masanpham = t1.masanpham and date_trunc(t1.day,year) = date(t5.nam)

);

Create or replace table `warehouse.f_baocao_tonkho_phucvu_sanxuat_page_capture_t1`

copy `staging_temp.f_baocao_tonkho_phucvu_sanxuat_page_capture_t1_temp`;

End;