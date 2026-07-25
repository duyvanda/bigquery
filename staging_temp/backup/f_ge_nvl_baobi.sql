CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_ge_nvl_baobi()
BEGIN 
 
TRUNCATE TABLE staging_temp.f_ge_nvl_baobi_temp;

INSERT INTO `staging_temp.f_ge_nvl_baobi_temp`

(  


-- Create or replace table `staging_temp.f_ge_nvl_baobi_temp`
-- as

SELECT 
  mavattu,
  masanpham,
  case when left(msx,1) = 'A' then 'Nguyên liệu - Hóa chất' 
       when left(msx,1) = 'B' then 'Bao bì cấp 1'
       when left(msx,1) = 'C' then 'Bao bì cấp 2'
       when left(msx,1) = 'E' then 'Vặt tư tiêu hao'
       when left(msx,1) = 'D' then 'Nguyên liệu bao vì của CN sx chai nhựa'
       when left(msx,1) = 'T' then 'Thành phẩm/Bán thành phẩm'
       else 'Chưa khai báo' end as phanbiet_nvl,
  msx,
  tenvattu,	
  ngaychungtu,	
  sochungtu,
  sohoadon,	
  ngayhoadon,	
  soluong,	
  dongia,	
  thanhtien,	
  dvt,	
  dongianguyente,	
  thanhtiennguyente,	
  nhasanxuat,	
  makh,
  makhsx,	
  tenkh
FROM `spatial-vision-343005.staging.f_ge_giao_dich_nvl_bao_bi`

);

Create or replace table `warehouse.f_ge_nvl_baobi`

copy `staging_temp.f_ge_nvl_baobi_temp`;

END;