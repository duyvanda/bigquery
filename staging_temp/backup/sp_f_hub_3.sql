CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_hub_3()
BEGIN 
TRUNCATE TABLE staging_temp.f_hub_3_temp;

INSERT INTO staging_temp.f_hub_3_temp
(

-- CREATE OR REPLACE table staging_temp.f_hub_3_temp
-- as

with DATA_F_SALES_FIXED as
( 
  WITH capnhat_chinhsua as
  (
    SELECT 
    a.sodondathang,
    a.ngaychungtu,
    case when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) <> EXTRACT (month from a.ngaychungtu))) then null
         when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) = EXTRACT (month from a.ngaychungtu))) then a.sodontrahang 
         else a.sodondathang end as ma_dh,

    case when a.kieudonhang = 'CO'then a.sodontrahang else a.sodondathang end as ma_dh_1,

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
    a.makenhkh,
    a.makenhphu,
    a.mahco,
    a.maphanloaihco,
    a.maphanhanghco,
    a.masanpham,
    a.tensanphamnb,
    a.tensanphamviettat,
    a.solo,
    a.soluong,
    a.ngaydatdon,
    a.ngaygiaohang,
    a.manv,
    a.tencvbh,
    a.tenquanlytt,
    a.tenquanlykhuvuc,
    a.tenquanlyvung,
    a.manvgh,
    a.nguoigiaohang,
    a.trangthaigiaohang,
    a.donvigiaohang,
    a.tennhavanchuyen,
    a.kieudonhang,
    a.thang,
    a.manvghreal,
    a.tennvghreal,
    
    case when EXTRACT (month from a.ngaychungtu) = EXTRACT (month from b.crtd_datetime) then b.crtd_user else null end as manv_dh_chanh,

    max (a.inserted_at) as inserted_at,
    
    case when a.manvghreal is null then a.manvgh else a.manvghreal end as mamds,

    sum (a.dongiacovat) as dongiacovat,
    sum (a.doanhsocovat) as doanhsocovat,
    sum (a.dongiachuavat) as dongiachuavat,
    sum (a.doanhsochuavat) as dschuvat_banhang,

    case when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) <> EXTRACT (month from a.ngaychungtu))) then 0
         when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) = EXTRACT (month from a.ngaychungtu))) then sum (a.doanhsochuavat)
         else sum (a.doanhsochuavat) end as dschuvat_giaohang,

    FROM `spatial-vision-343005.staging.f_sales` a
    LEFT JOIN `spatial-vision-343005.staging.sync_dms_dr` b  --- BIÊN BẢN GỬI HÀNG TỈNH
          on (case when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) <> EXTRACT (month from a.ngaychungtu))) then null
                   when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) = EXTRACT (month from a.ngaychungtu))) then a.sodontrahang 
                   else a.sodondathang end)
          = b.ordernbr 

    WHERE date (a.ngaychungtu) >= '2023-06-01' --and date (a.ngaychungtu) <= '2023-04-28'
          -- and (case when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) <> EXTRACT (month from a.ngaychungtu))) then null
          --           when (a.kieudonhang = 'CO' and (EXTRACT (month from a.ngaytrahang) = EXTRACT (month from a.ngaychungtu))) then a.sodontrahang 
          --           else a.sodondathang end) is not null
          and a.makenhkh not in ('NB','OTH_LAB')
          and masanpham not like 'V%'
          and a.tentinhkh in ('Hà Nam','Ninh Bình','Nam Định','Thái Bình')
      
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44
  )

  select
    a.* ,
    case when b.donvigiaohang is null then a.donvigiaohang else b.donvigiaohang end as donvigiaohang_fix,
    case when b.manvghreal is null then a.mamds else b.manvghreal end as ma_mds_fix,
    case when b.manvdh is null then a.manv_dh_chanh else b.manvdh end as ma_donghang_fix,

    case when (case when b.donvigiaohang is null then a.donvigiaohang else b.donvigiaohang end) not in ('Nhà vận chuyển','NVC' ) 
         then (case when b.manvghreal is null then a.mamds else b. manvghreal end ) 
         else null end as ma_nvgh_tinhluong,

    case when (case when b.donvigiaohang is null then a.donvigiaohang else b.donvigiaohang end) IN ('Nhà vận chuyển','NVC') 
         then (case when b.manvdh is null then a.mamds else b.manvdh end)

         when (case when b.donvigiaohang is null then a.donvigiaohang else b.donvigiaohang end) = 'Chành xe' 
         then (case when b.manvdh is null then a.manv_dh_chanh else b.manvdh end) 
         
         else null end as ma_donghang_tinhluong

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
    where DATE(crtd_datetime) >= "2023-06-01"
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

