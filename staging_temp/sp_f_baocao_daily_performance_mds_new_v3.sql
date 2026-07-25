CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_daily_performance_mds_new_v3()
BEGIN 
 
 TRUNCATE TABLE staging_temp.f_baocao_daily_performance_mds_new_temp;

 INSERT INTO `staging_temp.f_baocao_daily_performance_mds_new_temp`

(   

-- Create or replace table `staging_temp.f_baocao_daily_performance_mds_new_temp`
-- partition by date(ngaychungtu)
-- cluster by makhdms,sodondathang,tencvbh,tenquanlytt
-- as

with DATA_F_SALES_FIXED as
( 
  WITH DONIR as
  (
    SELECT
      a.macongtycn,
      a.sodondathang as don_ir,
      a.mahd,
      a.masanpham,
      a.tensanphamnb,
      a.kieudonhang,
      c.dh_goc,
      c.origordernbr as mahd_goc,
      c.donvigiaohang,
      c.manvgh,
      c.nguoigiaohang,
      c.trangthaigiaohang,
      c.tennhavanchuyen,
      c.manvghreal,
      c.tennvghreal,
      sum(a.soluong) as soluong,
    FROM `staging.f_sales` a
    INNER JOIN (SELECT 
                  DISTINCT a.sodondathang, 
                  a.mahd, 
                  a.macongtycn, 
                  b.origordernbr, 
                  a.masanpham,
                  c.sodondathang as dh_goc,
                  c.donvigiaohang,
                  c.manvgh,
                  c.nguoigiaohang,
                  c.trangthaigiaohang,
                  c.tennhavanchuyen,
                  c.manvghreal,
                  c.tennvghreal,
                  c.thang
                FROM `staging.f_sales` a
                LEFT JOIN `staging.sync_dms_pda_so` b on a.sodondathang = b.ordernbr 
                                                     and a.macongtycn = b.branchid
                LEFT JOIN `staging.f_sales` c  on b.origordernbr = c.mahd 
                                              and a.masanpham = c.masanpham 
                                              and c.macongtycn = b.branchid 
                                              and c.ngaychungtu >= '2023-10-01' 
                WHERE     a.ngaychungtu >= '2023-10-01' 
                      and a.kieudonhang ='IR' 
                      and b.origordernbr is not null
              ) c  on a.macongtycn = c.macongtycn 
                  and a.sodondathang = c.sodondathang 
                  and a.mahd = c.mahd 
                  and a.masanpham = c.masanpham 
                  and a.thang = c.thang
    WHERE date(a.ngaychungtu) >= '2023-10-01'
    group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
  )
  , 

  capnhat_chinhsua as
  (
    SELECT 
    a.sodondathang,
    a.ngaychungtu,
    case when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) <> EXTRACT (month from a.ngaychungtu))) then null
         when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) = EXTRACT (month from a.ngaychungtu))) then a.sodontrahang 
         when a.kieudonhang = 'IR' THEN ifnull(c.dh_goc,a.sodondathang)
         else a.sodondathang end as ma_dh,

    case when a.kieudonhang = 'CO'then a.sodontrahang 
         when a.kieudonhang = 'IR' then ifnull(c.dh_goc,a.sodondathang)
         else a.sodondathang end as ma_dh_1,

    a.sodontrahang,
    a.ngaytrahang,
    a.macongtycn,
    a.congtycn,
    a.mahd,
    a.hoadon,
    a.makhdms,
    a.makhcu,
    a.tenkhachhang,
    a.tenvungbh,
    a.tenkhuvuc,
    a.tentinhkh,
    a.tenquanhuyen,
    a.phuongxa,
    a.makenhkh,
    a.makenhphu,
    a.mahco,
    a.maphanloaihco,
    a.maphanhanghco,
    a.thtt,
    a.pmt,
    a.masanpham,
    a.tensanphamnb,
    a.tensanphamviettat,
    a.solo,
    
    a.ngaydatdon,
    a.ngaygiaohang,
    a.manv,
    a.tencvbh,
    a.tenquanlytt,
    a.tenquanlykhuvuc,
    a.tenquanlyvung,
    ifnull(a.manvgh,c.manvgh) as manvgh,
    ifnull(a.nguoigiaohang,c.nguoigiaohang) as nguoigiaohang,
    ifnull(a.trangthaigiaohang,c.trangthaigiaohang) as trangthaigiaohang,
    ifnull(a.donvigiaohang,c.donvigiaohang) as donvigiaohang,
    ifnull(a.tennhavanchuyen,c.tennhavanchuyen) as tennhavanchuyen,
    a.kieudonhang,
    a.thang,
    ifnull(a.manvghreal,c.manvghreal) as manvghreal,
    ifnull(a.tennvghreal,c.tennvghreal) as tennvghreal,
    
    case when EXTRACT(month from a.ngaychungtu) = EXTRACT(month from b.crtd_datetime) then b.crtd_user else null end as manv_dh_chanh,
    
    case when ifnull(a.manvghreal,c.manvghreal) is null then ifnull(a.manvgh,c.manvgh) else ifnull(a.manvghreal,c.manvghreal) end as mamds,
    trahangkhacthang,

    sum(a.soluong) as soluong,
    avg(a.dongiacovat) as dongiacovat,
    sum(a.doanhsocovat) as doanhsocovat,
    avg(a.dongiachuavat) as dongiachuavat,
    sum(a.doanhsochuavat) as dschuvat_banhang,
    

    case 
    when trahangkhacthang is true then 0
    when trahangkhacthang is null then sum (a.doanhsochuavat)
    else sum (a.doanhsochuavat) end as dschuvat_giaohang,

    -- case 
    -- when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) <> EXTRACT (month from a.ngaychungtu))) then 0
    -- when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) = EXTRACT (month from a.ngaychungtu))) then sum (a.doanhsochuavat)
    -- else sum (a.doanhsochuavat) end as dschuvat_giaohang,



    FROM `spatial-vision-343005.staging.f_sales` a
    LEFT JOIN DONIR c on a.macongtycn = c.macongtycn 
                     and a.sodondathang = c.don_ir 
                     and a.mahd = c.mahd
                     and a.masanpham = c.masanpham 
    LEFT JOIN `spatial-vision-343005.staging.sync_dms_dr` b  --- BIÊN BẢN GỬI HÀNG TỈNH
            on (case when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) <> EXTRACT (month from a.ngaychungtu))) then null
                      when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) = EXTRACT (month from a.ngaychungtu))) then a.sodontrahang
                      when a.kieudonhang = 'IR' THEN ifnull(c.dh_goc,a.sodondathang)
                      else a.sodondathang end)
            = b.ordernbr
          
    WHERE date (a.ngaychungtu) >= '2023-01-01' 
          and (case when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) <> EXTRACT (month from a.ngaychungtu))) then null
                    when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) = EXTRACT (month from a.ngaychungtu))) then a.sodontrahang 
                    else a.sodondathang end) is not null
          and a.makenhkh not in ('NB','OTH_LAB')
          and a.masanpham not like 'V%'
      
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48
  )

  select
    a.* except(trahangkhacthang) ,
    ifnull(b.donvigiaohang,a.donvigiaohang) as donvigiaohang_fix,
    ifnull(b.manvghreal,a.mamds) as ma_mds_fix,
    ifnull(b.manvdh,a.manv_dh_chanh) as ma_donghang_fix,

    case when ifnull(b.donvigiaohang,a.donvigiaohang) not in ('Nhà vận chuyển','NVC' ) then ifnull(b.manvghreal,a.mamds) 
         else null end as ma_nvgh_tinhluong,

    case when ifnull(b.donvigiaohang,a.donvigiaohang) IN ('Nhà vận chuyển','NVC') then ifnull(b.manvdh,a.mamds)
         when ifnull(b.donvigiaohang,a.donvigiaohang) = 'Chành xe' then ifnull(b.manvdh,a.manv_dh_chanh) 
         else null end as ma_donghang_tinhluong,



    from capnhat_chinhsua a
    left join `spatial-vision-343005.staging.d_dieuchinhmds` b on a.ma_dh = b.sodondathang
)
,

