CREATE VIEW `spatial-vision-343005.warehouse.view_data_contract_sign_by_users`
AS WITH sync_data as
(
SELECT
  /* Trạng thái ký */
  JSON_VALUE(js, '$.is_signed') AS da_ky_hay_chua,
  JSON_VALUE(js, '$.status_signed') AS trang_thai_ky,

  /* file + url */
  JSON_VALUE(js, '$.active') AS trang_thai_hoat_dong,
  JSON_VALUE(js, '$.attachment_name') AS ten_file_dinh_kem,
  JSON_VALUE(js, '$.attachment_url') AS duong_dan_file,

  /* Thông tin hợp đồng & Chính sách */
  
    JSON_VALUE(js, '$.contract_code') AS ma_hop_dong,
    CONCAT(JSON_VALUE(js, '$.customer_code'), '/', JSON_VALUE(js, '$.document_code')) AS ma_tren_hop_dong,
    JSON_VALUE(js, '$.contract_name') AS ten_hop_dong,
    JSON_VALUE(js, '$.contract_type_code') AS ma_loai_hop_dong,
    JSON_VALUE(js, '$.contract_type_name') AS ten_loai_hop_dong,
    JSON_VALUE(js, '$.contract_data') AS du_lieu_hop_dong,
    JSON_VALUE(js, '$.csbh_hinh_thuc') AS hinh_thuc_csbh,
    JSON_VALUE(js, '$.thoi_han_thanh_toan') AS thoi_han_thanh_toan,
    JSON_VALUE(js, '$.internal_promo_code') AS internal_promo_code,

  /* Lấy mức hợp đồng từ các key có dấu chấm */
  COALESCE(
    /* Nhóm PMC_CTD */ 
    JSON_VALUE(js, '$."HDMB_CSBH_PMC_CTD_QUY4_2026.muc.muc_doanh_so_nam"'),
    JSON_VALUE(js, '$."HDMB_CSBH_PMC_CTD_QUY3_2026.muc.muc_doanh_so_nam"'),
    JSON_VALUE(js, '$."HDMB_CSBH_PMC_CTD_QUY2_2026.muc.muc_doanh_so_nam"'),
    JSON_VALUE(js, '$."HDMB_CSBH_PMC_CTD_QUY1_2026.muc.muc_doanh_so_nam"'),
    /* Nhóm PKN_PKQ */
    JSON_VALUE(js, '$."HDMB_CSBH_PKN_PKQ_QUY4_2026.muc.muc_doanh_so_nam"'),
    JSON_VALUE(js, '$."HDMB_CSBH_PKN_PKQ_QUY3_2026.muc.muc_doanh_so_nam"'),
    JSON_VALUE(js, '$."HDMB_CSBH_PKN_PKQ_QUY2_2026.muc.muc_doanh_so_nam"'),
    JSON_VALUE(js, '$."HDMB_CSBH_PKN_PKQ_QUY1_2026.muc.muc_doanh_so_nam"'),
    /* Trường điều kiện khác */
    JSON_VALUE(js, '$.dieu_kien_muc_phi_tra_thuong')
  ) AS muc_hop_dong,

 /* 2. Mức CŨ NHẤT: Ưu tiên quét từ Quý 1 -> Quý 4 (Gồm cả 2 mã PMC_CTD và PKN_PKQ) */
  COALESCE(
    /* --- ƯU TIÊN 1: Tìm Quý 1 trước --- */
    JSON_VALUE(js, '$."HDMB_CSBH_PMC_CTD_QUY_1_2026.muc.muc_doanh_so_nam"'),
    JSON_VALUE(js, '$."HDMB_CSBH_PMC_CTD_QUY1_2026.muc.muc_doanh_so_nam"'),
    JSON_VALUE(js, '$."HDMB_CSBH_PKN_PKQ_QUY_1_2026.muc.muc_doanh_so_nam"'),
    JSON_VALUE(js, '$."HDMB_CSBH_PKN_PKQ_QUY1_2026.muc.muc_doanh_so_nam"'),
    
    /* --- ƯU TIÊN 2: Tìm Quý 2 --- */
    JSON_VALUE(js, '$."HDMB_CSBH_PMC_CTD_QUY2_2026.muc.muc_doanh_so_nam"'),
    JSON_VALUE(js, '$."HDMB_CSBH_PKN_PKQ_QUY2_2026.muc.muc_doanh_so_nam"'),
    
    /* --- ƯU TIÊN 3: Tìm Quý 3 --- */
    JSON_VALUE(js, '$."HDMB_CSBH_PMC_CTD_QUY3_2026.muc.muc_doanh_so_nam"'),
    JSON_VALUE(js, '$."HDMB_CSBH_PKN_PKQ_QUY3_2026.muc.muc_doanh_so_nam"'),
    
    /* --- ƯU TIÊN 4: Tìm Quý 4 --- */
    JSON_VALUE(js, '$."HDMB_CSBH_PMC_CTD_QUY4_2026.muc.muc_doanh_so_nam"'),
    JSON_VALUE(js, '$."HDMB_CSBH_PKN_PKQ_QUY4_2026.muc.muc_doanh_so_nam"'),
    
    /* Điều kiện khác cuối cùng */
    JSON_VALUE(js, '$.dieu_kien_muc_phi_tra_thuong')
  ) AS muc_hop_dong_cu,
  
  /*thời gian*/
  SAFE_CAST(JSON_VALUE(js, '$.created_at') AS TIMESTAMP) AS thoi_gian_tao,
  SAFE_CAST(JSON_VALUE(js, '$.signed_at') AS TIMESTAMP) AS thoi_gian_ky,

  /* Thông tin khách hàng */
  JSON_VALUE(js, '$.customer_code') AS ma_khach_hang,
  JSON_VALUE(js, '$.customer_name') AS ten_khach_hang_he_thong, /* Tên hiển thị trên hệ thống (QT...) */
  JSON_VALUE(js, '$.ten_khach_hang') AS ten_khach_hang_phap_ly, /* Tên trên giấy phép (Hộ Kinh Doanh...) */
  JSON_VALUE(js, '$.ten_khach_hang_gpp') AS ten_khach_hang_gpp, /* Tên biển hiệu nhà thuốc */
  JSON_VALUE(js, '$.customer_inv_code') AS ma_khach_hang_thue,
  JSON_VALUE(js, '$.customer_inv_name') AS ten_khach_hang_thue,
  JSON_VALUE(js, '$.dia_chi_dang_ky_kinh_doanh') AS dia_chi_dkkd,
  JSON_VALUE(js, '$.ma_so_thue') AS ma_so_thue,
  JSON_VALUE(js, '$.so_dien_thoai') AS so_dien_thoai,

  /* Thông tin đại diện pháp luật */
  JSON_VALUE(js, '$.dai_dien_dang_ky_kinh_doanh') AS dai_dien_dkkd,
  JSON_VALUE(js, '$.dai_dien_ky_hop_dong') AS dai_dien_ky_hop_dong,
  JSON_VALUE(js, '$.so_cccd_dai_dien') AS so_cccd_dai_dien,
  JSON_VALUE(js, '$.so_dinh_danh_cn') AS so_dinh_danh_ca_nhan,

  /* Thông tin người tạo & ID tham chiếu */
  JSON_VALUE(js, '$.created_by') AS id_nguoi_tao,
  JSON_VALUE(js, '$.created_code') AS ma_nhan_vien_tao,
  JSON_VALUE(js, '$.id_contract') AS id_hop_dong,
  JSON_VALUE(js, '$.id_contract_type') AS id_loai_hop_dong,
  JSON_VALUE(js, '$.id_customer') AS id_khach_hang,
  b.tencvbh,
  b.supid,
  b.tenquanlytt,

  etl_at AS thoi_gian_cap_nhat_he_thong
  
FROM `spatial-vision-343005.staging.data_contract_sign_by_users` a
LEFT JOIN `staging.d_users` b ON JSON_VALUE(a.js, '$.created_code') = b.manv

)

