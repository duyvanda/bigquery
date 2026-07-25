CREATE VIEW `spatial-vision-343005.warehouse.view_sp_f_nhacdon_tp_12tuan`
AS with caresoft as
(
  with bang1 as
  (
    select 
      distinct date (thoidiemtao) as ngaytao,
      makhdms as makhOA,
      'OA' as source,
      nullif(sodienthoaichinh,sodienthoaiphu1) as sdt_cs ,
      row_number() over (partition by makhdms order by thoidiemtao asc ) as loc
    from `spatial-vision-343005.staging.d_caresoft_customer`
    where makhdms is not null
  )
  select * from bang1
  where loc = 1
)  
,

ecom as 
(
  with bang2 as 
  (
    select 
      distinct date(created_at) as ngayactive,
      customer_code as makhEO,
      'EO' as source,
      customer_phone,
      row_number() over (partition by customer_code order by created_at asc) as loc
    from `spatial-vision-343005.staging.f_crawl_activate_ecom`
  )
  select * from bang2 
  where loc = 1
)
,

dskh_tp as
(
  select
    a.branchid,
    a.branchname,
    a.custid,
    a.custname, 
    a.channel,
    a.shoptype,
    a.hcoid,
    a.hcotypeid,
    a.classid,
    a.statedescr,
    a.territorydescr,
    a.shortterritorydescr,
    a.phone as sdt_dms,
    b.sdt_cs,
    b.ngaytao as ngay_dinhdanh,
    c.customer_phone as sdt_ecom,
    c.ngayactive as ngay_kichhoat
  from `spatial-vision-343005.staging.d_master_khachhang` a
  left join caresoft b on a.custid = b.makhOA
  left join ecom c on a.custid = c.makhEO
  where channel = 'TP'
)
,

tuyen_banhang as 
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

