CREATE VIEW `spatial-vision-343005.warehouse.view_thuhoi_bbgh`
AS with nvgh as
(
  SELECT 
    distinct a.macongtycn, 
    a.sodondathang,
    a.sodontrahang,
    a.kieudonhang,
    a.trangthaigiaohang,
    a.hoadon,
    ifnull(b.donvigiaohang,a.donvigiaohang) as donvigiaohang,
    ifnull(b.manvghreal,ifnull(a.manvghreal,a.manvgh)) as manvghreal,
  FROM `spatial-vision-343005.staging.f_sales` a
  left join `spatial-vision-343005.staging.d_dieuchinhmds` b on a.sodondathang = b.sodondathang

  WHERE ngaychungtu >= '2024-01-01' AND kieudonhang in ('CO','IN')
)
,

donhuy as
(
   SELECT 
    distinct sodontrahang,
    kieudonhang,
    hoadon,
    case when manvghreal is null then manvgh else manvghreal end as manvghreal ,
    case when tennvghreal is null then nguoigiaohang else tennvghreal end as tennvghreal,
  FROM `spatial-vision-343005.staging.f_sales` 
  WHERE ngaychungtu >= '2024-01-01' and kieudonhang = 'CO'
)
,

thuhoi_bienban as
(
  select 
    sodondathang,
    kt_da_nhan ,
    kh_ki_nhan_theo_mau_bb_giao_hang ,
    kh_ki_nhan_hang_tren_hoa_don ,
    p_manv ,
    p_version ,
    mds_da_ban_giao ,
    mds_phan_hoi ,
    mds_ghi_chu ,
    kt_ghi_chu 
  from `spatial-vision-343005.staging.d_form_kt_thong_tin_thu_hoi_bb_theo_user`
  where p_manv ='MR2662' and p_version = '085839'
  -- p_manv = manv_p and p_version = version_p
)
,

manual as
(
SELECT  distinct 
    cast(null as string) as magekhnb,
    makhdms as macsm,
    cast(null as string) as magevat,
    sodondathang as sodonhang,
    a.hoadon as sohoadon,
    ngaychungtu as ngayhoadon,
    null as ducuoikyno,
    ngaydatdon as ngaydonhang,
    cast(null as string) as pnql, 
    null as chenhlech,
    manv as macsmbh,
    tencvbh as tennvbh,
    ifnull(a.manvghreal,a.manvgh) as macsmgh,
    concat(makenhphu,maphanloaihco) as kenhphanphoi,
    makenhphu as kenhphu, 
    cast(null as string) as ktdanhan,
    cast(null as string) as nhan_bbgh,
    cast(null as string) as nhan_hdgh,
  FROM `spatial-vision-343005.staging.f_sales` a
  left join donhuy b on a.sodondathang = b.sodontrahang and a.hoadon = b.hoadon 
  where ngaychungtu >= '2023-01-01'and concat (trim(a.sodondathang),'-',a.hoadon) in  (select noimadhsohoadon from `staging.d_kt_thuhoi_bbgh_2023`) 
)
,

f_sale as
(
  SELECT  distinct 
    cast(null as string) as magekhnb,
    makhdms as macsm,
    cast(null as string) as magevat,
    sodondathang as sodonhang,
    a.hoadon as sohoadon,
    ngaychungtu as ngayhoadon,
    null as ducuoikyno,
    ngaydatdon as ngaydonhang,
    cast(null as string) as pnql, 
    null as chenhlech,
    manv as macsmbh,
    tencvbh as tennvbh,
    ifnull(a.manvghreal,a.manvgh) as macsmgh,
    concat(makenhphu,maphanloaihco) as kenhphanphoi,
    makenhphu as kenhphu, 
    cast(null as string) as ktdanhan,
    cast(null as string) as nhan_bbgh,
    cast(null as string) as nhan_hdgh,
  FROM `spatial-vision-343005.staging.f_sales` a
  left join donhuy b on a.sodondathang = b.sodontrahang and a.hoadon = b.hoadon 
  where (ngaychungtu >= '2024-01-01'and a.kieudonhang in ('IN') and b.kieudonhang is null) --or (concat (trim(a.sodondathang),'-',a.hoadon) in  (select noimadhsohoadon from `staging.d_kt_thuhoi_bbgh_2023`) )
)
,

total_data as
(
  SELECT * FROM manual
  union all 
  SELECT * FROM f_sale
)
,

