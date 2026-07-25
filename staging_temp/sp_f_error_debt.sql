CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_error_debt()
BEGIN 
  TRUNCATE TABLE staging_temp.f_error_debt_temp;

 INSERT INTO staging_temp.f_error_debt_temp(

-- Create table staging_temp.f_error_debt_temp
-- as

with data_error_debt as (
select 
so.OrigOrderNbr, 
-- so.ordertype,
-- so.salesordertype,
so.custid,
so.Crtd_DateTime, 
ib.SlsperID, 
so.OrderNbr from `staging.sync_dms_so` so
INNER JOIN staging.sync_dms_ibd ibd on
so.BranchID = ibd.BranchID and
so.OrigOrderNbr = ibd.OrderNbr
and so.Status = 'C'          
and so.OrderType = 'IN'
INNER JOIN `staging.sync_dms_ib` ib on
ibd.BranchID = ib.BranchID and
ibd.BatNbr = ib.BatNbr
and ib.Status = 'C'
left join `staging.sync_dms_debtdet` deb on
deb.BranchID = so.BranchID and
so.OrigOrderNbr = deb.OrderNbr and
so.ARBatNbr = deb.ARBatNbr
where cast(so.Crtd_DateTime as date) >= '2021-01-01'
and deb.BranchID IS NULL
order by so.Crtd_DateTime asc
--and so.OrigOrderNbr = 'DH2-0522-00700'
)

select a.*,b.custname,b.paymentsform,b.terms,
c.tencvbh,c.tenquanlytt,c.tenquanlykhuvuc,c.tenquanlyvung
 from data_error_debt a 
LEFT JOIN `staging.d_master_khachhang` b on a.custid =b.custid
LEFT JOIN `staging.d_users` c on a.slsperid =c.manv
where b.paymentsform in ('Tiền Mặt')
  );

Create or replace table `warehouse.f_error_debt`

copy `staging_temp.f_error_debt_temp`;

End;