NGAYNHANHANG as
(
  with b1 as
  (
    select *,
    row_number() over (partition by ordernbr order by lupd_datetime desc) as loc
    from `spatial-vision-343005.staging.sync_dms_delihistory`
    where status = 'A'
  )
  select * from b1 where loc = 1
)

,
-- SO XUAT HANG
SOXUATHANG as 
(
  -- Tạo sổ
  with dms_ib AS 
  (
    SELECT
      distinct
      branchid,
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
    WHERE DATE(crtd_datetime) >= "2023-06-01"
  )
  ,

  -- Chốt sổ
  dms_ibd AS 
  (
    SELECT
      distinct
      branchid,
      batnbr,
      ordernbr,
      status as status_ibd,
      deliverytime as deliverytime_ibd,
      crtd_datetime crtd_datetime_ibd,
      crtd_user as crtd_user_ibd,
      lupd_datetime as lupd_datetime_ibd,
      transporters 
    FROM`spatial-vision-343005.staging.sync_dms_ibd`
    WHERE DATE(crtd_datetime) >= "2023-06-01" 
  )

  select a.*,
    b.ordernbr,
    b.status_ibd,
    b.deliverytime_ibd,
    b.crtd_user_ibd,
    b.crtd_datetime_ibd,
    b.lupd_datetime_ibd,
    b.transporters,
    c.descr as thongtinxe_sxh
  from dms_ib a 
  LEFT JOIN dms_ibd b on a.branchid =b.branchid and a.batnbr = b.batnbr
  left join `spatial-vision-343005.staging.sync_dms_ot` c on a.branchid = c.branchid and a.truckid = c.code
  where status_ib = 'C'
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
      custid,
      slsperid,
      crtd_datetime,
      Case when routetype in ('B','D') then 1 else 2 end as routetype,
    FROM `spatial-vision-343005.staging.sync_dms_srm`
    where delroutedet is false --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
  )
  select * 
  from (
          select *,
            row_number() over (partition by custid order by routetype asc,crtd_datetime desc) as loc  
          from data_tuyen
       )
  where loc =1
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
    WHERE date (a.ngaychungtu) >= '2023-06-01' --and date (a.ngaychungtu) <= '2023-04-28'
          and sodontrahang is not null
)
,

