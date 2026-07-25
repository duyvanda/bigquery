CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_congno_rawdata_mds()
BEGIN


CREATE TEMP TABLE `f_congno_rawdata_mds` AS

(

with dms_checkin as
( 
  with order_checkin_final as 
  (
  -- lay tat ca checkin theo dh va id checkin
    with order_checkin as
    (
      SELECT 
        branchid,
        slsperid,
        deordernbr,
        de_updatetime,
        numbercico,
        inserted_at
      FROM `spatial-vision-343005.staging.sync_dms_decheckin` 
    )
    ,
    -- lay checkin theo dh va thoi gian gan nhat
    max_order_checkin as
    (
      select
      branchid,
      slsperid,
      deordernbr,
      max (de_updatetime) as max_de_updatetime
      from `spatial-vision-343005.staging.sync_dms_decheckin` 
      group by 1,2,3
    )
    -- join 2 cái lại để lấy id checkin (numbercico) theo dh & thoi gian lớn nhất => ra order_checkin_final
    select a.* 
    from order_checkin a
    join max_order_checkin b on a.branchid = b.branchid 
                            and a.slsperid = b.slsperid 
                            and a.deordernbr =b.deordernbr 
                            and a.de_updatetime = b. max_de_updatetime
    )
    ,
    -- lấy data checkin theo tọa độ, KH, loại checkin
    data_checkin as
    (
      select 
        branchid,
        slsperid,
        lat,
        lng,
        custid,
        typ,
        checktype,
        numbercico,
        updatetime 
      from `spatial-vision-343005.staging.d_checkin`
      where updatetime >='2023-01-01'
    )
    ,
    -- lấy data checkin chi tiết note, descr, distance, checkintype, imagefilename
    final_checkin as 
    (
      select *
      from `spatial-vision-343005.staging.sync_dms_oc`
    )
    -- kq dms_checkin
  select 
    a.slsperid,
    a.custid,
    a.visitdate,
    a.noteid,
    a.branchid,
    a.note,
    a.descr,
    a.salesid,
    a.distance,
    a.checkintype,
    a.imagefilename,
    a.inserted_at,
    b.typ AS checkin, b.lat, b.lng, b.updatetime as thoigiancheckin,
    c.typ AS checkout, c.updatetime as thoigiancheckout,
    d.deordernbr 
  from `spatial-vision-343005.staging.sync_dms_oc`  a 
  LEFT JOIN data_checkin b on a.branchid = b.branchid and a.slsperid = b.slsperid and a.custid = b.custid and a.salesid = b.numbercico and b.checktype = 'IO'
  LEFT JOIN data_checkin c on a.branchid = c.branchid and a.slsperid = c.slsperid and a.custid = c.custid and a.salesid = c.numbercico and c.checktype = '0O'
  LEFT JOIN order_checkin_final d on a.branchid = d.branchid and a.slsperid = d.slsperid and a.salesid = d.numbercico and a.checkintype = 'Giao Hàng'
  where a.visitdate >= '2025-01-01'
)
,

-- GIẢI TRÌNH
giaitrinhcongno as
(
  select 
    *,
    row_number() over (partition by madh order by ngay desc) as loc
  from `spatial-vision-343005.staging.d_giaitrinh_mds`
  order by madh desc
)
,


-- lấy ra trạng thái giao hàng và ngày giao hàng
leadtime1 as
(
  select 
    branchid,
    ordernbr,
    status,
    delivery_date, 
    lupd_datetime,
    slsperid, 
    row_number() over (partition by concat(branchid,ordernbr) order by sequence desc) as loc 
  from `spatial-vision-343005.staging.sync_dms_dv` where crtd_datetime >='2024-01-01'
)
,

leadtime as
(
  select *
  from leadtime1
  where loc = 1
)

, mbb as (
  select distinct branchid, invcnbr, 'gach_no' as action from `staging.d_mb_transaction`
)
 
  SELECT 
    a.branchid,
    c.branchid as chi_nhanh_kh,
    a.Ordnbr,
    a.custid, 
    c.custname,
    a.slsperid,
    b.tencvbh,
    b.tenquanlytt,
    b.tenquanlykhuvuc,
    b.tenquanlyvung,
    a.dateoforder as ngaydatdon,
    c.channel,
    c.shoptype,
    c.statedescr,
    a.DocType,
    a.terms,
    a.InvcNbr,
    a.InvcNote,
    k.descr as thoihanthanhtoan,
    
    case 
    
    when a.paymentsform = 'B' then 'Tiền Mặt'
    when a.paymentsform = 'C' then 'Tiền Mặt/Chuyển Khoản'
    else 'Khác'
    end as paymentsform,
    c.hcotypeid,
    a.so_du_chungtu,
    a.sotien_da_thanhtoan,
    GREATEST( 
    IFNULL(date(a.debt_appointment_date),date('1900-01-01') )  , 
    IFNULL(date(a.deli_appointment_date), date('1900-01-01') ) , 
    IFNULL(date(a.duedate), date('1900-01-01') )
    ) as duedate,
    a.inserted_at as inserted_at,
    concat (a.InvcNote,a.InvcNbr) as noi_hd,
    e.batnbr,
    case when f.slsperid is null then a.slsperid else f.slsperid end as ma_nvgh,
    case when g.tencvbh is null then b.tencvbh else g.tencvbh end as nvgh,
    case when g.supid is null then b.supid else g.supid end as manv_sup_gh,
    case when g.tenquanlytt is null then b.tenquanlytt else g.tenquanlytt end as sup_gh,
    case when g.asm is null then b.asm else g.asm end as manv_mgr_gh,
    case when g.tenquanlykhuvuc is null then b.tenquanlykhuvuc else g.tenquanlykhuvuc end as mgr_gh,
    case when g.rsmid is null then b.rsmid else g.rsmid end as manv_dir_gh,
    case when g.tenquanlyvung is null then b.tenquanlyvung else g.tenquanlyvung end as dir_gh,
    h.status,
    h.delivery_date as ngaygiaohang,
    a.debt_appointment_date as ngay_hen_tra_no_cua_crscx,
    a.deli_appointment_date as ngay_hen_giao_hang,
    h.lupd_datetime as thoigiancapnhattrangthai,
    j.tram,
    case when h.status = 'A' then 'Đã xác nhận'
         when h.status = 'C' then 'Đã giao hàng'
         when h.status = 'D' then 'KH không nhận'
         when h.status = 'H' then 'Chưa xác nhận'
         when h.status = 'R' then 'Từ chối giao hàng'
         when h.status = 'E' then 'Không tiếp tục giao hàng' 
         when h.status is null then 'Chưa xác nhận' else h.status end as trangthaigiaohang,

        CASE
        WHEN c.channel IN ('TP','PCL','MT','CLC','INS') 
              AND a.paymentsform IN ('B', 'C')
        THEN 'MDS'

        WHEN c.channel IN ('MT') 
              AND a.paymentsform IN ('B', 'C') 
              AND k.descr IN (
                  'Thu tiền ngay có VP PN', 
                  'Thu tiền ngay không có VP PN'
              ) 
        THEN 'MDS'

        WHEN c.channel IN ('INS') 
        THEN 'INS'

        ELSE 'CS'
        END AS phutrachno,

    a.paymentmethod_deli,
    m.action as mbb_action,

  bb.note,
  bb.distance,
  bb.descr, 
  cc.ngay,
  cc.giaitrinh,
  -- cc.sdt,
  dd.ngay as ngaytruoc,
  dd.giaitrinh as giaitrinhngaytruoc
    
  FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` a
  LEFT JOIN staging.d_manual_terms_detail k on k.termsid = a.terms
  LEFT JOIN `staging.d_users` b on a.slsperid = b.manv
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` c on a.custid = c.custid 
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_ibd` e on a.BranchID = e.branchid and a.Ordnbr = e.ordernbr
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_ib` f on e.branchid = f.branchid and e.batnbr =  f.batnbr
  LEFT JOIN `staging.d_users` g on g.manv = f.slsperid
  LEFT JOIN leadtime h on a.Ordnbr = h.ordernbr and a.BranchID = h.branchid 
  LEFT JOIN `spatial-vision-343005.staging.d_tinh`  j on c.statedescr = j.tinh
  LEFT JOIN `mbb` m on m.branchid = a.branchid and m.invcnbr = a.InvcNbr

  LEFT JOIN dms_checkin bb on a.custid = bb.custid and a.branchid = bb.branchid and a.slsperid = bb.slsperid and a.Ordnbr = bb.deordernbr
  LEFT JOIN giaitrinhcongno cc on a.Ordnbr = cc.madh and cc.loc = 1
  LEFT JOIN giaitrinhcongno dd on a.Ordnbr = dd.madh and dd.loc = 2

);


