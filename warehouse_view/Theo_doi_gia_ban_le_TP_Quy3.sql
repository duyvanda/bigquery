CREATE VIEW `spatial-vision-343005.warehouse.Theo_doi_gia_ban_le_TP_Quy3`
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
    WHERE visitdate >= '2024-07-01' AND visitdate <= '2024-07-31'  and posmid = 'CTBOG 2401-CT Bình Ổn Giá 2024'
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
    WHERE visitdate >= '2024-08-01' AND visitdate <= '2024-08-31'  and posmid = 'CTBOG 2401-CT Bình Ổn Giá 2024'
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
    WHERE visitdate >= '2024-09-01' AND visitdate <= '2024-09-30'  and posmid = 'CTBOG 2401-CT Bình Ổn Giá 2024'
    QUALIFY row = 1 
),
 
doanh_so_quy AS (
    SELECT                                              
        makhdms,
        SUM(doanhsocovat) AS ds_quy
    FROM `spatial-vision-343005.staging.f_sales`     
    WHERE masanpham IN ('OH031', 'T302201014', 'T302201018') AND ngaychungtu >= '2024-07-01' AND ngaychungtu <= '2024-09-30' 
    GROUP BY 1
) ,


NGAY_GAN_NHAT_QUY AS (
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
      ELSE 'Không đạt'
       END AS xet_cham_quy
        
    FROM `spatial-vision-343005.staging.f_theo_doi_binh_on_gia_tp` v
    WHERE visitdate >= '2024-07-01' AND visitdate <= '2024-09-30'  and posmid = 'CTBOG 2401-CT Bình Ổn Giá 2024'
    QUALIFY row = 1 
)

SELECT 
    o.supid,
    o.tenquanlytt AS ten_qltt,
    dc.visitdate AS visitdate_T7,
    ng.visitdate AS visitdate_T8,
    n.visitdate AS visitdate_T9,
    -- n2.xet_cham_quy,
    case when r.slsperid = 'MR2610' then 'MR3197' else r.slsperid end as slsperid, 
    o.tencvbh AS ten_nv,
    r.custid, 
    k.custname, 
    r.invtid,
    x.descr1, -- Tên tắt sản phẩm
    k.channel,
    k.districtdescr AS Quan,
    k.statedescr AS Tinh,
    CONCAT(r.invtid, ' - ', x.descr1) AS masp_tensp,
  --  CONCAT(k.custid,' - ',k.custname) AS makh_tenkh,
    CONCAT(r.custid,' - ',custname) as makh_tenkh,

    IFNULL(ds.ds_quy, 0) AS ds_quy,
    xet_cham_T7,
    xet_cham_T8,
    xet_cham_T9,

 --   CASE 
  --      WHEN xet_cham_T4 = 'Đạt' AND xet_cham_T5 = 'Đạt' AND xet_cham_T6 = 'Đạt' AND IFNULL(ds.ds_quy, 0) >= 1000000 THEN 'Đạt'
  --      ELSE 'Không đạt' 
   -- END AS xet_dat_quy

--  CASE WHEN 
--  (
--     case
--     when xetthangcham = '5,6' and xet_cham_T5 = 'Đạt' AND xet_cham_T6 = 'Đạt' 
--     AND IFNULL(ds.ds_quy, 0) >= 1000000 THEN 'Đạt'
--     ELSE 'Không đạt' 
--     end )  = 'Đạt'

--  OR

--  (   
--     case
--     when  IFNULL(xetthangcham, 'NONE') != '5,6' and xet_cham_T4 = 'Đạt' AND xet_cham_T5 = 'Đạt' AND xet_cham_T6 = 'Đạt'
--     AND IFNULL(ds.ds_quy, 0) >= 1000000 THEN 'Đạt'
--     ELSE 'Không đạt' 
--     end ) = 'Đạt'

-- THEN 'Đạt' ELSE 'Không đạt'    END AS xet_dat_quy


CASE WHEN 
xet_cham_T7 = 'Đạt' AND xet_cham_T8 = 'Đạt' AND xet_cham_T9 = 'Đạt' THEN 'Đạt'
ELSE 'Không đạt' 
END AS xet_cham_quy,

CASE WHEN 
xet_cham_T7 = 'Đạt' AND xet_cham_T8 = 'Đạt' AND xet_cham_T9 = 'Đạt'
AND IFNULL(ds.ds_quy, 0) >= 1000000 THEN 'Đạt'
ELSE 'Không đạt' 
END AS xet_dat_quy
    
FROM `spatial-vision-343005.staging.d_posm_regis` r
LEFT JOIN doanh_so_quy ds ON r.custid = ds.makhdms
LEFT JOIN ngay_gan_nhat_thang7 dc ON r.custid = dc.custid AND r.invtid = dc.invtid
LEFT JOIN ngay_gan_nhat_thang8 ng ON r.custid = ng.custid AND r.invtid = ng.invtid
LEFT JOIN ngay_gan_nhat_thang9 n ON r.custid = n.custid AND r.invtid = n.invtid
LEFT JOIN NGAY_GAN_NHAT_QUY     n2 ON r.custid = n2.custid and r.invtid = n2.invtid
LEFT JOIN `spatial-vision-343005.staging.d_users` o ON (case when r.slsperid = 'MR2610' then 'MR3197' else r.slsperid end) = o.manv
LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid` x ON r.invtid = x.invtid
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` k ON r.custid = k.custid
LEFT JOIN `spatial-vision-343005.staging.d_dskh_xet_cham_bog`  w on r.custid = w.makh
where r.accumulateid = '2401-CTBOG-CPA62-NT-QT-CTD'
-- and r.custid = 'P4710-0105'
;