data_giaohang as
(
  select a.* ,
    b.crtd_datetime_dv as ngaychotso,
    b.lupd_datetime_dv as ngaygiaohang_fix,
    j.lupd_datetime as ngaynhanhang,
    b.status_dv,
    c.batnbr as soxuathang,
    c.thongtinxe_sxh,

    -- case when b.lupd_datetime_dv is null 
    --      then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.crtd_datetime,minute)/60,2)
    --      else round (datetime_diff (b.lupd_datetime_dv,h.crtd_datetime,minute)/60,2) end as full_leadtime,

    case when b.lupd_datetime_dv is null and h.lupd_user ='admin' 
              then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.crtd_datetime,minute)/60,2)
         when b.lupd_datetime_dv is null and h.lupd_user !='admin' 
              then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.ApprovalDate,minute)/60,2)
         when b.lupd_datetime_dv is not null and h.lupd_user ='admin' 
              then round (datetime_diff (b.lupd_datetime_dv,h.crtd_datetime,minute)/60,2)
         when b.lupd_datetime_dv is not null and h.lupd_user != 'admin' 
              then round (datetime_diff (b.lupd_datetime_dv,h.ApprovalDate,minute)/60,2)
         else null end as full_leadtime,

    case when (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-08-31') 
              and j.lupd_datetime is null and h.lupd_user ='admin' and n.tennguoinhan <> n.nguoigiaohang 
              then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.crtd_datetime,minute)/60,2)
         when (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-08-31') 
              and j.lupd_datetime is null and h.lupd_user !='admin' and n.tennguoinhan <> n.nguoigiaohang 
              then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.ApprovalDate,minute)/60,2)
         when (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-08-31') 
              and j.lupd_datetime is not null and h.lupd_user ='admin' and n.tennguoinhan <> n.nguoigiaohang 
              then round (datetime_diff (j.lupd_datetime,h.crtd_datetime,minute)/60,2)
         when (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-08-31') 
              and j.lupd_datetime is not null and h.lupd_user != 'admin' and n.tennguoinhan <> n.nguoigiaohang 
              then round (datetime_diff (j.lupd_datetime,h.ApprovalDate,minute)/60,2)

         when (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
              and j.lupd_datetime is null and h.lupd_user ='admin' 
              and a.donvigiaohang_fix = 'Chành xe' 
              and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
              and a.ma_nvgh_tinhluong <> 'MR2953'
              then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.crtd_datetime,minute)/60,2)
         when (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
              and j.lupd_datetime is null and h.lupd_user !='admin' 
              and a.donvigiaohang_fix = 'Chành xe' 
              and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
              and a.ma_nvgh_tinhluong <> 'MR2953'
              then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.ApprovalDate,minute)/60,2)
         when (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
              and j.lupd_datetime is not null and h.lupd_user ='admin' 
              and a.donvigiaohang_fix = 'Chành xe' 
              and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
              and a.ma_nvgh_tinhluong <> 'MR2953'  
              then round (datetime_diff (j.lupd_datetime,h.crtd_datetime,minute)/60,2)
         when (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
              and j.lupd_datetime is not null and h.lupd_user != 'admin' 
              and a.donvigiaohang_fix = 'Chành xe' 
              and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
              and a.ma_nvgh_tinhluong <> 'MR2953' 
              then round (datetime_diff (j.lupd_datetime,h.ApprovalDate,minute)/60,2)
         else null end as chuyenhang_leadtime,

    -- d.kpi_leadtime,
    case when EXTRACT(DAYOFWEEK FROM h.crtd_datetime) in (1,2,3,4,5) then 54.5
         when EXTRACT(DAYOFWEEK FROM h.crtd_datetime) in (6) then 90.5
         when EXTRACT(DAYOFWEEK FROM h.crtd_datetime) in (7) then 66.5
         else 0 end as kpi_max_leadtime,

    case when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-07-31') 
                                       and tentinhkh = 'Hà Nam' then 48
         when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-08-01' AND date(ngaychungtu) <= '2023-08-31') 
                                       and tentinhkh = 'Hà Nam' then 48
         when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                                       and tentinhkh = 'Hà Nam' then 48                          

         when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-07-31') 
                                       and tentinhkh = 'Ninh Bình' then 48
         when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-08-01' AND date(ngaychungtu) <= '2023-08-31') 
                                       and tentinhkh = 'Ninh Bình' then 48
         when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                                       and tentinhkh = 'Ninh Bình' then 48                                                           

         when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-07-31') 
                                       and tentinhkh = 'Nam Định' then 48
         when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-08-01' AND date(ngaychungtu) <= '2023-08-31') 
                                       and tentinhkh = 'Nam Định' then 48
         when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                                       and tentinhkh = 'Nam Định' then 48

         when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-07-31') 
                                       and tentinhkh = 'Thái Bình' then 50
         when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-08-01' AND date(ngaychungtu) <= '2023-08-31') 
                                       and tentinhkh = 'Thái Bình' then 48
         when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                                       and tentinhkh = 'Thái Bình' then 48   
                                                                                                                                 
         when e.role_luong_mds = 'LOG' and (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-09-30') 
                                       then 48 else 0 end as kpi_leadtime, 

    case when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-08-31') 
                                       and n.tennguoinhan <> n.nguoigiaohang then 48
         when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                                       and a.donvigiaohang_fix = 'Chành xe' 
                                       and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
                                       and a.ma_nvgh_tinhluong <> 'MR2953' then 48
                                       else 0 end as kpi_chuyenhang,

    case when a.donvigiaohang_fix in ('Nhà vận chuyển','NVC') then null
         when a.donvigiaohang_fix not in ('Nhà vận chuyển','NVC') and
              (case when b.lupd_datetime_dv is null and h.lupd_user ='admin' 
                         then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.crtd_datetime,minute)/60,2)
                    when b.lupd_datetime_dv is null and h.lupd_user !='admin' 
                         then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.ApprovalDate,minute)/60,2)
                    when b.lupd_datetime_dv is not null and h.lupd_user ='admin' 
                         then round (datetime_diff (b.lupd_datetime_dv,h.crtd_datetime,minute)/60,2)
                    when b.lupd_datetime_dv is not null and h.lupd_user != 'admin' 
                         then round (datetime_diff (b.lupd_datetime_dv,h.ApprovalDate,minute)/60,2)
                    else null end) 
            > (case when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-07-31') 
                                                  and tentinhkh = 'Hà Nam' then 48
                    when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-08-01' AND date(ngaychungtu) <= '2023-08-31') 
                                                  and tentinhkh = 'Hà Nam' then 48
                    when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                                                  and tentinhkh = 'Hà Nam' then 48                          

                    when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-07-31') 
                                                  and tentinhkh = 'Ninh Bình' then 48
                    when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-08-01' AND date(ngaychungtu) <= '2023-08-31') 
                                                  and tentinhkh = 'Ninh Bình' then 48
                    when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                                                  and tentinhkh = 'Ninh Bình' then 48                                                           

                    when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-07-31') 
                                                  and tentinhkh = 'Nam Định' then 48
                    when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-08-01' AND date(ngaychungtu) <= '2023-08-31') 
                                                  and tentinhkh = 'Nam Định' then 48
                    when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                                                  and tentinhkh = 'Nam Định' then 48

                    when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-07-31') 
                                                  and tentinhkh = 'Thái Bình' then 50
                    when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-08-01' AND date(ngaychungtu) <= '2023-08-31') 
                                                  and tentinhkh = 'Thái Bình' then 48
                    when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                                                  and tentinhkh = 'Thái Bình' then 48        

                    when e.role_luong_mds = 'LOG' and (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-09-30') 
                                                  then 48 else 0 end) 
         then 'Ko dat' 
         else 'Dat' end as danhgia_leadtime,

    case when a.donvigiaohang_fix in ('Nhà vận chuyển','NVC') then null 
         when a.donvigiaohang_fix not in ('Nhà vận chuyển','NVC') 
              and (case when (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-08-31') 
                              and j.lupd_datetime is null and h.lupd_user ='admin' and n.tennguoinhan <> n.nguoigiaohang 
                              then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.crtd_datetime,minute)/60,2)
                        when (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-08-31') 
                              and j.lupd_datetime is null and h.lupd_user !='admin' and n.tennguoinhan <> n.nguoigiaohang 
                              then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.ApprovalDate,minute)/60,2)
                        when (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-08-31') 
                              and j.lupd_datetime is not null and h.lupd_user ='admin' and n.tennguoinhan <> n.nguoigiaohang 
                              then round (datetime_diff (j.lupd_datetime,h.crtd_datetime,minute)/60,2)
                        when (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-08-31') 
                              and j.lupd_datetime is not null and h.lupd_user != 'admin' and n.tennguoinhan <> n.nguoigiaohang 
                              then round (datetime_diff (j.lupd_datetime,h.ApprovalDate,minute)/60,2)

                        when (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                              and j.lupd_datetime is null and h.lupd_user ='admin' 
                              and a.donvigiaohang_fix = 'Chành xe' 
                              and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
                              and a.ma_nvgh_tinhluong <> 'MR2953'
                              then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.crtd_datetime,minute)/60,2)
                        when (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                              and j.lupd_datetime is null and h.lupd_user !='admin' 
                              and a.donvigiaohang_fix = 'Chành xe' 
                              and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
                              and a.ma_nvgh_tinhluong <> 'MR2953'
                              then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.ApprovalDate,minute)/60,2)
                        when (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                              and j.lupd_datetime is not null and h.lupd_user ='admin' 
                              and a.donvigiaohang_fix = 'Chành xe' 
                              and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
                              and a.ma_nvgh_tinhluong <> 'MR2953'  
                              then round (datetime_diff (j.lupd_datetime,h.crtd_datetime,minute)/60,2)
                        when (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                              and j.lupd_datetime is not null and h.lupd_user != 'admin' 
                              and a.donvigiaohang_fix = 'Chành xe' 
                              and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
                              and a.ma_nvgh_tinhluong <> 'MR2953' 
                              then round (datetime_diff (j.lupd_datetime,h.ApprovalDate,minute)/60,2)
                        else null end) 
                > (case when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-07-01' AND date(ngaychungtu) <= '2023-08-31') 
                                                      and n.tennguoinhan <> n.nguoigiaohang then 48
                        when e.role_luong_mds = 'MDS' and (date(ngaychungtu) >= '2023-09-01' AND date(ngaychungtu) <= '2023-09-30') 
                                                      and a.donvigiaohang_fix = 'Chành xe' 
                                                      and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
                                                      and a.ma_nvgh_tinhluong <> 'MR2953' then 48
                                                      else 0 end)
         then 'Ko dat' 
         else 'Dat' end as danhgia_chuyenhang,
    
    h.crtd_datetime as ngaytaodon,
    h.ApprovalDate as ngayduyetdon,
    case when h.lupd_user = 'admin' then 'duyettudong' else 'kotudong' end as nguoi_duyetdon,
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
    case when a.manv = 'TMDT_001' then g.slsperid else a.manv end as ma_nvbh,
    k.tencvbh as ten_nvbh,
    k.supid_bh as masup_bh,
    k.tenquanlytt_bh as tensup_bh,
    k.asm_bh as mamgr_bh,
    k.tenquanlykhuvuc_bh as tenmgr_bh,
    k.rsmid as madir_bh,
    k.tenquanlyvung as tendir_bh,
    k.role_luong_mds as role_banhang,
    k.role_luong_mds_phanloai as role_banhang_pl,

    m.don_co,

    case when (a.thang >= '2023-07-01' and a.thang <= '2023-08-31') and n.tennguoinhan = 'Lê Duy Tùng' and n.nguoigiaohang <> 'Lê Duy Tùng' then n.tennguoinhan 
         when a.thang >= '2023-08-01' and a.donvigiaohang_fix = 'Chành xe' 
                                      and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
                                      and a.ma_nvgh_tinhluong <> 'MR2953' then 'Lê Duy Tùng'
         else null end as ten_thahang_tinhluong,
         
    case when (a.thang >= '2023-07-01' and a.thang <= '2023-08-31') then l.manv
         when a.thang >= '2023-08-01' and a.donvigiaohang_fix = 'Chành xe' 
                                      and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
                                      and a.ma_nvgh_tinhluong <> 'MR2953' THEN 'MR2953' 
         else null end as manv_thahang_tinhluong,

    p.role_luong_mds as role_thahang,
    p.role_luong_mds_phanloai as role_thahang_pl,

  from DATA_F_SALES_FIXED a
  left join NGAYGIAOHANG b on a.ma_dh = b.ordernbr
  left join SOXUATHANG c on a.ma_dh = c.ordernbr
  left join TUYENBAN_MDS g on a.makhdms = g.custid --and a.thang = g.thang
  -- left join kpi_leadtime d on concat(a.tentinhkh,a.tenquanhuyen) = d.noi
  left join `spatial-vision-343005.staging.sync_dms_pda_so` h on a.ma_dh = h.ordernbr
  left join `spatial-vision-343005.staging.d_master_khachhang` i on a.makhdms = i.custid
  left join `spatial-vision-343005.staging.d_users` e on a.ma_nvgh_tinhluong = e.manv --and a.thang = e.thang
  left join `spatial-vision-343005.staging.d_users` f on a.ma_donghang_tinhluong = f.manv --and a.thang = f.thang
  left join `spatial-vision-343005.staging.d_users` k on (case when a.manv = 'TMDT_001' then g.slsperid else a.manv end) = k.manv --and a.thang = k.thang
  left join DONCO m on concat (a.macongtycn,a.ma_dh,a.hoadon) = m.noi and a.thang = m.thang
  left join `spatial-vision-343005.staging.d_dieuphoinguyen` n on c.batnbr = n.sosxh and a.macongtycn = n.chinhanh
  left join `spatial-vision-343005.staging.d_users` l on ( case when n.tennguoinhan = 'Lê Duy Tùng' and n.nguoigiaohang <> 'Lê Duy Tùng' 
                                                                then n.tennguoinhan else null end) = l.tencvbh
  left join NGAYNHANHANG j on a.ma_dh_1 = j.ordernbr and a.macongtycn = j.branchid and c.batnbr = j.batnbr
  left join `spatial-vision-343005.staging.sync_dms_dr` o on a.ma_dh = o.ordernbr
  left join `spatial-vision-343005.staging.d_users` p on ( case when (a.thang >= '2023-07-01' and a.thang <= '2023-08-31') then l.manv
                                                                when a.thang >= '2023-08-01' and a.donvigiaohang_fix = 'Chành xe' 
                                                                     and c.thongtinxe_sxh in ('PNHNI-29D-04683 (600kg)-GHTT','PNHNI-50LD-21145 (945kg)-GHTT')
                                                                     and a.ma_nvgh_tinhluong <> 'MR2953' THEN 'MR2953' 
                                                                else null end) = p.manv     
)
,

