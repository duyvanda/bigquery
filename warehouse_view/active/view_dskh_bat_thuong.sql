CREATE VIEW `spatial-vision-343005.warehouse.view_dskh_bat_thuong`
AS with 
base_date as (
 SELECT
    thang
FROM
        UNNEST(
            GENERATE_DATE_ARRAY(
                DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH),
                DATE_TRUNC(CURRENT_DATE(), MONTH),
                INTERVAL 1 MONTH
            )
        ) AS thang
    ORDER BY thang
)

,base_time as (
 SELECT 
        DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH) as thang_bao_cao, -- Tháng vừa kết thúc  
)

,data_sale as (
SELECT
ngaychungtu,
DATE(thang) as thang,
thang_number,
ma_crm,
tenquanlytt,
statedescr,
makhdms,
tenkhachhang,
makenhkh_cu,
makenhphu_cu,
manv,
tencvbh,
sodondathang,
masanpham,
tensanphamviettat,
tensanphamnb,
CASE WHEN masanpham in ('T302201014','T302201018','OH031','OH044','EH086','EH115','EH087','EH092') THEn 'Hot'
ELSE NULL END as is_sp_hot,
SUM(doanhsocovat) as doanhsocovat,
SUM(soluong) as soluong
FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
CROSS JOIN base_time p
where makenhkh_cu in ('TP')
AND DATE(ngaychungtu) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH)
AND makhdms not in ('014916', '014937','014938','MR0081') -- Kim Đô Mã, MR0081 của a Chiến
AND makhdms not in ('016010', '016020','016022','016023','016021','016363','016364','016361','016360','016365','016362') -- Gonsa
GROUP BY ALL
)
,monthly as (
SELECT
k.makhdms,
b.thang
FROM base_date b
CROSS JOIN (SELECT DISTINCT makhdms FROM data_sale ) k
ORDER BY k.makhdms,b.thang   
)
----- dskh biến động theo sp hot
,monthly_sales AS (
    SELECT
    makhdms,
    CAST(thang AS DATE) as thang,
    SUM(doanhsocovat) AS ds_thang_all_sp,
    SUM(Case when is_sp_hot = 'Hot' then doanhsocovat else 0 end) as ds_thang_sp_hot,
    COUNT(DISTINCT sodondathang) as sl_dh_thang
    FROM data_sale
    GROUP BY makhdms,thang
)
,d_avg_ds_6t as
(
    SELECT
    m.thang,
    m.makhdms,
    IFNULL(s.ds_thang_all_sp,0) as ds_thang_all_sp,
    IFNULL(s.ds_thang_sp_hot,0) as ds_thang_sp_hot,
    AVG(IFNULL(s.ds_thang_all_sp,0)) OVER (PARTITION BY m.makhdms ORDER BY m.thang ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING)  as avg_ds_6t_all_sp,
    AVG(IFNULL(s.ds_thang_sp_hot,0)) OVER (PARTITION BY m.makhdms ORDER BY m.thang ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING)  as avg_ds_6t_sp_hot,
    FROM monthly m
    LEFT JOIN monthly_sales s ON m.thang = s.thang and m.makhdms = s.makhdms
    GROUP BY m.makhdms,m.thang,s.ds_thang_all_sp,s.ds_thang_sp_hot
)

,monthly_sp as (
SELECT
k.masanpham,
thang
FROM base_date b
CROSS JOIN (SELECT DISTINCT masanpham FROM data_sale ) k
ORDER BY k.masanpham,b.thang   
)

,dskh_yt1 as (
SELECT
a.makhdms,
m.thang,
m.ds_thang_sp_hot,
a.avg_ds_6t_sp_hot
FROM d_avg_ds_6t a
JOIN monthly_sales m ON a.makhdms = m.makhdms and m.thang = a.thang
WHERE m.ds_thang_all_sp - a.avg_ds_6t_sp_hot > a.avg_ds_6t_sp_hot * 2
AND m.ds_thang_all_sp - a.avg_ds_6t_sp_hot > 5000000
)
,ds_3_thang as (
SELECT
makhdms,
thang,
------ sản phẩm hot
SUM(
    CASE WHEN thang_number = EXTRACT(MONTH FROM CURRENT_DATE())
    AND is_sp_hot = 'Hot' 
    THEN doanhsocovat ELSE NULL END) as ds_thang_ht,
SUM(
    CASE WHEN thang_number =  EXTRACT(MONTH FROM DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH))
    AND is_sp_hot = 'Hot' 
    THEN doanhsocovat ELSE NULL END) as ds_thang_t2,

