CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_trich_lap_du_phong_du_no()
BEGIN 
 

Create or replace table staging_temp.f_trich_lap_du_phong_du_no_temp
partition by date(thang)
cluster by ma_csm,ma_ge_vat,so_don_hang,so_hd
as


/*
Chat: https://gemini.google.com/app/579af3da84fef9bb
Check trùng lắp HĐ CLC:
SELECT 
    a.ma_kh,
    a.ten_kh,
    -- Thông tin hợp đồng 1
    a.so_hop_dong AS so_hop_dong_1,
    a.ngay_hl_theo_hop_dong AS bat_dau_1,
    a.ngay_het_hl_theo_hop_dong AS ket_thuc_1,
    -- Thông tin hợp đồng 2
    b.so_hop_dong AS so_hop_dong_2,
    b.ngay_hl_theo_hop_dong AS bat_dau_2,
    b.ngay_het_hl_theo_hop_dong AS ket_thuc_2,
    -- Tính số ngày trùng nhau
    TIMESTAMP_DIFF(
        LEAST(a.ngay_het_hl_theo_hop_dong, b.ngay_het_hl_theo_hop_dong),
        GREATEST(a.ngay_hl_theo_hop_dong, b.ngay_hl_theo_hop_dong),
        DAY
    ) + 1 AS so_ngay_overlap
FROM `spatial-vision-343005.warehouse.d_manual_clc_thu_hoi_hop_dong` a
JOIN `spatial-vision-343005.warehouse.d_manual_clc_thu_hoi_hop_dong` b
    ON a.ma_kh = b.ma_kh             -- Cùng một mã khách hàng
    AND a.so_hop_dong < b.so_hop_dong -- Đảm bảo không so sánh chính nó và tránh lặp cặp A-B, B-A
WHERE 
    -- Điều kiện bắt overlap: Start1 <= End2 AND Start2 <= End1
    a.ngay_hl_theo_hop_dong <= b.ngay_het_hl_theo_hop_dong
    AND b.ngay_hl_theo_hop_dong <= a.ngay_het_hl_theo_hop_dong
    -- Loại bỏ dữ liệu rác nếu có
    AND a.ngay_hl_theo_hop_dong IS NOT NULL
    AND b.ngay_hl_theo_hop_dong IS NOT NULL
ORDER BY a.ma_kh, so_ngay_overlap DESC;
*/


with
thu_hoi_bbgh as (
SELECT 
DISTINCT
sodonhang,
sohoadon,
kt_da_nhan
FROM `spatial-vision-343005.warehouse.f_thuhoi_bbgh` 
)

-- thu hồi HĐ INS
, contractid as (
        SELECT 
        DISTINCT
        a.branchid,
        a.custid,
        a.origordernbr,
        a.contractid
        FROM `spatial-vision-343005.staging.sync_dms_so` a
        where a.custid ='P5008-0309'
)

, thu_hoi_hop_dong_ins AS (
    SELECT
        a.*,
        so_hop_dong,
        thu_hoi_hd
        FROM contractid a
        LEFT JOIN `spatial-vision-343005.warehouse.f_theodoi_thuhoi_hopdong` b 
                ON CAST(a.contractid AS INT64) = b.so_hop_dong_bi AND a.custid = b.custid --AND a.branchid = b.branchid
        WHERE b.channel = 'INS'
 )

