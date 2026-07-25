CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_data_debt_ins2_1()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.data_debt_ins2_1_temp`;

 INSERT INTO `staging_temp.data_debt_ins2_1_temp`

(   


-- Create or replace table `staging_temp.data_debt_ins2_1_temp`
-- as

with 

-------------------------------------------------------------*Tính toán phân loại công nợ*-----------------------------------------------------------------------

----Mapping gối đầu 30 ngày

mapping_customer as (
select a.* except(terms,paymentsform),
a.terms,
Case when b1.statedescr in ('Thành phố Cần Thơ','Đồng Nai','Khánh Hòa','Nghệ An',
'Thành phố Đà Nẵng','Thành phố Hà Nội','Thành phố Hồ Chí Minh') then 'VP chi nhánh'
else 'Tỉnh' end as is_diadiem,
b1.channel as channel,
b1.shoptype as shoptype,
b1.statedescr as statedescr,
b1.custname as custname,
b1.paymentsform as paymentsform,
b1.refcustid as refcustid,
b1.territorydescr as territorydescr,

-- Case  when ordernbr in('DH122018-17643','DH062018-13754') then 'CS'
--       when trim(b.paymentsform) in ('B','C') and ifnull(e.shoptype,b.shoptype) in ('NT','PK','SI') then 'MDS'
--       when trim(a.paymentsform) in ('B','C') and ifnull(e.shoptype,b.shoptype) in ('CHUOI') and terms like '%Thu tiền ngay%' then 'MDS'
--     -- when trim(b.paymentsform) ='Tiền Mặt/Chuyển Khoản' and b.channel not in ('DLPP','CLC') then 'MDS'
--      else 'CS' end as debtincharge, 
 from `staging_temp.d_rawdata_debt`  a
-- LEFT JOIN `staging.d_master_khachhang2022` b on a.custid =b.custid and date(dateoforder) <'2023-01-01'
LEFT JOIN `staging.d_master_khachhang` b1 on a.custid =b1.custid --and date(dateoforder)>='2023-01-01'
-- LEFT JOIN `spatial-vision-343005.staging.sync_dms_historycustclass` e on e.version = a.Version
-- LEFT JOIN goi_dau_30ngay c on a.custid =c.custid and a.ordnbr =c.ordernbr and a.branchid=c.branchid
-- where a.custid in ('N0310320','N0110742')
where b1.channel in ('INS','PCL','CLC') 
and (so_du_dh >1000 or so_du_dh <-1000) 
and (left(lower(custname),5) <> 'xuất ' or lower(custname) not like '%anh sách%' or lower(custname) not like '%quà%')

),

tttt_ins as (
select * from (
SELECT a.manv,a.makhcu,a.thongtinthanhtoan,a.thoigiangoi,
row_number() over(partition by makhcu order by thoigiangoi desc,inserted_at desc) as loc  
FROM `spatial-vision-343005.staging.d_tttt_ins` a where thoigiangoi >='2023-04-30'
) where loc =1
),

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

mapping_customer0 as (
select 
	Case when b.refcustid = 'TD42I004A' then 'MR001'
				 when b.refcustid = 'TT55I011A' then 'MR001'
				 else b.branchid end as branchid,
  b.ordnbr as ordernbr,
  date(b.dateoforder) AS dateoforder,
  b.custid,
  Case when b.refcustid = 'TD42I004A' then 'TD42I004'
	   	  when b.refcustid = 'TT55I011A' then 'TT55I011'
				 when b.refcustid = 'TD42I025A' then 'TD42I025'
				 else b.refcustid end as refcustid,
  b.InvcNbr,
  date(b.orderdate) as orderdate,
  	sotien_nogoc,
		so_du_chungtu ,
		sotien_da_thanhtoan,
  b.duedate,
	b.paymentsform,
	-- b.terms,
--   Case when b.terms ='01' then 1 
--          when b.terms ='03' then 3 
--          when b.terms ='O1' then 30 
--          else
--   safe_cast (trim(REGEXP_REPLACE(e.descr, '[^0-9 ]','')) as numeric  ) end as day_terms,
e.dueintnv as day_terms,
  e.descr as terms,
--   e.dueintnv as day_terms,

  b.doctype,
	b.docdesc,
	-- b.updated_at,
  		-- Case 
   --  when d.manv is not null then d.manv
	-- 	when d.manv is null and b.territorydescr in ('Bắc Trung Bộ','Đông Nam 1','Đông Nam 2','Hồ Chí Minh 1','Hồ Chí Minh 2','Hồ Chí Minh Sĩ/Chuỗi','Miền Đông 1','Miền Đông 2','Nam Trung Bộ') then 'MR1432'
	-- 	when d.manv is null and b.territorydescr in ('Đông Bắc 1','Đông Bắc 2','Hà Nội 1','Hà Nội 2','Hà Nội Sĩ/Chuỗi','Mê Kông 1','Mê Kông 2','Tây Bắc HN')
	-- 	then 'MR2663' 
	-- 	else 'MR0292'
	-- 	end as 
    cast( null as string) as manv,
	-- b.slsperid as manv,
   b.channel,
	b.shoptype,
	b.statedescr as tinh,
	b.territorydescr as khuvuc,
	b.custname,
  concat(date(g.thoigiangoi),': ',g.thongtinthanhtoan) as thongtinthanhtoan,
  date(g.thoigiangoi) as thoigiangoi,
  is_diadiem,
  so_du_dh,
  b.mahd_so
 from mapping_customer b
 	-- LEFT JOIN d_phutrachno_ins d on d.makhcu=b.refcustid   
  LEFT JOIN tttt_ins g on g.makhcu = b.custid
  LEFT JOIN staging.d_manual_terms_detail e on e.termsid =b.terms

),

mapping_mau_no as (
select *, 
Case 
    when day_terms <=3 and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 1 day)   
    when day_terms <=3 and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 3 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 2 day) 
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 4 day) 

    when day_terms <=15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 2 day) 
    when day_terms <=15
     and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 4 day) 
    
    when day_terms > 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 2 day) 
     when day_terms > 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 4 day) 
 
 
  else  null

 end as thoi_diem_no_vang,


 Case 
    when day_terms <=3 and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 6 day)   
    when day_terms <=3 and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 8 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 7 day) 
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 9 day) 

    when day_terms <= 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 17 day) 
    when day_terms <= 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 19 day) 
    
    when day_terms > 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 32 day) 
     when day_terms > 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 34 day) 
 
 
  else  null

 end as thoi_diem_no_do,
 Case 
    when day_terms <= 3 and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 10 day)   
    when day_terms <= 3 and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 12 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 11 day) 
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 13 day) 

    when day_terms <= 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 32 day) 
    when day_terms <= 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 34 day) 
    
    when day_terms > 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(duedate),interval 62 day) 
     when day_terms > 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(duedate),interval 64 day) 
 
  else  null

 end as thoi_diem_no_den

 from mapping_customer0 ),


mapping_phanloaino as (

 select *,
Case 
   -- when doctype ='CM' then 'Nợ xanh' 
   when current_date("+7")  
 >= thoi_diem_no_den and (so_du_dh > 1000 or so_du_dh < -1000) then 'Nợ đen'
     when current_date("+7")
  < thoi_diem_no_den and (so_du_dh > 1000 or so_du_dh < -1000)  and current_date("+7")
 >= thoi_diem_no_do  then 'Nợ đỏ'
     when current_date("+7")
  < thoi_diem_no_do and (so_du_dh > 1000 or so_du_dh < -1000)  and current_date("+7")
  >= thoi_diem_no_vang  then 'Nợ vàng'
     when current_date("+7")
  < thoi_diem_no_vang and (so_du_dh > 1000 or so_du_dh < -1000)  then 'Nợ xanh'

     when date(orderdate) >= thoi_diem_no_den   and (so_du_dh <= 1000 and so_du_dh >= -1000)   then 'Nợ đen'
     when date(orderdate)  < thoi_diem_no_den   and (so_du_dh <= 1000 and so_du_dh >= -1000)   and date(orderdate)  >= thoi_diem_no_do  then 'Nợ đỏ'
     when date(orderdate)  < thoi_diem_no_do   and (so_du_dh <= 1000 and so_du_dh >= -1000)   and date(orderdate)  >= thoi_diem_no_vang   then 'Nợ vàng'
     when date(orderdate)  < thoi_diem_no_vang and (so_du_dh <= 1000 and so_du_dh >= -1000)     then 'Nợ xanh'
    --  when date(orderdate) is null
     when date(orderdate) is null and (so_du_dh <= 1000 and so_du_dh >= -1000) then 'Nợ xanh'
      when date(orderdate) is null
      and thoi_diem_no_den <= current_date("+7")
 then 'Nợ đen'
     when date(orderdate) is null and thoi_diem_no_do <= current_date("+7")
 then 'Nợ đỏ'
     when date(orderdate) is null and thoi_diem_no_vang <= current_date("+7")
 then 'Nợ vàng'
     when date(orderdate) is null and thoi_diem_no_vang >current_date("+7")
 then 'Nợ xanh'
else null
end as phanloaino,

-- Case when orderdate is not null then date_diff (date(orderdate),dateoforder,day)
--      when orderdate is null then date_diff(current_date("+7")
-- ,dateoforder,day)
-- else null 
-- end as songay_no,
-- Case when orderdate is not null then date_diff (date(orderdate),dateoforder,month)
--      when orderdate is null then date_diff(current_date("+7")
-- ,dateoforder,month)
-- else null 
-- end as sothang_no,
date_trunc(dateoforder,month) as thang_chungtu,
date_trunc(orderdate,month) as thang_thu

 
  from mapping_mau_no 
)

select  *,
Case when so_du_dh >1000 or so_du_dh <-1000 then date_diff(current_date("+7"), date(dateoforder),day)
      when  (so_du_dh <=1000 and so_du_dh >=-1000) then date_diff(orderdate, date(dateoforder),day)
      --  when orderdate is  null and  (so_du_dh <=1000 and so_du_dh >=-1000) then 0
      --  when orderdate is  null then date_diff(current_date("+7"), date(dateoforder),day)
      else 0 end as thoigian_no,
Case when so_du_dh >1000 or so_du_dh <-1000 and phanloaino in('Nợ vàng','Nợ đỏ','Nợ đen') then date_diff(current_date("+7"), date(thoi_diem_no_vang),day)
      when (so_du_dh <=1000 and so_du_dh >=-1000) and phanloaino in('Nợ vàng','Nợ đỏ','Nợ đen') then date_diff(orderdate, date(thoi_diem_no_vang),day)
      else 0 end as thoigian_noqh,
Case when so_du_dh >1000 or so_du_dh <-1000 and phanloaino in('Nợ đỏ','Nợ đen') then date_diff(current_date("+7"), date(thoi_diem_no_do),day)
      when (so_du_dh <=1000 and so_du_dh >=-1000) and phanloaino in('Nợ đỏ','Nợ đen') then date_diff(orderdate, date(thoi_diem_no_do),day)
      else 0 end as thoigian_noxau

 from mapping_phanloaino
--  where custid ='M0702002'


-- where ordernbr ='DH0-0123-00221'

);

Create or replace table `staging_temp.data_debt_ins2_1`

copy `staging_temp.data_debt_ins2_1_temp`;


END;