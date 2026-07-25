CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_mua_hang_sp_online_detail()
OPTIONS(
  strict_mode=false)
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_mua_hang_sp_online_detail_temp`;

 INSERT INTO `staging_temp.f_mua_hang_sp_online_detail_temp`

( 
-- Create or replace table staging_temp.f_mua_hang_sp_online_detail_temp as
with 
  tuyen_dms_moinhat AS (
  WITH
    data_tuyen AS (
    SELECT
      custid,
      slsperid,
      crtd_datetime,
      CASE
        WHEN routetype IN ('B', 'D') THEN 1
        ELSE 2
    END
      AS routetype,
    FROM
      `spatial-vision-343005.staging.sync_dms_srm`
    WHERE
      delroutedet IS FALSE )
  SELECT
    *
  FROM
    data_tuyen
  QUALIFY
    ROW_NUMBER() OVER (PARTITION BY custid ORDER BY routetype ASC, crtd_datetime DESC ) = 1 ),

ke_hoach as (
SELECT
cast (null as string) as ordernbr,
cast (null as string) as branchid,
ma_hco_tren_dms,
cast (null as string) as ma_hco_tren_dms_pp,
ma_hco_tren_dms as ma_hco_tren_dms_kpi,
cast ('2024-07-10' as timestamp) as crtd_datetime,
crs as ma_crs,
cast (null as string) as is_ecom,
0 as sl_ban,
cast ('2024-07-10' as timestamp) as crtd_datetime_min,
ifnull(ke_hoach_ban_online,0) as  ke_hoach_ban_online,
FROM `spatial-vision-343005.staging.d_dskh_mua_hang_sp_online` a 
)
,
sales as (
  select 
  a.ordernbr,
  a.branchid,
  a.custid  , 
  a.custid as ma_hco_tren_dms_pp, 
  cast (null as string) as ma_hco_tren_dms_kpi,
  a.crtd_datetime as crtd_datetime,
  Case 
  when b.slsperid in (
                'MR1682KN',
                'MR2504',
                'MR1232',
                'MR0806',
                'MR2608',
                'MR2111',
                'MR1682',
                'MR2504KN',
                'MR1232KN',
                'MR0806KN',
                'MR2608KN',
                'MR2111KN',
                'MR2993',
                'MR2993KN',
                'MR3038',
                'MR3038KN',
                'MR2608KN',
                'MR2948',
                'MR2948KN',
                'MR2608'
            ) then ifnull(g1.macrs, g2.macrs)
  when b.slsperid ='TMDT_001' and 
   e.slsperid in (
                'MR1682KN',
                'MR2504',
                'MR1232',
                'MR0806',
                'MR2608',
                'MR2111',
                'MR1682',
                'MR2504KN',
                'MR1232KN',
                'MR0806KN',
                'MR2608KN',
                'MR2111KN',
                'MR2993',
                'MR2993KN',
                'MR3038',
                'MR3038KN',
                'MR2608KN',
                'MR2948',
                'MR2948KN',
                'MR2608'
            )
           then ifnull(g1.macrs, g2.macrs)
  when b.slsperid ='TMDT_001' and 
   e.slsperid not in (
                'MR1682KN',
                'MR2504',
                'MR1232',
                'MR0806',
                'MR2608',
                'MR2111',
                'MR1682',
                'MR2504KN',
                'MR1232KN',
                'MR0806KN',
                'MR2608KN',
                'MR2111KN',
                'MR2993',
                'MR2993KN',
                'MR3038',
                'MR3038KN',
                'MR2608KN',
                'MR2948',
                'MR2948KN',
                'MR2608'
            )
           then e.slsperid
  else b.slsperid end AS ma_crs,
  Case when b.slsperid ='TMDT_001' then 'Ecom'
  else 'Merap' end as is_ecom,

  sum(b.lineqty) as qty,
  min(a.crtd_datetime) as crtd_datetime_min,
  0 as ke_hoach
    from `staging.sync_dms_pda_so` a
  LEFT JOIN `staging.sync_dms_pda_sod` b on a.ordernbr =b.ordernbr and a.branchid =b.branchid
  LEFT JOIN `staging.d_master_khachhang` c on a.custid =c.custid
  LEFT JOIN tuyen_dms_moinhat e ON e.custid = a.custid AND b.slsperid ='TMDT_001'
  -- JOIN tuyen_dms_moinhat f on f.custid = a.custid and IFNULL(e.slsperid,b.slsperid) = f.slsperid
  LEFT JOIN `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` g1 on g1.phuongxa is not null
        and trim(upper(concat(concat(g1.tinhtp, g1.quanhuyen), g1.phuongxa))) = trim(upper( concat(concat(c.statedescr, c.districtdescr), c.wardname)))
  LEFT JOIN `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` g2 on g2.phuongxa is null
        and trim(upper(concat(g2.tinhtp, g2.quanhuyen))) = trim(upper(concat(c.statedescr, c.districtdescr)))
  LEFT JOIN `staging.d_users` d on 

  (Case 
  when b.slsperid in (
                'MR1682KN',
                'MR2504',
                'MR1232',
                'MR0806',
                'MR2608',
                'MR2111',
                'MR1682',
                'MR2504KN',
                'MR1232KN',
                'MR0806KN',
                'MR2608KN',
                'MR2111KN',
                'MR2993',
                'MR2993KN',
                'MR3038',
                'MR3038KN',
                'MR2608KN',
                'MR2948',
                'MR2948KN',
                'MR2608'
            ) then ifnull(g1.macrs, g2.macrs)
  when b.slsperid ='TMDT_001' and 
   e.slsperid in (
                'MR1682KN',
                'MR2504',
                'MR1232',
                'MR0806',
                'MR2608',
                'MR2111',
                'MR1682',
                'MR2504KN',
                'MR1232KN',
                'MR0806KN',
                'MR2608KN',
                'MR2111KN',
                'MR2993',
                'MR2993KN',
                'MR3038',
                'MR3038KN',
                'MR2608KN',
                'MR2948',
                'MR2948KN',
                'MR2608'
            )
           then ifnull(g1.macrs, g2.macrs)
  when b.slsperid ='TMDT_001' and 
   e.slsperid not in (
                'MR1682KN',
                'MR2504',
                'MR1232',
                'MR0806',
                'MR2608',
                'MR2111',
                'MR1682',
                'MR2504KN',
                'MR1232KN',
                'MR0806KN',
                'MR2608KN',
                'MR2111KN',
                'MR2993',
                'MR2993KN',
                'MR3038',
                'MR3038KN',
                'MR2608KN',
                'MR2948',
                'MR2948KN',
                'MR2608'
            )
           then e.slsperid
  else b.slsperid end) = d.manv

  where date(a.crtd_datetime) >='2024-07-10' and a.crtd_datetime <'2024-07-12 17:30:00'
  and a.ordertype ='IN' and a.status not in ('E','V','X')
  and b.freeitem is false and b.invtid ='T302203003' and c.channel in ('TP','PCL')
  and d.tenquanlytt  in ('Lê Đức Châu','Nguyễn Thanh Tài','Trần Quang Luân','Nguyễn Văn Án','Nguyễn Anh Dũng','Lê Duy Chung','Lương Đức Tiến','Huỳnh Văn Huy')
  group by 1,2,3,4,5,6,7,8
  having qty >=5
),

union_all as (
select * from ke_hoach
 UNION ALL
SELECT * from sales
),

mapping as (
select 
  a.*,
  b.tencvbh as ten_crs,
  b.supid as ma_crm,
  b.tenquanlytt as ten_crm,
  b.rsmid as ma_ncxm,
  b.tenquanlyvung as ten_ncxm,
  Case when b.tenquanlytt in ('Lê Đức Châu','Nguyễn Thanh Tài','Trần Quang Luân','Nguyễn Văn Án','Nguyễn Anh Dũng') then 'Miền Nam'
        when b.tenquanlytt in ('Lê Duy Chung','Lương Đức Tiến','Huỳnh Văn Huy') then 'Miền Bắc'
  else null end as ten_mien,
  c.statedescr,
  c.custname,
  c.address,
  c.channel,
  c.shoptype,
  c.hcotypeid,
  c.classid,
  Case when b.usertypes like '%D%' then 0.5 else 1 end as he_so_nhom,
  current_datetime("+7") as inserted_at
 from union_all a 
 LEFT JOIN `staging.d_users` b on a.ma_crs = b.manv 
 LEFT JOIN `staging.d_master_khachhang` c on a.ma_hco_tren_dms =c.custid
)

select * from mapping 
);

Create or replace table `warehouse.f_mua_hang_sp_online_detail`

copy `staging_temp.f_mua_hang_sp_online_detail_temp`;

END;