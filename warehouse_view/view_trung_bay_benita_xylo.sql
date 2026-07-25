CREATE VIEW `spatial-vision-343005.warehouse.view_trung_bay_benita_xylo`
AS WITH mst_base as (
SELECT
    makhdms,
    COUNT(DISTINCT invoicecustid) AS so_mst_khac_nhau,
  FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy`
  WHERE DATE(ngaychungtu) >= '2025-01-01'
  GROUP BY ALL
)
,
data_sales as (
select 
makhdms, 
date(thang) as thang,
CAST (sum(doanhsocovat) AS INT64) as doanhsocovat,
sum(CASE WHEN masanpham = 'T303102009' THEN soluong ELSE 0 END) as soluong -- sl của Benita Xylo
from `warehouse.f_raw_data_sales_yoy` where makenhkh <>'OTH_LAB' and masanpham in ('T303102009','T303102005','EH086','EH087','EH108','T303102010','T303102011','T303102006')
and ngaychungtu >='2025-04-02' 
and ngaychungtu <='2025-12-26'
group by 1,2
having doanhsocovat <> 0
),

trungbay_benita_xylo as
(
SELECT
makhuvuc,
diachikhachhang,
manhanvienphutrach,
tennhanvienphutrach,
thoigiantbtu,
thoigiantbden,
makhachhang,
tenkhachhang,
thanhphotinh,
phanloaihco,
ngaydangky,
CASE
  WHEN ngaydangky <=  '2025-05-31' THEN '2025-04-01'
  WHEN ngaydangky >=  '2025-06-01' THEN '2025-07-01'
  ELSE NULL END AS ngay_ky_hd,
mucdangky,
somattrungbay,
if(somattrungbay=4,30,0) as muc_dk_sl --if(somattrungbay=8,30,0)
FROM
`spatial-vision-343005.staging.d_tdisplay`
where
machuongtrinh = '2504-CTTB-CPA28-NT-QT'
and lower(trangthaiduyettrungbay) = 'đã duyệt'
qualify row_number() over (partition by makhachhang order by ngaydangky desc) = 1
)

,dskh_thu_hoi_pl AS (
SELECT
ma_khach_hang,
thu_hoi_phu_luc_hop_dong,
thu_hoi_tttb,
thu_hoi_phu_luc_thay_doi_thong_tin_thoa_thuan_3_ben_bien_ban_thanh_ly_hop_dong
FROM `spatial-vision-343005.staging.d_manual_gs_dskh_tham_gia_khung_benita_2025`
qualify row_number() over (partition by ma_khach_hang order by thu_hoi_tttb desc) = 1
)


,mapping_sales as (

select 
makhuvuc as stt,
e.col.ma_nvbh as macrs,
makhachhang as makh, 
tenkhachhang as tennhathuoctenhco,
thanhphotinh as tinhtp,
diachikhachhang as diachitheodms,
somattrungbay as loaimuc,
tennhanvienphutrach as crs,
a.ngay_ky_hd,
muc_dk_sl,
-- b1.thang,
sum(ifnull(b1.soluong,0)) as soluong,-- chỉ là số lượng của sp Benita Xylo
sum(ifnull(b1.doanhsocovat,0)) as doanhsocovat,
sum(Case when extract(month from thang) = 4 then ifnull(soluong,0) else 0 end) as soluong_t4,
sum(Case when extract(month from thang) = 5 then ifnull(soluong,0) else 0 end) as soluong_t5,
sum(Case when extract(month from thang) = 6 then ifnull(soluong,0) else 0 end) as soluong_t6,
sum(Case when extract(month from thang) = 7 then ifnull(soluong,0) else 0 end) as soluong_t7,
sum(Case when extract(month from thang) = 8 then ifnull(soluong,0) else 0 end) as soluong_t8,
sum(Case when extract(month from thang) = 9 then ifnull(soluong,0) else 0 end) as soluong_t9,
sum(Case when extract(month from thang) = 10 then ifnull(soluong,0) else 0 end) as soluong_t10,
sum(Case when extract(month from thang) = 11 then ifnull(soluong,0) else 0 end) as soluong_t11,
sum(Case when extract(month from thang) = 12 then ifnull(soluong,0) else 0 end) as soluong_t12,
-- Doanh số
sum(Case when extract(month from thang) = 7 then ifnull(b1.doanhsocovat,0) else 0 end) as doanhsocovat_t7,
sum(Case when extract(month from thang) = 8 then ifnull(b1.doanhsocovat,0) else 0 end) as doanhsocovat_t8,
sum(Case when extract(month from thang) = 9 then ifnull(b1.doanhsocovat,0) else 0 end) as doanhsocovat_t9,
sum(Case when extract(month from thang) = 10 then ifnull(b1.doanhsocovat,0) else 0 end) as doanhsocovat_t10,
sum(Case when extract(month from thang) = 11 then ifnull(b1.doanhsocovat,0) else 0 end) as doanhsocovat_t11,
sum(Case when extract(month from thang) = 12 then ifnull(b1.doanhsocovat,0) else 0 end) as doanhsocovat_t12

FROM trungbay_benita_xylo a
LEFT JOIN data_sales b1 on trim(upper(a.makhachhang)) = trim(upper(b1.makhdms))
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` e on e.custid = a.makhachhang
group by all
)