chitieu_doanhso as
(
  with b1 as
  (
    select
      'MR2902' as manv,
      'Hoàng Văn Thành' as tennv,
      'Hà Nam' as tinh,
      '2023-07-01 00:00:00 UTC' as thang,
      180000000 as kh_total
  union all
    select
      'MR2954' as manv,
      'Phạm Đình Cần' as tennv,
      'Ninh Bình' as tinh,
      '2023-07-01 00:00:00 UTC' as thang,
      240000000 as kh_total
  union all
    select
      'MR2676' as manv,
      'Phạm Công Diễn' as tennv,
      'Nam Định' as tinh,
      '2023-07-01 00:00:00 UTC' as thang,
      344848000 as kh_total
  union all 
    select
      'MR2902' as manv,
      'Hoàng Văn Thành' as tennv,
      'Hà Nam' as tinh,
      '2023-08-01 00:00:00 UTC' as thang,
      200000000 as kh_total
  union all
    select
      'MR2954' as manv,
      'Phạm Đình Cần' as tennv,
      'Ninh Bình' as tinh,
      '2023-08-01 00:00:00 UTC' as thang,
      220000000 as kh_total
  union all
    select
      'MR2676' as manv,
      'Phạm Công Diễn' as tennv,
      'Nam Định' as tinh,
      '2023-08-01 00:00:00 UTC' as thang,
      356484970 as kh_total
  union all
    select
      'MR2902' as manv,
      'Hoàng Văn Thành' as tennv,
      'Hà Nam' as tinh,
      '2023-09-01 00:00:00 UTC' as thang,
      220000000 as kh_total
  union all
    select
      'MR2954' as manv,
      'Phạm Đình Cần' as tennv,
      'Ninh Bình' as tinh,
      '2023-09-01 00:00:00 UTC' as thang,
      230000000 as kh_total
  union all
    select
      'MR2676' as manv,
      'Phạm Công Diễn' as tennv,
      'Nam Định' as tinh,
      '2023-09-01 00:00:00 UTC' as thang,
      398484970 as kh_total                 
  )
  select 
    manv,
    tennv,
    tinh,
    cast(thang as timestamp) as thang,
    cast (kh_total as FLOAT64) as kh_total
  from b1
)
,