NGAYGIAOHANG as
(
  with dms_dv as 
  (
    select 
      distinct
      branchid,batnbr,
      sequence,
      ordernbr,
      slsperid as slsperid_dv,	
      status as status_dv,	
      crtd_datetime as crtd_datetime_dv,
      crtd_user as crtd_user_dv,
      delivery_date as lupd_datetime_dv,
      inserted_at
    from `spatial-vision-343005.staging.sync_dms_dv`
    where DATE(crtd_datetime) >= "2023-01-01"
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

  select a.* 
  from dms_dv a 
  JOIN max_sequence b on a.branchid = b.branchid 
                      and a.ordernbr = b.ordernbr 
                      and a.batnbr = b.batnbr 
                      and a.sequence = b.max_sequence
                      and b.crtd_datetime = a.crtd_datetime_dv 
)
,

-- SO XUAT HANG
SOXUATHANG as 
(
  -- Tạo sổ
  with dms_ib AS 
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
      -- approvedate as lupd_datetime_ib
      -- đổi qua cột approvedate ngày 9/1/2023
    FROM `spatial-vision-343005.staging.sync_dms_ib`
    WHERE DATE(crtd_datetime) >= "2023-01-01"
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
      transporters,
    FROM`spatial-vision-343005.staging.sync_dms_ibd`
    WHERE DATE(crtd_datetime) >= "2023-01-01" 
  )
  ,

  soxuathang_final as
  (
    SELECT 
      a.*,
      b.ordernbr,
      b.status_ibd,
      b.deliverytime_ibd,
      b.crtd_user_ibd,
      b.crtd_datetime_ibd,
      b.lupd_datetime_ibd,
      b.transporters,
      c.descr as thongtinxe_sxh,
      row_number() over (partition by a.batnbr,b.ordernbr order by crtd_datetime_ib desc) as loc  
    FROM dms_ib a 
    LEFT JOIN dms_ibd b on a.branchid = b.branchid and a.batnbr = b.batnbr
    LEFT JOIN `spatial-vision-343005.staging.sync_dms_ot` c on a.branchid = c.branchid 
                                                           and a.truckid = c.code
    WHERE status_ib = 'C'
  )

  select * from soxuathang_final 
  -- where loc = 1  
)
-- END SO XUAT HANG

