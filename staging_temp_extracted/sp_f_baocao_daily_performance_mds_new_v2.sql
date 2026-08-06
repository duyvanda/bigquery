-- ==========================================================================
-- Routine Name : sp_f_baocao_daily_performance_mds_new_v2
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-06-01 09:55:20.400000+00:00
-- Last Altered : 2026-06-01 09:55:20.400000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_daily_performance_mds_new_v2()
BEGIN

--
DECLARE partition_date DATE DEFAULT DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH);
BEGIN TRANSACTION;
DELETE FROM
    `warehouse.f_baocao_daily_performance_mds_new_v2`
WHERE
    DATE(ngaychungtu) >= DATE(partition_date);
INSERT INTO
    `warehouse.f_baocao_daily_performance_mds_new_v2`
-- BAT DAU SELECT
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
    CASE
        WHEN a.makhdms IN ('008140', '003589', '013410', '018851') THEN 'ECE'
        WHEN a.masanpham = 'EH092'
            AND ngaychungtu >= '2024-04-01'
            AND a.makenhkh = 'INS' THEN 'CLC'
        ELSE a.makenhkh
    END AS makenhkh,
    a.makenhphu,
    a.mahco,
    a.maphanloaihco,
    a.maphanhanghco,
    f.invoicecustid,
    REGEXP_REPLACE(f.custinvcname, r'[\n\r]', ' ') as custinvcname,
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
    -- a.trangthaigiaohang,
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
    a.soluong as soluong,
    a.dongiacovat as dongiacovat,
    a.doanhsocovat as doanhsocovat,
    a.dongiachuavat as dongiachuavat,
    a.doanhsochuavat as dschuvat_banhang,
    IF (a.trahangkhacthang is not true, a.doanhsochuavat, 0)  as dschuvat_giaohang,
    FROM `spatial-vision-343005.staging.f_sales` a
    LEFT JOIN `spatial-vision-343005.staging.sync_dms_so` f ON f.ordernbr = a.mahd AND f.branchid = a.macongtycn
    LEFT JOIN `staging.d_master_khachhang` c on c.custid = a.makhdms
    WHERE
    true
    and date (a.ngaychungtu) >= date(partition_date)
    AND a.macongtycn not in ('DL0001') -- loại các đơn kim đô sales out
    AND a.masanpham not like 'V%'
    AND
        (CASE
            WHEN a.makhdms IN ('008140', '003589', '013410', '018851') THEN 'ECE'
            ELSE a.makenhkh
        END) in ('INS', 'CLC', 'PCL', 'TP','MT', 'ECE', 'EXP', 'GT')
  )
      , hoa_don_goc as (
    select
    c.branchid,
    c.OrigOrderNbr as Ir_OrigOrderNbr,
    c.SalesOrderType,
    c.InvcNbr,
    c.InvcNote,
    o.OrderNbr,
    o.OrigOrderNbr,
    sod.OrigOrderNbr as Ori_OrigOrderNbr,
    sod.InvcNbr as ori_InvcNbr
    FROM `staging.sync_dms_so` c
    LEFT JOIN `staging.sync_dms_pda_so` o  on o.OrderNbr = c.OrigOrderNbr and o.BranchID = c.BranchID and cast (o.crtd_datetime as Date) >= '2025-06-01'
    LEFT JOIN `staging.sync_dms_so` sod ON sod.OrderNbr=o.OrigOrderNbr AND sod.BranchID=o.BranchID and cast (sod.crtd_datetime as Date) >= '2025-06-01'
    where c.SalesOrderType <> '' and c.OrderType = 'IR' and cast (c.crtd_datetime as Date) >= '2025-06-01'
    )
    ,ds_tong_dh_hoa_don as
    (
      SELECT
      IFNULL(sodontrahang, sodondathang) as ma_dh,
      macongtycn,
      IFNULL(hd.ori_InvcNbr,a.hoadon) as hoadon,
      sum(doanhsochuavat) as ds_tong_hoa_don
      FROM `spatial-vision-343005.staging.f_sales` a
      LEFT JOIN hoa_don_goc hd on a.sodondathang = hd.Ir_OrigOrderNbr and a.macongtycn = hd.branchid and hd.InvcNbr = a.hoadon
      where date(ngaychungtu) >= date(partition_date)
      group by 1,2,3
    )
  , ds_tong_dh as (
    -- DH0-0624-00119 don nay bi loai boi dieu kien tra hang khac thang nen ds tong dh bi sai
    select
    ma_dh,
    macongtycn,
    sum(ds_tong_hoa_don) as ds_tong_dh
    from ds_tong_dh_hoa_don a
    group by 1,2

  )
  , manual_upload_hinh_anh_bbgh as

  (
      select distinct thong_tin_don_hang_upload from staging.d_mds_upload_hinh_anh_bbgh where thong_tin_don_hang_upload not like '%PBNH%'
      UNION DISTINCT
      select distinct ordernbr from staging.d_mds_upload_hinh_anh_bbgh a
      LEFT JOIN (select distinct branchid, reportid, ordernbr from staging.sync_dms_rd) c on a.thong_tin_don_hang_upload = c.reportid and a.chi_nhanh = c.branchid
      where thong_tin_don_hang_upload like '%PBNH%'
  )
    , raw_debt as (

    select distinct n.Terms, n.paymentsform, n.Ordnbr, n.InvcNbr from `staging_temp.d_rawdata_debt` n  where dateoforder >= date(partition_date)

    )
