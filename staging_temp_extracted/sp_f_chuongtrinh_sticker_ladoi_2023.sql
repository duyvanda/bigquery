-- ==========================================================================
-- Routine Name : sp_f_chuongtrinh_sticker_ladoi_2023
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2025-12-27 04:44:57.660000+00:00
-- Last Altered : 2025-12-27 04:44:57.660000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_chuongtrinh_sticker_ladoi_2023()
BEGIN
TRUNCATE TABLE staging_temp.f_chuongtrinh_sticker_ladoi_2023_temp;

--INSERT INTO staging_temp.f_chuongtrinh_sticker_ladoi_2023_temp(
Create or replace table staging_temp.f_chuongtrinh_sticker_ladoi_2023_temp as

WITH

thu_hoi_hd as

(
    SELECT ma_kh,thu_hoi_tttb,ghi_chu,
		thu_hoi_phu_luc_thay_doi_thong_tin_thoa_thuan_3_ben_bien_ban_thanh_ly_hop_dong
		FROM `spatial-vision-343005.staging.d_manual_gs_dskh_tham_gia_sticker_2025`
		qualify row_number() over (partition by ma_kh order by thu_hoi_tttb desc) = 1
)
, mst_base as (
SELECT
    makhdms,
    COUNT(DISTINCT invoicecustid) AS so_mst_khac_nhau,
  FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy`
  WHERE DATE(ngaychungtu) >= '2025-01-01'
  GROUP BY ALL
)
, data_sales as (
select
makhdms, date(thang) as thang,
sum(doanhsocovat) as doanhsocovat
from `warehouse.f_raw_data_sales_yoy`
where makenhkh <>'OTH_LAB'
  and ngaychungtu >='2025-01-01'
	and ngaychungtu <='2025-12-26' --<'2026-01-01'
  AND makhdms IS NOT NULL
  and masanpham in ('T302101005','T302101006','T302101007','T302101008')
group by 1,2
),
stiker_ladoi as
(
SELECT
manhanvienphutrach,
tennhanvienphutrach,
thoigiantbtu,
thoigiantbden,
makhachhang as ma_kh,
tenkhachhang,
thanhphotinh,
phanloaihco,
mucdangky as muc,
if(mucdangky like '%750k%',750000,if(mucdangky like '%1tr5%',1500000,0)) as muc_dk_ds
	FROM
		`spatial-vision-343005.staging.d_tdisplay`
	where
		machuongtrinh = '2501-CTTB-CPA10-NT-QT'
		and lower(trangthaiduyettrungbay) = 'đã duyệt'
)
,
mapping_sales as(
select
--a.*,
f.col.ma_nvbh as manhanvienphutrach,
a.tennhanvienphutrach,
a.thoigiantbtu,
a.thoigiantbden,
a.ma_kh,
a.tenkhachhang,
a.thanhphotinh,
a.phanloaihco,
a.muc,
a.muc_dk_ds,
(select max(updated_at) from warehouse.f_raw_data_sales_yoy where ngaychungtu >='2024-01-01') as inserted_at,
sum(Case when extract(month from thang) = 1 then ifnull(doanhsocovat,0) else 0 end) as doanhsocovat_t1,
sum(Case when extract(month from thang) = 2 then ifnull(doanhsocovat,0) else 0 end) as doanhsocovat_t2,
sum(Case when extract(month from thang) = 3 then ifnull(doanhsocovat,0) else 0 end) as doanhsocovat_t3,
sum(Case when extract(month from thang) = 4 then ifnull(doanhsocovat,0) else 0 end) as doanhsocovat_t4,
sum(Case when extract(month from thang) = 5 then ifnull(doanhsocovat,0) else 0 end) as doanhsocovat_t5,
sum(Case when extract(month from thang) = 6 then ifnull(doanhsocovat,0) else 0 end) as doanhsocovat_t6,
sum(Case when extract(month from thang) = 7 then ifnull(doanhsocovat,0) else 0 end) as doanhsocovat_t7,
sum(Case when extract(month from thang) = 8 then ifnull(doanhsocovat,0) else 0 end) as doanhsocovat_t8,
sum(Case when extract(month from thang) = 9 then ifnull(doanhsocovat,0) else 0 end) as doanhsocovat_t9,
sum(Case when extract(month from thang) = 10 then ifnull(doanhsocovat,0) else 0 end) as doanhsocovat_t10,
sum(Case when extract(month from thang) = 11 then ifnull(doanhsocovat,0) else 0 end) as doanhsocovat_t11,
sum(Case when extract(month from thang) = 12 then ifnull(doanhsocovat,0) else 0 end) as doanhsocovat_t12,
sum(ifnull(b.doanhsocovat,0)) as doanhsocovat
 from stiker_ladoi a
 LEFT JOIN data_sales b on a.ma_kh = b.makhdms
 LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` f on f.custid = a.ma_kh
 group by all
)

select a.*,
c.custname,
c.statedescr,
c.channel,
c.shoptype,
c.hcotypeid,
if(date(c.legaldate) >= current_date("+7"),'Còn hiệu lực','Hết hiệu lực') as hieu_luc_gdp,
c.stocksales as tinh_trang_ma_so_thue,
c.businessscope as pham_vi_kinh_doanh,
c.branchid,
c.branchname,
c.shortterritorydescr,
a.manhanvienphutrach AS ma_crs,
e.tencvbh,
h.ma_cre,
h.ho_ten_cre,
e.supid AS ma_crm,
e.tenquanlytt as tenquanlytt,
e.asm AS ma_scrm,
e.tenquanlykhuvuc,
e.rsmid AS ma_ncxm,
e.tenquanlyvung,
if(muc_dk_ds - (doanhsocovat_t1 + doanhsocovat_t2 + doanhsocovat_t3) <= 0,0,muc_dk_ds - (doanhsocovat_t1 + doanhsocovat_t2 + doanhsocovat_t3) ) as sl_conthieu_q1,
if(muc_dk_ds - (doanhsocovat_t4 + doanhsocovat_t5 + doanhsocovat_t6) <= 0,0,muc_dk_ds - (doanhsocovat_t4 + doanhsocovat_t5 + doanhsocovat_t6) ) as sl_conthieu_q2,
if(muc_dk_ds - (doanhsocovat_t7 + doanhsocovat_t8 + doanhsocovat_t9) <= 0,0,muc_dk_ds - (doanhsocovat_t7 + doanhsocovat_t8 + doanhsocovat_t9) ) as sl_conthieu_q3,
if(muc_dk_ds - (doanhsocovat_t10 + doanhsocovat_t11 + doanhsocovat_t12) <= 0,0,muc_dk_ds - (doanhsocovat_t10 + doanhsocovat_t11 + doanhsocovat_t12) ) as sl_conthieu_q4,
if(muc_dk_ds <= doanhsocovat_t1 + doanhsocovat_t2 + doanhsocovat_t3,'Đạt','Không đạt' ) as xet_sl_q1,
if(muc_dk_ds <= doanhsocovat_t4 + doanhsocovat_t5 + doanhsocovat_t6,'Đạt','Không đạt' ) as xet_sl_q2,
if(muc_dk_ds <= doanhsocovat_t7 + doanhsocovat_t8 + doanhsocovat_t9,'Đạt','Không đạt' ) as xet_sl_q3,
if(muc_dk_ds <= doanhsocovat_t10 + doanhsocovat_t11 + doanhsocovat_t12,'Đạt','Không đạt' ) as xet_sl_q4,
ifnull(d.thu_hoi_tttb,'Chưa thu') as thu_hoi_ttmb,
if(g.so_mst_khac_nhau > 1, 'Gộp MST', '') as gop_mst,
d.thu_hoi_phu_luc_thay_doi_thong_tin_thoa_thuan_3_ben_bien_ban_thanh_ly_hop_dong
from mapping_sales a
 LEFT JOIN `staging.d_master_khachhang` c on a.ma_kh = c.custid
 LEFT JOIN `staging.d_users` e on e.manv = a.manhanvienphutrach
 LEFT JOIN thu_hoi_hd d on a.ma_kh =d.ma_kh
 LEFT JOIN mst_base g on g.makhdms = a.ma_kh
 LEFT JOIN `spatial-vision-343005.staging.d_calendar_cre` h ON a.manhanvienphutrach = h.ma_crs AND date(h.thang) = DATE_TRUNC(DATE(CURRENT_DATE()),MONTH)

--)
;

Create or replace table `warehouse.f_chuongtrinh_sticker_ladoi_2023`

copy `staging_temp.f_chuongtrinh_sticker_ladoi_2023_temp`;

End;
