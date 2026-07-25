CREATE PROCEDURE `spatial-vision-343005`.staging_temp.f_stt_hanghoa()
BEGIN 
 
 TRUNCATE TABLE staging_temp.f_stt_hanghoa_temp;

 INSERT INTO `staging_temp.f_stt_hanghoa_temp`

(  
-- Create or replace table `staging_temp.f_stt_hanghoa_temp`
-- as

with thongtin_banhang as
(
  select 
    distinct ngaychungtu,
    sodondathang,
    makhdms, 
    tenkhachhang, 
    tentinhkh,
    hoadon, 
    makenhphu, 
    manv, 
    tencvbh,
    ifnull(manvghreal,manvgh) as ma_mds, 
    ifnull(tennvghreal,nguoigiaohang) as ten_mds, 
    -- tensanphamviettat,
    -- tensanphamnb,
    -- solo
  from `spatial-vision-343005.staging.f_sales`
)
  SELECT 
    a.*,
    b.*except(sodondathang)
  FROM `spatial-vision-343005.staging.stt_hanghoa` a
  left join thongtin_banhang b on trim(a.ma_dh_full) = b.sodondathang 
  where a.ma_dh_full is not null and  ma_dh_tat is not null

);

Create or replace table `warehouse.f_stt_hanghoa`

copy `staging_temp.f_stt_hanghoa_temp`;

END;