,

kpi_leadtime as 
(
  SELECT 
    distinct concat (statedescr,districtdescr) as noi,
    statedescr,
    districtdescr,
    ltfromcrtd as kpi_leadtime
  FROM `spatial-vision-343005.staging.d_leadtimekpi`
  where ltfromcrtd > 0
  GROUP BY 1,2,3,4
)
,

-- Xu ly tuyen ban
TUYENBAN_MDS as 
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

DONCO as
(
  select 
     distinct concat(macongtycn,sodontrahang,hoadon) as noi,
     thang,
     hoadon,
     macongtycn,
     sodontrahang as don_dh,
     sodondathang as don_co,
  FROM `spatial-vision-343005.staging.f_sales` a
  WHERE date (a.ngaychungtu) >= '2023-01-01' 
        and sodontrahang is not null
)
,

DONIR as
(
  SELECT
    a.macongtycn,
    a.sodondathang as don_ir,
    a.mahd,
    a.masanpham,
    a.tensanphamnb,
    a.kieudonhang,
    c.dh_goc as don_dh,
    c.origordernbr as mahd_goc,
    c.donvigiaohang,
    c.manvgh,
    c.nguoigiaohang,
    c.trangthaigiaohang,
    c.tennhavanchuyen,
    c.manvghreal,
    c.tennvghreal,
    sum(a.soluong) as soluong,
  FROM `staging.f_sales` a
  INNER JOIN (SELECT 
                DISTINCT a.sodondathang, 
                a.mahd, 
                a.macongtycn, 
                b.origordernbr, 
                a.masanpham,
                c.sodondathang as dh_goc,
                c.donvigiaohang,
                c.manvgh,
                c.nguoigiaohang,
                c.trangthaigiaohang,
                c.tennhavanchuyen,
                c.manvghreal,
                c.tennvghreal
              FROM `staging.f_sales` a
              LEFT JOIN `staging.sync_dms_pda_so` b on a.sodondathang = b.ordernbr 
                                                   and a.macongtycn = b.branchid
              LEFT JOIN `staging.f_sales` c  on b.origordernbr = c.mahd 
                                            and a.masanpham = c.masanpham 
                                            and c.macongtycn = b.branchid 
                                            and c.ngaychungtu >= '2023-10-01' 
              WHERE     a.ngaychungtu >= '2023-10-01' 
                    and a.kieudonhang ='IR' 
                    and b.origordernbr is not null
            ) c on a.macongtycn = c.macongtycn 
               and a.sodondathang = c.sodondathang 
               and a.mahd = c.mahd 
               and a.masanpham = c.masanpham
  WHERE date(a.ngaychungtu) >= '2023-10-01'
  group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
)
,

suco as
(
  with b1 as
  (
    select 
      distinct ordernbr, 
      descr, 
      crtd_datetime,
      concat(date(crtd_datetime)," | ",descr) as noidung_suco  
    FROM `spatial-vision-343005.staging.sync_dms_delihistory` 
    order by crtd_datetime asc
  )
    select 
      ordernbr, 
      STRING_AGG(noidung_suco , " & ") as suco
    from b1
    -- where ordernbr = 'DH3-0622-01146'
    group by 1
)
,