, upload_orc AS (
    SELECT
    DISTINCT
    b.custid,
    ifnull(b1.origordernbr, b.origordernbr) as origordernbr,
    b.invcnbr,
    b.branchid,
    a.manv,
    a.inserted_at,
    'x' AS ketoandanhan,
    CONCAT('https://bi.meraplion.com/DMS/kt_bbgh_proof/0_', b.invcnbr, '.jpeg') AS ocr_url
    FROM
        `spatial-vision-343005.staging.sync_ocr_delivery_record` AS a
    LEFT JOIN
        `staging.sync_dms_so` AS b
        ON a.invoice_number = b.invcnbr
        AND a.invoice_symbol = b.invcnote
    /*invoice_number = '00025305' trong bảng SO sẽ ra mã HLxxx => phải lấy mã HL này lấy ra mã đơn thực tế tiếp*/
    LEFT JOIN
        `staging.sync_dms_so` AS b1
        ON b.origordernbr = b1.ordernbr
        AND b.branchid = b1.branchid
    UNION DISTINCT
    SELECT
    DISTINCT
    c.makhdms as custid,
    b.ordernbr as origordernbr,
    c.hoadon as invcnbr,
    a.ma_chi_nhanh as branchid,
    a.manv,
    a.inserted_at,
    'x' AS ketoandanhan,
    CONCAT('https://bi.meraplion.com/DMS/kt_bbgh_proof_nvc/0_', b.ordernbr, a.ma_chi_nhanh, '.jpeg') AS ocr_url
    FROM `spatial-vision-343005.staging.sync_ocr_delivery_record_nvc` a
    LEFT JOIN `spatial-vision-343005.staging.sync_dms_rd` b on a.ma_chung_tu = b.reportid and a.ma_chi_nhanh = b.branchid
    LEFT JOIN `staging.f_sales` c on b.ordernbr = c.sodondathang and c.ngaychungtu>= '2026-03-01'
)

  -- , upload_orc AS (
  --     SELECT
  --     DISTINCT
  --     b.custid,
  --     ifnull(b1.origordernbr, b.origordernbr) as origordernbr,
  --     b.invcnbr,
  --     b.branchid,
  --     a.manv,
  --     a.inserted_at,
  --     'x' AS ketoandanhan,
  --         CONCAT('https://bi.meraplion.com/DMS/kt_bbgh_proof/0_', b.invcnbr, '.jpeg') AS ocr_url
  --     FROM
  --         `spatial-vision-343005.staging.sync_ocr_delivery_record` AS a
  --     LEFT JOIN
  --         `staging.sync_dms_so` AS b
  --         ON a.invoice_number = b.invcnbr
  --         AND a.invoice_symbol = b.invcnote
  --     /*invoice_number = '00025305' trong bảng SO sẽ ra mã HLxxx => phải lấy mã HL này lấy ra mã đơn thực tế tiếp*/
  --     LEFT JOIN
  --         `staging.sync_dms_so` AS b1
  --         ON b.origordernbr = b1.ordernbr
  --         AND b.branchid = b1.branchid
  -- )
  , DATA_F_SALES_FIXED as
  (
    SELECT
    a.* except(manv_tao_bbgh_nvc),
    IFNULL(dc.bbght_dvgt,a.tennhavanchuyen) as tennhavanchuyen_fix,
    IFNULL(dc.donvigiaohang,a.donvigiaohang) as donvigiaohang_fix,
    IFNULL(dc.manvghreal,a.mamds) as ma_mds_fix,
    IFNULL(dc.manvdh,a.manv_dh_chanh) as ma_donghang_fix,
    n4.note,
    n4.img1,
    n4.img2,
    n4.img3,
    n5.reportid as bbnh_nvc,
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
    THEN IFNULL(dc.manvdh, IFNULL(manv_tao_bbgh_nvc,a.mamds)) ELSE NULL end as manv_dong_hang_nvc_tinhluong,
    CASE
    WHEN
    IFNULL(dc.donvigiaohang,a.donvigiaohang) = 'Chành xe'
    AND IFNULL(dc.bbght_dvgt,a.tennhavanchuyen) !=  'MERAPLION'
    THEN IFNULL(dc.manvdh,a.manv_dh_chanh) ELSE NULL end as manv_dong_hang_chanh_tinhluong,
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
        WHEN IFNULL(dc.donvigiaohang, a.donvigiaohang) = 'Chành xe'
        AND IFNULL(dc.bbght_dvgt, a.tennhavanchuyen) = 'MERAPLION'
        THEN IFNULL(dc.manvthc1, manv_dh_chanh)
        ELSE NULL
    END AS manv_thahang_tinhluong_c1,
    CASE
    WHEN
    IFNULL(dc.donvigiaohang,a.donvigiaohang) = 'Chành xe'
    THEN  IFNULL(dc.manvthc2, manvth_bbgh_tinh)
    ELSE NULL
    END AS manv_thahang_tinhluong,
    CASE
    WHEN n.Terms NOT IN ('01','03')
    AND n.paymentsform != 'B' then mamds
    ELSE NULL END AS manv_phu_trach_thu_hoi_bbgh,
    0 AS so_du_chung_tu_het_no, -- Không sét nợ nữa

    CASE
        /* Logic cũ */
        WHEN trim(lower( ifnull(n2.ketoandanhan, n3.ketoandanhan)) ) IN ('x','mds giữ để thu tiền mặt','khách hàng thanh toán tiền ngay không ký bbgh',
             'khách hàng đã thanh toán không còn công nợ','kt đã nhận hình ảnh', 'kế toán đã nhận bản gốc', 'kt nhận hình ảnh đơn 0 đồng') THEN 1

        /* Logic mới: Check kết quả từ A Thắng là 'Dat' */
        WHEN trim(lower(mn.ket_qua_tu_a_thang)) = 'dat' THEN 1
        ELSE 0
    END AS da_thu_hoi_bbgh,
    n6.deliverydroptype,
    from lay_thong_tin a
    LEFT JOIN `spatial-vision-343005.staging.d_dieuchinhmds` dc on a.ma_dh = dc.sodondathang
    LEFT JOIN `raw_debt` n on a.sodondathang = n.Ordnbr and a.hoadon = n.InvcNbr
    LEFT JOIN `staging.d_kt_thuhoi_bbgh` n2 on concat(trim(a.sodondathang),'-',a.hoadon) = trim(n2.noimadhsohoadon)
    LEFT JOIN `upload_orc` n3 on CONCAT(TRIM(a.sodondathang), '-', a.hoadon) = CONCAT(TRIM(n3.origordernbr), '-', n3.invcnbr)

    /* Join trực tiếp bảng giải trình A Thắng */
    LEFT JOIN `spatial-vision-343005.staging.d_manual_thu_hoi_bbgh_giai_trinh_dat` mn
    ON concat(trim(a.sodondathang),'-',a.hoadon) = trim(mn.ma_dh_noi_so_hoa_don)

    LEFT JOIN `staging.view_sync_dms_bbgh_checkin` n4 ON a.ma_dh = n4.ordernbr AND a.macongtycn = n4.branchid
    LEFT JOIN `staging.sync_dms_rd` n5 on n5.ordernbr = a.ma_dh
    and date(n5.crtd_datetime) >= date(partition_date)
    LEFT JOIN `staging.sync_dms_dr` n6 on n6.ordernbr = a.ma_dh and a.macongtycn = n6.branchid
    and date(n6.crtd_datetime) >= date(partition_date)

  )
