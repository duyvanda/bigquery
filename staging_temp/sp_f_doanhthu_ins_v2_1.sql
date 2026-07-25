CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_doanhthu_ins_v2_1()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_doanhthu_ins_v2_1_temp`;


 INSERT INTO `staging_temp.f_doanhthu_ins_v2_1_temp`

(   
-- Create or replace table staging_temp.f_doanhthu_ins_v2_1_temp
-- partition by date(ngaythu_ge)
-- cluster by state,custname,territory,tencvbh
-- as 
with 
nv_thaythe as 
(
select manv,nhanvien_thaythe from (
SELECT *,row_number() over (partition by manv order by inserted_at desc ) as loc FROM `spatial-vision-343005.staging.d_phanquyen_trading` 
where trangthaihoatdong ='Đã nghỉ' and kenhphutrach='INS') a
where loc =1
),
--- Nhân viên thay thế
-- d_phutrachno_ins as 
-- (
-- select a.*except (manv),ifnull(b.nhanvien_thaythe,a.manv) as manv from `staging.d_phutrachno_ins`  a 
-- LEFT JOIN nv_thaythe b on a.manv =b.manv
-- ),
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


-- Case when b.statedescr in ('Thành phố Cần Thơ','Đồng Nai','Khánh Hòa','Nghệ An',
-- 'Thành phố Đà Nẵng','Thành phố Hà Nội','Thành phố Hồ Chí Minh') then 'VP chi nhánh'
-- else 'Tỉnh' end as is_diadiem,
-- b.channel as channels,
-- b.shoptype as subchannel,
-- b.terms,
-- b.custname,
-- b.territorydescr,
-- b.refcustid,
-- b.statedescr as state 
-- b1.terms as terms,
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
-- Case when b.thuongkpi is null then round( ( a.DebConfirmAmtRelease * 0.8/100)/1000,0)*1000
-- else round ( (a.DebConfirmAmtRelease * b.thuongkpi/100)/1000,0)*1000 end as thuongkpi,
a.orderdate as ngaythu_dms,
a.orderdate,
-- Case 
-- 		when b.manv is null and a.territorydescr in ('Bắc Trung Bộ','Đông Nam 1','Đông Nam 2','Hồ Chí Minh 1','Hồ Chí Minh 2','Hồ Chí Minh Sĩ/Chuỗi','Miền Đông 1','Miền Đông 2','Nam Trung Bộ') then 'MR1432'
-- 		when b.manv is null and a.territorydescr in ('Đông Bắc 1','Đông Bắc 2','Hà Nội 1','Hà Nội 2','Hà Nội Sĩ/Chuỗi','Mê Kông 1','Mê Kông 2','Tây Bắc HN')
-- 		then 'MR2629' 
-- 		when b.manv is null then 'MR0292'else b.manv 
-- 		end as manv,
-- Case 
-- 				when b.manv ='MR1432' then 'Lương Tấn Khả'
-- 				when b.manv ='MR2663' then 'Hà Bảo Châu'
-- 				when b.manv ='MR2629' then 'Nguyễn Thị Mỹ Thanh'
-- 				when b.manv is null and a.territorydescr in ('Bắc Trung Bộ','Đông Nam 1','Đông Nam 2','Hồ Chí Minh 1','Hồ Chí Minh 2','Hồ Chí Minh Sĩ/Chuỗi','Miền Đông 1','Miền Đông 2','Nam Trung Bộ') then 'Lương Tấn Khả'
-- 		when b.manv is null and a.territorydescr in ('Đông Bắc 1','Đông Bắc 2','Hà Nội 1','Hà Nội 2','Hà Nội Sĩ/Chuỗi','Mê Kông 1','Mê Kông 2','Tây Bắc HN')
-- 		then 'Hà Bảo Châu' 
-- when c.tencvbh is null then 'Đỗ Thị Hồng Thủy' else c.tencvbh end as tencvbh,
-- Case 
-- 				when b.manv ='MR1432' then 'Lương Tấn Khả'
-- 				when b.manv ='MR2663' then 'Hà Bảo Châu'
-- 				when b.manv ='MR2629' then 'Nguyễn Thị Mỹ Thanh'
-- 				when b.manv is null and a.territorydescr in ('Bắc Trung Bộ','Đông Nam 1','Đông Nam 2','Hồ Chí Minh 1','Hồ Chí Minh 2','Hồ Chí Minh Sĩ/Chuỗi','Miền Đông 1','Miền Đông 2','Nam Trung Bộ') then 'Lương Tấn Khả'
-- 				when b.manv is null and a.territorydescr in ('Đông Bắc 1','Đông Bắc 2','Hà Nội 1','Hà Nội 2','Hà Nội Sĩ/Chuỗi','Mê Kông 1','Mê Kông 2','Tây Bắc HN')
-- 		then 'Hà Bảo Châu' 
-- 				when c.tenquanlytt is null then 'Đỗ Thị Hồng Thủy' else c.tenquanlytt end as tenquanlytt,
-- Case 
-- 				when b.manv ='MR1432' then 'Lương Tấn Khả'
-- 				when b.manv ='MR2663' then 'Hà Bảo Châu'
-- 				when b.manv ='MR2629' then 'Nguyễn Thị Mỹ Thanh'
-- 				when b.manv is null and a.territorydescr in ('Bắc Trung Bộ','Đông Nam 1','Đông Nam 2','Hồ Chí Minh 1','Hồ Chí Minh 2','Hồ Chí Minh Sĩ/Chuỗi','Miền Đông 1','Miền Đông 2','Nam Trung Bộ') then 'Lương Tấn Khả'
-- 				when b.manv is null and a.territorydescr in ('Đông Bắc 1','Đông Bắc 2','Hà Nội 1','Hà Nội 2','Hà Nội Sĩ/Chuỗi','Mê Kông 1','Mê Kông 2','Tây Bắc HN')
-- 		then 'Hà Bảo Châu' 
-- 				when c.tenquanlykhuvuc is null then 'Đỗ Thị Hồng Thủy' else c.tenquanlykhuvuc end as tenquanlykhuvuc,
-- Case when c.tenquanlyvung is null then 'Đỗ Thị Hồng Thủy' else c.tenquanlyvung end as tenquanlyvung,
-- -- a.inserted_at,
-- c.supid as ma_crm,
-- c.asm as ma_scrm,
-- Left(c.rsmid,6) as ma_ncxm
cast(null as string) as manv,
cast(null as string) as tencvbh,
cast(null as string) as tenquanlytt,
cast(null as string) as tenquanlykhuvuc,
cast(null as string) as tenquanlyvung,
cast(null as string) as ma_crm,
cast(null as string) as ma_scrm,
cast(null as string) as ma_ncxm


 FROM data_doanhthu_moi a
--  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` d on d.custid =a.custid 
--  LEFT JOIN d_phutrachno_ins b on a.refcustid =b.makhcu
--  LEFT JOIN `spatial-vision-343005.staging.d_users` c on b.manv =c.manv
 where DebConfirmAmtRelease <> 0
