CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_tonghopdata_hcp_pcl(manv_p STRING, version_p STRING)
BEGIN 

INSERT INTO warehouse.f_tonghopdata_hcp_pcl 
(

-- create or replace table warehouse.f_tonghopdata_hcp_pcl as

with khc as 
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
    -- and channel = 'CLC'
    -- and active = 'Active'
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
    mailing_province,
    makh_chung,
    account_name,
    hangbv,
    tuyenbv,
    khuvuc,
    phanloai_pcl,
    phanhang_hcp_pcl,
    contact_name,
    kenh_lamviec,
    ma_hcp1,
    contact_code as ma_hcp2,
    phanloai_hcp,
    gender,
    ngaysinh,
    thangsinh,
    namsinh,
    mobile,
    chucvu_pcl,
    chucdanh_pcl,
    nganh_pcl,
    chuyenkhoa_pcl,
    bs_lambv_cocode,
    soluot_kham,
    phanhang_hcp_bv,
    'Nguyễn Thọ Chiến' as crd,
    related_users as crm,
    substring(related_users, STRPOS(related_users,'MR'),6) as ma_crm, 
    
    ifnull(b1.tencvbh,related_users) as ten_crm,

    organization_unit_name as nhom, 
    owner_name as crs1,
    mailing_address,
    doanhso,
    c.custid as makh_tructiep,
    c.custname as tenkh_tructiep,
    case when a.inactive = 'True' then 'Ngưng' else 'Còn hoạt động' end as inactive,
    created_by,
    created_date,
    modified_by,
    modified_date,
    ma_crs,
    b.tencvbh as ten_crs,
    bs_lambv_code as custid,
    bs_lambv_cocode as custname,
    bs_lambv_cocode as custid_bs_lambv_cocode,

    p_manv,
    p_version,
    bs_lam_o_bv_chuacode
  FROM `spatial-vision-343005.staging.get_crm_contract_v2_theo_user` a
  left join `spatial-vision-343005.staging.d_users` b on a.ma_crs = b.manv
  left join `spatial-vision-343005.staging.d_users` b1 on  TRIM(substring(related_users, STRPOS(related_users,'MR'),6)) = b1.manv
  left join khc c on trim(a.makh_chung) = c.pubcustid
  -- left join kh_ngoai_clc d on trim(a.makh_chung) = d.pubcustid
  -- left join kh_clc e on nullif(trim(a.bs_lambv_cocode),"-") = e.pubcustname
  -- left join kh_clc f on nullif(trim(a.bs_lambv_cocode),"-") = f.pubcustname

  where p_manv = manv_p and p_version = version_p
)
  select *
  from result  


);

End;