-- TP, MT, CLC
, hop_dong_tp_mt_clc AS (
-- TP Ký số
SELECT
DISTINCT 
'TP' as channel,
ma_khach_hang as custid,
ma_hop_dong as so_hop_dong,
DATE('2026-01-01') as  ngay_hieu_luc_theo_hd,
DATE('2026-12-31') as  ngay_het_hieu_luc_theo_hd,
Case when trang_thai_ky = 'Đã ký' then 'Đã thu' else 'Chưa thu' end as thu_hoi_hd
FROm `spatial-vision-343005.warehouse.view_data_contract_sign_by_users`
where
internal_promo_code ='202601-TL-QD785-PMC-CTD'
--and trang_thai_ky = 'Đã ký'

-- TP Ký tay
UNION ALL
SELECT 
'TP' as channel,
ma_kh,
'loyaty_2026' as so_hop_dong,
DATE('2026-01-01') as  ngay_hieu_luc_theo_hd,
DATE('2026-12-31') as  ngay_het_hieu_luc_theo_hd,
Case When ngay_thu_hoi is not null then 'Đã thu' else 'Chưa thu' end as thu_hoi_hd
FROM `spatial-vision-343005.staging.theo_doi_thu_hoi_chung_tu_ky_ben_ngoai_loyaty_2026`
--WHERE ngay_thu_hoi is not null

UNION ALL
SELECT 
DISTINCT
'TP' as channel,
ma_khnb_csm,
so_hop_dong_so_phu_luc,
DATE(tu_ngay_ddmmyyyy) as  ngay_hieu_luc_theo_hd,
DATE(den_ngay_ddmmyyyy) as  hieu_luc_hd,
CASE WHEN EXTRACT (YEAR FROm ngay_nhan_ddmmyyyy) > 2000 Then 'Đã thu' ELSE 'Chưa thu' END as thu_hoi_hd
FROM `spatial-vision-343005.staging.d_manual_gs_cat_nhap_thong_tin_tp`
WHERE phan_loai_hdpl = 'HĐ'

--MT
UNION ALL
SELECT 
DISTINCT
'MT' as channel,
ma_khnb_csm,
so_hop_dong_so_phu_luc,
DATE(tu_ngay_ddmmyyyy) as  ngay_hieu_luc_theo_hd,
DATE(den_ngay_ddmmyyyy) as  hieu_luc_hd,
CASE WHEN EXTRACT (YEAR FROm ngay_nhan_ddmmyyyy) > 2000 Then 'Đã thu' ELSE 'Chưa thu' END as thu_hoi_hd
FROM `spatial-vision-343005.staging.d_manual_gs_cat_nhap_thong_tin_mt`
WHERE phan_loai_hdpl = 'HĐ'

--clc
UNION ALL
SELECT
channel,
custid,
so_hop_dong,
ngay_hieu_luc_theo_hd,
hieu_luc_hd,
thu_hoi_hd
FROM `spatial-vision-343005.warehouse.f_theodoi_thuhoi_hopdong`
WHERE channel = 'CLC'
)

, matched_invoices AS (
  SELECT 
    -- Key để map
    inv.ma_ge_khnb,
    inv.so_don_hang,
    -- Trường tình trạng thu hồi từ bảng hợp đồng (dựa trên schema image đầu tiên bạn gửi)
    thu_hoi_hd as hien_trang_thu_hoi,
    inv.ngay_hoa_don,
    so_hop_dong,

    -- Logic ưu tiên lấy 1 hợp đồng duy nhất khi bị overlap
    ROW_NUMBER() OVER (
      PARTITION BY inv.ma_ge_khnb, inv.so_don_hang
      ORDER BY 
        hd.ngay_hieu_luc_theo_hd DESC,
        hd.so_hop_dong DESC
    ) as priority_rank

  FROM `staging.f_cong_no_kt` AS inv
  INNER JOIN hop_dong_tp_mt_clc AS hd
    ON inv.ma_ge_khnb = hd.custid 
    AND DATE(inv.ngay_hoa_don) BETWEEN DATE(hd.ngay_hieu_luc_theo_hd) AND DATE(hd.ngay_het_hieu_luc_theo_hd)
    --and UPPER(thu_hoi_hd) = 'ĐÃ THU'
    and inv.so_don_hang is not null
    and hd.channel = inv.kenh
)

--select * from matched_invoices where so_don_hang = 'DL7-0126-00007'

, thu_hoi_hd_clc_tp_mt AS (
    SELECT
        ma_ge_khnb,
        so_don_hang,
        so_hop_dong,
        hien_trang_thu_hoi AS tinh_trang_thu_hoi
        FROM matched_invoices
        WHERE priority_rank = 1
        ORDER BY ngay_hoa_don DESC
)
, thu_hoi_dccn as 

