CREATE VIEW `spatial-vision-343005.warehouse.view_sp_f_overview_mds_hanh1`
AS WITH data_so_huy_co as
(
  select 
    branchid,
    ordernbr,
    custid,
    invcnbr,
    invcnote,
    orderdate 
  from `staging.sync_dms_so` 
  where ordertype in ('CO','HK') and status ='C' 
)
,
  /* 
  Phát hành lại nhưng cùng 1 mã đơn hàng origordernbr, cùng ordertype ='IN'
  */
data_huyhd_phathanhlai as 
(
  with data_huy_hoadon as 
  (
    select 
      origordernbr,
      count(distinct invcnbr),
      count(distinct status)
    from `staging.sync_dms_so` 
    where crtd_datetime >="2021-05-01" --and ordertype ='IN'
    group by 1 
    having count(distinct invcnbr) >1 and count(distinct status) >1
  )
  select 
    b.*,
    dense_rank() over (partition by a.origordernbr order by b.origordernbr,b.status asc) as loc_dh
  from data_huy_hoadon a
  JOIN `staging.sync_dms_so` b on a.origordernbr =b.origordernbr
  order by a.origordernbr,b.crtd_datetime desc
)
,

/*
Phát hành lại hóa đơn nhưng khác mã đơn hàng origordernbr, ordertype in( RP )
*/

data_so_taolai as 
(
  select *
  from `staging.sync_dms_so` 
  where Status = 'C'  
        and  OrderType IN ('CO','DI','DM','IN','IR','LO','OO')
        and salesordertype in('RP')
)        
,

data_so_huy as 
(
  select 
    OrderNbr,
    BranchID,
    CustID,
    InvoiceCustID,
    Version,
    OrigOrderNbr,
    ARBatNbr ,
    ARRefNbr,
    OrderDate ,
    PaymentsForm ,
    InvcNbr,
    InvcNote,
    OrderType
  from `staging.sync_dms_so` 
  where Status = 'V' 
)
,
  
data_so_mapping as 
(
  select 
    a.branchid,
    ifnull(b.ordernbr,a.ordernbr) as ordernbr, --Update 20/3/2023 lỗi đơn hủy tạo lại k mapping dc vs giá trị đơn hàng
    IFNULL(b.OrigOrderNbr,a.OrigOrderNbr) as OrigOrderNbr,
    a.custid,
    a.ordertype,
    a.arbatnbr,
    a.arrefnbr,
    a.inbatnbr,
    a.inrefnbr,
    a.invcnbr,
    a.invcnote,
    a.status as status_so,
    a.slsperid as slsperid_so,
    a.orderdate as orderdate_so,
    a.crtd_user as crtd_user_so,
    a.crtd_datetime as crtd_datetime_so,
    a.lupd_user as lupd_user_so,
    a.lupd_datetime as lupd_datetime_so,
    a.remark as remark_so
  from data_so_taolai a
  JOIN data_so_huy b on a.branchid =b.branchid
                    and a.ARBatNbr =b.ARBatNbr
                    and a.ARRefNbr =b.ARRefNbr
)
,

pda_so AS 
(
  SELECT
    distinct branchid,
    ordernbr,
    custid,
    crtd_prog,
    status as status_pda_so,
    slsperid as slsperid_pda_so,
    crtd_user AS crtd_user_pda_so,
    crtd_datetime AS crtd_datetime_pda_so,
    lupd_datetime AS lupd_datetime_pda_so,
    lupd_user AS lupd_user_pda_so,
    remark AS remark_pda_so,
    deliverytime
  FROM `spatial-vision-343005.staging.sync_dms_pda_so`
  WHERE DATE(crtd_datetime) >= "2021-05-01" and ordertype ='IN'
)
,
-- Duyệt đơn hàng

