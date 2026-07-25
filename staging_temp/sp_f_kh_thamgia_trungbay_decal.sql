CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_kh_thamgia_trungbay_decal()
BEGIN 
  TRUNCATE TABLE staging_temp.f_kh_thamgia_trungbay_decal_temp;

 --INSERT INTO staging_temp.f_kh_thamgia_trungbay_decal_temp(

Create or replace table staging_temp.f_kh_thamgia_trungbay_decal_temp
as 

with 

-- thu_hoi_hd as 

-- (
--    SELECT ma_kh,thu_hoi_tttb,ghi_chu,
--     thu_hoi_phu_luc_thay_doi_thong_tin_thoa_thuan_3_ben_bien_ban_thanh_ly_hop_dong
--     FROM `spatial-vision-343005.staging.d_manual_gs_dskh_tham_gia_decal_2025` 
-- qualify row_number() over (partition by ma_kh order by thu_hoi_tttb desc) = 1
-- )
mst_base as (
SELECT
    makhdms,
    COUNT(DISTINCT invoicecustid) AS so_mst_khac_nhau,
  FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy`
  WHERE DATE(ngaychungtu) >= '2026-01-01'
  GROUP BY ALL
)
, data_sales as (
select makhdms, date(thang) as thang,
sum(Case when masanpham in ('OH051','OH050','OH049','OH052','T302201014','T302201018','T302203002','T302201017') then doanhsochuavat else 0 end) as ds_xixat,
sum(doanhsochuavat) as tong_ds_chuavat
from `warehouse.f_raw_data_sales_yoy` where makenhkh <>'OTH_LAB'
 and ngaychungtu >='2026-01-01'
 and ngaychungtu <= '2026-12-26'
 
group by 1,2
),

trungbay_decal as
(
SELECT
e.col.ma_nvbh as manhanvienphutrach,
tennhanvienphutrach,
thoigiantbtu,
thoigiantbden,
makhachhang,
tenkhachhang,
thanhphotinh,
phanloaihco,
mucdangky,
0 as phitrathuongthang,
-- replace(regexp_extract(mucdangky,r'(\(\w+)'),'(','') as nhantrungbay
'XISAT' as nhantrungbay,
500000 as muc_dk_ds
	FROM
		`spatial-vision-343005.staging.d_tdisplay` a
    LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` e on e.custid = a.makhachhang    
	where
		machuongtrinh = '2601-CTTB-CPA10-NT-QT'
		and lower(trangthaiduyettrungbay) = 'đã duyệt'
),
mapping_sales as  (
SELECT 
a.*except(manhanvienphutrach,tennhanvienphutrach),

a.manhanvienphutrach as manv,
c.tencvbh as tennhanvienphutrach,
c.supid as ma_crm,
c.tenquanlytt,
c.rsmid as ma_ncxm,
c.tenquanlyvung,
d.branchid,
d.branchname,
d.channel,
d.statedescr,
d.shoptype,
d.shortterritorydescr,
if(date(d.legaldate) >= current_date("+7"),'Còn hiệu lực','Hết hiệu lực') as hieu_luc_gdp,
d.stocksales as tinh_trang_ma_so_thue, 
d.businessscope as pham_vi_kinh_doanh,
(select max(updated_at) from warehouse.f_raw_data_sales_yoy where ngaychungtu >='2026-01-01' and ngaychungtu <= '2026-12-26' ) as inserted_at,

sum(ifnull(ds_xixat,0)) as ds_nhantrungbay,

sum(ifnull(tong_ds_chuavat,0)) as tong_ds_chuavat,

SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 1 THEN IFNULL(ds_xixat, 0) ELSE 0 END) AS ds_nhantrungbay_t1,
SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 2 THEN IFNULL(ds_xixat, 0) ELSE 0 END) AS ds_nhantrungbay_t2,
SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 3 THEN IFNULL(ds_xixat, 0) ELSE 0 END) AS ds_nhantrungbay_t3,
SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 4 THEN IFNULL(ds_xixat, 0) ELSE 0 END) AS ds_nhantrungbay_t4,
SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 5 THEN IFNULL(ds_xixat, 0) ELSE 0 END) AS ds_nhantrungbay_t5,
SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 6 THEN IFNULL(ds_xixat, 0) ELSE 0 END) AS ds_nhantrungbay_t6,
SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 7 THEN IFNULL(ds_xixat, 0) ELSE 0 END) AS ds_nhantrungbay_t7,
SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 8 THEN IFNULL(ds_xixat, 0) ELSE 0 END) AS ds_nhantrungbay_t8,
SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 9 THEN IFNULL(ds_xixat, 0) ELSE 0 END) AS ds_nhantrungbay_t9,
SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 10 THEN IFNULL(ds_xixat, 0) ELSE 0 END) AS ds_nhantrungbay_t10,
SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 11 THEN IFNULL(ds_xixat, 0) ELSE 0 END) AS ds_nhantrungbay_t11,
SUM(CASE WHEN EXTRACT(MONTH FROM thang) = 12 THEN IFNULL(ds_xixat, 0) ELSE 0 END) AS ds_nhantrungbay_t12


 FROM trungbay_decal a
