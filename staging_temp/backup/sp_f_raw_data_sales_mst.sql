CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_raw_data_sales_mst()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_raw_data_sales_mst_temp`;


 INSERT INTO `staging_temp.f_raw_data_sales_mst_temp`

(   
-- Create or replace table `staging_temp.f_raw_data_sales_mst_temp`
-- partition by ngayhoadon
-- as


 with 
 data_sales as (

  select
   macongtycn,congtycn,masanpham,sodondathang,hoadon,ngaychungtu,tensanphamviettat,makhdms,mahd,manv,tencvbh,maphanloaihco_cu,mahco_cu,tenkhachhang,statedescr as  tentinhkh,makenhkh_cu,makenhphu_cu,
  extract(month from ngaychungtu) as thang_number,
  extract(QUARTER from ngaychungtu) as quy,
  extract(year from ngaychungtu) as nam,
  date_trunc(ngaychungtu,month) as thang,
  Case when doanhsochuavat =0 then 0 else soluong end as soluong, --PBH k tính số lượng hàng khuyến mãi
  doanhsochuavat,doanhsocovat

from `warehouse.f_raw_data_sales_yoy`
where ngaychungtu >='2023-01-01' --and ngaychungtu <'2023-06-01'
and LEFT(masanpham,1) != 'V' 
and makenhkh not in ('NB','OTH_LAB')
-- AND manv NOT IN ( 'GH001','QUYNHPTA','MA001','MA002')
) ,


data_hoadon_cu as 
(
      select distinct ordernbr,origordernbr,branchid,custid,invoicecustid,custinvcname,taxregnbr,salesordertype,invcnbr from `staging.sync_dms_so` where  crtd_datetime >='2023-01-01'
      and status = 'C'
),
 
 result as (
 select 
 a.congtycn as chinhanh,
 a.tentinhkh as tinh,
 a.nam,
 a.quy,
 a.thang_number as thang,
 a.sodondathang,
 ifnull(b1.invcnbr,b.invcnbr) as sohoadon,
 date(ngaychungtu) as ngayhoadon,
 a.makhdms,
 a.tenkhachhang as ten_kh,
 ifnull(b1.invoicecustid,b.invoicecustid) as ma_kh_thue,
 ifnull(b1.custinvcname,b.custinvcname) as ten_kh_thue,
 ifnull(b1.taxregnbr,b.taxregnbr) as ma_sothue,
--  Case when a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and e.channel ='INS' then 'CLC' else e.channel end  as kenh,
-- ifnull(f.channel,e.channel) as kenh,
-- ifnull(f.shoptype,e.shoptype) as makenhphu,
ifnull(f.channel,a.makenhkh_cu) as kenh,
ifnull(f.shoptype,a.makenhphu_cu) as makenhphu,
--  Case 
--   when  a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and e.shoptype ='INS1' then 'CLC1'
--   when  a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and e.shoptype ='INS2' then 'CLC2'
--   when  a.masanpham ='EH092' and ngaychungtu >='2024-04-01' and e.shoptype ='INS3' then 'CLC3'
--   else e.shoptype end as makenhphu,

-- ifnull(b.channel,c.channel) as channel_pda,
-- ifnull(b.shoptype,c.shoptype) as shoptype_pda,
ifnull(f.hcoid,a.mahco_cu) as mahco,
ifnull(f.hcotypeid,a.maphanloaihco_cu) as  maphanloai_hco,
 a.masanpham,
 a.tensanphamviettat,
 a.manv,
 a.tencvbh,
 d.supid as crm,
 d.tenquanlytt,
 a.mahd,
sum(a.soluong) as soluong,
sum(a.doanhsochuavat) as doanhsochuavat,
sum(a.doanhsocovat) as doanhsocovat,

from data_sales a 
LEFT JOIN data_hoadon_cu b on a.macongtycn=b.branchid and a.makhdms =b.custid and a.mahd =b.ordernbr 
LEFT JOIN data_hoadon_cu b1 on a.macongtycn=b1.branchid and a.makhdms =b1.custid and a.mahd = b1.origordernbr and b1.salesordertype ='RP'
-- LEFT JOIN `warehouse.f_mapping_crs_bytime` c on c.custid = a.makhdms and date(c.thang) =date(date_trunc(ngaychungtu,month))
-- LEFT JOIN data_crs c on  c.mahd = a.mahd and a.macongtycn =c.macongtycn  and a.masanpham =c.masanpham
LEFT JOIN `staging.d_users_bytime` d on a.manv = d.manv and date(d.thang) =date(date_trunc(ngaychungtu,month))
-- LEFT JOIN `staging.d_master_khachhang` e on e.custid =a.makhdms
LEFT JOIN `staging.sync_dms_pda_so` f on a.macongtycn =f.branchid and a.sodondathang =f.ordernbr

group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24
)

select * from result  
);

Create or replace table `warehouse.f_raw_data_sales_mst`

copy `staging_temp.f_raw_data_sales_mst_temp`;


END;