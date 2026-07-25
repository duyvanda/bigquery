CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_daily_performance_mds_new_v2_bytime()
BEGIN 

CREATE OR REPLACE TABLE staging_temp.f_baocao_daily_performance_mds_new_v2_bytime_temp AS 

(   

WITH lay_thong_tin as
  (
    SELECT 
    a.sodondathang,
    a.ngaychungtu,
    IFNULL(sodontrahang, sodondathang) as ma_dh,
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
    a.manvgh,
    a.nguoigiaohang,
    a.trangthaigiaohang,
    a.donvigiaohang,
    a.tennhavanchuyen,
    a.kieudonhang,
    a.thang,
    a.manvghreal,
    a.tennvghreal,
    a.manvdh_bbgh_tinh,
    a.manvth_bbgh_tinh,
    a.manv_tao_bbgh_nvc,
    manvdh_bbgh_tinh as manv_dh_chanh,
    IFNULL(a.manvghreal, a.manvgh) as mamds,
    soxuathang,
    codexesxh as thongtinxe_sxh,
    c.cluster_state,
    concat(trim(a.sodondathang),'-',a.hoadon) as noi_dh_hoa_don,
    sum(a.soluong) as soluong,
    avg(a.dongiacovat) as dongiacovat,
    sum(a.doanhsocovat) as doanhsocovat,
    avg(a.dongiachuavat) as dongiachuavat,
    sum(a.doanhsochuavat) as dschuvat_banhang,
    sum (a.doanhsochuavat) as dschuvat_giaohang
    FROM `spatial-vision-343005.staging.f_sales` a
    LEFT JOIN `staging.d_master_khachhang` c on c.custid = a.makhdms
    WHERE date (a.ngaychungtu) >= '2023-01-01' 
            AND a.makenhkh not in ('NB','OTH_LAB')
            AND a.masanpham not like 'V%'
            AND a.trahangkhacthang is not true
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52
  )

  ,

  DATA_F_SALES_FIXED as
  (
    SELECT
    a.* except(manv_tao_bbgh_nvc,tennhavanchuyen),
    IFNULL(dc.bbght_dvgt,a.tennhavanchuyen) as tennhavanchuyen,
    IFNULL(dc.donvigiaohang,a.donvigiaohang) as donvigiaohang_fix,
    IFNULL(dc.manvghreal,a.mamds) as ma_mds_fix,
    IFNULL(dc.manvdh,a.manv_dh_chanh) as ma_donghang_fix,
    

    CASE 
        WHEN IFNULL(dc.donvigiaohang,a.donvigiaohang) not in ('Nhà vận chuyển','NVC' ) then IFNULL(dc.manvghreal,a.mamds) 
        ELSE null
    END AS ma_nvgh_tinhluong,
    CASE 
        WHEN IFNULL(dc.donvigiaohang,a.donvigiaohang)  in ('Nhà vận chuyển','NVC' ) then IFNULL(manv_tao_bbgh_nvc,a.mamds) 
        ELSE null
    END AS manv_tao_bbgh_nvc,

    CASE
      WHEN 
        IFNULL(dc.donvigiaohang,a.donvigiaohang) IN ('Nhà vận chuyển','NVC')
        THEN IFNULL(dc.manvdh, IFNULL(manv_tao_bbgh_nvc,a.mamds))
      WHEN
        IFNULL(dc.donvigiaohang,a.donvigiaohang) = 'Chành xe'
        AND IFNULL(dc.bbght_dvgt,a.tennhavanchuyen) !=  'MERAPLION'
        THEN IFNULL(dc.manvdh,a.manv_dh_chanh) 
      ELSE null
    END AS ma_donghang_tinhluong,

    CASE 
      WHEN
        IFNULL(dc.donvigiaohang,a.donvigiaohang) = 'Chành xe'
        AND IFNULL(dc.bbght_dvgt,a.tennhavanchuyen) = 'MERAPLION'
      THEN manv_dh_chanh 
      ELSE NULL 
    END AS manv_thahang_tinhluong_c1,
    
    CASE 
    WHEN
    IFNULL(dc.donvigiaohang,a.donvigiaohang) = 'Chành xe'
    THEN  manvth_bbgh_tinh 
    ELSE NULL 
    END AS manv_thahang_tinhluong,

    -- NHU START HERE 28/03/2024
    --case
    --when n.Terms IN ('01','03') or (n.Terms NOT IN ('01','03') and n.paymentsform = 'B') 
    --then manvgh
    --else null
    --end AS manv_phu_trach_thu_hoi_bbgh,

    case
    when ifnull(dc.donvigiaohang, a.donvigiaohang) IN  ('Nhà vận chuyển','NVC') THEN ifnull(manv_tao_bbgh_nvc,mamds)
    when ifnull(dc.donvigiaohang, a.donvigiaohang) NOT IN ('Nhà vận chuyển','NVC') AND n.Terms NOT IN ('01','03')  THEN mamds
    else null
    end AS manv_phu_trach_thu_hoi_bbgh,

    CASE 
    WHEN so_du_chungtu <= 0 THEN 1 
    ELSE 0 
    END AS so_du_chung_tu_het_no,

    CASE 
    WHEN trim(lower(ketoandanhan)) IN ('x','mds giữ để thu tiền mặt') THEN 1
    ELSE 0 
    END AS da_thu_hoi_bbgh
    -- END

    from lay_thong_tin a
    LEFT JOIN `spatial-vision-343005.staging.d_dieuchinhmds` dc on a.ma_dh = dc.sodondathang
    LEFT JOIN `staging_temp.d_rawdata_debt` n on a.sodondathang = n.Ordnbr and a.hoadon = n.InvcNbr
--    LEFT JOIN `staging.d_mds_thuhoi_bbgh` n1 on concat(trim(a.sodondathang),'-',a.hoadon) = n1.noimadhsohoadon
    LEFT JOIN `staging.d_kt_thuhoi_bbgh` n2 on concat(trim(a.sodondathang),'-',a.hoadon) = trim(n2.noimadhsohoadon)
    where IFNULL(dc.donvigiaohang,a.donvigiaohang) is not null
  )
,

NGAYGIAOHANG as
(
  select 
  crtd_datetime as crtd_datetime_dv, 
  branchid,
  ordernbr,
  status as status_dv,
  delivery_date as lupd_datetime_dv
  FROM `spatial-vision-343005.staging.sync_dms_dv` dv
  where dv.delivery_date IS NOT NULL AND dv.status = 'C'
)

, NGAYCHOTSO as
(
  select 
  branchid,
  ordernbr,
  crtd_datetime as crtd_datetime_dv
  FROM `spatial-vision-343005.staging.sync_dms_dv` dv
  where dv.crtd_datetime IS NOT NULL and date(crtd_datetime)>= '2023-01-01'
  QUALIFY row_number() over (partition by ordernbr,branchid order by crtd_datetime asc ) = 1
)

, suco as
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
    group by 1
)
,

