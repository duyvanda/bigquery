CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_thuongdoanhthu_hcp()
BEGIN

TRUNCATE TABLE staging_temp.f_thuongdoanhthu_hcp_temp;
--INSERT INTO staging_temp.f_thuongdoanhthu_hcp_temp(

Create or replace table staging_temp.f_thuongdoanhthu_hcp_temp
as 

with 
data_mapping as 

(
SELECT 
        CAST(THANG as date) as thang, 
        msnvcsmmoi as macrm, 
        hovatenfullname as tenquanlytt
    FROM `spatial-vision-343005.staging.d_hr_dsns_bytime` 
    WHERE phongdeptsummary = 'HCP'
    AND (chucdanhengtitlesum LIKE '%CRM%' OR chucdanhengtitlesum LIKE '%CRD%')
    AND msnvcsmmoi not in ('MR0123', 'MR1650') -- loại vì thưởng doanh thu không áp dụng cho N.CRM
)

, data_doanhthu as (
SELECT
  date(date_trunc(dt.ngaythu_ge,month)) as thang,
  
  /* Lấy mã CRM: Ưu tiên Gonsa -> HR -> f_mapping_crs (dùng trực tiếp dt.custname) */
  CASE 
    WHEN LOWER(dt.custname) LIKE '%gonsa%' THEN 'MR1137'
    ELSE IFNULL(hr_crm.msnvcsmmoi, c.supid) 
  END as ma_crm,

  /* Lấy tên CRM: Ưu tiên Gonsa -> d_manual -> f_mapping_crs */
  CASE 
    WHEN LOWER(dt.custname) LIKE '%gonsa%' THEN 'Vũ Mừng'
    ELSE IFNULL(g.crm, c.tenquanlytt) 
  END as tenquanlytt,

  sum(case when dt.phanloai_no='Nợ xanh' then dt.doanhthu else 0 end) as no_xanh,
  sum(case when dt.phanloai_no='Nợ vàng' then dt.doanhthu else 0 end) as no_vang,
  sum(case when dt.phanloai_no='Nợ đỏ' then dt.doanhthu else 0 end) as no_do,
  sum(case when dt.phanloai_no='Nợ đen' then dt.doanhthu else 0 end) as no_den,
  sum(dt.doanhthu) as doanhthu,
  sum(dinhmuc_thuong_crm) as dinhmuc_thuong_crm,
  sum(dinhmuc_thuong_ncrd) as dinhmuc_thuong_ncrd

FROM
  `warehouse.f_thuongdoanhthu_hcp_detail` dt
LEFT JOIN `warehouse.f_mapping_crs` c on dt.custid = c.custid
LEFT JOIN `staging.d_manual_dia_ban_cong_no_hcp` g on dt.custid = g.ma_kh
LEFT JOIN (
    SELECT msnvcsmmoi, hovatenfullname
    FROM `spatial-vision-343005.staging.d_hr_dsns`
    WHERE phongdeptsummary = 'HCP'
) hr_crm on hr_crm.hovatenfullname = g.crm

WHERE
  ngaythu_ge>='2023-01-01' 
  group by 1,2,3
  order by thang
)
,

doanhthu_mapping as (
 select 
 ifnull(a.thang,b.thang) as thang ,
 ifnull(b.ma_crm,a.macrm) as macrm,
 ifnull(b.tenquanlytt,a.tenquanlytt) as tenquanlytt,
 b.no_xanh,
 b.no_vang,
 b.no_do,
 b.no_den,
 b.dinhmuc_thuong_crm,
 b.dinhmuc_thuong_ncrd
 from data_doanhthu b 
 FULL JOIN  data_mapping a  on a.thang = b.thang and a.macrm  =b.ma_crm
 where  ifnull(a.thang,b.thang)>='2023-01-01'
),

result_doanhthu as (
-- Doanh thu theo CRM
select 
    thang, 
    macrm, 
    tenquanlytt,
    ifnull(no_xanh, 0) as no_xanh, 
    ifnull(no_vang, 0) as no_vang, 
    ifnull(no_do, 0) as no_do, 
    ifnull(no_den, 0) as no_den,
    --round((ifnull(no_do, 0) + ifnull(no_den, 0)) * 20 / 100, 1) as dinhmuc_duyetdon,
    ifnull(dinhmuc_thuong_crm,0) as dinhmuc_thuong_crm,
    ifnull(dinhmuc_thuong_ncrd,0) as dinhmuc_thuong_ncrd
from doanhthu_mapping
where macrm != 'MR1137'
-- DOanh thu theo N.CRM
 UNION ALL
select 
    thang, 
    'MR1137' as macrm, 
    'Vũ Mừng' as tenquanlytt,
    sum(ifnull(no_xanh, 0)) as no_xanh, 
    ifnull(sum(no_vang), 0) as no_vang, 
    ifnull(sum(no_do), 0) as no_do, 
    ifnull(sum(no_den), 0) as no_den,
    --round(sum(ifnull(no_do, 0) + ifnull(no_den, 0)) * 40 / 100, 1) as dinhmuc_duyetdon,
    sum(ifnull(dinhmuc_thuong_crm,0)) as dinhmuc_thuong_crm,     
    sum(ifnull(dinhmuc_thuong_ncrd,0)) as dinhmuc_thuong_ncrd
from doanhthu_mapping
group by thang,macrm, tenquanlytt

),

result as (
 select 
 b.thang,
 extract(quarter from b.thang) || extract(year from b.thang) as quy,
 ifnull(b.macrm,'') as macrm,
 b.tenquanlytt,
 --b.dinhmuc_duyetdon,
 --b.dinhmuc_duyetdon,
 --avg(b.dinhmuc_duyetdon) over(partition by b.macrm,b.thang) - sum(ifnull(doanhsochuavat,0)) over(partition by b.macrm,a.thang)  as dinhmuc_duyetdon_conlai,
 
 b.no_xanh,
 b.no_vang,
 b.no_do,
 b.no_den,
 
 /* ===== UPDATE POLICY TỪ 01/03/2026 ĐÃ TỐI ƯU GỘP BIẾN ===== */
 CASE 
    WHEN b.macrm = 'MR1137_KN' THEN 0 
    WHEN b.macrm = 'MR1137' THEN dinhmuc_thuong_ncrd -- thưởng NCRD
    ELSE b.dinhmuc_thuong_crm
--ROUND((b.no_xanh * 0.7 + b.no_vang * 0.6 + b.no_do * 0.5 + b.no_den * 0.4)/100, 1)
END as dinhmuc_thuong
 from  result_doanhthu b
 )

/* ===== LẤY KẾT QUẢ CUỐI (ĐÃ BỎ TRUY THU, GIỮ LẠI CHỨC DANH) ===== */
select 
    a.*,
    CASE 
        WHEN a.macrm IN ('MR1137','MR1137_KN') THEN 'N-CRD (HCP)' 
        ELSE b.chucdanhengtitlesum 
    END as chucdanh,
    'Công ty cổ phần tập đoàn Merap' as phaply,
    current_datetime("+7") as updated_at
from result a 
left join staging.d_hr_dsns_bytime b on left(a.macrm,6) = b.msnvcsmmoi and date(a.thang) = date(b.thang)
where b.msnvcsmmoi is not null
and phongdeptsummary not in ('TP')
order by a.thang;

Create or replace table `warehouse.f_thuongdoanhthu_hcp`
copy `staging_temp.f_thuongdoanhthu_hcp_temp`;

End;