-- ==========================================================================
-- Routine Name : sp_f_doanhthu_hcp_crm
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-07-01 12:53:15.937000+00:00
-- Last Altered : 2026-07-01 12:53:15.937000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_doanhthu_hcp_crm()
BEGIN
TRUNCATE TABLE staging_temp.f_doanhthu_hcp_crm_temp;
INSERT INTO staging_temp.f_doanhthu_hcp_crm_temp(

with

f_doanhthu_ins_v2_1 as
(
  with

-----Orderdate null
data_doanhthu_moi as
(
select a.*except(orderdate),
a.orderdate as orderdate,
a.sotien_da_thanhtoan as DebConfirmAmtRelease,
-- a.so_du_dh,
a.so_du_chungtu as congno,
  sum(a.sotien_da_thanhtoan) over (partition by a.custid,a.branchid,a.InvcNbr,a.ordnbr order by a.DateOfOrder asc,a.orderdate asc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) as so_tien_kt_xacnhan_congdon,
a.sotien_nogoc -sum(a.sotien_da_thanhtoan) over (partition by a.custid,a.branchid,a.InvcNbr,a.ordnbr order by a.DateOfOrder asc,a.orderdate asc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) as  congno_saukhi_kt_xacnhan,
a.ordnbr as ordernbr,
sum(a.sotien_da_thanhtoan) over (partition by a.ordnbr,a.branchid,a.CustId,a.InvcNbr,a.docdesc ) as group_sotien_dathanhtoan,
b2.dueintnv as songay_thanhtoan,
Case when b1.statedescr in ('Thành phố Cần Thơ','Đồng Nai','Khánh Hòa','Nghệ An',
'Thành phố Đà Nẵng','Thành phố Hà Nội','Thành phố Hồ Chí Minh') then 'VP chi nhánh'
else 'Tỉnh' end as is_diadiem,
b1.channel as channels,
b1.shoptype as subchannel ,
b1.statedescr as state,
b1.custname as custname,
b1.paymentsform as paymentsform,
-- b1.refcustid as refcustid,
b1.territorydescr as territorydescr,
  Case when b1.refcustid = 'TD42I004A' then 'TD42I004'
	   	  when b1.refcustid = 'TT55I011A' then 'TT55I011'
				 when b1.refcustid= 'TD42I025A' then 'TD42I025'
				 else b1.refcustid end as refcustid,
-- ifnull(b.refcustid,b1.refcustid) as refcustid,
-- b1.territorydescr as territorydescr
from `staging_temp.d_rawdata_debt_detail` a
-- LEFT JOIN `staging_temp.d_rawdata_debt_detail` a1 on a1.is_dup_nogoc = a.is_dup_nogoc and a1.is_dup_nogoc =2 and a1.fill_orderdate_null + 1 = a.fill_orderdate_null
-- and a.ordnbr =a1.ordnbr and a.custid = a1.custid and a.invcnbr= a1.invcnbr and a.BranchID = a1.branchid and a.docdesc = a1.docdesc
-- LEFT JOIN `staging.d_master_khachhang2022` b on a.custid =b.custid and date(a.dateoforder) <'2023-01-01'
LEFT JOIN `staging.d_master_khachhang` b1 on a.custid =b1.custid
LEFT JOIN staging.d_manual_terms_detail b2 on b2.termsid = a.Terms

where b1.channel in('INS','PCL','CLC')
and (left(lower(custname),5) <> 'xuất ' or lower(custname) not like '%anh sách%' or lower(custname) not like '%quà%')
and b1.custid not like 'DS%'

),
data_doanhthu as (
SELECT a.ordernbr,a.custid,a.refcustid,a.custname,is_diadiem,a.so_du_dh,
a.InvcNbr, a.congno,a.so_tien_kt_xacnhan_congdon,a.congno_saukhi_kt_xacnhan,
a.dateoforder,a.duedate,a.territorydescr as territory,a.state,
a.channels,a.subchannel,
a.terms,
a.songay_thanhtoan,
a.DebConfirmAmtRelease as sotien,
a.orderdate as ngaythu_dms,
a.orderdate,
 FROM data_doanhthu_moi a
 where DebConfirmAmtRelease <> 0

 ),
result as (
 select a.*,
   Case when  e.madonhang =a.ordernbr and e.makhcu =a.refcustid then e.ngaythu_ge
  else Cast ( a.ngaythu_dms as timestamp) end as ngaythu_ge,
	m.canhbao_noxau

  from data_doanhthu a
  LEFT JOIN `spatial-vision-343005.staging.d_doanhthu_donhang` e on e.madonhang =a.ordernbr and e.makhcu =a.refcustid
	LEFT JOIN (select distinct custid,canhbao_noxau from `warehouse.f_congno_hcp_crs`) m on m.custid =a.custid

),
-- THêm phân loại nợ theo đơn hàng khi đã thanh toán
mapping_mau_no as (
select *,
 Case
    when songay_thanhtoan <=3 and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 1 day)
    when songay_thanhtoan <=3 and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 3 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 2 day)
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 4 day)

    when songay_thanhtoan <=15
     and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 2 day)
    when songay_thanhtoan <=15
     and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 4 day)

    when songay_thanhtoan > 15
     and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 2 day)
     when songay_thanhtoan > 15
     and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 4 day)

  else  null

 end as thoi_diem_no_vang,
 Case
    when songay_thanhtoan <=3 and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 6 day)
    when songay_thanhtoan <=3 and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 8 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 7 day)
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 9 day)

    when songay_thanhtoan <= 15
     and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 17 day)
    when songay_thanhtoan <= 15
     and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 19 day)

    when songay_thanhtoan > 15
     and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 32 day)
     when songay_thanhtoan > 15
     and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 34 day)

  else  null

 end as thoi_diem_no_do,
 Case
    when songay_thanhtoan <= 3 and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 10 day)
    when songay_thanhtoan <= 3 and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 12 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 11 day)
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 13 day)

    when songay_thanhtoan <= 15
     and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 32 day)
    when songay_thanhtoan <= 15
     and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 34 day)

    when songay_thanhtoan > 15
     and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 62 day)
     when songay_thanhtoan > 15
     and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 64 day)

  else  null

 end as thoi_diem_no_den

 from result ),
