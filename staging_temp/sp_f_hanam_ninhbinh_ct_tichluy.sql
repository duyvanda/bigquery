CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_hanam_ninhbinh_ct_tichluy()
BEGIN 
  TRUNCATE TABLE staging_temp.f_hanam_ninhbinh_ct_tichluy_temp;


 INSERT INTO staging_temp.f_hanam_ninhbinh_ct_tichluy_temp(

--  Create or replace table staging_temp.f_hanam_ninhbinh_ct_tichluy_temp as 

select a.*except(tinhtp,channel,branchid,shoptype,hcotypeid,branchname,tenhco,makhdms,accumulatedvalue,shortterritorydescr),
b.*except(ma_crm,ma_scrm,ma_ncxm,tenquanlyvung,tenquanlykhuvuc,statedescr,branchid,channel,accumulatedvalue,shortterritorydescr,shoptype ) ,

b.ma_crm as ma_crm_ttmb,
Case when a.mahcotrendms is not null then 'Viplus' else null end as vippplus,
Case when b.makhdms is not null then 'TTMB' else null end as ttmb,
c.channel,
c.shoptype,
c.branchid,
c.custname,
c.custid,
ifnull(crsscrs,b.tencvbh) as filter_tencvbh,
ifnull(crmacrm,b.tenquanlytt) as filter_tenquanlytt,

ifnull(a.tinhtp,b.statedescr) as tinhtp
-- ifnull(a.ma_crs,b.crtd_user) as manv,
-- ifnull(a.crsscrs,b.tencvbh) as tencvbh,

from `warehouse.f_viplus_trading` a 
FULL JOIN `warehouse.f_thoathuan_muaban` b on a.mahcotrendms = b.makhdms
LEFT JOIN `staging.d_master_khachhang` c on ifnull(a.mahcotrendms,b.makhdms) = c.custid

where ifnull(a.tinhtp,b.statedescr) in ('Hà Nam','Nam Định','Ninh Bình')

  );

Create or replace table `warehouse.f_hanam_ninhbinh_ct_tichluy`

copy `staging_temp.f_hanam_ninhbinh_ct_tichluy_temp`;

End;