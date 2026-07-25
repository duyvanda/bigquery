CREATE VIEW `spatial-vision-343005.warehouse.view_KPI`
AS WITH q AS (
  SELECT DISTINCT classid, custid
  FROM `spatial-vision-343005.staging.d_master_khachhang`
  WHERE classid IN ('KA', 'RB', 'RC')
),

--before 2024
kh_cu  as 
(select distinct makhdms
from  `staging.f_sales`
where ngaychungtu < '2024-01-01'
)

SELECT a.manv, 
       thang,
       c.supid,
       sum(doanhsocovat) as doanhso,
       COUNT(a.makhdms) AS slkh,
       count(distinct case when b.makhdms is null then a.makhdms else null end) as slkh_moi,
       COUNT(distinct case when kieudonhang = 'IN' THEN sodondathang ELSE NULL END) as sldh,
       COUNT(DISTINCT CASE WHEN q.classid = 'KA' THEN a.makhdms ELSE NULL END) AS slkh_ka,
       COUNT(DISTINCT CASE WHEN q.classid = 'RB' THEN a.makhdms ELSE NULL END) AS slkh_rb,
       COUNT(DISTINCT CASE WHEN q.classid = 'RC' THEN a.makhdms ELSE NULL END) AS slkh_rc,
       COUNT(DISTINCT CASE WHEN q.classid = 'KA' THEN a.makhdms ELSE NULL END) / COUNT(a.makhdms) as tyle_kh_ka,
       COUNT(DISTINCT CASE WHEN q.classid = 'RB' THEN a.makhdms ELSE NULL END) / COUNT(a.makhdms) as tyle_kh_rb,
       COUNT(DISTINCT CASE WHEN q.classid = 'RC' THEN a.makhdms ELSE NULL END) / COUNT(a.makhdms) as tyle_kh_rc,
       sum(case when q.classid = 'KA' THEN doanhsocovat ELSE NULL END) as ds_ka,
       sum(case when q.classid = 'RB' THEN doanhsocovat ELSE NULL END) as ds_rb,
       sum(case when q.classid = 'RC' THEN doanhsocovat ELSE NULL END) as ds_rc,
       sum(case when makenhkh = 'TP' THEN doanhsocovat ELSE NULL END) as ds_tp,
       sum(case when makenhkh in ('INS','CLC','PCL') THEN doanhsocovat else null end ) as ds_hcp,
       sum(case when b.makhdms is null then doanhsocovat else null end) as ds_kh_moi,
       COUNT(DISTINCT CASE WHEN kieudonhang = 'IN' and q.classid = 'KA' THEN sodondathang ELSE NULL END) AS sldh_ka,
       COUNT(DISTINCT CASE WHEN kieudonhang = 'IN' and q.classid = 'RB' THEN sodondathang ELSE NULL END) AS sldh_rb,
       COUNT(DISTINCT CASE WHEN kieudonhang = 'IN' and q.classid = 'RC' THEN sodondathang ELSE NULL END) AS sldh_rc,
      COUNT(DISTINCT CASE WHEN kieudonhang = 'IN' and b.makhdms is null THEN sodondathang ELSE NULL END) AS sldh_kh_moi,


FROM `spatial-vision-343005.staging.f_sales` a
LEFT JOIN q ON a.makhdms = q.custid
left join kh_cu b on a.makhdms = b.makhdms
left join `spatial-vision-343005.staging.d_users` c on a.manv = c.manv
WHERE ngaychungtu >= '2024-01-01' --kh_mới
and kieudonhang = 'IN' 
GROUP BY 1,2,3;