CREATE VIEW `spatial-vision-343005.warehouse.view_kha_nang_sanxuat`
AS with ton_kho_moi_nhat_theo_ngay as    
(
    select ma_vt, so_luong_vt, capture_date
    from `spatial-vision-343005.staging.f_ge_giao_dich_nvl_bao_bi`
    where trim(ma_kho) in (
    'A0101',
    'A0102',
    'A0201',
    'A0202',
    'A0204',
    'A0205',
    'A0301',
    'A0302',
    'A04',
    'A041',
    'A042',
    'A0401',
    'A0402'
    )
    --and lower(kho_hang) not like '%biệt trữ%'
    qualify dense_rank () over (order by capture_date desc ) = 1
--    where capture_date >= '2024-05-22'
),

tong_so_luong_vt as 
(
    select ma_vt,
    sum(so_luong_vt) as sl_vt
    from ton_kho_moi_nhat_theo_ngay
    group by 1
),


soluongcothesx as  
(select
ma_thanh_pham,
ten_sp as ten_thanh_pham,
dm1 as sltp_can_san_xuat,
mavt as ma_nvl,
tenvt as ten_nvl,
value as hamluongnvl,
dvt,
sl_vt,
loainvlbb,
daychuyensx,
ifnull(floor(safe_divide(s.sl_vt, value)) * dm1, 0) as sl_co_the_sx
from `spatial-vision-343005.staging.d_dm_nvl_bbi` c
left join tong_so_luong_vt s on trim(c.mavt) = trim(s.ma_vt)
where value is not null),


thanhphamnhonhat as
(select ten_thanh_pham,
MIN (sl_co_the_sx) AS sl_nhonhat_sx
from soluongcothesx
group by 1)

select
ma_thanh_pham,
r.ten_thanh_pham,
sltp_can_san_xuat,
ma_nvl,
ten_nvl,
hamluongnvl,
dvt,
sl_vt,
loainvlbb,
daychuyensx,
floor(sl_co_the_sx) as sl_co_the_sx,
case when floor(z.sl_nhonhat_sx) <= 0 then 0 else floor(z.sl_nhonhat_sx) end as sl_nhonhat_sx,
from soluongcothesx r
left join thanhphamnhonhat  z on r.ten_thanh_pham = z.ten_thanh_pham



;