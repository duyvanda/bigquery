CREATE VIEW `spatial-vision-343005.warehouse.view_don_hang_khong_doi_duoc_no_tm`
AS with order_co_no as
(
SELECT
-- a.slsperid,
-- a.BranchID,
a.CustId,
-- DocType,
a.Ordnbr,
-- docdesc,
-- InvcNote,
-- InvcNbr,
-- a.Terms,
-- a.dateoforder, 
-- ngay hoa don
a.duedate,
-- orderdate,
-- so_du_dh,
-- inserted_at,
-- a.paymentsform,
-- sum(sotien_nogoc) as so_tien_no_goc_sum,
-- sum(sotien_da_thanhtoan) as   so_tien_da_thanh_toan_sum,
-- sum(so_du_chungtu) as so_du_chung_tu_sum

FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` a
INNER JOIN staging.d_master_khachhang c on a.CustId = c.custid and c.channel not in ('OTH_LAB','NB')
where a.paymentsform in ('B','C')

group by all

having sum(so_du_chungtu) >= 1

)
-- select Ordnbr from order_co_no group by all

, checkin_note as
(
  select 
  custid,
  visitdate,
  noteid,
  slsperid,
  -- branchid,
  note, -- ghi chu check in
  -- descr,
  -- salesid,
  -- distance,
  checkintype,
  replace(imagefilename, 'dms.phanam.com.vn','dms.meraplion.com') as imagefilename,
  1 as count_check_in_debt
from `spatial-vision-343005.staging.sync_dms_oc`
where date(visitdate) >= "2024-04-01"  and checkintype = 'Thu Nợ'
order by visitdate asc
)

-- select count(*) from order_co_no
-- 1330 dong

, cac_don_hang_con_no_va_co_check_in_thu_no_sau_ngay_toi_han as (
-- các đơn hàng còn nợ và có check in thu nợ sau ngày tới hạn


select 
a.*, 
cast (date(visitdate) as STRING) as visitdate_string, 
note, ifnull(b.count_check_in_debt,0) as count_check_in_debt
from order_co_no a LEFT JOIN checkin_note b on a.CustId = b.custid and

date(visitdate) > date(duedate)
where date(visitdate) is not null

)

, cac_don_hang_con_no_va_co_check_in_thu_no_sau_ngay_toi_han_2lan as
-- các đơn hàng còn nợ và có check in thu nợ sau ngày tới hạn 2 lần
(
select 
CustId, 
Ordnbr, 
STRING_AGG(visitdate_string, " & ") as visitdate_string,
STRING_AGG(note, " & ") as note,
sum(count_check_in_debt) as count_check_in_debt_sum
from cac_don_hang_con_no_va_co_check_in_thu_no_sau_ngay_toi_han group by all
HAVING count_check_in_debt_sum >=2

)

, lay_nv_crm_sales as

(
  SELECT distinct sodondathang, ma_crm as crm, tenquanlytt  FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy`
)

select
a.slsperid,
n.tencvbh,
n.supid,
n.tenquanlytt,

-- sales

s.crm,
s.tenquanlytt as crm_name,

--end

a.BranchID,
a.CustId,
c.custname,
c.channel,
c.shoptype,
-- a.DocType,
a.Ordnbr,
a.paymentsform,
-- a.docdesc,
-- a.InvcNote,
a.InvcNbr,
a.Terms,
-- a.mahd_so,
a.sotien_nogoc,
a.sotien_da_thanhtoan,
a.so_du_chungtu,
a.dateoforder,
a.duedate,
-- a.orderdate,
-- a.so_du_dh,
a.inserted_at,
b.visitdate_string,
b.note, 
b.count_check_in_debt_sum,
kt_da_nhan as ketoandanhan
FROM `spatial-vision-343005.staging_temp.d_rawdata_debt` a 
INNER JOIN cac_don_hang_con_no_va_co_check_in_thu_no_sau_ngay_toi_han_2lan  b
on a.CustId = b.CustId and a.Ordnbr = b.Ordnbr
LEFT JOIN staging.d_master_khachhang c on a.CustId = c.custid
left join `spatial-vision-343005.staging.d_users`  n on a.slsperid = n.manv
LEFT JOIN lay_nv_crm_sales s on s.sodondathang = a.Ordnbr
--LEFT JOIN `staging.d_kt_thuhoi_bbgh` n2 on concat(trim(a.Ordnbr),'-',a.InvcNbr) = trim(n2.noimadhsohoadon) and n2.ketoandanhan is not null and n2.ketoandanhan not in ('-')
LEFT JOIN `spatial-vision-343005.warehouse.f_thuhoi_bbgh` n2 on n2.sodonhang = a.Ordnbr AND n2.mahd = a.mahd_so
LEFT JOIN `staging.view_sync_dms_bbgh_checkin`  d on d.ordernbr = a.Ordnbr and d.branchid = a.BranchID








;