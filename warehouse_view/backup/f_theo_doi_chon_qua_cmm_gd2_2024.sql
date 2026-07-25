CREATE VIEW `spatial-vision-343005.warehouse.f_theo_doi_chon_qua_cmm_gd2_2024`
AS SELECT 
    a.*except(id_user,
      access_key,
      active,
      deleted_at,
      created_at,
      created_name,
      created_code,
      ty_trong_theo_doanh_so
    ),
    cast(ty_trong_theo_doanh_so as float64) as ty_trong_theo_doanh_so,
    f.custname,
    f.channel,
    f.shoptype,
    f.hcoid,
    f.hcotypeid,
    f.statedescr,
    f.shortterritorydescr,
    f.branchid,
    f.branchname,
    l.col.ma_nvbh as slsperid,
    e.tencvbh,
    e.supid,
    e.tenquanlytt,
    e.asm,
    e.tenquanlykhuvuc,
    e.rsmid,
    e.tenquanlyvung,
    current_timestamp() + interval 7 hour as inserted_at
FROM `spatial-vision-343005.staging.d_manual_theo_doi_chon_qua_cmm_gd2_2024` a 
LEFT JOIN `staging.d_master_khachhang` f on f.custid = a.ma_kh
LEFT JOIN `warehouse.f_mapping_crs` l on l.custid = a.ma_kh 
LEFT JOIN `staging.d_users` e on e.manv = l.col.ma_nvbh;