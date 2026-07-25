CREATE VIEW `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2_extend_manual_upload`
AS With manual_upload_hinh_anh_bbgh as
  (
    select distinct thong_tin_don_hang_upload from staging.d_mds_upload_hinh_anh_bbgh where thong_tin_don_hang_upload not like '%PBNH%'
    UNION DISTINCT
    select distinct ordernbr from staging.d_mds_upload_hinh_anh_bbgh a
    LEFT JOIN (select distinct branchid, reportid, ordernbr from staging.sync_dms_rd) c on a.thong_tin_don_hang_upload = c.reportid and a.chi_nhanh = c.branchid
    where thong_tin_don_hang_upload like '%PBNH%'
  )
SELECT a.*,
case when n5.thong_tin_don_hang_upload is not null then 'da_up' else null end as da_up_manual_hinh_anh_bbgh
FROM `spatial-vision-343005.warehouse.f_baocao_daily_performance_mds_new_v2` a
LEFT JOIN manual_upload_hinh_anh_bbgh n5 on a.ma_dh = n5.thong_tin_don_hang_upload
-- where ma_dh = 'DL5-1124-00672';