select a.*except(macrs,crs),
ifnull(upper(trim(a.macrs)),trim(b2.manv)) as macrs,-- a.macrs
b2.tencvbh as crs,

-- soluong_t1 + soluong_t2 + soluong_t3 as soluong_quy1_2024,
soluong_t4 + soluong_t5 + soluong_t6 as soluong_quy2_2025,
soluong_t7 + soluong_t8 + soluong_t9 as soluong_quy3_2025,
soluong_t10 + soluong_t11 + soluong_t12 as soluong_quy4_2025,
doanhsocovat_t7 + doanhsocovat_t8 + doanhsocovat_t9 as ds_quy3_2025,
doanhsocovat_t10 + doanhsocovat_t11 + doanhsocovat_t12 as ds_quy4_2025,

-- if( muc_dk_sl - (soluong_t1 + soluong_t2 + soluong_t3) <=0,0,muc_dk_sl - (soluong_t1 + soluong_t2 + soluong_t3) ) as sl_conthieu_q1,
if(muc_dk_sl - (soluong_t4 + soluong_t5 + soluong_t6) <= 0,0,muc_dk_sl - (soluong_t4 + soluong_t5 + soluong_t6) ) as sl_conthieu_q2,
-- if(muc_dk_sl - (soluong_t7 + soluong_t8 + soluong_t9) <= 0,0,muc_dk_sl - (soluong_t7 + soluong_t8 + soluong_t9) ) as sl_conthieu_q3,
CASE
  WHEN a.ngay_ky_hd < '2025-07-01' 
    AND pl.thu_hoi_phu_luc_hop_dong IS NULL 
    AND muc_dk_sl - (soluong_t7 + soluong_t8 + soluong_t9) > 0
  THEN muc_dk_sl - (soluong_t7 + soluong_t8 + soluong_t9)
  WHEN 15 - (soluong_t7 + soluong_t8 + soluong_t9) > 0
  THEN 15 - (soluong_t7 + soluong_t8 + soluong_t9)
  ELSE 0 END AS sl_conthieu_q3,

CASE
  WHEN a.ngay_ky_hd >= '2025-07-01' 
    AND 870000 - (doanhsocovat_t7 + doanhsocovat_t8 + doanhsocovat_t9) > 0
  THEN 870000 - (doanhsocovat_t7 + doanhsocovat_t8 + doanhsocovat_t9)
  WHEN a.ngay_ky_hd < '2025-07-01' 
    AND pl.thu_hoi_phu_luc_hop_dong IS NOT NULL 
    AND 870000 - (doanhsocovat_t7 + doanhsocovat_t8 + doanhsocovat_t9) > 0
  THEN 870000 - (doanhsocovat_t7 + doanhsocovat_t8 + doanhsocovat_t9)
  ELSE 0 END AS ds_conthieu_q3,

-- if(muc_dk_sl - (soluong_t10 + soluong_t11 + soluong_t12) <= 0,0,muc_dk_sl - (soluong_t10 + soluong_t11 + soluong_t12) ) as sl_conthieu_q4,
CASE
  WHEN a.ngay_ky_hd < '2025-07-01' 
    AND pl.thu_hoi_phu_luc_hop_dong IS NULL 
    AND muc_dk_sl - (soluong_t10 + soluong_t11 + soluong_t12) > 0
  THEN muc_dk_sl - (soluong_t10 + soluong_t11 + soluong_t12)
  WHEN 15 - (soluong_t10 + soluong_t11 + soluong_t12) > 0
  THEN 15 - (soluong_t10 + soluong_t11 + soluong_t12)
  ELSE 0 END AS sl_conthieu_q4,

CASE
  WHEN a.ngay_ky_hd >= '2025-07-01' 
    AND 870000 - (doanhsocovat_t10 + doanhsocovat_t11 + doanhsocovat_t12) > 0
  THEN 870000 - (doanhsocovat_t10 + doanhsocovat_t11 + doanhsocovat_t12)
  WHEN a.ngay_ky_hd < '2025-07-01' 
    AND pl.thu_hoi_phu_luc_hop_dong IS NOT NULL 
    AND 870000 - (doanhsocovat_t10 + doanhsocovat_t11 + doanhsocovat_t12) > 0
  THEN 870000 - (doanhsocovat_t10 + doanhsocovat_t11 + doanhsocovat_t12)
  ELSE 0 END AS ds_conthieu_q4,

