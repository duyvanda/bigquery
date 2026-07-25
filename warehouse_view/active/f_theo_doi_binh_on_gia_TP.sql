CREATE VIEW `spatial-vision-343005.warehouse.f_theo_doi_binh_on_gia_TP`
AS SELECT 
  a.*,
  b.supid,
  b.tenquanlytt as ten_qltt,
  firstname as ten_nv,
  c.descr1,
  a.descr as Tinh,
  CONCAT(a.invtid,' - ',c.descr1) as masp_tensp,
  CONCAT(custid,' - ',custname) as makh_tenkh,
  ROW_NUMBER () OVER (PARTITION BY slsperid, custid, a.invtid ORDER BY visitdate DESC) row_num
FROM `spatial-vision-343005.staging.f_theo_doi_binh_on_gia_tp` a
LEFT JOIN `spatial-vision-343005.staging.d_users` b ON a.slsperid = b.manv
LEFT JOIN `spatial-vision-343005.staging.d_dms_master_invtid` c ON a.invtid = c.invtid
where visitdate >= '2024-01-01' and visitdate <= '2024-03-31' 
QUALIFY row_num = 1 ;