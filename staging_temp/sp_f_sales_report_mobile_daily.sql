CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_sales_report_mobile_daily()
BEGIN

DECLARE partition_date DATE DEFAULT DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH), MONTH);

TRUNCATE TABLE staging_temp.f_sales_report_mobile_daily_temp;
INSERT INTO staging_temp.f_sales_report_mobile_daily_temp(

-- Create or replace table `staging_temp.f_sales_report_mobile_daily_temp`
-- PARTITION BY date(ngaychungtu)
-- as (

with data_trongtuyenmcp as
(
  SELECT 
    distinct custid 
  FROM `spatial-vision-343005.staging.sync_dms_srm` 
  where routetype in ('B', 'C', 'D') 
)
,

tuyen123 as
(
  select * from (
                  select custid, datatype, row_number() over (partition by custid order by datatype asc) as loc 
                  from (
                          SELECT custid, routetype, 1 as datatype from `staging.sync_dms_srm` where routetype in ('B','C','D') and delroutedet is false
                          UNION ALL
                          SELECT custid, routetype, 2 as datatype from `staging.sync_dms_srm` where routetype in ('F') and delroutedet is false
                          UNION ALL
                          SELECT custid, routetype, 3 as datatype from `staging.sync_dms_srm` where routetype in ('A') and delroutedet is false
                       )
                )
  where loc = 1 
)
,

cum_tinh_quan_huyen as

(

  select distinct statedescr, districtdescr, cluster_state from staging.d_leadtimekpi where districtdescr != 'Huyện Bình Chánh'

)

, cum_phuong_xa as
(
  select distinct statedescr, districtdescr, wardname, cluster_state from staging.d_leadtimekpi where districtdescr = 'Huyện Bình Chánh'

)
,

base as
(
  select
    t1.ngaychungtu, 
    t1.sodondathang, 
    t1.mahd,
    t1.macongtycn,
    t1.congtycn,
    t1.trangthai,
    t1.makhdms, 
    t1.makhcu, 
    b.custname as tenkhachhang, 
    t1.tenvungbh,
    t1.tenkhuvuc,
    b.channel as makenhkh,
    t1.tenkenhkh,
    t1.makenhphu, 
    b.shoptypedescr as tenkenhphu, 
    t1.mahco, 
    t1.tenhco, 
    t1.maphanloaihco, 
    t1.tenphanloaihco, 
    t1.maphanhanghco, 
    t1.tenphanhanghco, 
    t1.tensanphamnb, 
    t1.masanpham,
    t1.tentinhkh,
    t1.thtt,
    t1.pmt,
    case when lower(b.custname) like '%fpt long châu%' and b.channel = 'MT' then '1.Long Châu' 
         when lower(b.custname) like '%pharmacity%' and b.channel = 'MT' then '2.Phamacity' 
         when lower(b.custname) like '%trung sơn%' and b.channel = 'MT' then '3.Trung Sơn' 
         when lower(b.custname) like '%medx%' and b.channel = 'MT' then '4.MedX' 
         when lower(b.custname) like '%guardian%' and b.channel = 'MT' then '5.Guardian' 
         when lower(b.custname) like '%an khang%' and b.channel = 'MT' then '6.An Khang' 
      
         when lower(b.custname) like '%wincommerce%' and b.channel ='MT' then '7.WinMart'
         when lower(b.custname) like '%meraki%' and b.channel ='MT' then '8.Meraki'
         when t1.makhdms = '003589' and b.channel = 'MT' then '9.ECE - Ecommerce enable'
         else 'others' end as group_khach_hang,
    case when tenkenhphu like '%Clinic Chanel%'  then 'Clinic'
        when  tenkenhphu like '%Đại Lý Phân Phối%' then 'Đại Lý Phân Phối'
        when  tenkenhphu like '%Insurance%' then 'Kênh Bảo hiểm'
        else tenkenhphu end as kenh_khach_hang,

    cast(b.legaldate as date) as thoihanhieulucgdpgpp,
    Case when b.legaldate is not null then 'Y' else 'N' end as is_co_gpp,
    b.classid as phanhanghco,
    t1.tencvbh as tencvbh,
    t1.tenquanlytt as tenquanlytt,
    t1.tenquanlykhuvuc as tenquanlykhuvuc,
    t1.tenquanlyvung as tenquanlyvung,

    t1.tenquanlytt as acrm,
    t1.tenquanlykhuvuc as scrm,
    t1.tenquanlyvung as ncxm,
    b.hcoid mahco_dsn,
    Case when b.channel = 'OTC' and b.hcotypeid like '%Phòng Khám Có%' then 'PKC'
         when b.channel = 'OTC' and b.hcotypeid like '%Phòng Khám Không%' then 'PKK'
         when b.channel = 'OTC' and b.shoptype ='PK' and b.hcotypeid is null then 'PK chưa phân loại' 
         when b.channel = 'OTC' and b.shoptype is not null then b.shoptype 
         when b.channel = 'OTC' and b.shoptype is  null then 'OTC'
         else b.channel end as channel,
    b.custidinvoice,
    b.custnameinvoice, 
    b.taxregnbr,
    t4.trangthaidon,
    t4.thongtinxe,
    t4.full_leadtime,
    t4.deliveryunit,
    t4.ngaygiaohang,
    b.active,
    b.cluster_state,
    t1.inserted_at,
    sum(t1.doanhsochuavat) doanhsochuavat,
    sum(t1.soluong) soluong,

  from `spatial-vision-343005.staging.f_sales` t1
  LEFT JOIN `staging.d_master_khachhang` b on t1.makhdms =b.custid
  left join ( 
              select 
                distinct ordernbr,
                branchid,
                t4.trangthaidon,
                t4.thongtinxe,
                t4.full_leadtime,
                t4.deliveryunit,
                t4.ngaygiaohang 
              from `spatial-vision-343005.warehouse.f_leadtime_new_detail1` t4
              where date(t4.ngaytaodon) >= partition_date
             ) t4 on t1.sodondathang = t4.ordernbr 
                     and t1.macongtycn=t4.branchid
                     
              WHERE
              true
              AND LEFT(t1.masanpham, 1) != 'V'
              AND t1.makenhkh not in ('NB')
              AND
              (
              CASE
              WHEN t1.makhdms IN ('008140', '003589', '013410', '018851') THEN TRUE
              WHEN t1.makenhkh = 'OTH_LAB' THEN TRUE
              WHEN t1.manv NOT IN ('GH001', 'QUYNHPTA', 'MA001', 'MA002') THEN TRUE
              ELSE FALSE END
              )
              and date(t1.ngaychungtu)>= partition_date
              AND t1.macongtycn != 'DL0001'
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51

)
,

result as 
(
  select 
    t1.* ,
    case when t4.doanhsochuavat <500000 then '1.<500k'
         when t4.doanhsochuavat <1000000 then '2.<1tr'
         when t4.doanhsochuavat <2000000 then '3.<2tr'
         when t4.doanhsochuavat <3000000 then '4.<3tr'
         when t4.doanhsochuavat <4000000 then '5.<4tr'
         when t4.doanhsochuavat <5000000 then '6.<5tr'
         when t4.doanhsochuavat <10000000 then '7.<10tr'
         else '8.>=10tr' end as doanhsodon_type,
    t4.soluong soluong_don,
    t3.lat,t3.lng,
    t3.hcotypeid,
    ifnull(t3.businessscope,"") businessscope,
    ifnull(t3.phone,"") phone,
    ifnull(REGEXP_REPLACE(t3.emailinvoice, ",", "| "),"") emailinvoice,
    'N' as iscaresoft_customer,
    case when t7.ordernbr is not null then 'Y' else 'N' end is_Ecommerce_orders,
    Case when t10.custid is null then 'N' else 'Y' end as is_trongtuyen_mcp,
    t11.datatype as tuyen123,
    t3.terms as HTTT,
    t3.paymentsform as HTT
  from base t1
  left join ( SELECT 
                sodondathang,
                sum(doanhsochuavat) doanhsochuavat,
                sum(soluong) soluong 
              from `spatial-vision-343005.staging.f_sales`
              where doanhsochuavat>0 and date(ngaychungtu) >= partition_date
              group by 1) t4 on t1.sodondathang = t4.sodondathang
  left join staging.d_master_khachhang t3 on t1.makhdms = t3.custid
  left join ( SELECT 
                distinct branchid,
                ordernbr 
             FROM `spatial-vision-343005.staging.sync_dms_pda_sod` 
             WHERE DATE(crtd_datetime) >= partition_date and slsperid = 'TMDT_001'
            ) t7 on t1.sodondathang = t7.ordernbr and t1.macongtycn = t7.branchid
  LEFT JOIN data_trongtuyenmcp t10 on trim(t10.custid) = trim(t1.makhdms)
  LEFT JOIN tuyen123 t11 on trim(t11.custid) = trim(t1.makhdms)
)

select * from result
);

-- Create or replace table `warehouse.f_sales_report_mobile_daily`

-- copy `staging_temp.f_sales_report_mobile_daily_temp`;

BEGIN TRANSACTION;
DELETE FROM
    `warehouse.f_sales_report_mobile_daily`
WHERE
    DATE(ngaychungtu) >= DATE(partition_date);
INSERT INTO
    `warehouse.f_sales_report_mobile_daily`
SELECT
    *
FROM
    `staging_temp.f_sales_report_mobile_daily_temp`;
COMMIT TRANSACTION;

























End;