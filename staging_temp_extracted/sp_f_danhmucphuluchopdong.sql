-- ==========================================================================
-- Routine Name : sp_f_danhmucphuluchopdong
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2025-12-04 09:00:05.399000+00:00
-- Last Altered : 2025-12-04 09:00:05.399000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danhmucphuluchopdong()
BEGIN

-- TRUNCATE TABLE staging_temp.f_danhmucphuluchopdong_temp;
-- INSERT INTO `staging_temp.f_danhmucphuluchopdong_temp`
-- (
Create or replace table `staging_temp.f_danhmucphuluchopdong_temp` as
(

with appendix_all as
(
  with appendix_tanggiamsl as
  (
    select
      contractid,
      invtid,
      adjustqty,
      appendixtype,
      appendixnbr,
      -- STRING_AGG(appendixnbr , " & ") as appendixnbr,
      -- STRING_AGG(descr , " & ") as descr
    from `staging.d_appendixcontractdet`
    where appendixtype in ('AdjUp','AdjDown') and adjustqty != 0
  )
  , d_oricontractdet_pricehist as (
    select * from `staging.d_oricontractdet_pricehist`
    QUALIFY row_number() over(partition by contractid, invtid order by crtd_datetime asc) = 1
  )
  ,
  appendix_dieuchinhgia as
  (
    select
      a.contractid,
      a.invtid,
      a.appendixtype,
      a.appendixnbr,
      b.price as price_goc,
      c.price as price_dieuchinh

    from  `staging.d_appendixcontractdet` a
    left join  `d_oricontractdet_pricehist` b on a.contractid = b.contractid and a.invtid = b.invtid
    left join `staging.d_oricontractdet` c on a.contractid = c.contractid and a.invtid = c.invtid
    where a.appendixtype in ('AdjPrice') and b.price is not null --and a.contractid = 8092 and a.invtid = 'T303102006'
  )
  ,
  appendix_ngaygiahan as
  (
    SELECT
      a.contractid,
      a.appendixtype,
      a.appendixnbr,
      a.invtid,
      b.todate,
      b.gentodate
    from  `staging.d_appendixcontractdet` a
    left join `spatial-vision-343005.staging.d_oricontract` b on a.contractid = b.contractid
    where appendixtype in ('AdjTime')
  )
  ,
  appendix_themsp as
  -- phụ lục này bị đúp
  (
    select
      a.contractid,
      a.appendixtype,
      STRING_AGG(a.appendixnbr , " & ") as appendixnbr,
      STRING_AGG(a.invtid , " & ") as invtid,
      sum(b.qty) as qty
    from `staging.d_appendixcontractdet` a
    left join  `staging.d_oricontractdet` b on a.contractid = b.contractid and a.invtid = b.invtid
    where a.appendixtype = 'AdjInsert'
    group by all
  )
  ,
  result as
  (
    select
      a.contractid,
      case when b.invtid is not null then b.invtid
           when c.invtid is not null then c.invtid
           when d.invtid is not null then d.invtid
           when e.invtid is not null then e.invtid
           else '' end as invtid,
      a.invtid as invtid_,
      trim(a.appendixnbr) as appendixnbr,
      a.appendixtype,
      a.descr,
      a.signeddate,
      a.todate,
      a.crtd_datetime,
      a.lupd_datetime,
      a.note,
      b.adjustqty as sl_tanggiam,
      c.price_goc,
      c.price_dieuchinh,
      d.todate as ngayhieuluc_hd,
      d.gentodate as ngaygiahan,
      e.invtid as sp_bsung,
      e.qty as slsp_bsung

    from `staging.d_appendixcontractdet` a
    left join appendix_tanggiamsl b on a.contractid = b.contractid
                                    and a.invtid = b.invtid
                                    and a.appendixtype = b.appendixtype
                                    and a.appendixnbr = b.appendixnbr
    left join appendix_dieuchinhgia c on a.contractid = c.contractid
                                     and a.invtid = c.invtid
                                     and a.appendixtype = c.appendixtype
                                     and a.appendixnbr = c.appendixnbr
    left join appendix_ngaygiahan d on a.contractid = d.contractid
                                   and a.invtid = d.invtid
                                   and a.appendixtype = d.appendixtype
                                   and a.appendixnbr = d.appendixnbr
    left join appendix_themsp e on a.contractid = e.contractid
                              --  and a.invtid = e.invtid
                               and a.appendixtype = e.appendixtype
                              --  and a.appendixnbr = e.appendixnbr
  )

  select * from result
)
,appendix AS
(
  select
    contractid,
    invtid,
    sum(adjustqty) as adjustqty,
    STRING_AGG(appendixnbr , " & ") as appendixnbr,
    STRING_AGG(descr , " & ") as descr
  from `staging.d_appendixcontractdet`
  where adjustqty != 0 group by 1,2
)
,result as (
SELECT
    f.*,
    h.appendixnbr as so_plhd,
    h.crtd_datetime as ngaytao_plhd,
    h.lupd_datetime as ngaychinhsua_plhd,
    h.descr as nd_plhd,
    h.note,
    h.invtid as sp_plhd,
    h.sl_tanggiam,
    h.price_goc,
    h.price_dieuchinh,
    h.ngaygiahan,
    h.sp_bsung,
    h.slsp_bsung
FROM `spatial-vision-343005.warehouse.f_danhmuchopdong` f
LEFT JOIN appendix_all h on f.contractid = h.contractid and f.invtid = h.invtid
)

select *,
case when note like '%TANG20%' THEN concat(nd_plhd," - ",'Mua tăng 20%') else nd_plhd end as nd_plhd_fix
from result

);

Create or replace table `warehouse.f_danhmucphuluchopdong`

copy `staging_temp.f_danhmucphuluchopdong_temp`;
END;
