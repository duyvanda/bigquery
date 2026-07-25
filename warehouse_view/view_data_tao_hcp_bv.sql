CREATE VIEW `spatial-vision-343005.warehouse.view_data_tao_hcp_bv`
AS with d_avg_ds_6t as
(

    SELECT

    pubcustid,

    SUM(doanhsochuavat)/6 as avg_ds_6t

    FROM

    `warehouse.f_raw_data_sales_yoy`

    WHERE

    DATE(ngaychungtu) >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
    

    GROUP BY

    pubcustid

    HAVING SUM(doanhsochuavat) > 1000

)
, d_shoptype AS (
        SELECT
            pubcustid,
            STRING_AGG(
                shoptype, '&' 
                ORDER BY 
                    CASE WHEN branchid NOT LIKE 'MR%' THEN 0 ELSE 1 END ASC,
                    CASE WHEN shoptype = 'DLPP_CLC' THEN 1 ELSE 0 END ASC, 
                    shoptype ASC
            ) AS shoptype
        FROM (
            SELECT
                pubcustid,
                shoptype,
                branchid
            FROM `spatial-vision-343005.staging.d_master_khachhang`
            WHERE pubcustid IS NOT NULL 
            GROUP BY 
                pubcustid,
                shoptype,
                branchid
        )
        GROUP BY 
            pubcustid
)

