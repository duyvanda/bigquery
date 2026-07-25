CREATE FUNCTION `spatial-vision-343005`.staging_temp.fun_get_phan_hang_hcp(kenh_lam_viec STRING, chuc_vu STRING, avg_ds_6t FLOAT64, so_luot_kham FLOAT64, so_tiem_nang FLOAT64) RETURNS STRING
AS (
CASE
    WHEN kenh_lam_viec = 'GO' AND chuc_vu = 'Nhân viên' THEN 'GB'
    WHEN kenh_lam_viec = 'GO' AND chuc_vu != 'Nhân viên' THEN 'GA'
    WHEN kenh_lam_viec = 'ED' AND chuc_vu in ('Nhân viên','Giảng viên') THEN 'EB'
    WHEN kenh_lam_viec = 'ED' AND chuc_vu not in ('Nhân viên','Giảng viên') THEN 'EA'
    WHEN kenh_lam_viec = 'PCL' AND avg_ds_6t < 500000 THEN 'PC3'
    WHEN kenh_lam_viec = 'PCL' AND avg_ds_6t >= 500000 and so_luot_kham >=900 THEN 'PC1'
    WHEN kenh_lam_viec = 'PCL' AND avg_ds_6t >= 500000 AND so_luot_kham >= 900 THEN 'PC1'
    WHEN kenh_lam_viec = 'PCL' AND avg_ds_6t >= 500000 AND so_luot_kham >= 300 AND so_luot_kham < 900 THEN 'PC2'
    WHEN kenh_lam_viec = 'PCL' AND avg_ds_6t >= 500000 AND avg_ds_6t < 3000000 THEN 'PC2'
    WHEN kenh_lam_viec = 'PCL' AND avg_ds_6t >= 3000000 THEN 'PC1'
    WHEN kenh_lam_viec IN ('CLC & INS','CLC','INS') AND (so_tiem_nang > 30 OR (so_tiem_nang >= 5 AND so_luot_kham >= 480)) THEN 'KA'
    WHEN kenh_lam_viec IN ('CLC & INS','CLC','INS') AND (so_tiem_nang > 20 OR (so_tiem_nang >= 5 AND so_luot_kham >= 360)) THEN 'KB'
    WHEN kenh_lam_viec IN ('CLC & INS','CLC','INS') AND (so_tiem_nang >= 5 AND so_luot_kham >= 120) THEN 'KC'
    WHEN kenh_lam_viec IN ('CLC & INS','CLC','INS') AND (so_tiem_nang < 5 OR so_luot_kham < 120 ) THEN 'NU'
    ELSE NULL
END
);