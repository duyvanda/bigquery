-- ==========================================================================
-- Routine Name : sp_d_rawdata_debt
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-07-23 15:13:47.074000+00:00
-- Last Altered : 2026-07-23 15:13:47.074000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_d_rawdata_debt()
BEGIN

/*
  Xem logic phức tạp: https://docs.google.com/spreadsheets/d/1JsrMK_Fcl-FM1gIRN5IiETUb9L-n_u1jDg9azkcV46k
*/

-- TRUNCATE TABLE `staging_temp.d_rawdata_debt_temp`;
-- INSERT INTO `staging_temp.d_rawdata_debt_temp`
CREATE TEMP TABLE `d_rawdata_debt_temp` PARTITION BY dateoforder AS

(

WITH
  payment_mt AS (
    SELECT
      branchid,
      ordernbr,
      paymentmethod
    FROM
      `spatial-vision-343005.staging.sync_dms_delihistoryc`
    QUALIFY
      ROW_NUMBER() OVER (
        PARTITION BY
          branchid,
          ordernbr
        ORDER BY
          lupd_datetime DESC
      ) = 1
  ),
  debtdet AS (
    SELECT
      *
    FROM
      (
        SELECT
          BranchID,
          ARBatNbr,
          CustID,
          slsperid,
          ROW_NUMBER() OVER (
            PARTITION BY
              BranchID,
              ARBatNbr,
              CustID
            ORDER BY
              crtd_datetime DESC
          ) AS loc
        FROM
          `staging.sync_dms_debtdet`
      )
    WHERE
      loc = 1
  ),
  ib AS (
    WITH
      ib_loc AS (
        SELECT
          branchid,
          batnbr,
          MAX(crtd_datetime) AS max_crtd_datetime
        FROM
          `staging.sync_dms_ib`
        GROUP BY
          1,
          2
      )
    SELECT
      a.branchid,
      a.batnbr,
      a.slsperid
    FROM
      `staging.sync_dms_ib` AS a
      JOIN ib_loc AS b ON b.branchid = a.branchid
      AND a.batnbr = b.batnbr
      AND a.crtd_datetime = b.max_crtd_datetime
  ),
  ibd AS (
    WITH
      ibd_loc AS (
        SELECT
          branchid,
          ordernbr,
          MAX(crtd_datetime) AS max_crtd_datetime
        FROM
          `staging.sync_dms_ibd`
        GROUP BY
          1,
          2
      )
    SELECT
      a.branchid,
      a.ordernbr,
      a.batnbr
    FROM
      `staging.sync_dms_ibd` AS a
      JOIN ibd_loc AS b ON b.branchid = a.branchid
      AND b.ordernbr = a.ordernbr
      AND b.max_crtd_datetime = a.crtd_datetime
  ),
  batch AS (
    WITH
      batch_loc AS (
        SELECT
          BatNbr,
          BranchID,
          Rlsed,
          Module,
          Status,
          ROW_NUMBER() OVER (
            PARTITION BY
              BatNbr,
              BranchID
            ORDER BY
              crtd_datetime DESC
          ) AS loc
        FROM
          `spatial-vision-343005.staging.sync_dms_batch`
        WHERE
          true
          AND Module = 'AR'
      )
    SELECT
      *
    FROM
      batch_loc
    WHERE
      loc = 1
  ),
  goi_dau_30ngay AS (
    WITH
      data_goi_1_dh AS (
          SELECT DISTINCT
          a.branchid,
          a.custid,
          IFNULL(a.origordernbr, a.ordernbr) AS ordernbr,
          DATE(a.orderdate) AS dateoforder
        FROM
          `spatial-vision-343005.staging.sync_dms_so` AS a
        LEFT JOIN `spatial-vision-343005.staging.sync_dms_so` AS c
          ON c.invcnbr = a.invcnbr
          AND c.branchid = a.branchid
          AND IFNULL(a.invcnote, '') = IFNULL(c.invcnote, '')
          AND a.custid = c.custid
          AND c.ordertype IN ('CO', 'HK') AND c.status = 'C'
        INNER JOIN `spatial-vision-343005.staging.sync_dms_ardoc` AS ar
          ON ar.ordnbr = IFNULL(a.origordernbr, a.ordernbr)
          AND ar.branchid = a.branchid
        INNER JOIN `spatial-vision-343005.staging.d_manual_terms_detail` AS term
          ON term.termsid = ar.terms
        WHERE
          a.status = 'C'
          AND a.ordertype IN ('IN', 'IO', 'EP', 'NP')
          AND c.invcnbr IS NULL
          AND term.descr = 'Gối 1 Đơn Hàng (trong 30 ngày)'
      )
      ,
      khoangcach_dh AS (
        SELECT
          a.*,
          DATE_DIFF(
            a.dateoforder,
            MAX(a.dateoforder) OVER (
              PARTITION BY
                a.custid
              ORDER BY
                a.dateoforder ASC ROWS BETWEEN UNBOUNDED PRECEDING
                AND 1 PRECEDING
            ),
            DAY
          ) AS khoangcachdonhang
        FROM
          data_goi_1_dh AS a
      ),
      khoangcach_dh1 AS (
        SELECT
          a.*,
          CASE
          /*WHEN a.khoangcachdonhang IN (0, 1, 2) sửa lại liên tiếp là cùng ngày được rồi*/
            WHEN a.khoangcachdonhang IN (0) THEN 0
            ELSE 1
          END AS lientiep_01
        FROM
          khoangcach_dh AS a
      ),
      group_khoangcach_dh AS (
        SELECT
          *,
          SUM(lientiep_01) OVER (
            PARTITION BY
              custid
            ORDER BY
              custid ASC,
              dateoforder ASC ROWS UNBOUNDED PRECEDING
          ) AS groupa
        FROM
          khoangcach_dh1
      ),
      cte_ngaytoihan AS (
        SELECT
          custid,
          groupa,
          MIN(dateoforder) AS ngaytoihan
        FROM
          group_khoangcach_dh
        WHERE
          khoangcachdonhang < 30
        GROUP BY
          custid,
          groupa
        ORDER BY
          groupa
      ),
      mapping_ngaytoihan AS (
        SELECT
          c.*,
          'N' AS is_kh_88pcl,
          CASE
            WHEN b.ngaytoihan IS NOT NULL THEN b.ngaytoihan
            ELSE DATE(DATE_ADD(c.dateoforder, INTERVAL 30 DAY))
          END AS ngaytoihan
        FROM
          group_khoangcach_dh AS c
          LEFT JOIN cte_ngaytoihan AS b ON c.custid = b.custid
          AND c.groupa = b.groupa - 1
          -- LEFT JOIN
          --   `staging.d_manual_ds_kh_theodoi_pcl` AS d
          --   ON d.makh = c.custid
      )
    SELECT
      * EXCEPT (ngaytoihan),
      CASE
        WHEN DATE_TRUNC(ngaytoihan, MONTH) <> DATE_TRUNC(dateoforder, MONTH)
        AND is_kh_88pcl = 'Y' THEN DATE(
          DATE_ADD(DATE_TRUNC(dateoforder, MONTH), INTERVAL 1 MONTH) - INTERVAL 1 DAY
        )
        ELSE ngaytoihan
      END AS ngaytoihan
    FROM
      mapping_ngaytoihan
  )
  /*
  Đơn DM: Ví dụ Khách hàng có 2 mã KH nội bộ (cùng mã số thuế), chiết khấu thuộc mã KH nội bộ P3103-0148, nhưng KH muốn cấn trừ vào đơn nợ của mã KH TN90E063 -> nên chị làm bút toán này để thay đổi mã KH nội bộ để cấn trừ cho KH.
  */
  --Lấy thanh toán công nợ
,
  thanhtoan_congno_ori AS (
    SELECT
      a.BranchID,
      AdjdBatNbr,
      AdjdRefNbr,
      MAX(adjgdocdate) AS adjgdocdate,
      SUM(AdjAmt) AS AdjAmt
    FROM
      `staging.sync_dms_adjust` AS a
      INNER JOIN batch AS b ON a.BranchID = b.BranchID
      AND a.BatNbr = b.BatNbr
      AND b.Module = 'AR'
    WHERE
      IFNULL(a.Reversal, '') = ''
      AND b.Rlsed = 1
      AND DATE(a.AdjgDocDate) <= (
        SELECT
          *
        FROM
          `staging.d_current_table`
      )
    GROUP BY
      a.BranchID,
      AdjdBatNbr,
      AdjdRefNbr
  ),
  thanhtoan_congno_mapping AS (
    SELECT
      *
    FROM
      thanhtoan_congno_ori
      -- UNION ALL
      -- SELECT
      --   *
      -- FROM
      --   thanhtoan_congno_kt
  )
  /*Dành cho đơn IN, DM. Ghi nợ*/
,
  thanhtoan_congno AS (
    SELECT
      BranchID,
      AdjdBatNbr,
      AdjdRefNbr,
      MAX(adjgdocdate) AS adjgdocdate,
      SUM(AdjAmt) AS AdjAmt
    FROM
      thanhtoan_congno_mapping
    GROUP BY
      1,
      2,
      3
  ),
  /*Dành cho đơn trả hàng CM, PP. Ghi có (clear nợ) */
  cantru_congno AS (
    SELECT
      a.BranchID,
      AdjgBatNbr,
      AdjgRefNbr,
      MAX(adjgdocdate) AS adjgdocdate,
      SUM(AdjAmt * -1) AS AdjAmt
    FROM
      `staging.sync_dms_adjust` AS a
      INNER JOIN batch AS b ON a.BranchID = b.BranchID
      AND a.BatNbr = b.BatNbr
      AND b.Module = 'AR'
    WHERE
      IFNULL(a.Reversal, '') = ''
      AND b.Rlsed = 1
      AND DATE(a.AdjgDocDate) <= (
        SELECT
          *
        FROM
          `staging.d_current_table`
      )
    GROUP BY
      a.BranchID,
      AdjgBatNbr,
      AdjgRefNbr
  )
  /*Dành cho các CT chiết khấu, tích lũy, ghi có*/
,
  hoan_ung AS (
    SELECT
      a.BranchID,
      AdjdBatNbr,
      AdjdRefNbr,
      MAX(adjgdocdate) AS adjgdocdate,
      SUM(AdjAmt * -1) AS AdjAmt
    FROM
      `staging.sync_dms_adjust` AS a
      INNER JOIN batch AS b ON a.BranchID = b.BranchID
      AND a.BatNbr = b.BatNbr
      AND b.Module = 'AR'
    WHERE
      IFNULL(a.Reversal, '') = ''
      AND b.Rlsed = 1
      AND DATE(a.AdjgDocDate) <= (
        SELECT
          *
        FROM
          `staging.d_current_table`
      )
    GROUP BY
      a.BranchID,
      AdjdBatNbr,
      AdjdRefNbr
  ),
  mapping_thanhtoan_congno AS (
    SELECT
      IFNULL(deb.SlsperID, d.SlsperId) AS SlsperId,
      d.BranchID,
      d.CustId,
      d.BatNbr,
      d.DocType,
      d.DocDate,
      aj.adjgdocdate AS adjgdocdate,
      d.OrdNbr,
      d.docdesc,
      d.InvcNote,
      d.InvcNbr,
      d.OrigDocAmt,
      IFNULL(aj.adjamt, 0) AS AdjAmt,
      0 AS remain,
      d.DueDate,
      '' AS OrigOrderNbr,
      d.Terms,
      d.inserted_at AS Crtd_DateTime
    FROM
      `staging.sync_dms_ardoc` AS d
      INNER JOIN batch AS b ON d.BranchID = b.BranchID
      AND d.BatNbr = b.BatNbr
      AND b.Module = 'AR'
      LEFT JOIN thanhtoan_congno AS aj ON aj.BranchID = d.BranchID
      AND aj.AdjdBatNbr = d.BatNbr
      AND d.RefNbr = aj.AdjdRefNbr
      LEFT JOIN debtdet AS deb ON deb.BranchID = d.BranchID
      AND deb.ARBatNbr = d.BatNbr
      AND deb.CustID = d.CustId
    WHERE
      d.DocType IN ('DM', 'IN')
      AND d.Rlsed = 1
      AND DATE(d.DocDate) <= (
        SELECT
          *
        FROM
          `staging.d_current_table`
      )
  ),
  mapping_cantru_congno AS (
    SELECT
      IFNULL(deb.SlsperID, d.SlsperId) AS SlsperId,
      d.BranchID,
      d.CustId,
      d.BatNbr,
      d.DocType,
      d.DocDate,
      aj.adjgdocdate,
      d.OrdNbr,
      d.docdesc,
      d.InvcNote,
      d.InvcNbr,
      -1 * OrigDocAmt AS OrigDocAmt,
      IFNULL(aj.adjamt, 0) AS AdjAmt,
      0 AS remain,
      d.DueDate,
      '' AS OrigOrderNbr,
      d.Terms,
      d.inserted_at AS Crtd_DateTime
    FROM
      `staging.sync_dms_ardoc` AS d
      INNER JOIN batch AS b ON d.BranchID = b.BranchID
      AND d.BatNbr = b.BatNbr
      AND b.Module = 'AR'
      LEFT JOIN cantru_congno AS aj ON aj.BranchID = d.BranchID
      AND aj.AdjgBatNbr = d.BatNbr
      AND aj.AdjgRefNbr = d.RefNbr
      LEFT JOIN debtdet AS deb ON deb.BranchID = d.BranchID
      AND deb.ARBatNbr = d.BatNbr
      AND deb.CustID = d.CustId
    WHERE
      d.DocType IN ('CM', 'PP')
      AND d.Rlsed = 1
      AND b.Status = 'C'
      AND DATE(d.docdate) <= (
        SELECT
          *
        FROM
          `staging.d_current_table`
      )
  ),
  mapping_hoan_ung AS (
    SELECT
      IFNULL(deb.SlsperID, d.SlsperId) AS SlsperId,
      d.BranchID,
      d.CustId,
      d.BatNbr,
      d.DocType,
      d.DocDate,
      aj.adjgdocdate,
      d.OrdNbr,
      d.docdesc,
      d.InvcNote,
      d.InvcNbr,
      0 AS OrigDocAmt,
      IFNULL(aj.adjamt, 0) AS AdjAmt,
      0 AS remain,
      d.DueDate,
      '' AS OrigOrderNbr,
      d.Terms,
      d.inserted_at AS Crtd_DateTime
    FROM
      `staging.sync_dms_ardoc` AS d
      INNER JOIN hoan_ung AS aj ON aj.BranchID = d.BranchID
      AND aj.AdjdBatNbr = d.BatNbr
      AND d.RefNbr = aj.AdjdRefNbr
      LEFT JOIN debtdet AS deb ON deb.BranchID = d.BranchID
      AND deb.ARBatNbr = d.BatNbr
      AND deb.CustID = d.CustId
    WHERE
      d.DocType IN ('CM', 'PP')
      AND d.Rlsed = 1
      AND DATE(d.DocDate) <= (
        SELECT
          *
        FROM
          `staging.d_current_table`
      )
  ),
  union_all_hoadon AS (
    SELECT
      *
    FROM
      mapping_thanhtoan_congno
    UNION ALL
    SELECT
      *
    FROM
      mapping_cantru_congno
    UNION ALL
    SELECT
      *
    FROM
      mapping_hoan_ung
  ),
  result AS (
    SELECT
      ib.slsperid AS slsperid,
      p.BranchID,
      p.CustId,
      p.DocType,
      IFNULL(o.orderdate, p.DocDate) AS DocDate,
      IFNULL(
        o.OrigOrderNbr,
        IFNULL(o.ordernbr, IFNULL(ht.SoDonHang, ''))
      ) AS Ordnbr,
      o.paymentsform,
      CASE
        WHEN IFNULL(o.Ordernbr, '') = 'IR102021-00011'
        AND p.InvcNbr = '0010026' THEN 'Dung dịch vệ sinh mũi nước biển sâu nước biển sâu Xisat người lớn (75 ml), Việt Nam, (1chai/hộp)'
        ELSE p.docdesc
      END AS docdesc,
      p.InvcNote,
      p.InvcNbr,
      CASE
        WHEN p.terms = 'O1' THEN DATE_ADD(p.docdate, INTERVAL 30 DAY)
        ELSE p.duedate
      END AS duedate,
      p.Terms,
      CASE
        WHEN IFNULL(o.Ordernbr, '') = 'IR102021-00011'
        AND p.InvcNbr = '0010026' THEN 'IR102021-00010'
        ELSE IFNULL(o.Ordernbr, '')
      END AS mahd_so,
      cast(o.contractid as int) as contractid,
      MAX(p.adjgdocdate) AS adjgdocdate,
      SUM(OrigdocAmt) AS sotien_nogoc,
      SUM(AdjAmt) AS sotien_da_thanhtoan,
      SUM(OrigdocAmt) - SUM(AdjAmt) AS so_du_chungtu
    FROM
      union_all_hoadon AS p
      LEFT JOIN `staging.sync_ar_chuyencongno_cnoff_sangcnhientai` AS ht ON ht.NewBranchID = p.BranchID
      AND ht.NewBatnbr = p.BatNbr
      LEFT JOIN `staging.sync_dms_so` AS o ON o.BranchID = IFNULL(ht.macongtycn, p.BranchID)
      AND o.Ordernbr = p.Ordnbr
      LEFT JOIN `staging.sync_dms_pda_so` AS a ON o.BranchID = a.BranchID
      AND o.OrigOrderNbr = a.OrderNbr
      LEFT JOIN ibd AS ibe ON ibe.BranchID = a.BranchID
      AND ibe.OrderNbr = a.OrderNbr
      LEFT JOIN ib ON ibe.BranchID = ib.BranchID
      AND ibe.BatNbr = ib.BatNbr
    GROUP BY
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14
  )
  /*
  -- hóa đơn 00012710 bị thay bởi 00017543, ardoc mất hóa đơn 00012710
  --select top 100 OrigOrderNbr, SalesOrderType,* from OM_SalesOrd where InvcNbr = '00012710' and BranchID = 'HCM001'
  --select top 100 OrigOrderNbr, SalesOrderType,* from OM_SalesOrd where InvcNbr = '00017543' and BranchID = 'HCM001'
  --select top 100 * from AR_Doc where InvcNbr = '00012710' and BranchID = 'HCM001'
  --select top 100 * from AR_Doc where InvcNbr = '00017543' and BranchID = 'HCM001'
  */
,
  adjust_invcnbr as (
    select DISTINCT
      so.origordernbr,
      so.InvcNbr as ori_invcnbr,
      d.InvcNbr as adjust_invcnbr
    from
      `staging.sync_dms_so` so
      LEFT JOIN `staging.sync_dms_ardoc` d on d.BranchID = so.BranchID
      and so.ARBatNbr = d.Batnbr
    WHERE
      so.OrderDate >= '2025-07-01'
      and d.crtd_datetime >= '2025-07-01'
      and so.InvcNbr != d.InvcNbr
  ),
  mapping_customer AS (
    SELECT
      a.* EXCEPT (adjgdocdate, DocDate, duedate, contractid),
      DATE(a.DocDate) AS dateoforder,
      IFNULL(DATE(gd.ngaytoihan), DATE(duedate)) AS duedate,
      DATE(a.adjgdocdate) AS orderdate, -- ngày thanh toán
      SUM(so_du_chungtu) OVER (PARTITION BY a.custid, a.ordnbr, a.branchid, a.invcnbr, a.docdesc) AS so_du_dh,
      d.paymentmethod AS paymentmethod_deli,
      e.appointment_date AS debt_appointment_date,
      f.appointment_date AS deli_appointment_date,
      (
        SELECT
          MAX(inserted_at)
        FROM
          `staging.sync_dms_ardoc`
        WHERE
          inserted_at IS NOT NULL
      ) AS inserted_at,
      IFNULL(ad.ori_invcnbr, a.invcnbr) as ori_invcnbr,
      -- 2. Đẩy cột contractid xuống dưới cùng ở đây để khớp với bảng đích
      a.contractid
    FROM
      result AS a
      LEFT JOIN goi_dau_30ngay AS gd ON a.custid = gd.custid
      AND a.ordnbr = gd.ordernbr
      AND a.branchid = gd.branchid
      AND a.terms = 'O1'
      LEFT JOIN payment_mt AS d ON a.ordnbr = d.ordernbr
      AND a.branchid = d.branchid
      LEFT JOIN `staging.d_debt_appointment_date` AS e ON a.ordnbr = e.ordernbr
      AND a.branchid = e.branchid
      LEFT JOIN `staging.d_delivery_appointment_date` AS f ON a.ordnbr = f.ordernbr
      AND a.branchid = f.branchid
      LEFT JOIN adjust_invcnbr ad on ad.origordernbr = a.Ordnbr
      and ad.adjust_invcnbr = a.invcnbr
      and dateoforder >= '2025-07-01'
  ),
  mapping_customer_info AS (
    SELECT
      a.*,
      b1.channel AS channel,
      b1.shoptype AS shoptype,
      b1.statedescr AS statedescr,
      b1.districtdescr,
      b1.wardname,
      b1.custname AS custname,
      b1.paymentsform AS paymentsform_hien_tai,
      b1.refcustid AS refcustid,
      b1.shortterritorydescr AS territorydescr,
      b1.pubcustid,
      b1.pubcustname,
      b1.hcoid,
      b1.hcotypeid,
      e.dueintnv AS day_terms,
      CASE
        WHEN f.makh IS NOT NULL
        AND e.descr = 'Gối 1 Đơn Hàng (trong 30 ngày)' THEN 'Gối 1 Đơn Hàng (cuối tháng)'
        ELSE e.descr
      END AS terms_name,
      CASE
        WHEN b1.statedescr IN (
          'Thành phố Hồ Chí Minh',
          'Thành phố Đà Nẵng',
          'Hưng Yên'
        ) THEN 'VP chi nhánh'
        ELSE 'Tỉnh'
      END AS is_diadiem
    FROM
      mapping_customer a
      LEFT JOIN `staging.d_master_khachhang` b1 ON a.custid = b1.custid
      LEFT JOIN `staging.d_manual_terms_detail` e ON e.termsid = a.Terms
      LEFT JOIN `staging.d_manual_ds_kh_theodoi_pcl` f ON f.makh = a.custid
  ),
  mapping_phanloai_udf AS (
    SELECT
      *,
      `staging_temp.fn_phan_loai_no` (
        terms_name,
        is_diadiem,
        duedate,
        day_terms,
        so_du_dh,
        orderdate,
        dateoforder,
        so_du_chungtu
      ) AS no_info
    FROM
      mapping_customer_info
  ),
  phanloai_nokh AS (
    SELECT
      * EXCEPT (no_info),
      no_info.thoi_diem_no_vang,
      no_info.thoi_diem_no_do,
      no_info.thoi_diem_no_den,
      no_info.phan_loai_no,
      no_info.thang_chung_tu,
      no_info.thang_thu,
      no_info.no_xanh,
      no_info.no_vang,
      no_info.no_do,
      no_info.no_den,
      no_info.no_xau,
      (no_info.no_vang + no_info.no_do + no_info.no_den) AS no_qua_han,
      no_info.vung_no_kh,
      no_info.thoigian_no,
      no_info.thoigian_noqh,
      no_info.thoigian_noxau
    FROM
      mapping_phanloai_udf
  ),
  vungnokh AS (
    SELECT
      custid,
      MAX(vung_no_kh) AS phan_loai_vung_no
    FROM
      phanloai_nokh
    WHERE
      doctype <> 'CM'
    GROUP BY
      custid
  ),
  mapping_all AS (
    SELECT
      a.*,
      b.phan_loai_vung_no,
      CASE
        WHEN a.branchid IN (
          'NAN012',
          'KHA014',
          'HYN017',
          'HNI010',
          'HCM001',
          'DNI015',
          'DNG013',
          'CTO016'
        ) THEN 'MERAP'
        WHEN a.branchid = 'PHA NAM' THEN 'PHA NAM'
        WHEN a.branchid = 'MERAP' THEN 'MERAP'
        ELSE 'PHA NAM'
      END AS phap_nhan,
      c.col.ma_nvbh AS manv,
      c.tencvbh,
      CASE
        WHEN LOWER(a.custname) LIKE '%gonsa%'
        OR LOWER(a.custname) LIKE '%tây âu%' THEN 'MR1137'
        ELSE COALESCE(hr_crm.msnvcsmmoi, c.supid, 'MR1137')
      END AS macrm,
      CASE
        WHEN LOWER(a.custname) LIKE '%gonsa%'
        OR LOWER(a.custname) LIKE '%tây âu%' THEN 'Vũ Mừng'
        ELSE COALESCE(g.crm, c.tenquanlytt, 'Vũ Mừng')
      END AS tenquanlytt,
      d.bbnt08,
      d.thanh_ly_dac_biet,
      e_tinh.ma_nv_phu_trach_chung_tu AS ma_nv_phu_trach_chung_tu_hcp,
      e_tinh.ten_nv_phu_trach_chung_tu AS ten_nv_phu_trach_chung_tu,
      ct.contractnbr,
      ct.noticenbr
    FROM
      phanloai_nokh a
      LEFT JOIN vungnokh b ON a.custid = b.custid
      LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` c ON c.custid = a.custid
      LEFT JOIN `spatial-vision-343005.staging.d_manual_dia_ban_cong_no_hcp` g ON g.ma_kh = a.custid
      LEFT JOIN (
        SELECT
          msnvcsmmoi,
          hovatenfullname
        FROM
          `spatial-vision-343005.staging.d_hr_dsns`
        WHERE
          phongdeptsummary = 'HCP'
      ) hr_crm ON hr_crm.hovatenfullname = g.crm
      LEFT JOIN `spatial-vision-343005.staging.d_manual_bien_ban_nghiem_thu_hcp_2026` d ON d.so_don_dat_hang = a.ordnbr
      AND d.so_hoa_don = a.InvcNbr
      LEFT JOIN `staging.d_oricontract` ct ON ct.contractid = a.contractid
      LEFT JOIN `staging.d_tinh` e_tinh ON a.statedescr = e_tinh.tinh
  )
SELECT
  *
FROM
  mapping_all

);

Create or replace table `staging_temp.d_rawdata_debt`

copy `d_rawdata_debt_temp`;
END;
