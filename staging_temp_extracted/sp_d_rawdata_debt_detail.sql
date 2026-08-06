-- ==========================================================================
-- Routine Name : sp_d_rawdata_debt_detail
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-06-22 08:49:32.751000+00:00
-- Last Altered : 2026-06-22 08:49:32.751000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_d_rawdata_debt_detail()
BEGIN

/*
Mục đích: Giữ lại chi tiết từng mốc thời gian phát sinh giao dịch (thanh toán/cấn trừ) cho cùng một chứng từ.

Kết quả: Nếu một hóa đơn được thanh toán làm nhiều lần vào các ngày khác nhau, bảng này sẽ đẻ ra nhiều dòng cho hóa đơn đó (mỗi dòng tương ứng với một mốc adjgdocdate).

Ví dụ:
SELECT *  FROM `spatial-vision-343005.staging_temp.d_rawdata_debt_detail`
where Ordnbr = 'DL7-0625-03533' order by orderdate asc

*/

TRUNCATE TABLE `staging_temp.d_rawdata_debt_detail_temp`;

INSERT INTO `staging_temp.d_rawdata_debt_detail_temp`
(
    -- Create or replace table `staging_temp.d_rawdata_debt_detail_temp`
    -- partition by orderdate
    -- cluster by ordnbr,custid,dateoforder,invcnbr
    -- as
    WITH debtdet AS (
        SELECT * FROM (
            SELECT
                BranchID,
                ARBatNbr,
                CustID,
                slsperid,
                ROW_NUMBER() OVER (
                    PARTITION BY BranchID, ARBatNbr, CustID
                    ORDER BY crtd_datetime DESC
                ) AS loc
            FROM `staging.sync_dms_debtdet`
        )
        WHERE loc = 1
    ),
    -- Data thêm vào ngày 8/7 bị duplicate
    ib AS (
        WITH ib_loc AS (
            SELECT
                branchid,
                batnbr,
                MAX(crtd_datetime) AS max_crtd_datetime
            FROM `staging.sync_dms_ib`
            GROUP BY 1, 2
        )
        SELECT
            a.branchid,
            a.batnbr,
            a.slsperid
        FROM `staging.sync_dms_ib` a
        INNER JOIN ib_loc b
            ON b.branchid = a.branchid
            AND a.batnbr = b.batnbr
            AND a.crtd_datetime = b.max_crtd_datetime
    ),
    ibd AS (
        WITH ibd_loc AS (
            SELECT
                branchid,
                ordernbr,
                MAX(crtd_datetime) AS max_crtd_datetime
            FROM `staging.sync_dms_ibd`
            GROUP BY 1, 2
        )
        SELECT
            a.branchid,
            a.ordernbr,
            a.batnbr
        FROM `staging.sync_dms_ibd` a
        INNER JOIN ibd_loc b
            ON b.branchid = a.branchid
            AND b.ordernbr = a.ordernbr
            AND b.max_crtd_datetime = a.crtd_datetime
    ),
    batch AS (
        WITH batch_loc AS (
            SELECT
                BatNbr,
                BranchID,
                Rlsed,
                Module,
                Status,
                ROW_NUMBER() OVER (
                    PARTITION BY BatNbr, BranchID
                    ORDER BY crtd_datetime DESC
                ) AS loc
            FROM `spatial-vision-343005.staging.sync_dms_batch`
            WHERE Rlsed = 1
              AND Module = 'AR'
        )
        SELECT * FROM batch_loc
        WHERE loc = 1
    ),
    goi_dau_30ngay AS (
        WITH data_goi_1_dh AS (
            SELECT DISTINCT
                branchid,
                custid,
                ordernbr,
                DATE(ngayphathanhhd) AS dateoforder
            FROM `spatial-vision-343005.warehouse.f_leadtime_new_detail1`
            WHERE status_so = 'Đã phát hành'
              AND ordernbr_co = 'Không hủy HĐ'
              AND terms = 'Gối 1 Đơn Hàng (trong 30 ngày)'
              -- AND a.custid = 'P2308-0345'
        ),
        khoangcach_dh AS (
            SELECT
                a.*,
                DATE_DIFF(
                    a.dateoforder,
                    MAX(a.dateoforder) OVER (
                        PARTITION BY a.custid
                        ORDER BY a.dateoforder ASC
                        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
                    ),
                    DAY
                ) AS khoangcachdonhang
            FROM data_goi_1_dh a
        ),
        khoangcach_dh1 AS (
            SELECT
                a.*,
                CASE
                    WHEN a.khoangcachdonhang IN (0) THEN 0
                    ELSE 1
                END AS lientiep_01
            FROM khoangcach_dh a
        ),
        group_khoangcach_dh AS (
            SELECT
                *,
                SUM(lientiep_01) OVER (
                    PARTITION BY custid
                    ORDER BY custid ASC, dateoforder ASC
                    ROWS UNBOUNDED PRECEDING
                ) AS groupa
            FROM khoangcach_dh1
        ),
        ngaytoihan AS (
            SELECT
                custid,
                groupa,
                MIN(dateoforder) AS ngaytoihan
            FROM group_khoangcach_dh
            WHERE khoangcachdonhang < 30
            GROUP BY 1, 2
            ORDER BY groupa
        ),
        mapping_ngaytoihan AS (
            SELECT
                c.*,
                CASE
                    WHEN d.makh IS NOT NULL THEN 'Y'
                    ELSE 'N'
                END AS is_kh_88pcl,
                CASE
                    WHEN b.ngaytoihan IS NOT NULL THEN b.ngaytoihan
                    WHEN d.makh IS NOT NULL AND b.ngaytoihan IS NULL
                        THEN DATE(DATE_ADD(DATE_TRUNC(c.dateoforder, MONTH), INTERVAL 1 MONTH) - INTERVAL 1 DAY)
                    ELSE DATE(DATE_ADD(c.dateoforder, INTERVAL 30 DAY))
                END AS ngaytoihan
            FROM group_khoangcach_dh c
            LEFT JOIN ngaytoihan b
                ON c.custid = b.custid
                AND c.groupa = b.groupa - 1
            LEFT JOIN `staging.d_manual_ds_kh_theodoi_pcl` d
                ON d.makh = c.custid
            -- WHERE c.custid = 'P2412-0153'
        )
        SELECT
            * EXCEPT(ngaytoihan),
            CASE
                WHEN DATE_TRUNC(ngaytoihan, MONTH) <> DATE_TRUNC(dateoforder, MONTH)
                  AND is_kh_88pcl = 'Y'
                    THEN DATE(DATE_ADD(DATE_TRUNC(dateoforder, MONTH), INTERVAL 1 MONTH) - INTERVAL 1 DAY)
                ELSE ngaytoihan
            END AS ngaytoihan
        FROM mapping_ngaytoihan
    ),
    -------------------------------------------------------------*Lấy công nợ*-----------------------------------------------------------------------
    -- Fix lỗi data từ ngày 8/7
    -- thanhtoan_congno_kt AS (
    --     SELECT
    --         a.BranchID,
    --         AdjdBatNbr,
    --         AdjdRefNbr,
    --         adjgdocdate,
    --         SUM(AdjAmt) AS AdjAmt
    --     FROM `staging.sync_dms_adjust_kt` a
    --     WHERE DATE(a.AdjgDocDate) <= (SELECT * FROM `staging.d_current_table`)
    --     GROUP BY
    --         a.BranchID,
    --         AdjdBatNbr,
    --         AdjdRefNbr,
    --         4
    -- ),
    -- Lấy thanh toán công nợ
    thanhtoan_congno_ori AS (
        SELECT
            a.BranchID,
            AdjdBatNbr,
            AdjdRefNbr,
            -- MAX(adjgdocdate) AS
            adjgdocdate,
            SUM(AdjAmt) AS AdjAmt
        FROM `staging.sync_dms_adjust` a
        INNER JOIN batch b
            ON a.BranchID = b.BranchID
            AND a.BatNbr = b.BatNbr
            AND b.Module = 'AR'
        WHERE IFNULL(a.Reversal, '') = ''
          AND b.Rlsed = 1 -- Bảng batch thiếu trường này
          AND DATE(a.AdjgDocDate) <= (SELECT * FROM `staging.d_current_table`)
        GROUP BY
            a.BranchID,
            AdjdBatNbr,
            AdjdRefNbr,
            4
    ),
    thanhtoan_congno AS (
        SELECT * FROM thanhtoan_congno_ori
        -- UNION ALL
        -- SELECT * FROM thanhtoan_congno_kt
    ),
    ---------------- Lấy Cấn Trừ Công Nợ
    cantru_congno AS (
        SELECT
            a.BranchID,
            AdjgBatNbr,
            AdjgRefNbr,
            -- MAX(adjgdocdate) AS
            adjgdocdate,
            SUM(AdjAmt * -1) AS AdjAmt
        FROM `staging.sync_dms_adjust` a
        INNER JOIN batch b
            ON a.BranchID = b.BranchID
            AND a.BatNbr = b.BatNbr
            AND b.Module = 'AR'
        WHERE IFNULL(a.Reversal, '') = ''
          AND b.Rlsed = 1
          AND DATE(a.AdjgDocDate) <= (SELECT * FROM `staging.d_current_table`)
        GROUP BY
            a.BranchID,
            AdjgBatNbr,
            AdjgRefNbr,
            4
    ),
    ------------------------ Hoàn Ứng
    hoan_ung AS (
        SELECT
            a.BranchID,
            AdjdBatNbr,
            AdjdRefNbr,
            adjgdocdate,
            SUM(AdjAmt * -1) AS AdjAmt
        FROM `staging.sync_dms_adjust` a
        INNER JOIN batch b
            ON a.BranchID = b.BranchID
            AND a.BatNbr = b.BatNbr
            AND b.Module = 'AR'
        WHERE IFNULL(a.Reversal, '') = ''
          AND b.Rlsed = 1
          AND DATE(a.AdjgDocDate) <= (SELECT * FROM `staging.d_current_table`)
        GROUP BY
            a.BranchID,
            AdjdBatNbr,
            AdjdRefNbr,
            4
    )
  , mapping_thanhtoan_congno AS (
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
    INNER JOIN
      batch AS b
      ON d.BranchID = b.BranchID
      AND d.BatNbr = b.BatNbr
      AND b.Module = 'AR'
    LEFT JOIN
      thanhtoan_congno AS aj
      ON aj.BranchID = d.BranchID
      AND aj.AdjdBatNbr = d.BatNbr
      AND d.RefNbr = aj.AdjdRefNbr
    LEFT JOIN
      debtdet AS deb
      ON deb.BranchID = d.BranchID
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
  )
  , mapping_cantru_congno AS (
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
    INNER JOIN
      batch AS b
      ON d.BranchID = b.BranchID
      AND d.BatNbr = b.BatNbr
      AND b.Module = 'AR'
    LEFT JOIN
      cantru_congno AS aj
      ON aj.BranchID = d.BranchID
      AND aj.AdjgBatNbr = d.BatNbr
      AND aj.AdjgRefNbr = d.RefNbr
    LEFT JOIN
      debtdet AS deb
      ON deb.BranchID = d.BranchID
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
  )
  ,   mapping_hoan_ung AS (
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
    INNER JOIN
      hoan_ung AS aj
      ON aj.BranchID = d.BranchID
      AND aj.AdjdBatNbr = d.BatNbr
      AND d.RefNbr = aj.AdjdRefNbr
    LEFT JOIN
      debtdet AS deb
      ON deb.BranchID = d.BranchID
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
    SELECT *
    FROM
      mapping_thanhtoan_congno
    UNION ALL
    SELECT *
    FROM
      mapping_cantru_congno
    UNION ALL
    SELECT *
    FROM
      mapping_hoan_ung
  )

    -- ,   max_data_adj AS (
    --     SELECT
    --         a.BranchID,
    --         a.AdjdBatNbr,
    --         a.AdjdRefNbr,
    --         a.adjgrefnbr,
    --         a.adjgbatnbr,
    --         MAX(DATE(a.adjgdocdate)) AS max_adjgdocdate,
    --         MIN(DATE(a.adjgdocdate)) AS min_adjgdocdate
    --     FROM `staging.sync_dms_adjust` a
    --     GROUP BY 1, 2, 3, 4, 5
    -- )
    ,   result AS (
        SELECT
            ib.slsperid AS slsperid, -- IFNULL(ib.slsperid, p.slsperid)
            p.BranchID,
            p.CustId,
            p.DocType,
            o.orderdate AS DocDate,
            IFNULL(o.OrigOrderNbr, IFNULL(o.ordernbr, '')) AS Ordnbr,
            o.paymentsform,
            CASE
                WHEN IFNULL(o.Ordernbr, '') = 'IR102021-00011' AND p.InvcNbr = '0010026'
                    THEN 'Dung dịch vệ sinh mũi nước biển sâu Xisat người lớn (75 ml), Việt Nam, (1chai/hộp)'
                ELSE p.docdesc
            END AS docdesc,
            p.InvcNote,
            p.InvcNbr,
            -- OrigDocAmt
            -- AdjAmt
            -- remain
            CASE
                WHEN p.terms = 'O1' THEN DATE_ADD(p.docdate, INTERVAL 30 DAY)
                ELSE p.duedate
            END AS duedate,
            -- OrigOrderNbr
            p.Terms,
            p.adjgdocdate,
            CASE
                WHEN IFNULL(o.Ordernbr, '') = 'IR102021-00011' AND p.InvcNbr = '0010026'
                    THEN 'IR102021-00010'
                ELSE IFNULL(o.Ordernbr, '')
            END AS mahd_so,
            -- p.Crtd_DateTime AS updated_at
            SUM(OrigdocAmt) AS sotien_nogoc,
            SUM(AdjAmt) AS sotien_da_thanhtoan,
            SUM(OrigdocAmt) - SUM(AdjAmt) AS so_du_chungtu
        FROM union_all_hoadon p
        LEFT JOIN
        `staging.sync_ar_chuyencongno_cnoff_sangcnhientai` AS ht
        ON ht.NewBranchID = p.BranchID
        AND ht.NewBatnbr = p.BatNbr
        LEFT JOIN `staging.sync_dms_so` o
            ON o.BranchID = p.BranchID
            AND o.Ordernbr = p.Ordnbr
        LEFT JOIN `staging.sync_dms_pda_so` a
            ON o.BranchID = a.BranchID
            AND o.OrigOrderNbr = a.OrderNbr
        LEFT JOIN ibd ibe
            ON ibe.BranchID = a.BranchID
            AND ibe.OrderNbr = a.OrderNbr
        LEFT JOIN ib
            ON ibe.BranchID = ib.BranchID
            AND ibe.BatNbr = ib.BatNbr
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
    ),
    -------------------------------------------------------------*Tính toán phân loại công nợ*-----------------------------------------------------------------------
    -- Mapping gối đầu 30 ngày
    mapping_customer AS (
        SELECT
            a.* EXCEPT(adjgdocdate, DocDate, duedate, so_du_chungtu),
            CASE
                WHEN so_du_chungtu = 0 THEN so_du_chungtu
                WHEN COUNT(DISTINCT sotien_nogoc) OVER (
                        PARTITION BY a.ordnbr, a.custid, a.invcnbr, a.docdesc, a.BranchID
                      ) = 1
                    THEN AVG(sotien_nogoc) OVER (
                            PARTITION BY a.custid, a.branchid, a.ordnbr, a.docdesc, a.invcnbr
                          )
                        - SUM(a.sotien_da_thanhtoan) OVER (
                            PARTITION BY a.custid, a.branchid, a.InvcNbr, a.docdesc, a.ordnbr
                            ORDER BY a.DocDate ASC, a.adjgdocdate ASC
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                          )
                ELSE SUM(sotien_nogoc) OVER (
                        PARTITION BY a.custid, a.branchid, a.ordnbr, a.invcnbr
                      )
                    - SUM(sotien_da_thanhtoan) OVER (
                        PARTITION BY a.custid, a.branchid, a.ordnbr, a.invcnbr
                      )
            END AS so_du_chungtu,
            -- IFNULL(b.terms, b1.terms) AS terms,
            DATE(DocDate) AS dateoforder, -- Ngày hóa đơn
            IFNULL(DATE(c.ngaytoihan), DATE(duedate)) AS duedate,
            DATE(adjgdocdate) AS orderdate, -- Ngày thu tiền
            COUNT(DISTINCT sotien_nogoc) OVER (
                PARTITION BY a.ordnbr, a.custid, a.invcnbr, a.docdesc, a.BranchID
            ) AS is_dup_nogoc,
            ROW_NUMBER() OVER (
                PARTITION BY a.ordnbr, a.custid, a.invcnbr, a.BranchID, a.docdesc
                ORDER BY adjgdocdate DESC
            ) AS fill_orderdate_null,
            CASE
                WHEN COUNT(DISTINCT sotien_nogoc) OVER (
                        PARTITION BY a.ordnbr, a.custid, a.invcnbr, a.docdesc, a.BranchID
                      ) = 1
                    THEN AVG(sotien_nogoc) OVER (
                            PARTITION BY a.custid, a.branchid, a.ordnbr, a.docdesc, a.invcnbr
                          )
                        - SUM(sotien_da_thanhtoan) OVER (
                            PARTITION BY a.custid, a.branchid, a.ordnbr, a.docdesc, a.invcnbr
                          )
                ELSE SUM(sotien_nogoc) OVER (
                        PARTITION BY a.custid, a.branchid, a.ordnbr, a.invcnbr
                      )
                    - SUM(sotien_da_thanhtoan) OVER (
                        PARTITION BY a.custid, a.branchid, a.ordnbr, a.invcnbr
                      )
            END AS so_du_dh,
            (SELECT MAX(inserted_at) FROM `staging.sync_dms_ardoc` WHERE inserted_at IS NOT NULL) AS inserted_at
        FROM result a
        LEFT JOIN goi_dau_30ngay c
            ON a.custid = c.custid
            AND a.ordnbr = c.ordernbr
            AND a.branchid = c.branchid
            AND a.terms = 'O1'
    )

    SELECT * FROM mapping_customer
);

CREATE OR REPLACE TABLE `staging_temp.d_rawdata_debt_detail`
COPY `staging_temp.d_rawdata_debt_detail_temp`;
END;
