CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danhsach_ketnoi_zalo_oa()
BEGIN
 
TRUNCATE TABLE `staging_temp.f_danhsach_ketnoi_zalo_oa_temp`;

INSERT INTO `staging_temp.f_danhsach_ketnoi_zalo_oa_temp`

(   
-- Create or replace table staging_temp.f_danhsach_ketnoi_zalo_oa_temp as

  SELECT 
  a.customer_code,
  a.customer_phone,
  a.customer_name,
  b.branchid,
  b.branchname,
  b.statedescr,
  b.shortterritorydescr,
  b.active,
  b.channel,
  b.shoptype,
  b.hcotypeid,
  b.hcoid,
  b.classid,
  a.follow_name,
  a.follow_phone,
  a.gender,
  a.birthday,
  a.follow_address,
  a.customer_address,
  a.updated_at,
  a.customer_role_name,
  a.office_code,
  a.office_name,
  a.user_name,
  a.user_code,
  a.pharmacy_name,
  a.status,
  '' as labels,
  0 as total_mess,
  a.created_at,
  a.inserted_at,
  'N' as is_check_today_birthday
  -- Case when cast(right(birthday,2) as int) = extract(day from current_date("+7")) 
  -- and cast(substr(birthday,6,2) as int) = extract(month from current_date("+7")) 
  -- then 'Y' else 'N' end as is_check_today_birthday

 FROM `spatial-vision-343005.staging.f_crawl_activate_ecom`  a
 LEFT JOIN `staging.d_master_khachhang` b on a.customer_code = b.custid
--  qualify row_number() over (partition by customer_code order by created_at desc) = 1

 );

Create or replace table `warehouse.f_danhsach_ketnoi_zalo_oa`

copy `staging_temp.f_danhsach_ketnoi_zalo_oa_temp`;


END;