data_giaohang as
-- Xu ly leadtime va vai tro
(
  SELECT a.*except(manvth_bbgh_tinh, manvdh_bbgh_tinh),
      b1.crtd_datetime_dv as ngaychotso,
      b.lupd_datetime_dv as ngaygiaohang_fix,
      b.status_dv,
      case 
      when b.lupd_datetime_dv is null
      then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.crtd_datetime,minute)/60,2)
      else round(datetime_diff (b.lupd_datetime_dv,h.crtd_datetime,minute)/60,2) 
      end as full_leadtime,

      case 
      when b.lupd_datetime_dv is null 
      then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.ApprovalDate,minute)/60,2)
      else round(datetime_diff (b.lupd_datetime_dv,h.ApprovalDate,minute)/60,2) 
      end as full_leadtime_duyet,

      i.ltfromcrtd as kpi_leadtime,

      case 
      when a.donvigiaohang_fix in ('Nhà vận chuyển','NVC') then null 
      when a.donvigiaohang_fix not in ('Nhà vận chuyển','NVC')
      and (
          case when b.lupd_datetime_dv is null 
          then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour), h.crtd_datetime,minute)/60,2)
          else round(datetime_diff (b.lupd_datetime_dv,h.crtd_datetime,minute)/60,2) end
          ) 
          > i.ltfromcrtd
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
      a.manv as ma_nvbh,
      IF (a.kieudonhang in ('CO'), sodontrahang , null)  as don_co,
      IF (a.kieudonhang in ('IR'), sodontrahang , null)  as don_ir,
      u.suco,

      l1.tencvbh as ten_thahang_tinhluong_c1,
      l1.role_luong_mds as role_thahang_c1,
      l1.role_luong_mds_phanloai as role_thahang_pl_c1,

      l.tencvbh as ten_thahang_tinhluong,
      l.role_luong_mds as role_thahang,
      l.role_luong_mds_phanloai as role_thahang_pl,


      --NHU BO SUNG TEN

      u4.supid   AS ma_ql_phu_trach_thu_hoi_bbgh,
      u4.tencvbh AS ten_phu_trach_thu_hoi_bbgh,
      u4.tenquanlytt AS ten_ql_phu_trach_thu_hoi_bbgh
      
      --END

      , 
      
      case when e.role_luong_mds_phanloai = 'MDS' and makenhkh in ('TP','PCL') then 'MDS-T (TP-PCL)' 
          when e.role_luong_mds_phanloai = 'MDS' and makenhkh in ('INS','MT','CLC') THEN 'MDS-T2 (INS-CLC-MT)' 
          when e.role_luong_mds_phanloai = 'MDS2' then 'MDS2-T'
          when e.role_luong_mds_phanloai = 'LOG' and makenhkh IN ('INS','CLC','MT') THEN 'LOG-T (INS-CLC-MT)'
          when e.role_luong_mds_phanloai = 'LOG' and makenhkh IN ('TP','PCL') THEN 'LOG-T2 (TP-PCL)'
          when e.role_luong_mds_phanloai like 'LOGHUB%' then 'LOGHUB-T'
          ELSE 'KHÁC' 
      end as phanloai_doanhso_gh,

      --mapping thong tin ban hang
      u3.tencvbh as ten_nvbh,
      u3.supid_bh as masup_bh,
      u3.tenquanlytt_bh as tensup_bh,
      u3.asm_bh as mamgr_bh,
      u3.tenquanlykhuvuc_bh as tenmgr_bh,
      u3.rsmid as madir_bh,
      u3.tenquanlyvung as tendir_bh,
      u3.role_luong_mds as role_banhang,
      u3.role_luong_mds_phanloai as role_banhang_pl,
      SUM(dschuvat_giaohang) OVER (PARTITION BY ma_dh,a.macongtycn) as ds_tong_dh

  from DATA_F_SALES_FIXED a
  LEFT JOIN NGAYGIAOHANG b on a.ma_dh = b.ordernbr and a.macongtycn = b.branchid
  LEFT JOIN NGAYCHOTSO b1 on a.ma_dh = b1.ordernbr and a.macongtycn = b1.branchid
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_pda_so` h on a.ma_dh = h.ordernbr
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` i on a.makhdms = i.custid
  LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` e on a.ma_nvgh_tinhluong = e.manv and e.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` f on a.ma_donghang_tinhluong = f.manv and f.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` f1 on a.manvdh_bbgh_tinh = f1.manv and f1.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` l on l.manv = a.manv_thahang_tinhluong and l.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` l1 on l1.manv = a.manv_thahang_tinhluong_c1 and l1.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` k1 on a.manv = k1.manv and k1.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` u3 on a.manv = u3.manv and u3.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users_bytime` u4 on a. manv_phu_trach_thu_hoi_bbgh = u4.manv and u4.thang = a.thang
  LEFT JOIN suco u on a.ma_dh = u.ordernbr
  
)

