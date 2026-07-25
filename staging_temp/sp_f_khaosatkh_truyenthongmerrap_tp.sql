CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_khaosatkh_truyenthongmerrap_tp(manv_p STRING, version_p STRING)
BEGIN 

INSERT INTO warehouse.f_khaosatkh_truyenthongmerrap_tp 
(
-- create or replace table warehouse.f_khaosatkh_truyenthongmerrap_tp as

with all_data as 

(
  select * 
  from `staging.d_khao_sat_kh_truyen_thong_tp_q42023_theo_user` 
  where p_manv = manv_p and p_version = version_p
)
,

ds_kh_tp as 

(
  select 
    madinhdanhdungchokhaosat,
    sodthoailienhekh,
    makhdms,
    tenkhachhang,
    macrs,
    tencrs,
    sdtcrs,
    phanhangkh,
    p_manv,
    p_version
  from all_data 
  where data_type = 'ds_kh_tp'
)
,

tin_nhan_zns_tp as
(
  SELECT 
    ngayddmmyyyy,
    trangthai10, 
    sodthoailienhekh  
  FROM all_data
  where data_type = 'tin_nhan_zns_tp' and trangthai10 = "1"
)
,

form_out_put_tp as 
(
  select
    distinct anhchivuilongnhapmakhachhangduoccungcaptrongtinnhan as madinhdanhdungchokhaosat,
  from all_data 
  where data_type = 'form_out_put_tp'
)

select 
  a.*except(madinhdanhdungchokhaosat),
  b.trangthai10 as guitn_thanhcong, 
  c.madinhdanhdungchokhaosat
from ds_kh_tp a
left join tin_nhan_zns_tp b on a.sodthoailienhekh = b.sodthoailienhekh
left join form_out_put_tp c on a.madinhdanhdungchokhaosat = c.madinhdanhdungchokhaosat 


);

End;