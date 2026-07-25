CREATE TABLE FUNCTION `spatial-vision-343005`.staging_temp.api_congno_khach_hang_table(p_ma_crs STRING)
AS
with 

-------------------------------------------------------------*Tính toán phân loại công nợ*-----------------------------------------------------------------------

mapping_customer as (
select 
a.slsperid,
a.BranchID,
a.* except(terms,paymentsform,BranchID,slsperid),
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

 from `staging_temp.d_rawdata_debt`  a
LEFT JOIN `staging.d_master_khachhang` b1 on a.custid =b1.custid --and date(dateoforder)>='2023-01-01'
where 
-- b1.channel in ('INS','PCL','CLC') 
-- and (so_du_dh >1000 or so_du_dh <-1000) 
(left(lower(custname),5) <> 'xuất ' or lower(custname) not like '%anh sách%' or lower(custname) not like '%quà%')

),


mapping_customer0 as (
select 
   Case 
      when b.refcustid = 'TD42I004A' then 'MR001'
      when b.refcustid = 'TT55I011A' then 'MR001'
   else b.branchid end as branchid,
   b.ordnbr as ordernbr,
   date(b.dateoforder) AS dateoforder,
   b.custid,
   Case 
      when b.refcustid = 'TD42I004A' then 'TD42I004'
      when b.refcustid = 'TT55I011A' then 'TT55I011'
      when b.refcustid = 'TD42I025A' then 'TD42I025'
   else b.refcustid end as refcustid,
   b.InvcNbr,
   date(b.orderdate) as orderdate,
   so_du_chungtu ,
   sotien_da_thanhtoan,
   b.duedate,
   b.paymentsform,
   e.dueintnv as day_terms,
   Case when f.makh is not null and e.descr ='Gối 1 Đơn Hàng (trong 30 ngày)' then 'Gối 1 Đơn Hàng (cuối tháng)'
   else e.descr end as terms,
   b.doctype,
   b.docdesc,
   b.channel,
   b.shoptype,
   b.statedescr as tinh,
   b.territorydescr as khuvuc,
   b.custname,
   is_diadiem,
   so_du_dh,
   b.mahd_so
 from mapping_customer b
  LEFT JOIN staging.d_manual_terms_detail e on e.termsid =b.terms
  LEFT JOIN staging.d_manual_ds_kh_theodoi_pcl f on f.makh = b.custid

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

date_trunc(dateoforder,month) as thang_chungtu,
date_trunc(orderdate,month) as thang_thu

 
  from mapping_mau_no 
)
,
data_debt_ins2_1 as 
( select  *,
Case when so_du_dh >1000 or so_du_dh <-1000 then date_diff(current_date("+7"), date(dateoforder),day)
      when  (so_du_dh <=1000 and so_du_dh >=-1000) then date_diff(orderdate, date(dateoforder),day)
      else 0 end as thoigian_no,
Case when so_du_dh >1000 or so_du_dh <-1000 and phanloaino in('Nợ vàng','Nợ đỏ','Nợ đen') then date_diff(current_date("+7"), date(thoi_diem_no_vang),day)
      when (so_du_dh <=1000 and so_du_dh >=-1000) and phanloaino in('Nợ vàng','Nợ đỏ','Nợ đen') then date_diff(orderdate, date(thoi_diem_no_vang),day)
      else 0 end as thoigian_noqh,
Case when so_du_dh >1000 or so_du_dh <-1000 and phanloaino in('Nợ đỏ','Nợ đen') then date_diff(current_date("+7"), date(thoi_diem_no_do),day)
      when (so_du_dh <=1000 and so_du_dh >=-1000) and phanloaino in('Nợ đỏ','Nợ đen') then date_diff(orderdate, date(thoi_diem_no_do),day)
      else 0 end as thoigian_noxau
 from mapping_phanloaino
 ),
	
	-- Tính toán phân loại nợ theo đơn hàng