dms_so AS 
(
  SELECT
    distinct branchid,
    ordernbr,
    origordernbr,
    custid,
    ordertype,
    arbatnbr,
    arrefnbr,
    inbatnbr,
    inrefnbr,
    invcnbr,
    invcnote,
    status as status_so,
    slsperid as slsperid_so,
    orderdate as orderdate_so,
    crtd_user as crtd_user_so,
    crtd_datetime as crtd_datetime_so,
    lupd_user as lupd_user_so,
    lupd_datetime as lupd_datetime_so,
    remark as remark_so
  FROM `spatial-vision-343005.staging.sync_dms_so`
  WHERE DATE(crtd_datetime) >= "2021-05-01" --and ordertype ='IN'
        and origordernbr not in (select distinct origordernbr from data_huyhd_phathanhlai)
        and ordernbr not in (select distinct ordernbr from data_so_taolai)
        and origordernbr not in (select distinct origordernbr from data_so_mapping)

  UNION ALL

  select     
    b.branchid,
    b.ordernbr,
    b.origordernbr,
    b.custid,
    b.ordertype,
    b.arbatnbr,
    b.arrefnbr,
    b.inbatnbr,
    b.inrefnbr,
    b.invcnbr,
    b.invcnote,
    b.status as status_so,
    b.slsperid as slsperid_so,
    b.orderdate as orderdate_so,
    b.crtd_user as crtd_user_so,
    b.crtd_datetime as crtd_datetime_so,
    b.lupd_user as lupd_user_so,
    b.lupd_datetime as lupd_datetime_so,
    b.remark as remark_so
  from data_huyhd_phathanhlai b where loc_dh = 1

  UNION ALL 
  select * 
  from data_so_mapping
)
,  

mapping_so as
(
  select 
    a.*,
    Case when c.ordernbr is not null then 'Hủy HĐ' else 'Không hủy HĐ' end as ordernbr_co, c.orderdate as orderdate_co
  from dms_so a
  LEFT JOIN data_so_huy_co c on c.invcnbr = a.invcnbr 
                             and c.branchid =a.branchid  
                             and a.invcnote =c.invcnote 
                             and a.custid=c.custid
                             and a.ordertype in ('IN', 'IO', 'EP', 'NP')
)
,
    --Duyệt hóa đơn
dms_iv as 
(
  select 
    distinct branchid,
    refnbr,
    invcnbr,
    invcnote,
    crtd_datetime as crtd_datetime_iv,
    lupd_user as lupd_user_iv,
    lupd_datetime  as lupd_datetime_iv
  from `spatial-vision-343005.staging.sync_dms_iv`
  where crtd_datetime >='2021-05-01'
)
,
-- Tạo sổ
  
dms_ib AS 
(
  SELECT
    distinct branchid,
    truckid,
    batnbr,
    deliveryunit,
    slsperid as slsperid_ib,
    status as status_ib,
    issuedate as issuedate_ib,
    crtd_datetime as crtd_datetime_ib,
    crtd_user as crtd_user_ib,
    lupd_datetime as lupd_datetime_ib1,
    Case when date(approvedate) ='1900-01-01' then null else
    approvedate end as lupd_datetime_ib
  FROM `spatial-vision-343005.staging.sync_dms_ib`
  WHERE DATE(crtd_datetime) >= "2021-05-01" 
)
,

-- Chốt sổ
dms_ibd AS 
(
  SELECT
    distinct branchid,
	  batnbr,
  	ordernbr,
    status as status_ibd,
    deliverytime as deliverytime_ibd,
    crtd_datetime crtd_datetime_ibd,
    crtd_user as crtd_user_ibd,
    lupd_datetime as lupd_datetime_ibd,
    transporters 
  FROM `spatial-vision-343005.staging.sync_dms_ibd`
  WHERE DATE(crtd_datetime) >= "2021-05-01" 
)
,

mapping_ib as 
(
  select 
    a.*,
    b.ordernbr,
    b.status_ibd,
    b.deliverytime_ibd,
    b.crtd_user_ibd,
    b.crtd_datetime_ibd,
    b.lupd_datetime_ibd,
    b.transporters
  from dms_ib a 
  LEFT JOIN dms_ibd b on a.branchid =b.branchid and a.batnbr = b.batnbr
)
,    

