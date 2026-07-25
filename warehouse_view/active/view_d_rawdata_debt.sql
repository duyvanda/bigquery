CREATE VIEW `spatial-vision-343005.warehouse.view_d_rawdata_debt`
AS WITH thuhoi_bbgh AS (
SELECT
DISTINCT
macongtycn,
mahd,
kt_da_nhan
FROM `warehouse.f_thuhoi_bbgh`
)
, phan_bo_no_mds AS (
select
c.custid,
c.branchid,
c.ordernbr,
c.invcnote,
c.invcnbr,
c.slsperid as manv_phanbono,
e.tencvbh as ten_phanbono,
e.supid,
e.tenquanlytt
from `spatial-vision-343005.staging.sync_dms_debtdet` c
LEFT JOIN `staging.d_users` e on e.manv = c.slsperid
QUALIFY ROW_NUMBER() OVER(
        PARTITION BY 
            c.custid,
            c.branchid,
            c.ordernbr,
            c.invcnote,
            c.invcnbr
        ORDER BY DATE(crtd_datetime) desc ) = 1

)

SELECT
  a.slsperid,
  t.tencvbh as ten_nvgh,
  a.BranchID,
  a.CustId,
  a.DocType,
  a.Ordnbr,
  a.paymentsform,
   case when a.paymentsform = 'A' then	'Chuyển Khoản'
      when a.paymentsform = 'B' then 'Tiền Mặt'
      when a.paymentsform = 'C' then 'Tiền Mặt/Chuyển Khoản'
      when a.paymentsform = 'D'	then 'Ghi Nợ'
      when a.paymentsform = 'E'	then 'TM/CK/CTH'
      when a.paymentsform = 'F' then	'Cấn Trừ Nợ' 
    else a.paymentsform end as hinhthucthanhtoan,
  a.docdesc,
  a.InvcNote,
  a.InvcNbr,
  a.Terms,
  d.descr as han_thanh_toan,
  a.mahd_so,
  a.sotien_nogoc,
  a.sotien_da_thanhtoan,
  a.so_du_chungtu,
  abs(a.so_du_chungtu) as abs_so_du_chungtu,
  a.dateoforder,
  a.duedate,
  a.orderdate,
  a.contractid,
  ct.contractnbr,
  ct.noticenbr,
  q.custname,
  q.channel,
  kt_da_nhan,
  c. manv_phanbono,
  c.ten_phanbono,
  c.supid,
  c.tenquanlytt

FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` a
LEFT JOIN `staging.d_oricontract` ct ON ct.contractid = a.contractid
LEFT JOIN spatial-vision-343005.staging.d_master_khachhang q on a.CustId = q.custid
LEFT JOIN `staging.d_users` t on t.manv = a.slsperid
LEFT JOIN thuhoi_bbgh b on a.BranchID = b.macongtycn and a.mahd_so = b.mahd
LEFT JOIN `spatial-vision-343005.staging.d_manual_terms_detail` d on a.Terms = d.termsid
LEFT JOIN phan_bo_no_mds c 
  on  c.custid = a.CustId 
  and c.branchid = a.BranchID
  and c.ordernbr = a.Ordnbr
  and c.invcnote = a.InvcNote
  and c.invcnbr = a.InvcNbr

--WHERE a.mahd_so IS NOT NULL




;