CREATE VIEW `spatial-vision-343005.warehouse.view_input_muc_tieu_google_sheet_hcp`
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
  select custid,sum(tiennocongty) as congno from `warehouse.f_congno_hcp_crm` group by all
)

, muc_tieu_thang_trc as

(
  SELECT makh, sum(target) as lm_target FROM `spatial-vision-343005.staging.f_input_muc_tieu_crs` 
  where target is not null
  group by all 
)

select 
ifnull(d.slsperid,d1.col.ma_nvbh) as slsperid,
e.tencvbh,
e.supid,
e.tenquanlytt,
a.custid,
a.custname,
a.channel,
a.shoptype,
a.statedescr,
h.lm_target as muc_tieu_thang_trc,
ifnull(b1.ds,0) as thuc_hien_thang_trc,
0.0 as thuc_hien_tren_muc_tieu_thang_trc,
concat("https://ds.merapgroup.com/reportscreen/21?params=%257B%22df25%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580MR0000%22%2C%22df26%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580",a.custid,"%22%257D") as link_chi_tiet_doanh_so,
-- ifnull(b.ds,0) as thuc_hien_mtd,
0 as thuc_hien_mtd,
c.congno as du_no,
-- ifnull(c.congno,0) as du_no,
concat("https://ds.merapgroup.com/reportscreen/182?params=%257B%22df178%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580MR0000%22%2C%22df180%22%3A%22include%2525EE%252580%2525800%2525EE%252580%252580IN%2525EE%252580%252580",a.custid,"%22%257D") as link_chi_tiet_no,
from `staging.d_master_khachhang` a
LEFT JOIN sales b on a.custid = b.makhdms
LEFT JOIN sales_previous b1 on a.custid = b1.makhdms
LEFT JOIN congno c on a.custid = c.custid
LEFT JOIN `warehouse.f_mapping_crs` d1 on d1.custid =a.custid and a.channel ='PCL'
LEFT JOIN mapping_mcp_hd d on d.custid =a.custid and a.channel !='PCL'
LEFT JOIN `staging.d_users` e on ifnull(d.slsperid,d1.col.ma_nvbh) = e.manv
LEFT JOIN muc_tieu_thang_trc h on h.makh = a.custid
where a.channel in ('INS','CLC','PCL');