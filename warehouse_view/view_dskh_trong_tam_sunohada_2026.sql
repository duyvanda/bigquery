CREATE VIEW `spatial-vision-343005.warehouse.view_dskh_trong_tam_sunohada_2026`
AS with sales as
( 
SELECT
b.ma_khach_hang_dms as makhdms,
c.pubcustname as ten_hco,
b.target_2026 as doanh_so_ke_hoach,
c.channel as makenhkh,
b.kenh_phu as makenhphu_cu,
b.ma_hco_chung as pubcustid,
t.supid,
t.tenquanlytt,
t.asm,
t.tenquanlykhuvuc,
c.statedescr,
b.phan_loai,
b.chuyen_khoa_pcl,

MAX(
    CASE 
      WHEN a.masanpham IN ('T4040101001','T4040101002') THEN DATE(a.ngaychungtu) 
      ELSE NULL 
    END
  ) as ngaychungtu_gan_nhat,

SUM(
  Case WHEN a.year = 2025 and a.masanpham in ('T4040101001','T4040101002') THEN a.doanhsochuavat ELSE 0 END
) as ds_2025,

SUM(
  Case WHEN a.year = 2026 and a.masanpham in ('T4040101001','T4040101002') THEN a.doanhsochuavat ELSE 0 END
) as ds_2026

FROM `staging.d_manual_dskh_trong_tam_sunohada_pcl_clc_2026` b 
LEFT JOIN`spatial-vision-343005.warehouse.f_raw_data_sales_yoy` a on a.makhdms = b.ma_khach_hang_dms
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` t on t.custid = b.ma_khach_hang_dms
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` c on c.custid = b.ma_khach_hang_dms
GROUP BY ALL
)
, temp_hcp_specialty_summary AS (
    SELECT 
        hco_bv,
        -- 1. Đếm tổng tất cả HCP của bệnh viện đó
        COUNT(*) AS tong_sl_hcp,
        -- 2. Đếm riêng số lượng HCP Da Liễu
        COUNTIF(nganh_chuyen_khoa = 'DA LIỄU') AS sl_hcp_da_lieu,
        -- 3. Đếm riêng số lượng HCP Nhi
        COUNTIF(nganh_chuyen_khoa = 'NHI') AS sl_hcp_nhi
    FROM 
        `spatial-vision-343005.staging.d_master_hcp`
    WHere hco_bv is not null
    GROUP BY 
        hco_bv
)

SELECT 
    s.*,
    COALESCE(h.tong_sl_hcp, 0) AS tong_sl_hcp,
    COALESCE(h.sl_hcp_da_lieu, 0) AS sl_hcp_da_lieu,
    COALESCE(h.sl_hcp_nhi, 0) AS sl_hcp_nhi
FROM sales s
LEFT JOIN temp_hcp_specialty_summary h ON s.pubcustid = h.hco_bv


;