data_giaohang as
(
  with thongtingiaohang as
  (
    select a.* ,
      b.crtd_datetime_dv as ngaychotso,
      b.lupd_datetime_dv as ngaygiaohang_fix,
      b.status_dv,

      c.batnbr as soxuathang,
      c.thongtinxe_sxh,
      case when b.lupd_datetime_dv is null 
           then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.crtd_datetime,minute)/60,2)
           else round(datetime_diff (b.lupd_datetime_dv,h.crtd_datetime,minute)/60,2) end as full_leadtime,

      case when b.lupd_datetime_dv is null 
           then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.ApprovalDate,minute)/60,2)
           else round(datetime_diff (b.lupd_datetime_dv,h.ApprovalDate,minute)/60,2) end as full_leadtime_duyet,    

      case when a.thang >= '2023-08-01' and tentinhkh = 'Sóc Trăng' then 48 else d.kpi_leadtime end as kpi_leadtime,
      
      case when a.donvigiaohang_fix in ('Nhà vận chuyển','NVC') then null 
           when a.donvigiaohang_fix not in ('Nhà vận chuyển','NVC')
                and (case when b.lupd_datetime_dv is null 
                          then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.crtd_datetime,minute)/60,2)
                          else round(datetime_diff (b.lupd_datetime_dv,h.crtd_datetime,minute)/60,2) end) 
                  > (case when a.thang >= '2023-08-01' and tentinhkh = 'Sóc Trăng' then 48 else d.kpi_leadtime end) 
           then 'Ko dat' 
           else 'Dat' end as danhgia_leadtime,
      
      h.crtd_datetime as ngaytaodon,
      h.ApprovalDate as ngayduyetdon,
      h.remark as crs_mds_note,
      h.remark_km as cx_note,
      i.address as diachikhachhang,

      e.tencvbh as ten_nvgh_tinhluong,
      e.role_luong_mds as role_giaohang_tinhluong,
      e.role_luong_mds_phanloai as role_giaohang_tinhluong_pl,
      e.supid as masup_gh,
      e.tenquanlytt as tensup_gh,
      e.asm as mamgr_gh,
      e.tenquanlykhuvuc as tenmgr_gh,
      e.rsmid as madir_gh,
      e.tenquanlyvung as tendir_gh,
      f.tencvbh as ten_donghang_tinhluong,
      f.role_luong_mds as role_donghang_tinhluong,
      f.role_luong_mds_phanloai as role_donghang_tinhluong_pl,
      f.supid as masup_donghang,
      f.tenquanlytt as tensup_donghang,
      f.asm as mamgr_donghang,
      f.tenquanlykhuvuc as tenmgr_donghang,

      case when makenhkh = 'TP' 
                and a.manv in ('MR1682KN','MR2504','MR1232','MR0806','MR2608','MR2111','MR1682',
                               'MR2504KN','MR1232KN','MR0806KN','MR2608KN','MR2111KN') 
                then ifnull(o.macrs,o1.macrs)
           when (a.manv = 'TMDT_001' and k.tenquanlytt_bh = 'Nguyễn Văn Tiến') then ifnull(o.macrs,o1.macrs)
           when (a.manv = 'TMDT_001' and k.tenquanlytt_bh <> 'Nguyễn Văn Tiến') then g.slsperid
           when (a.manv = 'TMDT_001') then ifnull(o.macrs,o1.macrs)
           when  k1.tenquanlytt_bh = 'Nguyễn Văn Tiến' and makenhphu not in ('SI','SI23','CTD') then ifnull(o.macrs,o1.macrs)
           else a.manv end as ma_nvbh,

      m.don_co,
      m1.don_ir,
      u.suco,

      case when (a.ngaychungtu >= '2023-07-01' and a.ngaychungtu <= '2023-08-31') then l.manv
      --------------------------Code update mới
      when manvloghub is not null and manvloghub2 is null and a.ma_nvgh_tinhluong <> p.manvloghub THEN p.manvloghub
      ---Trùng mã tài xế xe
      when manvloghub2 is not null and a.ma_nvgh_tinhluong <> p.manvloghub and extract(hour from a.ngaychungtu) between 0 and 11 then p.manvloghub
      when manvloghub2 is not null and  a.ma_nvgh_tinhluong <> p.manvloghub2 and extract(hour from a.ngaychungtu) between 12 and 23 then p.manvloghub2 
      -----------------------------------Code update cũ ---------------------------                                    

          --  when (a.ngaychungtu >= '2023-09-01' and a.ngaychungtu <= '2023-12-25') and a.donvigiaohang_fix = 'Chành xe' 
          --                                      and trim(c.thongtinxe_sxh) in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT') -- XE 21145 backup 1 đh
          --                                      and a.ma_nvgh_tinhluong <> 'MR2953' THEN 'MR2953' --Lê Duy Tùng
          --  when a.ngaychungtu >= '2023-12-26' and a.donvigiaohang_fix = 'Chành xe' 
          --                                     and trim(c.thongtinxe_sxh) in ('HUBTONGMB-29K-085.11 (990kg) - HNM-GHTT') -- 26-12-2023
          --                                     and a.ma_nvgh_tinhluong <> 'MR2953' THEN 'MR2953' --Lê Duy Tùng                             

          --  when a.ngaychungtu >= '2023-11-01' and a.donvigiaohang_fix = 'Chành xe' 
          --                                     and trim(c.thongtinxe_sxh) in ('PNHNI-29C-80049 (1050kg)-GHTT')
          --                                     and a.ma_nvgh_tinhluong <> 'MR2000' THEN 'MR2000' --Nguyễn Văn Vinh
          --  when a.ngaychungtu >= '2023-11-01' and a.donvigiaohang_fix = 'Chành xe' 
          --                                     and trim(c.thongtinxe_sxh) in ('PNHNI-50LD-21145 (945kg)-GHTT')
          --                                     and a.ma_nvgh_tinhluong <> 'MR3039' THEN 'MR3039' --Nguyễn Văn Duy
          --  when a.ngaychungtu >= '2023-11-01' and a.donvigiaohang_fix = 'Chành xe' 
          --                                     and trim(c.thongtinxe_sxh) in ('PNHNI-50LD-21145 (945kg)-GHTT')
          --                                     and a.ma_nvgh_tinhluong <> 'MR3050' THEN 'MR3050' --Trần Tuấn Anh                                                                                     
          --  when (a.ngaychungtu >= '2023-12-01' and a.ngaychungtu <= '2023-12-25') and a.donvigiaohang_fix = 'Chành xe' 
          --                                      and trim(c.thongtinxe_sxh) in ('PNNAN-29D-55219 (600kg)-GHTT')
          --                                      and a.ma_nvgh_tinhluong <> 'MR2081' THEN 'MR2081' -- Phan Sỹ Lộc
          --  when a.ngaychungtu >= '2023-12-26' and a.donvigiaohang_fix = 'Chành xe' 
          --                                      and trim(c.thongtinxe_sxh) in ('HUBTONGMB-29K-084.38 (990Kg) - NAN-GHTT')
          --                                      and a.ma_nvgh_tinhluong <> 'MR2081' THEN 'MR2081' -- Phan Sỹ Lộc
          --  when a.ngaychungtu >= '2023-12-26' and a.donvigiaohang_fix = 'Chành xe' 
          --                                      and trim(c.thongtinxe_sxh) in ('PNNAN-29D-55219 (600kg)-GHTT')
          --                                      and a.ma_nvgh_tinhluong <> 'MR3055' THEN 'MR3055' -- Lâm Quyết Thắng
          --  when a.ngaychungtu >= '2023-12-15' and a.donvigiaohang_fix = 'Chành xe' 
          --                                     and trim(c.thongtinxe_sxh) in ('HUBTONGMB-29K-084.18 (990kg) - TONGKHO-GHTT')
          --                                     and a.ma_nvgh_tinhluong <> 'MR3030' THEN 'MR3030' -- Đào Ngọc Thành
          --  when a.ngaychungtu >= '2023-12-15' and a.donvigiaohang_fix = 'Chành xe' 
          --                                     and trim(c.thongtinxe_sxh) in ('HUBTONGMB-29K-084.18 (990kg) - TONGKHO-GHTT')
          --                                     and a.ma_nvgh_tinhluong <> 'MR3049' THEN 'MR3049' -- Tạ Văn Cường

          --  when a.ngaychungtu >= '2023-12-26' and a.donvigiaohang_fix = 'Chành xe' 
          --                                     and trim(c.thongtinxe_sxh) in ('HUBTONGMB-29K-061.85 (990kg) - BGI-GHTT')
          --                                     and a.ma_nvgh_tinhluong <> 'MR3042' THEN 'MR3042' -- Nguyễn Văn Hạnh                                 
          --  when a.ngaychungtu >= '2023-12-26' and a.donvigiaohang_fix = 'Chành xe' 
          --                                     and trim(c.thongtinxe_sxh) in ('HUBTONGMB-29K-085.44 (990kg) - HPG-GHTT')
          --                                     and a.ma_nvgh_tinhluong <> 'MR3021' THEN 'MR3021' -- Tô Văn Sức
           
           else null end as manv_thahang_tinhluong,

      l.role_luong_mds as role_thahang,
      l.role_luong_mds_phanloai as role_thahang_pl,

      case when e.role_luong_mds_phanloai = 'MDS' and makenhkh in ('TP','PCL') then 'MDS-T (TP-PCL)' 
           when e.role_luong_mds_phanloai = 'MDS' and makenhkh in ('INS','MT','CLC') THEN 'MDS-T2 (INS-CLC-MT)' 

           when e.role_luong_mds_phanloai = 'MDS2' then 'MDS2-T'
           when e.role_luong_mds_phanloai = 'LOG' and makenhkh IN ('INS','CLC','MT') THEN 'LOG-T (INS-CLC-MT)'
           when e.role_luong_mds_phanloai = 'LOG' and makenhkh IN ('TP','PCL') THEN 'LOG-T2 (TP-PCL)'

           when e.role_luong_mds_phanloai like 'LOGHUB%' then 'LOGHUB-T'

           ELSE 'KHÁC' end as phanloai_doanhso_gh

    from DATA_F_SALES_FIXED a
    left join NGAYGIAOHANG b on a.ma_dh = b.ordernbr
    left join SOXUATHANG c on a.ma_dh = c.ordernbr
    left join TUYENBAN_MDS g on a.makhdms = g.custid 
    left join kpi_leadtime d on concat(a.tentinhkh,
                                       case when a.tenquanhuyen in ('Quận 9','Quận 2') then 'Thành phố Thủ Đức' else a.tenquanhuyen end
                                      ) = d.noi
    left join `spatial-vision-343005.staging.sync_dms_pda_so` h on a.ma_dh = h.ordernbr
    left join `spatial-vision-343005.staging.d_master_khachhang` i on a.makhdms = i.custid
    left join `spatial-vision-343005.staging.d_users` e on a.ma_nvgh_tinhluong = e.manv 
    left join `spatial-vision-343005.staging.d_users` f on a.ma_donghang_tinhluong = f.manv 
    left join DONCO m on concat (a.macongtycn,a.ma_dh,a.hoadon) = m.noi and a.thang = m.thang
    left join DONIR  m1 on a.ma_dh = m1.don_dh 
                       and a.macongtycn = m1.macongtycn 
                       and a.masanpham = m1.masanpham 
                       and a.mahd = m1.mahd_goc
    left join `spatial-vision-343005.staging.d_dieuphoinguyen` n on c.batnbr = n.sosxh 
                                                                and a.macongtycn = n.chinhanh
    left join `spatial-vision-343005.staging.d_users` l on (case when n.tennguoinhan = 'Lê Duy Tùng' 
                                                                 and n.nguoigiaohang <> 'Lê Duy Tùng' 
                                                                 then n.tennguoinhan else null end
                                                           ) = l.tencvbh
    left join `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` o on o.phuongxa is not null 
                                                                          and a.tentinhkh = o.tinhtp 
                                                                          and a.tenquanhuyen = o.quanhuyen 
                                                                          and a.phuongxa = o.phuongxa
    left join `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` o1 on o1.phuongxa is null 
                                                                          and a.tentinhkh = o1.tinhtp 
                                                                          and a.tenquanhuyen = o1.quanhuyen
    left join `spatial-vision-343005.staging.d_users` k on g.slsperid = k.manv
    left join `spatial-vision-343005.staging.d_users` k1 on a.manv = k1.manv
    left join suco u on a.ma_dh = u.ordernbr
    left join `staging.d_manual_danhsach_so_xe_loghub` p on c.thongtinxe_sxh = p.soxetrendms and a.ngaychungtu between p.tungay and p.denngay
    and a.donvigiaohang_fix = 'Chành xe'
  )
  
  select
    a.*except(ma_nvbh,manv_thahang_tinhluong,role_thahang,role_thahang_pl),
    a.ma_nvbh,
    c.tencvbh as ten_nvbh,
    c.supid_bh as masup_bh,
    c.tenquanlytt_bh as tensup_bh,
    c.asm_bh as mamgr_bh,
    c.tenquanlykhuvuc_bh as tenmgr_bh,
    c.rsmid as madir_bh,
    c.tenquanlyvung as tendir_bh,
    c.role_luong_mds as role_banhang,
    c.role_luong_mds_phanloai as role_banhang_pl,
    ifnull(b.manvth,a.manv_thahang_tinhluong) as manv_thahang_tinhluong,
    d.tencvbh as ten_thahang_tinhluong,
    ifnull(a.role_thahang,d.role_luong_mds) as role_thahang,
    ifnull(a.role_thahang_pl,d.role_luong_mds_phanloai) as role_thahang_pl,
    sum(dschuvat_giaohang) over(partition by ma_dh_1,a.macongtycn) as loc_don_ir

  from thongtingiaohang a
  left join `spatial-vision-343005.staging.d_dieuchinhmds` b on a.ma_dh_1 = b.sodondathang --- điều chỉnh nv thả hàng
  left join `spatial-vision-343005.staging.d_users` c on a.ma_nvbh = c.manv
  left join `spatial-vision-343005.staging.d_users` d on ifnull(b.manvth,a.manv_thahang_tinhluong) = d.manv
)
,