--  where DebConfirmAmtRelease >1000 
 ),


result as (
 select a.*,
   Case when  e.madonhang =a.ordernbr and e.makhcu =a.refcustid then e.ngaythu_ge
  else Cast ( a.ngaythu_dms as timestamp) end as ngaythu_ge,
	m.canhbao_noxau,


	-- Câp nhật cho các bạn CRM/SRCM download theo khu vực phụ trách
	Case when a.state in ('Lâm Đồng','Bình Phước','Đắk Nông','Đắk Lắk','Gia Lai','Kon Tum') then 'MR1260' --'dsminhnhan@gmail.com' --Chu Minh Nhàn
			 when a.state in ('Bình Dương','Tây Ninh') then 'MR0538' --'canh.oseven@gmail.com' -- Lâm Văn Cảnh --thuộc SCRM
			 when a.state in ('Đồng Nai','Bà Rịa - Vũng Tàu') then 'MR0294' --'thanhphucmai@gmail.com' --Mai Thị Thanh Phúc
			 
			 when a.state in ('Hà Nam','Nam Định','Ninh Bình','Thái Bình','Hà Tĩnh','Nghệ An','Thanh Hóa') then 'MR0081' --'cuonghv0702@gmail.com' --Hồ Văn Cường -- Đã nghỉ chuyển qua cho a Chiến
			 when a.state in ('Đồng Tháp','Trà Vinh','Vĩnh Long','An Giang','Bạc Liêu','Cà Mau','Thành phố Cần Thơ','Hậu Giang','Kiên Giang','Sóc Trăng')
			 then 'MR0843' --'giavinh84@gmail.com'-- Trần Gia Vĩnh
			 when a.state in ('Bình Định','Thành phố Đà Nẵng','Thừa Thiên - Huế','Quảng Bình','Quảng Nam','Quảng Ngãi','Quảng Trị')  
			 then 'MR0992' --'nguyenhongha0810628@gmail.com' --Nguyễn Thị Hồng Hà
			 when a.state in ('Bình Thuận','Khánh Hòa','Ninh Thuận','Phú Yên') then 'MR0055' --'phanthibinhkhe@gmail.com' -- Phan Thị Bình Khê
			 when a.state in ('Thành phố Hồ Chí Minh') then 'MR2383' --'thuymerap1985@gmail.com' -- Lý Hương Thủy
			 when a.state in ('Thành phố Hà Nội') then '' --Nguyễn Thị Lý -- CRS nên k có cập nhật để trống 
			 when a.state in ('Hải Dương','Hải Phòng','Hưng Yên','Quảng Ninh','Bắc Giang','Bắc Ninh','Lạng Sơn','Bắc Kạn','Cao Bằng',
			 'Điện Biên','Hà Giang','Hòa Bình','Lai Châu','Lào Cai','Phú Thọ','Sơn La','Thái Nguyên','Tuyên Quang','Vĩnh Phúc','Yên Bái'
			 ) then 'MR2355' --'mr.donbacninh99@gmail.com' -- Nguyễn Văn Đôn
			 when a.state in ('Bến Tre','Long An','Tiền Giang') then '' --Trà Huỳnh Ý -- CRS nên k có cập nhật để trống 
			 else null
	end as filter_email_khuvuc_crm,

		Case when a.state in ('Lâm Đồng','Bình Phước','Đắk Nông','Đắk Lắk','Gia Lai','Kon Tum') then 'MR0538' --'canh.oseven@gmail.com' --Lâm Văn Cảnh
			 when a.state in ('Bình Dương','Tây Ninh') then 'MR0538' --'canh.oseven@gmail.com' -- Lâm Văn Cảnh
			 when a.state in ('Đồng Nai','Bà Rịa - Vũng Tàu') then 'MR0538'  --'canh.oseven@gmail.com' --Lâm Văn Cảnh
			 
			 when a.state in ('Hà Nam','Nam Định','Ninh Bình','Thái Bình','Hà Tĩnh','Nghệ An','Thanh Hóa') then 'MR0081' --'nguyenthochien2015@gmail.com' --Nguyễn Thọ Chiến
			 when a.state in ('Đồng Tháp','Trà Vinh','Vĩnh Long','An Giang','Bạc Liêu','Cà Mau','Thành phố Cần Thơ','Hậu Giang','Kiên Giang','Sóc Trăng')
			 then  'MR0081' --'nguyenthochien2015@gmail.com'-- Nguyễn Thọ Chiến
			 when a.state in ('Bình Định','Thành phố Đà Nẵng','Thừa Thiên - Huế','Quảng Bình','Quảng Nam','Quảng Ngãi','Quảng Trị')  then 'MR0055' --'phanthibinhkhe@gmail.com'--Phan Thị Bình Khê
			 when a.state in ('Bình Thuận','Khánh Hòa','Ninh Thuận','Phú Yên') then  'MR0055' --'phanthibinhkhe@gmail.com' -- Phan Thị Bình Khê
			 when a.state in ('Thành phố Hồ Chí Minh') then 'MR1137' --'happyvu76@gmail.com' -- Vũ Mừng
			 when a.state in ('Thành phố Hà Nội') then  'MR1137' --'happyvu76@gmail.com' --Vũ Mừng
			 when a.state in ('Hải Dương','Hải Phòng','Hưng Yên','Quảng Ninh','Bắc Giang','Bắc Ninh','Lạng Sơn','Bắc Kạn','Cao Bằng',
			 'Điện Biên','Hà Giang','Hòa Bình','Lai Châu','Lào Cai','Phú Thọ','Sơn La','Thái Nguyên','Tuyên Quang','Vĩnh Phúc','Yên Bái'
			 ) then 'MR1137'  --'happyvu76@gmail.com' -- Vũ Mừng
			 when a.state in ('Bến Tre','Long An','Tiền Giang') then  'MR1137' --'happyvu76@gmail.com' --Vũ Mừng
			 else null end as filter_email_khuvuc_scrm

  from data_doanhthu a
  LEFT JOIN `spatial-vision-343005.staging.d_doanhthu_donhang` e on e.madonhang =a.ordernbr and e.makhcu =a.refcustid
	LEFT JOIN (select distinct custid,canhbao_noxau from `view_report.f_congno_ins2_1`) m on m.custid =a.custid
	
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

--      when date(orderdate) >= thoi_diem_no_den   and (so_du_dh <= 1000 and so_du_dh >= -1000)   then 'Nợ đen'
--      when date(orderdate)  < thoi_diem_no_den   and (so_du_dh <= 1000 and so_du_dh >= -1000)   and date(orderdate)  >= thoi_diem_no_do  then 'Nợ đỏ'
--      when date(orderdate)  < thoi_diem_no_do   and (so_du_dh <= 1000 and so_du_dh >= -1000)   and date(orderdate)  >= thoi_diem_no_vang   then 'Nợ vàng'
--      when date(orderdate)  < thoi_diem_no_vang and (so_du_dh <= 1000 and so_du_dh >= -1000)     then 'Nợ xanh'
--     --  when date(orderdate) is null
--      when date(orderdate) is null and (so_du_dh <= 1000 and so_du_dh >= -1000) then 'Nợ xanh'
--       when date(orderdate) is null
--       and thoi_diem_no_den <= current_date("+7")
--  then 'Nợ đen'
--      when date(orderdate) is null and thoi_diem_no_do <= current_date("+7")
--  then 'Nợ đỏ'
--      when date(orderdate) is null and thoi_diem_no_vang <= current_date("+7")
--  then 'Nợ vàng'
--      when date(orderdate) is null and thoi_diem_no_vang >current_date("+7")
--  then 'Nợ xanh'
else null
end as phanloai_no,
(select max(inserted_at) from `staging_temp.d_rawdata_debt_detail` where inserted_at is not null) as updated_at


 from mapping_mau_no b)

 select * from result_0  --where phanloai_no is null

);

Create or replace table `warehouse.f_doanhthu_ins_v2_1`

copy `staging_temp.f_doanhthu_ins_v2_1_temp`;


END;