SUM(
    CASE WHEN thang_number =  EXTRACT(MONTH FROM DATE_SUB(CURRENT_DATE(), INTERVAL 2 MONTH))
    AND is_sp_hot = 'Hot' 
    THEN doanhsocovat ELSE NULL END) as ds_thang_t1,

---- tất cả các sp

SUM(
    CASE WHEN thang_number = EXTRACT(MONTH FROM CURRENT_DATE()) 
    THEN doanhsocovat ELSE NULL END) as ds_thang_ht_all,
SUM(
    CASE WHEN thang_number =  EXTRACT(MONTH FROM DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH)) 
    THEN doanhsocovat ELSE NULL END) as ds_thang_t2_all,

SUM(
    CASE WHEN thang_number =  EXTRACT(MONTH FROM DATE_SUB(CURRENT_DATE(), INTERVAL 2 MONTH)) 
    THEN doanhsocovat ELSE NULL END) as ds_thang_t1_all,

FROM data_sale
WHERE DATE(ngaychungtu) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH), MONTH)
GROUP BY ALL
)
,dskh_yt2 as (
SELECT
makhdms,
ds_thang_ht,
thang,
IFNULL(ds_thang_t1,0) as ds_thang_t1,
IFNULL(ds_thang_t2,0) as ds_thang_t2,
FROM ds_3_thang
WHERE IFNULL(ds_thang_t1,0) + IFNULL(ds_thang_t2,0) = 0
AND ds_thang_ht >= 5000000
)

,dskh_yt3 as (
SELECT
makhdms,
thang,
COUNT(DISTINCT sodondathang) as sl_dh_hien_tai
FROM data_sale
WHERE 
is_sp_hot = 'Hot'
GROUP BY ALL
HAVING sl_dh_hien_tai > 6
ORDER BY thang
)

------- ds sp biến động

,monthly_sales_sp AS (
SELECT
masanpham,
CAST(thang AS DATE) as thang,
SUM(doanhsocovat) AS ds_thang,
COUNT(DISTINCT sodondathang) as sl_dh_thang
    FROM data_sale
    GROUP BY masanpham,thang
    HAVING ds_thang > 1000
)

,d_avg_ds_6t_theo_sp as
(
    SELECT
    m.thang,
    m.masanpham,
    IFNULL(s.ds_thang,0) as ds_thang,
    AVG(IFNULL(s.ds_thang,0)) OVER (PARTITION BY m.masanpham ORDER BY m.thang ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING)  as avg_ds_6t_sp,
    FROM monthly_sp m
    LEFT JOIN monthly_sales_sp s ON m.thang = s.thang and m.masanpham = s.masanpham
    GROUP BY m.masanpham,m.thang,s.ds_thang
)

,ds_sp_bien_dong AS (
SELECT
distinct masanpham,
--thang,
CASE
    WHEN thang = (SELECT thang_bao_cao FROM base_time)
    THEN ROW_NUMBER() OVER (PARTITION BY thang ORDER BY SAFE_DIVIDE(ds_thang,avg_ds_6t_sp) DESC) --  SUM(ds_thang - avg_ds_6t_sp)
    ELSE NULL END AS top_sp_bien_dong
FROM d_avg_ds_6t_theo_sp 
WHERE ds_thang >= avg_ds_6t_sp *2
AND thang = (SELECT thang_bao_cao FROM base_time)
GROUP BY masanpham,thang,ds_thang,avg_ds_6t_sp

)

------ dskh biến động all sp