f_sale as
(
  with doanhso as
  (
    with ds_tp as
    (
      select 
        macongtycn,
        congtycn,
        makhdms, 
        tenkhachhang,
        tentinhkh,
        makenhkh,
        makenhphu,
        tenquanhuyen,
        phuongxa,
        ngaychungtu,
        sodondathang,
        masanpham,
        tensanphamnb,
        mahd,
        manv,
        -- khuvucviettat,
        case when manv = 'TMDT_001' then 'online' else 'offline' end as kenh_muahang,
        sum(doanhsochuavat) as doanhsochuavat
      From `spatial-vision-343005.staging.f_sales` a
      --chi lay cac KH trong danh sach
      INNER JOIN `staging.d_ds_nhac_don_tp_cx` b on a.makhdms = b.ma_khach_hang
      where makenhkh = 'TP'and masanpham not like 'V%' and ngaychungtu >= '2023-01-01'
      group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
    )
      select 
        *,
        row_number()over(partition by makhdms,masanpham,kenh_muahang order by ngaychungtu desc) as loc
      from ds_tp 
      where doanhsochuavat > 0
  )
  ,
  maptuyenban as
  (
    select 
      a.*,
      d.shortterritorydescr as  khuvucviettat,
      case when extract (DAYOFWEEK FROM a.ngaychungtu) = 7 then date_add (date(a.ngaychungtu), interval 2 day)
           when extract (DAYOFWEEK FROM a.ngaychungtu) = 1 then date_add (date(a.ngaychungtu), interval 1 day)
           else date(a.ngaychungtu) end as ngaychuyendoi,
      d.classid,
      d.hcoid,
      d.hcotypeid,
      d.sdt_dms,
      d.sdt_ecom,
      d.sdt_cs,
      d.ngay_dinhdanh,
      d.ngay_kichhoat,
      ifnull((case when a.manv in ('MR1682KN','MR2504','MR1232','MR0806','MR2608','MR2111','MR1682','MR2504KN','MR1232KN','MR0806KN','MR2608KN','MR2111KN') 
                then ifnull(ifnull(o.macrs,o1.macrs),a.manv)
                      when (a.manv = 'TMDT_001' and k.tenquanlytt_bh = 'Nguyễn Văn Tiến') then ifnull(o.macrs,o1.macrs)
                      when (a.manv = 'TMDT_001' and k.tenquanlytt_bh <> 'Nguyễn Văn Tiến') then c.slsperid
                      when (a.manv = 'TMDT_001') then ifnull(o.macrs,o1.macrs)
                      when  k1.tenquanlytt_bh = 'Nguyễn Văn Tiến' and makenhphu not in ('SI','SI23','CTD') then ifnull(o.macrs,o1.macrs)
                      else a.manv end), a.manv) as ma_nvbh,
      k2.firstname as ten_nvbh,
      k2.role,
      k3.tenquanlytt,
    from doanhso a
    left join tuyen_banhang c on a.makhdms = c.custid
    left join dskh_tp d on a.makhdms = d.custid
    left join `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` o on o.phuongxa is not null --and o.ncrm = 'Lương Trịnh Thắng'
                                                                          and a.tentinhkh = o.tinhtp 
                                                                          and a.tenquanhuyen = o.quanhuyen 
                                                                          and a.phuongxa = o.phuongxa
    left join `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs` o1 on o1.phuongxa is null --and o1.ncrm = 'Lương Trịnh Thắng'
                                                                          and a.tentinhkh = o1.tinhtp 
                                                                          and a.tenquanhuyen = o1.quanhuyen 
    left join `spatial-vision-343005.staging.d_users` k on c.slsperid = k.manv
    left join `spatial-vision-343005.staging.d_users` k1 on a.manv = k1.manv 
    left join `spatial-vision-343005.staging.d_dms_master_users` k2 on 
              ifnull((case when a.manv in ('MR1682KN','MR2504','MR1232','MR0806','MR2608','MR2111','MR1682','MR2504KN','MR1232KN','MR0806KN','MR2608KN','MR2111KN') 
                                then ifnull(o.macrs,o1.macrs)
                           when (a.manv = 'TMDT_001' and k.tenquanlytt_bh = 'Nguyễn Văn Tiến') then ifnull(o.macrs,o1.macrs)
                           when (a.manv = 'TMDT_001' and k.tenquanlytt_bh <> 'Nguyễn Văn Tiến') then c.slsperid
                           when (a.manv = 'TMDT_001') then ifnull(o.macrs,o1.macrs)
                           when  k1.tenquanlytt_bh = 'Nguyễn Văn Tiến' and makenhphu not in ('SI','SI23','CTD') then ifnull(o.macrs,o1.macrs)
                           else a.manv end), a.manv) 
              = k2.username  
    left join `spatial-vision-343005.staging.d_users` k3 on 
              ifnull((case when a.manv in ('MR1682KN','MR2504','MR1232','MR0806','MR2608','MR2111','MR1682','MR2504KN','MR1232KN','MR0806KN','MR2608KN','MR2111KN') 
                                then ifnull(o.macrs,o1.macrs)
                           when (a.manv = 'TMDT_001' and k.tenquanlytt_bh = 'Nguyễn Văn Tiến') then ifnull(o.macrs,o1.macrs)
                           when (a.manv = 'TMDT_001' and k.tenquanlytt_bh <> 'Nguyễn Văn Tiến') then c.slsperid
                           when (a.manv = 'TMDT_001') then ifnull(o.macrs,o1.macrs)
                           when  k1.tenquanlytt_bh = 'Nguyễn Văn Tiến' and makenhphu not in ('SI','SI23','CTD') then ifnull(o.macrs,o1.macrs)
                           else a.manv end), a.manv) 
              = k3.manv      

    where a.loc = 1
  )
  select * from maptuyenban
)
,

result as 
(
  select 
    a.*, 
    case when a.ngaychuyendoi = current_date() then null
         else date_diff (current_date(), a.ngaychuyendoi,day) 
         end as songay_chuadatdon,
    round((date_diff(current_date(), a.ngaychuyendoi,day))/7,0) as sotuan_chuadatdon,

  from f_sale a
)

select *, 
  case when sotuan_chuadatdon <> 0 then mod (cast(round(sotuan_chuadatdon,0) as int64),12)
       else null end as dieukien_guitn_12,
  case when sotuan_chuadatdon <> 0 then mod (cast(round(sotuan_chuadatdon,0) as int64),4)
       else null end as dieukien_guitn_4,       

from result;