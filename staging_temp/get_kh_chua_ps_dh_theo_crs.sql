CREATE PROCEDURE `spatial-vision-343005`.warehouse.get_kh_chua_ps_dh_theo_crs(url_param STRING)
BEGIN
  -- 1. Declare biến
  DECLARE v_ma_crs STRING;
  
  -- 2. Parse parameters từ JSON input (Lấy key ma_crs)
  SET v_ma_crs = COALESCE(JSON_VALUE(url_param, '$.ma_crs'), '');

  -- 3. Thực thi Query chính
  SELECT (
      WITH 
      tuyen_dms AS (
        SELECT custid, slsperid 
        FROM `spatial-vision-343005.staging.sync_dms_srm`
        WHERE delroutedet IS FALSE
        QUALIFY ROW_NUMBER() OVER (
          PARTITION BY custid 
          ORDER BY (CASE WHEN routetype IN ('B','D') THEN 1 ELSE 2 END) ASC, crtd_datetime DESC
        ) = 1
      ),
      tuyen_hd AS (
        SELECT custid, slsperid
        FROM `spatial-vision-343005.staging.d_get_contract_det`
        WHERE slsperid NOT IN ('GH001','QUYNHPTA','MA001','MA002')
      ),
      mapping_mcp_hd AS (
        SELECT custid, slsperid FROM tuyen_dms
        UNION DISTINCT
        SELECT custid, slsperid FROM tuyen_hd
      ),
      sales AS (
        SELECT makhdms, MAX(DATE(ngaychungtu)) AS ngay_dat_don_gan_nhat 
        FROM `spatial-vision-343005.warehouse.f_raw_data_sales_yoy` 
        GROUP BY 1
      ),
      final_list AS (
        SELECT 
          a.custid AS ma_kh_dms,
          c.custname AS ten_kh,
          a.slsperid AS ma_crs,
          d.tencvbh AS ten_crs,
          d.supid AS ma_crm,
          d.tenquanlytt AS ten_crm,
          -- Lấy ngày đầu tháng hiện tại
          DATE(DATE_TRUNC(CURRENT_DATE("+07"), MONTH)) AS thang_hien_tai,
          b.ngay_dat_don_gan_nhat,
          -- Logic: Check mua hàng trong tháng dựa trên thang_hien_tai
          CASE 
            WHEN DATE(DATE_TRUNC(CURRENT_DATE("+07"), MONTH)) = DATE(DATE_TRUNC(b.ngay_dat_don_gan_nhat, MONTH)) THEN 'Y' 
            ELSE 'N' 
          END AS is_check_mua_hang_trong_thang,
          -- Logic: Nếu đã mua trong tháng thì null, ngược lại lấy mã khách hàng
          CASE 
            WHEN DATE(DATE_TRUNC(CURRENT_DATE("+07"), MONTH)) = DATE(DATE_TRUNC(b.ngay_dat_don_gan_nhat, MONTH)) THEN NULL 
            ELSE a.custid 
          END AS so_khach_hang_chua_ps_dh,
          -- Tính số ngày trễ
          DATE_DIFF(CURRENT_DATE("+07"), IFNULL(b.ngay_dat_don_gan_nhat, DATE('2023-01-01')), DAY) AS so_ngay_dat_don_gan_nhat
        FROM mapping_mcp_hd a
        INNER JOIN `spatial-vision-343005.staging.d_master_khachhang` c ON a.custid = c.custid
        LEFT JOIN `spatial-vision-343005.staging.d_users` d ON a.slsperid = d.manv
        LEFT JOIN sales b ON a.custid = b.makhdms 
        WHERE c.active = 'Active' 
          AND (v_ma_crs = '' OR CONTAINS_SUBSTR(CONCAT(COALESCE(d.supid,''), COALESCE(a.slsperid,'')), v_ma_crs))
      ),
      overview_data AS (
        SELECT 
          COUNTIF(is_check_mua_hang_trong_thang = 'Y') AS da_mua,
          COUNTIF(is_check_mua_hang_trong_thang = 'N') AS chua_mua,
          COUNT(*) AS total_rows
        FROM final_list
      )
      
      -- Render kết quả JSON cuối cùng
      SELECT JSON_OBJECT(
        'status', 'ok',
        'rows', COALESCE((SELECT total_rows FROM overview_data), 0),
        'data', JSON_OBJECT(
          'Overview', JSON_OBJECT(
            'da_mua', COALESCE((SELECT da_mua FROM overview_data), 0),
            'chua_mua', COALESCE((SELECT chua_mua FROM overview_data), 0)
          ),
          'Detail', COALESCE(
            (SELECT TO_JSON(ARRAY_AGG(t ORDER BY t.is_check_mua_hang_trong_thang ASC, t.so_ngay_dat_don_gan_nhat DESC)) 
             FROM final_list t), 
            JSON_ARRAY()
          )
        )
      )
  ) AS json_result;

EXCEPTION WHEN ERROR THEN
  SELECT JSON_OBJECT(
      'status', 'fail',
      'error_message', @@error.message
  ) AS json_result;
END;