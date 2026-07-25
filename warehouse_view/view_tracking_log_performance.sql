CREATE VIEW `spatial-vision-343005.warehouse.view_tracking_log_performance`
AS WITH NGAYXACNHAN as
(
SELECT branchid, ordernbr, max(lupd_datetime) as time_xac_nhan FROM `spatial-vision-343005.staging.sync_dms_delihistory`
where status = 'A' and date(crtd_datetime) >= '2023-01-01'
group by all
)

  , form_xac_nhan_c1 as

  (
    SELECT 
    distinct ma_ct as machungtu, cn as machinhanh FROM `spatial-vision-343005.staging.f_form_data_log`
    where role = 'chang_1'
  )

    , form_xac_nhan_c2 as

  (
    SELECT 
    distinct ma_ct as machungtu, cn as machinhanh FROM `spatial-vision-343005.staging.f_form_data_log`
    where role = 'chang_2'
  )

    , form_xac_nhan_t1 as

  (
    SELECT 
    distinct ma_ct as machungtu, cn as machinhanh FROM `spatial-vision-343005.staging.f_form_data_log`
    where role = 'chang_1_tha_hang'
  )

    , form_xac_nhan_t2 as

  (
    SELECT 
    distinct ma_ct as machungtu, cn as machinhanh FROM `spatial-vision-343005.staging.f_form_data_log`
    where role = 'chang_2_tha_hang'
  )

select
a.ngaylap,
b.time_xac_nhan as time_xac_nhan_dms, 
a.machinhanh,
a.tenchinhanh,
a.machungtu,
case when manhanviennhanchang1 is not null then a.machungtu else null end as mct_nhan_hang_c1,
case when manhanviennhanchang2 is not null then a.machungtu else null end as mct_nhan_hang_c2,
case when nhanvienthahang1 is not null then a.machungtu else null end as mct_tha_hang_c1,
case when nhanvienthahang2 is not null then a.machungtu else null end as mct_tha_hang_c2,
case when c1.machungtu is null then 'chua_xac_nhan' else 'da_xac_nhan' end as trang_thai_xac_nhan_nhan_hang_chang_1,
case when c2.machungtu is null then 'chua_xac_nhan' else 'da_xac_nhan' end as trang_thai_xac_nhan_nhan_hang_chang_2,
case when t1.machungtu is null then 'chua_xac_nhan' else 'da_xac_nhan' end as trang_thai_xac_nhan_tha_hang_chang_1,
case when t2.machungtu is null then 'chua_xac_nhan' else 'da_xac_nhan' end as trang_thai_xac_nhan_tha_hang_chang_2,

a.manhanvienthahang1,
a.nhanvienthahang1,
a.manhanviennhanchang1,
a.tennhanviennhanchang1,
a.manhanvienthahang2,
a.nhanvienthahang2,
a.manhanviennhanchang2,
a.tennhanviennhanchang2,


--

n1.tenquanlytt as tenquanlytt_nhan_hang_c1,
n2.tenquanlytt as tenquanlytt_nhan_hang_c2,
th3.tenquanlytt as tenquanlytt_nhan_hang_t1,
th4.tenquanlytt as tenquanlytt_nhan_hang_t2,
--

a.nguoidonghang,
a.nhanviengiaohang,
a.donvigiaohang,
a.thongtinxe,
a.sokienhang,
-- a.vecong,
-- a.cauduong,
-- a.phigoihang,
-- a.ngaygiaohangdukien,
a.soxuathang,
a.sodonhang,
a.tongtiendonhang,
a.trangthai,
a.makh,
a.tenkh,
a.makhcu,
-- a.diachikh,
a.tinhtp,
a.quanhuyen,

-- a.phuongxa,
-- a.sdt,
-- a.hethongbanhang,
-- a.kenh,
-- a.kenhphu,
-- a.hco,
-- a.loaihco,
-- a.phanhanghco,
-- a.thanhtientruocthue,
-- a.thanhtiensauthue,

from `staging.f_bao_cao_bb_gui_hang_tinh` a
left join NGAYXACNHAN b on a.sodonhang = b.ordernbr
LEFT JOIN form_xac_nhan_c1 c1 on a.machinhanh = c1.machinhanh and a.machungtu = c1.machungtu
LEFT JOIN form_xac_nhan_c2 c2 on a.machinhanh = c2.machinhanh and a.machungtu = c2.machungtu
LEFT JOIN form_xac_nhan_t1 t1 on a.machinhanh = t1.machinhanh and a.machungtu = t1.machungtu
LEFT JOIN form_xac_nhan_t2 t2 on a.machinhanh = t2.machinhanh and a.machungtu = t2.machungtu
left join spatial-vision-343005.staging.d_users n1 on a.manhanviennhanchang1 = n1.manv
left join spatial-vision-343005.staging.d_users n2 on a.manhanviennhanchang2 = n2.manv
left join spatial-vision-343005.staging.d_users th3 on a.manhanvienthahang1 = th3.manv
left join spatial-vision-343005.staging.d_users th4 on a.manhanvienthahang2 = th4.manv

-- where a.machungtu = '20250200423';