-- if(muc_dk_sl <= soluong_t1 + soluong_t2 + soluong_t3,'Đạt','Không đạt' ) as xet_sl_q1,
if(muc_dk_sl <= soluong_t4 + soluong_t5 + soluong_t6,'Đạt','Không đạt' ) as xet_sl_q2,
--if(muc_dk_sl <= soluong_t7 + soluong_t8 + soluong_t9,'Đạt','Không đạt' ) as xet_sl_q3,
CASE
  -- NHÓM 1: KH tham gia từ 1/4 và KHÔNG ký phụ lục (Xét theo đk1)
  WHEN a.ngay_ky_hd < '2025-07-01' AND pl.thu_hoi_phu_luc_hop_dong IS NULL THEN 
      IF(soluong_t7 + soluong_t8 + soluong_t9 >= muc_dk_sl, 'Đạt', 'Không đạt')

  -- NHÓM 2: KH tham gia từ 1/7 HOẶC (tham gia 1/4 nhưng CÓ ký phụ lục) (Xét theo đk2)
  -- Lưu ý: Nhóm này phải thỏa mãn CẢ số lượng và doanh số
  WHEN (soluong_t7 + soluong_t8 + soluong_t9 >= 15) 
       AND (doanhsocovat_t7 + doanhsocovat_t8 + doanhsocovat_t9 >= 870000) THEN 'Đạt'

  -- CÁC TRƯỜNG HỢP CÒN LẠI (Không đủ định mức của Nhóm 2)
  ELSE 'Không đạt' 
END AS xet_sl_q3,
--if(muc_dk_sl <= soluong_t10 + soluong_t11 + soluong_t12,'Đạt','Không đạt' ) as xet_sl_q4,
CASE
  -- NHÓM 1: KH tham gia từ 1/4 và KHÔNG ký phụ lục (Xét theo đk1)
  WHEN a.ngay_ky_hd < '2025-07-01' AND pl.thu_hoi_phu_luc_hop_dong IS NULL THEN 
      IF(soluong_t10 + soluong_t11 + soluong_t12 >= muc_dk_sl, 'Đạt', 'Không đạt')

  -- NHÓM 2: KH tham gia từ 1/7 HOẶC (tham gia 1/4 nhưng CÓ ký phụ lục) (Xét theo đk2)
  WHEN (soluong_t10 + soluong_t11 + soluong_t12 >= 15) 
       AND (doanhsocovat_t10 + doanhsocovat_t11 + doanhsocovat_t12 >= 870000) THEN 'Đạt'

  ELSE 'Không đạt' 
END AS xet_sl_q4,
h.ma_cre,
h.ho_ten_cre,
b2.manv as macrm,
b2.supid as ma_crm,
b2.asm as ma_scrm,
LEFT(b2.rsmid,6) as ma_ncxm,
b2.tenquanlytt,
b2.tenquanlykhuvuc,
b2.tenquanlyvung,
c.channel,
c.shoptype,
c.branchid,
c.branchname,
c.shortterritorydescr,
if(date(c.legaldate) >= current_date("+7"),'Còn hiệu lực','Hết hiệu lực') as hieu_luc_gdp,
c.stocksales as tinh_trang_ma_so_thue, 
c.businessscope as pham_vi_kinh_doanh,
c.territorydescr,
pl.thu_hoi_tttb as thu_hoi_ttmb,
pl.thu_hoi_phu_luc_hop_dong,
if(g.so_mst_khac_nhau > 1, 'Gộp MST', '') as gop_mst,
pl.thu_hoi_phu_luc_thay_doi_thong_tin_thoa_thuan_3_ben_bien_ban_thanh_ly_hop_dong,
(select max(updated_at) from warehouse.f_raw_data_sales_yoy where ngaychungtu >='2025-01-01') as inserted_at

from mapping_sales a
LEFT JOIN `staging.d_users` b2 on a.macrs = b2.manv
LEFT JOIN `staging.d_master_khachhang` c on c.custid = a.makh
LEFT JOIN mst_base g on g.makhdms = a.makh
LEFT JOIN dskh_thu_hoi_pl pl ON pl.ma_khach_hang = a.makh
LEFT JOIN `spatial-vision-343005.staging.d_calendar_cre` h ON upper(trim(a.macrs)) = h.ma_crs AND date(h.thang) = DATE_TRUNC(DATE(CURRENT_DATE()),MONTH)
--where a.makh = '014994'
GROUP BY ALL
;