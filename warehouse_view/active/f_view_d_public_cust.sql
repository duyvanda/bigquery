CREATE VIEW `spatial-vision-343005.warehouse.f_view_d_public_cust`
AS with sales as (
  select 
  pubcustid, sum(doanhsochuavat) as ds
  FROM `staging.f_sales` a
  LEFT JOIN `staging.d_master_khachhang` b on a.makhdms = b.custid
  where ngaychungtu >='2023-01-01' 
  group by all
)

, sl_ma_kh_dms as (
  select pubcustid, count(custid) as slkh from `staging.d_master_khachhang` where active = 'Active' and pubcustid is not null
  group by all 
)

SELECT
a.*, ifnull(b.slkh,0) as slkh, ifnull(c.ds,0) as dscv
FROM `spatial-vision-343005.staging.d_public_cust` a 
LEFT JOIN `sl_ma_kh_dms` b on a.pubcust = b.pubcustid
LEFT JOIN sales c on a.pubcust = c.pubcustid
-- group by all;