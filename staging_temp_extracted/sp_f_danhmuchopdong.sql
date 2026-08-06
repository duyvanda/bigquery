-- ==========================================================================
-- Routine Name : sp_f_danhmuchopdong
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-07-27 03:11:14.317000+00:00
-- Last Altered : 2026-07-27 03:11:14.317000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danhmuchopdong()
BEGIN

-- TRUNCATE TABLE staging_temp.f_danhmuchopdong_temp;
-- INSERT INTO `staging_temp.f_danhmuchopdong_temp`
-- (
Create or replace table `staging_temp.f_danhmuchopdong_temp` as
(

WITH appendix AS
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
,
result_dmhd as
(
  SELECT
    mk.districtdescr,
    mk.shoptype,
    ifnull(dc.branchid,k.branchid) as branchid,-- chinh nhánh theo kho
    oc.custid,
    mk.custname,
    mk.pubcustname,
    mk.statedescr,
    mk.shortterritorydescr,
    mk.channel,
    oc.terms,
    mk.pubcustid,
    oc.formname,
    ocd.genslsperid,
    o.supid,
    o.tenquanlytt,
    u.firstname,
    trim(oc.contractnbr) as contractnbr,
    oc.contractmain,
    oc.contractid,
    oc.crtd_datetime as ngaytao_hd,
    oc.signeddate,
    oc.todate,
    oc.gentodate,
    ifnull(ocd.noticenbr, oc.noticenbr) as noticenbr,
    oc.startdate AS informdate,
    ifnull(ocd.investorname, oc.investorname) as investorname,
    -- ocd.investorname,
    ifnull(ocd.startdate, oc.startdate) as startdate,
    -- ocd.startdate,
    ifnull(ocd.exprdate, oc.exprdate) as exprdate,
    -- ocd.exprdate,
    ocd.inserted_at,
    ocd.invtid,
    inv.descr1 as tensanphamviettat,
    inv.descr as tensp,
    ocd.price,
    case when (ocd.price/(case when ocd.invtid ='EH126' THEN 20 ELSE inv.donvitinhle end)) in (1,0) then null
         else (ocd.price/(case when ocd.invtid ='EH126' THEN 20 ELSE inv.donvitinhle end))
         end as price_le ,
    ocd.orderunit,
    ocd.unit,
    -- ocd.note as ghichu_plhd,
    ocd.qty,
    ocd.qty * (case when ocd.invtid ='EH126' THEN 20 ELSE inv.donvitinhle end) as qty_le,
    apd.adjustqty * (case when ocd.invtid ='EH126' THEN 20 ELSE inv.donvitinhle end) as adjustqty_le,
    ((ocd.qty + ifnull(apd.adjustqty,0)) * (case when ocd.invtid ='EH126' THEN 20 ELSE inv.donvitinhle end) ) as total_qty_le,
    ((ocd.qty + ifnull(apd.adjustqty,0)) * ocd.price) as thanhtien_hopdong,
    apd.appendixnbr,
    apd.descr,
    case when date(ifnull(gentodate,oc.todate)) >= CURRENT_DATE() then 1 else 0 end as active,
    CASE
      WHEN DATE_DIFF(CURRENT_DATE(), DATE(IFNULL(gentodate, oc.todate)), DAY) <= 365
      THEN 1
      ELSE 0
    END AS active_within_x_days,
    --h.appendixnbr as so_plhd,
    --h.crtd_datetime as ngaytao_plhd,
    --h.lupd_datetime as ngaychinhsua_plhd,
    --h.descr as nd_plhd,
    --h.note,
    -- h.invtid as sp_plhd,
    -- h.sl_tanggiam,
    -- h.price_goc,
    -- h.price_dieuchinh,
    -- h.ngaygiahan,
    -- h.sp_bsung,
    -- h.slsp_bsung,
    inv.tendonvitinhleviethoa,
    inv.donvitinhle,
    -- case when mk.shortterritorydescr in ('BTB') then 'Lương Tấn Khả'
    --      when mk.shortterritorydescr in ('DB1','DB2','DN1','DN2','HN','TB') then 'Lê Thị Ngọc Anh'
    --      when mk.shortterritorydescr in ('HCM','MK1','MK2') then 'Trần Tường Ngân'
    --      when mk.shortterritorydescr in ('MD1','MD2','NTB') then 'Lương Thị Mỹ Nhàn'
    --      else '' end as phutrach_chungtu,
    ti.ten_nv_phu_trach_chung_tu as phutrach_chungtu,
    ti.ma_nv_phu_trach_chung_tu as ma_phutrach_chungtu,
    -- case when mk.shortterritorydescr in ('BTB') then 'MR1432'
    --      when mk.shortterritorydescr in ('DB1','DB2','DN1','DN2','HN','TB') then 'MR1132'
    --      when mk.shortterritorydescr in ('HCM','MK1','MK2') then 'MR2643'
    --      when mk.shortterritorydescr in ('MD1','MD2','NTB') then 'MR2956'
    --      else '' end as ma_phutrach_chungtu
  FROM `staging.d_oricontract` oc
  LEFT JOIN `staging.d_oricontractdet` ocd ON oc.contractid = ocd.contractid
  LEFT JOIN appendix apd ON ocd.contractid = apd.contractid
                        AND ocd.invtid = apd.invtid
  LEFT JOIN `staging.d_master_khachhang` mk ON oc.custid = mk.custid
  LEFT JOIN `staging.d_dms_master_invtid` inv ON ocd.invtid = inv.invtid
  LEFT JOIN `staging.d_dms_master_users` u ON ocd.genslsperid = u.username
  LEFT JOIN `spatial-vision-343005.staging.d_users` o on ocd.genslsperid = o.manv
  --LEFT JOIN appendix_all h on oc.contractid = h.contractid and ocd.invtid = h.invtid
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_siteid` k ON ocd.siteid = k.siteid
  LEFT JOIN `spatial-vision-343005.staging.d_manual_gs_cat_nhap_thong_tin_hd` dc on cast(dc.contractid as int) = oc.contractid
  --LEFT JOIN `staging.d_hr_dsns` hr on staging.map_phu_trach_chung_tu_team_thau(mk.shortterritorydescr) = hr.msnvcsmmoi
  LEFT JOIN `staging.d_tinh` ti on ti.tinh = mk.statedescr
  WHERE
  true
  -- and ocd.invtid <> 'SPA'
  and mk.channel not in ('OTH_LAB','NB')-- and
)
,
result as
(
  SELECT * FROM result_dmhd
  UNION ALL

  SELECT
    b.districtdescr,
    b.shoptype,
    a.chinhanh as branchid,
    trim(a.makhdms) as custid,
    trim(b.custname) as custname,
    b.pubcustname,
    b.statedescr,
    b.shortterritorydescr,
    b.channel,
    b.terms,
    b.pubcustid,
    c.formname,
    c.genslsperid,
    c.supid,
    c.tenquanlytt,
    c.firstname,
    trim(sohddms) as contractnbr,
    trim(sohdchinh) as contractmain,
    c.contractid,
    c.ngaytao_hd,
    c.signeddate,
    c.todate,
    c.gentodate,
    c.noticenbr,
    c.informdate,
    c.investorname,
    c.startdate,
    c.exprdate,
    c.inserted_at,
    null as invtid,
    null as tensanphamviettat,
    null as tensp,
    null as price,
    null as  price_le,
    null as orderunit,
    null as unit,
    null as qty,
    null as qty_le,
    null as adjustqty_le,
    null as total_qty_le,
    null as thanhtien_hopdong,
    soplhd as appendixnbr,
    noidungplhd as descr,
    c.active,
    c.active_within_x_days,
    --soplhd as so_plhd,
    --ngaytaoplhd as ngaytao_plhd,
    --ngaychinhsuaplhd as ngaychinhsua_plhd,
    -- TIMESTAMP(PARSE_DATE('%d/%m/%Y', ngaytaoplhd)) as ngaytao_plhd,
    -- TIMESTAMP(PARSE_DATE('%d/%m/%Y', ngaychinhsuaplhd)) as ngaychinhsua_plhd,
    --noidungplhd as nd_plhd,
    --null as note,
    -- null as sp_plhd,
    -- null as sl_tanggiam,
    -- null as price_goc,
    -- null as price_dieuchinh,
    -- null as ngaygiahan,
    -- null as sp_bsung,
    -- null as slsp_bsung,
    null as tendonvitinhleviethoa,
    null as donvitinhle,
    c.phutrach_chungtu,
    c.ma_phutrach_chungtu
  FROM `spatial-vision-343005.staging.d_manual_gs_cat_nhap_thong_tin_phu_luc_hd` a
  LEFT JOIN `staging.d_master_khachhang` b on trim(a.makhdms) = b.custid
  LEFT JOIN ( select distinct *except(invtid,tensanphamviettat,tensp,price,price_le,orderunit,qty,qty_le,adjustqty_le,total_qty_le,thanhtien_hopdong)
  --sp_plhd,sl_tanggiam,price_goc,price_dieuchinh,ngaygiahan,sp_bsung,slsp_bsung)
  from result_dmhd) c on a.makhdms = c.custid and trim(a.sohddms) = c.contractnbr

)

select *,
--case when note like '%TANG20%' THEN concat(nd_plhd," - ",'Mua tăng 20%') else nd_plhd end as nd_plhd_fix
from result

);

Create or replace table `warehouse.f_danhmuchopdong`

copy `staging_temp.f_danhmuchopdong_temp`;
END;
