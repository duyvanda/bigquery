CREATE VIEW `spatial-vision-343005.warehouse.View_Theo_doi_gia_ban_le_CTD_Quy3`
AS WITH ngay_gan_nhat_thang7 AS (
    SELECT
        -- slsperid,
        custid,
        invtid,
        visitdate,
        result,
        -- ROW_NUMBER() OVER (PARTITION BY slsperid, custid, invtid ORDER BY visitdate DESC) AS row,
        ROW_NUMBER() OVER (PARTITION BY custid, invtid ORDER BY visitdate DESC) AS row,
        CASE 
            WHEN result = 'Đạt' THEN 'Đạt'
          --  WHEN result IS NULL THEN 'Chưa chấm' 
            ELSE 'Không đạt'
        END AS xet_cham_T7
    FROM `spatial-vision-343005.staging.f_theo_doi_binh_on_gia_tp` v
    WHERE visitdate >= '2024-07-01' AND visitdate <= '2024-07-31'  and posmid != 'CTBOG 2401-CT Bình Ổn Giá 2024'
    QUALIFY row = 1 
),

ngay_gan_nhat_thang8 AS (
    SELECT
        slsperid,
        custid,
        invtid,
        visitdate,
        result,
        -- ROW_NUMBER() OVER (PARTITION BY slsperid, custid, invtid ORDER BY visitdate DESC) AS row,
        ROW_NUMBER() OVER (PARTITION BY custid, invtid ORDER BY visitdate DESC) AS row,
        CASE 
            WHEN result = 'Đạt' THEN 'Đạt'
         --   WHEN result IS NULL THEN 'Chưa chấm' 
            ELSE 'Không đạt'
        END AS xet_cham_T8
    FROM `spatial-vision-343005.staging.f_theo_doi_binh_on_gia_tp` v
    WHERE visitdate >= '2024-08-01' AND visitdate <= '2024-08-31'  and posmid != 'CTBOG 2401-CT Bình Ổn Giá 2024'
    QUALIFY row = 1  
),

ngay_gan_nhat_thang9 AS (
    SELECT
        slsperid,
        custid,
        invtid,
        visitdate,
        result,
        -- ROW_NUMBER() OVER (PARTITION BY slsperid, custid, invtid ORDER BY visitdate DESC) AS row,
        ROW_NUMBER() OVER (PARTITION BY custid, invtid ORDER BY visitdate DESC) AS row,
        CASE 
            WHEN result = 'Đạt' THEN 'Đạt'
 --           WHEN result IS NULL THEN 'Chưa chấm' 
            ELSE 'Không đạt'
        END AS xet_cham_T9
    FROM `spatial-vision-343005.staging.f_theo_doi_binh_on_gia_tp` v
    WHERE visitdate >= '2024-09-01' AND visitdate <= '2024-09-30'  and posmid != 'CTBOG 2401-CT Bình Ổn Giá 2024'
    QUALIFY row = 1 
)
 
, doanh_so_quy AS (
    SELECT                                              
        makhdms,
        SUM(doanhsocovat) AS doanhsocovat_tongquy
    FROM `spatial-vision-343005.staging.f_sales`     
    WHERE masanpham IN ('OH031', 'OH059',  'T302201014', 'T302201017', 'T302201018', 'T302203002') AND ngaychungtu >= '2024-07-01' AND ngaychungtu <= '2024-09-30' 
    GROUP BY 1
)

, doanh_so_quy_tung_sp AS (
    SELECT                                              
        makhdms,
        masanpham,
        SUM(doanhsocovat) AS doanhsocovat_tongquy,
        sum(Case when extract(month from ngaychungtu)= 7 then doanhsocovat else 0 end ) as doanhsocovat_t7,
        sum(Case when extract(month from ngaychungtu)= 8 then doanhsocovat else 0 end ) as doanhsocovat_t8,
        sum(Case when extract(month from ngaychungtu)= 9 then doanhsocovat else 0 end ) as doanhsocovat_t9,
    FROM `spatial-vision-343005.staging.f_sales`     
    WHERE masanpham IN ('OH031', 'OH059',  'T302201014', 'T302201017', 'T302201018', 'T302203002') AND ngaychungtu >= '2024-07-01' AND ngaychungtu <= '2024-09-30' 
    GROUP BY 1,2
) 