doanhso_kehoach as
(
  select a.*,
    0 as kh_total
    from data_giaohang a

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
    a.tinh as tentinhkh,
    null as tenquanhuyen,
    null as makenhkh,
    null as makenhphu,
    null as mahco,
    null as maphanloaihco,
    null as maphanhanghco,
    null as masanpham,
    null as tensanphamnb,
    null as tensanphamviettat,
    null as solo,
    null as soluong,
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
    null as inserted_at,
    null as mamds,
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
    null as ngaynhanhang,
    null as status_dv,
    null as soxuathang,
    null as thongtinxe_sxh,
    null as full_leadtime,
    null as chuyenhang_leadtime,
    null as kpi_max_leadtime,
    null as kpi_leadtime,
    null as kpi_chuyenhang,
    null as danhgia_leadtime,
    null as danhgia_chuyenhang,
    null as ngaytaodon,
    null as ngayduyetdon,
    null as nguoi_duyetdon,
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

    a.manv as ma_nvbh,
    a.tennv as ten_nvbh,
    b.supid_bh as masup_bh,
    b.tenquanlytt_bh as tensup_bh,
    b.asm_bh as mamgr_bh,
    b.tenquanlykhuvuc_bh as tenmgr_bh,
    b.rsmid as madir_bh,
    b.tenquanlyvung as tendir_bh,
    b.role_luong_mds as role_banhang,
    b.role_luong_mds_phanloai as role_banhang_pl,
    null as don_co,
    null as ten_thahang_tinhluong,
    null as manv_thahang_tinhluong,
    null as role_thahang,
    null as role_thahang_pl,

    a.kh_total

  from  chitieu_doanhso a
  left join `spatial-vision-343005.staging.d_users` b on a.manv = b.manv --and a.thang = b.thang
  where date(a.thang) >= '2023-06-01' --and a.tenquanlyvung ='Lương Trịnh Thắng'
)
,

