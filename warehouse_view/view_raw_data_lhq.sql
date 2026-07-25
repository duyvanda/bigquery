CREATE VIEW `spatial-vision-343005.warehouse.view_raw_data_lhq`
AS SELECT 
a.thang,
a.ngaychungtu,
a.scrm,
a.ncxm,
a.crm,
a.manv,
a.tencvbh,
a.statedescr,
a.districtdescr,
a.makhdms,
a.tenkhachhang,
a.mahco,
a.maphanloaihco,
a.makenhkh,
a.makenhphu,
a.sodondathang,
a.hoadon,
a.masanpham,
a.tensanphamviettat,
SUM(a.soluong) as so_luong,
SUM(a.doanhsocovat) as doanhsocovat,
SUM(a.doanhsochuavat) as doanhsochuavat,
d.custidinvoice,
d.custnameinvoice,
d.taxregnbr,
q.hovatenfullname
FROM `spatial-vision-343005.staging_temp.f_sales_crs_lhq_bytime` a
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` d ON d.custid = a.makhdms
LEFT JOIN spatial-vision-343005.staging.d_hr_dsns   q on a.crm = q.msnvcsmmoi
WHERE date(ngaychungtu) >= '2025-01-01'
AND datatype1 NOT IN ('d_calendar')
AND makenhkh in ('MT','TP', 'INS', 'CLC', 'PCL')
AND crs_tuyenbanhang_trongmcp NOT IN ('Rural')
AND manv != 'CX'
GROUP BY ALL;