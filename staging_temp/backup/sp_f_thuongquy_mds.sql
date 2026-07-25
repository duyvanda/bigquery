CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_thuongquy_mds()
BEGIN 
TRUNCATE TABLE staging_temp.f_thuongquy_mds_temp;

INSERT INTO staging_temp.f_thuongquy_mds_temp
(

-- CREATE OR REPLACE table staging_temp.f_thuongquy_mds_temp
-- as

with TUYENBAN_MDS as 
(
  with data_tuyen as 
  (
    SELECT 
      extract(year from a.thang) as nam,
      extract(quarter from a.thang) as quy,
      a.thang,
      a.custid,
      a.slsperid,
      a.crtd_datetime,
      Case when a.routetype in ('B','D') then 1 else 2 end as routetype,
      b.tenquanlytt_bh
    FROM `spatial-vision-343005.staging.sync_dms_srm_bytime` a
    left join `spatial-vision-343005.staging.d_users_bytime` b on a.slsperid = b.manv and a.thang = b.thang
    where delroutedet is false --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
  )
  select * 
  from (
          select 
            *,
            row_number() over (partition by custid,thang order by routetype asc,crtd_datetime desc) as loc  
          from data_tuyen
       )
  where loc =1 and thang in ('2023-06-01','2023-09-01','2023-12-01')
)
,

slkh_tuyen as
(
  with tuyen as
  (
    select 
      nam,
      quy,
      a.slsperid,
      b.tencvbh,
      c.businessscope,
      a.custid,
      case when businessscope like '%5' then '05'
           when businessscope like '5%' then '05'
           when businessscope like '%5%' then '05'
           when businessscope like '%05' then '05'
           when businessscope like '05%' then '05'   
           when businessscope like '%05%' then '05'  
           else null end as businessscope_05,

    from TUYENBAN_MDS a
    left join `spatial-vision-343005.staging.d_users_bytime` b on a.slsperid = b.manv and a.thang = b.thang
    left join `spatial-vision-343005.staging.d_master_khachhang` c on a.custid = c.custid
    where --b.tenquanlyvung = 'Lương Trịnh Thắng' and 
    c.active = 'Active' and c.channel ='TP' 
    -- group by 1,2,3,4,5,6,7
  )  
    select 
      nam,
      quy,
      slsperid,
      tencvbh,
      count(distinct custid) as slkh_tuyenmds
    from tuyen
    where businessscope_05 is not null
    group by 1,2,3,4
)
,

doanhso_kh as
( 
  with nhanvien as
  (
    select *
    from `spatial-vision-343005.staging.d_users_bytime` 
    where thang in ('2023-06-01','2023-09-01','2023-12-01')
  )
  ,

  doanhso as
  (
    select 
      extract(year from a.ngaychungtu) as nam,
      extract(quarter from a.ngaychungtu) as quy,
      -- a.thang,
      a.makhdms,
      a.makenhkh,

      case when (makenhkh = 'TP' 
                and a.manv in ('MR1682KN','MR2504','MR1232','MR0806','MR2608','MR2111','MR1682','MR2504KN','MR1232KN','MR0806KN','MR2608KN','MR2111KN')) 
                then ifnull(o.macrs,o1.macrs)
           when (a.manv = 'TMDT_001' and k.tenquanlytt_bh = 'Nguyễn Văn Tiến') then ifnull(o.macrs,o1.macrs)
           when (a.manv = 'TMDT_001' and k.tenquanlytt_bh <> 'Nguyễn Văn Tiến') then b.slsperid
           when (a.manv = 'TMDT_001') then ifnull(o.macrs,o1.macrs)
           when (k1.tenquanlytt_bh = 'Nguyễn Văn Tiến' and makenhphu not in ('SI','SI23','CTD')) then ifnull(o.macrs,o1.macrs)
           else a.manv end as ma_nvbh,   

      masanpham,
      tensanphamviettat,
      case when businessscope like '%5' then '05'
           when businessscope like '5%' then '05'
           when businessscope like '%5%' then '05'
           when businessscope like '%05' then '05'
           when businessscope like '05%' then '05'   
           when businessscope like '%05%' then '05'  
           else null end as businessscope_05,
      sum(doanhsochuavat) as doanhsochuavat
    FROM `spatial-vision-343005.staging.f_sales` a
    left join TUYENBAN_MDS b on a.makhdms = b.custid 
                             and extract(year from a.ngaychungtu) = b.nam 
                             and extract(quarter from a.ngaychungtu) = b.quy
    left join nhanvien c on (case when a.manv = 'TMDT_001' then b.slsperid else a.manv end) = c.manv 
                          and extract(year from a.ngaychungtu) = extract(year from c.thang)
                          and extract(quarter from a.ngaychungtu) = extract(quarter from c.thang)
    left join `spatial-vision-343005.staging.d_master_khachhang` d on a.makhdms = d.custid

    left join `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs_bytime` o on o.phuongxa is not null
                                                                                    and a.tentinhkh = o.tinhtp 
                                                                                    and a.tenquanhuyen = o.quanhuyen 
                                                                                    and a.phuongxa = o.phuongxa 
                                                                                    and a.thang = cast(o.thang as timestamp)
    left join `spatial-vision-343005.staging.d_manual_tuyenbanhang_crs_bytime` o1 on o1.phuongxa is null 
                                                                                    and a.tentinhkh = o1.tinhtp 
                                                                                    and a.tenquanhuyen = o1.quanhuyen 
                                                                                    and a.thang = cast(o1.thang as timestamp)
    left join `spatial-vision-343005.staging.d_users_bytime` k on b.slsperid = k.manv and b.thang = k.thang
    left join `spatial-vision-343005.staging.d_users_bytime` k1 on a.manv = k1.manv and a.thang = k1.thang


    WHERE date (a.ngaychungtu) >= '2023-04-01' 
          and a.makenhkh not in ('NB','OTH_LAB')
          and a.masanpham not like 'V%'
          -- and c.tenquanlyvung = 'Lương Trịnh Thắng'  
          and d.active = 'Active'  
          and d.channel in ('TP') 
    group by 1,2,3,4,5,6,7,8
  )
    select a.*, b.tencvbh
    from doanhso a
    left join nhanvien  b on a.ma_nvbh = b.manv and a.nam = extract(year from b.thang) and a.quy = extract(quarter from b.thang)
    where a.businessscope_05 is not null --doanhsochuavat >= 250000
)
,

slkh_mds as
( 
  select
    nam,
    quy,
    ma_nvbh,
    tencvbh,
    count(distinct makhdms) as slkh_cods
  FROM doanhso_kh
  group by 1,2,3,4
)
,

doanhso_mds as
( 
  select
    nam,
    quy, 
    ma_nvbh,
    tencvbh,
    makenhkh,
    sum(doanhsochuavat) as doanhsochuavat
  FROM doanhso_kh
  group by 1,2,3,4,5
)
,

doanhso_phanphoi_sp as
( 
  select
    nam,
    quy,
    -- thang, 
    ma_nvbh,
    tencvbh,
    sum(doanhsochuavat) as doanhsochuavat_ppsp
  FROM doanhso_kh
  where tensanphamviettat in ('SHED100H','SHED100X','SHED200H','LD200H','SHED200X','LD200X')
  and nam = 2023 and quy = 2
  group by 1,2,3,4
)
,

chitieu_phanphoi_sp as
(
  select
  2023 as nam,
  2 as quy,
  'MR2934' as manv,
  'Nguyễn Minh Tiến' as tennv,
  3647727 as chitieu_ppsp

  union all
  select
  2023 as nam,
  2 as quy,
  'MR1221' as manv,
  'Nguyễn Công Văn' as tennv,
  2272727 as chitieu_ppsp

  union all
  select
  2023 as nam,
  2 as quy,
  'MR2441' as manv,
  'Lý Thái Long' as tennv,
  2218636 as chitieu_ppsp

  union all
  select
  2023 as nam,
  2 as quy,
  'MR1351' as manv,
  'Nguyễn Văn Loan' as tennv,
  5670455 as chitieu_ppsp

  union all
  select 
  2023 as nam,
  2 as quy,
  'MR1222' as manv,
  'Cao Văn Toàn' as tennv,
  8919545 as chitieu_ppsp

  union all 
  select
  2023 as nam,
  2 as quy,
  'MR2929' as manv,
  'Hoàng Văn Đoàn' as tennv,
  9049545 as chitieu_ppsp

  union all
  select 
  2023 as nam,
  2 as quy,
  'MR1739' as manv,
  'Cao Văn Sìn' as tennv,
  18088636 as chitieu_ppsp

  union all
  select 
  2023 as nam,
  2 as quy,
  'MR2604' as manv,
  'Nguyễn Hoàng Linh' as tennv, 
  23565455 as chitieu_ppsp

)
,

chitieu_phanphoi_kh as
(
  select 
  2023 as nam,
  3 as quy,
  'MR2938' as manv,
  'Tô Thanh Thiên' as tennv, 
  20 as chitieu_ppkh

  union all
  select 
  2023 as nam,
  3 as quy,
  'MR1351' as manv,
  'Nguyễn Văn Loan' as tennv, 
  12 as chitieu_ppkh

  union all
  select 
  2023 as nam,
  3 as quy,
  'MR1221' as manv,
  'Nguyễn Công Văn' as tennv, 
  12 as chitieu_ppkh

  union all
  select 
  2023 as nam,
  3 as quy,
  'MR2934' as manv,
  'Nguyễn Minh Tiến' as tennv, 
  13 as chitieu_ppkh

  union all
  select 
  2023 as nam,
  3 as quy,
  'MR2441' as manv,
  'Lý Thái Long' as tennv, 
  9 as chitieu_ppkh

  union all
  select 
  2023 as nam,
  3 as quy,
  'MR2902' as manv,
  'Hoàng Văn Thành' as tennv, 
  15 as chitieu_ppkh

  union all
  select 
  2023 as nam,
  3 as quy,
  'MR2954' as manv,
  'Phạm Đình Cần' as tennv, 
  18 as chitieu_ppkh

  union all
  select 
  2023 as nam,
  3 as quy,
  'MR1739' as manv,
  'Cao Văn Sìn' as tennv, 
  24 as chitieu_ppkh

  union all
  select 
  2023 as nam,
  3 as quy,
  'MR2604' as manv,
  'Nguyễn Hoàng Linh' as tennv, 
  24 as chitieu_ppkh

  union all
  select 
  2023 as nam,
  3 as quy,
  'MR2949' as manv,
  'Hoàng Dương Vũ' as tennv, 
  22 as chitieu_ppkh
)
,

soluong_phanphoi_kh as
(
  select
    nam,
    quy,
    ma_nvbh,
    tencvbh,
    count(distinct makhdms) as sl_ppkh
  FROM doanhso_kh
  where masanpham in ('OH074','OH075','OH077','OH078','T302101008','T302101007','T302101006','T302101005')
        and nam = 2023 
        and quy = 3
  group by 1,2,3,4
)
,

kehoach as
(
  select 
    extract(year from a.thang) as nam,
    extract(quarter from a.thang) as quy,
    -- a.thang,
    a.manv,
    b.tencvbh,
    -- b.supid_bh,
    -- b.tenquanlytt_bh,
    -- b.asm_bh,
    -- b.tenquanlykhuvuc_bh,
    b.role_luong_mds,
    SUM(a.kh_total) AS kh_total
  from  `spatial-vision-343005.staging.d_calendar` a
  left join `spatial-vision-343005.staging.d_users_bytime` b on a.manv = b.manv and a.thang = b.thang
  WHERE date (a.thang) >= '2023-04-01' and role_luong_mds_phanloai in ('MDS2','SDS') --a.tenquanlyvung = 'Lương Trịnh Thắng'
  group by 1,2,3,4,5
)
,

total_nhanvien as
( 
    select 
      a.nam,
      a.quy,
      a.manv as msnvcsmmoi,
      a.tencvbh,
      a.role_luong_mds,
      b.makenhkh,
      a.kh_total,
      b.doanhsochuavat,
      c.doanhsochuavat_ppsp,
      d.chitieu_ppsp,
      e.slkh_tuyenmds,
      f.slkh_cods,
      g.chitieu_ppkh,
      h.sl_ppkh

    from kehoach a
    left join doanhso_mds b on a.manv = b.ma_nvbh and a.nam = b.nam and a.quy = b.quy
    left join doanhso_phanphoi_sp c on a.manv = c.ma_nvbh and a.nam = c.nam and a.quy = c.quy
    left join chitieu_phanphoi_sp d on a.manv = d.manv and a.nam = d.nam and a.quy = d.quy
    left join slkh_tuyen e on a.manv = e.slsperid and a.nam = e.nam and a.quy = e.quy
    left join slkh_mds f on a.manv = f.ma_nvbh and a.nam = f.nam and a.quy = f.quy
    left join chitieu_phanphoi_kh g on a.manv = g.manv and a.nam = g.nam and a.quy = g.quy
    left join soluong_phanphoi_kh h on a.manv = h.ma_nvbh and a.nam = h.nam and a.quy = h.quy
)
,

tinh_thuongquy as
(
  select * ,
    doanhsochuavat/kh_total as tyle_doanhso,
    doanhsochuavat_ppsp/chitieu_ppsp as tyle_phanphoi_sp,
    slkh_cods/slkh_tuyenmds as tyle_khachhang,
    sl_ppkh/chitieu_ppkh as tyle_phanphoi_kh,

  --- TIÊU CHÍ A
      case when nam = 2023 and quy in (2,3) and doanhsochuavat/kh_total < 0.9 then 1*0.6
           when nam = 2023 and quy in (2,3) and (doanhsochuavat/kh_total >= 0.9 and doanhsochuavat/kh_total < 1) then 2*0.6
           when nam = 2023 and quy in (2,3) and (doanhsochuavat/kh_total >= 1 and doanhsochuavat/kh_total < 1.1) then 3*0.6
           when nam = 2023 and quy in (2,3) and (doanhsochuavat/kh_total >= 1.1 and doanhsochuavat/kh_total < 1.2) then 4*0.6
           when nam = 2023 and quy in (2,3) and doanhsochuavat/kh_total >= 1.2 then 5*0.6

           when nam = 2023 and quy in (4) and doanhsochuavat/kh_total < 0.9 then 1*0.7
           when nam = 2023 and quy in (4) and (doanhsochuavat/kh_total >= 0.9 and doanhsochuavat/kh_total < 1) then 2*0.7
           when nam = 2023 and quy in (4) and (doanhsochuavat/kh_total >= 1 and doanhsochuavat/kh_total < 1.1) then 3*0.7
           when nam = 2023 and quy in (4) and (doanhsochuavat/kh_total >= 1.1 and doanhsochuavat/kh_total < 1.2) then 4*0.7
           when nam = 2023 and quy in (4) and doanhsochuavat/kh_total >= 1.2 then 5*0.7
           else 0 end as diem_A,

  --- TIÊU CHÍ C   
      case when nam = 2023 and quy = 2 and slkh_cods/slkh_tuyenmds < 0.75 then 1*0.2
           when nam = 2023 and quy = 2 and (slkh_cods/slkh_tuyenmds >= 0.75 and slkh_cods/slkh_tuyenmds < 0.8) then 2*0.2
           when nam = 2023 and quy = 2 and (slkh_cods/slkh_tuyenmds >= 0.8 and slkh_cods/slkh_tuyenmds < 0.85) then 3*0.2  
           when nam = 2023 and quy = 2 and (slkh_cods/slkh_tuyenmds >= 0.85 and slkh_cods/slkh_tuyenmds < 0.9) then 4*0.2 
           when nam = 2023 and quy = 2 and slkh_cods/slkh_tuyenmds >= 0.9 then 5*0.2

           when nam = 2023 and quy = 3 and slkh_tuyenmds >= 180 and slkh_cods/slkh_tuyenmds < 0.75 then 1*0.2
           when nam = 2023 and quy = 3 and slkh_tuyenmds >= 180 and (slkh_cods/slkh_tuyenmds >= 0.75 and slkh_cods/slkh_tuyenmds < 0.8) then 2*0.2
           when nam = 2023 and quy = 3 and slkh_tuyenmds >= 180 and (slkh_cods/slkh_tuyenmds >= 0.8 and slkh_cods/slkh_tuyenmds < 0.85) then 3*0.2  
           when nam = 2023 and quy = 3 and slkh_tuyenmds >= 180 and (slkh_cods/slkh_tuyenmds >= 0.85 and slkh_cods/slkh_tuyenmds < 0.9) then 4*0.2 
           when nam = 2023 and quy = 3 and slkh_tuyenmds >= 180 and slkh_cods/slkh_tuyenmds >= 0.9 then 5*0.2
           
           when nam = 2023 and quy = 4 and slkh_tuyenmds >= 110 and slkh_cods/slkh_tuyenmds < 0.75 then 1*0.3
           when nam = 2023 and quy = 4 and slkh_tuyenmds >= 110 and (slkh_cods/slkh_tuyenmds >= 0.75 and slkh_cods/slkh_tuyenmds < 0.8) then 2*0.3
           when nam = 2023 and quy = 4 and slkh_tuyenmds >= 110 and (slkh_cods/slkh_tuyenmds >= 0.8 and slkh_cods/slkh_tuyenmds < 0.85) then 3*0.3  
           when nam = 2023 and quy = 4 and slkh_tuyenmds >= 110 and (slkh_cods/slkh_tuyenmds >= 0.85 and slkh_cods/slkh_tuyenmds < 0.9) then 4*0.3 
           when nam = 2023 and quy = 4 and slkh_tuyenmds >= 110 and slkh_cods/slkh_tuyenmds >= 0.9 then 5*0.3
           else 0 end as diem_C,  

  --- TIÊU CHÍ N
      case when nam = 2023 and quy = 2 and doanhsochuavat_ppsp/chitieu_ppsp < 0.9 then 1*0.2
           when nam = 2023 and quy = 2 and (doanhsochuavat_ppsp/chitieu_ppsp >= 0.9 and doanhsochuavat_ppsp/chitieu_ppsp< 1) then 2*0.2
           when nam = 2023 and quy = 2 and (doanhsochuavat_ppsp/chitieu_ppsp >= 1 and doanhsochuavat_ppsp/chitieu_ppsp < 1.1) then 3*0.2
           when nam = 2023 and quy = 2 and (doanhsochuavat_ppsp/chitieu_ppsp >= 1.1 and doanhsochuavat_ppsp/chitieu_ppsp < 1.2) then 4*0.2
           when nam = 2023 and quy = 2 and doanhsochuavat_ppsp/chitieu_ppsp >= 1.2 then 5*0.2

           when nam = 2023 and quy = 3 and sl_ppkh/chitieu_ppkh < 0.9 then 1*0.2
           when nam = 2023 and quy = 3 and (sl_ppkh/chitieu_ppkh >= 0.9 and sl_ppkh/chitieu_ppkh < 1) then 2*0.2
           when nam = 2023 and quy = 3 and (sl_ppkh/chitieu_ppkh >= 1 and sl_ppkh/chitieu_ppkh < 1.1) then 3*0.2
           when nam = 2023 and quy = 3 and (sl_ppkh/chitieu_ppkh >= 1.1 and sl_ppkh/chitieu_ppkh < 1.2) then 4*0.2
           when nam = 2023 and quy = 3 and sl_ppkh/chitieu_ppkh >= 1.2 then 5*0.2
           else 0 end as diem_N,

  from total_nhanvien
)
,

result as
( 
  with quanly_theoquy as
  (
    select *
    from `spatial-vision-343005.staging.d_users_bytime`
    where thang in ('2023-06-01','2023-09-01','2023-12-01')
  )
  select 
    current_datetime ("+7") as thoigian,
    a.*,
    d.supid_bh,
    d.tenquanlytt_bh,
    d.asm_bh,
    d.tenquanlykhuvuc_bh,
    ifnull(b.loaihdld,'Nghỉ việc') as loaihdld,
    ifnull(b.phaply,'Nghỉ việc') as phaply,
    c.invalid_note,

    case when c.invalid_note is not null then 'Không đạt'|| " - "|| c.invalid_note
         when c.invalid_note is null then 'Đạt'
         else null end as is_dat_tinhthuong_quy,

    diem_A + diem_C + diem_N as diemdanhgia,

    case when (diem_A + diem_C + diem_N) < 2 then 'C'
         when (diem_A + diem_C + diem_N) >= 2 AND (diem_A + diem_C + diem_N) < 3 then 'B'
         when (diem_A + diem_C + diem_N) >= 3 AND (diem_A + diem_C + diem_N) < 4 then 'A2'
         when (diem_A + diem_C + diem_N) >= 4 AND (diem_A + diem_C + diem_N) < 4.5 then 'A1'
         when (diem_A + diem_C + diem_N) >= 4.5 then 'A'
         ELSE '' END AS xeploaiquy,

    case when (diem_A + diem_C + diem_N) < 2 then 'Cần hoàn thiện'
         when (diem_A + diem_C + diem_N) >= 2 AND (diem_A + diem_C + diem_N) < 3 then 'Đạt yêu cầu'
         when (diem_A + diem_C + diem_N) >= 3 AND (diem_A + diem_C + diem_N) < 4 then 'Khá'
         when (diem_A + diem_C + diem_N) >= 4 AND (diem_A + diem_C + diem_N) < 4.5 then 'Tốt'
         when (diem_A + diem_C + diem_N) >= 4.5 then 'Xuất sắc'
         ELSE '' END AS phanloai,

    case when trim(loaihdld) in ('Có xác định thời hạn','Không xác định thời hạn') 
              and (diem_A + diem_C + diem_N) < 2 then 0
         when trim(loaihdld) in ('Có xác định thời hạn','Không xác định thời hạn') 
              and (diem_A + diem_C + diem_N) >= 2 AND (diem_A + diem_C + diem_N) < 3 then 0
         when trim(loaihdld) in ('Có xác định thời hạn','Không xác định thời hạn') 
              and (diem_A + diem_C + diem_N) >= 3 AND (diem_A + diem_C + diem_N) < 4 then 2000000
         when trim(loaihdld) in ('Có xác định thời hạn','Không xác định thời hạn') 
              and (diem_A + diem_C + diem_N) >= 4 AND (diem_A + diem_C + diem_N) < 4.5 then 3000000
         when trim(loaihdld) in ('Có xác định thời hạn','Không xác định thời hạn') 
              and (diem_A + diem_C + diem_N) >= 4.5 then 5000000
         ELSE 0 END AS thuongquy

  from tinh_thuongquy a
  left join `spatial-vision-343005.staging.d_hr_dsns` b on a.msnvcsmmoi = b.msnvcsmmoi --and a.quy = extract(quarter from b.thang)
  left join `spatial-vision-343005.staging.d_quarter_eligable` c on a.msnvcsmmoi = c.manv and concat(0,a.quy,a.nam) = c.quarter
  left join quanly_theoquy d on a.msnvcsmmoi = d.manv and a.nam = extract(year from d.thang) and a.quy = extract(quarter from d.thang)
)


select * from result 
-- where quy = 4 and tencvbh ='Cao Văn Sìn'



);
Create or replace table `warehouse.f_thuongquy_mds`

copy `staging_temp.f_thuongquy_mds_temp`;

End;