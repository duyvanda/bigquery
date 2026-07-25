CREATE VIEW `spatial-vision-343005.warehouse.Theo_doi_gia_ban_le_TP_KHchuacham`
AS WITH dc AS 
(
    SELECT 
        custid, 
        slsperid, 
        invtid, 
        descr, 
        channel, 
        hcotypeid, 
        invtname
    FROM `spatial-vision-343005.staging.f_theo_doi_binh_on_gia_tp`
)

SELECT 
    k.custid, 
    k.custname, 
    a.slsperid, 
    e.tencvbh, 
    a.invtid, 
    dc.custid AS custid_1, 
    dc.slsperid AS slsperid_1, 
    dc.invtid AS invtid_1, 
    k.districtdescr, -- Tỉnh
    k.channel, 
    k.hcotypeid, -- Phân loại HCO
    x.descr1, -- Tên tắt sản phẩm
    e.supid, 
    e.tenquanlytt, 
    IFNULL(z.DS_Quy,0) as DS_Quy,
    CONCAT(a.invtid,' - ',x.descr1) as masp_tensp,
    CONCAT(k.custid,' - ',k.custname) as makh_tenkh
  
FROM `spatial-vision-343005.staging.d_posm_regis` a
LEFT JOIN 
(
    SELECT       -- TINH DOANH SO QUÝ                                         
        makhdms,
        SUM(doanhsocovat) AS DS_Quy
    FROM `spatial-vision-343005.staging.f_sales`     
    WHERE masanpham IN ('OH031', 'T302201014', 'T302201018') AND ngaychungtu >= '2024-01-01' 
    GROUP BY 1
) z ON a.custid = z.makhdms 

LEFT JOIN dc ON a.slsperid = dc.slsperid AND a.custid = dc.custid AND a.invtid = dc.invtid
LEFT JOIN `spatial-vision-343005.staging.d_users` e ON a.slsperid = e.manv
LEFT JOIN `staging.d_master_khachhang` k ON a.custid = k.custid
LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid` x ON a.invtid = x.invtid

WHERE dc.custid IS NULL
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,z.DS_Quy
;