SOXUATHANG as 
(
  -- Tạo sổ
  with dms_ib AS 
  (
    SELECT
      distinct branchid,
      truckid,
      batnbr,
      deliveryunit,
      slsperid as slsperid_ib,
      status as status_ib,
      issuedate as issuedate_ib,
      crtd_datetime as crtd_datetime_ib,
      crtd_user as crtd_user_ib,
      lupd_datetime as lupd_datetime_ib1,
      Case when date(approvedate) ='1900-01-01' then null else
      approvedate end as lupd_datetime_ib
      -- approvedate as lupd_datetime_ib
      -- đổi qua cột approvedate ngày 9/1/2023
    FROM `spatial-vision-343005.staging.sync_dms_ib`
    WHERE DATE(crtd_datetime) >= "2024-01-01"
  )
  ,

  -- Chốt sổ
  dms_ibd AS 
  (
    SELECT
      distinct branchid,
      batnbr,
      ordernbr,
      status as status_ibd,
      deliverytime as deliverytime_ibd,
      crtd_datetime crtd_datetime_ibd,
      crtd_user as crtd_user_ibd,
      lupd_datetime as lupd_datetime_ibd,
      transporters,
    FROM`spatial-vision-343005.staging.sync_dms_ibd`
    WHERE DATE(crtd_datetime) >= "2024-01-01" 
  )
  ,

  soxuathang_final as
  (
    SELECT 
      a.*,
      b.ordernbr,
      b.status_ibd,
      b.deliverytime_ibd,
      b.crtd_user_ibd,
      b.crtd_datetime_ibd,
      b.lupd_datetime_ibd,
      b.transporters,
      c.descr as thongtinxe_sxh,
      row_number() over (partition by a.batnbr,b.ordernbr order by crtd_datetime_ib desc) as loc  
    FROM dms_ib a 
    LEFT JOIN dms_ibd b on a.branchid = b.branchid and a.batnbr = b.batnbr
    LEFT JOIN `spatial-vision-343005.staging.sync_dms_ot` c on a.branchid = c.branchid 
                                                           and a.truckid = c.code
    WHERE status_ib = 'C'
  )

  select * from soxuathang_final 
  -- where loc = 1  
)
-- END SO XUAT HANG

,