dms_dv as 
(
  select 
    distinct branchid,
    batnbr,
    sequence,
    ordernbr,slsperid as slsperid_dv,	status as status_dv,	
    crtd_datetime as crtd_datetime_dv,crtd_user as crtd_user_dv,
    delivery_date as lupd_datetime_dv,
    inserted_at
 from `spatial-vision-343005.staging.sync_dms_dv`
 where DATE(crtd_datetime) >= "2021-05-01"
)
,

max_sequence as 
(
  select 
    branchid,
    batnbr,
    ordernbr,
    max(sequence) as max_sequence ,
    max(crtd_datetime) as crtd_datetime
  from `spatial-vision-343005.staging.sync_dms_dv` 
  group by 1,2,3 
)
,

mapping_dv as 
(
  select a.* 
  from dms_dv a 
  JOIN max_sequence b on a.branchid = b.branchid 
                      and a.ordernbr = b.ordernbr 
                      and a.batnbr =b.batnbr 
                      and a.sequence = b.max_sequence
                      and b.crtd_datetime =a.crtd_datetime_dv
)
,

--Lý do trì hoãn
dms_error AS 
(
  SELECT
    distinct  a.branchid,
    a.ordernbr,
    a.crtd_datetime as crtd_datetime_err,
    a.lupd_datetime as lupd_datetime_err,
    a.errormessage
  FROM `spatial-vision-343005.staging.sync_dms_err` a
  JOIN  ( SELECT
            distinct
            branchid,
            ordernbr,
            max(crtd_datetime) as max_crtd_datetime_err  
          FROM `spatial-vision-343005.staging.sync_dms_err` 
          group by 1,2
        ) b on a.branchid =b.branchid and a.ordernbr =b.ordernbr and a.crtd_datetime =b.max_crtd_datetime_err
  WHERE DATE(a.crtd_datetime) >= "2021-05-01" 
)
,

/* *** Note ***
      IR','NI','OO','OC','RC': Không đi qua PDA --> crtd_datetime_so ::ngày tạo đơn
      Đi qua PDA:--> crtd_datetime_pda_so:: ngày tạo đơn 
      crtd_datetime_so :: ngày duyệt đơn
      lupd_datetime_iv :: ngày duyệt hóa đơn ( ngày chứng từ ::datetime )
          Nếu ngày chứng từ > ngày giao hàng ---> ngày chứng từ = lupd_datetime_pda_so
      lupd_datetime_ib :: ngày tạo sổ 
      lupd_datetime_ibd:: ngày chốt sổ
      lupd_datetime_dv::  ngày giao
      orderdate_so :: ngày chứng từ(date)
      --
       -- Trạng thái đơn hàng
      Status pda_so			      Status so			    Invnbr (invoice)			  Status IB		  	    			            Status DV	
      C	Đã duyệt đơn hàng		  C	Đã phát hành		blank	    K có hóa đơn	C	Đã chốt sổ	       		              A	Đã xác nhận
      E	Đóng đơn hàng	      	V	Hủy đơn hàng		no blank	Có hóa đơn	  H	Chưa xác nhận	  			              C	Đã giao hàng
      D	Đơn hàng tạm		      I	Tạo hóa đơn					                    Blank	: Chưa tạo sổ		   			        D	KH không nhận
      H	Chờ xử lý		          N	Tạo hóa đơn											                                              H	Chưa xác nhận
      V Hủy đơn hàng          H	Chờ xử lý									                                                 		L	
      blank		               	E	Đóng đơn hàng										                                             	R	Từ chối giao hàng
                              D	Đơn hàng tạm									                                                E	Không tiếp tục giao hàng
      */