,dskh_yt1_all_sp as(
    with dskh_bien_dong as (
        SELECT
        a.makhdms,
        a.thang,
        a.ds_thang_all_sp,
        a.avg_ds_6t_all_sp
    FROM d_avg_ds_6t a
    --JOIN monthly_sales_all_sp m ON a.makhdms = m.makhdms and m.thang = a.thang
    WHERE ds_thang_all_sp - avg_ds_6t_all_sp > avg_ds_6t_all_sp * 2
    AND ds_thang_all_sp - avg_ds_6t_all_sp > 5000000
)
SELECT distinct makhdms,thang from dskh_bien_dong
)

,dskh_yt2_all_sp as (
SELECT
makhdms,
ds_thang_ht_all,
thang,
IFNULL(ds_thang_t1_all,0) as ds_thang_t1,
IFNULL(ds_thang_t2_all,0) as ds_thang_t2,
FROM ds_3_thang
WHERE IFNULL(ds_thang_t1_all,0) + IFNULL(ds_thang_t2_all,0) = 0
AND ds_thang_ht_all >= 5000000
)

,dskh_yt3_all_sp as (
SELECT
makhdms,
thang,
COUNT(DISTINCT sodondathang) as sl_dh_hien_tai
FROM data_sale
GROUP BY ALL
HAVING sl_dh_hien_tai > 6
ORDER BY thang
)

,union_all_dskh_bien_dong as (
SELECT
makhdms,
thang,
'DS biến động > 200%' as type,
'all sp' as type_dskh
FROM dskh_yt1_all_sp

UNION ALL
SELECT
makhdms,
thang,
'2 tháng liền kề không phát sinh DS' as type,
'all sp' as type_dskh
FROM dskh_yt2_all_sp

UNION ALL
SELECT
makhdms,
thang,
'SLĐH >= 6' as type,
'all sp' as type_dskh
FROM dskh_yt3_all_sp

UNION ALL
SELECT
makhdms,
thang,
'DS biến động > 200%' as type,
'sp hot' as type_dskh
FROM dskh_yt1

UNION ALL
SELECT
makhdms,
thang,
'2 tháng liền kề không phát sinh DS' as type,
'sp hot' as type_dskh
FROM dskh_yt2

UNION ALL
SELECT
makhdms,
thang,
'SLĐH >= 6' as type,
'sp hot' as type_dskh
FROM dskh_yt3
)

,dskh_bat_thuong as(
SELECT 
DISTINCT makhdms,
STRING_AGG (DISTINCT type, ' ,') as type,
MAX(CASE WHEN type_dskh = 'all sp' THEN 'Y' ELSE 'N' END) AS is_all_sp,
MAX(CASE WHEN type_dskh = 'sp hot' THEN 'Y' ELSE 'N' END) AS is_sp_hot,
FROM union_all_dskh_bien_dong
where thang = (SELECT thang_bao_cao FROM base_time) 
GROUP BY ALL
)
,d_avg_ds_6t_sp_theo_tinh as (
    SELECT
    b.thang,
    k.masanpham,
    a.statedescr,
    AVG(IFNULL(s.ds_thang,0)) OVER (PARTITION BY k.masanpham, a.statedescr ORDER BY b.thang ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING)  as avg_ds_6t,
    FROM base_date b
    CROSS JOIN (SELECT DISTINCT masanpham FROM data_sale) k
    CROSS JOIN (SELECT DISTINCT statedescr FROM data_sale) a
    LEFT JOIN
        (SELECT masanpham, statedescr, thang, SUM(doanhsocovat) as ds_thang 
         FROM data_sale GROUP BY 1,2,3 HAVING ds_thang > 1000
        ) s ON b.thang = s.thang and k.masanpham = s.masanpham and a.statedescr = s.statedescr
    GROUP BY b.thang, k.masanpham, a.statedescr, s.ds_thang
)

