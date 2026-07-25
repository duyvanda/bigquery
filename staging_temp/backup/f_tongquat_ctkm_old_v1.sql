CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_tongquat_ctkm_old_v1()
BEGIN 

TRUNCATE TABLE staging_temp.f_tongquat_ctkm_temp;

INSERT INTO `staging_temp.f_tongquat_ctkm_temp`

( 

-- Create or replace table `staging_temp.f_tongquat_ctkm_temp`
-- partition by date(ngaychungtu)
-- cluster by discseq,mahd,makhdms,manv
-- as

with _ctkm as
(
  select 
  discidpn, 
  descr, 
  branchid, 
  discid, 
  discseq, 
  ordernbr,
  discamt,
  disctblamt,
  split(
  case
  when groupreflineref is null then solineref
  when solineref = '' or solineref is null or freeitemqty < 1 then groupreflineref
  else concat(groupreflineref,",",solineref) end
  ) as groupreflineref
  from `staging.f_orddisc_all`
  -- where ordernbr = 'HL0-1023-09331'
),

ctkm as
(
  select 
  distinct
  discidpn, 
  descr, 
  branchid, 
  discid, 
  discseq, 
  ordernbr,
  groupreflineref,
  discamt,
  disctblamt,
  FROM _ctkm, _ctkm.groupreflineref AS groupreflineref
),



discamt as
(
  SELECT branchid, ordernbr, lineref, sum(discamt + groupdiscamt1 + docdiscamt ) as discamt  FROM `spatial-vision-343005.staging.sync_dms_sod1` 
  WHERE (discamt + groupdiscamt1 + docdiscamt) > 0
  group by 1,2,3
)
,

group_p as
(
  SELECT
  a.discidpn,
  a.ordernbr, 
  a.branchid, 
  groupreflineref as group_split,
  sum(discamt) as discamt,
  sum(disctblamt) as disctblamt,
  max(a.discseq) as discseq,
  max(b.discounttype) as discounttype,
  max(b.discountdescr) as discountdescr,
  max(a.descr) as descr,
  max(b.startdate) as startdate,
  max(b.enddate) as enddate,
  max (b.statusname) as statusname
  FROM ctkm a
  left join `spatial-vision-343005.staging.d_discseq` b on a.discseq = b.discseq
  group by 1,2,3,4
)
,



tuyenban as 
(
  with data_tuyen as 
    (
      SELECT 
        -- thang,
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


result as
(
  select
    b.discseq,
    b.discidpn,
    -- case when b.loai_ctkm = 'L' then 'Dòng Sản phẩm'
    --      when b.loai_ctkm = 'D' then 'Chứng từ'
    --      when b.loai_ctkm = 'G' then 'Nhóm sản phẩm'
    --      else b.loai_ctkm end as loai_ctkm,
    b.descr,  
    b.startdate,
    b.enddate,   
    b.discounttype as loai_ct,
    b.discountdescr as apdung,
    a.macongtycn,
    a.congtycn,
    a.ngaychungtu,
    a.sodondathang,
    a.mahd,
    a.makhdms,
    a.tenkhachhang,
    a.hoadon,
    a.makenhkh,
    a.makenhphu,
    a.tentinhkh,
    a.tenquanhuyen,
    a.masanpham,
    a.tensanphamviettat,
    a.tensanphamnb, 
    a.lineref, 
    a.soluong,
    a.dongiachuavat,
    a.dongiacovat,
    a.doanhsochuavat, 
    a.doanhsocovat,
    a.manv,
    a.tencvbh,
    a.tenquanlytt,
    a.tenquanlykhuvuc,
    a.tenquanlyvung,
    case when statusname = 'Đang hoạt động' and date(b.enddate) >= current_date() then 1  else 0 end as active,
    case when a.doanhsochuavat = 0 then 1 else 0 end as sp_kmai,

    case when makenhkh = 'TP'
              and a.manv in ('MR1682KN','MR2504','MR1232','MR0806','MR2608','MR2111','MR1682','MR2504KN','MR1232KN','MR0806KN','MR2608KN','MR2111KN') 
              then ifnull(o.macrs,o1.macrs)
         when (a.manv = 'TMDT_001' and k.tenquanlytt_bh = 'Nguyễn Văn Tiến') then ifnull(o.macrs,o1.macrs)
         when (a.manv = 'TMDT_001' and k.tenquanlytt_bh <> 'Nguyễn Văn Tiến') then c.slsperid
         when (a.manv = 'TMDT_001') then ifnull(o.macrs,o1.macrs)
         when  k1.tenquanlytt_bh = 'Nguyễn Văn Tiến' and makenhphu not in ('SI','SI23','CTD') then ifnull(o.macrs,o1.macrs)
         else a.manv end as ma_nvbh,
    -- dis.discamt as total_discamt,
    (a.soluong * a.dongiacovat)/b.disctblamt*b.discamt as discamt,
    dis.discamt as lineref_total_discamt,
    kh.hcoid,
    kh.hcotypeid,
    kh.shortterritorydescr
  from `spatial-vision-343005.staging.f_sales` a
  left join discamt dis on a.mahd = dis.ordernbr and a.macongtycn = dis.branchid and a.lineref = dis.lineref
  inner join group_p b on a.mahd = b.ordernbr and a.macongtycn = b.branchid and group_split = a.lineref
  left join tuyenban c on a.makhdms = c.custid
  left join `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` o on o.phuongxa is not null --and o.ncrm = 'Lương Trịnh Thắng'
                                                                             and a.tentinhkh = o.tinhtp 
                                                                             and a.tenquanhuyen = o.quanhuyen 
                                                                             and a.phuongxa = o.phuongxa
  left join `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` o1 on o1.phuongxa is null --and o1.ncrm = 'Lương Trịnh Thắng'
                                                                              and a.tentinhkh = o1.tinhtp 
                                                                              and a.tenquanhuyen = o1.quanhuyen
  left join `spatial-vision-343005.staging.d_users` k on c.slsperid = k.manv
  left join `spatial-vision-343005.staging.d_users` k1 on a.manv = k1.manv
  left join `spatial-vision-343005.staging.d_master_khachhang` kh on a.makhdms = kh.custid

)

select a.*,
  b.tencvbh as ten_nvbh,
  b.tenquanlytt_bh,
from result a
left join `spatial-vision-343005.staging.d_users` b on a.ma_nvbh = b.manv

);

Create or replace table `warehouse.f_tongquat_ctkm`

copy `staging_temp.f_tongquat_ctkm_temp`;

END;