CREATE VIEW `spatial-vision-343005.warehouse.view_KPI_byngaychungtu`
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

SELECT ngaychungtu,
 a.manv, 
       thang,
       c.supid,
       doanhsocovat,
       a.makhdms,
       kieudonhang,
       q.classid,
       sodondathang,
       makenhkh,
       case when b.makhdms is null then 'kh_moi' else 'kh_cu' end as check_kh 
      

FROM `spatial-vision-343005.staging.f_sales` a
LEFT JOIN q ON a.makhdms = q.custid
left join kh_cu b on a.makhdms = b.makhdms
left join `spatial-vision-343005.staging.d_users` c on a.manv = c.manv
WHERE ngaychungtu >= '2024-01-01' --kh_mới
and kieudonhang   = 'IN' 
;