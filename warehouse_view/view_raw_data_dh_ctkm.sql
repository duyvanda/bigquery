CREATE VIEW `spatial-vision-343005.warehouse.view_raw_data_dh_ctkm`
AS with _ctkm as
(
  select 
  discidpn, 
  descr, 
  branchid, 
  discid, 
  discseq, 
  ordernbr, 
  split(
  case
  when groupreflineref is null then solineref
  when solineref = '' or solineref is null or freeitemqty < 1 then groupreflineref
  else concat(groupreflineref,",",solineref) end
  ) as groupreflineref
  from `staging.f_orddisc_all`  
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
  groupreflineref 
  FROM _ctkm, _ctkm.groupreflineref AS groupreflineref
)
,

discamt as
(
  SELECT branchid, ordernbr, lineref, sum(discamt + groupdiscamt1 + docdiscamt ) as discamt  FROM `spatial-vision-343005.staging.sync_dms_sod1` 
  WHERE (discamt + groupdiscamt1 + docdiscamt) > 0
  group by 1,2,3
)
,
group_p_csbh as
(
  SELECT
  a.ordernbr, 
  a.branchid, 
  groupreflineref as group_split,
  STRING_AGG(a.discidpn,' & ') as discidpn,
  FROM ctkm a
  left join `spatial-vision-343005.staging.d_discseq` b on a.discseq = b.discseq
  where b.discounttype = 'Chính sách bán hàng'
  group by 1,2,3
)

,
group_p_ctkm as
(
  SELECT
  a.ordernbr, 
  a.branchid, 
  groupreflineref as group_split,
  STRING_AGG(a.discidpn,' & ') as discidpn,
  FROM ctkm a
  left join `spatial-vision-343005.staging.d_discseq` b on a.discseq = b.discseq
  where b.discounttype = 'Chương trình khuyến mãi'
  group by 1,2,3
)
,
group_p_cttl as
(
  SELECT
  a.ordernbr, 
  a.branchid, 
  groupreflineref as group_split,
  STRING_AGG(a.discidpn,' & ') as discidpn,
  FROM ctkm a
  left join `spatial-vision-343005.staging.d_discseq` b on a.discseq = b.discseq
  where b.discounttype = 'Chương trình tích lũy trả ngay'
  group by 1,2,3
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
    b1.discidpn as csbh_discidpn,
    b2.discidpn as ctkm_discidpn,
    b3.discidpn as cttl_discidpn,
    a.macongtycn,
    a.congtycn,
    a.ngaychungtu,
    a.sodondathang,
    a.mahd,
    a.makhdms,
    a.tenkhachhang,
    a.hoadon,
    -- ifnull(f.channel,kh.channel) as makenhkh,
    -- ifnull(f.shoptype,kh.shoptype) as makenhphu,
    a.makenhkh,
    a.makenhphu,
    a.tentinhkh,
    a.tenquanhuyen,
    a.masanpham,
    a.tensanphamviettat,
    a.tensanphamnb, 
    a.lineref, 
    a.soluong,
    a.doanhsochuavat, 
    a.doanhsocovat,
    a.manv,
    a.tencvbh,
    a.tenquanlytt,
    a.tenquanlykhuvuc,
    a.tenquanlyvung,
    case when a.doanhsochuavat = 0 then 1 else 0 end as sp_kmai,
    Case 
        when l.col.phan_loai_mcp = 'Rural' 
        or a.manv = 'TMDT_001'
        or a.manv in ("MR1682KN","MR2504","MR1232","MR0806","MR2608","MR2111","MR1682","MR2504KN","MR1232KN","MR0806KN","MR2608KN",
        "MR2111KN","MR2993","MR2993KN","MR3038","MR3038KN","MR2608KN","MR2948","MR2948KN","MR2608")
        or (a.makenhphu not in ('SI23', 'SI', 'CTD') and k1.tenquanlytt = 'Nguyễn Văn Tiến' and ngaychungtu < '2024-01-01') 
        then l.col.ma_nvbh
      else a.manv 
      end as ma_nvbh, 
    dis.discamt,
    -- ifnull(f.hcoid,kh.hcoid) as hcoid,
    kh.hcoid,
    ifnull(f.hcotypeid,kh.hcotypeid) as  hcotypeid, 
    kh.shortterritorydescr,
    tr.brand2023,
    tr.brand,
    tr.brandnew2023,
    tr.branddongnhat,
    Case 
      when makenhkh in ('TP','MT') then spcl2023tp_mt 
      when makenhkh in ('INS','CLC','PCL') then spcl2023pcl_clc_ins  
    else null end as spcl2023_all,
  from `spatial-vision-343005.staging.f_sales` a
  left join discamt dis on a.mahd = dis.ordernbr and a.macongtycn = dis.branchid and a.lineref = dis.lineref
  left join group_p_csbh b1 on a.mahd = b1.ordernbr and a.macongtycn = b1.branchid and b1.group_split = a.lineref
  left join group_p_ctkm b2 on a.mahd = b2.ordernbr and a.macongtycn = b2.branchid and b2.group_split = a.lineref
  left join group_p_cttl b3 on a.mahd = b3.ordernbr and a.macongtycn = b3.branchid and b3.group_split = a.lineref
  LEFT JOIN `warehouse.f_mapping_crs_bytime` l on l.custid = a.makhdms and date_trunc(ngaychungtu,month) = l.thang
  left join `spatial-vision-343005.staging.d_users` k on l.col.ma_nvbh = k.manv
  left join `spatial-vision-343005.staging.d_users` k1 on a.manv = k1.manv
  LEFT JOIN `staging.sync_dms_pda_so` f on a.macongtycn =f.branchid and a.sodondathang =f.ordernbr
  left join `spatial-vision-343005.staging.d_master_khachhang` kh on a.makhdms = kh.custid
  LEFT JOIN `staging.d_nhom_sp_trading` tr on tr.masanpham = a.masanpham

  where date(a.ngaychungtu)>= '2025-01-01' and a.macongtycn != 'DL0001'
)

select a.*,
Case
  when a.manv = 'CX' then 'MR1682'
  else left(b.supid,6)
end as crm,
Case
  when a.manv = 'CX' then 'CX'
  else b.tencvbh
end as ten_nvbh,
  -- b.tencvbh as ten_nvbh,
Case
  when a.manv = 'CX' then 'Đinh Thị Ngọc Mẫn'
  else b.tenquanlytt
end as tenquanlytt_bh,
  -- b.tenquanlytt_bh,
from result a
left join `spatial-vision-343005.staging.d_users` b on a.ma_nvbh = b.manv;