doanhso_kehoach as
(
  select *,
    null as kh_total
    from data_giaohang 

UNION ALL

  select
    null as sodondathang,
    a.thang as ngaychungtu,
    null as ma_dh,
    null as ma_dh_1,
    null as sodontrahang,
    null as ngaytrahang,
    null macongtycn,
    null as congtycn,
    null as mahd,
    null as hoadon,
    null as makhdms,
    null as makhcu,
    null as tenkhachhang,
    null as tenvungbh,
    null as tenkhuvuc,
    null as tentinhkh,
    null as tenquanhuyen,
    null as phuongxa,
    null as makenhkh,
    null as makenhphu,
    null as mahco,
    null as maphanloaihco,
    null as maphanhanghco,
    null as thtt,
    null as pmt,
    null as masanpham,
    null as tensanphamnb,
    null as tensanphamviettat,
    null as solo,
    
    null as ngaydatdon,
    null as ngaygiaohang,
    null as manv,
    null as tencvbh,
    null as tenquanlytt,
    null as tenquanlykhuvuc,
    null as tenquanlyvung,
    null as manvgh,
    null as nguoigiaohang,
    null as trangthaigiaohang,
    null as donvigiaohang,
    null as tennhavanchuyen,
    null as kieudonhang,
    a.thang as thang,
    null as manvghreal,
    null as tennvghreal,
    null as manv_dh_chanh,
    null as mamds,
    null as soluong,
    null as dongiacovat,
    null as doanhsocovat,
    null as dongiachuavat,
    null as dschuvat_banhang,
    null as dschuvat_giaohang,
    null as donvigiaohang_fix,
    null as ma_mds_fix,
    null as ma_donghang_fix,
    null as ma_nvgh_tinhluong,
    null as ma_donghang_tinhluong,
    null as ngaychotso,
    null as ngaygiaohang_fix,
    null as status_dv,
    null as soxuathang,
    null as thongtinxe_sxh,
    null as full_leadtime,
    null as full_leadtime_duyet,
    null as kpi_leadtime,
    null as danhgia_leadtime,
    null as ngaytaodon,
    null as ngayduyetdon,
    null as crs_mds_note, 
    null as cx_note,
    null as diachikhachhang,
    null as ten_nvgh_tinhluong,
    null as role_giaohang_tinhluong,
    null as role_giaohang_tinhluong_pl,
    null as masup_gh,
    null as tensup_gh,
    null as mamgr_gh,
    null as tenmgr_gh,
    null as madir_gh,
    null as tendir_gh,
    null as ten_donghang_tinhluong,
    null as role_donghang_tinhluong,
    null as role_donghang_tinhluong_pl,
    null as asup_donghang,
    null as tensup_donghang,
    null as mamgr_donghang,
    null as tenmgr_donghang,

    null as don_co,
    null as don_ir,
    null as suco, 
    null as phanloai_doanhso_gh,

    a.manv as ma_nvbh,
    b.tencvbh as ten_nvbh,
    b.supid_bh as masup_bh,
    b.tenquanlytt_bh as tensup_bh,
    b.asm_bh as mamgr_bh,
    b.tenquanlykhuvuc_bh as tenmgr_bh,
    b.rsmid as madir_bh_tinhluong,
    b.tenquanlyvung as tendir_bh,
    b.role_luong_mds as role_banhang,
    b.role_luong_mds_phanloai as role_banhang_pl,
    null as manv_thahang_tinhluong,
    null as ten_thahang_tinhluong,
    null as role_thahang,
    null as role_thahang_pl,
    null as loc_don_ir,

    kh_total
  from  `spatial-vision-343005.staging.d_calendar` a
  left join `spatial-vision-343005.staging.d_users` b on a.manv = b.manv
  where date(a.thang) >= '2023-01-01' and (role_luong_mds = 'MDS' or role_luong_mds = 'P.BH' 
                                                                  and role_luong_mds_phanloai = 'P.BH' 
                                                                  and a.tenquanlytt = 'Nguyễn Văn Tiến'
                                          )
)
,