order_detail as 
(
  with dms_pda_sod as 
  (
    SELECT
      branchid,
      ordernbr,
      freeitem,
      lineref,
      invtid,
      Case when ordertype in('DP','UP') then 0 else lineqty end as lineqty,
      ordertype,
      siteid,
      crtd_user,
      slsperid,
      beforevatprice,
      Case when ordertype in('DP') then -1* beforevatamount else beforevatamount end as  beforevatamount,
      aftervatprice,
      Case when ordertype in('DP') then -1*aftervatamount else aftervatamount end as aftervatamount,
      vatamount
    FROM `spatial-vision-343005.staging.sync_dms_pda_sod`
    WHERE DATE(crtd_datetime) >= "2021-05-01"
  --MR2448
  )
  ,

  dms_sod1 as 
  (
    SELECT
      branchid,
      ordernbr,
      origordernbr,
      lineref,
      originallineref,
      invtid,
      Case when ordertype in('DP','UP') then 0 else lineqty end as lineqty,
      ordertype,
      freeitem,
      siteid,
      crtd_user,
      slsperid,
      beforevatprice,
      Case when ordertype in('DP') then -1* beforevatamount else beforevatamount end as  beforevatamount,
      aftervatprice,
      Case when ordertype in('DP') then -1*aftervatamount else aftervatamount end as aftervatamount,
      vatamount,
      discamt,
      docdiscamt,
      groupdiscamt1
    FROM `spatial-vision-343005.staging.sync_dms_sod1`
    WHERE DATE(crtd_datetime) >= "2021-05-01"
  )
  select 
    a.branchid,
    a.ordernbr,
    b.ordernbr as ordernbr_mapping,
    Case when b.lineref is not null then b.originallineref else
    a.lineref end as lineref,
    ifnull(b.invtid,a.invtid) as invtid,
    Case when b.lineqty is not null then b.lineqty else 
    a.lineqty end as lineqty,
    b.ordertype,
    a.siteid,
    a.crtd_user,
    ifnull(a.slsperid,b.slsperid) as slsperid,
    a.beforevatprice ,
    Case when b.beforevatamount is not null then b.beforevatamount
         when b.freeitem = true then 0 
         else a.beforevatamount end as beforevatamount,
    a.aftervatprice,
    Case when b.aftervatamount is not null then b.aftervatamount
         when b.freeitem = true then 0 
         else a.aftervatamount end as aftervatamount,
    ifnull(b.vatamount,a.vatamount) as vatamount,
    ifnull(b.freeitem,a.freeitem) as freeitem,
    Case when b.discamt is null then 0 else b.discamt end as discamt,
    Case when b.docdiscamt is null then 0 else b.docdiscamt end as docdiscamt,
    Case when b.groupdiscamt1 is null then 0 else b.groupdiscamt1 end as groupdiscamt1
  from dms_pda_sod a
  left join dms_sod1 b on a.branchid =b.branchid and a.ordernbr =b.origordernbr and a.invtid =b.invtid and b.originallineref =a.lineref 
)
,

