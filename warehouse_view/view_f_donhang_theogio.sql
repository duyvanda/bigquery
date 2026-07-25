CREATE VIEW `spatial-vision-343005.warehouse.view_f_donhang_theogio`
AS SELECT
-- Chi lay cac field can thiet
distinct
a.ngaychungtu,
a.macongtycn,
a.sodondathang,
a.makhdms,
a.tenkhachhang,
a.tentinhkh,
a.tenquanhuyen,
a.makenhkh,
a.tenkenhphu,
a.doanhsocovat,
a.manv,
a.tencvbh,
a.tenquanlytt,
a.tenquanlyvung,
-- END

b.crtd_datetime,
c.supid as masup_bh,
extract(hour from b.crtd_datetime) thoigian,
d.cluster_state 
from `staging.f_sales` a 
left join staging.sync_dms_pda_so b ON a.macongtycn = b.branchid
AND a.sodondathang = b.ordernbr
left join `spatial-vision-343005.staging.d_users` c on a.manv = c.manv
left join `staging.d_master_khachhang` d on a.makhdms = d.custid
WHERE
kieudonhang = 'IN'
and date(ngaychungtu) >= "2023-01-01";