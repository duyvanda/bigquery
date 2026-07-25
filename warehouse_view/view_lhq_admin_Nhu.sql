CREATE VIEW `spatial-vision-343005.warehouse.view_lhq_admin_Nhu`
AS with 
nhanvien_byhr as (
  select 
  a.msnvcsmmoi as manv, 
  a.thang,
  a.hovatenfullname as tencvbh,
  a.supervisor as tenquanlytt,
  a.loaihdld,
  a.phaply,
  a.chucdanhengtitlesum as role_luong_mds_phanloai,


  from `staging.d_hr_dsns_bytime` a 
  where msnvcsmmoi  IN ('MR2662','MR3056', 'MR2514') and date(thang) >= '2024-02-01'
)

, admin_phu_trach as (
    SELECT
    b.*,
    Case 
    
    /*03/03/2026 e ơi, em kiểm tra chỗ BBGH của đơn DL7-0126-03788-00021238 (SDS phụ trách) có đang bị tính vô phần thu hồi của bạn MR3056-Quách Ngọc Hải không nhé*/
    when ma_dh in ('DL7-0126-03788') then null
    
    when b.tentinhkh in
    ('Thành phố Hà Nội','Hà Tây','Lào Cai','Lai Châu','Vĩnh Phúc','Bắc Kạn','Điện Biên',
    'Thái Nguyên','Phú Thọ','Hòa Bình','Yên Bái','Cao Bằng','Sơn La','Tuyên Quang',
    'Hà Giang','Hải Phòng','Hưng Yên','Quảng Ninh','Hải Dương','Bắc Ninh','Bắc Giang',
    'Lạng Sơn','Thái Bình','Ninh Bình','Nam Định','Hà Nam','Hà Tĩnh','Nghệ An','Thanh Hóa')
    then 'MR3056'

    when b.tentinhkh in ('Thành phố Hồ Chí Minh','Bà Rịa - Vũng Tàu','Bình Dương','Đồng Nai',
    'Lâm Đồng','Tây Ninh','Đắk Nông','Bình Phước','Tiền Giang','Long An','Trà Vinh','Bến Tre',
    'Vĩnh Long','Đồng Tháp','Kiên Giang','Cà Mau','Thành phố Cần Thơ','An Giang','Bạc Liêu',
    'Sóc Trăng','Hậu Giang')
    then 'MR2662' 
    
    when b.tentinhkh in ('Thành phố Đà Nẵng', 'Quảng Trị', 'Quảng Nam', 'Bình Định', 'Thừa Thiên - Huế', 
    'Thừa Thiên Huế', 'Quảng Ngãi', 'Quảng Bình', 'Gia Lai', 'Khánh Hòa', 'Bình Thuận', 'Ninh Thuận', 
    'Đắk Lắk', 'Kon Tum','Phú Yên')
    then 'MR2514' 
    else null 
    end as manv_admin

    FROM `warehouse.f_baocao_daily_performance_mds_new_v2` b
)

, nv_kpi_dong_hang as 
(
    SELECT 
    thang,
    manv_admin as manv,
    SUM(CASE WHEN donvigiaohang_fix IN ('Nhà vận chuyển', 'NVC') THEN dschuvat_giaohang ELSE 0 END) AS ds_dong_hang_nvc,
    SUM(CASE WHEN donvigiaohang_fix = 'Chành xe' AND tennhavanchuyen_fix != 'MERAPLION' THEN dschuvat_giaohang ELSE 0 END) AS ds_dong_hang_chanh,
  
    SUM(CASE WHEN donvigiaohang_fix IN ('Nhà vận chuyển', 'NVC') THEN dschuvat_giaohang ELSE 0 END) + 
    SUM(CASE WHEN donvigiaohang_fix = 'Chành xe' AND tennhavanchuyen_fix != 'MERAPLION' THEN dschuvat_giaohang ELSE 0 END) AS ds_dong_hang_total


  FROM `admin_phu_trach` c
  WHERE ma_donghang_tinhluong is not null
  GROUP BY 1,2
) ,


 nv_kpi_tha_hang_c1 as
(
  SELECT 
    thang,
    manv_admin as manv,
    sum(dschuvat_giaohang) as ds_donghang_di_tha,

  FROM `admin_phu_trach` c
  WHERE manv_thahang_tinhluong_c1 is not null
  GROUP BY 1,2
),


nv_kpi_bbgh as 
(
    SELECT
    TIMESTAMP(DATE_ADD(DATE(DATE_TRUNC(ngaychungtu, MONTH)), INTERVAL 1 MONTH))as thang,
    manv_admin as manv,
    count (distinct case when c.ma_noi_tinh_thu_hoi_bbgh is not null then ma_noi_tinh_thu_hoi_bbgh end) as sl_bb_can_thu_hoi,
    count (distinct case when c.ma_noi_tinh_thu_hoi_bbgh is not null and (da_thu_hoi_bbgh = 1) then ma_noi_tinh_thu_hoi_bbgh
    end) as sl_bb_da_thu_hoi,
    ROUND(SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN ma_noi_tinh_thu_hoi_bbgh IS NOT NULL AND (da_thu_hoi_bbgh = 1 OR so_du_chung_tu_het_no = 1) 
    THEN ma_noi_tinh_thu_hoi_bbgh END), COUNT(DISTINCT CASE WHEN ma_noi_tinh_thu_hoi_bbgh IS NOT NULL THEN ma_noi_tinh_thu_hoi_bbgh END)), 3) 
    AS  ty_le_thu_hoi_bbgh

  FROM `admin_phu_trach` c
  LEFT JOIN `spatial-vision-343005.staging.d_hr_dsns_bytime` h ON
  (
    CASE WHEN c.manv_phu_trach_thu_hoi_bbgh LIKE '%KN%' THEN REPLACE(manv_phu_trach_thu_hoi_bbgh, 'KN','') 
    ELSE c.manv_phu_trach_thu_hoi_bbgh END
  ) = h.msnvcsmmoi 
    AND c.thang = h.thang
    AND phongdeptsummary = 'MDS' AND hovatenfullname NOT IN ('Quách Ngọc Hải','Trần Thị Mỹ Uyên','Lương Trịnh Thắng')
  where c.manv_phu_trach_thu_hoi_bbgh LIKE '%MR%' and h.msnvcsmmoi is not null
  GROUP BY 1,2

)