,d_avg_ds_6t_sp_crs as (
    SELECT
    b.thang,
    k.masanpham,
    u.manv,
    AVG(IFNULL(s.ds_thang,0)) OVER (PARTITION BY k.masanpham, u.manv  ORDER BY b.thang ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING)  as avg_ds_6t,
    SUM(IFNULL(s.ds_thang,0)) OVER (PARTITION BY k.masanpham, u.manv  ORDER BY b.thang ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING)  as ds_6t,
    FROM base_date b
    CROSS JOIN (SELECT DISTINCT masanpham FROM data_sale) k
    CROSS JOIN (SELECT DISTINCT manv FROM data_sale) u
    LEFT JOIN
       (SELECT masanpham, manv, thang, SUM(doanhsocovat) as ds_thang 
        FROM data_sale GROUP BY 1,2,3 HAVING ds_thang > 1000
        ) s ON k.masanpham = s.masanpham AND u.manv = s.manv AND b.thang = s.thang
    GROUP BY b.thang, k.masanpham, u.manv, s.ds_thang
)
,phan_cap_all_sp as (
SELECT
a.makhdms,
m.thang,
m.ds_thang_all_sp,
a.avg_ds_6t_all_sp,
m.sl_dh_thang,
SAFE_DIVIDE(m.ds_thang_all_sp,a.avg_ds_6t_all_sp) as ty_le_bien_dong_ds_all_sp,
CASE
    WHEN m.ds_thang_all_sp - a.avg_ds_6t_all_sp > a.avg_ds_6t_all_sp * 3 AND m.sl_dh_thang > 6 
    AND m.thang = (SELECT thang_bao_cao FROM base_time)
    THEN 'Cấp 1'

    WHEN m.ds_thang_all_sp - a.avg_ds_6t_all_sp > a.avg_ds_6t_all_sp * 2  
    AND m.thang = (SELECT thang_bao_cao FROM base_time)
    THEN 'Cấp 2'
    ELSE NULL END phan_cap_kh_all_sp,

CASE
    WHEN m.ds_thang_all_sp > a.avg_ds_6t_all_sp
    AND m.thang = (SELECT thang_bao_cao FROM base_time)
    THEN 'Cấp 1'
    WHEN m.ds_thang_all_sp > a.avg_ds_6t_all_sp * 0.5  
    AND m.thang = (SELECT thang_bao_cao FROM base_time)
    THEN 'Cấp 2'
    ELSE NULL END phan_cap_sp,
CASE
    WHEN m.thang = (SELECT thang_bao_cao FROM base_time)
    THEN ROW_NUMBER() OVER (PARTITION BY m.thang ORDER BY SAFE_DIVIDE(m.ds_thang_all_sp,a.avg_ds_6t_all_sp) DESC) 
    ELSE NULL END AS top_ds_bien_dong_theo_all_sp

FROM d_avg_ds_6t a
JOIN monthly_sales m ON a.makhdms = m.makhdms AND m.thang = a.thang
LEFT JOIN dskh_bat_thuong ds ON ds.makhdms = a.makhdms
WHERE ds.makhdms IS NOT NULL
AND ds.is_all_sp = 'Y'
AND a.thang >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH), MONTH)
GROUP BY ALL
)

