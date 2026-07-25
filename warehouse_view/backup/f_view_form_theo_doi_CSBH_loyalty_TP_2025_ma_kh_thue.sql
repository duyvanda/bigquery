CREATE VIEW `spatial-vision-343005.warehouse.f_view_form_theo_doi_CSBH_loyalty_TP_2025_ma_kh_thue`
AS WITH sales_fixed as
(
    SELECT
    * EXCEPT (ngayhoadon),
    case 
    when sodondathang in (
    "DL6-0325-02016",
    "DL6-0325-02016",
    "DL6-0325-02052",
    "DL6-0325-02077",
    "DL6-0325-02092",
    "DL6-0325-02128",
    "DL6-0325-02130",
    "DL6-0325-02142",
    "DL6-0325-02138",
    "DL6-0325-02145",
    "DL6-0325-02129",
    "DL6-0325-02144",
    "DL6-0325-02139",
    "DL6-0325-02131",
    "DL6-0325-02066"
    )
    then timestamp('2025-03-01 00:00:00 UTC') else
    ngayhoadon end as ngayhoadon,
    FROM `spatial-vision-343005.warehouse.view_f_raw_data_sales_mst`
),
base_date as (
SELECT 
* EXCEPT (quy),
EXTRACT (QUARTER FROM ngayhoadon) as quy,
FROM sales_fixed
),
ds_theo_ma_kh_thue as (
SELECT 
a.quy,
a.nam,
a.makhdms as ma_kh,
a.ten_kh,
a.ma_kh_thue,
a.ten_kh_thue,
a.ma_sothue,
a.macongtycn,
a.chinhanh,
e.stocksales AS tinh_trang_ma_so_thue,
e.legaldate,
IF(date(e.legaldate) >= CURRENT_DATE(),'Còn hiệu lực','Hết hiệu lực') as hieu_luc_GDP_CPP ,
a.kenh,
a.mahco,
a.maphanloai_hco,
a.tinh,
hl.hieu_luc_hd,
hl.muc_hd_2025,
hl.hang_thanh_vien_theo_doanh_so_nam_2024,
d.manv AS ma_crs,
d.tencvbh AS ten_crs,
d.supid AS ma_crm,
d.tenquanlytt AS ten_crm,
d.rsmid AS ma_ncxm,
d.tenquanlyvung AS ten_ncxm,
f.thu_hoi_ttmb as tinh_trang_thu_hd,
g.tinh_trang_thu_hoi_chung_tu_pkttcn,
-- Xử lý doanh số so với ngày hợp đồng
SUM(
        CASE 
            WHEN b.nhomcpa = 'XO' 
                AND DATE(a.ngayhoadon) >= DATE(hl.hieu_luc_hd) 
                AND DATE(a.ngayhoadon) < '2025-12-27' 
            THEN doanhsocovat 
            ELSE 0 
        END
    ) AS ds_xo,
    SUM(
        CASE 
            WHEN b.nhomcpa = 'CL' 
                AND DATE(a.ngayhoadon) >= DATE(hl.hieu_luc_hd)
                AND DATE(a.ngayhoadon) < '2025-12-27' 
            THEN doanhsocovat 
            ELSE 0 
        END
    ) AS ds_cl,
    SUM(
        CASE 
            WHEN b.nhomcpa = 'KS+' 
                AND DATE(a.ngayhoadon) >= DATE(hl.hieu_luc_hd) 
                AND DATE(a.ngayhoadon) < '2025-12-27' 
            THEN doanhsocovat 
            ELSE 0 
        END
    ) AS ds_ks,
    SUM(
        CASE 
            WHEN DATE(a.ngayhoadon) >= DATE(hl.hieu_luc_hd) 
                AND DATE(a.ngayhoadon) < '2025-12-27' 
            THEN doanhsocovat 
            ELSE 0 
        END
    ) AS ds,
  
  ROW_NUMBER() OVER (PARTITION BY makhdms, quy) AS stt

FROM base_date a
INNER JOIN `spatial-vision-343005.staging.form_theo_doi_CSBH_loyalty_TP_2025` hl on hl.ma_kh = a.makhdms
LEFT JOIN `staging.d_nhom_sp_trading` b ON a.masanpham = b.masanpham
LEFT JOIN `warehouse.f_mapping_crs` c on a.makhdms = c.custid
LEFT JOIN `staging.d_users` d on c.col.ma_nvbh = d.manv
LEFT JOIN `staging.d_master_khachhang` e on a.makhdms = e.custid
LEFT JOIN `spatial-vision-343005.staging.d_manual_gs_csbh_loyalty_2025_tp_pcl` f ON f.ma_kh = a.makhdms AND a.ma_kh_thue = f.ma_kh_thue
LEFT JOIN `spatial-vision-343005.staging.d_manual_phu_luc_thay_doi_ct_loyalty` g ON g.ma_kh_dms = a.makhdms AND g.ma_kh_thue = a.ma_kh_thue
Where nam = 2025 --and ma_kh= '000257' and quy = 1
GROUP BY ALL
)
SELECT
a.quy,
a.nam,
a.ma_kh_thue,
a.ten_kh_thue,
a.ma_sothue,
a.ma_crs,
a.ten_crs,
a.ma_crm,
a.ten_crm,
a.ma_ncxm,
a.ten_ncxm,
a.ds_xo,
a.ds_cl,
a.ds_ks,
b.ds,
a.ma_kh,
a.hieu_luc_hd,
a.muc_hd_2025,
a.ten_kh,
a.kenh,
a.mahco,
a.maphanloai_hco,
a.tinh_trang_ma_so_thue,
a.macongtycn,
a.chinhanh,
a.tinh,
a.legaldate,
a.hieu_luc_GDP_CPP,
a.hang_thanh_vien_theo_doanh_so_nam_2024,
a.tinh_trang_thu_hd,
a.tinh_trang_thu_hoi_chung_tu_pkttcn,
b.phan_tram_ck_xo_nam_dk,
b.phan_tram_ck_cl_nam_dk,
b.phan_tram_ck_ks_nam_dk,
b.dk_doanh_so_quy,
b.xo,
b.cl,
b.ks,
b.ds_xo_luy_ke,
b.ds_cl_luy_ke,
b.ds_ks_luy_ke,
b.ds_luy_ke,
b.th_kpi_ds,
b.th_kpi_ds_luy_ke,
b.ds_thieu_luy_ke,
b.tong_ds_nam,
b.tong_ds_xo_nam,
b.tong_ds_cl_nam,
b.tong_ds_ks_nam,
b.ck_xo_nam,
b.ck_cl_nam,
b.ck_ks_nam,
b.ds_bao_luu_chua_ck,
b.tong_tien_ck_xo_nam,
b.tong_tien_ck_cl_nam,
b.tong_tien_ck_ks_nam,
b.tien_ck_xo,
b.tien_ck_ks,
b.tien_ck_cl,
b.tien_ck_xo_dukien,
b.tien_ck_ks_dukien,
b.tien_ck_cl_dukien,
b.tong_tien_ck,
b.tong_tien_ck_dukien,
b.tong_tien_ck_nam,
b.tong_tien_ck_nam_du_kien,
b.ck_nam_xo_dukien,
b.ck_nam_cl_dukien,
b.ck_nam_ks_dukien,
FROM ds_theo_ma_kh_thue a
LEFT JOIN `spatial-vision-343005.warehouse.f_view_form_theo_doi_CSBH_loyalty_TP_2025` b ON 
  b.ma_kh = a.ma_kh 
  and a.quy = b.quy 
  and a.stt = 1
--Where a.ma_kh = '000257' and a.quy = 1










;