CREATE VIEW `spatial-vision-343005.warehouse.view_f_raw_data_sales_mst`
AS SELECT

a.year as nam,
EXTRACT(QUARTER from IFNULL (b.ngaychungtu,a.ngaychungtu)) as quy,
a.cycle,
EXTRACT(MONTH from IFNULL (b.ngaychungtu,a.ngaychungtu)) as thang,
a.macongtycn,
a.phap_nhan,
a.macongtycn as chinhanh,
a.makhcu,
a.makhdms,
a.tenkhachhang as ten_kh,
a.tentinhkh as tinh,
-- a.statedescr,
-- a.territorydescr,
-- a.districtdescr,
-- a.wardname,
-- a.khuvucviettat,
-- a.cluster_state,
-- a.hcoid,
-- a.hcotypeid,
-- a.classid,
-- a.pubcustid,
-- a.custidinvoice_dongnhat,
-- a.custnameinvoice_dongnhat,
-- a.taxregnbr_dongnhat,
-- a.custname_dongnhat,
-- a.pubcustname,
a.sodondathang,
a.sodontrahang,
IFNULL (b.ngaychungtu,a.ngaychungtu) as ngayhoadon,
a.ngaydatdon,
EXTRACT(MONTH from IFNULL (b.ngaychungtu,a.ngaychungtu)) as month,
-- a.thang,
a.lineref,
a.masanpham,
a.tensanphamnb,
a.tensanphamviettat,
a.soluong,
a.dongiachuavat,
a.dongiachuavat_ori,
a.dongiacovat,
a.doanhsocovat,
a.doanhsochuavat,
a.doanhsochuavat_ori,
a.doanhsocovat_ori,
a.kieudonhang,
a.is_hang_km,
a.makenhkh_cu as kenh,
a.makenhphu_cu as makenhphu,
-- a.makenhkh,
-- a.makenhphu,
a.mahco_cu as mahco,
-- a.maphanhanghco_cu,
a.maphanloaihco_cu as maphanloai_hco,
a.mahd,
-- a.solo,
-- a.expdate,
a.hoadon as sohoadon,
a.is_ecom,
a.datatype,
-- a.spcl2023tp_mt,
-- a.spcl2023pcl_clc_ins,
-- a.spcl2023_all,
-- a.brand2023,
-- a.brand,
-- a.brandnew2023,
-- a.branddongnhat,
-- a.ori_manv,
-- a.manvgh,
-- a.ten_nvgh,
a.invoicecustid as ma_kh_thue,
a.custinvcname as ten_kh_thue,
a.taxregnbr as ma_sothue,
a.invcnote,
a.thoi_han_thanh_toan,
a.hinh_thuc_thanh_toan,
a.updated_at,
a.is_phanam,
a.phan_hang_c2_2023,
a.phan_hang_c1_2024,
a.ten_sp_day_du,
-- a.ten_mien,
-- a.cn_dia_ly,
a.manv,
-- a.phanloai_tuyen_chitiet,
-- a.phanloai_tuyen,
a.ma_crm as crm,
a.scrm,
a.ma_ncxm,
a.tencvbh,
a.tenquanlytt,
a.tenquanlykhuvuc,
a.tenquanlyvung,
a.phong_kh,
b1.citizenid
-- a.phong_kh_cu,
-- a.ds_sp_thang,
-- a.inserted_at,
-- a.manv_dongnhat,
-- a.tencvbh_dongnhat,
-- a.ma_crm_dongnhat,
-- a.tenquanlytt_dongnhat,
-- a.ma_scrm_dongnhat,
-- a.tenquanlykhuvuc_dongnhat,
-- a.ma_ncxm_dongnhat,
-- a.tenquanlyvung_dongnhat

FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a
LEFT JOIN `spatial-vision-343005.staging.f_sales_adjusted` b ON b.sodondathang = a.sodondathang AND b.note = 'đơn hàng chưa có hàng về kho, giữ lại ngày hóa đơn'
LEFT JOIN `staging.d_master_khachhang` b1 ON b1.custid = a.makhdms
LEFT JOIN `spatial-vision-343005.warehouse.dim_excluded_makhdms` excl ON a.makhdms = excl.makhdms
where a.makenhkh_cu not in ('OTH_LAB')
AND excl.makhdms IS NULL
;