cum1 as 
(
  select 
    distinct
    statedescr,
    districtdescr,
    wardname, 
    cluster,
    cluster_state,
  from `spatial-vision-343005.staging.d_leadtimekpi`
  group by 1,2,3,4,5
)
,

cum2 as 
(
  select 
    distinct
    statedescr,
    districtdescr,
    cluster,
    cluster_state,
  from `spatial-vision-343005.staging.d_leadtimekpi`
  where districtdescr != 'Huyện Bình Chánh'
  group by 1,2,3,4
)
,

result as
(
  select 
    current_datetime ("+7") as thoigian , 
    a.* ,

    case when a.kieudonhang in ('DP','UP') then 0
         when a.kieudonhang in ('IR') and loc_don_ir = 0 then 0 
         when a.kieudonhang in ('IN') and loc_don_ir = 0 then 0 
         when a.kieudonhang in ('IR') and don_ir is null then 0
         when (a.donvigiaohang_fix in ('NVC','Nhà vận chuyển') or a.ma_nvgh_tinhluong like 'GH%') 
                                                               and a.kieudonhang in ('IR') 
                                                               and loc_don_ir <> 0 then 0 
         when (a.donvigiaohang_fix in ('NVC','Nhà vận chuyển') or a.ma_nvgh_tinhluong like 'GH%') 
                                                               and a.kieudonhang in ('IN') 
                                                               and loc_don_ir <> 0 then 0 
         when a.donvigiaohang_fix in ('NVC','Nhà vận chuyển') then 0
         when a.ma_nvgh_tinhluong like 'GH%' then 0
         when a.don_co is not null then 0
         else 1 end as don_tinh_gh,   -- 1 là tinh tiền, 0 là ko tính
  
    case when a.kieudonhang in ('DP','UP','LO','OO') then null
         when a.kieudonhang in ('IR') and loc_don_ir = 0 then null
         when a.kieudonhang in ('IN') and loc_don_ir = 0 then null
         when a.kieudonhang in ('IR') and don_ir is null then null
         when (a.donvigiaohang_fix in ('NVC','Nhà vận chuyển') or a.ma_nvgh_tinhluong like 'GH%') 
                                                               and a.kieudonhang in ('IR') 
                                                               and loc_don_ir <> 0 then null 
         when (a.donvigiaohang_fix in ('NVC','Nhà vận chuyển') or a.ma_nvgh_tinhluong like 'GH%') 
                                                               and a.kieudonhang in ('IN') 
                                                               and loc_don_ir <> 0 then null
         when a.donvigiaohang_fix in ('NVC','Nhà vận chuyển') then null
         when a.ma_nvgh_tinhluong like 'GH%' then null
         when a.don_co is not null then null
         else a.ma_dh end as madon_tinh_gh,  

    case when a.kieudonhang in ('DP','UP') then 0
         when a.kieudonhang in ('IR') and loc_don_ir = 0 then 0 
         when a.kieudonhang in ('IN') and loc_don_ir = 0 then 0 
         when a.kieudonhang in ('IR') and don_ir is null then 0
         when (a.donvigiaohang_fix in ('NVC','Nhà vận chuyển') or a.ma_nvgh_tinhluong like 'GH%') 
                                                               and a.kieudonhang in ('IR') 
                                                               and loc_don_ir <> 0 then 0 
         when (a.donvigiaohang_fix in ('NVC','Nhà vận chuyển') or a.ma_nvgh_tinhluong like 'GH%') 
                                                               and a.kieudonhang in ('IN') 
                                                               and loc_don_ir <> 0 then 0 
         when a.donvigiaohang_fix not in ('NVC','Nhà vận chuyển','Chành xe') then 0
         when a.don_co is not null then 0
         else 1 end as don_tinh_dh,         

    b.note as noidung_giaitrinh,
    b.ketqualeadtime_giaitrinh,

    -- ifnull(c.cluster,d.cluster) as cluster,      
    -- ifnull(c.cluster_state,d.cluster_state) as cluster_state, 
    c.cluster_state,
    ifnull(b.ketqualeadtime_giaitrinh,(case when a.danhgia_leadtime = 'Dat' then 1 else 0 end)) as ketqua_leadtime_tinhluong  , 

    case when (case when a.donvigiaohang_fix not in ('NVC','Nhà vận chuyển') 
                    and a.ma_nvgh_tinhluong not like 'GH%' 
                    and a.don_co is null then 1 else 0 end
              ) is not null 

              and ifnull(b.ketqualeadtime_giaitrinh,(case when a.danhgia_leadtime = 'Dat' then 1 else 0 end)
                        ) = 1 

              and (case when a.donvigiaohang_fix not in ('NVC','Nhà vận chuyển') 
                          and a.ma_nvgh_tinhluong not like 'GH%' 
                          and a.don_co is null then 1 else 0 end
                          ) = 1 
          then a.ma_dh 
          else null end as madon_leadtimedat_tinhluong,

    -- case when a.kieudonhang in ('DP','UP','LO','OO') then null
    --      when a.kieudonhang in ('IR') and loc_don_ir = 0 then null
    --      when a.kieudonhang in ('IN') and loc_don_ir = 0 then null
    --      when a.kieudonhang in ('IR') and don_ir is null then null
    --      when (a.donvigiaohang_fix in ('NVC','Nhà vận chuyển') or a.ma_nvgh_tinhluong like 'GH%') and a.kieudonhang in ('IR') and loc_don_ir <> 0 then null 
    --      when (a.donvigiaohang_fix in ('NVC','Nhà vận chuyển') or a.ma_nvgh_tinhluong like 'GH%') and a.kieudonhang in ('IN') and loc_don_ir <> 0 then null
    --      when a.donvigiaohang_fix in ('NVC','Nhà vận chuyển') then null
    --      when a.ma_nvgh_tinhluong like 'GH%' then null
    --      when a.don_co is not null then null
    --      else a.ma_dh end as madon_tinh_gh,        

  from doanhso_kehoach a
  left join `spatial-vision-343005.staging.d_giaitrinhlt_mds` b on a.ma_dh = b.ordernbr 
  -- left join cum1 c on concat (a.tentinhkh,
  --                             case when a.tenquanhuyen in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' 
  --                                  else a.tenquanhuyen end,
  --                             a.phuongxa
  --                             )
  --                   = concat (c.statedescr,c.districtdescr,c.wardname)
  -- left join cum2 d on concat (a.tentinhkh,case when a.tenquanhuyen in ('Quận 2','Quận 9') then 'Thành phố Thủ Đức' 
  --                                              else a.tenquanhuyen end
  --                            )
  --                   = concat (d.statedescr,d.districtdescr)
  left join `staging.d_master_khachhang` c on c.custid =a.makhdms
  where ngaychungtu >= '2023-01-01' 
)

  select 
  *,
    (select max(inserted_at) from `spatial-vision-343005.staging.f_sales` ) as inserted_at,
    row_number()over(partition by ma_dh,macongtycn order by masanpham) as loc, 
    case when don_tinh_gh = 1 and (row_number()over(partition by ma_dh,macongtycn order by masanpham)) = 1 then full_leadtime 
         else null end as full_leadtime_1
  from result 
-- where  ma_dh_1 in ('DL1-1223-04154')--,'DL6-1123-00158')--,'DL1-1023-05212')

);

Create or replace table `warehouse.f_baocao_daily_performance_mds_new_v2`

copy `staging_temp.f_baocao_daily_performance_mds_new_temp`;

END;