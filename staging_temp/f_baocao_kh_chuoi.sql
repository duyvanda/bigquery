CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_baocao_kh_chuoi()
BEGIN 
 
TRUNCATE TABLE staging_temp.f_baocao_kh_chuoi_temp;

INSERT INTO `staging_temp.f_baocao_kh_chuoi_temp`

(  
-- Create or replace table `staging_temp.f_baocao_kh_chuoi_temp`
-- as

with data_sales as 
(
  select 
  a.macongtycn,
  a.congtycn,
  a.makhdms,
  a.tenkhachhang,
  a.makenhkh,
  a.makenhphu,
  a.sodondathang,
  a.kieudonhang,
  a.mahd,
  a.trangthai,
  a.lineref,
  a.hoadon,
  a.ngaychungtu, 
  a.masanpham,
  a.tensanphamnb,
  sum(soluong) as soluong,
  sum(doanhsochuavat) as doanhsochuavat
from `spatial-vision-343005.staging.f_sales` a
where a.makenhkh = 'MT' AND a.masanpham not like 'V%' AND a.ngaychungtu >= '2023-01-01' 
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
),

result as (
select 
  a.macongtycn,
  a.congtycn,
  a.makhdms,
  a.tenkhachhang,
  a.makenhkh,
  a.makenhphu,
  a.sodondathang,
  a.kieudonhang,
  a.mahd,
  a.trangthai,
  c.invcnote as kyhieu_hoadon,
  a.hoadon,
  a.ngaychungtu, 
  a.masanpham,
  a.tensanphamnb,
  b.taxcat as vat,
  a.soluong,
  a.doanhsochuavat as doanhsochuavat_lamtron,
  case when a.kieudonhang in ('IR','CO','OO') THEN - b.beforevatamount else b.beforevatamount end as doanhsochuavat,
  b.beforevatprice,
  case when a.kieudonhang in ('IR','CO','OO') THEN - b.aftervatamount ELSE b.aftervatamount end as aftervatamount,
  case when a.kieudonhang in ('IR','CO','OO') and (b.discamt + b.docdiscamt + b.groupdiscamt1) <> 0 THEN -(b.discamt + b.docdiscamt + b.groupdiscamt1) else (b.discamt + b.docdiscamt + b.groupdiscamt1) end as tong_ck,
  
from data_sales a
left join  `spatial-vision-343005.staging.sync_dms_sod1` b on a.macongtycn = b.branchid and a.mahd = b.ordernbr and a.masanpham = b.invtid and a.lineref = b.lineref 
left join `spatial-vision-343005.staging.sync_dms_so` c on a.macongtycn = c.branchid and a.mahd = c.ordernbr

)

select * from result



);

Create or replace table `warehouse.f_baocao_kh_chuoi`

copy `staging_temp.f_baocao_kh_chuoi_temp`;

END;