(

SELECT 
  makhcu,
  makhthue,
  phaply,
  dccndenthang,
  namdccn,
  thangdccn
FROM `spatial-vision-343005.warehouse. view_thuhoi_dccn_kt`
WHERE ngaythuhoi IS NOT NULL
QUALIFY ROW_NUMBER() OVER(
  PARTITION BY makhcu, makhthue
  ORDER BY namdccn DESC, thangdccn DESC
) = 1
)
-- ,
-- hop_dong_clc_pcl as
-- ( 
-- select 
--   a.ma_kh as custid,
--   so_hop_dong,
--   date(a.ngay_het_hl_theo_hop_dong) as ngay_het_hieu_luc_theo_hd ,
--   date(ngay_hl_theo_hop_dong) as ngay_hl_theo_hop_dong,

-- FROM `spatial-vision-343005.staging.d_manual_clc_thu_hoi_hop_dong`  a 
-- LEFT JOIN `staging.d_master_khachhang` b on a.ma_kh = b.custid
-- where 
-- ngay_thu_hoi is not null 
-- qualify row_number() over (partition by ma_kh,ngay_hl_theo_hop_dong,ngay_het_hl_theo_hop_dong order by ngay_thu_hoi desc) = 1
-- )
-- ,

-- lay_ra_so_hd as 

-- (
-- select a.ordnbr,a.invcnbr,a.custid,d.contractnbr,sum(so_du_chungtu) as so_du_chungtu 
--   from `staging_temp.d_rawdata_debt` a 
-- LEFT JOIN `staging.sync_dms_so` b on a.branchid = b.branchid and a.mahd_so = b.ordernbr
-- JOIN `staging.d_master_khachhang` c on a.custid = c.custid and c.channel ='INS'
-- JOIN `spatial-vision-343005.staging.d_oricontract` d on cast(d.contractid as string)=b.contractid
-- group by 1,2,3,4

-- )

,
-- GOM DOANH THU & NGÀY THU TỪ BẢNG HCP_DETAIL
doanh_thu_va_ngay_thu as (
  SELECT 
    Ordnbr as sodondathang,
    InvcNbr as hoadon,
    SUM(SAFE_CAST(sotien_da_thanhtoan as FLOAT64)) as doanh_thu,
    MAX(DATE(orderdate)) as ngay_thu 
  FROM `spatial-vision-343005.staging_temp.d_rawdata_debt_detail`
  GROUP BY 1, 2
)
,