LEFT JOIN data_sales b on a.makhachhang = b.makhdms
LEFT JOIN `staging.d_users` c on a.manhanvienphutrach =c.manv
LEFT JOIN `staging.d_master_khachhang` d on d.custid =a.makhachhang
group by all
)
,latest_visits as (
SELECT 
    custid,
    criteriaid,
    result,
    EXTRACT(QUARTER FROM visitdate) as quy
  FROM `spatial-vision-343005.staging.d_display_criteria_remark`
  WHERE displayid = '2601-CTTB-CPA10-NT-QT'
    AND EXTRACT(YEAR FROM visitdate) = 2026
  -- Lọc ngày mới nhất dựa trên quý vừa tính
  QUALIFY visitdate = MAX(visitdate) OVER(PARTITION BY custid, EXTRACT(QUARTER FROM visitdate))
)
,quarter_status AS (
SELECT 
  custid AS ma_kh,
  CASE 
    WHEN COUNTIF(quy = 1 AND criteriaid = '1' AND result = 'Đạt') > 0 
     AND COUNTIF(quy = 1 AND criteriaid = '2' AND result = 'Đạt') > 0 
    THEN 'Đạt'
    ELSE 'Không Đạt' 
  END AS kq_anh_q1,
  CASE 
    WHEN COUNTIF(quy = 2 AND criteriaid = '1' AND result = 'Đạt') > 0 
     AND COUNTIF(quy = 2 AND criteriaid = '2' AND result = 'Đạt') > 0 
    THEN 'Đạt'
    ELSE 'Không Đạt' 
  END AS kq_anh_q2,
  CASE 
    WHEN COUNTIF(quy = 3 AND criteriaid = '1' AND result = 'Đạt') > 0 
     AND COUNTIF(quy = 3 AND criteriaid = '2' AND result = 'Đạt') > 0 
    THEN 'Đạt'
    ELSE 'Không Đạt' 
  END AS kq_anh_q3,
  CASE 
    WHEN COUNTIF(quy = 4 AND criteriaid = '1' AND result = 'Đạt') > 0 
     AND COUNTIF(quy = 4 AND criteriaid = '2' AND result = 'Đạt') > 0 
    THEN 'Đạt'
    ELSE 'Không Đạt' 
  END AS kq_anh_q4

FROM latest_visits
GROUP BY custid
)

, thong_tin_ky_hop_dong as (
SELECT
distinct ma_khach_hang,
trang_thai_ky,
internal_promo_code
FROm `spatial-vision-343005.warehouse.view_data_contract_sign_by_users`
where
internal_promo_code ='2601-CTTB-CPA10-NT-QT'
and trang_thai_ky = 'Đã ký'
)


select a.*,
h.ma_cre,
h.ho_ten_cre,

