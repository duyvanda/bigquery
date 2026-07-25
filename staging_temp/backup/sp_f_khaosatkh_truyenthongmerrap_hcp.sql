CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_khaosatkh_truyenthongmerrap_hcp(manv_p STRING, version_p STRING)
BEGIN 

INSERT INTO warehouse.f_khaosatkh_truyenthongmerrap_hcp 
(

-- create or replace table warehouse.f_khaosatkh_truyenthongmerrap_hcp as

with all_data as 

(
  select * 
  from `staging.d_khao_sat_kh_truyen_thong_hcp_q42023_theo_user` 
  where p_manv = manv_p and p_version = version_p
)
,

ds_kh_hcp as 

(
  select 
    madinhdanhdungchokhaosat,
    sodthoailienhekh,
    macrs,
    tencrs,
    sdtcrs,
    kenhpclinsclc,
    codehco,
    tenhco,
    p_manv,
    p_version
  from all_data 
  where data_type = 'ds_kh_hcp'
)
,

tin_nhan_zns_hcp as
(
  SELECT 
    ngayddmmyyyy,
    trangthai10, 
    sodthoailienhekh  
  FROM all_data
  where data_type = 'tin_nhan_zns_hcp' and trangthai10 = "1"
)
,

form_out_put_hcp as 
(
  select 
    distinct bacsivuilongnhapmakhachhangduoccungcaptrongtinnhan as madinhdanhdungchokhaosat 
    from all_data 
    where data_type = 'form_out_put_hcp'
)

select 
  a.*except(madinhdanhdungchokhaosat),
  b.trangthai10 as guitn_thanhcong,
  c.madinhdanhdungchokhaosat
from  ds_kh_hcp a
left join tin_nhan_zns_hcp b on a.sodthoailienhekh = b.sodthoailienhekh
left join form_out_put_hcp c on a.madinhdanhdungchokhaosat = c.madinhdanhdungchokhaosat

);

End;