,phan_cap_sp_hot as (
SELECT
a.makhdms,
m.thang,
m.ds_thang_sp_hot,
a.avg_ds_6t_sp_hot,
m.sl_dh_thang,
SAFE_DIVIDE(m.ds_thang_sp_hot,a.avg_ds_6t_sp_hot) AS ty_le_bien_dong_ds,
CASE
    WHEN m.ds_thang_sp_hot - a.avg_ds_6t_sp_hot > a.avg_ds_6t_sp_hot * 3 AND m.sl_dh_thang > 6 
    AND m.thang = (SELECT thang_bao_cao FROM base_time)
    THEN 'Cấp 1'

    WHEN m.ds_thang_sp_hot - a.avg_ds_6t_sp_hot > a.avg_ds_6t_sp_hot * 2  
    AND m.thang = (SELECT thang_bao_cao FROM base_time)
    THEN 'Cấp 2'

    ELSE NULL END phan_cap,

CASE
    WHEN m.thang = (SELECT thang_bao_cao FROM base_time)
    THEN ROW_NUMBER() OVER (PARTITION BY m.thang ORDER BY SAFE_DIVIDE(m.ds_thang_sp_hot,a.avg_ds_6t_sp_hot) DESC) 
    ELSE NULL END AS top_ds_bien_dong

FROM d_avg_ds_6t a
JOIN monthly_sales m ON a.makhdms = m.makhdms AND m.thang = a.thang
LEFT JOIN dskh_bat_thuong ds ON ds.makhdms = a.makhdms
WHERE ds.makhdms IS NOT NULL
AND ds.is_sp_hot = 'Y'
AND a.thang >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH), MONTH)
GROUP BY ALL
)
SELECT
ngaychungtu,
s.thang,
u.supid as ma_crm,
u.tenquanlytt,
s.statedescr,
s.makhdms,
tenkhachhang,
makenhkh_cu,
makenhphu_cu,
m.col. ma_nvbh as manv,
u.tencvbh,
sodondathang,
s.masanpham,
tensanphamviettat,
tensanphamnb,
CASE WHEN ds.makhdms IS NOT NULL AND ds.is_sp_hot = 'Y' THEN 'Y' ELSE 'N' END as trang_thai_nhay_cam,
CASE WHEN ds.makhdms IS NOT NULL AND ds.is_all_sp = 'Y' THEN 'Y' ELSE 'N' END as trang_thai_nhay_cam_all_sp,
CASE WHEN ds.makhdms IS NOT NULL AND ds.is_sp_hot = 'Y' THEN ds.type ELSE NULL END as type_sp_hot,
CASE WHEN ds.makhdms IS NOT NULL AND ds.is_all_sp = 'Y' THEN ds.type ELSE NULL END as type_all_sp,
CASE WHEN e.masanpham IS NOT NULL THEN 'Y' ELSE 'N' END AS sp_bien_dong,
c.phan_cap,
g.phan_cap_sp,
g.phan_cap_kh_all_sp,
g.top_ds_bien_dong_theo_all_sp,
c.top_ds_bien_dong,
CASE WHEN s.thang = (SELECT thang_bao_cao FROM base_time) THEN e.top_sp_bien_dong ELSE NULL END AS top_sp_bien_dong,
doanhsocovat,
soluong,
SAFE_DIVIDE(doanhsocovat,c.avg_ds_6t_sp_hot) as ty_le_bien_dong_ds,
SAFE_DIVIDE(doanhsocovat,g.avg_ds_6t_all_sp) as ty_le_bien_dong_ds_all_sp,
SAFE_DIVIDE(doanhsocovat,sp.avg_ds_6t_sp) as ty_le_bien_dong_ds_theo_sp,
SAFE_DIVIDE(doanhsocovat,t.avg_ds_6t) as ty_le_bien_dong_ds_sp_tinh,
SAFE_DIVIDE(doanhsocovat,h.avg_ds_6t) as ty_le_bien_dong_ds_sp_crs,
h.avg_ds_6t as avg_ds_6t_sp_crs,
h.ds_6t as ds_6t_sp_crs,
FROM data_sale s
LEFT JOIN dskh_bat_thuong ds ON ds.makhdms = s.makhdms 
LEFT JOIN phan_cap_sp_hot c ON c.makhdms = s.makhdms and c.thang = s.thang
LEFT JOIN d_avg_ds_6t_theo_sp sp ON sp.masanpham = s.masanpham and sp.thang = s.thang
LEFT JOIN ds_sp_bien_dong e ON e.masanpham = s.masanpham
LEFT JOIN phan_cap_all_sp g ON g.makhdms = s.makhdms and g.thang = s.thang
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` m ON m.custid = s.makhdms
LEFT JOIN `spatial-vision-343005.staging.d_users` u ON u.manv = m.col. ma_nvbh
LEFT JOIN d_avg_ds_6t_sp_theo_tinh t ON t.masanpham = s.masanpham and t.thang = s.thang and t.statedescr = s.statedescr
LEFT JOIN d_avg_ds_6t_sp_crs h ON h.masanpham = s.masanpham and h.thang = s.thang and h.manv = s.manv
WHERE
date(ngaychungtu) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH)






;