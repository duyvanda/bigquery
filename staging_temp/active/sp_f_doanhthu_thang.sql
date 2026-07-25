CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_doanhthu_thang()
BEGIN 
  TRUNCATE TABLE staging_temp.f_doanhthu_thang_temp;

 INSERT INTO staging_temp.f_doanhthu_thang_temp(

-- Create table staging_temp.f_doanhthu_thang_temp
-- partition by orderdate
-- as

with
mapping_customer as (
select a.*except(so_du_dh,inserted_at,paymentsform),
b2.dueintnv as songay_thanhtoan,

Case when ifnull(b.statedescr,b1.statedescr) in ('Thành phố Cần Thơ','Đồng Nai','Khánh Hòa','Nghệ An',
'Thành phố Đà Nẵng','Thành phố Hà Nội','Thành phố Hồ Chí Minh') then 'VP chi nhánh'
else 'Tỉnh' end as is_diadiem,
ifnull(b.channel,b1.channel) as channel,
ifnull(b.shoptype,b1.shoptype) as shoptype,
ifnull(b.statedescr,b1.statedescr) as statedescr,
ifnull(b.custname,b1.custname) as custname,
ifnull(b.paymentsform,b1.paymentsform) as paymentsform,
ifnull(b.refcustid,b1.refcustid) as refcustid,
ifnull(b.territorydescr,b1.territorydescr) as territorydescr

-- Case  when ordernbr in('DH122018-17643','DH062018-13754') then 'CS'
--       when trim(b.paymentsform) in ('B','C') and ifnull(e.shoptype,b.shoptype) in ('NT','PK','SI') then 'MDS'
--       when trim(a.paymentsform) in ('B','C') and ifnull(e.shoptype,b.shoptype) in ('CHUOI') and terms like '%Thu tiền ngay%' then 'MDS'
--     -- when trim(b.paymentsform) ='Tiền Mặt/Chuyển Khoản' and b.channel not in ('DLPP','CLC') then 'MDS'
--      else 'CS' end as debtincharge, 
 from `staging_temp.d_rawdata_debt_detail`  a
LEFT JOIN `staging.d_master_khachhang2022` b on a.custid =b.custid and date(dateoforder) <'2023-01-01'
LEFT JOIN `staging.d_master_khachhang` b1 on a.custid =b1.custid and date(dateoforder)>='2023-01-01'
LEFT JOIN staging.d_manual_terms_detail b2 on b2.termsid = a.Terms

-- LEFT JOIN `spatial-vision-343005.staging.sync_dms_historycustclass` e on e.version = a.Version
-- LEFT JOIN goi_dau_30ngay c on a.custid =c.custid and a.ordnbr =c.ordernbr and a.branchid=c.branchid
-- where a.custid in ('N0310320','N0110742')
where ifnull(b.channel,b1.channel) not in ('NB','OTH_LAB')
),

-------------------------------------------------------------*Chốt công nợ*-----------------------------------------------------------------------



-- select invcnbr,sum(OrigdocAmt) as origdoc,sum(adjamt) as adjamt from union_all_hoadon where custid ='000354'
-- group by 1

-- select distinct adjgdocdate from result where result.so_du_chungtu <0
--where ordnbr ='CO120422-00019'
--where custid ='N0320136'
-- select 
-- custid ,
-- sum(sotien_nogoc) as no_goc, sum(result.sotien_da_thanhtoan) as dathanhtoan,
-- sum(sotien_nogoc)-sum(result.sotien_da_thanhtoan) as so_du
-- -- sum(result.so_du_chungtu) as so_du 
-- from result
--  where custid ='N06102002'
-- group by 1
-- having so_du =0


-------------------------------------------------------------*Tính toán phân loại công nợ*-----------------------------------------------------------------------

fill_orderdate_null as 
(
select a.*except(orderdate),
ifnull(a1.orderdate,a.orderdate) as orderdate,
from mapping_customer a
--Xử lý đơn orderdate null
LEFT JOIN mapping_customer a1 on a1.is_dup_nogoc = a.is_dup_nogoc and a1.is_dup_nogoc =2 and a1.fill_orderdate_null + 1 = a.fill_orderdate_null
and a.ordnbr =a1.ordnbr and a.custid = a1.custid and ifnull(a.invcnbr,'')= ifnull(a1.invcnbr,'') and a.BranchID = a1.branchid and a.docdesc = a1.docdesc


)
,
data_doanhthu_moi as (
select 
*except(sotien_nogoc,sotien_da_thanhtoan,so_du_chungtu,fill_orderdate_null),
sum(sotien_nogoc) as sotien_nogoc,
sum(sotien_da_thanhtoan) as sotien_da_thanhtoan,

 from fill_orderdate_null a
--   where is_dup_nogoc =2
 group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
),
--  having so_du_chungtu <>0

data_doanhthu_moi1 as (
select *,
  sum(a.sotien_da_thanhtoan) over (partition by a.custid,a.branchid,a.InvcNbr,a.ordnbr order by a.DateOfOrder asc,a.orderdate asc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) as so_tien_kt_xacnhan_congdon,

a.sotien_nogoc -sum(a.sotien_da_thanhtoan) over (partition by a.custid,a.branchid,a.InvcNbr,a.ordnbr order by a.DateOfOrder asc,a.orderdate asc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) as  congno_saukhi_kt_xacnhan,

a.sotien_nogoc -sum(a.sotien_da_thanhtoan) over (partition by a.custid,a.branchid,a.InvcNbr,a.ordnbr order by a.DateOfOrder asc,a.orderdate asc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW )  + a.sotien_da_thanhtoan as  congno_goc_conlai,
-- avg(so_du_chungtu) over (partition by a.ordnbr,a.branchid,a.CustId,a.InvcNbr ) - sum(sotien_da_thanhtoan) over (partition by a.ordnbr,a.branchid,a.CustId,a.InvcNbr ) as congno_saukhi_kt_xacnhan,
sum(a.sotien_da_thanhtoan) over (partition by a.ordnbr,a.branchid,a.CustId,a.InvcNbr,a.docdesc ) as group_sotien_dathanhtoan,

 from data_doanhthu_moi a
)
,
-- where custid ='TD42I024'

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
 from data_doanhthu_moi1 
 ),

phanloai_no as (
select *,
Case when date(orderdate) >= thoi_diem_no_den then 'Nợ đen'
     when date(orderdate) < thoi_diem_no_den  and date(orderdate) >= thoi_diem_no_do  then 'Nợ đỏ'
     when date(orderdate)  < thoi_diem_no_do and date(orderdate) >= thoi_diem_no_vang  then 'Nợ vàng'
     when date(orderdate) < thoi_diem_no_vang   then 'Nợ xanh'

       when date(orderdate) is null and thoi_diem_no_den <= (select * from `staging.d_current_table`)
 then 'Nợ đen'
     when date(orderdate) is null and thoi_diem_no_do <= (select * from `staging.d_current_table`)
 then 'Nợ đỏ'
     when date(orderdate) is null and thoi_diem_no_vang <= (select * from `staging.d_current_table`)
 then 'Nợ vàng'
     when date(orderdate) is null and thoi_diem_no_vang >(select * from `staging.d_current_table`)
 then 'Nợ xanh'

else null end as phanloai_no,
(select max(inserted_at) from `staging_temp.d_rawdata_debt_detail`) as inserted_at
from mapping_mau_no
)

select * from phanloai_no where  date(orderdate) <= (select * from `staging.d_current_table`)

  );

Create or replace table `warehouse.f_doanhthu_thang`

copy `staging_temp.f_doanhthu_thang_temp`;

End;