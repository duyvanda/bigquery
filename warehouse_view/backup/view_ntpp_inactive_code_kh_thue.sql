CREATE VIEW `spatial-vision-343005.warehouse.view_ntpp_inactive_code_kh_thue`
AS with warning_custid as (
  select custid, custname, custidinvoice from `staging.d_master_khachhang`
)

, lastest_cust_change as (
  select * from `spatial-vision-343005.staging.d_tracking_cust_changes` a where a.type = 'Mã KH Thuế'
  and date(a.lupd_datetime) >= DATE_SUB(current_date(), INTERVAL 365 DAY) and a.`old` is not null
  QUALIFY ROW_NUMBER() OVER(PARTITION BY custid order by version desc) = 1
)

SELECT
a.lupd_datetime,
a.lupd_user,
-- a.version,
ifnull(a.`new`, 'unknow') as gia_tri_moi_active,
ifnull(a.`old`, 'unknow') as gia_tri_cu_inactive,
-- a.custid as custid_thay_doi,
b.custid as custid_con_hoat_dong,
b.custname,
q.tencvbh
-- a.type as loai_thay_doi,
-- a.datatype as loai_thong_tin,
-- c.hcotypeid

FROM lastest_cust_change a
LEFT JOIN warning_custid b on a.old = b.custidinvoice
INNER JOIN `staging.d_master_khachhang` c on c.custid = a.custid and hcotypeid = 'NTPP'
LEFT JOIN `spatial-vision-343005.staging.d_users` q on a.lupd_user = q.manv
where b.custid is not null
order by a.lupd_datetime desc;