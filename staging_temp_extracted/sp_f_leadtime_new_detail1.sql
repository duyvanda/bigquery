-- ==========================================================================
-- Routine Name : sp_f_leadtime_new_detail1
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-07-22 09:43:54.650000+00:00
-- Last Altered : 2026-07-22 09:43:54.650000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_leadtime_new_detail1()
BEGIN

DECLARE partition_date DATE DEFAULT DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH), MONTH);
-- TRUNCATE TABLE `staging_temp.f_leadtime_new_detail1_temp`;
-- INSERT INTO `staging_temp.f_leadtime_new_detail1_temp`
-- CREATE TABLE `staging_temp.f_leadtime_new_detail1_temp` PARTITION BY DATE(ngaytaodon) AS
-- (
-----Tạo đơn hàng
BEGIN TRANSACTION;
DELETE FROM
    `warehouse.f_leadtime_new_detail1`
WHERE
    DATE(ngaytaodon) >= DATE(partition_date);
INSERT INTO
    `warehouse.f_leadtime_new_detail1`
WITH data_so_huy_co as
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
  and date(crtd_datetime)>=partition_date
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
    where
    1=1
    -- and date(crtd_datetime)>=partition_date
    group by 1
    having count(distinct invcnbr) >1
    and count(distinct status) >1
)
  select
    b.*,
    dense_rank() over (partition by a.origordernbr order by b.origordernbr,b.status asc) as loc_dh
    from data_huy_hoadon a
  JOIN `staging.sync_dms_so` b on a.origordernbr = b.origordernbr
  where
  1=1
  -- and date(b.crtd_datetime)>= partition_date
  order by a.origordernbr, b.crtd_datetime desc
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
        -- and date(crtd_datetime)>= partition_date
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
    ARBatNbr,
    ARRefNbr,
    OrderDate,
    PaymentsForm,
    InvcNbr,
    InvcNote,
    OrderType
  from `staging.sync_dms_so`
  where Status = 'V'
  -- and date(crtd_datetime)>=partition_date
)
,
data_so_mapping as
(
  select
    a.branchid,
    ifnull(b.ordernbr,a.ordernbr) as ordernbr,
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
    a.remark as remark_so,
    a.salesordertype as ordertype_so
  from data_so_taolai a
  JOIN data_so_huy b on a.branchid =b.branchid
                    and a.ARBatNbr =b.ARBatNbr
                    and a.ARRefNbr =b.ARRefNbr
)
,
pda_so AS
(
  SELECT
    distinct
    branchid,
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
  WHERE
  true
  and date(crtd_datetime)>=partition_date
  and ordertype ='IN'
)
,
-- Duyệt đơn hàng
dms_so AS
(
  SELECT
    distinct
    branchid,
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
    remark as remark_so,
    salesordertype as ordertype_so
  FROM `spatial-vision-343005.staging.sync_dms_so`
  WHERE
  true
  and date(crtd_datetime)>=partition_date
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
    b.remark as remark_so,
    salesordertype as ordertype_so
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
    case when c.ordernbr is not null then 'Hủy HĐ' else 'Không hủy HĐ' end as ordernbr_co, c.orderdate as orderdate_co
  from dms_so a
  LEFT JOIN data_so_huy_co c on c.invcnbr = a.invcnbr
                            and c.branchid = a.branchid
                            and a.invcnote = c.invcnote
                            and a.custid = c.custid
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
  -- where date(crtd_datetime)>=partition_date
)
,
-- Tạo sổ
ib_loc as
(
  with ib_loc as
  (
    select
      branchid,
      batnbr,
      max(crtd_datetime) as max_crtd_datetime
    from `staging.sync_dms_ib`
    where date(crtd_datetime)>=partition_date
    group by 1,2
  )
  select a.*
  from `staging.sync_dms_ib` a
 JOIN ib_loc b
  on b.branchid = a.branchid
  and a.batnbr = b.batnbr
  and a.crtd_datetime = b.max_crtd_datetime
  -- where date(a.crtd_datetime)>=partition_date
)
,
ibd_loc as
(
 with ibd_loc as
 (
  select
    branchid,
    ordernbr,
    max(crtd_datetime) as max_crtd_datetime
  from `staging.sync_dms_ibd`
  where date(crtd_datetime)>=partition_date
  group by 1,2
)
  select a.*
  from `staging.sync_dms_ibd` a
 JOIN ibd_loc b on b.branchid = a.branchid
and b.ordernbr = a.ordernbr
and b.max_crtd_datetime = a.crtd_datetime
where date(crtd_datetime)>=partition_date
)
,
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
  FROM ib_loc
  WHERE date(crtd_datetime)>=partition_date
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
  FROM ibd_loc
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
  LEFT JOIN dms_ibd b on a.branchid =b.branchid and a.batnbr =b.batnbr
)
,
dms_dv as
(
  select
    distinct branchid,batnbr,
    sequence,
    ordernbr,
    slsperid as slsperid_dv,
    status as status_dv,
    crtd_datetime as crtd_datetime_dv,
    crtd_user as crtd_user_dv,
    delivery_date as lupd_datetime_dv,
    inserted_at
 from `spatial-vision-343005.staging.sync_dms_dv`
 where date(crtd_datetime)>=partition_date
)
,
max_sequence as
(
  select
    branchid,
    batnbr,
    ordernbr,
    max(sequence) as max_sequence --,max(crtd_datetime) as crtd_datetime
  from `spatial-vision-343005.staging.sync_dms_dv`
  where date(crtd_datetime)>=partition_date
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
)
,
dms_error AS
(
  SELECT
    distinct a.branchid,
    a.ordernbr,
    a.crtd_datetime as crtd_datetime_err,
    a.lupd_datetime as lupd_datetime_err,
    a.errormessage
  FROM `spatial-vision-343005.staging.sync_dms_err` a
  JOIN (SELECT
          distinct branchid,
          ordernbr,
          max(crtd_datetime) as max_crtd_datetime_err
        FROM `spatial-vision-343005.staging.sync_dms_err`
        where
        true
        and date(crtd_datetime) >= partition_date
        group by 1,2
        ) b on a.branchid = b.branchid
           and a.ordernbr = b.ordernbr
           and a.crtd_datetime = b.max_crtd_datetime_err
  WHERE
  true
  and date(a.crtd_datetime) >= partition_date
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
      case when ordertype in('DP','UP') then 0 else lineqty end as lineqty,
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
  WHERE date(crtd_datetime)>=partition_date
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
  WHERE
  true
  and date(crtd_datetime)>=partition_date
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
          when b.freeitem = true then 0 else
          a.beforevatamount end as beforevatamount,
    a.aftervatprice,
    Case
    when b.aftervatamount is not null then b.aftervatamount
    when b.freeitem = true then 0 else
    a.aftervatamount end as aftervatamount,
    ifnull(b.vatamount,a.vatamount) as vatamount,
    ifnull(b.freeitem,a.freeitem) as freeitem,
    Case when b.discamt is null then 0 else b.discamt end as discamt,
    Case when b.docdiscamt is null then 0 else b.docdiscamt end as docdiscamt,
    Case when b.groupdiscamt1 is null then 0 else b.groupdiscamt1 end as groupdiscamt1
  from dms_pda_sod a
  left join dms_sod1 b on a.branchid = b.branchid
                      and a.ordernbr = b.origordernbr
                      and a.invtid = b.invtid
                      and b.originallineref = a.lineref
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
      where date(de_updatetime) >= partition_date
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
    select a.*
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
      lat,lng,typ,checktype,
      updatetime,
      numbercico
    from `spatial-vision-343005.staging.d_checkin`
    where date(updatetime) >= partition_date
  )
  ,
  sales_checkin as
  (
	  select *
    from `spatial-vision-343005.staging.sync_dms_sacheckin`
    where date(sa_updatetime) >= partition_date
  )
  ,
  checkin_note as
  (
    select *
    from (  select
              custid,
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
            where date(visitdate) >= partition_date
         )
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
    case when b.checkintype ='Bán Hàng' then f.saordernbr
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
    k.address,
    k.classid,
    k.hcotypeid,
    g.role
  FROM checkin_note b
  LEFT JOIN data_checkin a on a.slsperid = b.slsperid
                          and a.custid =b.custid --and a.branchid =b.branchid
                          and b.salesid =a.numbercico
                          and a.checktype ='IO'
  LEFT JOIN data_checkin c on c.slsperid = b.slsperid
                          and c.custid = b.custid --and c.branchid =b.branchid
                          and b.salesid = c.numbercico
                          and c.checktype ='OO'
  LEFT JOIN order_checkin e on e.slsperid = b.slsperid --and e.branchid =b.branchid
                          and e.numbercico = b.salesid
                          and b.checkintype ='Giao Hàng'--and (d.typ ='PA' or d.typ like 'DE%')
  LEFT JOIN sales_checkin f on f.numbercico = b.salesid
                          and f.slsperid = b.slsperid --and f.branchid =b.branchid
                          and b.checkintype ='Bán Hàng'
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` g on g.username = b.slsperid
  LEFT JOIN `spatial-vision-343005.staging.d_users` h on h.manv = b.slsperid
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` k on k.custid = b.custid and k.branchid = b.branchid
  where k.custname is not null
)
,
result as
(
  SELECT
    Case when a.crtd_prog= 'eCom'then 'Y'
    else 'N' end as check_ecom,
    b.ordernbr_co,
    a.branchid,
    a.ordernbr,
    b.invcnbr,
    d.truckid,
    d.crtd_user_ib AS ng_taoso,
    'tencvbh' AS ten_taoso,
    b.ordernbr as origordernbr,
    a.custid,
    b.ordertype,
    Case when b.status_so ='C' then 'Đã phát hành'
         when b.status_so ='V' then 'Hủy hóa đơn'
         when b.status_so ='I' then 'Tạo hóa đơn'
         when b.status_so ='N' then 'Tạo hóa đơn'
         when b.status_so ='H' then 'Chờ xử lý'
         when b.status_so ='E' then 'Đóng đơn hàng'
         when b.status_so ='D' then 'Đơn hàng tạm'
         else null end as status_so, --Chưa dùng

    b.orderdate_so,
    b.crtd_user_so,
    b.crtd_datetime_so,b.lupd_datetime_so,b.remark_so,
    Case when a.status_pda_so ='C' then 'Đã duyệt đơn hàng'
         when a.status_pda_so ='E' then 'Đóng đơn hàng'
         when a.status_pda_so ='D' then 'Đơn hàng tạm'
         when a.status_pda_so ='H' then 'Chờ xử lý duyệt đơn hàng'
         when a.status_pda_so ='V' then 'Hủy đơn hàng'
         when a.status_pda_so ='X' then 'Đóng đơn hàng tạm'
         else null end as status_pda_so, -- Trạng thái đơn hàng
    a.slsperid_pda_so, -- Người bán hàng
    b.slsperid_so,
    a.crtd_datetime_pda_so as ngaytaodon, -- Ngày tạo đơn
    a.crtd_user_pda_so, -- Người tạo đơn
    Case when  a.status_pda_so in ('C','V','E') then
    a.lupd_datetime_pda_so  else null end as ngayduyetdon, -- Ngày duyệt đơn
    a.crtd_datetime_pda_so,
    a.lupd_datetime_pda_so,
    Case when a.status_pda_so in('C','E','V') then
    a.lupd_user_pda_so else null end as lupd_user_pda_so, -- Người duyệt đơn
    a.remark_pda_so,
    a.deliverytime,
    -- c.refnbr,c.invcnbr,
    -- Case when c.invcnbr is not null or c.invcnbr <> '' then 'Đã phát hành HĐ'
    --     else 'Chưa phát hành HĐ' end as status_iv,
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
         when b.status_so is null and a.status_pda_so ='H' then 'Chờ xử lý duyệt đơn hàng'
         when b.status_so is null and a.status_pda_so ='V' then 'Hủy đơn hàng'
         when b.status_so is null and a.status_pda_so ='X' then 'Đóng đơn hàng tạm'
         else null end as status_iv, -- Trạng thái phát hành hóa đơn
    -- c.crtd_datetime_iv,
    -- Case when b.status_so in ('C') then
    Case when b.status_so = 'C' then b.orderdate_so
    else null end as ngayphathanhhd, -- Ngày phát hành hóa đơn
    -- Case when b.status_so in('C') then
    b.lupd_user_so  as lupd_user_so, -- Người phát hành hóa đơn

    Case when  d.status_ib ='C' then 'Đã chốt sổ'
         when  d.status_ib ='H' then 'Chưa xác nhận chốt sổ'
         else null end as status_ib, -- Trạng thái tạo sổ

    d.crtd_user_ib as crtd_user_ib, -- Người tạo sổ
    d.slsperid_ib,
    d.crtd_datetime_ib as ngaytaoso, -- Ngày tạo sổ
    d.lupd_datetime_ib,
    Case when d.status_ib ='C' and d.deliveryunit ='TP'  then d.crtd_user_ib
         when d.status_ib ='C' then e.crtd_user_dv
         else null end as crtd_user_dv,  -- Người chốt sổ
    Case when d.status_ib ='C' and d.deliveryunit ='TP' then ifnull(d.lupd_datetime_ib,ifnull(e.crtd_datetime_dv,d.lupd_datetime_ib1))
         when d.status_ib ='C' and e.status_dv <> 'C' then ifnull(d.lupd_datetime_ib,ifnull(e.crtd_datetime_dv,d.lupd_datetime_ib1)) --e.crtd_datetime_dv
         when d.status_ib ='C' and e.status_dv ='C' then ifnull(d.lupd_datetime_ib,ifnull(e.crtd_datetime_dv,d.lupd_datetime_ib1)) --and d.lupd_datetime_ib <= e.crtd_datetime_dv
         else null end as ngaychotso, -- Ngày chốt sổ
    d.batnbr,
    -- d.deliverytime_ibd,d.crtd_user_ibd,d.crtd_datetime_ibd,
    case when d.deliveryunit = 'CW' then 'Chành Xe'
          when d.deliveryunit = 'PN' then 'Pha Nam'
          when d.deliveryunit = 'TP' then 'NVC' else null end as deliveryunit,
    Case when e.status_dv ='C' then 'Đã giao hàng'
         when d.status_ib ='C'  and d.deliveryunit ='TP' then 'Đã giao hàng'
         when e.status_dv ='A' then 'Đã xác nhận - Sẵn sàng giao' -- Đã chốt sổ
         when e.status_dv ='D' then 'KH không nhận'
         when e.status_dv ='H' then 'Chưa xác nhận' -- Chưa chốt sổ
         when e.status_dv ='R' then 'Từ chối giao hàng'
         when e.status_dv ='E' then 'Không tiếp tục giao hàng'
         else null end as status_dv,	 -- Trạng thái giao hàng
    e.crtd_datetime_dv,
    Case when e.status_dv in ('C','D','R','E','A','H','L') then e.slsperid_dv else null end as slsperid_dv, -- Người giao hàng
    Case when e.status_dv in ('C','D','R','E','A','H','L') then e.lupd_datetime_dv else null end as ngaygiaohang, -- Ngày giao hàng
    f.crtd_datetime_err,f.lupd_datetime_err, f.errormessage,
   (select max(inserted_at) from `staging.sync_dms_so`) as inserted_at
  FROM pda_so a
  LEFT JOIN mapping_so b on a.ordernbr = b.origordernbr and a.branchid =b.branchid
  LEFT JOIN mapping_ib d on d.branchid = a.branchid and a.ordernbr = d.ordernbr
  LEFT JOIN mapping_dv e on e.branchid = a.branchid and e.ordernbr = a.ordernbr and d.batnbr =e.batnbr
  LEFT JOIN dms_error f on f.branchid = a.branchid and f.ordernbr = a.ordernbr
)
, result1 as
(
  select
    distinct a.*,
    g.role,
    g.firstname AS mds_sxh,
    b2.tencvbh AS mds,
    b2.tenquanlytt AS sup_mds,
    b2.tenquanlykhuvuc AS mng_mds,
    Case
         when a.ordernbr_co ='Hủy HĐ' then 'Hủy hóa đơn'
         when a.status_pda_so ='Đóng đơn hàng' then 'Đóng đơn hàng'
         when a.status_pda_so ='Đóng đơn hàng tạm' then 'Đóng đơn hàng'
        --  when a.status_iv ='Đã phát hành hóa đơn' and a.ordernbr_co ='Hủy HĐ' and status_dv is null then 'Hủy hóa đơn'
         when a.status_iv ='Hủy hóa đơn' then 'Hủy hóa đơn'
         when a.status_iv ='Đã phát hành hóa đơn' and status_ib = 'Đã chốt sổ' and status_dv ='Đã giao hàng' and status_pda_so = 'Đã duyệt đơn hàng' then 'Đã giao hàng'
         when a.status_iv ='Đã phát hành hóa đơn' and status_ib = 'Đã chốt sổ' and status_dv ='Không tiếp tục giao hàng' then 'Không tiếp tục giao hàng'
         when a.status_iv ='Đã phát hành hóa đơn' and status_ib = 'Đã chốt sổ' and status_dv ='Chưa xác nhận' then 'Đã chốt sổ'
         when a.status_iv ='Đã phát hành hóa đơn' and status_ib = 'Đã chốt sổ' and status_dv ='Đã xác nhận' then 'Xác nhận (Nhận hàng)'
         when a.status_iv ='Đã phát hành hóa đơn' and status_ib = 'Đã chốt sổ' and status_dv not in ('Đã giao hàng','Không tiếp tục giao hàng') then 'Xác nhận (Nhận hàng)'
         when a.status_iv ='Đã phát hành hóa đơn' and status_ib = 'Đã chốt sổ' then 'Đã chốt sổ'
         when a.status_iv ='Đã phát hành hóa đơn' and (status_ib not in ( 'Đã chốt sổ' ) or status_ib is null ) then 'Đã phát hành hóa đơn'
         when a.status_iv not in ('Đã phát hành hóa đơn','Hủy hóa đơn') and status_pda_so ='Đã duyệt đơn hàng' then 'Đã duyệt đơn hàng'
         when a.status_iv not in ('Đã phát hành hóa đơn','Hủy hóa đơn') and status_pda_so not in ('Đã duyệt đơn hàng') then 'Tạo mới'
         else null end as trangthaidon,
    Case when ngayduyetdon is null  then null else round(datetime_diff(ngayduyetdon,ngaytaodon,minute)/60,2) end as t0,
    Case when ngayphathanhhd is null then null else round(datetime_diff(ngayphathanhhd,ngayduyetdon,minute)/60,2) end as t1,
    Case when ngaytaoso is null then null else round(datetime_diff(ngaytaoso,ngayphathanhhd,minute)/60,2) end as t2,
    Case when ngaychotso is null then null else round(datetime_diff(ngaychotso,ngaytaoso,minute)/60,2) end as t3,
    Case when ngaychotso is null then null else round(datetime_diff(ngaychotso,ngayduyetdon,minute)/60,2) end as t3_1,
    Case when ngaygiaohang is null then null else round(datetime_diff(ngaygiaohang,ngaychotso,minute)/60,2) end as t4,
    Case when status_ib='Đã chốt sổ' and a.deliveryunit ='NVC' then round(datetime_diff(ngaychotso,ngaytaodon,minute)/60,2)
         when status_ib='Đã chốt sổ' and a.deliveryunit ='NVC' and ngaychotso is null then round(datetime_diff(CURRENT_TIMESTAMP() + interval 7 hour,ngaytaodon,minute)/60,2)
         when ngaygiaohang is not null then round(datetime_diff(ngaygiaohang,ngaytaodon,minute)/60,2)
         else round(datetime_diff(CURRENT_TIMESTAMP() + interval 7 hour,ngaytaodon,minute)/60,2) end as full_leadtime ,
    Case when extract(DAYOFWEEK from ngaytaodon) >= 2 and extract(DAYOFWEEK from ngaytaodon) <5 then datetime_add(ngaytaodon,interval 36 hour) --đơn hàng từ thứ 2 đến thứ 4
         when extract(DAYOFWEEK from ngaytaodon) = 5 and extract(hour from ngaytaodon) < 12 then datetime_add(ngaytaodon,interval 36 hour) -- đơn hàng ngày thứ 5 trước 12h trưa
         when extract(DAYOFWEEK from ngaytaodon) = 5 and extract(hour from ngaytaodon) >= 12 then datetime_add(ngaytaodon,interval 72 hour) -- đơn hàng ngày thứ 5 sau 12h trưa
         when extract(DAYOFWEEK from ngaytaodon) = 6 and extract(hour from ngaytaodon) < 12 then datetime_add(ngaytaodon,interval 72 hour) -- đơn hàng ngày thứ 6 trước 12h trưa
         when extract(DAYOFWEEK from ngaytaodon) = 6 and extract(hour from ngaytaodon) >= 12 then datetime_add(ngaytaodon,interval 84 hour)  -- đơn hàng ngày thứ 6 sau 12h trưa
         when extract(DAYOFWEEK from ngaytaodon) = 7 and extract(hour from ngaytaodon) < 12 then datetime_add(ngaytaodon,interval 84 hour) -- đơn hàng ngày thứ 7 trước 12h
         when extract(DAYOFWEEK from ngaytaodon) = 7 and extract(hour from ngaytaodon) >= 12 then datetime_add( datetime_trunc(ngaytaodon,day) , interval 84 hour) -- đơn hàng ngày thứ 7 sau 12h
         when extract(DAYOFWEEK from ngaytaodon) = 1 then datetime_add( datetime_trunc(ngaytaodon,day) , interval 60 hour)-- đơn hàng ngày chủ nhật
         else null end as ship_on_time_sla,
    Case when b.firstname is null then a.crtd_user_pda_so else b.firstname end as nguoitaodon,
    Case when c.firstname is null then a.lupd_user_pda_so else
    c.firstname end as nguoiduyetdon,
    Case when d.firstname is null then a.lupd_user_so else
    d.firstname end as nguoiphathanhhd,
    Case when e.firstname is null then  a.crtd_user_ib else e.firstname end as nguoitaoso,
    Case when f.firstname is null then  a.crtd_user_dv else
    f.firstname end as nguoichotso,
    Case when g.firstname is null then  a.slsperid_dv else
    g.firstname end as nguoigiaohang,
    Case when k1.firstname is null then  a.slsperid_pda_so else
    k1.firstname end as nguoibanhang,
  -- -- Thông tin khách hàng
    h.custname as tenkhachhang,
  -- h.branchid,
    Case when a.branchid in('MR0001','HCM001') then 'Hồ Chí Minh'
         when a.branchid ='MR0003' then 'CÔNG TY TNHH MTV DƯỢC PHA NAM HÀ NỘI'
         when a.branchid in('MR0014','KHA014') then 'Khánh Hòa'
         when a.branchid in('MR0015','DNI015') then 'Đồng Nai'
         when a.branchid ='MR0011' then 'Hải Phòng'
         when a.branchid in('MR0012','NAN012') then 'Nghệ An'
         when a.branchid in('MR0010','HNI010') then 'Hà Nội'
         when a.branchid in('MR0013','DNG013') then 'Đà Nẵng'
         when a.branchid in('MR0016','CTO016') then 'Cần Thơ'
         else h.branchname end as branchname_filter,
    concat(a.branchid,'-',a.ordernbr,'-',h.custname) as filter_order ,
    CASE
      WHEN h.branchname = 'CÔNG TY CỔ PHẦN DƯỢC PHA NAM' OR h.branchid = 'MR0001' THEN 'CHI NHÁNH HCM'
      WHEN h.branchname LIKE '%CHI NHÁNH%' THEN SUBSTRING(h.branchname, 32)
      ELSE h.branchname
    END AS chinhanh,
    h.branchname,
    h.terms,
    h.paymentsform,
    h.channel, --kênh
    h.statedescr, --tỉnh
    h.territorydescr, --khu vuc
    h.active,
    h.phone,
    h.attn as nglienhe,
    k.lineref,
  -- h.custid,
    h.refcustid,
    h.classid,
    h.hcotypeid,
    h.address as addr1,
    h.shoptype, --kênh phụ
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
    Case when k.discamt is null then 0 else k.discamt end as discamt,
    Case when k.docdiscamt is null then 0 else k.docdiscamt end as docdiscamt,
    Case when k.groupdiscamt1 is null then 0 else k.groupdiscamt1 end as groupdiscamt1,
    j.lotsernbr,
    j.expdate,
    o.descr1 as tensp_viettat,
    o.descr as tensp_daydu,
    o.status as status_product,
    o.stkunit as unit_product,
    ot.descr as thongtinxe,
    ot1.descr AS thongtinxe_sxh,
    dr.crtd_user AS donghang_tinh,
    dr1.tencvbh AS nguoidonghang_tinh,
    Case when rd.ordernbr=a.ordernbr and a.branchid =rd.branchid and rd.custid = a.custid then rd.deliveryunit
         when dr.ordernbr=a.ordernbr and a.branchid =dr.branchid and dr.custid = a.custid then dr.deliveryunit
         else null end as deliveryunit_code,
    k.slsperid,
    '' as ma_chuongtrinh,
    '' as ten_chuongtrinh,
    '' as loai_chuongtrinh,
    '' as loai_chinhsach,
    '' as chinhsach_tichluy,
    '' as chinhsach_banhang,
    '' as chinhsach_khuyenmai,
    k.slsperid as ma_nv_pda_sod,
    k1_2.firstname as ten_nv_pda_sod,
    CASE
    WHEN a.deliveryunit = 'Chành Xe' AND dr.ordernbr IS NULL THEN 'Chưa tạo BBGHT'
    WHEN a.deliveryunit = 'NVC' AND rd.ordernbr IS NULL THEN 'Chưa tạo BBGHT'
    ELSE 'Đã tạo BBGHT/Chốt sổ'
    END AS tao_bbght,
    vp.vptt

  from result a
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` b on a.crtd_user_pda_so = b.username
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` c on c.username = a.lupd_user_pda_so
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` d on d.username = a.lupd_user_so
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` e on e.username = a.crtd_user_ib
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` f on f.username = a.crtd_user_dv
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` g on g.username = a.slsperid_dv
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` k1 on k1.username = a.slsperid_pda_so
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` h on h.custid = a.custid
  LEFT JOIN `spatial-vision-343005.staging.d_vptt` vp ON TRIM(UPPER(h.statedescr)) = TRIM(UPPER(vp.tinh))
  LEFT JOIN order_detail k on k.branchid = a.branchid and k.ordernbr_mapping = a.origordernbr
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_users` k1_2 on k1_2.username = k.slsperid
  LEFT JOIN `spatial-vision-343005.staging.d_users` b2 ON a.slsperid_dv = b2.manv
  LEFT JOIN `spatial-vision-343005.staging.d_users` b1 ON a.slsperid_pda_so = b1.manv
  LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid` o on o.invtid = k.invtid
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_lt` j on j.branchid = k.branchid and k.ordernbr_mapping = j.ordernbr and j.omlineref = k.lineref and date(j.crtd_datetime) >= partition_date
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_rd` rd on rd.ordernbr=a.ordernbr and a.branchid =rd.branchid and rd.custid = a.custid
and date(rd.crtd_datetime) >= partition_date
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_dr` dr on dr.ordernbr=a.ordernbr and a.branchid =dr.branchid and dr.custid = a.custid
and date(dr.crtd_datetime) >= partition_date
LEFT JOIN `spatial-vision-343005.staging.d_users` dr1 ON dr.crtd_user = dr1.manv
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_ot` ot on ot.branchid=a.branchid and ot.code=ifnull(ifnull(dr.truckid,rd.truckid),a.truckid)
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_ot` ot1 ON ot1.branchid = a.branchid AND ot1.code = a.truckid
  where  a.ordertype in ('IN','DP','UP') or a.ordertype is null
)

  select
    a.*,
    Case when ngaygiaohang is not null and ngaygiaohang <= ship_on_time_sla then 'Giao hàng đúng hạn'
         when ngaygiaohang is not null and ngaygiaohang > ship_on_time_sla then 'Trễ hạn giao hàng'
         when ngaygiaohang is null and deliveryunit ='NVC' and ngaychotso <= ship_on_time_sla then 'Giao hàng đúng hạn'
         when ngaygiaohang is null and deliveryunit ='NVC' and ngaychotso > ship_on_time_sla then 'Trễ hạn giao hàng'
         when ngaygiaohang is null and ship_on_time_sla < datetime_add(current_timestamp(),interval 7 hour) and trangthaidon not in ('Đã giao hàng') then 'Trễ hạn giao hàng'
         else null end as check_sot,
    ard.deliveryunitname,gh.note as note_gh,gh.descr as ghichu_gh,
   'bimerap.main@gmail.com'  as sup_mds_email
  from result1 a
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_ard`ard on a.deliveryunit_code = ard.deliveryunitid and ard.branchid =a.branchid
  LEFT JOIN dms_checkin gh on gh.slsperid = a.slsperid_dv and gh.deordernbr = a.ordernbr and gh.custid = a.custid
  LEFT JOIN `spatial-vision-343005.staging.d_users` c on c.manv =ifnull(a.slsperid_dv,a.crtd_user_dv)
;

COMMIT TRANSACTION;
END;
