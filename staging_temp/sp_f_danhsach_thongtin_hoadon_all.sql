CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danhsach_thongtin_hoadon_all()
BEGIN 
  TRUNCATE TABLE staging_temp.f_danhsach_thongtin_hoadon_all_temp;


 INSERT INTO staging_temp.f_danhsach_thongtin_hoadon_all_temp(

-- Create table staging_temp.f_danhsach_thongtin_hoadon_all_temp
-- partition by date(orderdate)
-- as
WITH
tthd as ( 
  select distinct macongtycn, mahd, sodontrahang, ngaytrahang, concat("da huy ", cast((date(ngaytrahang)) as string)) as trangthaihoadonCO from staging.f_sales where sodontrahang is not null
),

data_viettel AS (
  SELECT
    branchid,
    batnbr,
    invoicenbr,
    taxinvcode,
    mtloi
  FROM
    `staging.sync_dms_omapiviettelsecretkey`),
data_sales AS (
  SELECT
    hoadon,
    sodondathang,
    sodontrahang,
    makhdms,
    SUM(doanhsochuavat) AS doanhsochuavat,
    SUM(doanhsocovat) AS doanhsocovat
  FROM
    `staging.f_sales`
  WHERE
    ngaychungtu >='2022-01-01'
  GROUP BY
    1,
    2,
    3,
    4)
SELECT a.*,ordamt as sotien ,b.doanhsochuavat,b.doanhsocovat,mtloi,d.channel,
d.custname,d.custnameinvoice,d.custidinvoice,
e.trangthaihoadonCO,
    Case when c.taxinvcode is null then "Chưa cấp mã của CQT" else "Đã cấp mã của CQT" end as tinhtrangcapma,
    Case when a.status ="C" then "Đã phát hành hóa đơn"
when a.status ="V" then "Hủy hóa đơn"
when a.status ="I" then "Tạo hóa đơn"
when a.status ="N" then "Tạo hóa đơn"
when a.status ="H" then "Chờ xử lý hóa đơn"
when a.status ="E" then "Đóng đơn hàng"
when a.status ="D" then "Đơn hàng tạm" 
else null end as trangthaihd,

FROM `spatial-vision-343005.staging.sync_dms_so` a
left join data_sales b on  b.makhdms = a.custid and a.origordernbr = b.sodondathang and b.hoadon = a.invcNbr
left join  data_viettel c on c.branchid = a.branchid and a.ordernbr = c.batnbr
left join `staging.d_master_khachhang` d on a.custid = d.custid
left join tthd e on e.mahd = a.ordernbr and e.macongtycn = a.branchid
where date(a.orderdate) >="2022-01-01" and a.invcnbr is not null

  );

Create or replace table `warehouse.f_danhsach_thongtin_hoadon_all`

copy `staging_temp.f_danhsach_thongtin_hoadon_all_temp`;

End;