result as 
( SELECT a.*,

Case when phanloaino ='Nợ xanh' then so_du_chungtu else 0 end as no_xanh,
Case when phanloaino ='Nợ vàng' then so_du_chungtu else 0 end as no_vang,

Case when phanloaino ='Nợ đỏ' then so_du_chungtu else 0 end as no_do,

Case when phanloaino ='Nợ đen' then so_du_chungtu else 0 end as no_den,

Case when phanloaino in('Nợ đỏ','Nợ đen') then so_du_chungtu else 0 end as no_xau,


from data_debt_ins2_1 a
 ),

	
phanloai_nokh as (
	SELECT *,
	Case when a.phanloaino  = 'Nợ xanh' then 1
			 when a.phanloaino  =  'Nợ vàng'  then 2
			 when a.phanloaino  =  'Nợ đỏ'  then 3
			 when a.phanloaino  =  'Nợ đen' then 4
   else 1
  end	as vungno_kh

  from result a

),
	
	--Tính vùng nợ KH
vungnokh as ( 
SELECT custid,max(phanloai_nokh.vungno_kh) as phanloai_vungno from phanloai_nokh 
		where doctype <>'CM' --- Đơn hàng chiết khấu nên k tính vùng nợ cho KH dc
		GROUP BY custid
		),

		-- Thời gian nợ xa nhất của KH
max_thoigianno as ( 
SELECT custid,
		max(thoigian_no) as max_thoigian_no,
		max(thoigian_noqh) as max_thoigian_nqh,
		max(thoigian_noxau) as max_thoigian_noxau,
		min(date(dateoforder)) as min_ngaychungtu,
		min(thoi_diem_no_vang) as thoi_diem_no_vang ,
    min(thoi_diem_no_do) as thoi_diem_no_do,
    min(thoi_diem_no_den ) as thoi_diem_no_den
		from result
		 GROUP BY 1
		),

mapping_ngaytoihan_no as (
select a.*,b.phanloai_vungno as vungno_kh 
from max_thoigianno a 
LEFT JOIN vungnokh b on a.custid =b.custid 
where b.phanloai_vungno > 1
),

	---Map nhân viên bán hàng CRSS, CRM/A.CRM , S.CRM và tính toán vùng nợ KH
phanloai_nokh1 as (
	SELECT a.*except(vungno_kh),
	Case when b.phanloai_vungno  = 1 then 'Nợ xanh'
			 when b.phanloai_vungno  = 2 then 'Nợ vàng'
			 when b.phanloai_vungno  = 3 then 'Nợ đỏ'
			 when b.phanloai_vungno  = 4 then 'Nợ đen'
			 else 'Nợ xanh'
  end	as vungno_kh,
	c.max_thoigian_no as ngay_dh_xa_nhat,
	--  c.min_ngaydatdon,
	c.max_thoigian_nqh,
	c.min_ngaychungtu as min_ngaydatdon,
	c.thoi_diem_no_den as ngaytoihan_noden_kh,
	c.thoi_diem_no_do as ngaytoihan_nodo_kh
  from phanloai_nokh a
	LEFT JOIN 
	vungnokh  b on a.custid = b.custid 
	LEFT JOIN 
	max_thoigianno  c on a.custid = c.custid 

	)
,

f_congno_ins2_1 as (

SELECT 
 	A.*except(dateoforder,phanloaino,shoptype,so_du_chungtu),
	so_du_chungtu as tiennocongty,
	phanloaino as phanloai_no,
	shoptype as kenhphu,
	dateoforder as ngaydatdon,
	dateoforder as ngaychungtu,


 	from phanloai_nokh1 a 

),
----Mapping CRS
tuyen_dms_moinhat as 
(
with data_tuyen as (
SELECT custid,slsperid,crtd_datetime,
Case when routetype in ('B','D') then 1 else 2 end as routetype,
FROM `spatial-vision-343005.staging.sync_dms_srm`  a 
LEFT JOIN `staging.d_users` b on a.slsperid =b.manv

where delroutedet is false

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

where delroutedet is false 

)

select custid,slsperid
from data_tuyen
qualify row_number() over (partition by custid order by thang desc,routetype asc,crtd_datetime desc) =1
),


