CREATE VIEW `spatial-vision-343005.warehouse.view_input_muc_tieu_google_sheet_tp`
AS with 
tuyen_dms as 
(
with data_tuyen as (
SELECT custid,slsperid,crtd_datetime,
Case when routetype in ('B','D') then 1 else 2 end as routetype,
FROM `spatial-vision-343005.staging.sync_dms_srm`  a 
LEFT JOIN `staging.d_users` b on a.slsperid =b.manv

where delroutedet is false  and routetype in ('B','D')
)

select custid,slsperid
from data_tuyen
qualify row_number() over (partition by custid order by routetype asc,crtd_datetime desc) =1
),

tuyen_cvbh_hd as 
(
select distinct custid,slsperid
from `spatial-vision-343005.staging.d_get_contract_det` a
LEFT JOIN `staging.d_users` b on a.slsperid =b.manv

where slsperid not in ('GH001','QUYNHPTA','MA001','MA002') and b.tenquanlyvung ='Nguyễn Thọ Chiến'
-- qualify row_number() over (partition by custid,slsperid order by cast(crtd_date as date) desc) =1
-- where  loc = 1

),

tuyen_cvbh_hd_lichsu as
(

SELECT 
distinct b.custid,a.slsperid
FROM `spatial-vision-343005.staging.d_oricontractdet` a 
INNER JOIN `spatial-vision-343005.staging.d_oricontract` b on a.contractid = b.contractid
LEFT JOIN `staging.d_users` c on c.manv =a.slsperid
where c.tenquanlyvung ='Nguyễn Thọ Chiến'
and b.custid not in (select custid from tuyen_cvbh_hd)
qualify row_number() over (partition by custid order by genlupd_datetime desc) = 1
),

mapping_mcp_hd as (
select * from tuyen_dms
UNION Distinct
select * from tuyen_cvbh_hd
UNION Distinct
select * from tuyen_cvbh_hd_lichsu
),

sales as (
  select makhdms,sum(doanhsochuavat) as ds from `warehouse.f_raw_data_sales_yoy`  
  where date(ngaychungtu) between date(date_trunc(current_date("+7"),month))  and date(date_trunc(current_date("+7"),month) + interval 1 month - interval 1 day)
  group by all
)
,
sales_previous as (
  select makhdms,sum(doanhsochuavat) as ds from `warehouse.f_raw_data_sales_yoy` 
  where date(ngaychungtu) between date(date_trunc(current_date("+7"),month) - interval 1 month)  and date(date_trunc(current_date("+7"),month) - interval 1 day)
  group by all
)
,

congno as (
  select custid,sum(so_du_chungtu) as congno from `warehouse.f_congno_tp_mt` group by all
)

, muc_tieu_thang_trc as

(
  SELECT makh, sum(target) as lm_target FROM `spatial-vision-343005.staging.f_input_muc_tieu_crs` 
  where target is not null
  group by all 
)
, tong_ds_nam_du_kien as (
SELECT 
a.makhdms,

SUM(
    CASE    WHEN b.nhomcpa in ('XO','CL','KS')
            AND DATE(ngaychungtu) >= '2025-01-02' 
            AND DATE(ngaychungtu) < '2025-12-27'
        THEN doanhsocovat
        ELSE 0 
    END
) AS tong_ds_nam
FROM `warehouse.f_raw_data_sales_yoy` a
LEFT JOIN `staging.d_nhom_sp_trading` b ON a.masanpham = b.masanpham
WHERE
    a.ngaychungtu >= '2025-01-01'  
    and a.ngaychungtu <= '2025-12-27'
GROUP BY ALL
)

,hang_tv_nam as (
SELECT
*,
CASE 
        WHEN tong_ds_nam >= 600000000 THEN 'Diamond'
        WHEN tong_ds_nam >= 240000000 THEN 'Platinum'
        WHEN tong_ds_nam >= 120000000 THEN 'Gold'
        WHEN tong_ds_nam >= 60000000 THEN 'Silver'
        WHEN tong_ds_nam >= 36000000 THEN 'Copper'
        ELSE NULL  -- If none of the conditions are met
    END AS hang_tv_nam
FROM tong_ds_nam_du_kien
)