IFNULL(qs.kq_anh_q1, 'Không Đạt') AS kq_anh_q1,
IFNULL(qs.kq_anh_q2, 'Không Đạt') AS kq_anh_q2,
IFNULL(qs.kq_anh_q3, 'Không Đạt') AS kq_anh_q3,
IFNULL(qs.kq_anh_q4, 'Không Đạt') AS kq_anh_q4,
 (ds_nhantrungbay_t1 + ds_nhantrungbay_t2 + ds_nhantrungbay_t3)  as ds_q1,
 (ds_nhantrungbay_t4 + ds_nhantrungbay_t5 + ds_nhantrungbay_t6)  as ds_q2,
 (ds_nhantrungbay_t7 + ds_nhantrungbay_t8 + ds_nhantrungbay_t9)  as ds_q3,
(ds_nhantrungbay_t10 + ds_nhantrungbay_t11 + ds_nhantrungbay_t12)  as ds_q4,

if(muc_dk_ds - (ds_nhantrungbay_t1 + ds_nhantrungbay_t2 + ds_nhantrungbay_t3) <=0,0,muc_dk_ds - (ds_nhantrungbay_t1 + ds_nhantrungbay_t2 + ds_nhantrungbay_t3) ) as sl_conthieu_q1,
if(muc_dk_ds - (ds_nhantrungbay_t4 + ds_nhantrungbay_t5 + ds_nhantrungbay_t6) <=0,0,muc_dk_ds - (ds_nhantrungbay_t4 + ds_nhantrungbay_t5 + ds_nhantrungbay_t6) ) as sl_conthieu_q2,
if(muc_dk_ds - (ds_nhantrungbay_t7 + ds_nhantrungbay_t8 + ds_nhantrungbay_t9) <=0,0,muc_dk_ds - (ds_nhantrungbay_t7 + ds_nhantrungbay_t8 + ds_nhantrungbay_t9) ) as sl_conthieu_q3,
if(muc_dk_ds - (ds_nhantrungbay_t10 + ds_nhantrungbay_t11 + ds_nhantrungbay_t12) <=0,0,muc_dk_ds - (ds_nhantrungbay_t10 + ds_nhantrungbay_t11 + ds_nhantrungbay_t12) ) as sl_conthieu_q4,

if(muc_dk_ds <= ds_nhantrungbay_t1 + ds_nhantrungbay_t2 + ds_nhantrungbay_t3,'Đạt','Không đạt' ) as xet_sl_q1,
if(muc_dk_ds <= ds_nhantrungbay_t4 + ds_nhantrungbay_t5 + ds_nhantrungbay_t6,'Đạt','Không đạt' ) as xet_sl_q2,
if(muc_dk_ds <= ds_nhantrungbay_t7 + ds_nhantrungbay_t8 + ds_nhantrungbay_t9,'Đạt','Không đạt' ) as xet_sl_q3,
if(muc_dk_ds <= ds_nhantrungbay_t10 + ds_nhantrungbay_t11 + ds_nhantrungbay_t12,'Đạt','Không đạt' ) as xet_sl_q4,

Case when b.ngay_thu_hoi is not null then 'Đã thu' 
When e.ma_khach_hang is not null then  'Đã thu'
else 'Chưa thu' end as thu_hoi_ttmb,

if(g.so_mst_khac_nhau > 1, 'Gộp MST', '') as gop_mst
 from mapping_sales a 
 LEFT JOIN `spatial-vision-343005.staging.theo_doi_thu_hoi_chung_tu_ky_ben_ngoai_decal_xisat_2026` b on a.makhachhang =b.ma_kh
 LEFT JOIN mst_base g on g.makhdms = a.makhachhang
 LEFT JOIN `spatial-vision-343005.staging.d_calendar_cre` h ON a.manv = h.ma_crs AND date(h.thang) = DATE_TRUNC(DATE(CURRENT_DATE()),MONTH)
 LEFT JOIN quarter_status qs ON a.makhachhang = qs.ma_kh
 LEFT JOIN thong_tin_ky_hop_dong e ON e.ma_khach_hang = a.makhachhang
  ;

Create or replace table `warehouse.f_kh_thamgia_trungbay_decal`

copy `staging_temp.f_kh_thamgia_trungbay_decal_temp`;

End;