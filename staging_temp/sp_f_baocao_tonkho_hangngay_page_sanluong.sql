CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_baocao_tonkho_hangngay_page_sanluong()
BEGIN 
  TRUNCATE TABLE staging_temp.f_baocao_tonkho_hangngay_page_sanluong_temp;


 INSERT INTO staging_temp.f_baocao_tonkho_hangngay_page_sanluong_temp(

-- Create or replace table staging_temp.f_baocao_tonkho_hangngay_page_sanluong_temp
-- partition by date(ngaychungtu)
-- as

----------------------------- `warehouse.mr|báo cáo tồn kho hàng ngày (sc và pbh) page sản lượng`---------------------



with 
-- data_trongtuyenmcp as (
-- with data_max_descr as (
-- SELECT custid,descr,row_number() over (partition by custid order by visitdate desc) as loc_descr FROM `spatial-vision-343005.staging.sync_dms_salesroutedet` 
-- ),

-- loc_descr as 
-- (
--   select a.*,statedescr,districtdescr,wardname 
--   from data_max_descr  a
--   LEFT JOIN `staging.d_master_khachhang` b on a.custid = b.custid
--   where loc_descr =1
-- )

-- select * from loc_descr
-- ),
data_trongtuyenmcp as (SELECT distinct custid FROM `spatial-vision-343005.staging.sync_dms_srm` where routetype in ('B', 'C', 'D') ),

tuyen123 as
(
select * from 
(
  select custid,slsperid, datatype, row_number() over (partition by custid order by datatype asc) as loc from 
  (

  SELECT custid,slsperid, routetype, 1 as datatype from `staging.sync_dms_srm` where routetype in ('B','C','D') and delroutedet is false
  UNION ALL
  SELECT custid,slsperid, routetype, 2 as datatype from `staging.sync_dms_srm` where routetype in ('F') and delroutedet is false
  UNION ALL
  SELECT custid,slsperid, routetype, 3 as datatype from `staging.sync_dms_srm` where routetype in ('A') and delroutedet is false

  )
)
where loc = 1 

),

base as
(select
t1.ngaychungtu, 
t1.sodondathang, 
t1.mahd,
t1.macongtycn,
t1.trangthai,
t1.makhdms, 
t1.makhcu, 
b.custname as tenkhachhang, 
t1.tenvungbh,
t1.tenkhuvuc,
t1.makenhkh,
t1.tenkenhkh,
t1.makenhphu, 
b.shoptypedescr as tenkenhphu, 
t1.mahco, 
t1.tenhco, 
t1.maphanloaihco, 
t1.tenphanloaihco, 
t1.maphanhanghco, 
t1.tenphanhanghco, 
t1.tensanphamnb, 
t1.masanpham,
t1.tentinhkh,
t1.thtt,
t1.pmt,

case when lower(t1.tenkhachhang) like '%fpt long châu%' then '1.Long Châu' 
     when lower(t1.tenkhachhang) like '%pharmacity%' then '2.Phamacity' 
     when lower(t1.tenkhachhang) like '%trung sơn%' then '3.Trung Sơn' 
     when lower(t1.tenkhachhang) like '%medx%' then '4.MedX' 
     when lower(t1.tenkhachhang) like '%guardian%' then '5.Guardian' 
     when lower(t1.tenkhachhang) like '%an khang%' then '6.An Khang'
     when t1.makhdms = '003589' then '7.ECE - Ecommerce enable'
     else 'others' end as group_khach_hang,
--concat(makenhkh,"-",    
case when tenkenhphu like '%Clinic Chanel%'  then 'Clinic'
     when  tenkenhphu like '%Đại Lý Phân Phối%' then 'Đại Lý Phân Phối'
     when  tenkenhphu like '%Insurance%' then 'Kênh Bảo hiểm'
     else tenkenhphu
     end as kenh_khach_hang,
cast(b.legaldate as date) as thoihanhieulucgdpgpp,
Case when b.legaldate is not null then 'Y' else 'N' end as is_co_gpp,
b.classid as phanhanghco,
coalesce(t12.tencvbh,t1.tencvbh) as tencvbh,
coalesce(t12.tenquanlytt,t1.tenquanlytt) as tenquanlytt,
coalesce(t12.tenquanlykhuvuc,t1.tenquanlykhuvuc) as tenquanlykhuvuc,
coalesce(t12.tenquanlyvung,t1.tenquanlyvung) as tenquanlyvung,

coalesce(t12.tenquanlytt,t1.tenquanlytt) as acrm,
coalesce(t12.tenquanlykhuvuc,t1.tenquanlykhuvuc) as scrm,
coalesce(t12.tenquanlyvung,t1.tenquanlyvung) as ncxm,
-- t3.acrm,
-- t3.scrm,
-- t3.ncxm,
b.hcoid mahco_dsn,
Case when b.channel = 'OTC' and b.hcotypeid like '%Phòng Khám Có%' then 'PKC'
     when b.channel = 'OTC' and b.hcotypeid like '%Phòng Khám Không%' then 'PKK'
     when b.channel = 'OTC' and b.shoptype ='PK' and b.hcotypeid is null then 'PK chưa phân loại' 
     when b.channel = 'OTC' and b.shoptype is not null then b.shoptype 
     --when b.channel = 'CLC' and b.hcotypeid is  null then 'CLC'
     when b.channel = 'OTC' and b.shoptype is  null then 'OTC'
     else b.channel end as channel,
b.custidinvoice
,b.custnameinvoice
, b.taxregnbr
,t4.trangthaidon
,t4.thongtinxe
,t4.full_leadtime
 ,t4.deliveryunit
,t4.ngaygiaohang,
b.active,
t1.makho,
t1.tenkho,
t1.solo,
t2.expdate
,sum(t1.doanhsochuavat) doanhsochuavat,
sum(        Case
            when doanhsochuavat = 0 then 0
            else t1.soluong
        end ) soluong,



from `spatial-vision-343005.staging.f_sales` t1
LEFT JOIN `staging.d_master_khachhang` b on t1.makhdms =b.custid
left join `spatial-vision-343005.staging.sync_dms_lt` t2 on t1.macongtycn = t2.branchid and t1.lineref =t2.omlineref and t1.mahd = t2.ordernbr
-- left join `spatial-vision-343005.staging.d_dskh_29032022` t3 on t1.makhdms = t3.mahco
LEFT JOIN tuyen123 t11 on trim(t11.custid) = trim(t1.makhdms)
LEFT JOIN `staging.d_users` t12 on t12.manv = t11.slsperid
left join (select distinct ordernbr,branchid,t4.trangthaidon
,t4.thongtinxe
,t4.full_leadtime
 ,t4.deliveryunit
,t4.ngaygiaohang 

from `spatial-vision-343005.warehouse.f_leadtime_new_detail1` t4 ) t4 on t1.sodondathang = t4.ordernbr 
                        and t1.macongtycn=t4.branchid


where 
ngaychungtu >='2023-01-01' and
--t1.tencvbh <> 'Phạm Thị Quỳnh Ảo' 
      LEFT(masanpham,1) != 'V' 
      --AND t1.manv NOT IN ( 'GH001', 'MA001', 'MA002', 'QUYNHPTA') 
     -- and a.phanam not in ( 'PHA NAM')
      AND makenhkh not in ( 'NB','OTH_LAB')
      and makhdms not in ('008140', '003589')
--and date(ngaychungtu)>=date_trunc(date_sub((select * from `staging.d_current_table`), interval 13 month),month)
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52
),

-- disc_q42021
-- as
-- (select distinct makhdms,disc_kh_type disc_kh_typeq42021,doanhso_kh_type doanhso_kh_typeq42021,kh_type kh_typeq42021
-- from staging.f_sales_promotion_total_temp
-- ),

result as (


select t1.* ,
-- ifnull(MR_acc_registered,'N') MR_acc_registered, 

-- ifnull(PN_acc_registered,'N') PN_acc_registered
'N' MR_acc_registered, 

'N' PN_acc_registered
 ,case when t4.doanhsochuavat <500000 then '1.<500k'
       when t4.doanhsochuavat <1000000 then '2.<1tr'
       when t4.doanhsochuavat <2000000 then '3.<2tr'
       when t4.doanhsochuavat <3000000 then '4.<3tr'
       when t4.doanhsochuavat <4000000 then '5.<4tr'
       when t4.doanhsochuavat <5000000 then '6.<5tr'
        when t4.doanhsochuavat <10000000 then '7.<10tr'
       else '8.>=10tr' end as doanhsodon_type
  ,t4.soluong soluong_don
--   ,t2.* except(makhdms,kh_typeq42021), 
--   ,case when kh_typeq42021 is null then 'binh thuong' else kh_typeq42021 end as kh_typeq42021,
--   case when t1.makenhphu in ('NT') then concat(t1.makenhkh,"-",makenhphu,"- ", 
--   case when kh_typeq42021 is null then 'binh thuong' else kh_typeq42021 end) else concat(t1.makenhkh,"-",t1.makenhphu) end kh_type_new
-- ,t3.active
,t3.lat
,t3.lng
,t3.hcotypeid
,ifnull(t3.businessscope,"") businessscope
,ifnull(t3.phone,"") phone
--,ifnull(t3.phoneinvoice,"") phoneinvoice
,ifnull(REGEXP_REPLACE(t3.emailinvoice, ",", "| "),"") emailinvoice,
-- ,case when t6.makhdms is not null then 'Y' else 'N' end iscaresoft_customer
'N' iscaresoft_customer
,case when t7.ordernbr is not null then 'Y' else 'N' end is_Ecommerce_orders
,
-- ,t8.phanchamsoc
-- ,Case when trim(t9.mrpn)='PN' then 'PN'
-- else 'MR' end as mrpn,
Case when t10.custid is null then 'N'
else 'Y' end as is_trongtuyen_mcp,
t11.datatype as tuyen123,
t3.terms as HTTT,
t3.paymentsform as HTT,
(select  max(inserted_at) from `staging.f_sales` ) as inserted_at


from base t1
left join (SELECT sodondathang,sum(doanhsochuavat) doanhsochuavat,sum(soluong) soluong from `spatial-vision-343005.staging.f_sales`
            where doanhsochuavat>0 and  date(ngaychungtu)>=date_trunc(date_sub((select * from `staging.d_current_table`), interval 13 month),month) group by 1) t4 on t1.sodondathang = t4.sodondathang
-- left join disc_q42021 t2 on t1.makhdms = t2.makhdms
left join staging.d_master_khachhang t3 on t1.makhdms = t3.custid
----------- Danh sách đk TLQ
-- left join
--  (SELECT custid, if(sum(case when t1.accumulateid like '%/MR%' then 1 else 0 end)>0,'Y',null) MR_acc_registered,
--  if(sum(case when t1.accumulateid like '%/PN%' then 1 else 0 end)>0,'Y',null) PN_acc_registered
--            FROM `spatial-vision-343005.staging.d_accumulated` t1
--            left join staging.d_accumulatedregis t2 on t1.AccumulateID=t2.AccumulateID and t2.crtd_datetime between t1.fromdate and t1.todate
--            where date_trunc(case when(select * from `staging.d_current_table`) between date(fromdate) and date(todate) then (select * from `staging.d_current_table`) else date(t2.crtd_datetime) end ,quarter ) = date_trunc((select * from `staging.d_current_table`),quarter)
--            group by 1 ) t5 on t1.makhdms=t5.custid
-- left join 
-- (select distinct makhdms from
-- `staging.f_caresoft_contact_detail`) t6 on t1.makhdms= t6.makhdms ---- danh sách caresoft
left join 
(SELECT distinct branchid,ordernbr FROM `spatial-vision-343005.staging.sync_dms_pda_sod` 
WHERE DATE(crtd_datetime) >= "2022-06-28" and slsperid = 'TMDT_001') t7 
                        on t1.sodondathang = t7.ordernbr 
                        and t1.macongtycn=t7.branchid
-- LEFT JOIN staging.d_phanloai_chamsoc_kh t8 on trim(t8.makhachhang) =trim(t1.makhdms) and t1.tenkenhkh not in ('INS','CLC')
-- LEFT JOIN staging.d_ds_sanpham t9 on trim(t1.masanpham) =trim(t9.masp)
LEFT JOIN data_trongtuyenmcp t10 on trim(t10.custid) = trim(t1.makhdms)
LEFT JOIN tuyen123 t11 on trim(t11.custid) = trim(t1.makhdms)
LEFT JOIN `staging.d_users` t12 on t12.manv = t11.slsperid


)


select * from result

  );

Create or replace table `warehouse.f_baocao_tonkho_hangngay_page_sanluong`

copy `staging_temp.f_baocao_tonkho_hangngay_page_sanluong_temp`;

End;