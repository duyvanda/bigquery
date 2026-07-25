CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_detail_order_promotion()
BEGIN 
  TRUNCATE TABLE staging_temp.f_detail_order_promotion_temp;

 INSERT INTO staging_temp.f_detail_order_promotion_temp(

-- Create table staging_temp.f_detail_order_promotion_temp
-- partition by date(thang)

-- as
with data_sales as (
select  thang,macongtycn,mahd,sodondathang,masanpham,makhdms,lineref,sum(doanhsochuavat) as doanhsochuavat,sum(soluong) as soluong

 from `staging.f_sales` where  ngaychungtu >='2022-01-01' 
  and makenhkh not in ('NB','OTH_LAB')
  AND LEFT(masanpham,1) != 'V' 
      AND manv NOT IN ( 'GH001', 'MA001', 'MA002', 'QUYNHPTA') 
 group by 1,2,3,4,5,6,7
),
data_sod1 as 
(
  select * from `staging.sync_dms_sod1` where crtd_datetime >='2022-01-01'
),

result as (
select a.*,
c.refcustid,
c.custname,
c.channel,
c.shoptype,
d.brand as brand_dl_nt,
Case when d.nhomcpa='KS&STO' then 'Kháng sinh'
     when trim(upper(d.brand)) in ('XISAT','SHEMA','OSLA') then 'XOS' else 'Còn lại' end as nhom_sp,
b.discamt,
b.docdiscamt,
b.groupdiscamt1,
b.beforevatprice,
b.aftervatprice,
-- Case when doanhsochuavat =0 then 'Hàng tặng' else 'Hàng bán' end as loaihang,
Case when freeitem is true then 'Hàng tặng' else 'Hàng bán' end as loaihang,
Case when  freeitem is true then a.soluong * b.beforevatprice else 0 end as giatri_hangtang
 from data_sales a 
LEFT JOIN data_sod1 b on a.macongtycn=b.branchid and a.mahd=b.ordernbr and a.lineref =b.lineref 
LEFT JOIN `staging.d_master_khachhang` c on a.makhdms =c.custid
LEFT JOIN `staging.d_nhom_sp_trading` d on a.masanpham =d.masanpham
)

select *,
Case when discamt + docdiscamt + groupdiscamt1 + giatri_hangtang >0 then sodondathang else null end as is_dh_km,
Case when discamt + docdiscamt + groupdiscamt1 + giatri_hangtang >0 then refcustid else null end as is_kh_km,
round(discamt + docdiscamt + groupdiscamt1 + giatri_hangtang,0) as tong_km,
(select max(inserted_at) from `staging.f_sales` where ngaychungtu >='2023-04-01' )  as inserted_at


from result


  );

Create or replace table `warehouse.f_detail_order_promotion`

copy `staging_temp.f_detail_order_promotion_temp`;


End;