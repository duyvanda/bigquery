-- ==========================================================================
-- Routine Name : sp_f_phanhang_theo_sku
-- Routine Type : PROCEDURE
-- Dataset      : spatial-vision-343005.staging_temp
-- Created      : 2025-11-06 03:24:14.394000+00:00
-- Last Altered : 2025-11-06 03:24:14.394000+00:00
-- Extracted At : 2026-08-06 13:45:04
-- ==========================================================================

CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_phanhang_theo_sku()
BEGIN

 TRUNCATE TABLE `staging_temp.f_phanhang_theo_sku_temp`;

 INSERT INTO `staging_temp.f_phanhang_theo_sku_temp`

(
-- Create or replace table staging_temp.f_phanhang_theo_sku_temp as
with

tuyen_dms_moinhat as (
    with data_tuyen as (
        SELECT
            custid,
            slsperid,
            crtd_datetime,
            Case
                when routetype in ('B', 'D') then 1
                else 2
            end as routetype,
        FROM
            `spatial-vision-343005.staging.sync_dms_srm`
        where
            delroutedet is false
    )
    select
        *
    from
        data_tuyen
        qualify row_number() over (
            partition by custid
            order by
                routetype asc,
                crtd_datetime desc
        ) = 1
),
raw_data_sales as
(
select

d.slsperid as slsperid,e.tencvbh,e.supid as crm, e.tenquanlytt, a.masanpham, makhdms, IFNULL(b.classid,'O') as maphanhanghco, thang as ngaychungtu,
sum(soluong) as soluong

from `warehouse.f_raw_data_sales_yoy`  a
INNER JOIN `staging.d_master_khachhang` b on a.makhdms = b.custid
LEFT JOIN `staging.d_nhom_sp_trading` c on c.masanpham = a.masanpham
LEFT JOIN tuyen_dms_moinhat d on d.custid = a.makhdms
LEFT JOIN `staging.d_users` e on d.slsperid =e.manv

where
date(ngaychungtu)>= '2024-01-01' and makenhkh ='TP' --and d.col.phan_loai_mcp ='CRS (Trong MCP)'
and e.tenquanlyvung ='Nguyễn Hoàng Viển'
-- and date(ngaychungtu) < '2025-01-01'
group by all
having soluong > 0

)
,
data_sales as
(
select a.*,
case when sum(soluong) over (partition by makhdms,masanpham) > 0 and
row_number()over(partition by makhdms,masanpham order by soluong desc) = 1 then 1 else 0 end as count_kh_sp,
null as slkh_ka,
null as slkh_rb,
null as slkh_rc
from raw_data_sales a
)
,
distinct_sales_sku as
(
select distinct masanpham from data_sales
)
, slkh_theo_tung_nv_ql as (
  select
  slsperid,
  tencvbh,
  crm,
  tenquanlytt,
  count ( distinct case when maphanhanghco = 'KA' then makhdms else null end) as slkh_ka,
  count ( distinct case when maphanhanghco = 'RB' then makhdms else null end) as slkh_rb,
  count ( distinct case when maphanhanghco = 'RC' then makhdms else null end) as slkh_rc,
  from data_sales group by all
)
, cross_join_nv_sp as
(
select * from slkh_theo_tung_nv_ql cross join distinct_sales_sku
)
,
result as (
select * from data_sales
UNION ALL
select
slsperid,
tencvbh,
crm,
tenquanlytt,
masanpham,
-- brand,
null as makhdms,
null as maphanhanghco,
null as ngaychungtu,
null as makhdms,
0 as count_kh_sp,
slkh_ka,
slkh_rb,
slkh_rc
from cross_join_nv_sp
)

select
a.*,
b.brand,
c.shortterritorydescr as khuvucviettat,
c.statedescr,
c.custname as tenkhachhang,
d.descr as tensanphamnb,
d.descr1 as tensanphamviettat,
current_datetime("+7") as inserted_at
 from result a
 LEFT JOIN `staging.d_master_khachhang` c on c.custid =a.makhdms
 LEFT JOIN `staging.d_nhom_sp_trading` b on b.masanpham = a.masanpham
 LEFT JOIN `staging.d_dms_master_invtid` d on a.masanpham =d.invtid

);

Create or replace table `warehouse.f_phanhang_theo_sku`
copy `staging_temp.f_phanhang_theo_sku_temp`;
END;
