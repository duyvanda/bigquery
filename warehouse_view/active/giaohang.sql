CREATE VIEW `spatial-vision-343005.warehouse.giaohang`
AS SELECT
  ngaychungtu,
  sodondathang,
  sodontrahang, 
  ngaytrahang,
  makhdms,
  tenkhachhang,
  tentinhkh,
  makenhkh,
  makenhphu,
  masanpham,
  soluong,
  a.manv,
  a.tencvbh,
  manvgh,
  manvghreal,
  donvigiaohang,
  kieudonhang,
  trahangkhacthang,
  tennvghreal,
  b.supid,
  b.tenquanlytt,
  b.rsmid,
  b.tenquanlyvung,
  b.role_luong_mds,
  b.role_luong_mds_phanloai,
  c.cluster_state,
  a.tenkhuvuc,
  a.tenquanhuyen,
  a.macongtycn,
  d.delivery_date,
  d.ordernbr,
  d.branchid,
  CASE 
    WHEN makenhkh IN ('TP', 'PCL') THEN 'TP/PCL'
    WHEN makenhkh IN ('INS','CLC','MT') THEN 'INS/CLC/MT' 
    END AS dsgiaohang_phanloai,
  SUM(doanhsochuavat) AS doanhsochuavat
FROM `spatial-vision-343005.staging.f_sales` a 
LEFT JOIN `spatial-vision-343005.staging.d_users` b ON 
  (IFNULL (manvghreal, manvgh)) = b.manv
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` c ON a.makhdms = c.custid
LEFT JOIN `spatial-vision-343005.staging.sync_dms_dv` d ON a.macongtycn = d.branchid AND a.sodondathang = d.ordernbr
AND d.delivery_date IS NOT NULL AND d.status = 'C'
WHERE ngaychungtu >= "2024-02-01" AND donvigiaohang IN ('Pha Nam', 'Chành xe') AND trahangkhacthang IS NOT true 
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32

  
  

;