CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_khmomoi_duanhub()
BEGIN 
  TRUNCATE TABLE staging_temp.f_khmomoi_duanhub_temp;

 INSERT INTO staging_temp.f_khmomoi_duanhub_temp
 (

-- CREATE OR REPLACE table staging_temp.f_khmomoi_duanhub_temp
-- as

with data_crs as 
(
  with data_tuyen as 
  (
    SELECT 
      thang,    
      custid,
      slsperid,
      crtd_datetime,
      Case when routetype in ('B','D') then 1 else 2 end as routetype,
    FROM `spatial-vision-343005.staging.sync_dms_srm_bytime`
    where delroutedet is false 
  )
  select * 
  from (
         select   *,
         row_number() over (partition by custid,thang order by routetype asc,crtd_datetime desc) as loc  
         from data_tuyen
       )
  where loc =1
)
,

masterdata as 
(
  select 
    distinct (crtd_datetime) as ngaytao,
    custid as makh,
    statecode,
    'khdms' as source, 
    cast(legaldate as date) as thoihanhieulucgdpgpp,
    Case when legaldate is not null then custid else null end as is_co_gpp,
    Case when legaldate is null then custid else null end as is_ko_gpp,

    case when cast (legaldate as date) < CURRENT_DATETIME() then custid else null end as gpp_hethan,

    case when cast (legaldate as date) >= CURRENT_DATETIME() then custid else null end as gpp_conhan,

    taxregnbr,
    Case when taxregnbr is not null then custid else null end as is_co_mst,
    Case when taxregnbr is null then custid else null end as is_ko_mst,

  from `spatial-vision-343005.staging.d_master_khachhang` 
  -- where active = 'Active'
)
,

kh_active as 
(
  with bang2a as 
  (
    select 
      distinct date(created_at) as ngayactive,
      customer_phone as sdtEO,
      customer_code as makhEO,
      follow_phone,
      'EO' as source,
      row_number() over (partition by customer_code order by created_at asc) as loc
    from `spatial-vision-343005.staging.f_crawl_activate_ecom`
  )
  select * 
  from bang2a 
  where loc = 1
)
,

dso_ecom_khachhang as
(
  select 
    DISTINCT
    DATETIME_TRUNC(TIMESTAMP (a.ngaychungtu), MONTH) as thang,
    a.makhdms,
    sum(doanhsocovat) as doanhsocovat,
    sum(doanhsochuavat) as doanhsochuavat
  FROM `spatial-vision-343005.staging.f_sales` a
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_pda_so` b on a.sodondathang = b.ordernbr and a.makhdms = b.custid
  WHERE a.ngaychungtu >= '2023-07-01'
        and (b.slsperid = 'TMDT_001' OR crtd_user = 'TMDT_001') 
        and b.status = 'C'
        and a.tentinhkh in ('Hà Nam','Ninh Bình','Nam Định') 
  group by 1,2
)
,

result as 
(
  select
    e.ngaytao as ngaytao_kh,
    e.makh,
    e.source as source_total_kh,
    e.thoihanhieulucgdpgpp,
    e.taxregnbr,
    e.is_co_gpp,
    e.is_ko_gpp,
    e.is_co_mst,
    e.is_ko_mst,
    e.gpp_hethan,
    e.gpp_conhan,
    b.ngayactive,
    b.makhEO,
    b.sdtEO,
    b.follow_phone,

    d.custname,
    d.branchid,
    d.legaldate,
    d.channel,
    d.shoptype,
    d.statedescr,
    case when d.districtdescr in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' else d.districtdescr end as districtdescr,
    d.wardname,
    d.territorydescr,
    d.hcotypeid,
    d.phone as sdtdms,
    d.terms,
    d.paymentsform,
    d.active,
    d.crtd_user,
    d.market,
    case when m.firstname is null then d.crtd_user else m.firstname end as nguoitao,
    g.doanhsochuavat,
    
    case 
    when d.shoptype in ('PMC','SI23','CTD') THEN 'TP'
    WHEN d.shoptype in ('INS','CLC','PCL') THEN 'HCP'
    WHEN d.shoptype in ('NTC','CCD','CVS') THEN 'MT' ELSE channel end as kenh,

    from masterdata e
    left join kh_active b on e.makh =  b.makhEO
    left join `staging.d_master_khachhang` d on e.makh = d.custid
    left join data_crs f on e.makh = f.custid
    left join dso_ecom_khachhang g on e.makh = g.makhdms
    left join `spatial-vision-343005.staging.d_dms_master_users` m on d.crtd_user = m.username
    where  d.statedescr in ('Hà Nam','Nam Định','Ninh Bình') and (date (ngayactive) >= '2023-07-01' and date (ngayactive) <= '2023-09-30') 
)

select *
from result 
WHERE channel not in ('OTH_LAB','NB') and makh not like 'DS%' and market != '08'
-- group by 1,2
-- order by thang,statedescr asc
  );

Create or replace table `warehouse.f_khmomoi_duanhub`

copy `staging_temp.f_khmomoi_duanhub_temp`;

End;