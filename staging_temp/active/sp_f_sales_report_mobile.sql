CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_sales_report_mobile()
BEGIN 

DECLARE partition_date DATE DEFAULT DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH), MONTH);

TRUNCATE TABLE staging_temp.f_sales_report_mobile_temp;
INSERT INTO staging_temp.f_sales_report_mobile_temp
(

-- Create or replace table staging_temp.f_sales_report_mobile_temp
-- partition by ngaychungtu
-- as (

----------------------------- `view_report.mr|sales report-mobile page monthly`---------------------
with cum_tinh_quan_huyen as

(

  select distinct statedescr, districtdescr, cluster_state from staging.d_leadtimekpi where districtdescr != 'Huyện Bình Chánh'

)

, cum_phuong_xa as
(
  select distinct statedescr, districtdescr, wardname, cluster_state from staging.d_leadtimekpi where districtdescr = 'Huyện Bình Chánh'

)
, base as
(
  -- select 
  --   date(thang) ngaychungtu ,
  --   masanpham,
  --   IFNULL(t1.tensanphamnb,c.descr) as tensanphamnb,
  --   t2.custid makhdms,
  --   t2.statedescr as tentinhkh,
  --   t2.districtdescr as tenquanhuyen,
  --   t2.wardname as phuongxakh,
  --   tenkhachhang,
  --   makenhkh,
  --   makenhphu,
  --   t2.channel as tenkenhkh,
  --   t2.shoptype as tenkenhphu, 
  --   null as company_products,
  --   null as sodondathang,
  --   t2.branchid as macongtycn,
  --   t2.branchname as tenctycn,
  --   t2.cluster_state,
  --   t2.paymentsform,
  --   t2.terms,

  --   doanhsochuavat,
  --   soluong,
  --   t1.inserted_at,
  
  -- from spatial-vision-343005.staging.f_monthly_sales t1
  -- left join staging.d_master_khachhang t2 on t1.makhcu = t2.refcustid
  -- LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid` c on t1.masanpham = c.invtid
  -- where date(thang)<'2021-05-01'

  -- union all

  select 
    date(a.ngaychungtu) ngaychungtu ,
    a.masanpham,
    IFNULL(a.tensanphamnb,c.descr) as tensanphamnb,
    a.makhdms, 
    b.statedescr as tentinhkh, 
    b.districtdescr,
    b.wardname as phuongxakh,
    b.custname as tenkhachhang,
    b.channel as makenhkh,
    b.shoptype as makenhphu,
    a.tenkenhkh,
    a.tenkenhphu,
    'MR' as company_products,
    a.sodondathang,
    a.macongtycn, 
    a.congtycn,
    b.cluster_state,
    b.paymentsform,
    b.terms,
    sum(doanhsochuavat) as doanhsochuavat,
    sum(soluong) soluong,
    a.inserted_at,
  FROM `spatial-vision-343005.staging.f_sales` a
  LEFT JOIN staging.d_master_khachhang b on a.makhdms = b.custid
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid` c on a.masanpham = c.invtid
  WHERE
  TRUE
  AND Date(a.ngaychungtu) >= partition_date
  AND LEFT(a.masanpham, 1) != 'V'
  AND a.makenhkh not in ('NB')
  AND
  (
  CASE
  WHEN a.makhdms IN ('008140', '003589', '013410', '018851') THEN TRUE
  WHEN a.makenhkh = 'OTH_LAB' THEN TRUE
  WHEN a.manv NOT IN ('GH001', 'QUYNHPTA', 'MA001', 'MA002') THEN TRUE
  ELSE FALSE END
  )
  AND macongtycn != 'DL0001'
  group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,22
)
,

result0 as
( 
  select 
  t1.*,
  case when lower(t1.tenkhachhang) like '%fpt long châu%' and makenhkh = 'MT' then '1.Long Châu' 
      when lower(t1.tenkhachhang) like '%pharmacity%' and makenhkh = 'MT' then '2.Phamacity' 
      when lower(t1.tenkhachhang) like '%trung sơn%' and makenhkh = 'MT' then '3.Trung Sơn' 
      when lower(t1.tenkhachhang) like '%medx%' and makenhkh = 'MT' then '4.MedX' 
      when lower(t1.tenkhachhang) like '%guardian%' and makenhkh = 'MT' then '5.Guardian' 
      when lower(t1.tenkhachhang) like '%an khang%' and makenhkh = 'MT' then '6.An Khang' 
      when t1.makhdms = '003589' and makenhkh = 'MT' then '9.ECE - Ecommerce enable'
      when lower(t1.tenkhachhang) like '%wincommerce%' and makenhkh ='MT' then '7.WinMart'
      when lower(t1.tenkhachhang) like '%meraki%' and makenhkh ='MT' then '8.Meraki'
      else 'others' end as group_khach_hang,
  --concat(makenhkh,"-",    
  case when tenkenhphu like '%Clinic Chanel%'  then 'Clinic'
      when  tenkenhphu like '%Đại Lý Phân Phối%' then 'Đại Lý Phân Phối'
      when  tenkenhphu like '%Insurance%' then 'Kênh Bảo hiểm'
      else tenkenhphu end as kenh_khach_hang,
  'N' iscaresoft_customer,
  case when t7.ordernbr is not null then 'Y' else 'N' end is_Ecommerce_orders

  from base t1
  left join ( 
  SELECT
  distinct branchid,
  ordernbr 
  FROM `spatial-vision-343005.staging.sync_dms_pda_sod` 
  WHERE DATE(crtd_datetime) >= partition_date and slsperid = 'TMDT_001'
  ) t7 
on t1.sodondathang = t7.ordernbr 
and t1.macongtycn=t7.branchid
)
select * from result0
);
-- Create or replace table `warehouse.f_sales_report_mobile`

-- copy `staging_temp.f_sales_report_mobile_temp`;

BEGIN TRANSACTION;
DELETE FROM
    `warehouse.f_sales_report_mobile`
WHERE
    DATE(ngaychungtu) >= DATE(partition_date);
INSERT INTO
    warehouse.f_sales_report_mobile
SELECT
    *
FROM
    `staging_temp.f_sales_report_mobile_temp`;
COMMIT TRANSACTION;
END;