, LogicSigned AS (
    SELECT 
    * EXCEPT(muc_hop_dong,muc_hop_dong_cu),
    /* ĐIỀU CHỈNH LOGIC CHO CỘT MỨC HỢP ĐỒNG */
        CASE 
            -- 1. Nhóm PMC-CTD / PKN-PKQ: Xóa ký hiệu "≥", ">=" và khoảng trắng để trả về chuỗi số sạch
            WHEN internal_promo_code IN ('202601-TL-QD785-PMC-CTD', '202601-TL-QD786-PKN-PKQ') THEN 
                TRIM(REGEXP_REPLACE(muc_hop_dong, r'^[≥>=]+\s*', ''))
                
            -- 2. Khung Ebysta: Trích xuất chỉ lấy cụm từ "Mức 1", "Mức 2", ...
            WHEN internal_promo_code = '2604-CTTB-26MTP2022-NT-QT' THEN 
                REGEXP_EXTRACT(muc_hop_dong, r'(Mức \d+)')
                
            -- 3. Các trường hợp còn lại: Giữ nguyên
            ELSE muc_hop_dong 
        END AS muc_hop_dong,

        CASE 
      /* Nếu mức cũ giống hệt mức mới -> Khách hàng chỉ có 1 mức -> Trả về NULL */
      WHEN muc_hop_dong_cu = muc_hop_dong THEN NULL 
      
      /* Nếu khác nhau -> Làm sạch chuỗi mức cũ tương tự như mức mới */
      WHEN internal_promo_code IN ('202601-TL-QD785-PMC-CTD', '202601-TL-QD786-PKN-PKQ') THEN 
        TRIM(REGEXP_REPLACE(muc_hop_dong_cu, r'^[≥>=]+\s*', ''))
      WHEN internal_promo_code = '2604-CTTB-26MTP2022-NT-QT' THEN 
        REGEXP_EXTRACT(muc_hop_dong_cu, r'(Mức \d+)')
      ELSE muc_hop_dong_cu
    END AS muc_hop_dong_cu,

    /*Thời gian ký mới nhất, trạng thái đã ký, lấy mới nhất theo mã kh + tên HĐ*/
           -- Chỉ đánh số thứ tự cho những dòng có trạng thái 'Đã ký'
           CASE 
                WHEN trang_thai_ky = 'Đã ký' THEN 
                    ROW_NUMBER() OVER (
                        PARTITION BY ma_khach_hang, ten_hop_dong, trang_thai_ky 
                        ORDER BY thoi_gian_ky DESC
                    )
                ELSE 1 -- Các trạng thái khác (Chưa ký, v.v.) giữ nguyên, không lọc
           END as rn
    FROM sync_data
)
SELECT *
FROM LogicSigned
WHERE rn = 1;






;