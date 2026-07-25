CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_congno_rawdata_cs_tm()
BEGIN 
-- TRUNCATE TABLE staging_temp.f_congno_rawdata_cs_tm_temp;
-- INSERT INTO staging_temp.f_congno_rawdata_cs_tm_temp
-- (

CREATE OR REPLACE table staging_temp.f_congno_rawdata_cs_tm_temp as

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
      b.typ AS checkin, b.lat, b. lng, b.updatetime as thoigiancheckin,
      c.typ AS checkout, c.updatetime as thoigiancheckout,
      d.deordernbr 
    from final_checkin  a 
    LEFT JOIN data_checkin b on a.branchid = b.branchid 
                            and a.slsperid = b.slsperid 
                            and a.custid = b.custid 
                            and a.salesid = b.numbercico 
                            and b.checktype = 'IO'
    LEFT JOIN data_checkin c on a.branchid = c.branchid 
                            and a.slsperid = c.slsperid 
                            and a.custid = c.custid 
                            and a.salesid = c.numbercico 
                            and c.checktype = '0O'
    LEFT JOIN order_checkin_final d on a.branchid = d.branchid 
                                   and a.slsperid = d.slsperid 
                                   and a.salesid = d.numbercico 
                                   and a.checkintype = 'Giao Hàng'
)
,

-- GIẢI TRÌNH
giaitrinhcongno as
(
    select *,
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
    lupd_datetime,slsperid, 
    row_number() over (partition by concat(branchid,ordernbr) order by sequence desc) as loc 
  from `spatial-vision-343005.staging.sync_dms_dv`
)
,

leadtime as
(
  select *
  from leadtime1
  where loc = 1
)