dms_checkin as 
(
  with order_checkin as 
  (
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

    max_order_checkin as 
    (
      select 
        branchid,
        slsperid,
        deordernbr,
        max(de_updatetime) as max_de_updatetime 
      from `spatial-vision-343005.staging.sync_dms_decheckin`  
      group by 1,2,3
     )
     
    select 
      a.* 
    from order_checkin a
    JOIN max_order_checkin b on a.branchid = b.branchid 
                            and a.slsperid = b.slsperid 
                            and a.deordernbr = b.deordernbr 
                            and a.de_updatetime = b.max_de_updatetime 
  )
  ,
  data_checkin as 
  (
    select 
      slsperid,
      custid,
      branchid,
      lat,lng,typ,
      checktype,
      updatetime,
      numbercico 
    from `spatial-vision-343005.staging.d_checkin`
    where updatetime >'2021-05-01'
  )
  ,

  sales_checkin as 
  (
	  select * 
    from `spatial-vision-343005.staging.sync_dms_sacheckin`
  )
  ,
  
  checkin_note as 
  (
    select * 
    from ( select custid,
  	              visitdate,
                  noteid,
                  slsperid,
                  branchid,
                  note,
                  descr,
                  salesid,
                  distance,
                  checkintype,
                  imagefilename,
                  inserted_at,
                  row_number() over(partition by slsperid,salesid order by branchid desc) as row_
           from `spatial-vision-343005.staging.sync_dms_oc`
           where date(visitdate) >= "2022-01-01"  
         ) a 
    where row_=1 
)
/*
CL = Close
IO= In outlet
PS= Program Sales
SO= Sales ord vào step ghi nhận đơn hàng
PA= Thanh toán công nợ
OO= Out outlet
DP= trưng bày
SA= Có đơn hàng
FC= Feedback customer
PO = POSM/Gimmick
SK= Stock keeping
*/

  SELECT  
    distinct b.*,
    a.typ as checkin,
    case when a.updatetime is null then b.visitdate else 
    a.updatetime  end as time_checkin,
    a.lat,a.lng,
    c.typ as checkout, 
    c.updatetime  as time_checkout,

  -- Case when d.typ ='PA' and e.deordernbr is not null then 'Giao hàng'
  -- 		 when d.typ like 'DE%'  then 'Giao hàng'
  -- 		 when d.typ ='PA' and e.deordernbr is  null then 'Thanh toán công nợ'
  -- 		 when d.typ ='CL' then 'Close'
  -- 		 when d.typ ='IO' then 'In outlet'
  -- 		 when d.typ ='PS' then 'Program Sales'
  -- 		 when d.typ ='SO' then 'Sales ord vào step ghi nhận đơn hàng'
  -- 		 when d.typ ='OO' then 'Out outlet'
  -- 		 when d.typ ='DP' then 'trưng bày'
  -- 		 when d.typ ='SA' then 'Có đơn hàng'
  -- 		 when d.typ ='FC' then 'Feedback customer'
  -- 		 when d.typ ='PO' then 'POSM/Gimmick'
  -- 		 when d.typ ='SK' then 'Stock keeping'
  --     else null end as phanloai_checkin,

    Case when b.checkintype ='Bán Hàng' then f.saordernbr
         when b.checkintype ='Giao Hàng' then e.deordernbr
         else null end as ordernbr,
    e.deordernbr,
    f.saordernbr,
    f.ordamt,
    h.tencvbh as mds,
    h.tenquanlytt,
    h.tenquanlykhuvuc,
    h.tenquanlyvung,
    k.custname,
    k.statedescr,
    k.territorydescr,
    g.role

  FROM checkin_note b
  LEFT JOIN data_checkin a on a.slsperid = b.slsperid 
                          and a.custid = b.custid 
                          and b.salesid = a.numbercico 
                          and a.checktype ='IO'
  LEFT JOIN data_checkin c on c.slsperid = b.slsperid 
                          and c.custid = b.custid 
                          and b.salesid = c.numbercico 
                          and c.checktype ='OO'
  LEFT JOIN order_checkin e on e.slsperid = b.slsperid 
                            and e.numbercico =b.salesid 
                            and b.checkintype ='Giao Hàng'
  LEFT JOIN sales_checkin f on f.numbercico = b.salesid 
                            and f.slsperid = b.slsperid 
                            and b.checkintype ='Bán Hàng'
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` g on g.username = b.slsperid  
  LEFT JOIN `spatial-vision-343005.staging.d_users` h on h.manv = b.slsperid
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` k on k.custid = b.custid and k.branchid = b.branchid
  where k.custname is not null
)
,

data_tracking_deli as 
(
  with data_ as 
  (
    select *,
      row_number() over (partition by branchid,ordernbr,status order by crtd_datetime) as row_
    from `staging.sync_dms_delihistory` 
    where crtd_datetime >='2022-01-01'
  )
  select * 
  from data_ 
  where row_ =1 
)
,

