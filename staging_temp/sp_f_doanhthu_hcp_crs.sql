CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_doanhthu_hcp_crs()
BEGIN 
  TRUNCATE TABLE staging_temp.f_doanhthu_hcp_crs_temp;

 INSERT INTO staging_temp.f_doanhthu_hcp_crs_temp(

-- Create or replace table staging_temp.f_doanhthu_hcp_crs_temp
-- partition by ngaythu_dms
-- as


with 
f_doanhthu_ins_v2_1 as (
with 

-----Orderdate null 

data_doanhthu_moi as 
(
select a.*except(orderdate),
ifnull(a1.orderdate,a.orderdate) as orderdate,
a.sotien_da_thanhtoan as DebConfirmAmtRelease,
-- a.so_du_dh,
a.so_du_chungtu as congno,
  sum(a.sotien_da_thanhtoan) over (partition by a.custid,a.branchid,a.InvcNbr,a.ordnbr order by a.DateOfOrder asc,a.orderdate asc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) as so_tien_kt_xacnhan_congdon,
a.sotien_nogoc -sum(a.sotien_da_thanhtoan) over (partition by a.custid,a.branchid,a.InvcNbr,a.ordnbr order by a.DateOfOrder asc,a.orderdate asc ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) as  congno_saukhi_kt_xacnhan,
a.ordnbr as ordernbr,
-- avg(so_du_chungtu) over (partition by a.ordnbr,a.branchid,a.CustId,a.InvcNbr ) - sum(sotien_da_thanhtoan) over (partition by a.ordnbr,a.branchid,a.CustId,a.InvcNbr ) as congno_saukhi_kt_xacnhan,
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
LEFT JOIN `staging_temp.d_rawdata_debt_detail` a1 on a1.is_dup_nogoc = a.is_dup_nogoc and a1.is_dup_nogoc =2 and a1.fill_orderdate_null + 1 = a.fill_orderdate_null
and a.ordnbr =a1.ordnbr and a.custid = a1.custid and a.invcnbr= a1.invcnbr and a.BranchID = a1.branchid and a.docdesc = a1.docdesc
-- LEFT JOIN `staging.d_master_khachhang2022` b on a.custid =b.custid and date(a.dateoforder) <'2023-01-01'
LEFT JOIN `staging.d_master_khachhang` b1 on a.custid =b1.custid 
LEFT JOIN staging.d_manual_terms_detail b2 on b2.termsid = a.Terms

where b1.channel in('INS','PCL','CLC')
and (left(lower(custname),5) <> 'xuất ' or lower(custname) not like '%anh sách%' or lower(custname) not like '%quà%')
-- and a.slsperid <> 'GH001' 
-- 	  and concat(a.ordernbr,a.branchid) not in ('DH022017-05277MR0003','DH072017-30131MR0003',
-- 		'DH032017-00645MR0003','DH012019-05622MR0003','DH032017-00141MR0003',
-- 		'DH052017-17203MR0003','DH042017-10045MR0003','DH062017-04068MR0003',
-- 		'DH122016-09019MR0003','DH122016-06110MR0003','DH122016-07898MR0003','DH012017-12644MR0003'
		
		-- )
	  
--  and a.DebConfirmAmtRelease >0
),




data_doanhthu as (
SELECT a.ordernbr,a.custid,a.refcustid,a.custname,is_diadiem,a.so_du_dh,
a.InvcNbr, a.congno,a.so_tien_kt_xacnhan_congdon,a.congno_saukhi_kt_xacnhan,
--OpeiningOrderAmt + DeliveredOrderAmt -ReturnOrdAmt as congno,
a.dateoforder,a.duedate,a.territorydescr as territory,a.state,
a.channels,a.subchannel,
a.terms,
a.songay_thanhtoan,
a.DebConfirmAmtRelease as sotien,
a.orderdate as ngaythu_dms,
a.orderdate,
 FROM data_doanhthu_moi a

 where DebConfirmAmtRelease <> 0
--  where DebConfirmAmtRelease >1000 
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
end as phanloai_no

 from mapping_mau_no b)

 select * from result_0  --where phanloai_no is null
),


----Mapping CRS
tuyen_dms_moinhat as 
(
with data_tuyen as (
SELECT custid,slsperid,crtd_datetime,
Case when routetype in ('B','D') then 1 else 2 end as routetype,
FROM `spatial-vision-343005.staging.sync_dms_srm`  a 
LEFT JOIN `staging.d_users` b on a.slsperid =b.manv

where delroutedet is false and routetype in ('B','D') --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
and b.tenquanlyvung in('Nguyễn Thọ Chiến','Vũ Mừng')
)


select custid,slsperid --'Tuyến MCP' as datatype 
from data_tuyen
qualify row_number() over (partition by custid order by routetype asc,crtd_datetime desc) =1
),

tuyen_dms_bytime as 
(
with data_tuyen as (
SELECT custid,slsperid,crtd_datetime,thang,
Case when routetype in ('B','D') then 1 else 2 end as routetype,
FROM `spatial-vision-343005.staging.sync_dms_srm_bytime`  a 
LEFT JOIN `staging.d_users` b on a.slsperid =b.manv

where delroutedet is false and routetype in ('B','D') --and slsperid not in ('MR1008','MR1705','MR2610','MR1225','MR2596','MR2594','MR2611')
and b.tenquanlyvung in('Nguyễn Thọ Chiến','Vũ Mừng') and custid not in (select custid from tuyen_dms_moinhat)
)

select custid,slsperid
from data_tuyen
qualify row_number() over (partition by custid order by thang desc,routetype asc,crtd_datetime desc) =1
),

tuyen_cvbh_hd as 
(


select distinct custid,slsperid
from `spatial-vision-343005.staging.d_get_contract_det`  a
LEFT JOIN `staging.d_users` b on a.slsperid =b.manv
where 
 slsperid not in ('GH001','QUYNHPTA','MA001','MA002') and b.tenquanlyvung in('Nguyễn Thọ Chiến','Vũ Mừng')
UNION distinct
select distinct custid,slsperid
from `spatial-vision-343005.staging.d_get_contract_det_bytime` a
LEFT JOIN `staging.d_users` b on a.slsperid =b.manv

and slsperid not in ('GH001','QUYNHPTA','MA001','MA002') and b.tenquanlyvung in('Nguyễn Thọ Chiến','Vũ Mừng')
qualify row_number() over (partition by custid,slsperid order by thang desc,cast(crtd_date as date) desc) =1
-- where  loc = 1

),
tuyen_cvbh_hd_lichsu as
(

SELECT 
b.custid,a.slsperid
 FROM `spatial-vision-343005.staging.d_oricontractdet` a 
INNER JOIN `spatial-vision-343005.staging.d_oricontract` b on a.contractid = b.contractid
qualify row_number() over (partition by custid order by genlupd_datetime desc) = 1

),
-- mapping_mcp_hd as (
-- select * from tuyen_dms_moinhat
-- UNION Distinct
-- select * from tuyen_dms_bytime
-- UNION Distinct
-- select * from tuyen_cvbh_hd
-- ),
mapping_crs as (
select * from tuyen_dms_moinhat
UNION Distinct
select * from tuyen_dms_bytime
UNION Distinct
select * from tuyen_cvbh_hd
-- select custid,slsperid
-- from mapping_mcp_hd 
-- UNION distinct
-- select makhdms,manv
--  from `staging.d_phutrachno_hcp_v2` 
UNION distinct
select custid,slsperid
 from tuyen_cvbh_hd_lichsu

)

SELECT 
a.* ,
 round ( (a.sotien * 0.8/100)/1000,0)*1000  as thuongkpi,
b.col.ma_nvbh as manv,
b.tencvbh as CRSS,
cast( current_datetime ("+7") as timestamp) as updated_at

FROM f_doanhthu_ins_v2_1 a 
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` b on a.custid = b.custid

  );

Create or replace table `warehouse.f_doanhthu_hcp_crs`

copy `staging_temp.f_doanhthu_hcp_crs_temp`;

End;