,
--- lấy ra khách hàng còn nợ
bang_no1 as
(
  SELECT 
    CustId,
    sum(so_du_chungtu) as so_du_chungtu 
  FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` 
  WHERE so_du_chungtu != 0 
  group by 1
)
,
--- lấy ra hóa đơn còn nợ
bang_no2 as 
(
  SELECT 
    a.CustId,
    concat (a.InvcNote,a.InvcNbr) as noi_hd, 
    sum(a.so_du_chungtu) as so_du_chungtu 
  FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` a
  join bang_no1 b on a.CustId = b.CustId
  WHERE b.so_du_chungtu != 0 
  group by 1,2
)
,
--- CÔNG NỢ
bang_no as 
(  
  SELECT 
    a.branchid,
    a.Ordnbr,
    a.custid, 
    c.custname,
    a.paymentsform,
    a.slsperid,
    b.tencvbh,
    b.tenquanlytt,
    b.tenquanlykhuvuc,
    b.tenquanlyvung,
    a.dateoforder as ngaydatdon,
    c.channel,
    c.shoptype,
    a.DocType,
    a.terms,
    case when a.terms = '01' then 'Thu tiền ngay có VP PN'
         when a.terms = '03' then 'Thu tiền ngay không có VP PN'
         when a.terms = '07'	then '7 Ngày'
         when a.terms = '10'	then 'Thời hạn thanh toán 10 ngày'
         when a.terms = '12'	then 'Thời hạn thanh toán 120 ngày'
         when a.terms = '15'	then '15 Ngày'
         when a.terms = '18'	then 'Thời hạn thanh toán 180 ngày'
         when a.terms = '20'	then '20 Ngày'
         when a.terms = '30'	then '30 Ngày'
         when a.terms = '45'	then '45 Ngày'
         when a.terms = '60'	then '60 Ngày'
         when a.terms = '90'	then '90 Ngày'
         when a.terms = 'DF'	then '150 Ngày'
         when a.terms = 'O1'	then 'Gối 1 Đơn Hàng (trong 30 ngày)'
         when a.terms = 'O2'	then 'TT vào ngày 15 hàng tháng'
         when a.terms = 'O3'	then 'TT vào ngày 25 hàng tháng'
         when a.terms = 'O4'	then 'TT vào ngày 7 hàng tháng' 
         else a.terms end as thoihanthanhtoan,

    c.paymentsform as hinhthucthanhtoan,
    c.hcotypeid,
    a.so_du_chungtu,
    a.sotien_da_thanhtoan,
    a.duedate,
    a.inserted_at as inserted_at,
    a.InvcNbr,
    a.InvcNote,
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
    --h.slsperid as ma_nvgh,
    h.status,
    h.delivery_date as ngaygiaohang,
    h.lupd_datetime as thoigiancapnhattrangthai,
    j.tram,
    case 
    when h.status = 'A' then 'Đã xác nhận'
    when h.status = 'C' then 'Đã giao hàng'
    when h.status = 'D' then 'KH không nhận'
    when h.status = 'H' then 'Chưa xác nhận'
    when h.status = 'R' then 'Từ chối giao hàng'
    when h.status = 'E' then 'Không tiếp tục giao hàng' 
    when h.status is null then 'Chưa xác nhận' else h.status end as trangthaigiaohang,
    case when c.shoptype IN ('PMC','CTD','PCL', 'NT', 'PK', 'SI', 'SI23') 
              AND a.paymentsform in ('B','C') 
              and c.terms in ('Thu tiền ngay có VP PN',
                              'Thu tiền ngay không có VP PN', 
                              'Gối 1 Đơn Hàng (trong 30 ngày)',
                              '30 Ngày','TT vào ngày 25 hàng tháng',
                              'Thời hạn thanh toán 10 ngày',
                              '15 Ngày',
                              '7 Ngày',
                              'Gối Đầu 30 Pha Nam')  THEN 'MDS'
    
         when c.shoptype in ('CHUOI', 'NTC','CCD','ECOM') 
              AND a.paymentsform in ('B','C') 
              AND c.terms in ('Thu tiền ngay có VP PN',
                              'Thu tiền ngay không có VP PN') THEN 'MDS' 

         when c.channel in ('INS') THEN 'INS' 
         else 'CS' end as phutrachno,

    -- case 
    --  when h.status = ('C') and c.terms in ('Thu tiền ngay không có VP PN','Thu tiền ngay có VP PN','Gối Đầu 30 Pha Nam') and h.delivery_date is not null then (date_add (date (h.delivery_date) , interval 1 day))
    -- when h.status not in ('C') and c.terms in ('Thu tiền ngay không có VP PN', 'Gối Đầu 30 Pha Nam') and h.delivery_date is not null then date_add(date(h.delivery_date),interval 3 day)
    -- when h.status not in ('C') and c.terms in ('Thu tiền ngay có VP PN', 'Gối Đầu 30 Pha Nam') and h.delivery_date is not null then date_add(date(h.delivery_date),interval 1 day)
    -- when (h.status not in ('C') and c.terms in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN','Gối Đầu 30 Pha Nam') and h.delivery_date is null) then date (a.duedate) 
    -- else date (a.duedate) end as ngaytoihan,


  -- 01	Thu tiền ngay có VP PN
  -- 03	Thu tiền ngay không có VP PN
  -- 07	7 Ngày
  -- 10	Thời hạn thanh toán 10 ngày
  -- 12	Thời hạn thanh toán 120 ngày
  -- 15	15 Ngày
  -- 18	Thời hạn thanh toán 180 ngày
  -- 20	20 Ngay
  -- 30	30 Ngày
  -- 45	45 Ngày
  -- 60	60 Ngày
  -- 90	90 Ngày
  -- DF	150 Ngày
  -- O1	Gối 1 Đơn Hàng (trong 30 ngày)
  -- O2	TT vào ngày 15 hàng tháng 
  -- O3	TT vào ngày 25 hàng tháng
  -- O4	TT vào ngày 7 hàng tháng

  case when (a.terms not in ('03','01','Gối Đầu 30 Pha Nam') and date(a.duedate) <= current_date())
      or
        (h.status = ('C') and a.terms in ('03','01','Gối Đầu 30 Pha Nam') and (date_add (date (h.delivery_date), interval 1 day)) <= current_date())
      or
        (h.status not in ('C') and a.terms in ('01','Gối Đầu 30 Pha Nam') and (date_add(date(a.dateoforder), interval 1 day)) <= current_date())
      or 
        (h.status not in ('C') and a.terms in ('03','Gối Đầu 30 Pha Nam') and (date_add(date(a.dateoforder), interval 3 day))    <= current_date()) 
      then 'Nợ đến hạn' else 'Chưa đến hạn' end as no_toi_han,

      a.paymentmethod_deli
    

  FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` a
  LEFT JOIN `staging.d_users` b on a.slsperid = b.manv
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` c on a.custid = c.custid 
  JOIN bang_no2 d on concat (a.InvcNote,a.InvcNbr) = d.noi_hd
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_ibd` e on a.BranchID = e.branchid and a.Ordnbr = e.ordernbr
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_ib` f on e.branchid = f.branchid and e.batnbr =  f.batnbr
  LEFT JOIN `staging.d_users` g on g.manv = f.slsperid
  LEFT JOIN leadtime h on a.Ordnbr = h.ordernbr and a.BranchID = h.branchid     
  LEFT JOIN `spatial-vision-343005.staging.d_tinh`  j on c.statedescr = j.tinh
)
,

result as
(
  select 
    aa.*,
    --sum (aa.so_du_chungtu),
    bb.note,
    bb.distance,
    bb.descr, 
    cc.ngay,
    cc.giaitrinh,
    -- cc.sdt,
    dd.ngay as ngaytruoc,
    dd.giaitrinh as giaitrinhngaytruoc,
  FROM bang_no aa 
  LEFT JOIN dms_checkin bb on aa.custid = bb.custid and aa.branchid = bb.branchid and aa.slsperid = bb.slsperid and aa.Ordnbr = bb.deordernbr
  LEFT JOIN giaitrinhcongno cc on aa.Ordnbr = cc.madh and cc.loc = 1
  LEFT JOIN giaitrinhcongno dd on aa.Ordnbr = dd.madh and dd.loc = 2
  LEFT JOIN `spatial-vision-343005.staging.d_users` ee on aa.ma_nvgh = ee.manv
  where so_du_chungtu != 0 and phutrachno in ('CS') and channel not in ('NB','OTH_LAB') --and paymentsform in ('B','C') --and dir_gh = 'Lương Trịnh Thắng'
)
  select * 
  from result --where noi_hd = '1C23TMR00000884'
);

Create or replace table `warehouse.f_congno_rawdata_cs_tm`

copy `staging_temp.f_congno_rawdata_cs_tm_temp`;


End;