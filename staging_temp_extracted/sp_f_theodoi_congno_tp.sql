-- ==========================================================================
-- Routine Name : sp_f_theodoi_congno_tp
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-06-29 07:55:59.061000+00:00
-- Last Altered : 2026-06-29 07:55:59.061000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_theodoi_congno_tp()
BEGIN

TRUNCATE TABLE staging_temp.f_theodoi_congno_tp_temp;

INSERT INTO `staging_temp.f_theodoi_congno_tp_temp`

(
-- Create or replace table staging_temp.f_theodoi_congno_tp_temp as
WITH leadtime AS (
  SELECT
    branchid,
    ordernbr,
    custid,
    ngaygiaohang,
    deliveryunit,
    trangthaidon
  FROM
    `warehouse.f_leadtime_new_detail1`
  WHERE
    ngaytaodon >='2026-01-01'
    qualify row_number() over (partition by branchid,ordernbr,custid order by ngaygiaohang desc) =1
    )

  SELECT
    a.BranchID,
    a.slsperid,
    a.DocType,
    a.Ordnbr,
    a.docdesc,
    a.InvcNote,
    a.InvcNbr,
    a.mahd_so,
    a.sotien_nogoc,
    a.sotien_da_thanhtoan,
    a.so_du_chungtu,
    a.dateoforder,
    a.duedate,
    a.orderdate,
    a.so_du_dh,
    a.day_terms,
    a.terms,
    a.is_diadiem,
    a.paymentsform_goc,
    a.paymentsform,
    a.refcustid,
    a.ten_nvgh,
    a.thoi_diem_no_vang,
    a.thoi_diem_no_do,
    a.thoi_diem_no_den,
    a.phanloaino,
    a.phong_phu_trach_no,
    a.ma_nv_phu_trach_no,
    a.nv_phu_trach_no,
    a.thoigian_noqh,
    b.ma_khach_hang_dms AS custid,
    d.custname,
    d.statedescr AS tinh,
    d.territorydescr AS khuvuc,
    d.shortterritorydescr,
    d.channel,
    d.shoptype,
    e.ngaygiaohang,
    e.deliveryunit,
    e.trangthaidon,
    l.col.ma_nvbh as ma_crs,
    g.tencvbh,
    g.supid as ma_crm,
    g.tenquanlytt,
    g.asm as ma_scrm,
    g.tenquanlykhuvuc,
    g.rsmid as ma_ncxm,
    g.tenquanlyvung,
    CASE
      WHEN DATE_TRUNC(a.dateoforder,month) = DATE_TRUNC(CURRENT_DATETIME("+7"),month) THEN 'Y'
    ELSE
    'N'
  END
    AS is_current_month,
    cast(current_datetime("+7") as timestamp) as updated_at
  FROM
    `staging.d_dskh_theo_doi_cong_no_tp` b
  LEFT JOIN
    `warehouse.f_congno_tp_mt` a
  ON
    a.custid = b.ma_khach_hang_dms
  LEFT JOIN
    `staging.d_master_khachhang` d
  ON
    d.custid = b.ma_khach_hang_dms
  LEFT JOIN
    leadtime e
  ON
    e.custid =a.custid
    AND e.branchid =a.BranchID
    AND e.ordernbr =a.Ordnbr
  LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a.custid
  LEFT JOIN `staging.d_users` g on l.col.ma_nvbh =g.manv
  );

Create or replace table `warehouse.f_theodoi_congno_tp`

copy `staging_temp.f_theodoi_congno_tp_temp`;
END;