, d_doanh_so_nam AS (
        SELECT
            s.pubcustid,
            SUM(CASE WHEN s.year = 2024 THEN s.doanhsochuavat ELSE 0 END) AS doanh_so_2024,
            SUM(CASE WHEN s.year = 2025 THEN s.doanhsochuavat ELSE 0 END) AS doanh_so_2025,
            SUM(CASE WHEN s.year = 2026 THEN s.doanhsochuavat ELSE 0 END) AS doanh_so_2026
        FROM `warehouse.f_raw_data_sales_yoy` s
       -- LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` m ON s.makhdms = m.custid
        WHERE s.year IN (2024, 2025, 2026)
        AND s.makhdms not in ('014916', '014937','014938') -- Kim Đô
        AND s.makhdms not in ('016364', '016362', '016361', '016360', '016365', '016363', '016023', '016022', '016021', '016020', '016010', '014916', '014937', '014938','019009') -- Gonsa
        AND s.makhdms not in ('019738','019739') -- Tây Âu
        GROUP BY 
            s.pubcustid
)

SELECT
a.manv,
a.sdt,
a.email,
a.ten_hcp,
a.hco_bv,
a.ngay_sinh,
a.thang_sinh,
a.nam_sinh,
a.gioi_tinh,
a.kenh_lam_viec,
a.phan_loai_hcp,
a.chuc_danh,
a.chuc_vu,
a.nganh,
a.nganh_chuyen_khoa, -- Khoa phòng HCP làm việc
COALESCE(REGEXP_EXTRACT(nganh_chuyen_khoa, r'([^-]+)-'), nganh_chuyen_khoa) AS khoa_phong_lam_viec,
REGEXP_EXTRACT(nganh_chuyen_khoa, r'-([^-]+)') AS khoa_phong_lam_viec_khac,
a.nganh_khoa_phong, -- Chuyên khoa HCP học
COALESCE(REGEXP_EXTRACT(nganh_khoa_phong, r'([^-]+)-'), nganh_khoa_phong) AS chuyen_khoa_hcp_hoc,
REGEXP_EXTRACT(nganh_khoa_phong, r'-([^-]+)') AS chuyen_khoa_hcp_hoc_khac,
a.co_lam_them,
a.hco_lam_them,
a.chuc_vu_lam_them,
a.hco_chung_bv,
a.ma_hcp_1,
a.ma_hcp_2,
a.form_input,
a.inserted_at,
a.uuid,
IFNULL(a.so_luot_kham,0.0) as so_luot_kham,
IFNULL(a.so_tiem_nang,0.0) as so_tiem_nang,
IFNULL(t.avg_ds_6t, 0.0) as avg_ds_6t,
a.lupd_at,
a.ma_crs1,
a.ma_crs2,
a.ma_crs3,
a.ma_crm1,
a.concat_crs_sup,
p.custname as pubcustname,
a.statedescr,
a.shortterritorydescr,
a.hcotypeid,
a.inactive,
a.tinh,
a.quan_huyen,
a.phuong_xa,
a.dia_chi,
a.status,
a.p_manv,
a.p_version,
f.tencvbh as crs0,
b.tencvbh as crs1,
c.tencvbh as crs2,
d.tencvbh as crs3,
e.tenquanlytt as tencrm1,
b.asm,
b.tenquanlykhuvuc,
/* update thêm giúp mình nếu khoa_phong_lam_viec = 'DƯỢC' THÌ TRẢ VỀ NA */
CASE 
        WHEN COALESCE(REGEXP_EXTRACT(nganh_chuyen_khoa, r'([^-]+)-'), nganh_chuyen_khoa) = 'DƯỢC' THEN 'NA'
        ELSE IFNULL(
            staging_temp.fun_get_phan_hang_hcp(kenh_lam_viec, chuc_vu, t.avg_ds_6t, so_luot_kham, so_tiem_nang),
            'NA'
        )
    END AS phan_hang_hcp,

s.shoptype as makenhphu,

CASE 
        WHEN a.kenh_lam_viec in ('PCL','GO','ED') THEN a.kenh_lam_viec
        WHEN s.shoptype in ('PCL','GO','ED') THEN s.shoptype
        WHEN SPLIT(s.shoptype, '&')[SAFE_OFFSET(0)] IN ('INS1', 'CLC1', 'CLC4', 'INS2', 'CLC2') THEN 'BV'
        WHEN SPLIT(s.shoptype, '&')[SAFE_OFFSET(0)] IN ('INS3', 'CLC3') THEN 'PK'
        WHEN SPLIT(s.shoptype, '&')[SAFE_OFFSET(0)] IN ('PCL', 'GO', 'ED') THEN SPLIT(s.shoptype, '&')[SAFE_OFFSET(0)]
    END AS don_vi,
    
    CASE 
        WHEN a.kenh_lam_viec in ('PCL','GO','ED') THEN a.kenh_lam_viec
        WHEN SPLIT(s.shoptype, '&')[SAFE_OFFSET(0)] IN ('INS1', 'CLC1', 'CLC4') THEN 'BVNN'
        WHEN SPLIT(s.shoptype, '&')[SAFE_OFFSET(0)] IN ('INS2', 'CLC2') THEN 'BVTN'
        WHEN SPLIT(s.shoptype, '&')[SAFE_OFFSET(0)] IN ('INS3', 'CLC3') THEN 'PK'
        WHEN SPLIT(s.shoptype, '&')[SAFE_OFFSET(0)] IN ('PCL', 'GO', 'ED') THEN SPLIT(s.shoptype, '&')[SAFE_OFFSET(0)]
    END AS kenh_hco_chung,

IFNULL(y.doanh_so_2024, 0.0) AS doanh_so_2024,
IFNULL(y.doanh_so_2025, 0.0) AS doanh_so_2025,
IFNULL(y.doanh_so_2026, 0.0) AS doanh_so_2026,
ROW_NUMBER() OVER(
    PARTITION BY a.hco_bv
    ORDER BY a.status ASC, a.ma_hcp_2, a.inserted_at DESC, a.uuid
) AS stt_hcp_trong_hco
FROM `spatial-vision-343005.staging.f_data_tao_hcp_bv_by_users` a
left join `spatial-vision-343005.staging.d_users` b on a.ma_crs1 = b.manv
left join `spatial-vision-343005.staging.d_users` c on a.ma_crs2 = c.manv
left join `spatial-vision-343005.staging.d_users` d on a.ma_crs3 = d.manv
left join `spatial-vision-343005.staging.d_users` e on a.ma_crm1 = e.manv
left join `spatial-vision-343005.staging.d_users` f on a.manv = f.manv
left join `d_avg_ds_6t` t on t.pubcustid = hco_bv
LEFT JOIN d_doanh_so_nam y ON y.pubcustid = a.hco_bv
LEFT JOIN d_shoptype s ON s.pubcustid = a.hco_bv
LEFT JOIN `staging.d_public_cust` p on p.pubcust = a.hco_bv
;