-- ==========================================================================
-- Routine Name : sp_f_tongquan_doanhthu_congno_capture
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2026-06-22 10:34:55.047000+00:00
-- Last Altered : 2026-06-22 10:34:55.047000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_tongquan_doanhthu_congno_capture()
BEGIN
TRUNCATE TABLE staging_temp.f_tongquan_doanhthu_congno_capture_temp;
INSERT INTO staging_temp.f_tongquan_doanhthu_congno_capture_temp(
-- Create or replace table staging_temp.f_tongquan_doanhthu_congno_capture_temp
-- partition by thang
-- as
with

data_sales as
(
select makhdms,date(thang) as thang,count(distinct sodondathang) as sl_dh, sum(doanhsochuavat) as doanhsochuavat
 from `staging.f_sales`
  WHERE ngaychungtu >= '2021-12-01'
  AND LEFT(masanpham,1) != 'V'
      AND manv NOT IN ( 'GH001', 'MA001', 'MA002', 'QUYNHPTA')
      AND makenhkh not in ( 'NB','OTH_LAB')
      group by 1,2
),
mapping_customer as (
select a.*except(terms),
b1.terms,
b2.dueintnv as songay_thanhtoan,
-- sum(so_du_chungtu) over (partition by a.branchid,a.ordnbr,a.custid,a.invcnbr) as so_du_dh,
Case when b1.statedescr in ('Thành phố Cần Thơ','Đồng Nai','Khánh Hòa','Nghệ An',
'Thành phố Đà Nẵng','Thành phố Hà Nội','Thành phố Hồ Chí Minh') then 'VP chi nhánh'
else 'Tỉnh' end as is_diadiem,
b1.channel,
b1.shoptype,
b1.statedescr,
b1.custname,
b1.paymentsform,
b1.refcustid,
b1.hcotypeid,
 from `staging.d_rawdata_debt_capture`  a
LEFT JOIN `staging.d_master_khachhang` b1 on a.custid =b1.custid
LEFT JOIN staging.d_manual_terms_detail b2 on  trim(b2.descr) = trim(b1.Terms)
where b1.channel not in ('NB','OTH_LAB') and a.custid not in ('DSOTC-HN-001','DSOTC-HN--002')
),
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
 from mapping_customer

),
mapping_phanloaino as (

 select *,
Case when inserted_at
 >= thoi_diem_no_den and (so_du_dh > 1000 or so_du_dh <- 1000) then 'Nợ đen'
     when inserted_at
  < thoi_diem_no_den and  (so_du_dh > 1000 or so_du_dh <- 1000) and inserted_at
 >= thoi_diem_no_do then 'Nợ đỏ'
     when inserted_at
  < thoi_diem_no_do and  (so_du_dh > 1000 or so_du_dh <- 1000) and inserted_at
  >= thoi_diem_no_vang then 'Nợ vàng'
     when inserted_at
  < thoi_diem_no_vang and  (so_du_dh > 1000 or so_du_dh <- 1000) then 'Nợ xanh'

     when date(orderdate) >= thoi_diem_no_den   and so_du_dh <= 1000 and so_du_dh >=-1000 then 'Nợ đen'
     when date(orderdate)  < thoi_diem_no_den   and so_du_dh <=1000 and so_du_dh >=-1000   and date(orderdate)  >= thoi_diem_no_do then 'Nợ đỏ'
     when date(orderdate)  < thoi_diem_no_do   and so_du_dh <=1000 and so_du_dh >=-1000   and date(orderdate)  >= thoi_diem_no_vang then 'Nợ vàng'
     when date(orderdate)  < thoi_diem_no_vang and so_du_dh <=1000  and so_du_dh >=-1000  then 'Nợ xanh'
     when date(orderdate) is null and thoi_diem_no_den <= inserted_at
 then 'Nợ đen'
     when date(orderdate) is null and thoi_diem_no_do <= inserted_at
 then 'Nợ đỏ'
     when date(orderdate) is null and thoi_diem_no_vang <= inserted_at
 then 'Nợ vàng'
     when date(orderdate) is null and thoi_diem_no_vang >inserted_at
 then 'Nợ xanh'
else null
end as phanloaino

  from mapping_mau_no
),
phanloai_nokh as (
	SELECT *,
	Case when a.phanloaino  = 'Nợ xanh' then 1
			 when a.phanloaino  =  'Nợ vàng'  then 2
			 when a.phanloaino  =  'Nợ đỏ'  then 3
			 when a.phanloaino  =  'Nợ đen' then 4
   else null
  end	as vungno_kh,
  from mapping_phanloaino a
--   where  so_du_dh >1000 or so_du_dh < -1000
),
data_doanhthu_theovungno as (
with mapping_customer as (
select a.*except(terms),
b1.terms,
b2.dueintnv as songay_thanhtoan,
Case when b1.statedescr in ('Thành phố Cần Thơ','Đồng Nai','Khánh Hòa','Nghệ An',
'Thành phố Đà Nẵng','Thành phố Hà Nội','Thành phố Hồ Chí Minh') then 'VP chi nhánh'
else 'Tỉnh' end as is_diadiem,
b1.channel,
b1.shoptype,
b1.statedescr,
b1.custname,
b1.paymentsform,
b1.refcustid,
b1.hcotypeid,
 from `staging.d_rawdata_debt_detail_capture`  a
LEFT JOIN `staging.d_master_khachhang` b1 on a.custid =b1.custid
LEFT JOIN staging.d_manual_terms_detail b2 on  trim(b2.descr) = trim(b1.Terms)
where b1.channel not in ('NB','OTH_LAB') and a.custid not in ('DSOTC-HN-001','DSOTC-HN--002')
and date(a.inserted_at)= (select max(inserted_at) from `staging.d_rawdata_debt_capture`)
and orderdate is not null
and sotien_da_thanhtoan <>0
),
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

    when songay_thanhtoan <=15
     and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 17 day)
    when songay_thanhtoan <=15
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
    when songay_thanhtoan <=3 then
 date_add(date(duedate),interval 10 day)
    when songay_thanhtoan <=3 and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 12 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 11 day)
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then
 date_add(date(duedate),interval 13 day)

    when songay_thanhtoan <=15
     and is_diadiem ='VP chi nhánh' then
 date_add(date(duedate),interval 32 day)
    when songay_thanhtoan <=15
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
 from mapping_customer

),
mapping_phanloaino as (

 select *,
Case

     when date(orderdate) >= thoi_diem_no_den   and so_du_dh <= 1000 and so_du_dh >=-1000 then 'Nợ đen'
     when date(orderdate)  < thoi_diem_no_den   and so_du_dh <=1000 and so_du_dh >=-1000   and date(orderdate)  >= thoi_diem_no_do then 'Nợ đỏ'
     when date(orderdate)  < thoi_diem_no_do   and so_du_dh <=1000 and so_du_dh >=-1000   and date(orderdate)  >= thoi_diem_no_vang then 'Nợ vàng'
     when date(orderdate)  < thoi_diem_no_vang and so_du_dh <=1000  and so_du_dh >=-1000  then 'Nợ xanh'

else null
end as phanloaino

  from mapping_mau_no
)

