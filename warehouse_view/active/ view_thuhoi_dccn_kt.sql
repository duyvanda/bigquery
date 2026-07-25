CREATE VIEW `spatial-vision-343005.warehouse. view_thuhoi_dccn_kt`
AS with 

data_kt_gui as
(
  SELECT 
    a.*except(khuvuc,ngaythuhoi,thangthuhoi,namthuhoi,tinhkpipbh,sobill,nguoithuhoi,thongbaonoquahan,thunhacno,canhbaono,khoikien,ghichu,phutrachlienhe,ngaygoi,sotiendccn,tinh,tenkh,kenhphu,tenkhthue),

    b.custname as tenkh,
    b.custnameinvoice as tenkhthue,
    b.shoptype as kenhphu,
    b.statedescr as tinh,
    b.shortterritorydescr as khuvuc,
    b.channel,
    case when b.territorydescr in ('Mê Kông 1','Mê Kông 2','Miền Đông 2','Bắc Trung Bộ') then 'MR2931'
         when b.territorydescr in ('Hồ Chí Minh 1','Hồ Chí Minh 2','Miền Đông 1','Nam Trung Bộ') then 'MR2917'
         when b.territorydescr in ('Đông Bắc 1','Đông Bắc 2','Đông Nam 1','Đông Nam 2','Hà Nội 1','Hà Nội 2','Tây Bắc HN') then 'MR2280'
         else null end as ma_nguoiphutrach, 

    case when b.territorydescr in ('Mê Kông 1','Mê Kông 2','Miền Đông 2','Bắc Trung Bộ') then 'Ánh Hồng'
         when b.territorydescr in ('Hồ Chí Minh 1','Hồ Chí Minh 2','Miền Đông 1','Nam Trung Bộ') then 'Ngọc Nhi'
         when b.territorydescr in ('Đông Bắc 1','Đông Bắc 2','Đông Nam 1','Đông Nam 2','Hà Nội 1','Hà Nội 2','Tây Bắc HN') then 'Phạm Nga'
         else null end as nguoiphutrach, 

    cast(a.ngaygoi as string) as ngaygoi,
    cast(a.ngaythuhoi as string) as ngaythuhoi,
    cast(a.thangthuhoi as float64) as thangthuhoi,
    cast(a.namthuhoi as float64) as namthuhoi,
    a.tinhkpipbh,
    a.sobill,
    Case when a.nguoithuhoi is null and b.territorydescr in ('Mê Kông 1','Mê Kông 2','Miền Đông 2','Bắc Trung Bộ') then 'Ánh Hồng'
         when a.nguoithuhoi is null and b.territorydescr in ('Hồ Chí Minh 1','Hồ Chí Minh 2','Miền Đông 1','Nam Trung Bộ') then 'Ngọc Nhi'
         when a.nguoithuhoi is null and b.territorydescr in ('Đông Bắc 1','Đông Bắc 2','Đông Nam 1','Đông Nam 2','Hà Nội 1','Hà Nội 2','Tây Bắc HN') then 'Phạm Nga'
         else a.nguoithuhoi end as nguoithuhoi,
    a.thongbaonoquahan,
    a.thunhacno,
    a.canhbaono,
    a.khoikien,
    a.ghichu,
    cast(a.sotiendccn as float64) as sotien_dccn,

  FROM `spatial-vision-343005.staging.d_doi_chieu_cong_no_v2` a
  left join `spatial-vision-343005.staging.d_master_khachhang` b on a.makhcu = b.custid
  -- left join (select distinct custidinvoice, custnameinvoice from `spatial-vision-343005.staging.d_master_khachhang`) c on a.makhcu = b.custid
  -- left join `spatial-vision-343005.staging.d_kt_thuhoi_dccn` c on concat(a.makhcu,a.dccndenthang,b.channel,a.phaply,a.makhthue,a.tenkhthue) 
  --                                                               = concat(c.makh,c.dccndenthang,c.kenh,c.phaply,c.makhthue,c.tenkhthue) 
)
-- ,
-- max_thuhoi_dccn as 

-- (
--   select namdccn,thangdccn from `spatial-vision-343005.staging.d_doi_chieu_cong_no` 
--   qualify row_number() over (order by namdccn desc,thangdccn desc) = 1
-- )
,
thongtin_nguoinhan as (
select c.makh,c.phaply,c.makhthue,nguoinhan
from `spatial-vision-343005.staging.d_kt_thuhoi_dccn` c
where nguoinhan is not null
qualify row_number() over(partition by c.makh,c.phaply,c.makhthue order by namdccn desc,thangdccn desc,nguoinhan desc) = 1
)
,
thongtin_cv as (
select c.makh,c.phaply,c.makhthue,cv
from `spatial-vision-343005.staging.d_kt_thuhoi_dccn` c
where cv is not null
qualify row_number() over(partition by c.makh,c.phaply,c.makhthue order by namdccn desc,thangdccn desc,cv desc) = 1
)
,
thongtin_sdt as (
select c.makh,c.phaply,c.makhthue,sdt
from `spatial-vision-343005.staging.d_kt_thuhoi_dccn` c
where sdt is not null
qualify row_number() over(partition by c.makh,c.phaply,c.makhthue order by namdccn desc,thangdccn desc,sdt desc) = 1
)

, data_gui_thu_khach_hang_kt_ma_noi as(
SELECT
  ma_csm, 
  ma_ge,
  nguoi_nhan,
  sdt
FROM `spatial-vision-343005.staging.d_data_gui_thu_khach_hang_kt`
QUALIFY ROW_NUMBER() OVER(PARTITION BY ma_csm, ma_ge ORDER BY RAND()) = 1
)