ngay_den_han as  
(
select  
custid,
  ordnbr,
--   InvcNbr,
Case 
        when mahd_so ='HL0-0524-03555' then '00100860' 
        when Ordnbr ='DL0-0124-03346' then '00045231' 
        when Ordnbr ='DL0-0124-03345' then '00045229' 
        when Ordnbr ='DL7-0624-01077' then '00135480' 
        else InvcNbr  
    end as InvcNbr,
  case when a.paymentsform = 'A' then	'Chuyển Khoản'
      when a.paymentsform = 'B' then 'Tiền Mặt'
      when a.paymentsform = 'C' then 'Tiền Mặt/Chuyển Khoản'
      when a.paymentsform = 'D'	then 'Ghi Nợ'
      when a.paymentsform = 'E'	then 'TM/CK/CTH'
      when a.paymentsform = 'F' then	'Cấn Trừ Nợ' 
    else a.paymentsform end as hinhthucthanhtoan,
case when InvcNbr in ('00048479','00048481') and custid = 'N0320716' then '45' else terms end as terms,
min(dateoforder) as dateoforder,
min(duedate) as duedate,
sum(so_du_chungtu) as so_du_chungtu

from `spatial-vision-343005.staging_temp.d_rawdata_debt` a
where invcnbr is not null 
group by 1,2,3,4,5
)
,
mapping_all as  (
SELECT
  a.thang,
  a.ma_ge_khnb,
  a.ma_csm,
  b.custname as dtcn_noi_bo,
  a.dtcn_noi_bo as dtcn_noi_bo_ori,
  a.ma_ge_vat,
  b.custnameinvoice as ten_khach_hang_thue,
  a.ten_khach_hang_thue as ten_khach_hang_thue_ori,
  b.territorydescr,
  b.statedescr,
  b.shortterritorydescr,
  b.channel,
  b.shoptype,
  b.hcotypeid,
  b.branchid,
  a.so_don_hang,
  a.so_hd,
  concat(ifnull(a.so_don_hang,''),'-',a.so_hd) as ma_dh_hd,
  date(a.ngay_hoa_don) as ngay_hoa_don,
  a.du_cuoi_ky_no,
  a.du_cuoi_ky_co,
  a.pnql,
  a.kenh_phu,
  c.descr as terms,
  d.hinhthucthanhtoan,
  c.dueintnv as thoi_han_no,
  d.duedate as ngay_den_han,
  date_diff(date(date(a.thang) + interval 1 month - interval 1 day),date(a.ngay_hoa_don),day) - c.dueintnv  as ngay_tinh_tldp,
  date_diff(date(date(a.thang) + interval 2 month - interval 1 day),date(a.ngay_hoa_don),day) - c.dueintnv  as ngay_tinh_tldp_2,
  date_diff(date(date(a.thang) + interval 3 month - interval 1 day),date(a.ngay_hoa_don),day) - c.dueintnv  as ngay_tinh_tldp_3,
  date_diff(date(date(a.thang) + interval 4 month - interval 1 day),date(a.ngay_hoa_don),day) - c.dueintnv  as ngay_tinh_tldp_4,

  e.tongtrich2023,
  -- Case when a.ngay_hoa_don <'2023-01-01' then 'BBGH năm 2022 trở về trước KT không kiểm chứng từ'
  --      when upper(f.ketoandanhan) ='X' then 'Đã thu hồi BBGNHH chuyển KT/CN'
  --      when f1.kt_da_nhan is not null and f1.hinhthucthanhtoan ='Tiền Mặt' then 'KT đã nhận hình ảnh'
  --      when f.ketoandanhan ='-' then null
  -- else ifnull(f.ketoandanhan,e.tinhtrangthuhoibienbangiaohang) end as tinh_trang_thu_hoi_bbgh,
  q.kt_da_nhan as tinh_trang_thu_hoi_bbgh,

  -- Case when ifnull(h.ma_kh,ifnull(k.custid,l.makhnbcsm)) is not null then 'Đã thu HĐ'
  --   else 'Chưa thu hồi'
  -- end as tinh_trang_thu_hoi_hd,
Case 
      when b.channel in ('INS') AND r.custid is not null then r.thu_hoi_hd
      when b.channel in ('CLC','TP','MT') AND s.ma_ge_khnb is not null then s.tinh_trang_thu_hoi
      else 'Chưa thu' end as tinh_trang_thu_hoi_hd,

 CASE 
  WHEN m.makhcu IS NOT NULL
   AND DATE_TRUNC(DATE(a.ngay_hoa_don), MONTH) <= DATE(m.namdccn, m.thangdccn, 1)
  THEN 'Đã thu hồi'
  ELSE 'Chưa thu hồi' 
END AS tinh_trang_thu_hoi_dccn,

    Case when a.ngay_hoa_don <'2023-01-01' then 'Đã ký biên bản giao hàng'
        when f1.kt_da_nhan is not null and f1.hinhthucthanhtoan ='Tiền Mặt' then 'KT đã nhận hình ảnh'
       when upper(f.ketoandanhan) ='X' then 'Đã ký biên bản giao hàng'
       when f1.kt_da_nhan is not null and f1.hinhthucthanhtoan ='Tiền Mặt' then 'KT đã nhận hình ảnh'
       when f.ketoandanhan ='-' or f.ketoandanhan is null  then 'Chưa thu biên bản giao hàng'
       when f.ketoandanhan  is not null  then 'Đã ký biên bản giao hàng'
       else null
  end as phan_loai_trich_lap,

  Case 
       when b.channel in ('INS') then r.so_hop_dong 
       when b.channel in ('CLC','TP','MT') then s.so_hop_dong
       else null end as so_hop_dong,
 
  n.check_khoi_kien,
  Case when b.statedescr in ('Thành phố Cần Thơ','Đồng Nai','Khánh Hòa','Nghệ An',
'Thành phố Đà Nẵng','Thành phố Hà Nội','Thành phố Hồ Chí Minh') then 'VP chi nhánh'
else 'Tỉnh' end as is_diadiem,
a.ghi_chu,
a.gui_mau,
a.q1,a.q2,a.q3,a.q4,a.thu_hoi_dccn,
o.col.ma_nvbh as ma_crs,
o.tencvbh as ten_crs,
o.supid as macrm,
dt.doanh_thu,
dt.ngay_thu,
m.dccndenthang as ngay_thcn_cuoi_cung,

FROM
  `spatial-vision-343005.staging.f_cong_no_kt` a 
  LEFT JOIN `staging.d_master_khachhang` b on a.ma_csm = b.custid
  LEFT JOIN ngay_den_han d on d.custid = a.ma_csm and a.so_don_hang = d.ordnbr and a.so_hd = d.InvcNbr
  LEFT JOIN `staging.d_manual_terms_detail` c on d.terms = c.termsid
  LEFT JOIN `spatial-vision-343005.staging.f_trich_lap_kt_2023` e on a.so_hd=e.so_hd and ifnull(a.so_don_hang,'') = ifnull(e.so_don_hang,'') and a.ma_csm =e.ma_csm
  LEFT JOIN `staging.d_kt_thuhoi_bbgh` f on f.noimadhsohoadon = concat(a.so_don_hang,'-',a.so_hd)
  LEFT JOIN `warehouse.f_thuhoi_bbgh`  f1 on concat(f1.sodonhang,'-',f1.sohoadon) = concat(a.so_don_hang,'-',a.so_hd)
  LEFT JOIN thu_hoi_dccn m on m.makhcu = a.ma_csm and m.makhthue = a.ma_ge_vat and trim(upper(m.phaply)) =trim(upper(a.pnql))
  LEFT JOIN `spatial-vision-343005.staging.d_manual_danh_sach_kh_khoi_kien` n on n.so_don_hang = a.so_don_hang and a.so_hd = n.so_hd
  LEFT JOIN `spatial-vision-343005.warehouse.f_mapping_crs_bytime` o on o.custid = a.ma_csm and date(date_trunc(a.thang,month)) = date(o.thang)
  LEFT JOIN doanh_thu_va_ngay_thu dt on dt.sodondathang = a.so_don_hang and dt.hoadon = a.so_hd
  LEFT JOIN thu_hoi_bbgh q on q.sodonhang = ifnull(a.so_don_hang,'') and q.sohoadon = a.so_hd
  LEFT JOIn thu_hoi_hop_dong_ins r on r.custid = a.ma_csm and ifnull(a.so_don_hang,'') = r.origordernbr 
  LEFT JOIN thu_hoi_hd_clc_tp_mt s on s.ma_ge_khnb = a.ma_ge_khnb AND s.so_don_hang = ifnull(a.so_don_hang,'')
  where a.du_cuoi_ky_no > 0 and UPPER(TRIM(b.custname)) NOT LIKE '%GONSA%'
)
,tinh_trich_lap_dp as (
select 
  a.*,
  b.tencvbh as ten_crm,
  Case 
    when thoi_han_no <=3 and is_diadiem ='VP chi nhánh' then 
 date_add(date(ngay_den_han),interval 1 day)   
    when thoi_han_no <=3 and is_diadiem ='Tỉnh' then 
 date_add(date(ngay_den_han),interval 3 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then 
 date_add(date(ngay_den_han),interval 2 day) 
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then 
 date_add(date(ngay_den_han),interval 4 day) 

    when thoi_han_no <=15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(ngay_den_han),interval 2 day) 
    when thoi_han_no <=15
     and is_diadiem ='Tỉnh' then 
 date_add(date(ngay_den_han),interval 4 day) 
    
    when thoi_han_no > 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(ngay_den_han),interval 2 day) 
     when thoi_han_no > 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(ngay_den_han),interval 4 day) 
 
  else  null

 end as thoi_diem_no_vang,

 Case 
    when thoi_han_no <=3 and is_diadiem ='VP chi nhánh' then 
 date_add(date(ngay_den_han),interval 6 day)   
    when thoi_han_no <=3 and is_diadiem ='Tỉnh' then 
 date_add(date(ngay_den_han),interval 8 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then 
 date_add(date(ngay_den_han),interval 7 day) 
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then 
 date_add(date(ngay_den_han),interval 9 day) 

    when thoi_han_no <= 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(ngay_den_han),interval 17 day) 
    when thoi_han_no <= 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(ngay_den_han),interval 19 day) 
    
    when thoi_han_no > 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(ngay_den_han),interval 32 day) 
     when thoi_han_no > 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(ngay_den_han),interval 34 day) 
 
  else  null

 end as thoi_diem_no_do,
 Case 
    when thoi_han_no <= 3 and is_diadiem ='VP chi nhánh' then 
 date_add(date(ngay_den_han),interval 10 day)   
    when thoi_han_no <= 3 and is_diadiem ='Tỉnh' then 
 date_add(date(ngay_den_han),interval 12 day)

     when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='VP chi nhánh' then 
 date_add(date(ngay_den_han),interval 11 day) 
    when terms in ('Gối 1 Đơn Hàng (trong 30 ngày)') and is_diadiem ='Tỉnh' then 
 date_add(date(ngay_den_han),interval 13 day) 

    when thoi_han_no <= 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(ngay_den_han),interval 32 day) 
    when thoi_han_no <= 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(ngay_den_han),interval 34 day) 
    
    when thoi_han_no > 15
     and is_diadiem ='VP chi nhánh' then 
 date_add(date(ngay_den_han),interval 62 day) 
     when thoi_han_no > 15
     and is_diadiem ='Tỉnh' then 
 date_add(date(ngay_den_han),interval 64 day) 
 
  else  null

 end as thoi_diem_no_den,

  Case when check_khoi_kien is null and ngay_tinh_tldp < 180 and IFNULL(ghi_chu,'') != 'KH trong danh sách khởi kiện' then 0/100 * du_cuoi_ky_no
      else 0 end as less_6_month,
  Case when  check_khoi_kien is null and ngay_tinh_tldp >= 180 and ngay_tinh_tldp < 365 and IFNULL(ghi_chu,'') != 'KH trong danh sách khởi kiện'  then 30/100 * du_cuoi_ky_no
      else 0 end as from_6_month_to_1_year,
  Case when  check_khoi_kien is null and ngay_tinh_tldp >= 365 and ngay_tinh_tldp < 365*2 and IFNULL(ghi_chu,'') != 'KH trong danh sách khởi kiện' then 50/100 * du_cuoi_ky_no
      else 0 end as from_1_year_to_2_year,
  Case when  check_khoi_kien is null and ngay_tinh_tldp >= 365*2 and ngay_tinh_tldp < 365*3 and IFNULL(ghi_chu,'') != 'KH trong danh sách khởi kiện'  then 70/100 * du_cuoi_ky_no
      else 0 end as from_2_year_to_3_year,
  Case when  check_khoi_kien is null and ngay_tinh_tldp >= 365*3 and IFNULL(ghi_chu,'') != 'KH trong danh sách khởi kiện' then 100/100 * du_cuoi_ky_no
      else 0 end as over_3_year,
  Case when check_khoi_kien is not null then 100/100 * du_cuoi_ky_no
    when ghi_chu = 'KH trong danh sách khởi kiện' then 100/100 * du_cuoi_ky_no
      else 0 end as trich_lap_khoi_kien,

