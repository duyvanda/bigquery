CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_tonghopdata_hcp_bv(manv_p STRING, version_p STRING)
BEGIN 

INSERT INTO warehouse.f_tonghopdata_hcp_bv 
(

-- create or replace table warehouse.f_tonghopdata_hcp_bv as

with kh_clc as 
(
  with b1 as
  (
    select 
      pubcustid, 
      pubcustname,
      custid, 
      custname,
      row_number()over(partition by pubcustid order by lupd_datetime desc) as loc
    from `spatial-vision-343005.staging.d_master_khachhang`
    where 
    1=1
    and channel = 'CLC'
    and active = 'Active'
  )
    select * from b1 where loc = 1  
)
,

kh_ngoai_clc as 
(
  with b2 as
  (
    select 
      pubcustid, 
      pubcustname,
      custid, 
      custname,
      row_number()over(partition by pubcustid order by lupd_datetime desc) as loc
    from `spatial-vision-343005.staging.d_master_khachhang`
    where 1=1
    and channel not in  ('CLC')
    and active = 'Active'
  )
    select * from b2 where loc = 1  
)
,

result as 
(
  SELECT
    a.*except(crd,inactive,bs_co_pm_code),
    'Nguyễn Thọ Chiến' as crd,
    substring(crm, STRPOS(crm,'MR'),6) as ma_crm, 
    ifnull(b1.tencvbh,crm) as ten_crm,
    case when a.inactive = 'True' then 'Ngưng' else 'Còn hoạt động' end as inactive,
    b.tencvbh as ten_crs,
    bs_co_pm_code as custid,
    bs_co_pm_cocode as custname,
    bs_co_pm_cocode as custid_bs_lambv_cocode

  FROM `spatial-vision-343005.staging.get_crm_bv_contract_v2_theo_user` a
  left join `spatial-vision-343005.staging.d_users` b on a.ma_crs1 = b.manv
  left join `spatial-vision-343005.staging.d_users` b1 on  TRIM(substring(crm, STRPOS(crm,'MR'),6)) = b1.manv
  -- left join kh_clc c on trim(a.makh_chung) = c.pubcustid
  -- left join kh_ngoai_clc d on trim(a.makh_chung) = d.pubcustid
  -- left join kh_clc e on nullif(trim(a.bs_co_pm_cocode ),"-") = e.pubcustname
  -- left join kh_clc f on nullif(trim(a.bs_co_pm_cocode ),"-") = f.pubcustname

  where p_manv = manv_p and p_version = version_p
)
  select *
  from result  

);

End;