CREATE VIEW `spatial-vision-343005.warehouse.f_view_kenh_sp`
AS WITH data_sales AS (
    SELECT 
        'DH' AS datatype,
        DATE(thang) AS thang,
        makhdms,
        makenh_moi,
        maphanloaihco,
        sodondathang,
        masanpham,
        SUM(soluong) AS sl,
        SUM(doanhsochuavat) AS ds,
        MAX(updated_at) AS updated_at
    FROM 
        `warehouse.f_sales_crs`
    WHERE 
        ngaychungtu >= '2024-01-01' 
        AND makenh_moi IN ('TP', 'PCL', 'INS', 'MT', 'CLC')
    GROUP BY 
        thang, makhdms, makenh_moi, maphanloaihco, sodondathang, masanpham
    HAVING 
        sl >= 10

    UNION ALL 

    SELECT 
        'Tháng' AS datatype,
        DATE(thang) AS thang,
        makhdms,
        makenh_moi,
        maphanloaihco,
        '' AS sodondathang,
        masanpham,
        SUM(soluong) AS sl,
        SUM(doanhsochuavat) AS ds,
        MAX(updated_at) AS updated_at
    FROM 
        `warehouse.f_sales_crs`
    WHERE 
        ngaychungtu >= '2024-01-01' 
        AND makenh_moi IN ('TP', 'PCL', 'INS', 'MT', 'CLC')
    GROUP BY 
        thang, makhdms, makenh_moi, maphanloaihco, masanpham
    HAVING 
        sl >= 10
)
SELECT 
    a.*,
    b.descr,
    b.descr1
FROM 
    data_sales a
LEFT JOIN 
    `staging.d_dms_master_invtid` b 
ON 
    a.masanpham = b.invtid
ORDER BY 
    datatype, thang;

;