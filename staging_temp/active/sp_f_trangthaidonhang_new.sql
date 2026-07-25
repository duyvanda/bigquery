CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_trangthaidonhang_new()
BEGIN

-- DECLARE partition_date DATE DEFAULT '2024-01-01';
DECLARE partition_date DATE DEFAULT DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH), MONTH);

-- TRUNCATE TABLE staging_temp.f_trangthaidonhang_new_temp;
-- INSERT INTO staging_temp.f_trangthaidonhang_new_temp
-- (
-- Create or replace table staging_temp.f_trangthaidonhang_new_temp
-- partition by date(crtd_datetime)
-- as
-- (
-- DECLARE partition_date DATE DEFAULT '2024-01-01';
BEGIN TRANSACTION;
DELETE FROM
    `warehouse.f_trangthaidonhang_new`
WHERE
    DATE(crtd_datetime) >= DATE(partition_date);

INSERT INTO
    `warehouse.f_trangthaidonhang_new`
WITH ctkm as
(

  select 1
  -- select 
  --   distinct discidpn, 
  --   descr, 
  --   branchid, 
  --   discid, 
  --   discseq, 
  --   ordernbr, 
  --   ifnull(groupreflineref,solineref) as groupreflineref
  -- from `staging.f_orddisc_all` 
)
,

tuyenban as
(
  with data_tuyen as
    (
      SELECT 
        a.custid,
        a.slsperid,
        a.crtd_datetime,
        Case when a.routetype in ('B','D') then 1 else 2 end as routetype,
        b.tenquanlytt_bh
      FROM `spatial-vision-343005.staging.sync_dms_srm` a
      left join `spatial-vision-343005.staging.d_users` b on a.slsperid = b.manv
      where a.delroutedet is false --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
    )
      select * 
      from (  select *,
                row_number() over (partition by custid order by routetype asc,crtd_datetime desc) as loc  
              from data_tuyen
           )
      where loc =1 --and custid  = '008817'
)
,

group_p as ---- nối ctkm
(
  select 1
  -- SELECT
  --   a.discseq,
  --   a.discidpn,
  --   b.discounttype,
  --   b.discountdescr,
  --   a.descr,
  --   a.ordernbr, 
  --   a.branchid, 
  --   b.startdate,
  --   b.enddate,
  --   b.statusname,
  --   groupreflineref as group_split
  -- FROM ctkm a
  -- left join `spatial-vision-343005.staging.d_discseq` b on a.discseq = b.discseq
  -- left join ctkm c on a.branchid = c.branchid and a.discseq = c.discseq and a.ordernbr = c.ordernbr
  -- WHERE a.discidpn = '202308-DH-CPA33-PMC-PCL-CTD-SI-LADOI' and a.ordernbr = 'HL4-0823-02232'
)
,

chinhanh as
(
  select 
    distinct macongtycn, 
    congtycn
  from `spatial-vision-343005.staging.f_sales`
  where date(ngaychungtu)>=partition_date
)
,

trangthai_giaohang as
(
  with b1 as
  (
    select 
      branchid,
      ordernbr,
      status,
      case when status = 'A' then 'Đã xác nhận'
          when status = 'C' then 'Đã giao hàng'
          when status = 'D' then 'KH không nhận'
          when status = 'H' then 'Chưa xác nhận'
          when status = 'R' then 'Từ chối giao hàng'
          when status = 'E' then 'Không tiếp tục giao hàng'
          else status end as trangthaigiaohang,
      lupd_datetime, 
      row_number()over(partition by branchid,ordernbr order by sequence ,lupd_datetime desc) as loc
    from `spatial-vision-343005.staging.sync_dms_dv` 
    order by lupd_datetime desc
  )
  select * from b1 where loc = 1
)

, gio_tao_don as (
  select ordernbr as origordernbr, branchid, crtd_user, min(crtd_datetime) as crtd_datetime
  FROM `spatial-vision-343005.staging.sync_dms_pda_so` a
  where date(a.crtd_datetime)>= partition_date
  group by all
)

, man_hinh_tao_don as (
  select distinct ordernbr as origordernbr, branchid, crtd_prog as man_hinh_tao_don
  FROM `spatial-vision-343005.staging.sync_dms_pda_so` a
  where date(a.crtd_datetime)>= partition_date
  group by all
)

, nguoi_duyet_don as (
  select distinct ordernbr as origordernbr, branchid, lupd_user
  FROM `spatial-vision-343005.staging.sync_dms_pda_so` a
  where date(a.crtd_datetime)>= partition_date
  group by all
)

, dh_co_hoadon as
(
  SELECT 
    distinct a.pk,
    a.branchid,
    a.origordernbr as ordernbr,
    c.batchexpform,
    a.custid,
    cast(a.orderdate as timestamp) as orderdate,
    a.ordertype,
    a.slsperid,
    ifnull(td.crtd_user, a.crtd_user) as crtd_user,
    cast (ifnull(td.crtd_datetime, a.crtd_datetime) as TIMESTAMP) as crtd_datetime,
    ifnull(dd.lupd_user, a.lupd_user) as lupd_user,
    cast (a.lupd_datetime as TIMESTAMP) as lupd_datetime, 
    a.remark,
    cast(null as string) as remark_km,
    cast(a.invcnbr as string) as invcnbr,
    a.invcnote,
    c.statedescr,
    c.districtdescr,
    c.wardname,
    c.channel,
    c.shoptype,
    c.hcoid,
    c.hcotypeid,
    c.custname,
    c.territorydescr,
    b.invtid,
    b.slsprice,
    b.ordernbr as ma_hd,
    b.lineref  as LineRef,
    b.lineqty as LineQty,
    Case when freeitem = true then 0 else  b.beforevatprice * b.lineqty end as thanhtien_truocthue,
    Case when freeitem = true then 0 else b.aftervatprice * b.lineqty end as thanhtien_sauthue,
    e.descr as tensp,
    e.classid,
    g.congtycn,
    case when a.status in ('C','I','N') THEN 'Đã Duyệt Đơn Hàng' 
         when a.status in ('V') THEN 'Đóng Đơn Hàng'
         else a.status end AS trangthai_donhang,
    case when a.status = 'C' THEN 'Đã phát hành'
         when a.status = 'V' THEN 'Hủy hóa đơn' 
         when a.status = 'I' THEN 'Tạo hóa đơn' 
         when a.status = 'N' THEN 'Tạo hóa đơn' 
         when a.status = 'H' THEN 'Chờ Xử Lý'
         when a.status = 'E' THEN 'Đóng Đơn Hàng'
         when a.status = 'D' THEN 'Đơn Hàng Tạm'          
         else a.status END as trangthai_hoadon,
    h.trangthaigiaohang,
    b.freeitem,
    mhtd.man_hinh_tao_don

  FROM `spatial-vision-343005.staging.sync_dms_so` a
  left join `spatial-vision-343005.staging.sync_dms_sod1` b on a.ordernbr = b.ordernbr and a.branchid = b.branchid 
  and date(b.crtd_datetime)>= partition_date
  left join `spatial-vision-343005.staging.d_master_khachhang` c on a.custid = c.custid
  left join `spatial-vision-343005.staging.d_dms_master_invtid` e on b.invtid = e.invtid
  left join gio_tao_don td on td.origordernbr = a.origordernbr and a.branchid = td.branchid
  left join man_hinh_tao_don mhtd on mhtd.origordernbr = a.origordernbr and a.branchid = mhtd.branchid
  left join chinhanh g on a.branchid = g.macongtycn
  left join trangthai_giaohang h on a.branchid = h.branchid and a.origordernbr = h.ordernbr
  left join nguoi_duyet_don dd on a.branchid = dd.branchid and a.origordernbr = dd.origordernbr
  WHERE channel not in ('OTH_LAB','NB')
  and date(a.crtd_datetime)>= partition_date)
,

dh_chuaco_hoadon as
(
  SELECT 
    distinct a.pk,
    a.branchid,
    a.ordernbr,
    d.batchexpform,
    a.custid,
    cast(null as timestamp) as orderdate,
    a.ordertype,
    a.slsperid,
    a.crtd_user,
    cast(a.crtd_datetime as TIMESTAMP) as crtd_datetime,
    a.lupd_user,

    case when a.status = 'C' then cast(a.lupd_datetime as TIMESTAMP) else null
    end as lupd_datetime,

    a.remark,
    a.remark_km,
    cast(null as string) as invcnbr,
    cast(null as string) as invcnote,
    d.statedescr,
    d.districtdescr,
    d.wardname,
    d.channel,
    d.shoptype,
    d.hcoid,
    d.hcotypeid,
    d.custname,
    d.territorydescr,
    e.invtid,
    c.slsprice,
    cast(null as string) as ma_hd,
    lineref as LineRef,
    c.lineqty as LineQty,
    Case when freeitem= true then 0 else c.beforevatprice * c.lineqty end as thanhtien_truocthue,
    Case when freeitem= true then 0 else  c.aftervatprice * c.lineqty end as thanhtien_sauthue,
    e.descr as tensp,
    e.classid,
    g.congtycn,
    case when a.status = 'C' THEN 'Đã duyệt đơn hàng'
         when a.status = 'E' THEN 'Đóng Đơn Hàng'
         when a.status = 'D' THEN 'Đơn Hàng Tạm' 
         when a.status = 'H' THEN 'Chờ Xử Lý'
         when a.status = 'V' THEN 'Hủy Đơn Hàng'         
         else a.status END as trangthai_donhang,
    
    cast(null as string) as  trangthai_hoadon,
    cast(null as string) as trangthaigiaohang,
    c.freeitem,
    a.crtd_prog as man_hinh_tao_don

  FROM `spatial-vision-343005.staging.sync_dms_pda_so` a
  left join `spatial-vision-343005.staging.sync_dms_so` b on a.ordernbr = b.origordernbr and a.branchid = b.branchid 
  and date(b.crtd_datetime)>= partition_date
  left join `spatial-vision-343005.staging.sync_dms_pda_sod` c on a.ordernbr = c.ordernbr and a.branchid = c.branchid 
  and date(c.crtd_datetime)>= partition_date
  left join `spatial-vision-343005.staging.d_master_khachhang` d on a.custid = d.custid
  left join `spatial-vision-343005.staging.d_dms_master_invtid` e on c.invtid = e.invtid
  left join chinhanh g on a.branchid = g.macongtycn
  WHERE b.origordernbr is null 
  and date(a.crtd_datetime)>= partition_date
  
  
)
,

total_dh as
(
select * from dh_co_hoadon
union all
select * from dh_chuaco_hoadon
)
,

-- select * from total_dh where ordernbr = 'DL6-0425-01755'

lydo_chuaduyet as
(
  with bang2a as 
  (
    select 
      branchid,
      ordernbr,
      errormessage,
      lupd_datetime,
      row_number() over (partition by ordernbr order by lupd_datetime desc) as loc
    from  `spatial-vision-343005.staging.sync_dms_err` 
  )
  select *
  from bang2a 
  where loc = 1
)
,

result as
(
  select 
    a.*except(freeitem),
  
    case when freeitem = true then 1 else 0 end as sp_km, 

    case when IFNULL(b.errormessage, "None") like '%Không Đủ Tồn Kho Cho Sản Phẩm%' 
          and IFNULL(b.errormessage, "None") not like '%Có Nợ Quá Hạn Hoặc Vượt Hạn Mức Nợ%'
         then a.ordernbr else null end as chuaduyetthieuhang,

    case when IFNULL(b.errormessage, "None") like '%Có Nợ Quá Hạn Hoặc Vượt Hạn Mức Nợ%'
          and IFNULL(b.errormessage, "None") not like '%Không Đủ Tồn Kho Cho Sản Phẩm%' 
         then a.ordernbr else null end as chuaduyetvuongno,

    case when IFNULL(b.errormessage, "None") like '%Không Đủ Tồn Kho Cho Sản Phẩm%'
          and IFNULL(b.errormessage, "None") like '%Có Nợ Quá Hạn Hoặc Vượt Hạn Mức Nợ%'
         then a.ordernbr else null end as chuaduyetthieuhang_vuongno,

    case when ( IFNULL(b.errormessage, "None") like '%Có Nợ Quá Hạn Hoặc Vượt Hạn Mức Nợ%' 
             or IFNULL(b.errormessage, "None") like '%Không Đủ Tồn Kho Cho Sản Phẩm%') = false 
             and a.trangthai_hoadon = 'Đơn Hàng Tạm' 
         then a.ordernbr else null end as chuaduyetdontam,

    case when (IFNULL(b.errormessage, "None") like '%Có Nợ Quá Hạn Hoặc Vượt Hạn Mức Nợ%' 
            or IFNULL(b.errormessage, "None") like '%Không Đủ Tồn Kho Cho Sản Phẩm%' or a.trangthai_hoadon = 'Đơn Hàng Tạm') = false 
            and a.batchexpform = 'LT' 
         then a.ordernbr else null end as chuaduyet_lotien,

    case when (IFNULL(b.errormessage, "None") like '%Có Nợ Quá Hạn Hoặc Vượt Hạn Mức Nợ%' 
            or IFNULL(b.errormessage, "None") like '%Không Đủ Tồn Kho Cho Sản Phẩm%' or a.trangthai_hoadon = 'Đơn Hàng Tạm' or a.batchexpform = 'LT') = false 
            and a.channel = 'INS'  
         then a.ordernbr else null end as chuaduyet_ins,

    case when IFNULL(
                      (
                         IFNULL(b.errormessage, "None") like '%Có Nợ Quá Hạn Hoặc Vượt Hạn Mức Nợ%' 
                      or IFNULL(b.errormessage, "None") like '%Không Đủ Tồn Kho Cho Sản Phẩm%' 
                      or a.trangthai_hoadon = 'Đơn Hàng Tạm' 
                      or a.batchexpform = 'LT' 
                      or a.channel = 'INS' 
                      )
                      , false
                    ) = false then a.ordernbr else null end as chuaduyetdonkhac,

    case when a.remark like '%thầu%' then 'ĐH load thầu' else null end as dh_loadthau,

    b.errormessage,

    'null' as ma_ctkm,
    'null' as ten_ctkm,
    'null' as nd_ctkm,  
    TIMESTAMP('1900-01-01') as ngaybatdau_ctkm,
    TIMESTAMP('1900-01-01') as ngayketthuc_ctkm,
    'null' as loai_ct,
    'null' as apdung,

    case when a.channel = 'TP' 
            and a.slsperid in ('MR1682KN','MR2504','MR1232','MR0806','MR2608','MR2111','MR1682','MR2504KN','MR1232KN','MR0806KN','MR2608KN','MR2111KN') 
            then ifnull(o.macrs,o1.macrs)
         when (a.slsperid = 'TMDT_001' and e.tenquanlytt_bh = 'Nguyễn Văn Tiến') then ifnull(o.macrs,o1.macrs)
         when (a.slsperid = 'TMDT_001' and e.tenquanlytt_bh <> 'Nguyễn Văn Tiến') then d.slsperid
         when (a.slsperid = 'TMDT_001') then ifnull(o.macrs,o1.macrs)
         when e1.tenquanlytt_bh = 'Nguyễn Văn Tiến' and a.shoptype not in ('SI','SI23','CTD') then ifnull(o.macrs,o1.macrs)
         else a.slsperid end as ma_nvbh,
    f.lotsernbr,
    f.expdate

  from total_dh a
  left join lydo_chuaduyet b on a.ordernbr = b.ordernbr and a.branchid = b.branchid --and a.pk = b.pk
  left join tuyenban d on a.custid = d.custid
  left join `spatial-vision-343005.staging.d_users` e on d.slsperid = e.manv
  left join `spatial-vision-343005.staging.d_users` e1 on a.slsperid = e1.manv
  left join `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` o on o.phuongxa is not null --and o.ncrm = 'Lương Trịnh Thắng'
                                                                             and a.statedescr = o.tinhtp 
                                                                             and a.districtdescr = o.quanhuyen 
                                                                             and a.wardname = o.phuongxa
  left join `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` o1 on o1.phuongxa is null --and o1.ncrm = 'Lương Trịnh Thắng'
                                                                              and a.statedescr = o1.tinhtp 
                                                                              and a.districtdescr = o1.quanhuyen
  left join `staging.sync_dms_lt` f  on a.branchid = f.branchid 
                                    and a.ma_hd = f.ordernbr 
                                    and a.invtid = f.invtid 
                                    and a.LineRef = f.omlineref
                                    and date(f.crtd_datetime) >= partition_date
)
  select
    a.*,
    current_datetime('+7') as update_at,
    case when a.chuaduyetthieuhang is not null then null
        when a.chuaduyetvuongno is not null then null
        when a.chuaduyetthieuhang_vuongno is not null then null
        when a.chuaduyet_lotien is not null then null
        when a.chuaduyet_ins is not null then null
        when a.chuaduyetdontam is not null then null
        when a.chuaduyetdonkhac is not null then a.ordernbr
        else a.ordernbr end as chuaduyetdonkhac_new,
    b.tencvbh,
    b.supid,
    b.tenquanlytt,
    c.tencvbh as ten_nguoi_dat_don

  from result a
  left join `spatial-vision-343005.staging.d_users` b on a.ma_nvbh = b.manv
  left join `spatial-vision-343005.staging.d_users` c on a.crtd_user = c.manv
  ;

COMMIT TRANSACTION;
-- Create or replace table `warehouse.f_trangthaidonhang_new`

-- copy `staging_temp.f_trangthaidonhang_new_temp`;

End;