select
current_datetime ("+7") as thoigian , 
a.* ,



case -- case 1 2 3 phia duoi la dieu kien giong nhau
when a.kieudonhang in ('IN') 
and abs(ds_tong_dh) > 0
and a.donvigiaohang_fix not in ('NVC','Nhà vận chuyển')
and a.ma_nvgh_tinhluong not like 'GH%'
then 1
else 0
end as don_tinh_gh, -- 1 là tinh tiền, 0 là ko tính

case when 
a.kieudonhang in ('IN') 
and abs(ds_tong_dh) > 0
and a.donvigiaohang_fix not in ('NVC','Nhà vận chuyển')
and a.ma_nvgh_tinhluong not like 'GH%'
then ma_dh 
else null 
end as madon_tinh_gh,


--madon_leadtimedat_tinhluong thỏa 2 dk. 1)Phải là dh tính GH 2)phải đạt LT FINAL (sau giải trình)
--case when (true) and (true) then ma_dh else null end as madon_leadtimedat_tinhluong

case when (
  ( -- when don_tinh_gh = 1
    case when
    a.kieudonhang in ('IN') 
    and abs(ds_tong_dh) > 0
    and a.donvigiaohang_fix not in ('NVC','Nhà vận chuyển')
    and a.ma_nvgh_tinhluong not like 'GH%'
    then 1
    else 0 end
  ) = 1
) and (
  ifnull(b.ketqualeadtime_giaitrinh,(case when a.danhgia_leadtime = 'Dat' then 1 else 0 end)) = 1
) then ma_dh else null 
end as madon_leadtimedat_tinhluong,


0 as don_tinh_dh,

b.note as noidung_giaitrinh,
b.ketqualeadtime_giaitrinh,
ifnull(b.ketqualeadtime_giaitrinh,(case when a.danhgia_leadtime = 'Dat' then 1 else 0 end)) as ketqua_leadtime_tinhluong,

TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour) as inserted_at,

-- Với mỗi đơn hàng có nhiều sản phẩm chỉ lấy ra dòng đầu tiên để tính leadtime
case
  when
  (
    -- when don_tinh_gh = 1
    case
    when a.kieudonhang in ('IN') 
    and abs(ds_tong_dh) > 0
    and a.donvigiaohang_fix not in ('NVC','Nhà vận chuyển')
    and a.ma_nvgh_tinhluong not like 'GH%'
    then 1
    else 0 end
  ) = 1
  and 
  (
    row_number()over(partition by ma_dh,macongtycn order by masanpham)
  ) = 1 then full_leadtime 
  else null 
end as full_leadtime_1,


  -- NHU START HERE 28/03/2024 ma tính thu hoi bb
  case
  when a.kieudonhang in ('IN') 
  and abs(ds_tong_dh) > 0 
  then noi_dh_hoa_don 
  else null
  end as ma_noi_tinh_thu_hoi_bbgh

    -- END


from data_giaohang a
LEFT JOIN `spatial-vision-343005.staging.d_giaitrinhlt_mds` b on a.ma_dh = b.ordernbr
where ngaychungtu >= '2023-01-01' 

);

Create or replace table `staging_temp.f_baocao_daily_performance_mds_new_v2_bytime`

copy `staging_temp.f_baocao_daily_performance_mds_new_v2_bytime_temp`;

CALL `spatial-vision-343005.staging_temp.sp_f_luonghieuqua_mds`();

END;