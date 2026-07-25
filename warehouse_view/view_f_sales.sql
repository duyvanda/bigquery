CREATE VIEW `spatial-vision-343005.warehouse.view_f_sales`
AS WITH dis_amt as (
SELECT
branchid,
origordernbr,
invtid,
SUM(discamt + docdiscamt + groupdiscamt1) as total_discount
FROM `spatial-vision-343005.staging.sync_dms_sod1` WHERE TIMESTAMP_TRUNC(crtd_datetime, DAY) >= TIMESTAMP("2024-01-01")
AND (discamt + docdiscamt + groupdiscamt1) > 0
group by all
)

SELECT
-- a.macongtycn,
-- a.congtycn,
-- a.ngaychungtu,
a.sodondathang,
-- a.mahd,
-- a.sodontrahang,
-- a.ngaytrahang,
-- a.hoadon,
-- a.trangthai,
a.makhdms,
a.makhcu,
a.tenkhachhang,
a.thtt,
a.pmt,
a.tenvungbh,
a.tenkhuvuc,
a.tentinhkh,
a.tenquanhuyen,
a.makenhkh,
a.tenkenhkh,
a.makenhphu,
a.tenkenhphu,
-- a.mahco,
-- a.tenhco,
-- a.maphanloaihco,
-- a.tenphanloaihco,
-- a.maphanhanghco,
-- a.tenphanhanghco,
-- a.nhanhang,
a.masanpham,
-- a.tensanphamnb,
-- a.tensanphamviettat,
-- a.solo,
-- a.lineref,
a.soluong,
-- a.dongiacovat,
-- a.doanhsocovat,
-- a.dongiachuavat,
a.doanhsochuavat,
-- a.ngaydatdon,
-- a.ngaygiaohang,
a.manv,
-- a.tencvbh,
-- a.tenquanlytt,
-- a.tenquanlykhuvuc,
-- a.tenquanlyvung,
-- a.manvgh,
-- a.nguoigiaohang,
-- a.trangthaigiaohang,
-- a.donvigiaohang,
-- a.tennhavanchuyen,
-- a.kieudonhang,
-- a.makho,
-- a.tenkho,
a.thang,
-- a.inserted_at,
-- a.pda_crtd_user,
-- a.pda_slsperid,
-- a.manvghreal,
-- a.tennvghreal,
a.phuongxa,
-- a.trahangkhacthang,
-- a.manvdh_bbgh_tinh,
-- a.soxuathang,
-- a.codexesxh,
-- a.manvth_bbgh_tinh,
-- a.manv_tao_bbgh_nvc,
b.total_discount,
col.phan_loai_mcp as phan_loai_mcp,
q.classid
FROM `spatial-vision-343005.staging.f_sales` a
LEFT JOIN dis_amt b on a.sodondathang = b.origordernbr and b.invtid = a.masanpham
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` c on a.makhdms = c.custid
left join `spatial-vision-343005.staging.d_master_khachhang`  q on a.makhdms = q.custid
WHERE TIMESTAMP_TRUNC(a.ngaychungtu, DAY) >= TIMESTAMP("2024-01-01")
group by all
order by thang desc;