result as
(
  select a.*,
    case when b.terms = '01' then 'Thu tiền ngay có VP PN'
          when b.terms = '03' then 'Thu tiền ngay không có VP PN'
          when b.terms = '07' then '7 Ngày'
          when b.terms = '10' then 'Thời hạn thanh toán 10 ngày'
          when b.terms = '12' then 'Thời hạn thanh toán 120 ngày'
          when b.terms = '15' then '15 Ngày'
          when b.terms = '18' then 'Thời hạn thanh toán 180 ngày'
          when b.terms = '20' then '20 Ngày'
          when b.terms = '30' then '30 Ngày'
          when b.terms = '45' then '45 Ngày'
          when b.terms = '60' then '60 Ngày'
          when b.terms = '90' then '90 Ngày'
          when b.terms = 'DF' then '150 Ngày'
          when b.terms = 'O1' then 'Gối 1 Đơn Hàng (trong 30 ngày)'
          when b.terms = 'O2' then 'TT vào ngày 15 hàng tháng'
          when b.terms = 'O3' then 'TT vào ngày 25 hàng tháng'
          when b.terms = 'O4' then 'TT vào ngày 7 hàng tháng' 
          else b.terms end as thoihanthanhtoan,
    b.orderdate as ngaythanhtoan,  
    case when b.paymentsform = 'A' then	'Chuyển Khoản'
         when b.paymentsform = 'B' then 'Tiền Mặt'
         when b.paymentsform = 'C' then 'Tiền Mặt/Chuyển Khoản'
         when b.paymentsform = 'D'	then 'Ghi Nợ'
         when b.paymentsform = 'E'	then 'TM/CK/CTH'
         when b.paymentsform = 'F' then	'Cấn Trừ Nợ' 
         else b.paymentsform end as hinhthucthanhtoan ,
    c.custname as dtcn_noi_bo,
    c1.custidinvoice,
    c1.custnameinvoice as ten_khach_hang_thue,

    c.territorydescr as khu_vuc,
    c.channel,
    ifnull(d.manvghreal,a.macsmgh) as manvgh,-- 1 số k có thông tin -> map theo theo thông tin tính lương
    d.donvigiaohang,
    d.trangthaigiaohang,   
    d1.kieudonhang,
    e.tencvbh as ten_nvgh,
    e.supid as sup_mds,
    e.tenquanlytt as tensup_mds,
    f.mds_da_ban_giao,
    f.mds_phan_hoi,
    f.mds_ghi_chu,
    f.kt_ghi_chu,
    ifnull(a.ktdanhan,case when f.kt_da_nhan is not null then 'X' else f.kt_da_nhan end) as kt_da_nhan ,
    ifnull(a.nhan_bbgh,f.kh_ki_nhan_theo_mau_bb_giao_hang) as kh_ki_nhan_theo_mau_bb_giao_hang,
    ifnull(a.nhan_hdgh,f.kh_ki_nhan_hang_tren_hoa_don) as kh_ki_nhan_hang_tren_hoa_don,
    f1.kt_phan_hoi,
    f1.inserted_at,

    case 
         when b.terms  in ('01','03') then null
          when  c.territorydescr in ('Miền Đông 2') then 'MR2931'
         when c.territorydescr in ('Mê Kông 1','Mê Kông 2') then 'MR0654'  
         when c.territorydescr in ('Hồ Chí Minh 1','Hồ Chí Minh 2') then 'MR2917'
         when c.territorydescr in ('Đông Bắc 1','Đông Bắc 2','Đông Nam 1','Hà Nội 1','Hà Nội 2','Tây Bắc HN','Đông Nam 2') then 'MR2280'
         when c.territorydescr in ('Nam Trung Bộ') then 'MR0781'     
         when c.territorydescr in ('Miền Đông 1') then 'MR0027'   
         when c.territorydescr in ('Bắc Trung Bộ') then 'MR0338'
      --  when hanmuccn not in ('Tiền Mặt') and c.territorydescr in ('Đông Nam 2') then 'MR2086' --- tháng 12/23 chuyển chị Phạm Nga phụ trách 
         else null end as ma_nguoiluutru, -----map theo danh sách chị Quỳnh  map theo chuyển khoản, tm/ck, ng lưu trữ hiện trống tức là Tiền mặt

    case 
         when b.terms  in ('01','03') then null
         when c.territorydescr in ('Miền Đông 2') then 'Ánh Hồng'
         when c.territorydescr in ('Mê Kông 1','Mê Kông 2') then 'Mỹ Nga'  
         when c.territorydescr in ('Hồ Chí Minh 1','Hồ Chí Minh 2') then 'Ngọc Nhi'
         when c.territorydescr in ('Đông Bắc 1','Đông Bắc 2','Đông Nam 1','Hà Nội 1','Hà Nội 2','Tây Bắc HN','Đông Nam 2') then 'Phạm Nga'
         when c.territorydescr in ('Nam Trung Bộ') then 'Phương Thúy'     
         when c.territorydescr in ('Miền Đông 1') then 'Thu Hằng'   
         when c.territorydescr in ('Bắc Trung Bộ') then 'Thương - Đà Nẵng'
        --  when hanmuccn not in ('Tiền Mặt') and c.territorydescr in ('Đông Nam 2') then 'Thương - Nghệ An'--- tháng 12/23 chuyển chị Phạm Nga phụ trách  
         else null end as nguoiluutru, -----map theo danh sách chị Quỳnh  map theo chuyển khoản, tm/ck, ng lưu trữ hiện trống tức là Tiền mặt

    Case when rd.ordernbr = a.sodonhang and d.macongtycn = rd.branchid and rd.custid = a.macsm then rd.deliveryunit
         when dr.ordernbr = a.sodonhang and d.macongtycn = dr.branchid and dr.custid = a.macsm then dr.deliveryunit
         else null end as deliveryunit_code,   

    ard.deliveryunitname,   
    sxh.thongtinxe_sxh,    

    sum(b.so_du_chungtu) as so_du_chungtu,
    case when sum(b.so_du_chungtu) = 0   then 'Đã thanh toán' 
         when sum(b.so_du_chungtu) is null  then '' 
         else 'Chưa thanh toán' end as tinhtrang_thanhtoan, 
    row_number() over (partition by (concat (trim(a.sodonhang),'-',a.sohoadon) ) order by f1.inserted_at) as loc,

     
  from total_data a
  LEFT JOIN `spatial-vision-343005.staging_temp.d_rawdata_debt` b on concat (trim(a.sodonhang),a.sohoadon) = concat (b.Ordnbr,b.InvcNbr) 
                                                                  and dateoforder >= '2023-01-01'
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang` c on trim(a.macsm) = c.custid
  LEFT JOIN `spatial-vision-343005.staging.d_master_khachhang_bytime` c1 on trim(a.macsm) = c1.custid and timestamp_trunc(a.ngayhoadon,month) = c1.thang

  LEFT JOIN nvgh d on concat (trim(a.sodonhang),a.sohoadon) = concat (d.sodondathang,d.hoadon)
  LEFT JOIN donhuy d1 on concat (trim(a.sodonhang),a.sohoadon) = concat (d1.sodontrahang,d1.hoadon)
  LEFT JOIN `spatial-vision-343005.staging.d_users` e on ifnull(d.manvghreal,a.macsmgh) = e.manv
  left join thuhoi_bienban f on concat (trim(a.sodonhang),'-',a.sohoadon) =  f.sodondathang -- kq từ form kt nhập
  left join `spatial-vision-343005.staging.view_form_ktttthbb_phan_hoi` f1 on concat (trim(a.sodonhang),'-',a.sohoadon) =  f1.sodondathang
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_rd` rd on a.sodonhang = rd.ordernbr 
                                                          and d.macongtycn = rd.branchid 
                                                          and a.macsm = rd.custid 
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_dr` dr on a.sodonhang = dr.ordernbr 
                                                          and d.macongtycn = dr.branchid 
                                                          and a.macsm = dr.custid 
  LEFT JOIN `spatial-vision-343005.staging.sync_dms_ard` ard on ard.branchid = d.macongtycn  and
                                                      (Case when    rd.ordernbr = a.sodonhang 
                                                                and d.macongtycn = rd.branchid 
                                                                and rd.custid = a.macsm then rd.deliveryunit
                                                            when     dr.ordernbr = a.sodonhang 
                                                                 and d.macongtycn = dr.branchid 
                                                                 and dr.custid = a.macsm then dr.deliveryunit
                                                            else null end
                                                      ) = ard.deliveryunitid    
  LEFT JOIN SOXUATHANG sxh on a.sodonhang = sxh.ordernbr                                                                                            

  where c.channel not in ('OTH_LAB','NB') and b.InvcNbr is not null
  group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
),
mapping_all as (
  select 
    a.*except(kt_da_nhan,kh_ki_nhan_theo_mau_bb_giao_hang,kh_ki_nhan_hang_tren_hoa_don,kt_phan_hoi,kt_ghi_chu,mds_da_ban_giao,mds_phan_hoi,mds_ghi_chu),

    case 
          
         
         when ifnull(thoihanthanhtoan,'') in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN') then 'MDS phụ trách'

         when  ifnull(thoihanthanhtoan,'') not in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN') and hinhthucthanhtoan ='Tiền Mặt'  then 'MDS phụ trách'
         when  ifnull(thoihanthanhtoan,'') not in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN') and hinhthucthanhtoan <> 'Tiền Mặt'  then 'KT phụ trách'
        --  when nguoiluutru is null then 'MDS phụ trách'
              
         else '' end as nhomphutrach_thuhoi,
    Case when ifnull(thoihanthanhtoan,'') in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN') then 'Thanh toán ngay' else 'Có thời hạn nợ' end as pl_hinhthuc_tt,


    ifnull(a.kt_da_nhan,nullif( ifnull(b.ketoandanhan,b1.ketoandanhan),'-')) as kt_da_nhan,
    ifnull(a.kh_ki_nhan_theo_mau_bb_giao_hang,nullif( ifnull(b.khkinhantheomaubbgh,b1.khkinhantheomaubbgh),'-')) as kh_ki_nhan_theo_mau_bb_giao_hang,
    ifnull(a.kh_ki_nhan_hang_tren_hoa_don,nullif(ifnull(b.khkinhanhangtrenhdon,b1.khkinhanhangtrenhdon),'-')) as kh_ki_nhan_hang_tren_hoa_don,
    ifnull(a.kt_phan_hoi,nullif(ifnull(b.ketoanphanhoi,b1.ketoanphanhoi),'-')) as kt_phan_hoi,
    ifnull(a.kt_ghi_chu,nullif(ifnull(b.ketoanghichu,b1.ketoanghichu),'-')) as kt_ghi_chu,

    ifnull(a.mds_da_ban_giao,nullif(c.mdsdabangiaogoxneudabangiao,'-')) as mds_da_ban_giao,
    ifnull(a.mds_phan_hoi,nullif(c.mdsphanhoi,'-')) as mds_phan_hoi,
    ifnull(a.mds_ghi_chu,nullif(c.mdsghichu,'-')) as mds_ghi_chu,
    Case when d.tenquanlyvung ='Lương Trịnh Thắng' then 'MDS'
         when d.tenquanlyvung ='Nguyễn Hoàng Viển' then 'SDS'
      else null end as phanloai_giaohang

  from result a
  left join `spatial-vision-343005.staging.d_kt_thuhoi_bbgh` b on concat (trim(a.sodonhang),'-',a.sohoadon) = b.noimadhsohoadon -- kq từ ggsheet kt nhập
  left join `spatial-vision-343005.staging.d_kt_thuhoi_bbgh_2023` b1 on concat (trim(a.sodonhang),'-',a.sohoadon) = b1.noimadhsohoadon -- kq từ ggsheet kt nhập
  left join `spatial-vision-343005.staging.d_mds_thuhoi_bbgh` c on concat (trim(a.sodonhang),'-',a.sohoadon) = c.noimadhsohoadon -- kq từ ggsshet mds nhập
  left join `spatial-vision-343005.staging.d_users` d on a.manvgh =d.manv
  where loc = 1  --and sodonhang in ('DH0-1023-00755')
  )
 
  select a.*,
  case when so_du_chungtu != 0 or so_du_chungtu is null then concat(sohoadon,macsm) else null end as sl_hd_dh_chua_thanh_toan,
  case when so_du_chungtu = 0 then concat(sohoadon,macsm) else null end as sl_hd_dh_da_thanh_toan,

  Case 
    when nhomphutrach_thuhoi ='MDS phụ trách' and so_du_chungtu = 0 
          and ifnull(thoihanthanhtoan,'')  in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN')  then '9. MDS giữ để thu tiền mặt đã thanh toán'
    
    when nhomphutrach_thuhoi ='MDS phụ trách' and (so_du_chungtu != 0 or so_du_chungtu is null)
          and ifnull(thoihanthanhtoan,'')  in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN')  then '8. MDS giữ để thu tiền mặt chưa thanh toán'
    
    when nhomphutrach_thuhoi ='MDS phụ trách' and  (so_du_chungtu != 0 or so_du_chungtu is null) and (kt_da_nhan is not null ) 
          and ifnull(thoihanthanhtoan,'') not in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN')
            then '7. MDS giữ để thu tiền mặt chưa thanh toán - KT đã nhận hình ảnh'

    when nhomphutrach_thuhoi ='MDS phụ trách' and  (so_du_chungtu != 0 or so_du_chungtu is null) and kt_da_nhan is  null 
          and ifnull(thoihanthanhtoan,'') not in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN')
            then '6. MDS giữ để thu tiền mặt chưa thanh toán - KT chưa nhận hình ảnh'

    when nhomphutrach_thuhoi ='MDS phụ trách' and so_du_chungtu = 0 
          and ifnull(thoihanthanhtoan,'') not in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN') and (kt_da_nhan is not null ) 
          then '5. MDS giữ để thu tiền mặt đã thanh toán - KT đã nhận hình ảnh'  

    when nhomphutrach_thuhoi ='MDS phụ trách' and so_du_chungtu = 0 
          and ifnull(thoihanthanhtoan,'') not in ('Thu tiền ngay có VP PN','Thu tiền ngay không có VP PN') and kt_da_nhan is  null 
          then '4. MDS giữ để thu tiền mặt đã thanh toán - KT chưa nhận hình ảnh'  

    when nhomphutrach_thuhoi ='KT phụ trách' and kt_da_nhan is not null then '1. KT đã thu'
    when nhomphutrach_thuhoi ='KT phụ trách' and kt_da_nhan is  null  and (so_du_chungtu != 0 or so_du_chungtu is null) then '2. KT chưa thu + còn nợ'
    when nhomphutrach_thuhoi ='KT phụ trách' and kt_da_nhan is  null and  so_du_chungtu = 0 then '3. KT chưa thu + hết nợ'
    
    else null end as pl_thuhoi_bbgh
  
   from mapping_all a 
   LEFT JOIN staging.d_manual_ds_kh_theodoi_pcl b on a.macsm =b.makh
;