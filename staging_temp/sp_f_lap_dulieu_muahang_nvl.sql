CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_lap_dulieu_muahang_nvl()
BEGIN 
 
 TRUNCATE TABLE `staging_temp.f_lap_dulieu_muahang_nvl_temp`;

 INSERT INTO `staging_temp.f_lap_dulieu_muahang_nvl_temp`

(   

-- Create or replace table staging_temp.f_lap_dulieu_muahang_nvl_temp
-- as
with data_mua_nvl as (
SELECT
  a.ma,
  trim(regexp_replace(ifnull(c.ten,a.tennvl),"\n",''))  as tennvl,
  thoigiandathangmmyy,
  trim(regexp_replace(nsx,"\n",''))  as nsx,
  -- nsx,
  a.diadiemgiao,
  a.mancc,
  trim(regexp_replace(ncc,"\n",''))  as ncc,
  a.dvt,
  a.soluongdathang,
  Case when thanhtien >0 then ifnull(soluongthucnhan,soluongdathang) else 0 end as soluongthucnhan,
  ifnull(a.donvitiente,b.dvtiente) as donvitiente,
   Case when ifnull(a.donvitiente,b.dvtiente) ='USD' then dongiachuavat * 23920 
      when ifnull(a.donvitiente,b.dvtiente) ='EUR' then dongiachuavat * 25468
      else dongiachuavat end as dongiachuavat_vnd,
  dongiachuavat,
  thanhtien,
  Case when ifnull(a.donvitiente,b.dvtiente) ='USD' then thanhtien * 23920 
      when ifnull(a.donvitiente,b.dvtiente) ='EUR' then thanhtien * 25468
      else thanhtien end as thanhtien_vnd,
  kehoachgiaohang,
  timethuctegiaohangkho,
  trim(regexp_replace(a.ghichu,"\n",''))  as ghichu,
  -- Case when timethuctegiaohangkho is null then date_diff(date((select * from `staging.d_current_table`)),date(thoigiandathangmmyy),day) else
  date_diff(date(timethuctegiaohangkho),date(thoigiandathangmmyy),day)  as songay_giaohang,
  b.leadtimethang,
  b.leadtimethang * 30 as leadtime_gh_ngay,
  Case 
    when xacnhanghncc_ghichu is not null then 'Hủy'
    when b.leadtimethang is null then 'Không có leadtime GH'
    when timethuctegiaohangkho is not null and xacnhanghncc_ghichu is null
          and date_diff(date(timethuctegiaohangkho),date(thoigiandathangmmyy),day) <= b.leadtimethang * 30   then 'Đúng Leadtime GH'
    when timethuctegiaohangkho is null  and xacnhanghncc_ghichu is null 
          and date_diff(date((select * from `staging.d_current_table`)),date(thoigiandathangmmyy),day)  <= b.leadtimethang * 30 
  then 'Đúng Leadtime GH' 
  else 'Trễ Leadtime GH' end as is_check_leadtime_gh,
  xacnhanghncc_ghichu,
     Case when ifnull(a.donvitiente,b.dvtiente) ='USD' then coalesce(b.dongia5,b.dongia4,b.dongia3,b.dongia2,b.dongia1) * 23920 
      when ifnull(a.donvitiente,b.dvtiente) ='EUR' then coalesce(b.dongia5,b.dongia4,b.dongia3,b.dongia2,b.dongia1) * 25468
      else coalesce(b.dongia5,b.dongia4,b.dongia3,b.dongia2,b.dongia1) end as dongia_moinhat,
  -- coalesce(b.dongia5,b.dongia4,b.dongia3,b.dongia2,b.dongia1) as dongia_moinhat,


  
  coalesce(b.dongia5,b.dongia4,b.dongia3,b.dongia2,b.dongia1) as dongia5, 
  coalesce(b.dongia4,b.dongia3,b.dongia2,b.dongia1) as dongia4, 
  coalesce(b.dongia3,b.dongia2,b.dongia1) as dongia3, 
  ifnull(b.dongia2,b.dongia1) as dongia2,
  b.dongia1,
  min(dongiachuavat) over(partition by a.ma,a.mancc ) as giathapnhat,
  max(dongiachuavat) over(partition by a.ma,a.mancc ) as giacaonhat, 

FROM
  `spatial-vision-343005.staging.d_lab_dulieu_muahang_nvl` a
  LEFT JOIN `staging.d_lab_danhsach_nvl` b on a.ma =b.ma and a.mancc =b.mancc
  LEFT JOIN `staging.d_lab_danhsach_nvl` c on c.ma =a.ma 
  -- where a.ma='A032013'
)

select *,
Count(distinct mancc) over (partition by ma) as check_nvl_mancc,
round(safe_divide(dongia_moinhat,dongiachuavat_vnd),2) as chenhlech_dongia,
  Case when dongia_moinhat > dongiachuavat_vnd then 'Tăng'
        when dongia_moinhat = dongiachuavat_vnd then 'Giữ nguyên'
        else 'Giảm' end as is_check_dongia,

 from data_mua_nvl 
);

Create or replace table `warehouse.f_lap_dulieu_muahang_nvl`

copy `staging_temp.f_lap_dulieu_muahang_nvl_temp`;


END;