result as 
(
  SELECT
    a.branchid,
    a.ordernbr,
    b.ordernbr_co,
    d.truckid,
    d.crtd_user_ib as ng_taoso,
    g.tencvbh as ten_taoso,
    b.ordertype,
    b.ordernbr as origordernbr,
    a.custid,
    -- Case when b.status_so ='C' then 'Đã phát hành'
    --      when b.status_so ='V' then 'Hủy hóa đơn'
    --      when b.status_so ='I' then 'Tạo hóa đơn'
    --      when b.status_so ='N' then 'Tạo hóa đơn'
    --      when b.status_so ='H' then 'Chờ xử lý'
    --      when b.status_so ='E' then 'Đóng đơn hàng'
    --      when b.status_so ='D' then 'Đơn hàng tạm'
    --      else null end as status_so, --Chưa dùng

    Case when a.status_pda_so ='C' then 'Đã duyệt đơn hàng'
          when a.status_pda_so ='E' then 'Đóng đơn hàng'
          when a.status_pda_so ='D' then 'Đơn hàng tạm'
          when a.status_pda_so ='H' then 'Chờ xử lý duyệt đơn hàng'
          when a.status_pda_so ='V' then 'Hủy đơn hàng'
          when a.status_pda_so ='X' then 'Đóng đơn hàng tạm'
          else null end as status_pda_so, -- Trạng thái đơn hàng
    a.slsperid_pda_so, -- Người bán hàng
    a.crtd_datetime_pda_so as ngaytaodon, -- Ngày tạo đơn
    -- a.crtd_user_pda_so, -- Người tạo đơn
    -- a.lupd_datetime_pda_so  as ngayduyetdon, -- Ngày duyệt đơn 
    -- Case when a.status_pda_so in('C','E','V') then a.lupd_user_pda_so else null end as lupd_user_pda_so, -- Người duyệt đơn
    -- Case when c.invcnbr is not null or c.invcnbr <> '' then 'Đã phát hành HĐ' else 'Chưa phát hành HĐ' end as status_iv,
    Case when b.status_so ='C' then 'Đã phát hành hóa đơn'
         when b.status_so ='V' then 'Hủy hóa đơn'
         when b.status_so ='I' then 'Tạo hóa đơn'
         when b.status_so ='N' then 'Tạo hóa đơn'
         when b.status_so ='H' then 'Chờ xử lý hóa đơn'
         when b.status_so ='E' then 'Đóng đơn hàng'
         when b.status_so ='D' then 'Đơn hàng tạm'
         when b.status_so is null and a.status_pda_so ='C' then 'Chưa tạo HĐ ảo'
         when b.status_so is null and a.status_pda_so ='E' then 'Đóng đơn hàng'
         when b.status_so is null and a.status_pda_so ='D' then 'Đơn hàng tạm'
         when b.status_so is null and  a.status_pda_so ='H' then 'Chờ xử lý duyệt đơn hàng'
         when b.status_so is null and  a.status_pda_so ='V' then 'Hủy đơn hàng' 
         when b.status_so is null and  a.status_pda_so ='X' then 'Đóng đơn hàng tạm' 
         else null end as status_iv, -- Trạng thái phát hành hóa đơn

    Case when b.status_so ='C' then b.orderdate_so
         else null end as ngayphathanhhd, -- Ngày phát hành hóa đơn
    -- Case when b.status_so in('C') then b.lupd_user_so  as lupd_user_so, -- Người phát hành hóa đơn

    Case when  d.status_ib ='C' then 'Đã chốt sổ'
         when  d.status_ib ='H' then 'Chưa xác nhận chốt sổ'
         else null end as status_ib, -- Trạng thái tạo sổ
    -- d.crtd_user_ib as crtd_user_ib, -- Người tạo sổ
    -- d.slsperid_ib,
    -- d.crtd_datetime_ib as ngaytaoso, -- Ngày tạo sổ
    -- d.lupd_datetime_ib,
    -- Case when d.status_ib ='C' and d.deliveryunit ='TP'  then d.crtd_user_ib
    --      when d.status_ib ='C' then e.crtd_user_dv 
    --      else null end as crtd_user_dv,  -- Người chốt sổ
    
    Case when d.status_ib ='C' and d.deliveryunit ='TP' then ifnull(d.lupd_datetime_ib,ifnull(e.crtd_datetime_dv,d.lupd_datetime_ib1))
         when d.status_ib ='C' and e.status_dv <> 'C' then ifnull(d.lupd_datetime_ib,ifnull(e.crtd_datetime_dv,d.lupd_datetime_ib1)) 
         when d.status_ib ='C' and e.status_dv ='C' then ifnull(d.lupd_datetime_ib,ifnull(e.crtd_datetime_dv,d.lupd_datetime_ib1)) 
         else null end as ngaychotso, -- Ngày chốt sổ
    --d.slsperid_ib as slsperid_sxh,
    -- d.batnbr,
    -- d.deliverytime_ibd,d.crtd_user_ibd,d.crtd_datetime_ibd,
    case when d.deliveryunit = 'CW' then 'Chành Xe'
         when d.deliveryunit = 'PN' then 'Pha Nam' 
         when d.deliveryunit = 'TP' then 'NVC' else null end as deliveryunit,

    Case when e.status_dv ='C' then 'Đã giao hàng'
         when d.status_ib ='C'  and d.deliveryunit ='TP' then 'Đã giao hàng'
         when e.status_dv ='A' then 'Đã xác nhận' -- Đã chốt sổ
         when e.status_dv ='D' then 'KH không nhận'
         when e.status_dv ='H' then 'Chưa xác nhận' -- Chưa chốt sổ
         when e.status_dv ='R' then 'Từ chối giao hàng'
         when e.status_dv ='E' then 'Không tiếp tục giao hàng'
         else null end as status_dv,	 -- Trạng thái giao hàng
    -- e.crtd_datetime_dv,
    -- Case when  e.status_dv in ('C','A','D','R','E') then 'Đã chốt sổ'
    --      else 'Chưa chốt sổ' end as status_ibd, -- Trạng thái chốt sổ
    -- Case when e.status_dv in ('C','A','D','R','E') then e.crtd_user_dv 
    -- else null end as crtd_user_dv,  -- Người chốt sổ
    -- Case when e.status_dv in ('C','A','D','R','E') and d.crtd_datetime_ib <= e.crtd_datetime_dv then e.crtd_datetime_dv
    --     when e.status_dv in ('C','A','D','R','E') and d.crtd_datetime_ib > e.crtd_datetime_dv then d.crtd_datetime_ib
    --   else null end as ngaychotso, -- Ngày chốt sổ
    Case when e.status_dv is null then d.slsperid_ib --in ('C','D','R','E','A','H','L') then
         else e.slsperid_dv  end as slsperid_dv, -- Người giao hàng
    Case when e.status_dv in ('C') then 
    e.lupd_datetime_dv else null end as ngaygiaohang, -- Ngày giao hàng
    -- f.crtd_datetime_err,f.lupd_datetime_err, 
    -- f.errormessage,
    e.inserted_at

  FROM pda_so a  
  LEFT JOIN mapping_so b on a.ordernbr = b.origordernbr and a.branchid =b.branchid
  LEFT JOIN mapping_ib d on d.branchid = a.branchid and a.ordernbr = d.ordernbr
  LEFT JOIN mapping_dv e on e.branchid = a.branchid and e.ordernbr = a.ordernbr and d.batnbr =e.batnbr
  -- -- LEFT JOIN mapping_dv1 e on e.branchid = a.branchid and e.ordernbr = a.ordernbr and d.batnbr =e.batnbr
  LEFT JOIN dms_error f on f.branchid = a.branchid and f.ordernbr = a.ordernbr
  LEFT JOIN `spatial-vision-343005.staging.d_users` g on d.crtd_user_ib = g.manv 
)
,