tuyen_cvbh_hd_moinhat as 
(

select custid,slsperid
from `spatial-vision-343005.staging.d_get_contract_det`  a
LEFT JOIN `staging.d_users` b on a.slsperid =b.manv
where slsperid not in ('GH001','QUYNHPTA','MA001','MA002') and b.tenquanlyvung ='Nguyễn Thọ Chiến'
 QUALIFY  row_number() over (partition by custid order by cast(crtd_date as date) desc) =1
),
tuyen_cvbh_hd_bytime as 
(
select custid,slsperid
from `spatial-vision-343005.staging.d_get_contract_det_bytime`  a
LEFT JOIN `staging.d_users` b on a.slsperid =b.manv
LEFT JOIN `staging.d_hr_dsns` c on a.slsperid =c.msnvcsmmoi
where slsperid not in ('GH001','QUYNHPTA','MA001','MA002') and b.tenquanlyvung ='Nguyễn Thọ Chiến'
and c.msnvcsmmoi is not null
 QUALIFY  row_number() over (partition by custid order by a.thang desc,cast(crtd_date as date) desc) =1

),
tuyen_cvbh_hd_lichsu as
(
SELECT 
b.custid,a.slsperid
 FROM `spatial-vision-343005.staging.d_oricontractdet` a 
INNER JOIN `spatial-vision-343005.staging.d_oricontract` b on a.contractid = b.contractid
LEFT JOIN `staging.d_users` c on c.manv =a.slsperid
where c.tenquanlyvung ='Nguyễn Thọ Chiến'
qualify row_number() over (partition by custid order by genlupd_datetime desc) = 1

),
mapping_mcp_hd as (
select *,1 as datatype from tuyen_dms_moinhat
UNION distinct
select *,3 as datatype from tuyen_dms_bytime
UNION distinct
select *,2 as datatype from tuyen_cvbh_hd_moinhat
UNION distinct
select *,4 as datatype from tuyen_cvbh_hd_bytime
),

result_mapping_crs0 as (
select custid,slsperid,datatype
from mapping_mcp_hd 
UNION ALL
select custid,slsperid,6 as datatype
 from tuyen_cvbh_hd_lichsu
UNION ALL
select makhdms,manv,5 as datatype
 from `staging.d_phutrachno_hcp_v2`
)
,
result_mapping_crs as (
   select * from result_mapping_crs0
   qualify row_number() over (partition by custid order by datatype ) =1
)

SELECT 
a.custid as ma_kh_dms,
a.custname as ten_kh,
a.paymentsform as hinh_thuc_thanh_toan,
c.slsperid as ma_crs,
Case when c.slsperid ='CX' then 'CX' else d.tencvbh end as ten_crs, 
Case when c.slsperid ='CX' then 'MR1682' else d.supid end as ma_crm,
Case when c.slsperid ='CX' then 'Đinh Thị Ngọc Mẫn' else d.tenquanlytt end as ten_crm,
sum(tiennocongty) as no_goc,
sum(no_xau) as no_xau,
-- round(safe_divide(sum(no_xau),sum(tiennocongty)) *100,2) as ti_le_no_xau

FROM f_congno_ins2_1 a 
LEFT JOIN `staging.d_master_khachhang` b1 on a.custid =b1.custid 
LEFT JOIN result_mapping_crs c on c.custid =a.custid
LEFT JOIN `staging.d_users` d on c.slsperid =d.manv
where contains_substr(c.slsperid,p_ma_crs)
group by 1,2,3,4,5,6,7
-- having no_goc >1000 or no_goc <-1000
having no_goc <>0
order by slsperid,no_goc desc;