CREATE TEMP TABLE `result` AS
(
  WITH latest_debtdet AS (
  SELECT 
    custid, 
    branchid, 
    ordernbr, 
    slsperid,
    CONCAT(invcnote, invcnbr) AS noi_hd_key -- Gộp thành 1 field để đủ quota 5 field
  FROM `spatial-vision-343005.staging.sync_dms_debtdet`
  -- Vẫn dùng các cột gốc để định danh dòng duy nhất và lấy dòng mới nhất
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY custid, branchid, ordernbr, invcnote, invcnbr 
    ORDER BY crtd_datetime DESC
  ) = 1
  )
  , t1 as (
  select 
    aa.*,
    ff.slsperid as manv_phanbono,
    gg.tencvbh as tennv_phanbono,
    gg.supid as supid_phanbono,
    case when DATE_DIFF(CURRENT_DATE(), aa.duedate, DAY) >= 0 then 'Nợ đến hạn' else 'Chưa đến hạn' end as no_toi_han
  FROM `f_congno_rawdata_mds` aa
  LEFT JOIN `spatial-vision-343005.staging.d_users` ee on aa.ma_nvgh = ee.manv
  LEFT JOIN `latest_debtdet` ff
  on aa.custid = ff.custid
  and aa.branchid = ff.branchid
  and aa.Ordnbr = ff.ordernbr
  and aa.noi_hd = ff.noi_hd_key
  LEFT JOIN `spatial-vision-343005.staging.d_users` gg on ff.slsperid  = gg.manv
  where phutrachno = 'MDS'
  and Ordnbr NOT IN ('DL3-0426-00988','DL3-0526-00026','DL3-0526-00027')
  )
  select *
  from t1 where abs(so_du_chungtu) > 1000
);

Create or replace table `warehouse.f_congno_rawdata_mds` 
copy `result`;


Create or replace table `warehouse.f_congno_rawdata_mds_raw_w_phu_trach_no`
copy `f_congno_rawdata_mds`;



End;