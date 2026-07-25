CREATE VIEW `spatial-vision-343005.warehouse.view_quyet_toan_benita _xylo`
AS WITH data_sale AS (
SELECT
makhdms,
SUM(soluong) as soluong
FROM `spatial-vision-343005.staging.f_sales`
WHERE ngaychungtu >= '2025-01-01' and masanpham = 'V1HML'
GROUP BY ALL
)
SELECT 
a.* EXCEPT (custid),
k.branchid as macongtycn,
a.custid as makh,
k.custname as tennhathuoctenhco,
k.channel,
c.col. ma_nvbh as macrs,
d.tencvbh as crs,
d.supid as ma_crm,
d.tenquanlytt,
'Cấn trừ voucher mua hàng, mệnh giá 100.000 VND' as ten_voucher,
IFNULL(SUM(b.soluong),0) as sl_voucher_can_tru
FROM `spatial-vision-343005.staging.d_display_reward` a
LEFT JOIN data_sale b On b.makhdms = a.custid
LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs` c on c.custid = a.custid
LEFT JOIN `spatial-vision-343005.staging.d_users` d ON d.manv = c.col. ma_nvbh
LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` k ON k.custid = a.custid
where displayid = '2504-CTTB-CPA28-NT-QT'
GROUP BY ALL
;