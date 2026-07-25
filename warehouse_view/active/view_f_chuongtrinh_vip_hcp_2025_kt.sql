CREATE VIEW `spatial-vision-343005.warehouse.view_f_chuongtrinh_vip_hcp_2025_kt`
AS WITH 
base_date as (
  SELECT
    distinct date_trunc(ngay,month) as thang
    FROM
        unnest(
            GENERATE_DATE_ARRAY(
                date_sub(current_date("+7"), INTERVAL 24 MONTH),
                date_add(current_date("+7"), INTERVAL 12 MONTH),
                INTERVAL 1 DAY
            )
        ) AS ngay
),
data_sales as 
(
  select 
  a.thang,
  a.makhdms,
  sum(doanhsocovat) as doanhsocovat,

  from `warehouse.f_raw_data_sales_yoy` a
  where ngaychungtu >='2025-01-01' and ngaychungtu <'2026-01-01' 
  group by all
)


SELECT
    a2.thang,
    a1.custidinvoice as invoicecustid,
    a1.custnameinvoice,
    a1.custid,
    a1.custname,
    a1.hcotypeid,
    a1.shoptype,
    a1.hcoid,
    a1.channel,
    a1.branchid,
    a1.shortterritorydescr as territorydescr,
    a1.statedescr,
    ifnull(b.doanhsocovat,0) as doanhsocovat,
    Case when ifnull(b.doanhsocovat,0) >= 600000000 and ifnull(b.doanhsocovat,0)  < 2000000000 then 0.03 
         when ifnull(b.doanhsocovat,0)  >= 2000000000 then 0.05
    else 0 end as muc_chiet_khau,

    ifnull(b.doanhsocovat,0) * (
    Case when ifnull(b.doanhsocovat,0)  >= 600000000 and ifnull(b.doanhsocovat,0)  < 2000000000 then 0.03 
         when ifnull(b.doanhsocovat,0)  >= 2000000000 then 0.05
    else 0 end ) as tong_tien_chiet_khau,
    l.col.ma_nvbh as ma_crs,
    e.tencvbh,
    left(e.supid,6) as ma_crm,
    e.tenquanlytt,
    left(e.rsmid,6) as ma_ncxm,
    e.tenquanlyvung,
    sum(ifnull(b.doanhsocovat,0)) over (partition by a1.custid)  as acc_ds,
    '' as ngaythanhtoantienck_q1,
    '' as tinhtrang_thanhtoan_q1,
    '' as ghichu_thanhtoan_q1

FROM
   `staging.d_master_khachhang` a1 
    LEFT JOIN base_date a2 on 1 = 1
    LEFT JOIN data_sales b on a1.custid = b.makhdms and a2.thang = date(b.thang)
    LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a1.custid 
    LEFT JOIN `staging.d_users` e on l.col.ma_nvbh = e.manv
WHERE
    a1.custid ='MSPC0033'
    and a2.thang >='2025-01-01' 
    and a2.thang <'2026-01-01'
order by a2.thang;