---Tính cho sales

  Case when ngay_tinh_tldp >= 180 and ngay_tinh_tldp < 365  then 100/100 * du_cuoi_ky_no
      else 0 end as from_6_month_to_1_year_crm,
  Case when  ngay_tinh_tldp >= 365 and ngay_tinh_tldp < 365*2 then 100/100 * du_cuoi_ky_no
      else 0 end as from_1_year_to_2_year_crm,
  Case when  ngay_tinh_tldp >= 365*2 and ngay_tinh_tldp < 365*3  then 100/100 * du_cuoi_ky_no
      else 0 end as from_2_year_to_3_year_crm,
  Case when  ngay_tinh_tldp >= 365*3 then 100/100 * du_cuoi_ky_no
      else 0 end as over_3_year_crm,

  Case when ngay_tinh_tldp_2 < 180 then 0/100 * du_cuoi_ky_no
      else 0 end as less_6_month_2,
  Case when  ngay_tinh_tldp_2 >= 180 and ngay_tinh_tldp_2 < 365  then 100/100 * du_cuoi_ky_no
      else 0 end as from_6_month_to_1_year_2,
  Case when  ngay_tinh_tldp_2 >= 365 and ngay_tinh_tldp_2 < 365*2 then 100/100 * du_cuoi_ky_no
      else 0 end as from_1_year_to_2_year_2,
  Case when  ngay_tinh_tldp_2 >= 365*2 and ngay_tinh_tldp_2 < 365*3  then 100/100 * du_cuoi_ky_no
      else 0 end as from_2_year_to_3_year_2,
  Case when   ngay_tinh_tldp_2 >= 365*3 then 100/100 * du_cuoi_ky_no
      else 0 end as over_3_year_2,

  Case when  ngay_tinh_tldp_3 >= 180 and ngay_tinh_tldp_3 < 365  then 100/100 * du_cuoi_ky_no
      else 0 end as from_6_month_to_1_year_3,
  Case when  ngay_tinh_tldp_3 >= 365 and ngay_tinh_tldp_3 < 365*2 then 100/100 * du_cuoi_ky_no
      else 0 end as from_1_year_to_2_year_3,
  Case when  ngay_tinh_tldp_3 >= 365*2 and ngay_tinh_tldp_3 < 365*3  then 100/100 * du_cuoi_ky_no
      else 0 end as from_2_year_to_3_year_3,
  Case when   ngay_tinh_tldp_3 >= 365*3 then 100/100 * du_cuoi_ky_no
      else 0 end as over_3_year_3,

  Case when  ngay_tinh_tldp_4 >= 180 and ngay_tinh_tldp_4 < 365  then 100/100 * du_cuoi_ky_no
      else 0 end as from_6_month_to_1_year_4,
  Case when  ngay_tinh_tldp_4 >= 365 and ngay_tinh_tldp_4 < 365*2 then 100/100 * du_cuoi_ky_no
      else 0 end as from_1_year_to_2_year_4,
  Case when  ngay_tinh_tldp_4 >= 365*2 and ngay_tinh_tldp_4 < 365*3  then 100/100 * du_cuoi_ky_no
      else 0 end as from_2_year_to_3_year_4,
  Case when   ngay_tinh_tldp_4 >= 365*3 then 100/100 * du_cuoi_ky_no
      else 0 end as over_3_year_4,