result_0 as (
select *,
Case when date(ngaythu_ge)
 >= thoi_diem_no_den then 'Nợ đen'
     when date(ngaythu_ge)
  < thoi_diem_no_den  and date(ngaythu_ge)
 >= thoi_diem_no_do  then 'Nợ đỏ'
     when date(ngaythu_ge)
  < thoi_diem_no_do and date(ngaythu_ge)
  >= thoi_diem_no_vang  then 'Nợ vàng'
     when date(ngaythu_ge)
  < thoi_diem_no_vang   then 'Nợ xanh'

else null
end as phanloai_no,
(select max(inserted_at) from `staging_temp.d_rawdata_debt_detail` where inserted_at is not null) as updated_at

 from mapping_mau_no b)

 select * from result_0  --where phanloai_no is null
)

SELECT
date(date_trunc(ngaythu_dms,month)) as thang_thu,
a.*,
c.col.ma_nvbh as manv,
c.tencvbh,
CASE
  WHEN LOWER(a.custname) LIKE '%gonsa%'
    OR LOWER(a.custname) LIKE '%tây âu%' THEN 'MR1137'
  ELSE COALESCE(hr_crm.msnvcsmmoi, c.supid, 'MR1137')
END as macrm,
CASE
  WHEN LOWER(a.custname) LIKE '%gonsa%'
    OR LOWER(a.custname) LIKE '%tây âu%' THEN 'Vũ Mừng'
  ELSE COALESCE(g.crm, c.tenquanlytt, 'Vũ Mừng')
END as tenquanlytt,
FROM f_doanhthu_ins_v2_1 a
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` c on c.custid = a.custid
LEFT JOIN `spatial-vision-343005.staging.d_manual_dia_ban_cong_no_hcp` g on g.ma_kh = a.custid
LEFT JOIN (
    SELECT msnvcsmmoi, hovatenfullname
    FROM `spatial-vision-343005.staging.d_hr_dsns`
    WHERE phongdeptsummary = 'HCP'
) hr_crm on hr_crm.hovatenfullname = g.crm
);

Create or replace table `warehouse.f_doanhthu_hcp_crm`

copy `staging_temp.f_doanhthu_hcp_crm_temp`;

End;
