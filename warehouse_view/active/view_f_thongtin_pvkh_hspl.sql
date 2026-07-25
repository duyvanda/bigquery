CREATE VIEW `spatial-vision-343005.warehouse.view_f_thongtin_pvkh_hspl`
AS with tuyen123 as
(
  select * from 
(
  select custid, datatype, row_number() over (partition by custid order by datatype asc) as loc from 
  (

  SELECT custid, routetype, 1 as datatype from `staging.sync_dms_srm` where routetype in ('B','C','D') and delroutedet is false
  UNION ALL
  SELECT custid, routetype, 2 as datatype from `staging.sync_dms_srm` where routetype in ('F') and delroutedet is false
  UNION ALL
  SELECT custid, routetype, 3 as datatype from `staging.sync_dms_srm` where routetype in ('A') and delroutedet is false

  )
)
where loc = 1 
)

SELECT  
t1.branchid,
t1.branchname,
t1.custid,
t1.refcustid,
t1.pubcustid,
t1.pubcustname,
t1.custname,
t1.address,
t1.wardname,
t1.districtdescr,
t1.statedescr,
t1.territorydescr,
t1.custidinvoice,
t1.custnameinvoice,
t1.phoneinvoice,
t1.emailinvoice,
t1.addr1,
t1.taxregnbr,
t1.channel,
t1.shoptype,
t1.shoptypedescr,
t1.phone,
t1.hcotypename,
t1.hcotypeid,
t1.classid,
t1.paymentsform,
t1.terms,
t1.active,
t1.inactive,
t1.autogenorder,
t1.attn,
t1.businessscope,
t1.businessname,
t1.legaldate,
t1.taxdeclaration,
t1.vendorid,
t1.market,
t1.oricustid,
t1.billmarket,
t1.establishdate,
t1.establishdate2,
t1.stocksales,
t1.isagency,
t1.agencyid,
t1.agencyname,
t1.salessystemdescr,
t1.checkterm,
t1.shoperid,
t1.streetname,
t1.channeldescr,
t1.hcoid,
t1.legalname,
t1.chargereceive,
t1.chargepayment,
t1.chargephar,
t1.generalcustid,
t1.batchexpform,
t1.lat,
t1.lng,
t1.crtd_user,
t1.crtd_datetime,
t1.inserted_at,
t1.gtype,
t1.shortterritorydescr
,t2.YTD_doanhsochuavat,
case when d.customer_code is not null then 'Y' else 'N' end is_active_customer,
'N' iscaresoft_customer,
case when lower(t1.custname) like '%fpt long châu%' then '1.Long Châu' 
     when lower(t1.custname) like '%pharmacity%' then '2.Phamacity' 
     when lower(t1.custname) like '%trung sơn%' then '3.Trung Sơn' 
     when lower(t1.custname) like '%medx%' then '4.MedX' 
     when lower(t1.custname) like '%guardian%' then '5.Guardian' 
     when lower(t1.custname) like '%an khang%' then '6.An Khang'
     when t1.custid = '003589' then '7.ECE - Ecommerce enable'
     else 'others' end as group_khach_hang,
cast(t1.legaldate as date) as thoihanhieulucgdpgpp,
a.datatype as tuyen123,
b.crtd_user as manvbh,
c.tencvbh,
c.tenquanlytt,
c.tenquanlykhuvuc,
c.tenquanlyvung
from staging.d_master_khachhang t1
left join (select makhdms,sum(doanhsochuavat) YTD_doanhsochuavat from `staging.f_sales` 
            where date(ngaychungtu)>= date_trunc(current_date,year)
             group by 1) t2 on t1.custid=t2.makhdms
left join tuyen123 a on a.custid = t1.custid
left join `staging.sync_dms_so` b on b.custid = t1.custid
left join `staging.d_users` c on c.manv = b.crtd_user
left join `spatial-vision-343005.staging.f_crawl_activate_ecom` d on t1.custid =  d.customer_code;