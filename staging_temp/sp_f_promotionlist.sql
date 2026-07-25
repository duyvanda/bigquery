CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_promotionlist()
BEGIN 
  TRUNCATE TABLE staging_temp.f_promotionlist_temp;

 INSERT INTO staging_temp.f_promotionlist_temp(


-- Create table staging_temp.f_promotionlist_temp

-- as

SELECT 
discseq as ma_ctrinh,
discountname as ten_ctrinh,
contentinvoice as noidung_ctrinh,
discountpn as ma_ctrinh_pn,
discounttype as loai_ctrinh,
startdate2,
enddate2,
statusname as trangthai,
discatordidx as apdung_dh_thu,
promotype as quytac_tanghang,
statedisc as tinh_apdung,
discclassname as loai_dieukiendactrung,
custname as dieukiendactrung,
excludepromopn as loaitru_khuyenmai,
invtname as s_thamgiagiohang,
lineref as muc,
linename as diengiai_muc,
breakbyname as loai_dieukien,
breakamtqty as soluong_sotien,
discforname as chietkhau_theo,
convertfreeitem as chietkhautien_quy_sptang,
bonus as chietkhau,
menthod as phuongphap_chonsptang,
freeitemid as masp_tang,
unitdescr as donvi,
freeitemqty as soluong,

  case 
  when discseq = discseq then 'Cơ cấu áp dụng' 
  when discountname = discountname then 'Cơ cấu áp dụng' 
  when contentinvoice = contentinvoice then 'Cơ cấu áp dụng' 
  when discountpn = discountpn then 'Cơ cấu áp dụng' 
  when discounttype = discounttype then 'Cơ cấu áp dụng' 
  when startdate2 = startdate2 then 'Cơ cấu áp dụng' 
  when enddate2 = enddate2 then 'Cơ cấu áp dụng' 
  when statusname = statusname then 'Cơ cấu áp dụng' 
  when discatordidx = discatordidx then 'Cơ cấu áp dụng' 
  when promotype = promotype then 'Cơ cấu áp dụng' 
  when discclassname = discclassname then 'Cơ cấu áp dụng' 
  when custname = custname then 'Cơ cấu áp dụng' 
  when excludepromopn = excludepromopn then 'Cơ cấu áp dụng' 
  when invtname = invtname then 'Cơ cấu áp dụng'  
  
  when lineref = lineref then 'Điều kiện kiểm tra'
  when linename = linename then 'Điều kiện kiểm tra'
  when breakbyname = breakbyname then 'Điều kiện kiểm tra'
  when breakamtqty = breakamtqty then 'Điều kiện kiểm tra'
  
  when discforname = discforname then 'Kết quả khuyến mãi'
  when convertfreeitem = convertfreeitem then 'Kết quả khuyến mãi'
  when bonus = bonus then 'Kết quả khuyến mãi'
  when menthod = menthod then 'Kết quả khuyến mãi'
  when freeitemid = freeitemid then 'Kết quả khuyến mãi'
  when unitdescr = unitdescr then 'Kết quả khuyến mãi'
  when freeitemqty = freeitemqty then 'Kết quả khuyến mãi'
  
  
  else null end as type,


 FROM `spatial-vision-343005.staging.d_promotionlist`

   );
Create or replace table `warehouse.f_promotionlist`

copy `staging_temp.f_promotionlist_temp`;

End;