, first_time_fail as (
  SELECT branchid, ordernbr, crtd_datetime  FROM `spatial-vision-343005.staging.sync_dms_delihistory` WHERE TIMESTAMP_TRUNC(crtd_datetime, DAY) >= TIMESTAMP("2024-08-01")
  and descr is not null
  and date(crtd_datetime)>= '2024-08-01'
  QUALIFY row_number() over (partition by branchid, ordernbr order by crtd_datetime asc) = 1
)
, NGAYGIAOHANG as
(
  select
  dv.crtd_datetime as crtd_datetime_dv,
  dv.branchid,
  dv.ordernbr,
  dv.status as status_dv,
  case when dv.ordernbr = 'DL7-1025-03343' then timestamp('2025-10-30 15:39:11')
  else ifnull(ft.crtd_datetime,dv.delivery_date) end as lupd_datetime_dv
  FROM `spatial-vision-343005.staging.sync_dms_dv` dv
  LEFT JOIN first_time_fail ft on ft.branchid = dv.ordernbr and ft.branchid = dv.branchid
  where dv.delivery_date IS NOT NULL AND dv.status = 'C'
  and date(dv.crtd_datetime) >= date(partition_date)

)

-- select * from NGAYGIAOHANG where ordernbr = 'DL3-0325-02169'
, NGAYCHOTSO as
(
  select
  branchid,
  ordernbr,
  crtd_datetime as crtd_datetime_dv
  FROM `spatial-vision-343005.staging.sync_dms_dv` dv
  where dv.crtd_datetime IS NOT NULL
  and date(crtd_datetime)>= date(partition_date)
  QUALIFY row_number() over (partition by ordernbr,branchid order by crtd_datetime asc ) = 1
)
, NGAYXACNHAN as
(
SELECT branchid, ordernbr, max(lupd_datetime) as time_xac_nhan FROM `spatial-vision-343005.staging.sync_dms_delihistory`
where status = 'A'
and date(crtd_datetime) >= date(partition_date)
group by all
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
    where date(crtd_datetime) >= date(partition_date)
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
      case
      when a.sodondathang in ('CO7-0525-00001','HL0-0425-00144','IR6-0525-00007','IR4-0525-00001') then null
      when a.ma_dh in ('DL7-1025-05108') then timestamp('2025-11-03 08:00:00')
      when a.ma_dh in ('DL6-0825-01073', 'DL6-0825-01071', 'DL6-0825-01074', 'DL6-0825-01076','DL6-1125-01807', 'DL6-1125-01830', 'DL6-1125-01963') then timestamp('2025-11-28 08:00:00')
      when makenhkh = 'EXP' then ngaychungtu
      when (kieudonhang = 'OO' and ngaychungtu>= '2025-12-01') then ngaychungtu
      when kieudonhang in ('CO', 'IR')
      and ngaychungtu>= '2025-06-01'
      and IFNULL(b.lupd_datetime_dv, b2.thoi_gian_xac_nhan_giao_hang) is not null then ngaychungtu
      else IFNULL(b.lupd_datetime_dv, b2.thoi_gian_xac_nhan_giao_hang)
      end as ngaygiaohang_fix,
      case
      when makenhkh = 'EXP' then 'C'
      when kieudonhang in ('CO', 'IR', 'OO') then 'C'
      else b.status_dv
      end as status_dv,
      xn.time_xac_nhan as ngay_xac_nhan_hang,
      case
      when b.lupd_datetime_dv is null
      then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.crtd_datetime,minute)/60,2)
      else round(datetime_diff (b.lupd_datetime_dv,h.crtd_datetime,minute)/60,2)
      end as full_leadtime,
      case
        when b.lupd_datetime_dv is null
        then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),b.crtd_datetime_dv,minute)/60,2)
      else round(datetime_diff (b.lupd_datetime_dv,b.crtd_datetime_dv,minute)/60,2) end as chotso_leadtime,
      case
      when b.lupd_datetime_dv is null
      then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour),h.ApprovalDate,minute)/60,2)
      else round(datetime_diff (b.lupd_datetime_dv,h.ApprovalDate,minute)/60,2)
      end as full_leadtime_duyet,
      i.ltfromcrtd + ifnull(ex.lt_bo_sung,0) as kpi_leadtime,
      ex.lt_bo_sung,
      case
      when a.donvigiaohang_fix in ('Nhà vận chuyển','NVC') then null
      when a.donvigiaohang_fix not in ('Nhà vận chuyển','NVC') and date(lupd_datetime_dv) <= date(appointment_date) then 'Dat'
      when a.donvigiaohang_fix not in ('Nhà vận chuyển','NVC')
      and (
          case when b.lupd_datetime_dv is null
          then round (datetime_diff (TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour), h.crtd_datetime,minute)/60,2)
          else round(datetime_diff (b.lupd_datetime_dv,h.crtd_datetime,minute)/60,2) end
          )
          > (i.ltfromcrtd + ifnull(ex.lt_bo_sung,0) )
      then 'Ko dat'
      else 'Dat' end as danhgia_leadtime,
      case

      when makenhkh = 'EXP' then 'Đã giao hàng'
      when kieudonhang in ('CO', 'IR', 'OO') then 'Đã giao hàng'
      when abs(ds_tong_dh) > 0 and IFNULL(b.lupd_datetime_dv, b2.thoi_gian_xac_nhan_giao_hang) is null
      then 'Chưa giao hàng'
      else 'Đã giao hàng'
      end as trangthaigiaohang,
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
      u4.supid   AS ma_ql_phu_trach_thu_hoi_bbgh,
      u4.tencvbh AS ten_phu_trach_thu_hoi_bbgh,
      u4.tenquanlytt AS ten_ql_phu_trach_thu_hoi_bbgh,
      case when makenhkh in ('TP','PCL') then 'MDS-T (TP-PCL)'
          when makenhkh in ('INS','MT','CLC') THEN 'MDS-T2 (INS-CLC-MT)'
          ELSE 'KHÁC'
      end as phanloai_doanhso_gh,
      u3.tencvbh as ten_nvbh,
      u3.supid_bh as masup_bh,
      u3.tenquanlytt_bh as tensup_bh,
      u3.asm_bh as mamgr_bh,
      u3.tenquanlykhuvuc_bh as tenmgr_bh,
      u3.rsmid as madir_bh,
      u3.tenquanlyvung as tendir_bh,
      u3.role_luong_mds as role_banhang,
      u3.role_luong_mds_phanloai as role_banhang_pl,
      dst.ds_tong_dh,
      dsh.ds_tong_hoa_don

  from DATA_F_SALES_FIXED a
  LEFT JOIN NGAYGIAOHANG b on a.ma_dh = b.ordernbr and a.macongtycn = b.branchid
  LEFT JOIN NGAYCHOTSO b1 on a.ma_dh = b1.ordernbr and a.macongtycn = b1.branchid
  LEFT JOIN `staging.view_d_manual_data_nvc` b2 on b2.ma_dh = a.ma_dh
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_pda_so` h on a.ma_dh = h.ordernbr
  and date(h.crtd_datetime) >= date(partition_date)
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` i on a.makhdms = i.custid
  LEFT JOIN `spatial-vision-343005.staging.d_users` e on a.ma_nvgh_tinhluong = e.manv --**e.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users` f on a.ma_donghang_tinhluong = f.manv --**f.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users` f1 on a.manvdh_bbgh_tinh = f1.manv --**f1.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users` l on l.manv = a.manv_thahang_tinhluong --**l.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users` l1 on l1.manv = a.manv_thahang_tinhluong_c1 --**l1.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users` k1 on a.manv = k1.manv --**k1.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users` u3 on a.manv = u3.manv --**u3.thang = a.thang
  LEFT JOIN `spatial-vision-343005.staging.d_users` u4 on a. manv_phu_trach_thu_hoi_bbgh = u4.manv --**u4.thang = a.thang

  LEFT JOIN `spatial-vision-343005.staging.d_users` u5 on

  IFNULL(a.manv_thahang_tinhluong, a.ma_nvgh_tinhluong ) = u5.manv

  LEFT JOIN suco u on a.ma_dh = u.ordernbr
  LEFT JOIN ds_tong_dh dst on dst.ma_dh = a.ma_dh and dst.macongtycn = a.macongtycn
  LEFT JOIN ds_tong_dh_hoa_don dsh on dsh.ma_dh = a.ma_dh and dsh.macongtycn = a.macongtycn and dsh.hoadon = a.hoadon
  LEFT JOIN staging.d_delivery_appointment_date ad on ad.branchid = a.macongtycn  and ad.ordernbr = a.ma_dh
  LEFT JOIN warehouse.f_extra_leadtime ex on ex.branchid = a.macongtycn  and ex.ordernbr = a.ma_dh
  LEFT JOIN NGAYXACNHAN xn on a.ma_dh = xn.ordernbr and a.macongtycn = xn.branchid
)
, lst_sds as
(
select distinct msnvcsmmoi from `staging.d_hr_dsns` where chucdanhengtitlesum like '%SDS%'
)
, result_0 as
(
SELECT
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
case when
a.kieudonhang in ('IN')
and staging_temp.last_day_of_month(date(ngaychungtu)) IS FALSE
and abs(ds_tong_dh) > 0
and abs(ds_tong_hoa_don) > 0
and a.donvigiaohang_fix not in ('NVC','Nhà vận chuyển')
and a.ma_nvgh_tinhluong not like 'GH%'
then noi_dh_hoa_don
else null
end as madon_tinh_gh_tru_cuoi_thang,
0 as don_tinh_dh,
REGEXP_REPLACE(b.note, r'[\n\r]', ' ') as noidung_giaitrinh,
b.ketqualeadtime_giaitrinh,
ifnull(b.ketqualeadtime_giaitrinh,(case when a.danhgia_leadtime = 'Dat' then 1 else 0 end)) as ketqua_leadtime_tinhluong,
TIMESTAMP_ADD (CURRENT_TIMESTAMP(),INTERVAL 7 hour) as inserted_at,
  case
  when a.kieudonhang in ('IN')
  and abs(ds_tong_dh) > 0
  and abs(ds_tong_hoa_don) > 0
  then noi_dh_hoa_don
  else null
  end as ma_noi_tinh_thu_hoi_bbgh,
    -- END
case when c.msnvcsmmoi is null then 0 else 1 end as is_sds
FROM data_giaohang a
LEFT JOIN `spatial-vision-343005.staging.d_giaitrinhlt_mds` b on a.ma_dh = b.ordernbr
LEFT JOIN lst_sds c on c.msnvcsmmoi = a.ma_nvgh_tinhluong

)

select
*,
case when (
don_tinh_gh = 1 and ifnull(ketqualeadtime_giaitrinh,(case when danhgia_leadtime = 'Dat' then 1 else 0 end)) = 1) then ma_dh else null
end as madon_leadtimedat_tinhluong,
case when don_tinh_gh = 1 and (row_number()over(partition by ma_dh,macongtycn order by masanpham)) = 1 then full_leadtime
      else null end as full_leadtime_1,
case when don_tinh_gh = 1 and (row_number()over(partition by ma_dh,macongtycn order by masanpham)) = 1 then chotso_leadtime
      else null end as chotso_leadtime_1,
case when don_tinh_gh = 1 and (row_number()over(partition by ma_dh,macongtycn order by masanpham)) = 1 then full_leadtime_duyet
      else null end as full_leadtime_duyetdon_1

from result_0
;
COMMIT TRANSACTION;
-- Create or replace table `warehouse.f_baocao_daily_performance_mds_new_v2` copy `sp_f_baocao_daily_performance_mds_new_temp_v2`;
END;
