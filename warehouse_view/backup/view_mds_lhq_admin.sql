CREATE VIEW `spatial-vision-343005.warehouse.view_mds_lhq_admin`
AS with nv_bytime as (
  select 
  msnvcsmmoi as manv, 
  thang,
  e.hovatenfullname,
  e.chucdanhengtitlesum,
  e.loaihdld,
  e.phaply,
  e.supervisor as quan_ly 
  from staging.d_hr_dsns_bytime e where msnvcsmmoi  in('MR2662','MR3056', 'MR2514') and date(thang) >= '2024-02-01'
)

, v2_add_them_admin_phu_trach as (
    SELECT
    a.*,
    Case when a.tentinhkh in
    ('Thành phố Hà Nội','Hà Tây','Lào Cai','Lai Châu','Vĩnh Phúc','Bắc Kạn','Điện Biên',
    'Thái Nguyên','Phú Thọ','Hòa Bình','Yên Bái','Cao Bằng','Sơn La','Tuyên Quang',
    'Hà Giang','Hải Phòng','Hưng Yên','Quảng Ninh','Hải Dương','Bắc Ninh','Bắc Giang',
    'Lạng Sơn','Thái Bình','Ninh Bình','Nam Định','Hà Nam','Hà Tĩnh','Nghệ An','Thanh Hóa')
    then 'MR3056'

    when a.tentinhkh in ('Thành phố Hồ Chí Minh','Bà Rịa - Vũng Tàu','Bình Dương','Đồng Nai',
    'Lâm Đồng','Tây Ninh','Đắk Nông','Bình Phước','Tiền Giang','Long An','Trà Vinh','Bến Tre',
    'Vĩnh Long','Đồng Tháp','Kiên Giang','Cà Mau','Thành phố Cần Thơ','An Giang','Bạc Liêu',
    'Sóc Trăng','Hậu Giang')
    then 'MR2662' 
    
    when a.tentinhkh in (
    'Thành phố Đà Nẵng',
    'Quảng Trị',
    'Quảng Nam',
    'Bình Định',
    'Thừa Thiên - Huế',
    'Thừa Thiên Huế',
    'Quảng Ngãi',
    'Quảng Bình',
    'Gia Lai',
    'Khánh Hòa',
    'Bình Thuận',
    'Ninh Thuận',
    'Đắk Lắk',
    'Kon Tum',
    'Phú Yên'
    )
    then 'MR2514' 
    else null end as manv_admin

    FROM `warehouse.f_baocao_daily_performance_mds_new_v2` a
    -- where date(ngaychungtu)>= '2025-03-01' and trangthaigiaohang = 'Đã giao hàng' and date(ngaygiaohang_fix)<=  '2025-04-30'
)

, nv_kpi_tha_hang_c1 as
(
  SELECT 
    thang,
    manv_admin as manv,
    sum(dschuvat_giaohang) as ds_donghang_di_tha,
  FROM v2_add_them_admin_phu_trach a
  WHERE manv_thahang_tinhluong_c1 is not null  and trangthaigiaohang = 'Đã giao hàng' and date(ngaygiaohang_fix)<=  '2025-04-30'
  GROUP BY 1,2
)
,

nv_kpi_dong_hang as 
(
    SELECT 
    thang,
    manv_admin as manv,
    sum(dschuvat_giaohang) as ds_dong_hang,
  FROM `v2_add_them_admin_phu_trach` a
  WHERE ma_donghang_tinhluong is not null and trangthaigiaohang = 'Đã giao hàng' and date(ngaygiaohang_fix)<=  '2025-04-30'
  GROUP BY 1,2
)
,
nv_kpi_bbgh as 
(
    SELECT 
    TIMESTAMP(DATE_ADD(DATE(DATE_TRUNC(ngaychungtu, MONTH)), INTERVAL 1 MONTH))as thang,
    manv_admin as manv,
    count (distinct a.ma_noi_tinh_thu_hoi_bbgh) as sl_bb_thu_hoi
  FROM v2_add_them_admin_phu_trach a
  where
  manv_phu_trach_thu_hoi_bbgh is not null 
  GROUP BY 1,2

)  


----------------------TINH LHQ----------------------------

,tinh_luong as (
select 
  a.*,
  c.ds_dong_hang,
  f.sl_bb_thu_hoi,
  g.ds_donghang_di_tha,
  1 as ty_le_thu_hoi_bb,
  d.ket_qua,
  Case 
    when c.ds_dong_hang + g.ds_donghang_di_tha < 10000000000 then (c.ds_dong_hang + g.ds_donghang_di_tha )* 0.027 / 100
    when c.ds_dong_hang + g.ds_donghang_di_tha >= 10000000000 and c.ds_dong_hang + g.ds_donghang_di_tha < 15000000000 then 3000000
    when c.ds_dong_hang + g.ds_donghang_di_tha >= 15000000000 and c.ds_dong_hang + g.ds_donghang_di_tha < 20000000000 then 3500000
    when c.ds_dong_hang + g.ds_donghang_di_tha >= 20000000000 and c.ds_dong_hang + g.ds_donghang_di_tha < 25000000000 then 4000000
    when c.ds_dong_hang + g.ds_donghang_di_tha >= 25000000000 then 4000000  + ( (c.ds_dong_hang + g.ds_donghang_di_tha - 25000000000)  * 0.01 / 100 )
  else 0 end as lhq_1,
  Case 
    when f.sl_bb_thu_hoi < 300 then 1100000
    when f.sl_bb_thu_hoi >= 300 and f.sl_bb_thu_hoi < 500 then 1500000
    when f.sl_bb_thu_hoi >= 500 and f.sl_bb_thu_hoi < 700 then 1800000
    when f.sl_bb_thu_hoi >= 700 then 2000000
  else 0 end as lhq_2,
  d.ket_qua * 4000000 as lhq_3,

from nv_bytime a
LEFT JOIN nv_kpi_dong_hang c on c.thang = a.thang and c.manv = a.manv
LEFT JOIN nv_kpi_bbgh f on f.thang = a.thang and f.manv = a.manv
LEFT JOIN nv_kpi_tha_hang_c1 g on g.thang = a.thang and g.manv = a.manv
LEFT JOIN staging.d_kpi_mds d on d.manv = a.manv and a.thang = d.thang
)

select a.*except(lhq_1,lhq_2,lhq_3,thang),
date(thang) as thang,
Case when trim(loaihdld) in ('Có xác định thời hạn','Không xác định thời hạn') then lhq_1 else 0 end as lhq_1,
Case when trim(loaihdld) in ('Có xác định thời hạn','Không xác định thời hạn') then lhq_2 else 0 end as lhq_2,
Case when trim(loaihdld) in ('Có xác định thời hạn','Không xác định thời hạn') then lhq_3 else 0 end as lhq_3,
(select max(inserted_at) from `warehouse.f_baocao_daily_performance_mds_new_v2` where ngaychungtu >='2024-01-01' ) as thoigian
from tinh_luong a;