result as
(
  select 
    current_datetime ("+7") as thoigian , 
    a.* ,
  
    case when a.donvigiaohang_fix not in ('NVC','Nhà vận chuyển') 
        and a.ma_nvgh_tinhluong not like 'GH%' 
        and a.don_co is null then 1 else 0 end as don_tinh_gh, --- 1 là tinh tiền, 0 là ko tính

    case when (case when a.donvigiaohang_fix not in ('NVC','Nhà vận chuyển') 
        and a.ma_nvgh_tinhluong not like 'GH%' 
        and a.don_co is null then 1 else 0 end) = 1 then a.ma_dh else null end as madon_tinh_gh, 

    b.note as noidung_giaitrinh,
    b.ketqualeadtime_giaitrinh,

    case when b.ketqualeadtime_giaitrinh is null 
        then (case when a.danhgia_leadtime = 'Dat' then 1 else 0 end) 
        else b.ketqualeadtime_giaitrinh end as ketqua_leadtime_tinhluong  , 

    case when (case when a.donvigiaohang_fix not in ('NVC','Nhà vận chuyển') 
                    and a.ma_nvgh_tinhluong not like 'GH%' 
                    and a.don_co is null then 1 else 0 end) is not null 
        and (case when b.ketqualeadtime_giaitrinh is null then (case when a.danhgia_leadtime = 'Dat' then 1 else 0 end) 
                    else b.ketqualeadtime_giaitrinh end) = 1 
        and (case when a.donvigiaohang_fix not in ('NVC','Nhà vận chuyển') 
                    and a.ma_nvgh_tinhluong not like 'GH%' 
                    and a.don_co is null then 1 else 0 end) = 1 then a.ma_dh else null end as madon_leadtimedat_tinhluong,

  from doanhso_kehoach a
  left join `spatial-vision-343005.staging.d_giaitrinhlt_mds` b on a.ma_dh = b.ordernbr --and a.thang = b.thang
  where ngaychungtu >= '2023-06-01' --and ngaychungtu < '2023-05-01'
)

  select *,

    row_number()over(partition by ma_dh,macongtycn order by masanpham) as loc, 

    case when don_tinh_gh = 1 and (row_number()over(partition by ma_dh,macongtycn order by masanpham)) = 1 then full_leadtime 
         else null end as full_leadtime_1,

    case when don_tinh_gh = 1 and kpi_chuyenhang = 48 and (row_number()over(partition by ma_dh,macongtycn order by masanpham)) = 1 
         then chuyenhang_leadtime else null end as chuyenhang_leadtime_1,

    case when don_tinh_gh = 1 and kpi_chuyenhang = 48 and (row_number()over(partition by ma_dh,macongtycn order by masanpham)) = 1 
         then kpi_chuyenhang else null end as kpi_chuyenhang_1
           
  from result
  -- where ten_thahang_tinhluong ='Lê Duy Tùng' and thang ='2023-08-01


);

Create or replace table `warehouse.f_hub_3`

copy `staging_temp.f_hub_3_temp`;

End;