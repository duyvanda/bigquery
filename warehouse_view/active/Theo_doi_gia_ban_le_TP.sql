CREATE VIEW `spatial-vision-343005.warehouse.Theo_doi_gia_ban_le_TP`
AS WITH ngay_gan_nhat AS 
(
SELECT
slsperid,
custid,
invtid,
visitdate,
result,
ROW_NUMBER() OVER (PARTITION BY slsperid, custid, invtid ORDER BY visitdate DESC) AS row
FROM `spatial-vision-343005.staging.f_theo_doi_binh_on_gia_tp` v
where visitdate >= '2024-01-01' and visitdate <= '2024-03-31' 
QUALIFY row = 1 
),

 
doanh_so_quy AS 
(
 SELECT                                              
        makhdms,
        SUM(doanhsocovat) AS ds_quy
    FROM `spatial-vision-343005.staging.f_sales`     
    WHERE masanpham IN ('OH031', 'T302201014', 'T302201018') AND ngaychungtu >= '2024-01-01' and ngaychungtu <= '2024-03-31' 
    GROUP BY 1
)


SELECT 
    o.supid,
    o.tenquanlytt as ten_qltt,
    visitdate,
    r.slsperid, 
    o.tencvbh as ten_nv,
    k.custid, 
    k.custname, 
    r.invtid,
    x.descr1, -- Tên tắt sản phẩm
    k.channel,
    k.districtdescr AS Quan,
    k.statedescr AS Tinh,
    CONCAT(r.invtid, ' - ', x.descr1) AS masp_tensp,
    CONCAT(k.custid,' - ',k.custname) as makh_tenkh,
    IFNULL(ds.ds_quy,0) AS ds_quy,

    CASE WHEN  dc.result = 'Đạt' THEN 'Đạt'
    WHEN dc.result IS NULL THEN 'Chưa chấm' 
    ELSE 'Không đạt'
    END AS xet_cham_quy,
  
    CASE WHEN  dc.result = 'Đạt' AND IFNULL(ds.ds_quy,0) >= 1000000 THEN 'Đạt'
    WHEN IFNULL(ds.ds_quy,0) < 1000000  THEN 'Không đạt'
    ELSE null
    END AS xet_dat_quy


      
FROM `spatial-vision-343005.staging.d_posm_regis`    r
LEFT JOIN doanh_so_quy     ds      ON r.custid = ds.makhdms
LEFT JOIN ngay_gan_nhat    dc      ON r.slsperid = dc.slsperid AND r.custid = dc.custid AND r.invtid = dc.invtid
LEFT JOIN `spatial-vision-343005.staging.d_users`     o     ON r.slsperid = o.manv
LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid`     x     ON r.invtid = x.invtid
LEFT JOIN `staging.d_master_khachhang`     k     ON r.custid = k.custid
--where dc.custid = 'M1401079'





--GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9,ds.ds_quy, o.supid, o.tenquanlytt,dc.slsperid,dc.custid,dc.invtid

;