-- , NGAY_GAN_NHAT_QUY AS (
--     SELECT
--         slsperid,
--         custid,
--         invtid,
--         visitdate,
--         result,
--         -- ROW_NUMBER() OVER (PARTITION BY slsperid, custid, invtid ORDER BY visitdate DESC) AS row,
--         ROW_NUMBER() OVER (PARTITION BY custid, invtid ORDER BY visitdate DESC) AS row,
--       CASE 
--        WHEN result = 'Đạt' THEN 'Đạt'
--       ELSE 'Không đạt'
--        END AS xet_cham_quy
        
--     FROM `spatial-vision-343005.staging.f_theo_doi_binh_on_gia_tp` v
--     WHERE visitdate >= '2024-07-01' AND visitdate <= '2024-09-30'  and posmid != 'CTBOG 2401-CT Bình Ổn Giá 2024'
--     QUALIFY row = 1 
-- )

SELECT 
    o.supid,
    o.tenquanlytt AS ten_qltt,
    dc.visitdate AS visitdate_T7,
    ng.visitdate AS visitdate_T8,
    n.visitdate AS visitdate_T9,
    "khong_dung" as xet_cham_quy,
    r.slsperid, 
    o.tencvbh AS ten_nv,
    r.custid, 
    k.custname, 
    r.invtid,
    x.descr1, -- Tên tắt sản phẩm
    k.channel,
    k.districtdescr AS Quan,
    k.statedescr AS Tinh,
    CONCAT(r.invtid, ' - ', x.descr1) AS masp_tensp,
    CONCAT(r.custid,' - ',custname) as makh_tenkh,
    dst.doanhsocovat_tongquy as doanhsocovat_tongquy,
    IFNULL(ds.doanhsocovat_tongquy, 0) AS doanhsocovat_tongquy_tung_sp,
    IFNULL(ds.doanhsocovat_t7, 0) AS doanhsocovat_t7_tung_sp,
    IFNULL(ds.doanhsocovat_t8, 0) AS doanhsocovat_t8_tung_sp,
    IFNULL(ds.doanhsocovat_t9, 0) AS doanhsocovat_t9_tung_sp,
    xet_cham_T7,
    xet_cham_T8,
    xet_cham_T9
    
FROM `spatial-vision-343005.staging.d_posm_regis` r
LEFT JOIN doanh_so_quy dst ON r.custid = dst.makhdms
LEFT JOIN doanh_so_quy_tung_sp ds ON r.custid = ds.makhdms and r.invtid = ds.masanpham
LEFT JOIN ngay_gan_nhat_thang7 dc ON r.custid = dc.custid AND r.invtid = dc.invtid
LEFT JOIN ngay_gan_nhat_thang8 ng ON r.custid = ng.custid AND r.invtid = ng.invtid
LEFT JOIN ngay_gan_nhat_thang9 n ON r.custid = n.custid AND r.invtid = n.invtid
-- LEFT JOIN NGAY_GAN_NHAT_QUY     n2 ON r.custid = n2.custid and r.invtid = n2.invtid
LEFT JOIN `spatial-vision-343005.staging.d_users` o ON r.slsperid = o.manv
LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid` x ON r.invtid = x.invtid
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` k ON r.custid = k.custid
LEFT JOIN `spatial-vision-343005.staging.d_dskh_xet_cham_bog`  w on r.custid = w.makh
where r.accumulateid = '2408-CTTLXO-CPA50-CTD';