from mapping_all a 
LEFT JOIN `staging.d_users` b on b.manv = a.macrm

),

phan_loai_no as (
select  *,

less_6_month + from_6_month_to_1_year + from_1_year_to_2_year + from_2_year_to_3_year + over_3_year + trich_lap_khoi_kien as tong_trich_hientai,
from_6_month_to_1_year_2 + from_1_year_to_2_year_2 + from_2_year_to_3_year_2 + over_3_year_2 as tong_trich_hientai_2,
from_6_month_to_1_year_3 + from_1_year_to_2_year_3 + from_2_year_to_3_year_3 + over_3_year_3 as tong_trich_hientai_3,
from_6_month_to_1_year_4 + from_1_year_to_2_year_4 + from_2_year_to_3_year_4 + over_3_year_4 as tong_trich_hientai_4,
from_6_month_to_1_year_crm + from_1_year_to_2_year_crm + from_2_year_to_3_year_crm + over_3_year_crm as tong_trich_hientai_crm,


Case 
   when date(date(thang) + interval 1 month - interval 1 day) >= thoi_diem_no_den and du_cuoi_ky_no > 0 then 'Nợ đen'
   when date(date(thang) + interval 1 month - interval 1 day) >= thoi_diem_no_do and  du_cuoi_ky_no > 0 then 'Nợ đỏ'
   when date(date(thang) + interval 1 month - interval 1 day) >= thoi_diem_no_vang and du_cuoi_ky_no > 0 then 'Nợ vàng'
   when date(date(thang) + interval 1 month - interval 1 day) < thoi_diem_no_vang and du_cuoi_ky_no > 0  then 'Nợ xanh'
  else null end as phanloai_no
from tinh_trich_lap_dp 
),
tinh_du_no as (
select *,
Case when phanloai_no ='Nợ xanh' then du_cuoi_ky_no else 0 end as no_xanh,
Case when phanloai_no ='Nợ vàng' then du_cuoi_ky_no else 0 end as no_vang,
Case when phanloai_no ='Nợ đỏ' then du_cuoi_ky_no else 0 end as no_do,
Case when phanloai_no ='Nợ đen' then du_cuoi_ky_no else 0 end as no_den,
Case when phanloai_no in ('Nợ đỏ','Nợ đen') then du_cuoi_ky_no else 0 end as no_xau,
 from phan_loai_no 
)
,gui_thu_nhac_no as (
SELECT
DISTINCT
a.makhcu,
a.makhthue,
--a.dccndenthang,
MAX(NULLIF(TRIM(a.thunhacno), '-')) AS thunhacno,
MAX(NULLIF(TRIM(a.canhbaono), '-')) AS canhbaono,
  MAX(NULLIF(TRIM(a.khoikien), '-')) AS khoikien
FROM `spatial-vision-343005.warehouse. view_thuhoi_dccn_kt` a
GROUP BY 1,2
)
,tong_hop_gui_c123 AS (
    SELECT
    ma_kh,
    ma_kh_thue,
    phap_nhan,
    so_lan_gui_c1_luy_ke,
    so_lan_gui_c2_luy_ke,
    so_lan_gui_c3_luy_ke
    FROM `spatial-vision-343005.warehouse.view_tong_hop_gui_c1_c2_c3`
)

