CREATE VIEW `spatial-vision-343005.warehouse.view_xuat_data_online`
AS with 
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
    ROW_NUMBER() OVER (PARTITION BY custid ORDER BY routetype ASC, crtd_datetime DESC ) = 1 )
  

  select 
  a.ordernbr,
  a.branchid,
  a.custid  ,
  c.custname,
  a.status,
  a.inserted_at,
  date(a.crtd_datetime) as crtd_datetime,
  IFNULL(e.slsperid,b.slsperid) AS ma_crs,
  d.tencvbh,
  d.supid,
  d.tenquanlytt,
  sum(b.lineqty) as qty,
  min(a.crtd_datetime) as crtd_datetime_min
  -- 0 as ke_hoach
    from `staging.sync_dms_pda_so` a
  LEFT JOIN `staging.sync_dms_pda_sod` b on a.ordernbr =b.ordernbr and a.branchid = b.branchid
  LEFT JOIN `staging.d_master_khachhang` c on a.custid =c.custid
  LEFT JOIN tuyen_dms_moinhat e ON e.custid = a.custid AND b.slsperid ='TMDT_001'
  JOIN tuyen_dms_moinhat f on f.custid = a.custid and IFNULL(e.slsperid,b.slsperid) = f.slsperid
  LEFT JOIN `staging.d_users` d on IFNULL(e.slsperid,b.slsperid) = d.manv
  where date(a.crtd_datetime) >='2024-07-10' and date(a.crtd_datetime) <='2024-07-12'
  and a.ordertype ='IN' and a.status not in ('E','V','X')
  and b.freeitem is false and b.invtid ='T302203003'
  group by all
  having qty >= 5;