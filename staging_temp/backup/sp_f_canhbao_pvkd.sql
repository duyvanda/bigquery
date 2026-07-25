CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_canhbao_pvkd()
BEGIN 
  TRUNCATE TABLE staging_temp.f_canhbao_pvkd_temp;


 INSERT INTO staging_temp.f_canhbao_pvkd_temp(


-- Create table staging_temp.f_canhbao_pvkd_temp
-- partition by date(ngaychungtu)
-- as
with thongtin_thaydoi as
(
  with b1 as
  (
    select 
      custid,
      changetype,
      old_value,
      lupd_datetime,
      row_number() over (partition by custid order by lupd_datetime desc) as loc  
    from `spatial-vision-343005.staging.d_tracking_cust_changes`
    where changetype = 'businessscope'
  )
select * from b1
Where loc= 1
)
,
result as
(
  SELECT 
  a.inserted_at,
  a.macongtycn,
  a.congtycn,
  a.ngaychungtu,
  a.sodondathang,
  a.makhdms, 
  a.tenkhachhang, 
  a.makenhkh, 
  a.makenhphu, 
  a.mahco,
  a.maphanloaihco,
  a.tenkhuvuc,
  a.tentinhkh,
  a.tenquanhuyen,
  a.masanpham,
  a.tensanphamnb,
  b.businessscope as pvkd_kh,
  c.businessscope as pvkd_sp, 
  B.billmarket,
  sodontrahang,
  kieudonhang,
  case when changetype = 'businessscope' then d.lupd_datetime else null end as lupd_datetime , 
  case when changetype = 'businessscope' then old_value else null end as thongtin_cu,
  case when STRPOS (b.businessscope, c.businessscope) > 0 then 'true' else 'false' end as result,
  sum(a.soluong) as soluong,
  SUM(a.doanhsochuavat) as doanhsochuavat
FROM `spatial-vision-343005.staging.f_sales` a
left join `spatial-vision-343005.staging.d_master_khachhang` b on a.makhdms = b.custid
left join `spatial-vision-343005.staging.d_dms_master_invtid` c on a.masanpham = c.invtid
left join thongtin_thaydoi d on a.makhdms = d.custid
-- when changetype = 'businessscope' then 'PVKD'
WHERE date (ngaychungtu) >= '2022-01-01'
      and a.makenhkh not in ('NB','OTH_LAB')
      and a.masanpham not like 'V%'
      AND (case when STRPOS (b.businessscope, c.businessscope) > 0 then 'true' else 'false' END ) = 'false'
      and kieudonhang in ('IN')
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23
)
select * 
from result
where soluong != 0
-- and makhdms = 'N0610109012'
-- and masanpham = 'EH069'
-- and sodondathang  = 'EP052021-00114'

 );

Create or replace table `warehouse.f_canhbao_pvkd`

copy `staging_temp.f_canhbao_pvkd_temp`;


End;