, thong_tin_gui_dccn_moi_nhat as (
  SELECT 
      makhcu, 
      makhthue, 
      phaply,
      cv AS thong_tin_gui_dccn,
      sodienthoai AS sdt_nguoi_nhan,
      nguoinhan AS nguoi_nhan
  FROM `spatial-vision-343005.warehouse. view_thuhoi_dccn_kt`
  WHERE makhcu IS NOT NULL OR makhthue IS NOT NULL
  QUALIFY ROW_NUMBER() OVER(
      PARTITION BY makhcu, makhthue, phaply 
      ORDER BY 
          CAST(namdccn AS INT64) DESC, 
          CAST(thangdccn AS INT64) DESC, 
          inserted_at DESC
  ) = 1
)
, result as (
select 
*,
0 as noxautrichlap,
current_datetime("+7") as updated_at, 
from tinh_du_no

)

select 
a.* ,
d,thunhacno,
d.canhbaono,
f.so_lan_gui_c1_luy_ke,
f.so_lan_gui_c2_luy_ke,
f.so_lan_gui_c3_luy_ke,
e.thong_tin_gui_dccn,
e.sdt_nguoi_nhan,
e.nguoi_nhan,
CASE 
        WHEN LOWER(a.ghi_chu) LIKE '%khởi kiện%' THEN 'Khởi kiện' 
        ELSE NULL 
    END AS khoikien,