result1 as 
(
  select 
    a.*,
    coalesce(a.status_dv,a.status_ib,a.status_iv,a.status_pda_so) as trangthaidon,
    b1.tencvbh as nguoibanhang,
    Case when ngaygiaohang is null then null
         else round(datetime_diff(ngaygiaohang,ngaychotso,minute)/60,2) end as t4,
    Case when status_ib='Đã chốt sổ' and a.deliveryunit ='NVC' then round(datetime_diff(ngaychotso,ngaytaodon,minute)/60,2)
         when ngaygiaohang is null then null
         else round(datetime_diff(ngaygiaohang,ngaytaodon,minute)/60,2) end as full_leadtime ,  
    b2.role,
    b2.firstname as mds_sxh,
    b.tencvbh as mds,
    b.tenquanlytt as sup_mds,
    b.tenquanlykhuvuc as mng_mds,
    h.channel as kenh,
    h.terms,
    h.custname,
    h.statedescr as tinh,
    h.shoptype as kenhphu,
    h.paymentsform as hinhthucthanhtoan,
    Case when h.branchname ='CÔNG TY CỔ PHẦN DƯỢC PHA NAM' or h.branchid ='MR0001' then 'CHI NHÁNH HCM'
         when h.branchname like '%CHI NHÁNH%' then substring(h.branchname,32)
         else h.branchname end as chinhanh,
    h.districtdescr,
    h.wardname,  
    k.invtid,
    k.lineqty,
    Case when k.freeitem = true then 'Hàng tặng' else 'Hàng bán' end as freeitem,
    k.siteid,
    k.beforevatprice,
    k.beforevatamount,
    k.aftervatprice,
    k.aftervatamount,
    k.vatamount,
    j.lotsernbr,
    j.expdate,
    o.descr1 as tensp_viettat,
    o.descr as tensp_daydu,
    ot.descr as thongtinxe,
    ot1.descr as thongtinxe_sxh,
    dr.crtd_user as donghang_tinh,
    dr1.tencvbh as nguoidonghang_tinh,

    Case when rd.ordernbr = a.ordernbr and a.branchid = rd.branchid and rd.custid = a.custid then rd.deliveryunit
         when dr.ordernbr = a.ordernbr and a.branchid = dr.branchid and dr.custid = a.custid then dr.deliveryunit
         else null end as deliveryunit_code,
    case when a.deliveryunit = 'Chành Xe' and dr.ordernbr is null then 'Chưa tạo BBGHT' 
         when a.deliveryunit = 'NVC' and rd.ordernbr is null then 'Chưa tạo BBGHT'    
         else 'Đã tạo BBGHT/Chốt sổ' end as tao_bbght,
    vp.vptt

  From result a
  LEFT JOIN `spatial-vision-343005.staging.d_users` b on a.slsperid_dv = b.manv
  LEFT JOIN `spatial-vision-343005.staging.d_users` b1 on a.slsperid_pda_so = b1.manv
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` b2 on b2.username = a.slsperid_dv
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` h on h.custid = a.custid --and h.branchid =a.branchid
  LEFT JOIN `spatial-vision-343005.staging.d_vptt` vp on trim(upper(h.statedescr)) = trim(upper(vp.tinh))

  LEFT JOIN order_detail k on k.branchid = a.branchid 
                          and k.ordernbr_mapping =a.origordernbr -- k.ordernbr = a.ordernbr --
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid` o on o.invtid = k.invtid
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_lt` j on j.branchid = k.branchid 
                                                          and k.ordernbr_mapping = j.ordernbr 
                                                          and j.omlineref = k.lineref
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_rd` rd on rd.ordernbr = a.ordernbr 
                                                          and a.branchid = rd.branchid 
                                                          and rd.custid = a.custid
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_dr` dr on dr.ordernbr = a.ordernbr 
                                                          and a.branchid = dr.branchid 
                                                          and dr.custid = a.custid
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_ot` ot on ot.branchid = a.branchid 
                                                          and ot.code = ifnull(ifnull(dr.truckid,rd.truckid),a.truckid)
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_ot` ot1 on ot1.branchid = a.branchid 
                                                           and ot1.code = a.truckid
  LEFT JOIN `spatial-vision-343005.staging.d_users` dr1 on dr.crtd_user = dr1.manv                                                         


  where  a.ordertype in ('IN','DP','UP') or a.ordertype is null 
)

  select 
    a.*,
    ard.deliveryunitname,
    Case when dl.status is not null then dl.crtd_datetime else null end as ngay_xacnhan_nhanhang,
    Case when dl1.status is not null then dl1.crtd_datetime else null end as ngay_kh_k_nhanhang
  from result1 a
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_ard`ard on a.deliveryunit_code = ard.deliveryunitid 
                                                           and ard.branchid =a.branchid
  LEFT JOIN dms_checkin n on n.custid = a.custid 
                          and a.slsperid_dv = n.slsperid 
                          and a.ordernbr = n.deordernbr 
  LEFT JOIN data_tracking_deli dl on dl.branchid = a.branchid 
                                  and dl.ordernbr = a.ordernbr 
                                  and dl.status ='A'
  LEFT JOIN data_tracking_deli dl1 on dl1.branchid = a.branchid 
                                    and dl1.ordernbr = a.ordernbr 
                                    and dl1.status ='D';