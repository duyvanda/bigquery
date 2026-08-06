-- ==========================================================================
-- Routine Name : sp_f_xuatnhapton
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-07-13 09:06:26.630000+00:00
-- Last Altered : 2026-07-13 09:06:26.630000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_xuatnhapton()
BEGIN

Create or replace table `staging_temp.f_xuatnhapton_temp`
as
(

-- TRUNCATE TABLE staging_temp.f_xuatnhapton_temp;
-- INSERT INTO staging_temp.f_xuatnhapton_temp
-- (
WITH START_SQL AS (SELECT NULL) --- IGNORE DONG NAY
, _appendix AS
  (
    select
      contractid,
      invtid,
      sum(adjustqty) as adjustqty,
      STRING_AGG(appendixnbr , " & ") as appendixnbr,
      STRING_AGG(descr , " & ") as descr
    from `staging.d_appendixcontractdet`
    where adjustqty != 0 and lupd_datetime >= '2023-08-13'
    group by 1,2
  )
, _first_price as (

select contractid, invtid, price, row_number() over ( partition by contractid, invtid order by crtd_datetime asc)  as row_count
from staging.d_oricontractdet_pricehist
QUALIFY row_number() over ( partition by contractid, invtid order by crtd_datetime asc) = 1

)
, _ton_1208 as
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
)
, danhmuchopdong_ins as (

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
    trim(oc.contractnbr) as contractnbr,
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
    oc.contractorid,
    ocd.invtid,
    inv.descr1 as tensanphamviettat,
    inv.descr as tensp,
    ocd.price,
    ocd.orderunit,
    ocd.qty, -- sl ký hợp đồng
    apd.adjustqty, -- sl điều chỉnh
    apd.appendixnbr, -- số phụ lục
    apd.descr, -- note phụ lục
    ifnull(f.price,ocd.price) as giagoc,
    case when date(gentodate) >= current_date() then 1 else 0 end as active,
    case when date(gentodate) >= '2023-08-12' then 1 else 0 end as active_1208,
    --mapping ton kho 12 08, ton kho tu file excel
    t.soluong as so_luong_1208,---- số lượng lẻ của An
    t.soluong_bosungdieuchuyen as so_luong_bo_sung_dieu_chuyen_1208, ---- số lượng bổ sung/điều chuyển của An,
    t.tongsoluong_kyhd as tong_so_luong_ky_hd_1208, --- tổng số lượng của An
    t.tongsl_ton as tong_sl_ton_1208,
  FROM `staging.d_oricontract` oc
  LEFT JOIN `staging.d_oricontractdet` ocd on oc.contractid = ocd.contractid
  LEFT JOIN _appendix apd on ocd.contractid = apd.contractid and ocd.invtid = apd.invtid
  LEFT JOIN `staging.d_master_khachhang` mk on oc.custid = mk.custid
  LEFT JOIN `staging.d_dms_master_invtid` inv on ocd.invtid = inv.invtid
  LEFT JOIN `staging.d_dms_master_users` u on ocd.genslsperid = u.username
  LEFT JOIN `spatial-vision-343005.staging.d_users` e on ocd.genslsperid = e.manv
  left join  _first_price f  on oc.contractid = f.contractid and ocd.invtid = f.invtid
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_siteid` k on ocd.siteid = k.siteid
  LEFT JOIN `spatial-vision-343005.staging.d_xuatnhapton1208` t on ocd.contractid = t.contractid and ocd.invtid = t.masp
  WHERE channel IN ('INS','CLC') --and (case when date(gentodate) >= CURRENT_DATE() then 1 else 0 end) = 0
)

--select distinct formname from danhmuchopdong_ins
, hoadon_hopdong_tu1308 as
(
select ifnull(trim(c.contractnbr), sohopdongdms ) as contractnbr, makhdms as custid, masanpham as invtid, sum(soluong) as lineqty, max(a.inserted_at) as inserted_at from staging.f_sales a left join
`staging.sync_dms_so` b on a.mahd = b.ordernbr and a.macongtycn = b.branchid
LEFT JOIN `staging.d_oricontract` c on cast(b.contractid as int) = c.contractid
left join  `spatial-vision-343005.staging.d_manual_gs_xnt_cap_nhat_thong_tin_don_hang`
  d  on a.makhdms = d.makhachhangdms
  and a.sodondathang = d.sodonhang
  and a.hoadon = d.sohoadon
  and a.masanpham = d.masp
where c.contractnbr is not null and a.ngaychungtu> '2023-08-12' and a.makenhkh in ('INS','CLC') and hoadon not like '%GK%'
group by all

)
, hoadon_hopdong_tu2021 as
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
                                              and d.channel IN ('INS','CLC')
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
, results as
(
  select
    a.*,
    extract (month from (ifnull(gentodate,todate))) as thang_hieuluc_hd,
    -- b.*except(custid,contractnbr,invtid),
    f.shortterritorydescr as khuvucviettat,
    d.nhomspins,
    e.inserted_at,
    -- e.nam_hoadon,
CASE
        -- 1. "Thầu": Tất cả các hình thức thầu trừ "Trực tiếp" (dựa theo code bên dưới, contractorid = '01' là Trực tiếp)
        WHEN a.contractorid != '01' THEN 'Thầu'
        -- 2. "Áp thầu phân bổ có số lượng": Hình thức thầu là Trực tiếp VÀ Hình thức hợp đồng tương ứng
        WHEN a.contractorid = '01'
             AND LOWER(TRIM(a.formname)) IN ('chỉ định thầu rút gọn', 'đấu thầu trực tiếp', 'hdtm số lượng', 'hợp đồng có số lượng')
             THEN 'Áp thầu phân bổ có số lượng'
        -- 3. "Áp thầu phân bổ không số lượng": Hình thức thầu là Trực tiếp VÀ Hình thức hợp đồng tương ứng
        WHEN a.contractorid = '01'
             AND LOWER(TRIM(a.formname)) IN ('hdtm không số lượng', 'hợp đồng không số lượng')
             THEN 'Áp thầu phân bổ không số lượng'
        -- Các trường hợp còn lại không xác định (nếu có)
        ELSE ''
    END AS pl_hinhthuc_thau,
    IFNULL(d.donvitinhle,1) as quycachhop,
    round(a.price/IFNULL(d.donvitinhle,1),0) as price_le,
    round(a.giagoc/IFNULL(d.donvitinhle,1),0) as price_goc_le,
    ifnull(a.tong_so_luong_ky_hd_1208,0)- ifnull(a.tong_sl_ton_1208,0) as sl_ban_den1208,
    ifnull(a.tong_so_luong_ky_hd_1208,(a.qty * IFNULL(d.donvitinhle,1) )) as sl_kyhdong_le,
    ifnull(a.adjustqty,0) * IFNULL(d.donvitinhle,1) as dieuchuyen_le, --- note : 1/11 anh khả note nhân đvi lẻ

    (a.qty + ifnull(a.adjustqty,0)) as total_qty,
    datetime_diff (cast(ifnull(date(gentodate),date(todate)) as datetime),
                   current_datetime(), year) as sonam_conthau,
    datetime_diff (cast(ifnull(date(gentodate),date(todate)) as datetime),
                   current_datetime(), month) as sothang_conthau,
    datetime_diff (cast(ifnull(date(gentodate),date(todate)) as datetime),
                   current_datetime(), day) as songay_conthau,
    ifnull(a.tong_sl_ton_1208,0) as ton_1208,
    d.descr as tensanpham,
    d.nhomsanpham,
    d.tendonvitinhchan,
    d.tendonvitinhleviethoa,
    ifnull(e.lineqty,0) * IFNULL(d.donvitinhle,1)  as sl_ban_tu1308,
    ifnull(g.aftervatamount,0) as ban_2021,
    ifnull(g1.aftervatamount,0) as ban_2022,
    ifnull(g2.aftervatamount,0) as ban_2023,
    ifnull(g3.aftervatamount,0) as ban_2024,
    ifnull(g4.aftervatamount,0) as ban_2025,
    ifnull(g5.aftervatamount,0) as ban_2026,
    ifnull(g2.lineqty,0) as sl_ban_2023,
    ifnull(g3.lineqty,0) as sl_ban_2024,
    ifnull(g4.lineqty,0) as sl_ban_2025,
    ifnull(g5.lineqty,0) as sl_ban_2026,
    CASE
      WHEN a.contractorid = '01' THEN 'Trực tiếp'
      WHEN a.contractorid = '02' THEN 'MSTT'
      WHEN a.contractorid = '03' THEN 'CĐT Rút gọn'
      WHEN a.contractorid = '04' THEN 'Chào hàng cạnh tranh'
      WHEN a.contractorid = '05' THEN 'Chào giá trực tuyến'
      WHEN a.contractorid = '06' THEN 'Chỉ định thầu sau sáp nhập'
      WHEN a.contractorid = '07' THEN 'Mua sắm trực tuyến'
      ELSE NULL
      END as hinh_thuc_thau
  from danhmuchopdong_ins a
  -- left join danhmuchopdong_ins b on a.custid = b.custid and a.contractnbr = b.contractnbr and a.invtid = b.invtid
  -- left join _ton_1208 c on a.custid = c.makhdms and a.contractnbr  = c.sohopdong and a.invtid = c.masp
  left join `spatial-vision-343005.staging.d_dms_master_invtid` d on a.invtid = d.invtid

  left join hoadon_hopdong_tu1308 e on a.custid = e.custid and a.contractnbr = e.contractnbr and a.invtid = e.invtid
  left join hoadon_hopdong_tu2021 g on a.custid = g.custid and a.contractnbr = g.contractnbr and a.invtid = g.invtid and g.nam = 2021
  left join hoadon_hopdong_tu2021 g1 on a.custid = g1.custid and a.contractnbr = g1.contractnbr and a.invtid = g1.invtid and g1.nam = 2022
  left join hoadon_hopdong_tu2021 g2 on a.custid = g2.custid and a.contractnbr = g2.contractnbr and a.invtid = g2.invtid and g2.nam = 2023
  left join hoadon_hopdong_tu2021 g3 on a.custid = g3.custid and a.contractnbr = g3.contractnbr and a.invtid = g3.invtid and g3.nam = 2024
  left join hoadon_hopdong_tu2021 g4 on a.custid = g4.custid and a.contractnbr = g4.contractnbr and a.invtid = g4.invtid and g4.nam = 2025
  left join hoadon_hopdong_tu2021 g5 on a.custid = g5.custid and a.contractnbr = g5.contractnbr and a.invtid = g5.invtid and g5.nam = 2026
  left join `staging.d_master_khachhang` f on a.custid = f.custid
  -- left join `spatial-vision-343005.warehouse.sp_f_baocao_ketquatrungthau` h on a.custid = h.unitcode and a.noticenbr = h.noticenbr and a.invtid = h.invtid
  where a.invtid <> 'SPA'
)
, thong_tin_tbmtcode AS(
  SELECT DISTINCT
  noticenbr,
  --unitcode,
  tbmtcode,
  invtid
FROM `spatial-vision-343005.warehouse.sp_f_baocao_ketquatrungthau`
where date(exprdate) >= CURRENT_DATE
AND tbmtcode is not null
)

  select
    a.*,
    b.tbmtcode,
    (sl_kyhdong_le + dieuchuyen_le) as total_qty_le,
    (sl_kyhdong_le + dieuchuyen_le) * price_le as thanhtien_hopdong,
    (sl_ban_tu1308 * price_le) as thanhtien_ban_tu1308,
    (sl_ban_den1208 + sl_ban_tu1308) as sl_ban,
    (sl_ban_den1208 + sl_ban_tu1308)* price_le as thanhtien_ban,
    case
    when (sl_kyhdong_le + dieuchuyen_le) - (sl_ban_den1208 + sl_ban_tu1308) <= 0 then 0
    when pl_hinhthuc_thau = 'Áp thầu phân bổ không số lượng' Then 0
    else (sl_kyhdong_le + dieuchuyen_le) - (sl_ban_den1208 + sl_ban_tu1308)
    end as sl_ton,
    case
    when (sl_kyhdong_le + dieuchuyen_le) - (sl_ban_den1208 + sl_ban_tu1308) <= 0 then 0
    when pl_hinhthuc_thau = 'Áp thầu phân bổ không số lượng' Then 0
    else ( (sl_kyhdong_le + dieuchuyen_le) - (sl_ban_den1208 + sl_ban_tu1308) ) * price_le
    end as thanhtien_ton,
    -- ((sl_kyhdong_le + dieuchuyen_le) - (sl_ban_den1208 + sl_ban_tu1308)) * price_le as thanhtien_ton,
    date_add(date(signeddate), INTERVAL 90 day) as ba_thang_tu_ngay_ky_hd,
    case when current_date() >= date_add(date(signeddate), INTERVAL 90 day) then 1 else 0 end as check_da_qua_3_thang,
    case when (case when current_date() >= date_add(date(signeddate), INTERVAL 90 day) then 1 else 0 end) = 1
              and (sl_ban_den1208 + sl_ban_tu1308) = 0 then 1
         else 0 end as check_hd_chua_phat_sinh_ds_3_thang,
    sum(sl_ban_den1208 + sl_ban_tu1308)over(partition by contractid,custid) as check_sl_ban_tong_hd,
    case when (case when (case when current_date() >= date_add(date(signeddate), INTERVAL 90 day) then 1 else 0 end) = 1
                    and (sl_ban_den1208 + sl_ban_tu1308) = 0 then 1
                    else 0 end
              ) = 1
         and sum(sl_ban_den1208 + sl_ban_tu1308)over(partition by contractid,custid) = 0  then dense_rank()OVER (ORDER BY contractid ASC)
         else null end as stt

  from results a
  left join thong_tin_tbmtcode b ON b.noticenbr = a.noticenbr AND b.invtid = a.invtid --AND b.unitcode = a.custid

);

Create or replace table `warehouse.f_xuatnhapton`

copy `staging_temp.f_xuatnhapton_temp`;

End;