g.danh_gia_rui_ro_no_qua_han,
g.trich_bo_sung,
IFNULL(tong_trich_hientai,0) + IFNULL(g.trich_bo_sung,0) as tong_trich_hientai_sau_bs
from result a
LEFT JOIN gui_thu_nhac_no d on d.makhcu = a.ma_ge_khnb and d.makhthue = a.ma_ge_vat
LEFT JOIN thong_tin_gui_dccn_moi_nhat e 
  ON e.makhcu = a.ma_ge_khnb 
  AND e.makhthue = a.ma_ge_vat 
  AND TRIM(UPPER(e.phaply)) = TRIM(UPPER(a.pnql))
LEFT JOIN tong_hop_gui_c123 f 
    ON f.ma_kh = a.ma_ge_khnb
    AND f.ma_kh_thue = a.ma_ge_vat
    AND TRIM(UPPER(f.phap_nhan)) = TRIM(UPPER(a.pnql))
LEFT JOIN `spatial-vision-343005.staging_temp.d_trich_lap_bo_sung_kt` g 
    ON g.ma_kh = a.ma_ge_khnb
    AND g.so_don_hang = a.so_don_hang
    AND g.so_hd = a.so_hd

--)
;

Create or replace table `warehouse.f_trich_lap_du_phong_du_no`

copy `staging_temp.f_trich_lap_du_phong_du_no_temp`;

END;