----------------------TINH LHQ----------------------------

,tinh_luong as (
select 
  a.*,
  q.ds_dong_hang_total,
  q1.sl_bb_can_thu_hoi,
  q2.ds_donghang_di_tha,
  ty_le_thu_hoi_bbgh,
  ket_qua,

case 
  when (ds_dong_hang_total + ds_donghang_di_tha) < 10000000000 then (ds_dong_hang_total + ds_donghang_di_tha) * 0.02/100
  when (ds_dong_hang_total + ds_donghang_di_tha) >= 10000000000 and (ds_dong_hang_total + ds_donghang_di_tha) < 15000000000 then 2000000
  when (ds_dong_hang_total + ds_donghang_di_tha) >= 15000000000 and (ds_dong_hang_total + ds_donghang_di_tha) < 20000000000 then 2500000
  when (ds_dong_hang_total + ds_donghang_di_tha) >= 20000000000 and (ds_dong_hang_total + ds_donghang_di_tha) < 25000000000 then 3000000
  when (ds_dong_hang_total + ds_donghang_di_tha) >= 25000000000 then 3000000 + (ds_dong_hang_total + ds_donghang_di_tha - 25000000000) * 0.01/100
  else 0 
end as lhq_1,

 ------BBGH = 100
case 

when ty_le_thu_hoi_bbgh =1
  and sl_bb_can_thu_hoi < 300
  then ty_le_thu_hoi_bbgh * 1100000
  when ty_le_thu_hoi_bbgh =1
  and sl_bb_can_thu_hoi >= 300 
  and sl_bb_can_thu_hoi < 500
  then ty_le_thu_hoi_bbgh * 1500000
when
  ty_le_thu_hoi_bbgh =1
  and sl_bb_can_thu_hoi >= 500
  and sl_bb_can_thu_hoi < 700
  then ty_le_thu_hoi_bbgh * 1800000
when
  ty_le_thu_hoi_bbgh =1
  and sl_bb_can_thu_hoi >= 700
  then ty_le_thu_hoi_bbgh * 2000000

----BBGH 97-100
when
  ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1
  and sl_bb_can_thu_hoi < 300
  then ty_le_thu_hoi_bbgh * 700000
when
  ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1
  and sl_bb_can_thu_hoi >= 300
  and sl_bb_can_thu_hoi < 500
  then ty_le_thu_hoi_bbgh * 1000000
when
  ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1
  and sl_bb_can_thu_hoi >= 500
  and sl_bb_can_thu_hoi < 700
  then ty_le_thu_hoi_bbgh * 1300000
when
  ty_le_thu_hoi_bbgh >= 0.97 and ty_le_thu_hoi_bbgh < 1
  and sl_bb_can_thu_hoi >= 700
  then ty_le_thu_hoi_bbgh * 1500000

----BBGH < 97
when 
  ty_le_thu_hoi_bbgh < 0.97
  and sl_bb_can_thu_hoi < 300
  then ty_le_thu_hoi_bbgh * 500000
when 
  ty_le_thu_hoi_bbgh < 0.97
  and sl_bb_can_thu_hoi >= 300
  and sl_bb_can_thu_hoi < 500
  then ty_le_thu_hoi_bbgh * 700000
when 
  ty_le_thu_hoi_bbgh < 0.97
  and sl_bb_can_thu_hoi >= 500
  and sl_bb_can_thu_hoi < 700
  then ty_le_thu_hoi_bbgh * 900000
when  
  ty_le_thu_hoi_bbgh < 0.97
  and sl_bb_can_thu_hoi >= 700
  then ty_le_thu_hoi_bbgh * 1200000
else 0 end as lhq_2,

ket_qua * 4000000 as lhq_3,

0 as lhq_4


from nhanvien_byhr a
LEFT JOIN nv_kpi_dong_hang q on q.thang = a.thang and q.manv = a.manv
LEFT JOIN nv_kpi_bbgh q1 on q1.thang = a.thang and q1.manv = a.manv
LEFT JOIN nv_kpi_tha_hang_c1 q2 on q2.thang = a.thang and q2.manv = a.manv
LEFT JOIN `staging.d_kpi_mds` q3 on q3.manv = a.manv and q3.thang = a.thang 
)

select a.* except(lhq_1,lhq_2,lhq_3),
Case when trim(loaihdld) in ('Có xác định thời hạn','Không xác định thời hạn') then lhq_1 else 0 end as lhq_1,
Case when trim(loaihdld) in ('Có xác định thời hạn','Không xác định thời hạn') then lhq_2 else 0 end as lhq_2,
Case when trim(loaihdld) in ('Có xác định thời hạn','Không xác định thời hạn') then lhq_3 else 0 end as lhq_3,
(select max(inserted_at) 


from `warehouse.f_baocao_daily_performance_mds_new_v2` where ngaychungtu >='2024-01-01' ) as thoigian
from tinh_luong a
--where manv = 'MR2662' and thang = '2024-03-01';