, data_gui_thu_khach_hang_kt_ma_nb as(
SELECT
  ma_csm,
  nguoi_nhan,
  sdt
FROM `spatial-vision-343005.staging.d_data_gui_thu_khach_hang_kt`
QUALIFY ROW_NUMBER() OVER(PARTITION BY ma_csm ORDER BY RAND()) = 1
)
,noi_thang_nam_dccn_thu_hoi as (
select 
makhcu,
makhthue,
phaply,
STRING_AGG(CASE WHEN namdccn = 2023 THEN dccndenthang END, '-' ORDER BY thangdccn) AS nam_2023,
STRING_AGG(CASE WHEN namdccn = 2024 THEN dccndenthang END, '-' ORDER BY thangdccn) AS nam_2024,
STRING_AGG(CASE WHEN namdccn = 2025 THEN dccndenthang END, '-' ORDER BY thangdccn) AS nam_2025
from 
  (SELECT DISTINCT 
        a.makhcu, 
        a.makhthue,
        a.phaply,
        a.namdccn,
        a.thangdccn,
        a.dccndenthang
    FROM data_kt_gui a
    left join `spatial-vision-343005.staging.d_kt_thuhoi_dccn` c on concat(a.makhcu,a.dccndenthang,a.phaply,a.makhthue) 
                                                              = concat(c.makh,c.dccndenthang,c.phaply,c.makhthue) 
    WHERE ifnull(cast(a.ngaythuhoi as string),nullif(c.ngaythuhoi,'-')) IS NOT NULL
    ORDER BY a.namdccn ASC, a.thangdccn ASC)
group by 1,2,3

)

select 
  a.*except(ngaythuhoi,thangthuhoi,namthuhoi,tinhkpipbh,sobill,nguoithuhoi,thongbaonoquahan,thunhacno,canhbaono,khoikien,ghichu,ngaygoi,hinhthucgoi,nguoinhan,cv,sodienthoai
),
  ifnull(cast(date(a.ngaygoi) as string),nullif(c.ngaygui,'-')) as ngaygoi,
  ifnull(cast(a.ngaythuhoi as string),nullif(c.ngaythuhoi,'-')) as ngaythuhoi,
  ifnull(a.thangthuhoi,cast(nullif(c.thangthuhoi,'-') as float64)) as thangthuhoi,
  ifnull(a.namthuhoi,cast(nullif(c.namthuhoi,'-') as float64)) as namthuhoi,
  ifnull(a.tinhkpipbh,c.tinhkpipbh) as tinhkpipbh,
  ifnull(a.sobill,c.sobill) as sobill,
  ifnull(a.nguoithuhoi,c.nguoithuhoi) as nguoithuhoi,
  ifnull(c.hinhthucgui,a.hinhthucgoi) as hinhthucgoi,
  coalesce(e.nguoi_nhan,g.nguoi_nhan,c.nguoinhan,a.nguoinhan,b.nguoinhan) as nguoinhan,
  coalesce(c.cv,a.cv,b1.cv) as cv,
  coalesce(e.sdt,g.sdt,c.sdt,a.sodienthoai,b2.sdt) as sodienthoai,

  ifnull(c.thongbaonoquahan,a.thongbaonoquahan) as thongbaonoquahan,
  ifnull(c.thunhacno,a.thunhacno) as thunhacno,
  ifnull(c.canhbaono,a.canhbaono) as canhbaono,
  ifnull(c.khoikien,a.khoikien) as khoikien,
  ifnull(c.ghichu,a.ghichu) as ghichu,
  d.nam_2023 as thang_thcn_2023,
  d.nam_2024 as thang_thcn_2024,
  d.nam_2025 as thang_thcn_2025
from data_kt_gui a 
left join `spatial-vision-343005.staging.d_kt_thuhoi_dccn` c on concat(a.makhcu,a.dccndenthang,a.phaply,a.makhthue) 
                                                              = concat(c.makh,c.dccndenthang,c.phaply,c.makhthue) 
left join thongtin_nguoinhan b on  concat(a.makhcu,a.phaply,a.makhthue) 
                                   = concat(b.makh,b.phaply,b.makhthue) 
left join thongtin_cv b1 on  concat(a.makhcu,a.phaply,a.makhthue) 
                                   = concat(b1.makh,b1.phaply,b1.makhthue)                                   
left join thongtin_sdt b2 on  concat(a.makhcu,a.phaply,a.makhthue) 
                                   = concat(b2.makh,b2.phaply,b2.makhthue)
left join noi_thang_nam_dccn_thu_hoi d on d.makhcu = a.makhcu and  d.makhthue = a.makhthue and d.phaply = a.phaply
left join data_gui_thu_khach_hang_kt_ma_noi e on e.ma_csm = a.makhcu AND e.ma_ge = a.makhthue
left join data_gui_thu_khach_hang_kt_ma_nb g on g.ma_csm = a.makhcu

qualify row_number() over (partition by a.makhcu,a.dccndenthang,a.phaply,a.makhthue order by 

ifnull(cast(a.ngaythuhoi as string),nullif(c.ngaythuhoi,'-')) desc,
ifnull(a.thangthuhoi,cast(nullif(c.thangthuhoi,'-') as float64)) desc,
ifnull(a.namthuhoi,cast(nullif(c.namthuhoi,'-') as float64)) desc,
ifnull(c.thongbaonoquahan,a.thongbaonoquahan) desc,
ifnull(c.thunhacno,a.thunhacno) desc,
ifnull(c.canhbaono,a.canhbaono) desc,
ifnull(c.khoikien,a.khoikien) desc,
ifnull(c.ghichu,a.ghichu) desc
)
= 1;