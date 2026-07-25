CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_theo_doi_cpa74()
BEGIN 
TRUNCATE TABLE staging_temp.f_theo_doi_cpa74_temp;


INSERT INTO staging_temp.f_theo_doi_cpa74_temp 
(
-- Create or replace table `staging_temp.f_theo_doi_cpa74_temp` as 
with sales as 
(
  select makhdms,
  sum(Case when date(ngaychungtu) between '2024-08-01' and '2024-12-25' then doanhsocovat else 0 end)  as ds_t8_t12,
  sum(Case when date(ngaychungtu) between '2024-09-11' and '2024-12-25' then doanhsocovat else 0 end)  as ds_t9_t12,
  sum(Case when date(ngaychungtu) between '2024-08-01' and '2024-09-10' then doanhsocovat else 0 end)  as ds_1t8_10t9,
  sum(Case when date(ngaychungtu) between '2024-09-11' and '2024-09-30' then doanhsocovat else 0 end)  as ds_11t9_30t9,
  sum(Case when date(ngaychungtu) between '2024-10-01' and '2024-10-31' then doanhsocovat else 0 end)  as ds_t10,
  sum(Case when date(ngaychungtu) between '2024-11-01' and '2024-11-30' then doanhsocovat else 0 end)  as ds_t11,
  sum(Case when date(ngaychungtu) between '2024-12-01' and '2024-12-25' then doanhsocovat else 0 end)  as ds_t12,
  from `warehouse.f_sales_crs` where ngaychungtu >='2024-08-01' and ngaychungtu <'2024-12-26'
  group by 1
)

select 
a.mahcotrendms as custid,
a.tenhco,
c.custname,
a.doanhsomuctieu18251224,
a.doanhsodangkytheocttu119251224,
Case when a.mahcotrendms in ('013205','012835','012885') and ds_t9_t12 >= doanhsodangkytheocttu119251224 then 0.13
     when a.mahcotrendms not in ('013205','012835','012885') and ds_t9_t12 >= doanhsodangkytheocttu119251224 then 0.115
else 0 end as km_ct,
Case when a.mahcotrendms in ('013205','012835','012885') and ds_t9_t12 >= doanhsodangkytheocttu119251224 then 0.13 * ds_t9_t12
     when a.mahcotrendms not in ('013205','012835','012885') and ds_t9_t12 >= doanhsodangkytheocttu119251224 then 0.115 * ds_t9_t12
else 0 end as thanhtien_km_ct,

b.*except(makhdms),
c.channel,
c.branchid,
c.shoptype,
c.hcoid,
c.hcotypeid,
c.statedescr,
c.shortterritorydescr,
c.classid,
d.col.ma_nvbh as ma_crs,
e.tencvbh as ten_crs,
e.supid as ma_crm,
e.tenquanlytt as ten_crm,
e.rsmid as ma_ncxm,
e.tenquanlyvung as ten_ncxm,
'PMC,CTD' as pl_kh,
4000000000 / count(a.mahcotrendms) over (partition by 1) as kh_ds,
7200000 / count(a.mahcotrendms) over (partition by 1) as thue_hkd,
480000000 / count(a.mahcotrendms) over (partition by 1) as chiphi_km,
0.122 as chiphi_phantram,
current_datetime("+7") as insterted_at

 from `staging.d_manual_theo_doi_cpa74`  a 
 LEFT JOIN sales b on a.mahcotrendms = b.makhdms
 LEFT JOIN `staging.d_master_khachhang` c on a.mahcotrendms = c.custid
 LEFT JOIN `warehouse.f_mapping_crs` d on a.mahcotrendms = d.custid
 LEFT JOIN `staging.d_users` e on d.col.ma_nvbh = e.manv
 );

Create or replace table `warehouse.f_theo_doi_cpa74`

copy `staging_temp.f_theo_doi_cpa74_temp`;
END;