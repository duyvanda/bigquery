CREATE VIEW `spatial-vision-343005.warehouse.view_f_raw_data_sales_yoy_mp`
AS SELECT
a.year,
a.cycle,
a.thang_number,
a.phap_nhan,
a.macongtycn,
a.congtycn,
a.makhcu,
a.makhdms,
a.tenkhachhang,
a.tentinhkh,
a.statedescr,
a.territorydescr,
a.districtdescr,
a.wardname,
a.khuvucviettat,
a.cluster_state,
a.hcoid,
a.hcotypeid,
a.classid,
a.pubcustid,
-- a.custidinvoice_dongnhat,
-- a.custnameinvoice_dongnhat,
-- a.taxregnbr_dongnhat,
-- a.custname_dongnhat,
a.pubcustname,
a.sodondathang,
a.sodontrahang,
a.ngaychungtu,
a.month,
a.thang,
a.lineref,
a.masanpham,
a.tensanphamnb,
a.tensanphamviettat,
a.soluongori as soluong,
a.dongiachuavat,
a.dongiachuavat_ori,
a.dongiacovat,
a.doanhsocovat,
a.doanhsochuavat,
a.doanhsochuavat_ori,
a.doanhsocovat_ori,
a.kieudonhang,
null as makenhkh_cu,
null as makenhphu_cu,
null as mahco_cu,
null as maphanloaihco_cu,
a.is_hang_km as is_hangkm,
a.makenhkh_cu as channel_pda,
a.makenhphu_cu as shoptype_pda,
a.makenhkh,
a.makenhphu,
-- a.mahco_cu,
a.maphanhanghco_cu as hcoid_pda,
a.maphanloaihco_cu as hcotypeid_pda,
a.mahd,
a.solo,
a.expdate,
a.hoadon,
a.is_ecom,
-- a.datatype,
a.spcl2023tp_mt,
a.spcl2023pcl_clc_ins,
a.spcl2023_all,
a.brand2023,
a.brand,
a.brandnew2023,
a.branddongnhat,
a.ori_manv,
a.manvgh,
a.ten_nvgh,
a.invoicecustid,
a.custinvcname,
a.taxregnbr,
a.invcnote,
a.thoi_han_thanh_toan as terms,
a.hinh_thuc_thanh_toan as hinhthucthanhtoan,
a.updated_at,
a.is_phanam,
a.phan_hang_c2_2023,
a.phan_hang_c1_2024,
a.ten_sp_day_du,
a.ten_mien,
a.cn_dia_ly as branchname_filter,
a.manv,
a.phanloai_tuyen_chitiet,
a.phanloai_tuyen,
a.ma_crm,
a.scrm,
a.ma_ncxm,
a.tencvbh,
a.tenquanlytt,
a.tenquanlykhuvuc,
a.tenquanlyvung,
a.phong_kh,
a.ma_cre,
a.ho_ten_cre,
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


;