select
custid,
date_trunc(orderdate,month) as thang_dt,
sum(Case when phanloaino ='Nợ xanh' then sotien_da_thanhtoan else 0 end) as sotien_da_thanhtoan_no_xanh,
sum(Case when phanloaino ='Nợ vàng' then sotien_da_thanhtoan else 0 end) as sotien_da_thanhtoan_no_vang,
sum(Case when phanloaino ='Nợ đỏ' then sotien_da_thanhtoan else 0 end) as sotien_da_thanhtoan_no_do,
sum(Case when phanloaino ='Nợ đen' then sotien_da_thanhtoan else 0 end) as sotien_da_thanhtoan_no_den,
sum(sotien_da_thanhtoan) as doanhthu_thang
 from mapping_phanloaino a
group by 1,2

),
max_vungno as (
select inserted_at,date_trunc(inserted_at,month) as thang,custid,custname,channel,statedescr,shoptype,terms,
max(vungno_kh) as vung_no,
sum(sotien_nogoc) as sotien_nogoc,
sum(sotien_da_thanhtoan) as sotien_da_thanhtoan,
sum(so_du_chungtu) as so_du_chungtu,
sum(Case when phanloaino='Nợ xanh' then sotien_nogoc else 0 end) as no_xanh_goc,
sum(Case when phanloaino='Nợ vàng' then sotien_nogoc else 0 end) as no_vang_goc,
sum(Case when phanloaino='Nợ đỏ' then sotien_nogoc else 0 end) as no_do_goc,
sum(Case when phanloaino='Nợ đen' then sotien_nogoc else 0 end) as no_den_goc,
sum(Case when phanloaino='Nợ xanh' then so_du_chungtu else 0 end) as no_xanh,
sum(Case when phanloaino='Nợ vàng' then so_du_chungtu else 0 end) as no_vang,
sum(Case when phanloaino='Nợ đỏ' then so_du_chungtu else 0 end) as no_do,
sum(Case when phanloaino='Nợ đen' then so_du_chungtu else 0 end) as no_den,
sum(Case when phanloaino='Nợ xanh' then sotien_da_thanhtoan else 0 end) as no_xanh_tt,
sum(Case when phanloaino='Nợ vàng' then sotien_da_thanhtoan else 0 end) as no_vang_tt,
sum(Case when phanloaino='Nợ đỏ' then sotien_da_thanhtoan else 0 end) as no_do_tt,
sum(Case when phanloaino='Nợ đen' then sotien_da_thanhtoan else 0 end) as no_den_tt,
-- sum(Case when phanloaino is null then so_du_chungtu else 0 end) as k_no
 from phanloai_nokh
-- where phanloai_nokh ='Nợ đen' and (so_du_dh > 1000 or so_du_dh < -1000 )
group by 1,2,3,4,5,6,7,8
)

select a.*,
Case when vung_no = 1 then a.custid else null end kh_no_xanh,
Case when vung_no = 2 then a.custid else null end kh_no_vang,
Case when vung_no = 3 then a.custid else null end kh_no_do,
Case when vung_no = 4 then a.custid else null end kh_no_den,
ifnull(b.doanhsochuavat,0) as doanhso_chuavat,
ifnull(b.sl_dh,0) as sl_dh,
d.doanhthu_thang,
d.sotien_da_thanhtoan_no_xanh,
d.sotien_da_thanhtoan_no_vang,
d.sotien_da_thanhtoan_no_do,
d.sotien_da_thanhtoan_no_den,
Case when a.thang ='2022-06-01' then 1 else 0 end as chinhsach1_0_8,
Case when a.thang ='2023-02-01' then 1 else 0 end as chinhsach2_1_2,
from max_vungno a
LEFT JOIN data_sales b on a.thang =b.thang and a.custid =b.makhdms
LEFT JOIN data_doanhthu_theovungno d on a.thang = d.thang_dt and a.custid =d.custid
-- where a.custid ='MC013'
-- order by 1,2
  );
Create or replace table `warehouse.f_tongquan_doanhthu_congno_capture`

copy `staging_temp.f_tongquan_doanhthu_congno_capture_temp`;

End;
