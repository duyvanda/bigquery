CREATE VIEW `spatial-vision-343005.warehouse.giaohang 2`
AS WITH don_hang_va_doanh_so AS 
(
  SELECT 
    macongtycn, 
    IFNULL(sodontrahang,sodondathang) AS madhchung, --madhchung,
    SUM(doanhsochuavat) AS ds_tong_dh 
  FROM staging.f_sales a 
  GROUP BY 1,2
)

SELECT
    a.macongtycn,
    a.ngaychungtu,
    a.sodondathang,
    a.sodontrahang, 
    a.ngaytrahang,
    a.makhdms,
    a.tenkhachhang,
    a.tentinhkh,
    a.makenhkh,
    a.makenhphu,
    a.masanpham,
    a.soluong,
    a.manv,
    a.tencvbh,
    a.manvgh,
    a.manvghreal,
    a.tenquanlyvung,
    a.tenquanlytt,
    a.donvigiaohang,
    a.kieudonhang,
    a.trahangkhacthang,
    a.tennvghreal,
    a.doanhsochuavat,
    a.tenkhuvuc,
    a.tenquanhuyen,
    gh.delivery_date,
    b.role_luong_mds,
    b.role_luong_mds_phanloai, -- role_giaohang_tinhluong
    b.tenquanlytt AS sup_gh, -- sup_gh
    b.tenquanlykhuvuc AS mng_gh, --mng_gh 
    c.cluster_state,
    c.ltfromcrtd AS KPI_leadtime,
    d.crtd_datetime AS Ngay_tao_don,
    e.ketqualeadtime_giaitrinh,   --KET QUA LEADTME GIAI TRINH
    e.note AS Noidung_giaitrinh,                     --NOI DUNG GIAI TRINH
    FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', CURRENT_TIMESTAMP()) AS Thoi_gian,
    (IFNULL(dc.donvigiaohang, a.donvigiaohang)) AS donvigiaohang_dc, -- donvigiaohang_dc
    (IFNULL(IFNULL(dc.donvigiaohang, a.donvigiaohang),a.donvigiaohang)) AS donvigiaohang_fix, --donvigiaohang_fix
    (IFNULL(a.manvghreal, a.manvgh)) AS manvgh_final, -- manvgh_final
    (IFNULL(dc.manvghreal, (IFNULL(a.manvghreal, a.manvgh)))) AS ma_nvgh_tinhluong, --manvgh_fix
    (IFNULL(sodontrahang,a.sodondathang)) AS madhchung,--madhchung
    CASE WHEN makenhkh IN ('TP', 'PCL') THEN 'TP/PCL'
        WHEN makenhkh IN ('INS','CLC','MT') THEN 'INS/CLC/MT' 
    END AS dsgiaohang_phanloai, -- dsgiaohang_phanloai
    ds.ds_tong_dh,

    CASE 
        WHEN -- madon_tinh_giaohang
    (
        ABS(ds.ds_tong_dh ) > 0 
        AND (IFNULL(IFNULL(dc.donvigiaohang, a.donvigiaohang),a.donvigiaohang) IN ('Pha Nam', 'Chành xe'))  
        AND (IFNULL(dc.manvghreal, (IFNULL(a.manvghreal, a.manvgh)))) NOT LIKE '%GH%'
    ) THEN -- madhchung
    (IFNULL(sodontrahang,a.sodondathang))
    ELSE NULL
    END AS madon_tinh_giaohang,

    CASE 
        WHEN gh.delivery_date IS NOT NULL THEN 'Dondagiao'
        ELSE 'Donchuagiao' END AS Stt_gh ,    

    CASE 
        WHEN gh.delivery_date IS NOT NULL THEN TIMESTAMP_DIFF(gh.delivery_date, d.crtd_datetime, HOUR)
        WHEN gh.delivery_date IS NULL THEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), d.crtd_datetime, HOUR)
        END AS Full_leadtime    ,           --full lead time      

    CASE 
        WHEN 
        (CASE WHEN gh.delivery_date IS NOT NULL THEN TIMESTAMP_DIFF(gh.delivery_date, d.crtd_datetime, HOUR)
        WHEN gh.delivery_date IS NULL THEN TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), d.crtd_datetime, HOUR)
        END) <  c.ltfromcrtd THEN 'Dat' 
        ELSE 'Khong dat' END AS Danhgia_leadtime --Danhgia_leadtime

FROM `spatial-vision-343005.staging.f_sales` a
LEFT JOIN  `spatial-vision-343005.staging.d_master_khachhang` c ON a.makhdms = c.custid
LEFT JOIN `spatial-vision-343005.staging.sync_dms_dv` gh ON IFNULL(sodontrahang,sodondathang) = gh.ordernbr AND a.macongtycn = gh.branchid--joined chi nhanh
    AND gh.delivery_date IS NOT NULL AND gh.status = 'C'
LEFT JOIN `spatial-vision-343005.staging.d_dieuchinhmds`  dc ON a.macongtycn = dc.macongtycn AND (IFNULL(sodontrahang,a.sodondathang)) =  dc.sodondathang -- manvgh_dc    
LEFT JOIN  `spatial-vision-343005.staging.d_users` b ON (IFNULL(dc.manvghreal, (IFNULL(a.manvghreal, a.manvgh))) = b.manv) -- role_luong_mds
LEFT JOIN don_hang_va_doanh_so ds ON a.macongtycn = ds.macongtycn AND (IFNULL(sodontrahang, a.sodondathang)) = ds.madhchung
LEFT JOIN `spatial-vision-343005.staging.sync_dms_pda_so` d ON a.macongtycn = d.branchid AND (IFNULL(sodontrahang, a.sodondathang)) = d.ordernbr
LEFT JOIN `spatial-vision-343005.staging.d_giaitrinhlt_mds` e  ON a.macongtycn = e.branchid AND ds.madhchung = e.ordernbr

WHERE 
    ngaychungtu >= '2024-02-01'  
    AND trahangkhacthang IS NOT true
    AND a.makenhkh NOT IN ('NB','OTH_LAB')
    AND (IFNULL(IFNULL(dc.donvigiaohang, a.donvigiaohang),a.donvigiaohang)) IN ('Pha Nam','Chành xe') 
    AND (IFNULL(IFNULL(dc.donvigiaohang, a.donvigiaohang),a.donvigiaohang)) IS NOT NULL
    AND a.masanpham NOT LIKE 'V%'
    AND (IFNULL(dc.manvghreal, (IFNULL(a.manvghreal, a.manvgh)))) NOT LIKE '%GH%';