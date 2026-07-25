CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_trungbay_ebysta()
BEGIN 
  TRUNCATE TABLE staging_temp.f_trungbay_ebysta_temp;

 --INSERT INTO staging_temp.f_trungbay_ebysta_temp(

Create or replace table staging_temp.f_trungbay_ebysta_temp
as
with 
-- mst_base as (
-- SELECT
--     makhdms,
--     COUNT(DISTINCT invoicecustid) AS so_mst_khac_nhau,
--   FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy`
--   WHERE DATE(ngaychungtu) >= '2025-01-01'
--   GROUP BY ALL
-- )
thong_tin_ky_hop_dong as (
SELECT
distinct ma_khach_hang,
trang_thai_ky,
internal_promo_code
FROm `spatial-vision-343005.warehouse.view_data_contract_sign_by_users`
where
internal_promo_code ='2604-CTTB-26MTP2022-NT-QT'
and trang_thai_ky = 'Đã ký'
)
, thu_hoi_chung_tu_ben_ngoai AS (
	SELECT  
	DISTINCT
	ma_kh
	FROM `spatial-vision-343005.staging.theo_doi_thu_hoi_chung_tu_ky_ben_ngoai_ebysta_2026`
	Where ngay_thu_hoi is not null
)

, data_sales as (
select 
makhdms, 
date(thang) as thang,
sum(doanhsocovat) as doanhsocovat,
sum(soluong) as soluong
from `warehouse.f_raw_data_sales_yoy` where makenhkh <>'OTH_LAB' and masanpham ='EH115'
 and ngaychungtu >='2026-04-01' 
 and ngaychungtu <= '2026-12-26' --<'2026-01-01'
group by 1,2
having doanhsocovat <> 0 
),

trungbay_decal as
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
mucdangky,
somattrungbay,
if(somattrungbay=4,15,if(somattrungbay=8,30,0)) as muc_dk_sl,
-- replace(regexp_extract(mucdangky,r'(\(\w+)'),'(','') as nhantrungbay
'EBYSTA' as nhantrungbay
	FROM
		`spatial-vision-343005.staging.d_tdisplay`
	where
		machuongtrinh = '2604-CTTB-26MTP2022-NT-QT'
		and lower(trangthaiduyettrungbay) = 'đã duyệt'
),


mapping_sales as (

select 
makhuvuc as stt,
e.col.ma_nvbh as macrs,
makhachhang as makh, 
a.tenkhachhang,
thanhphotinh as tinhtp,
diachikhachhang as diachitheodms,
CASE WHEN somattrungbay = 4 THEN 'Mức 1' 
		WHEN somattrungbay = 8 THEN 'Mức 2'
		else null end as loaimuc,
muc_dk_sl,
-- b1.thang,
sum(ifnull(b1.soluong,0)) as soluong,
sum(ifnull(b1.doanhsocovat,0)) as doanhsocovat,
-- sum(Case when extract(month from b1.thang) = 1 then ifnull(soluong,0) else 0 end) as soluong_t1,
-- sum(Case when extract(month from b1.thang) = 2 then ifnull(soluong,0) else 0 end) as soluong_t2,
-- sum(Case when extract(month from b1.thang) = 3 then ifnull(soluong,0) else 0 end) as soluong_t3,
sum(Case when extract(month from b1.thang) = 4 then ifnull(soluong,0) else 0 end) as soluong_t4,
sum(Case when extract(month from b1.thang) = 5 then ifnull(soluong,0) else 0 end) as soluong_t5,
sum(Case when extract(month from b1.thang) = 6 then ifnull(soluong,0) else 0 end) as soluong_t6,
sum(Case when extract(month from b1.thang) = 7 then ifnull(soluong,0) else 0 end) as soluong_t7,
sum(Case when extract(month from b1.thang) = 8 then ifnull(soluong,0) else 0 end) as soluong_t8,
sum(Case when extract(month from b1.thang) = 9 then ifnull(soluong,0) else 0 end) as soluong_t9,
sum(Case when extract(month from b1.thang) = 10 then ifnull(soluong,0) else 0 end) as soluong_t10,
sum(Case when extract(month from b1.thang) = 11 then ifnull(soluong,0) else 0 end) as soluong_t11,
sum(Case when extract(month from b1.thang) = 12 then ifnull(soluong,0) else 0 end) as soluong_t12,

 from trungbay_decal a
LEFT JOIN data_sales b1 on trim(upper(a.makhachhang)) = trim(upper(b1.makhdms))
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` e on e.custid = a.makhachhang
group by all
),


result_0 as (
select a.*except(macrs),
ifnull(upper(trim(a.macrs)),trim(b2.manv)) as ma_crs,
b2.tencvbh as crs,
--soluong_t1 + soluong_t2 + soluong_t3 as soluong_quy1,
soluong_t4 + soluong_t5 + soluong_t6 as soluong_quy2,
soluong_t7 + soluong_t8 + soluong_t9 as soluong_quy3,
soluong_t10 + soluong_t11 + soluong_t12 as soluong_quy4,

--if( muc_dk_sl - (soluong_t1 + soluong_t2 + soluong_t3) <=0,0,muc_dk_sl - (soluong_t1 + soluong_t2 + soluong_t3) ) as sl_conthieu_q1,
if(muc_dk_sl - (soluong_t4 + soluong_t5 + soluong_t6) <= 0,0,muc_dk_sl - (soluong_t4 + soluong_t5 + soluong_t6) ) as sl_conthieu_q2,
if(muc_dk_sl - (soluong_t7 + soluong_t8 + soluong_t9) <= 0,0,muc_dk_sl - (soluong_t7 + soluong_t8 + soluong_t9) ) as sl_conthieu_q3,
if(muc_dk_sl - (soluong_t10 + soluong_t11 + soluong_t12) <= 0,0,muc_dk_sl - (soluong_t10 + soluong_t11 + soluong_t12) ) as sl_conthieu_q4,

--if(muc_dk_sl <= soluong_t1 + soluong_t2 + soluong_t3,'Đạt','Không đạt' ) as xet_sl_q1,
if(muc_dk_sl <= soluong_t4 + soluong_t5 + soluong_t6,'Đạt','Không đạt' ) as xet_sl_q2,
if(muc_dk_sl <= soluong_t7 + soluong_t8 + soluong_t9,'Đạt','Không đạt' ) as xet_sl_q3,
if(muc_dk_sl <= soluong_t10 + soluong_t11 + soluong_t12,'Đạt','Không đạt' ) as xet_sl_q4,
h.ma_cre,
h.ho_ten_cre,
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
CASE 
	WHEN f.ma_kh IS NOT NULL then 'Đã ký'
	ELSE IFNULL(e.trang_thai_ky, 'Chưa ký')
	END as thu_hoi_ttmb, 
--if(g.so_mst_khac_nhau > 1, 'Gộp MST', '') as gop_mst,
(select max(updated_at) from warehouse.f_raw_data_sales_yoy where ngaychungtu >='2026-04-01' and ngaychungtu <='2026-12-26') as inserted_at,
Null as kq_anh_q2,
Null as kq_anh_q3,
Null as kq_anh_q4

 from mapping_sales a
LEFT JOIN `staging.d_users` b2 on a.macrs = b2.manv
LEFT JOIN `staging.d_master_khachhang` c on c.custid = a.makh
LEFT JOIN thong_tin_ky_hop_dong e ON e.ma_khach_hang = a.makh
--LEFT JOIN mst_base g on g.makhdms = a.makh
LEFT JOIN `spatial-vision-343005.staging.d_calendar_cre` h ON a.macrs = h.ma_crs AND date(h.thang) = DATE_TRUNC(DATE(CURRENT_DATE()),MONTH)
LEFT JOIN thu_hoi_chung_tu_ben_ngoai f ON f.ma_kh = a.makh

)
select * from result_0 

--  )
	;
Create or replace table `warehouse.f_trungbay_ebysta`

copy `staging_temp.f_trungbay_ebysta_temp`;

End;