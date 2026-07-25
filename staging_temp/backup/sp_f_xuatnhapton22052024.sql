CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_xuatnhapton22052024()
BEGIN 
-- TRUNCATE TABLE staging_temp.f_xuatnhapton_temp;
-- INSERT INTO staging_temp.f_xuatnhapton_temp
(


-- Create or replace table `staging_temp.f_xuatnhapton_temp`
-- as

with ton_1208 as
(
  SELECT 
    trim(makhdms) as makhdms,
    trim(makhcu) as makhcu,
    tenkhachhang,
    trim(sohopdong) as sohopdong,
    trim(masp) as masp,
    soluong,
    soluong_bosungdieuchuyen,
    tongsoluong_kyhd,
    tongsl_ton,
    '1208' as type  
  FROM `spatial-vision-343005.staging.d_xuatnhapton1208` 
  -- group by 1,2,3,4,5,6,7,8,9,10,11,12
  -- where tongsl_ton <> 0
)
,

danhmuchopdong_ins as
(
  WITH appendix AS 
  (
    select 
      contractid, 
      invtid, 
      -- appendixtype,
      sum(adjustqty) as adjustqty, 
      STRING_AGG(appendixnbr , " & ") as appendixnbr, 
      STRING_AGG(descr , " & ") as descr  
    from `staging.d_appendixcontractdet` 
    where adjustqty != 0 and lupd_datetime >= '2023-08-13'
    group by 1,2
  )

  SELECT
    mk.districtdescr,
    mk.channel,
    mk.shoptype,
    k.branchid,--------------- chinh nhánh theo kho
    trim(oc.custid) as custid,
    mk.refcustid,
    mk.custname,
    mk.statedescr,
    mk.territorydescr,
    oc.formname,
    ocd.genslsperid,
    u.firstname,
    e.supid as asm,
    e.tenquanlytt as tenquanlykhuvuc,
    trim(oc.contractnbr) as contractnbr ,
    oc.contractmain,
    oc.contractid,
    oc.crtd_datetime as ngaytao_hd,
    oc.signeddate,
    oc.todate,
    oc.gentodate,
    oc.noticenbr,
    oc.startdate AS informdate,
    oc.investorname,
    oc.startdate,
    oc.exprdate,
    ocd.invtid,
    inv.descr1 as tensanphamviettat,
    inv.descr as tensp,
    ocd.price,
    ocd.orderunit,
    ocd.qty,
    apd.adjustqty,
    apd.appendixnbr,
    apd.descr,
    ifnull(f.price,ocd.price) as giagoc,
    -- apd.appendixtype,
    case when date(gentodate) >= current_date() then 1 else 0 end as active,
    case when date(gentodate) >= '2023-08-12' then 1 else 0 end as active_1208,

  FROM `staging.d_oricontract` oc
  LEFT JOIN `staging.d_oricontractdet` ocd on oc.contractid = ocd.contractid
  LEFT JOIN appendix apd on ocd.contractid = apd.contractid
                        and ocd.invtid = apd.invtid
  LEFT JOIN `staging.d_master_khachhang` mk on oc.custid = mk.custid
  LEFT JOIN `staging.d_dms_master_invtid` inv on ocd.invtid = inv.invtid
  LEFT JOIN `staging.d_dms_master_users` u on ocd.genslsperid = u.username
  LEFT JOIN `spatial-vision-343005.staging.d_users` e on ocd.genslsperid = e.manv
  left join  `staging.d_oricontractdet_pricehist` f  on oc.contractid = f.contractid 
                                                    and ocd.invtid = f.invtid 
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_siteid` k on ocd.siteid = k.siteid
  WHERE channel = 'INS' --and (case when date(gentodate) >= CURRENT_DATE() then 1 else 0 end) = 0
)
, 

ketqua_trungthau as
(
  SELECT 
    a.* , 
    b.descr as tensanpham
  FROM `spatial-vision-343005.staging.d_contractor` a
  left join `spatial-vision-343005.staging.d_dms_master_invtid` b on a.invtid = b.invtid
)
,

hoadon_hopdong_tu1308 as
(
  with detail_hoadon as
  (
    select 
      a.orderdate, 
      a.origordernbr, 
      a.ordertype, 
      b.contractid, 
      trim(b.contractnbr) as contractnbr, 
      a.invcnbr, 
      a.status, 
      a.custid, 
      d.refcustid, 
      d.custname, 
      trim(c.invtid) as invtid, 
      e.descr, 
      case when a.ordertype in ('CO','IR','DP') then -c.lineqty else c.lineqty end as lineqty, 
      c.beforevatprice, 
      c.aftervatprice, 
      case when a.ordertype in ('CO','IR','DP') then -c.aftervatamount else c.aftervatamount end as aftervatamount
    FROM `staging.sync_dms_so` a
    LEFT JOIN `staging.d_oricontract` b on cast(a.contractid as int) = b.contractid
    LEFT JOIN `staging.sync_dms_sod1` c on a.ordernbr = c.ordernbr and a.branchid = c.branchid
    INNER JOIN `staging.d_master_khachhang` d on d.custid = a.custid
                                              and d.channel = 'INS'
    INNER JOIN `staging.d_dms_master_invtid` e on e.invtid = c.invtid

    WHERE a.orderdate > '2023-08-12'  --a.orderdate >= '2021-01-01' --
          and a.status = 'C' 
          and a.ordertype in ('CO','IR', 'IN','DP','UP')
    ORDER BY a.crtd_datetime DESC
  )
  
  select 
    (select max(orderdate) from detail_hoadon) as inserted_at,
    -- extract(year from orderdate) as nam_hoadon,
    a.custid,
    ifnull(a.contractnbr,trim(b.sohopdongdms)) as contractnbr,
    a.invtid,
    sum(a.lineqty) as lineqty,
    avg(a.beforevatprice) as beforevatprice,
    avg(a.aftervatprice) as aftervatprice,
    sum(a.aftervatamount) as aftervatamount,
  from detail_hoadon a
  left join  `spatial-vision-343005.staging.d_manual_gs_xnt_cap_nhat_thong_tin_don_hang` b  on a.custid = b.makhachhangdms 
                                                                                            and a.origordernbr = b.sodonhang 
                                                                                            and a.invcnbr = b.sohoadon 
                                                                                            and a.invtid = b.masp
  group by 1,2,3,4
)
,

hoadon_hopdong_tu2021 as
(
  with detail_hoadon as
  (
    select 
      a.orderdate, 
      extract(year from orderdate) as nam,
      a.origordernbr, 
      a.ordertype, 
      b.contractid, 
      trim(b.contractnbr) as contractnbr, 
      a.invcnbr, 
      a.status, 
      a.custid, 
      d.refcustid, 
      d.custname, 
      trim(c.invtid) as invtid, 
      e.descr, 
      case when a.ordertype in ('CO','IR','DP') then -c.lineqty else c.lineqty end as lineqty, 
      c.beforevatprice, 
      c.aftervatprice, 
      case when a.ordertype in ('CO','IR','DP') then -c.aftervatamount else c.aftervatamount end as aftervatamount
    FROM `staging.sync_dms_so` a
    LEFT JOIN `staging.d_oricontract` b on cast(a.contractid as int) = b.contractid
    LEFT JOIN `staging.sync_dms_sod1` c  on a.ordernbr = c.ordernbr 
                                        and a.branchid = c.branchid
    INNER JOIN `staging.d_master_khachhang` d on d.custid = a.custid
                                              and d.channel = 'INS'
    INNER JOIN `staging.d_dms_master_invtid` e on e.invtid = c.invtid

    WHERE a.orderdate >= '2021-01-01' --
          and a.status = 'C' 
          and a.ordertype in ('CO','IR', 'IN','DP','UP')
    ORDER BY a.crtd_datetime DESC
  )
  
    select
    (select max(orderdate) from detail_hoadon) as inserted_at,
    nam,
    a.custid,
    ifnull(a.contractnbr,trim(b.sohopdongdms)) as contractnbr,
    a.invtid,
    sum(a.lineqty) as lineqty,
    avg(a.beforevatprice) as beforevatprice,
    avg(a.aftervatprice) as aftervatprice,
    sum(a.aftervatamount) as aftervatamount,
    from detail_hoadon a
    left join  `spatial-vision-343005.staging.d_manual_gs_xnt_cap_nhat_thong_tin_don_hang` b  
    on a.custid = b.makhachhangdms 
    and a.origordernbr = b.sodonhang 
    and a.invcnbr = b.sohoadon 
    and a.invtid = b.masp
    group by 1,2,3,4,5
)
,

-- khuvuc as
-- (
--   SELECT 
--     distinct tenkhuvuc,
--     khuvucviettat
--   FROM `spatial-vision-343005.staging.f_sales` 
--   WHERE date(ngaychungtu) >= '2023-08-01'
-- )
-- ,

master_hopdong as
(
  select distinct 
    custid,
    contractnbr,
    invtid, 
  from danhmuchopdong_ins

  union distinct

  select
    makhdms as custid,
    sohopdong as contractnbr,
    masp as invtid,
  from ton_1208  
)
,

results as
(
  select  
    a.*,
    extract (month from (ifnull(gentodate,todate))) as thang_hieuluc_hd,
    b.*except(custid,contractnbr,invtid),
    f.shortterritorydescr as khuvucviettat,
    d.nhomspins,
    e.inserted_at,
    -- e.nam_hoadon,
    case when b.formname = 	'Áp Thầu Không Phân Bổ Số Lượng'	then	'Áp thầu'
         when b.formname in ('Áp Thầu Phân Bổ Số Lượng','Chào Hàng Cạnh Tranh',
                             'Chỉ Định Thầu Rút Gọn','Đấu Thầu Trực Tiếp','Mua Sắm Trực Tiếp') then 'Thầu'
         else '' end as pl_hinhthuc_thau,

    case when a.invtid ='EH126' THEN 20 ELSE d.donvitinhle end as quycachhop,

    round(b.price/(case when a.invtid ='EH126' THEN 20 ELSE d.donvitinhle end),0) as price_le,
    round(b.giagoc/(case when a.invtid ='EH126' THEN 20 ELSE d.donvitinhle end),0) as price_goc_le,

    c.soluong,---- số lượng lẻ của An
    c.soluong_bosungdieuchuyen,---- số lượng bổ sung/điều chuyển của An,
    c.tongsoluong_kyhd,--- tổng số lượng của An
    ifnull(c.tongsoluong_kyhd,0)- ifnull(c.tongsl_ton,0) as sl_ban_den1208,

    ifnull(c.tongsoluong_kyhd,(b.qty * (case when a.invtid ='EH126' THEN 20 ELSE d.donvitinhle end))) as sl_kyhdong_le,

    ifnull(b.adjustqty,0) * (case when a.invtid ='EH126' THEN 20 ELSE d.donvitinhle end) as dieuchuyen_le, --- note : 1/11 anh khả note nhân đvi lẻ

    (b.qty + ifnull(b.adjustqty,0)) as total_qty,

    datetime_diff (cast(ifnull(date(gentodate),date(todate)) as datetime), 
                   current_datetime(), year) as sonam_conthau,               

    datetime_diff (cast(ifnull(date(gentodate),date(todate)) as datetime), 
                   current_datetime(), month) as sothang_conthau,                

    datetime_diff (cast(ifnull(date(gentodate),date(todate)) as datetime), 
                   current_datetime(), day) as songay_conthau,                   

    ifnull(c.tongsl_ton,0) as ton_1208,
    d.descr as tensanpham,
    d.nhomsanpham,
    d.tendonvitinhchan,
    d.tendonvitinhleviethoa,

    (ifnull(e.lineqty,0) * case when a.invtid ='EH126' THEN 20 ELSE d.donvitinhle end) as sl_ban_tu1308,

    ifnull(g.aftervatamount,0) as ban_2021,
    ifnull(g1.aftervatamount,0) as ban_2022,
    ifnull(g2.aftervatamount,0) as ban_2023,
    ifnull(g3.aftervatamount,0) as ban_2024,

  from master_hopdong a
  left join danhmuchopdong_ins b on a.custid = b.custid and a.contractnbr = b.contractnbr and a.invtid = b.invtid
  left join ton_1208 c on a.custid = c.makhdms and a.contractnbr  = c.sohopdong and a.invtid = c.masp
  left join `spatial-vision-343005.staging.d_dms_master_invtid` d on a.invtid = d.invtid
  left join hoadon_hopdong_tu1308 e on a.custid = e.custid and a.contractnbr = e.contractnbr and a.invtid = e.invtid
  left join hoadon_hopdong_tu2021 g on a.custid = g.custid and a.contractnbr = g.contractnbr and a.invtid = g.invtid and g.nam = 2021
  left join hoadon_hopdong_tu2021 g1 on a.custid = g1.custid and a.contractnbr = g1.contractnbr and a.invtid = g1.invtid and g1.nam = 2022
  left join hoadon_hopdong_tu2021 g2 on a.custid = g2.custid and a.contractnbr = g2.contractnbr and a.invtid = g2.invtid and g2.nam = 2023
  left join hoadon_hopdong_tu2021 g3 on a.custid = g3.custid and a.contractnbr = g3.contractnbr and a.invtid = g3.invtid and g3.nam = 2024
  left join `staging.d_master_khachhang` f on a.custid = f.custid

  where a.invtid <> 'SPA'
)
  select *,
    (sl_kyhdong_le + dieuchuyen_le) as total_qty_le,
    (sl_kyhdong_le + dieuchuyen_le) * price_le as thanhtien_hopdong,
    (sl_ban_tu1308 * price_le) as thanhtien_ban_tu1308,

    (sl_ban_den1208 + sl_ban_tu1308) as sl_ban,
    (sl_ban_den1208 + sl_ban_tu1308)* price_le as thanhtien_ban,

    case when (sl_kyhdong_le + dieuchuyen_le) is not null and (sl_kyhdong_le + dieuchuyen_le) <> 0 then (sl_kyhdong_le + dieuchuyen_le) - (sl_ban_den1208 + sl_ban_tu1308) 
         else 0 end as sl_ton,
    case when (sl_kyhdong_le + dieuchuyen_le) is not null and (sl_kyhdong_le + dieuchuyen_le) <> 0  then ((sl_kyhdong_le + dieuchuyen_le) - (sl_ban_den1208 + sl_ban_tu1308)) * price_le 
         else 0 end as thanhtien_ton,

    date_add(date(signeddate), INTERVAL 90 day) as bathang_tungaykyhd,
    case when current_date() >= date_add(date(signeddate), INTERVAL 90 day) then 1 else 0 end as bathang,

    case when (case when current_date() >= date_add(date(signeddate), INTERVAL 90 day) then 1 else 0 end) = 1 
              and (sl_ban_den1208 + sl_ban_tu1308) = 0 then 1 
         else 0 end as hd_chuaphatsinh_ds,
         
    sum(sl_ban_den1208 + sl_ban_tu1308)over(partition by contractid,custid) as loc_hd,

    case when (case when (case when current_date() >= date_add(date(signeddate), INTERVAL 90 day) then 1 else 0 end) = 1 
                    and (sl_ban_den1208 + sl_ban_tu1308) = 0 then 1 
                    else 0 end
              ) = 1       
         and sum(sl_ban_den1208 + sl_ban_tu1308)over(partition by contractid,custid) = 0  then dense_rank()OVER (ORDER BY contractid ASC) 
         else null end as stt

  from results 
  -- where 
  -- -- contractid = 8213 and invtid ='EH086'
  -- contractid = 6345 and invtid ='EH120'

);

Create or replace table `warehouse.f_xuatnhapton`

copy `staging_temp.f_xuatnhapton_temp`;

End;