select 
d1.col.ma_nvbh as slsperid,
e.tencvbh,
e.supid,
e.tenquanlytt,
a.ma_khachhang,
a.tenkhachhang,
-- Case when f.ma_hco_tren_dms is not null then 'GOLD'
--      when g.ma_kh_dms is not null then 'DIAMOND'
-- else 'OTHER' end as kenh_phu,

CASE 
        WHEN v.muc_hd_2025 >= 600000000 AND v.ma_kh is not null THEN CONCAT('Loyalty',' - ','Diamond')
        WHEN v.muc_hd_2025 >= 240000000 AND v.ma_kh is not null THEN CONCAT('Loyalty',' - ','Platinum')
        WHEN v.muc_hd_2025 >= 120000000 AND v.ma_kh is not null THEN CONCAT('Loyalty',' - ','Gold')
        WHEN v.muc_hd_2025 >= 60000000 AND v.ma_kh is not null THEN CONCAT('Loyalty',' - ','Silver')
        WHEN v.muc_hd_2025 >= 36000000 AND v.ma_kh is not null THEN CONCAT('Loyalty',' - ','Copper')
        ELSE 'Other' end as phan_loai_kh,
a.kenh,
a.tinh,
h.lm_target as muc_tieu_thang_trc,
ifnull(b1.ds,0) as thuc_hien_thang_trc,
SAFE_DIVIDE (b1.ds,h.lm_target) as thuc_hien_tren_muc_tieu_thang_trc,
concat("https://ds.merapgroup.com/reportscreen/21?params=%257B%22df25%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580MR0000%22%2C%22df26%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580",a.ma_khachhang,"%22%257D") as link_chi_tiet_doanh_so,
ifnull(b.ds,0) as thuc_hien_mtd,
c.congno as du_no,
concat("https://ds.merapgroup.com/reportscreen/142?params=%257B%22df50%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580MR0000%22%2C%22df55%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580",a.ma_khachhang,"%22%257D") as link_chi_tiet_no,
a.classid as loai_kh,
a.thu
from `spatial-vision-343005.warehouse.f_thongtin_tuyen_mcp_tp_pcl` a --`staging.d_master_khachhang` a
LEFT JOIN sales b on a.ma_khachhang = b.makhdms
LEFT JOIN sales_previous b1 on a.ma_khachhang = b1.makhdms
LEFT JOIN congno c on a.ma_khachhang = c.custid
LEFT JOIN `warehouse.f_mapping_crs` d1 on d1.custid = a.ma_khachhang 
LEFT JOIN `staging.d_users` e on d1.col.ma_nvbh = e.manv
LEFT JOIN `staging.d_manual_danh_sach_gold` f on f.ma_hco_tren_dms = a.ma_khachhang
LEFT JOIN `staging.d_manual_danhsach_khachhang_diamond` g on g.ma_kh_dms = a.ma_khachhang
LEFT JOIN muc_tieu_thang_trc h on h.makh = a.ma_khachhang
--LEFT JOIN `staging_temp.f_thongtin_tuyen_mcp_tp_pcl_temp` t on t.ma_khachhang = a.ma_khachhang and DATE(t.thang) = DATE_TRUNC(CURRENT_DATE(), MONTH)
LEFT JOIN `spatial-vision-343005.staging.form_theo_doi_CSBH_loyalty_TP_2025` v ON v.ma_kh = a.ma_khachhang AND DATE(hieu_luc_hd_ket_thuc) >= CURRENT_DATE
where a.kenh in ('TP')
and a.active = 'Active'
and a.tuyen_cn = 0
and DATE(a.thang) = DATE_TRUNC(CURRENT_DATE(), MONTH)
--and e.supid = 'MR0849'
ORDER BY a.classid




;