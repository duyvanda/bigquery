CREATE PROCEDURE `spatial-vision-343005`.staging_temp.sp_f_danh_sach_khach_hang_all()
BEGIN 
 
-- TRUNCATE TABLE `staging_temp.f_danh_sach_khach_hang_all_temp`;
-- INSERT INTO `staging_temp.f_danh_sach_khach_hang_all_temp`
-- (
Create or replace table staging_temp.f_danh_sach_khach_hang_all_temp as (

with 

sales as (

select 
makhdms,
extract(year from ngaychungtu) as nam,
sum(doanhsochuavat) as doanhsochuavat 
from `staging.f_sales`
WHERE DATE(ngaychungtu)>= '2024-01-01'
group by 1,2
),

mst_gan_nhat as (
  SELECT custid, taxregnbr, lupd_datetime FROM `spatial-vision-343005.staging.sync_dms_custhis` where taxregnbr is not null 
qualify row_number() over (partition by custid order by lupd_datetime desc) = 1

)
,

ngay_chinhsua_mst as 
(
with kh as (
SELECT custid, 
taxregnbr,
 lupd_datetime,row_number() over (partition by custid  order by lupd_datetime desc) as stt FROM `spatial-vision-343005.staging.sync_dms_custhis` 
)
select a.*,b.stt as stt1,b.lupd_datetime as lupd_datetime1,b.taxregnbr as taxregnbr1  from kh a 
LEFT JOIN kh b on a.custid =b.custid and a.stt = b.stt+1 and ifnull(a.taxregnbr,'x') <>  ifnull(b.taxregnbr,'x')
qualify row_number () over (partition by a.custid order by b.lupd_datetime desc,a.lupd_datetime) = 1
),
--Update từ ngày 1/4
tuyen_dms_moinhat as (
    with data_tuyen as (
        SELECT
            custid,
            slsperid,
            crtd_datetime,
            Case
                when routetype in ('B', 'D') then 1
                else 2
            end as routetype,
        FROM
            `spatial-vision-343005.staging.sync_dms_srm`
        where
            delroutedet is false
    )
    select
        *
    from
        data_tuyen 
        qualify row_number() over (
            partition by custid
            order by
                routetype asc,
                crtd_datetime desc
        ) = 1
),
---Tuyến bán hàng theo hợp đồng
tuyen_cvbh_hd as (
    select
        *,
        row_number() over(
            partition by custid
            order by
                crtd_date desc
        ) as loc
    from
        `spatial-vision-343005.staging.d_get_contract_det` 
        qualify row_number() over(
            partition by custid
            order by
                crtd_date desc
        ) = 1
),

data_khach_hang as (
SELECT
  branchid as ma_chi_nhanh,
  branchname as ten_chi_nhanh,
  custid as ma_khach_hang,
  custname as ten_khach_hang,
  refcustid as ma_khach_hang_cu,
  pubcustid as ma_khach_hang_chung,
  pubcustname as ten_khach_hang_chung,
  businessname as chu_nt_tren_gpkd,
  address as dia_chi_khach_hang,
  streetname as ten_duong,
  custidinvoice as ma_kh_thue,
  custnameinvoice as ten_kh_thue,
  emailinvoice as email_kh_thue,
  addr1 as dia_chi_kh_thue,
  personaltaxregnbr as ma_so_thue_ca_nhan,
  taxregnbr as ma_so_thue,
  attn as nguoi_lien_he,
  shoperid as nguoi_mua_hang,
  statecode as ma_tinh,
  districtcode as ma_quan_huyen,
  wardcode as ma_phuong_xa,
  territorycode as ma_khu_vuc,
  statedescr as ten_tinh,
  districtdescr as ten_quan_huyen,
  wardname as ten_phuong_xa,
  territorydescr as ten_khu_vuc,
  phone as so_dien_thoai,
  channel as ma_kenh,
  channeldescr as ten_kenh,
  shoptype as ma_kenh_phu,
  shoptypedescr as ten_kenh_phu,
  hcotypeid as ma_phan_loai_hco,
  hcotypename as ten_phan_loai_hco,
  hcoid as ma_hco,
  classid as ma_phan_hang,
  paymentsform as hinh_thuc_thanh_toan,
  terms as thoi_han_thanh_toan,
  salessystem as ma_htbh,
  salessystemdescr as ten_htbh,
  autogenorder as ten_tu_dong_tao_hd,
  batchexpform as ten_hinh_thuc_xuat_lo,
  crtd_user as nguoi_tao, 
  crtd_datetime as ngay_tao,
  active as trang_thai,
  lat as vi_do,
  lng as kinh_do,
  taxdeclaration as loai_ma_so_thue,
  stocksales as tinh_trang_ma_so_thue, 
  businessscope as pham_vi_kinh_doanh,
  agencyid as ma_dlpp,
  agencyname as ten_dlpp,
  inactive as ly_do_ngung_ho_so,
  chargephar as phu_trach_khoa_duoc,
  chargepayment as phu_trach_thanh_toan,
  chargereceive as phu_trach_nhan_hang,
  legalname as ten_tren_giay_gdp_gpp,
  legaldate as thoi_gian_hieu_luc_gdp_gpp,
  Case 
      when market = '08' or market like '%KH bán%' then 'Không phải KH bán'
      when market = '07' then 'Phòng Khám'
      when market = '06' then 'Bệnh viện'
      when market = '05' then 'CSDY'
      when market = '04' then 'PKNK'
      when market = '03' then 'Công Ty'
      when market = '02' then 'Quầy Thuốc'
      when market = '01' then 'Nhà Thuốc'
      when market = 'NA' or market like '%ChuaCo%' then 'Chưa Xác Định'
  else null
  end as loai_hinh_kinh_doanh,
  oricustid as so_giay_gpp,
  generalcustid as so_giay_du_dkkdd,
  vendorid as doanh_so_dong_khoan_thue,
  date(EstablishDate2) as ngay_cap_du_dkkdd,
  billmarket as ghi_chu_dieu_chinh,
  Case  
    when a.branchid in('HYN017') then'BB'
    when a.branchid in('MR0001','HCM001') then'HCM'
    when a.branchid in('HNI010','MR0010') then'HN'
    when a.branchid in('DNI015','MR0013') then'MD'
    when a.branchid in('CT0016','MR0016') then'MK'
    when a.branchid in('DNG013','KHA014','MR0014','MR0015') then'MT'
  else null end as ma_vung,
  Case  
    when a.branchid ='HYN017' then'Bắc Bộ'
    when a.branchid in('MR0001','HCM001') then'Hồ Chí Minh'
    when a.branchid in('HNI010','MR0010') then'Hà Nội'
    when a.branchid in('DNI015','MR0013') then'Miền Đông'
    when a.branchid in('CT0016','MR0016') then'Mê Kông'
    when a.branchid in('DNG013','KHA014','MR0014','MR0015') then'Miền Trung'
  else null end as ten_vung,
  a.citizenid as cccd,
  inserted_at

FROM
  `spatial-vision-343005.staging.d_master_khachhang` a
  where active ='Active'
)
,
pl_xet_gdp as (
select 
a.*,
b.dueintnv as so_ngay_thanh_toan,
b.termsid as ma_thoi_han_thanh_toan,
Replace(
  Replace(
    Replace(
      Replace(
        Replace ( 
          Replace(
          ( Replace (pham_vi_kinh_doanh,'01','Nhóm I') ) ,
            '02','Nhóm II' ),
              '03','Nhóm III'),
                '04','Nhóm IV'),
                  '05','Nhóm V'),
                    '06','Nhóm VI (Hàng khác- không bán)'),
                      '07','Nhóm VII'
          ) as ten_pham_vi_kinh_doanh,
if(SAFE_CAST(doanh_so_dong_khoan_thue AS FLOAT64) is null,'Not a number', 'A number')   as check_doanh_so_dong_khoan_thue,        
Case 
  when loai_hinh_kinh_doanh ='Không phải KH bán' then 'Không xét GDP'
  when a.ma_kenh_phu in ('CLC1','CLC2') then 'Không xét GDP'
  when a.ma_kenh in ('INS','NB','OTH_LAB') then 'Không xét GDP'
  when a.ma_phan_loai_hco in ('CSDYDL','NTXQPK','PKNK') then 'Không xét GDP'
else 'Có xét GDP' end as phan_loai_xet_gdp,
 from data_khach_hang a 
 LEFT JOIN `staging.d_manual_terms_detail` b on trim(upper(a.thoi_han_thanh_toan)) = trim(upper(b.descr))

),
so_ngay_het_han as (
select 
a.*,
Case 
  when phan_loai_xet_gdp ='Có xét GDP' then date_diff(date(thoi_gian_hieu_luc_gdp_gpp), current_date("+7"),day)
else 0 end as so_ngay_het_han_gdp,

Case 
  when phan_loai_xet_gdp ='Có xét GDP' and (thoi_gian_hieu_luc_gdp_gpp is null or thoi_gian_hieu_luc_gdp_gpp ='1900-01-01') then 'Chưa có GPP'
  when phan_loai_xet_gdp ='Có xét GDP' and date_diff(date(thoi_gian_hieu_luc_gdp_gpp), current_date("+7"),day) >= 0 then 'GDP còn hạn'
  when phan_loai_xet_gdp ='Có xét GDP' and date_diff(date(thoi_gian_hieu_luc_gdp_gpp), current_date("+7"),day) >= -90 
        and date_diff(date(thoi_gian_hieu_luc_gdp_gpp), current_date("+7"),day) < 0 then 'Hết hạn GDP < 90n - Được bán tiếp'
  when phan_loai_xet_gdp ='Có xét GDP' and date_diff(date(thoi_gian_hieu_luc_gdp_gpp), current_date("+7"),day) >= -180 
        and date_diff(date(thoi_gian_hieu_luc_gdp_gpp), current_date("+7"),day) < -90 then 'Hết hạn GDP < 180n - Cảnh báo'
  when phan_loai_xet_gdp ='Có xét GDP' and date_diff(date(thoi_gian_hieu_luc_gdp_gpp), current_date("+7"),day) < -180  then 'Hết hạn GDP > 180n - Ngưng'

else 'Không xét GPP' end as tinh_trang_gdp,


from pl_xet_gdp a
)
,
check_khaibao_gpp as (
select a.*,
Case 
  when tinh_trang_gdp ='Không xét GPP' then 'Không xét GPP'
  when phan_loai_xet_gdp ='Có xét GDP' and tinh_trang_gdp <> 'Chưa có GPP' and so_ngay_het_han_gdp <= 1095 then 'OK'
  when phan_loai_xet_gdp ='Có xét GDP' and tinh_trang_gdp <> 'Chưa có GPP' and so_ngay_het_han_gdp > 1095 then 'Khai báo sai'
else 'Chưa có GPP' end as check_khai_bao_ngay_gpp,
Case 
  when tinh_trang_gdp ='Không xét GPP' then 'Không xét GPP'
  when tinh_trang_gdp ='Chưa có GPP' then 'Chưa có GPP'
  when so_giay_gpp is null or so_giay_gpp ="" then 'Khai báo thiếu số giấy GPP'
else 'OK' end as check_khai_bao_so_gpp,


from so_ngay_het_han a
)
,
check_all as (
select 
a.*,
Case 
  when tinh_trang_gdp ='Không xét GPP' then 'Không xét GPP'
  when check_khai_bao_ngay_gpp <>'Chưa có GPP' and loai_hinh_kinh_doanh ='Chưa Xác Định' then 'Khai thiếu loại hình KD'
  when check_khai_bao_ngay_gpp <>'Chưa có GPP' and loai_hinh_kinh_doanh <> 'Chưa Xác Định' then 'OK'
else 'Chưa có GPP' end as check_khai_bao_loai_hinh_kd,

Case 
  when tinh_trang_gdp ='Không xét GPP' then 'Không xét GPP'
  when check_khai_bao_ngay_gpp <>'Chưa có GPP' and (ten_tren_giay_gdp_gpp is null or ten_tren_giay_gdp_gpp ="") then 'Khai thiếu tên GPP'
  when check_khai_bao_ngay_gpp <>'Chưa có GPP' and ten_tren_giay_gdp_gpp is not null and ten_tren_giay_gdp_gpp <> "" then 'OK'
else 'Chưa có GPP' end as check_khai_bao_ten_gpp,

Case 
  when ma_phan_loai_hco ='CSDLDY' and pham_vi_kinh_doanh not like '%05%' and pham_vi_kinh_doanh not like '%06%' then 'Xem lại PVKD'
  when ma_phan_loai_hco ='CSDLDY' and pham_vi_kinh_doanh not like '%06%' then 'Xem lại PVKD'
  when ma_phan_loai_hco ='CSDLDY' then ""
  when ma_phan_loai_hco ='PKNK' and pham_vi_kinh_doanh not like '%05%' and pham_vi_kinh_doanh not like '%06%' then 'Xem lại PVKD'
  when ma_phan_loai_hco ='PKNK' and pham_vi_kinh_doanh not like '%06%' then 'Xem lại PVKD'
  when ma_phan_loai_hco ='PKNK' then "OK" 
else 'OK' end as check_pvkd_theo_nhom_kh,

Case 
  when tinh_trang_gdp in ('Chưa có GPP', 'Hết hạn GDP > 180n - Ngưng') then 'Chỉ bán nhóm V'
  else 'Bán bình thường' end as check_tinh_trang_ban_hang_theo_gpp,

Case 
  when trim(upper(loai_ma_so_thue)) in ("CHƯA XÁC ĐỊNH",'DMS THIẾU') or loai_ma_so_thue is null then 'Thiếu thông tin Loại MST'
  else 'OK' end as check_thong_tin_loai_mst,

Case when tinh_trang_ma_so_thue not in ('Đã chuyển cơ quan thuế quản lý','Không có MST','Đang hoạt động','Tạm nghỉ kinh doanh có thời hạn','Ngừng hoạt động và đã đóng MST','Không hoạt động tại địa chỉ đã đăng ký','Ngừng hoạt động nhưng chưa hoàn thành thủ tục đóng MST','Không hoạt động tại địa chỉ đã đăng ký - Không giấy tờ bổ sung','Không hoạt động tại địa chỉ đã đăng ký  - Có giấy bổ sung','Đã chuyển cơ quan thuế quản lý - Không giấy tờ bổ sung','Đã chuyển cơ quan thuế quản lý - Có giấy tờ bổ sung') or tinh_trang_ma_so_thue is null then 'Thiếu thông tin Tình trạng MST'
  else 'OK' end as check_tinh_trang_mst,

Case
  when doanh_so_dong_khoan_thue = 'TTDT' then 'OK'
  when doanh_so_dong_khoan_thue = 'GTGT' then 'OK' 
  when doanh_so_dong_khoan_thue ='Trực tiếp doanh thu' then 'OK'
  when check_doanh_so_dong_khoan_thue ='A number' and doanh_so_dong_khoan_thue ='0' then 'Thiếu thông tin DS khoán'
  when check_doanh_so_dong_khoan_thue ='A number'or upper(doanh_so_dong_khoan_thue) like '%KHÔNG%' then 'OK'
else 'Thiếu thông tin DS khoán' end as check_thong_tin_thue_khoan,

Case 
  when (ma_so_thue is  null or ma_so_thue = "") and ma_so_thue_ca_nhan is not null then 'Có MST phụ'
  when (ma_so_thue is  null or ma_so_thue = "") and ma_so_thue_ca_nhan is null then 'Không có MST phụ'
  else 'Không cần MST phụ' end as check_ma_so_thue_phu,
Case 
  when tinh_trang_ma_so_thue in ('Ngừng hoạt động và đã đóng MST','Ngừng hoạt động nhưng chưa hoàn thành thủ tục đóng MST','Tạm nghỉ kinh doanh có thời hạn') then 'Ngưng bán'
  else 'Bán theo HSPL' end as check_tinh_trang_ban_hang_theo_mst,

 from check_khaibao_gpp a
)

select a.*,
Case 
when  check_tinh_trang_ban_hang_theo_mst ='Ngưng bán' and pham_vi_kinh_doanh ='06' then 'Cần điều chỉnh phạm vi KD'
else 'OK' end as check_pvkd,
Case when tinh_trang_ma_so_thue in ('Ngừng hoạt động và đã đóng MST','Ngừng hoạt động nhưng chưa hoàn thành thủ tục đóng MST','Tạm nghỉ kinh doanh có thời hạn') then 'Ngưng bán'
     when check_ma_so_thue_phu ='Không có MST phụ' then 'Ngưng bán'
     when phan_loai_xet_gdp ='Không xét GDP' then 'Bán bình thường'
     when tinh_trang_gdp in ('Chưa có GPP', 'Hết hạn GDP > 180n - Ngưng') then 'Chỉ bán nhóm V'
else 'Bán bình thường' end as tinh_trang_duoc_ban_hang,
h.col.ma_nvbh  as ma_crs,
k1.tencvbh,
k1.supid as ma_crm,
k1.tenquanlytt,
k1.rsmid as ma_ncxm,
k1.tenquanlyvung,
b.doanhsochuavat as doanhsochuavat_2023,
c.doanhsochuavat as doanhsochuavat_2024,
d.taxregnbr as taxregnbr_gan_nhat,
e.lupd_datetime1 as ngay_chinh_sua_mst_gan_nhat,
k.lupd_datetime

from check_all a 
LEFT JOIN `warehouse.f_mapping_crs` h on h.custid = a.ma_khach_hang
-- LEFT JOIN tuyen_cvbh_hd b2 on b2.custid = a.ma_khach_hang
LEFT JOIN staging.d_users k1 on h.col.ma_nvbh = k1.manv
LEFT JOIN sales b on a.ma_khach_hang =b.makhdms and b.nam = extract(year from current_date("+7")) - 1
LEFT JOIN sales c on a.ma_khach_hang =c.makhdms and c.nam = extract(year from current_date("+7")) 
LEFT JOIN mst_gan_nhat d on a.ma_khach_hang = d.custid
LEFT JOIN ngay_chinhsua_mst e on a.ma_khach_hang = e.custid
LEFT JOIN 
    ( SELECT distinct custid, MAX(lupd_datetime) as lupd_datetime 
    FROM `spatial-vision-343005.warehouse.view_tracking_cust_changes`
    where loai_thay_doi = 'Doanh Số Khoán'
    group by custid ) k
ON k.custid = a.ma_khach_hang

);

Create or replace table `warehouse.f_danh_sach_khach_hang_all`

copy `staging_temp.f_danh_sach_khach_hang_all_temp`;


END;